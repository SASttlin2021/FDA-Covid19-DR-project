/********************************************/
/*     Macro Variables for User to Set      */
/********************************************/
/* Path to where the code is saved, either on disk or the folderpath in SAS content */
%let codepath=/home/sasdemo/FDA-Covid19-DR-project/sas;
/* Path to where the data is and will be saved. All caslibs should be a **subfolder** of this.*/
%let datapath=/home/sasdemo/FDA-Covid19-DR-project/data;
/* Is the sas code saved in SAS content or on disk? */
%let files_in_content = 0;
/* Run script in test mode when 1, is quicker and doesnt write to disk.*/
%let testscript=0;
/* Run the data prep steps when 1. This is slow and unnecesary if source data has not changed.*/
%let prep=0;
/********************************************/

OPTIONS SOURCE2 MPRINT MPRINTNEST;

%let sessionName=mainSession;
cas &sessionName;

%let sars_cov_2="MESH:D000086402";
%let parent=1;

/* Code Location */
/* Defines the paths to other sas scripts so we can "%INCLUDE" them later */
%if &files_in_content %then %do;
    filename MAIN    filesrvc folderpath="&codepath"
    filename FACTMAC filesrvc folderpath="&codepath/factmac";
    filename NETWORK filesrvc folderpath="&codepath/network";
    filename MACROS  filesrvc folderpath="&codepath/macros" ;
%end; %else %do;
    filename MAIN	 "&codepath";
    filename FACTMAC "&codepath/factmac";
    filename NETWORK "&codepath/network";
    filename MACROS  "&codepath/macros" ;
%end;

/* Data Location */
/* Define caslib locations so that cas can read and write data on disk                      */
/*     - repositioning: the source data (after cleaning)                                    */
/*     - embedding: where we land the embeddings from our various methods                   */
/*     - visualization: where tables to be visualized in Visual Analytics go                */
caslib repositioning datasource=(srctype="path") path="&datapath/repositioning" global sessref=&sessionName;
caslib gnbr          datasource=(srctype="path") path="&datapath/GNBR"          global sessref=&sessionName;
caslib output        datasource=(srctype="path") path="&datapath/output"        global sessref=&sessionName;

/* Create temporary caslib for saving intermediate data */
caslib embedding   datasource=(srctype="path") path="&datapath/intermediate/embedding" global sessref=&sessionName;

/* Bind sas libnames to caslibs so sas can read and write data in cas */
libname repo    cas caslib="repositioning";
libname embed   cas caslib="embedding"    ;
libname casuser cas caslib="casuser"      ;
libname public  cas caslib="public"       ;
libname gnbr    cas caslib="gnbr"         ;
libname output  cas caslib="output"       ;

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
    %INCLUDE MAIN(gnbr_small);
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

/* 4. Drug-Protein, Protein-Protein, and Protein-Disease */
%INCLUDE NETWORK(method4);

/* * * * * * * * * * Outputs * * * * * * * * * * * * * * * * */
%INCLUDE MACROS(candidates_knn);
/* %candidates_knn(embeddings=embed.factmac_embeddings,  output=factcandidates); */
%candidates_knn(embeddings=embed.network1_embeddings, output=net1candidates);
%candidates_knn(embeddings=embed.network2_embeddings, output=net2candidates);
%candidates_knn(embeddings=embed.network3_embeddings, output=net3candidates);
%candidates_knn(embeddings=embed.network4_embeddings, output=net4candidates);

%INCLUDE MACROS(candidates_distance);
%candidates_distance(embeddings=embed.network4_embeddings, output=net4candidates2);

%INCLUDE MACROS(tsne_vary);
%tsne_vary(embeddings=embed.network1_embeddings, dataout=output.VA1_net1_tsne_all, start=5, end=10, by=5, maxIters=1);
/* %tsne_vary(embeddings=embed.network2_embeddings, dataout=output.VA1_net2_tsne_all, start=5, end=50, by=5, maxIters=1); */
/* %tsne_vary(embeddings=embed.network3_embeddings, dataout=output.VA1_net3_tsne_all_drugsonly, start=5, end=50, by=5, maxIters=1, drugsonly=1); */
/* %tsne_vary(embeddings=embed.network4_embeddings, dataout=output.VA1_net4_tsne_all_drugsonly, start=5, end=50, by=5, maxIters=1, drugsonly=1); */

%INCLUDE MACROS(evaluate_ap);
%evaluate_ap(repo.net4candidates2, repo.truth, distance);

cas mainSession terminate;


