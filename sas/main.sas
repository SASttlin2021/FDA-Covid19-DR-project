/********************************************/
/*     Macro Variables for User to Set      */
/********************************************/
%let parentpath=/home/sasdemo/FDA-Covid19-DR-project;
%let testscript=0;
%let parent=1;
%let prep=0;
/********************************************/

OPTIONS SOURCE2 MPRINT MPRINTNEST;

%let sessionName=mainSession;
cas &sessionName;

%let sars_cov_2="MESH:D000086402";

/* Code Location */
/* Defines the paths to other sas scripts so we can "%INCLUDE" them later */
filename MAIN	 "&parentpath/sas";
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
caslib gnbr          datasource=(srctype="path") path="&parentpath/data/GNBR"          global sessref=&sessionName;

/* Create temporary caslib for saving intermediate data */
caslib checkpoint    datasource=(srctype="path") path="&parentpath/data/checkpoint"    global sessref=&sessionName;

/* Bind sas libnames to caslibs so sas can read and write data in cas */
libname repo    cas caslib="repositioning";
libname embed   cas caslib="embedding"    ;
libname visual  cas caslib="visualization";
libname casuser cas caslib="casuser"      ;
libname public  cas caslib="public"       ;
libname gnbr    cas caslib="gnbr"         ;
libname check   cas caslib="checkpoint"   ;

/* * * * * * * * * * Load Data * * * * * * * * * * * * * * * * */
/****************************************************************************************/
/* Generate edgelist from our external tables, currently: 								*/
/* 	- DBProteins, Drug-Protein interactions 											*/
/* 	- StringPP, Protein-Protein interactions 											*/
/* 	- SARS-CoV-2-Proteins, Disease-Protein interactions, specifically for SARS-CoV-2 	*/
/* 	- GeneDiseaseUniprot, Disease-Protein interactions from GNBR 						*/
/* Currently only keeping head and tail entities and not relationship type 				*/
/****************************************************************************************/
%if &prep %then %do;
    %INCLUDE MAIN("GNBRSmall.sas");
%end;

proc casutil incaslib="repositioning" outcaslib="repositioning" sessref="&sessionName";
    droptable casdata="DBProteins";
    droptable casdata="stringpp";
    droptable casdata="truth";
	droptable casdata="sars_cov_2_proteins";

    load casdata="dbProteins.csv" casout="DBProteins" promote;
    load casdata="stringPP.csv" casout="stringpp" promote;
    load casdata="Truth.csv" casout="truth" promote;
	load casdata="sars_cov_2_proteins.csv" casout="sars_cov_2_proteins" promote;
quit;

proc casutil incaslib="gnbr" outcaslib="gnbr" sessref="&sessionName";
    droptable casdata="GeneDiseaseComplete";

    load casdata="GeneDiseaseComplete.csv" casout="GeneDiseaseComplete" promote
        vars=("UniProtID", "SecondEntityDBID");
quit;

data casuser.edges_drugbank_drug_protein;
    length head varchar(*) tail varchar(*);
    set repo.DBProteins;
    where drugbank_id and uniprot_id;
    head = cat("drug:",drugbank_id);
    tail = cat("protein:",uniprot_id);
    source = 1;
    keep source head tail;
run;

data casuser.edges_string_protein_protein;
    length head varchar(*) tail varchar(*);
    set repo.stringpp;
    where UniProtID1 and UniProtID2;
    head = cat("protein:",UniProtID1);
    tail = cat("protein:",UniProtID2);
    source = 2;
    keep source head tail;
run;

data casuser.edges_cov2_disease_protein;
    length head varchar(*) tail varchar(*);
    set repo.sars_cov_2_proteins;
    where Preys;
    head = &sars_cov_2;
    tail = cat("protein:",Preys);
    source = 3;
    keep source head tail;
run;

data casuser.edges_gnbr_protein_disease;
    length head varchar(*) tail varchar(*);
    set gnbr.genediseasecomplete;
/* 	where UniProtID and SecondEntityDBID; */
    head = cat("protein:",UniProtID);
    tail = SecondEntityDBID;
    source = 4;
    keep source head tail;
run;

/* * * * * * * * * * PROC FACTMAC Embedding * * * * * * * * * */
%INCLUDE FACTMAC("LoadEdgelist.sas");
%INCLUDE FACTMAC("SampleNegativeEdgelist.sas");
%INCLUDE FACTMAC("LearnFactmacEmbeddings.sas"); /* writes to embed.factmac_embeddings */


/* * * * * * * * * * PROC NETWORK Embedding  * * * * * * * * */
/* 1. Drug-Protein Only, Bipartite projection  */
%INCLUDE NETWORK(method1);

/* 2. Drug-Protein and Protein-Protein subset   */
%INCLUDE NETWORK(method2);

/* 3. Drug-Protein and Protein-Protein full     */
%INCLUDE NETWORK(method3);

/* 4. Drug-Protein, weighted by Protein-Protein */

/* 5. Drug-Protein, Protein-Protein, and Protein-Disease */
%INCLUDE NETWORK(method5);

/* * * * * * * * * * Outputs * * * * * * * * * * * * * * * * */
%INCLUDE MACROS(candidates_knn);
%candidates_knn(embeddings=embed.factmac_embeddings,  output=factcandidates);
%candidates_knn(embeddings=embed.network1_embeddings, output=net1candidates);
%candidates_knn(embeddings=embed.network2_embeddings, output=net2candidates);
%candidates_knn(embeddings=embed.network3_embeddings, output=net3candidates);
%candidates_knn(embeddings=embed.network5_embeddings, output=net5candidates);

%INCLUDE MACROS(candidates_distance);
%candidates_distance(embeddings=embed.network5_embeddings, output=net5candidates2);

%INCLUDE MACROS(tsne_vary);
/* %tsne_vary(datain=network1_embeddings, dataout=network1_tsne, start=5, end=50, by=5, maxIters=1); */
/* %tsne_vary(datain=network2_embeddings, dataout=network2_tsne, start=5, end=50, by=5, maxIters=1); */
/* %tsne_vary(datain=network3_embeddings, dataout=network3_tsne, start=5, end=50, by=5, maxIters=1, drugsonly=1); */

%INCLUDE MACROS(evaluate_ap);
%evaluate_ap(repo.net5candidates2, repo.truth, distance);

cas mainSession terminate;


