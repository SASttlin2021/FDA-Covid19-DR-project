/********************************************/
/*     Macro Variables for User to Set      */
/********************************************/
%let parentpath=/home/sasdemo/FDA-Covid19-DR-project;
%let testscript=0;
%let parent=1;
/********************************************/

OPTIONS SOURCE2 MPRINT MPRINTNEST;

%let sessionName=mainSession;
cas &sessionName;

/* Code Location */
/* Defines the paths to other sas scripts so we can "%INCLUDE" them later */
filename FACTMAC "&parentpath/sas/factmac";
filename NETWORK "&parentpath/sas/network";
filename MACROS  "&parentpath/sas/macros" ;

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
/****************************************************************************************/
/* Generate edgelist from our external tables, currently: 								*/
/* 	- DBProteins, Drug-Protein interactions 											*/
/* 	- StringPP, Protein-Protein interactions 											*/
/* 	- SARS-CoV-2-Proteins, Disease-Protein interactions, specifically for SARS-CoV-2 	*/
/* 	- GeneDiseaseUniprot, Disease-Protein interactions from GNBR 						*/
/* Currently only keeping head and tail entities and not relationship type 				*/
/****************************************************************************************/
proc casutil incaslib="repositioning" outcaslib="repositioning" sessref="&sessionName";
	droptable casdata="DBProteins";
	droptable casdata="stringpp";
	droptable casdata="truth";

	load casdata="dbProteins.csv" casout="DBProteins" promote;
	load casdata="stringPP.csv" casout="stringpp" promote;
	load casdata="Truth.csv" casout="truth" promote;
quit;

data casuser.edges_drugbank_drug_protein;
	set repo.DBProteins;
	where drugbank_id and uniprot_id;
	head = cat("drug:",drugbank_id);
	tail = cat("protein:",uniprot_id);
	source = 1;
	keep source head tail;
run;

data casuser.edges_string_protein_protein;
	set repo.stringpp;
	where UniProtID1 and UniProtID2;
	head = cat("protein:",UniProtID1);
	tail = cat("protein:",UniProtID2);
	source = 2;
	keep source head tail;
run;

data casuser.edges_cov2_disease_protein;
	set repo.sars_cov_2_proteins;
	where Preys;
	head = &sars_cov_2;
	tail = cat("protein:",Preys);
	source = 3;
	keep source head tail;
run;

/* * * * * * * * * * PROC FACTMAC Embedding * * * * * * * * * */
/* %INCLUDE FACTMAC("LoadEdgelist.sas"); */
/* %INCLUDE FACTMAC("SampleNegativeEdgelist.sas"); */
/* %INCLUDE FACTMAC("LearnFactmacEmbeddings.sas"); /* writes to embed.factmac_embeddings */


/* * * * * * * * * * PROC NETWORK Embedding  * * * * * * * * */
/* 1. Drug-Protein Only, Bipartite projection  */
%INCLUDE NETWORK(method1);

/* 2. Drug-Protein and Protein-Protein subset   */
%INCLUDE NETWORK(method2);

/* 3. Drug-Protein and Protein-Protein full     */
%INCLUDE NETWORK(method3);

/* 4. Drug-Protein, weighted by Protein-Protein */

/* * * * * * * * * * Outputs * * * * * * * * * * * * * * * * */
%INCLUDE MACROS(candidates_knn);
%candidates_knn(embeddings=embed.factmac_embeddings,  output=factcandidates);
%candidates_knn(embeddings=embed.network1_embeddings, output=net1candidates);
%candidates_knn(embeddings=embed.network2_embeddings, output=net2candidates);
%candidates_knn(embeddings=embed.network3_embeddings, output=net3candidates);

%INCLUDE MACROS(tsne_vary);
/* %tsne_vary(datain=network1_embeddings, dataout=network1_tsne, start=5, end=50, by=5, maxIters=1); */
/* %tsne_vary(datain=network2_embeddings, dataout=network2_tsne, start=5, end=50, by=5, maxIters=1); */
/* %tsne_vary(datain=network3_embeddings, dataout=network3_tsne, start=5, end=50, by=5, maxIters=1, drugsonly=1); */

cas mainSession terminate;


