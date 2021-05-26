/* Initialize CAS Session */

%if %symexist(parent) %then %do;
	%end;
%else %do;
	%put localSession;
	%let sessionName = localSession;
	cas &sessionName;
	libname public cas caslib="public";
	libname casuser cas caslib="casuser";
	%end;

/* MESH ID for SARS-CoV-2, our disease of interest */
%let sars_cov_2 = "MESH:D000086402";

/****************************************************************************************/
/* Generate edgelist from our external tables, currently: 								*/
/* 	- DBProteins, Drug-Protein interactions 											*/
/* 	- StringPP, Protein-Protein interactions 											*/
/* 	- SARS-CoV-2-Proteins, Disease-Protein interactions, specifically for SARS-CoV-2 	*/
/* 	- GeneDiseaseUniprot, Disease-Protein interactions from GNBR 						*/
/* Currently only keeping head and tail entities and not relationship type 				*/
/****************************************************************************************/

data casuser.edges1;
	set repo.DBProteins;
	where drugbank_id and uniprot_id;
	head = cat("drugbank:",drugbank_id);
	tail = cat("uniprot:",uniprot_id);
	source = 1;
	keep source head tail;
run;

data casuser.edges2;
	set repo.stringpp;
	where UniProtID1 and UniProtID2;
	head = cat("uniprot:",UniProtID1);
	tail = cat("uniprot:",UniProtID2);
	source = 2;
	keep source head tail;
run;

data casuser.edges3;
	set repo.sars_cov_2_proteins;
	where Preys;
	head = &sars_cov_2;
	tail = cat("uniprot:",Preys);
	source = 3;
	keep source head tail;
run;

/* data casuser.edges4; */
/* 	set public.genediseaseuniprott; */
/* 	where SecondEntityDBID ~= 'MESH' and UniProtID; */
/* 	head = SecondEntityDBID; */
/* 	tail = cat("uniprot:",UniProtID); */
/* 	source = 4; */
/* 	keep source head tail; */
/* run; */

/*
 * Concatenate each of the edgelists into one full graph
 */

data casuser.edges;
	set casuser.edges:;
	length head_v varchar(*) tail_v varchar(*);
	head_v = head;
	tail_v = tail;
	drop head tail;
run;

data casuser.edges;
	set casuser.edges;
	rename head_v=head tail_v=tail;
run;

/* Remove duplicates and sort edgelist. Useful for later processing */
proc sort data=casuser.edges out=casuser.edges nodupkey;
	by head tail;
run;

/****************************************************************/
/* Generate node table from edgelist. Current node types are: 	*/
/* 	- Drug 														*/
/* 	- Protein 													*/
/* 	- Disease 													*/
/****************************************************************/

proc fedsql sessref=&sessionName;
	drop table casuser.edges1 force;
	drop table casuser.edges2 force;
	drop table casuser.edges3 force;
	drop table casuser.edges4 force;

	drop table casuser.nodes force;
	create table nodes as select distinct node from (
		select distinct head as node from casuser.edges
		union
		select distinct tail as node from casuser.edges
	) a;
quit;

data casuser.nodes;
	set casuser.nodes;
	type = scan(node, 1, ":");
run;

/* Save edge and node tables to disk */
proc casutil incaslib="casuser" outcaslib="repositioning";
	save casdata="edges" casout="edges.csv" replace;
	save casdata="nodes" casout="nodes.csv" replace;
quit;

%if &sessionName = "localSession" %then %do;
	cas &sessionName terminate;
	%symdel sessionName;
	%end;
