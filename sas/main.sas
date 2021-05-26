/********************************************/
/*     Macro Variables for User to Set      */
/********************************************/
%let parentpath=/home/sasdemo/FDA-Covid19-DR-project;
%let testscript=1;
%let parent=1;


OPTIONS SOURCE2 MPRINT MPRINTNEST;

%let sessionName=mainSession;
cas &sessionName;

/* Code Location */
/* Defines the paths to other sas scripts so we can "%INCLUDE" them later */
filename FACTMAC "&parentpath/sas/factmac";
filename NETWORK "&parentpath/sas/network";

/* Data Location */
/* Define caslib locations so that cas can read and write data on disk                      */
/*     - repositioning: the source data (after cleaning)                                    */
/*     - embedding: where we land the embeddings from our various methods                   */
/*     - visualization: where tables to be visualized in Visual Analytics go                */
caslib repositioning datasource=(srctype="path") path="&parentpath/data/repositioning" global sessref=&sessionName;
caslib embedding     datasource=(srctype="path") path="&parentpath/data/embedding"     global sessref=&sessionName;
caslib visualization datasource=(srctype="path") path="&parentpath/data/visualization" global sessref=&sessionName;

/* Bind sas libnames to caslibs so sas can read and write data in cas */
libname repo    cas caslib="repositioning";
libname embed   cas caslib="embedding"    ;
libname visual  cas caslib="visualization";
libname casuser cas caslib="casuser"      ;
libname public  cas caslib="public"       ;

/* * * * * * * * * * Load Data * * * * * * * * * * * * * * * * */
proc casutil incaslib="repositioning" outcaslib="repositioning" sessref="&sessionName";
	load casdata="dbProteins.csv" casout="DBProteins" replace;
	load casdata="stringPP.csv" casout="stringpp" replace;
	load casdata="Truth.csv" casout="truth" replace;
quit;


/* * * * * * * * * * PROC FACTMAC Embedding * * * * * * * * * */
/* %let sessionName=casfactmac; */
/* cas &sessionName; */
/* caslib _all_ assign; */

%INCLUDE FACTMAC("LoadEdgelist.sas");
%INCLUDE FACTMAC("SampleNegativeEdgelist.sas");
%INCLUDE FACTMAC(LearnFactmacEmbeddings);
/* %INCLUDE FACTMAC(VisualizeFactmac); */

cas &sessionName terminate;

/* * * * * * * * * * PROC NETWORK Embedding  * * * * * * * * */
filename NETWORK filesrvc folderpath='/Projects/DrugReposition/Link Prediction/NETWORK';

/* 1. Drug-Protein Only, Bipartite projection  */
%INCLUDE NETWORK(method1);

/* 2. Drug-Protein and Protein-Protein subset   */
%INCLUDE NETWORK(method2);

/* 3. Drug-Protein and Protein-Protein full     */
%INCLUDE NETWORK(method3);

/* 4. Drug-Protein, weighted by Protein-Protein */

/* * * * * * * * * * PROC TSNE Visualizations  * * * * * * * * */

%macro tsne_vary(start=5, end=50, by=5, datain=network2_embeddings, dataout=network2_tsne);
/* You may want to consider setting the maxIters to a low value for runtime. */
cas tsnesession;
libname casuser cas caslib="casuser";
libname embed cas caslib="embed";
libname visual cas caslib="visual";
libname public cas caslib="public";

%do i=&start %to &end %by &by;
proc tsne
   seed        = 1
   data        = embed.&datain
   nDimensions = 2
   perplexity  = &i
   maxIters    = 400;
   input         vec_:;
   output
      out      = casuser.drugTsne_&i
      copyvars = (node);
run;
data casuser.drugTsne_&i;
    set casuser.drugTsne_&i;
    perplexity = &i;
run;
%end;
data casuser.tsne_all;
    set 
    %do i=&start %to &end %by &by;
        casuser.drugTsne_&i
    %end;
    ;
	length drugbank_id varchar(*);
	if substr(node, 1, 2) = 'DB' then drugbank_id = node;
run;

data casuser.tsne_all;
	merge casuser.tsne_all public.dbsmallm_truth;
	by drugbank_id;
run;

proc casutil;
	droptable casdata="&dataout" incaslib="visual" quiet;
	promote incaslib="casuser" casdata="tsne_all" outcaslib="visual" casout="&dataout";
quit;

cas tsnesession terminate;
%mend;

%tsne_vary(start=5, end=50, by=5, datain=network1_embeddings, dataout=network1_tsne);
%tsne_vary(start=5, end=50, by=5, datain=network2_embeddings, dataout=network2_tsne);
%tsne_vary(start=5, end=50, by=5, datain=network3_embeddings, dataout=network3_tsne);

%let embeddings=embed.network2_embeddings;

%macro retrieve_candidates(embeddings=embed.network2_embeddings);

%let embeddings=embed.network1_embeddings;

%let sessionName = localsession;
cas localsession;
libname casuser cas caslib="casuser";
libname embed cas caslib="embedding";
libname public cas caslib="public";
libname repo cas caslib="repositioning";

data work.fastknn_data;
	set &embeddings;
	if substr(node, 1, 2) = 'DB';
	nodeid = _n_;
run;

proc sql;
	drop table fastknn_query;

	create table fastknn_query as
	select d.* 
	from repo.truth as t inner join work.fastknn_data as d
	on d.node = t.drugbank_id;
quit;

proc casutil outcaslib="casuser";
	load data=work.fastknn_data replace;
	load data=work.fastknn_query replace;
quit; 

proc fastknn data=casuser.fastknn_data query=casuser.fastknn_query k=10 outdist=casuser.fastknn_dist;
	id nodeid;
	input vec_:;
	output out=casuser.nearest_neighbors;
run;

proc sql;
	create table nearest_neighbors as
	select d.*
	from casuser.fastknn_dist d
	where d.ReferenceID not in (select QueryID from casuser.fastknn_dist)
	order by QueryID, Distance;
quit;

data work.nearest_neighbors;
	set nearest_neighbors;
	by QueryID Distance;
	if first.QueryID then seqno = 0;
	seqno + 1;
run;

data casuser.nearest_neighbors;
	set work.nearest_neighbors;
	where seqno <= 10;
run;

proc fedsql sessref=&sessionName;
	drop table casuser.candidates force;

	create table casuser.candidates as
	select c.name, a.strength, a.ReferenceID, b.node
	from (select nn.ReferenceID, COUNT(*) as strength
			from casuser.nearest_neighbors as nn
			group by nn.ReferenceID
		 ) a,
		casuser.fastknn_data b,
		public.dbsmallm_truth c
		where
			a.ReferenceID = b.nodeid and
			b.node = c.drugbank_id;

	select * from casuser.candidates order by strength desc, name limit 20;
quit;

cas &sessionName terminate;

proc datasets library=work noprint;
	delete nearest_neighbors;
	delete fastknn_data;
	delete fastknn_query;
run;
quit;

%mend retrieve_candidates;

%retrieve_candidates(embeddings=embed.network1_embeddings);
%retrieve_candidates(embeddings=embed.network2_embeddings);
%retrieve_candidates(embeddings=embed.network3_embeddings);


