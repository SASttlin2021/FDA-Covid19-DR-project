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

OPTIONS SOURCE2 MPRINT MPRINTNEST CASDATALIMIT=500M;

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
caslib repositioning datasource=(srctype="path") path="&datapath/repositioning" sessref=&sessionName;
caslib gnbr          datasource=(srctype="path") path="&datapath/GNBR"          sessref=&sessionName;
/* caslib output        datasource=(srctype="path") path="&datapath/output"        sessref=&sessionName; */

/* Create temporary caslib for saving intermediate data */
caslib embedding   datasource=(srctype="path") path="&datapath/intermediate/embedding" sessref=&sessionName;

/* Bind sas libnames to caslibs so sas can read and write data in cas */
libname repo    cas caslib="repositioning";
libname embed   cas caslib="embedding"    ;
libname casuser cas caslib="casuser"      ;
/* libname public  cas caslib="public"       ; */
libname gnbr    cas caslib="gnbr"         ;
libname output  cas caslib="public"       ;

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
    load casdata="dbProteins.csv" casout="DBProteins" replace;
    load casdata="dbSmallM_Truth.csv" casout="dbsmallm_truth" replace;
    load casdata="stringPP.csv" casout="stringpp" replace;
    load casdata="Truth.csv" casout="truth" replace;
    load casdata="newTruth.csv" casout="newtruth" replace;
    load casdata="sars_cov_2_proteins.csv" casout="sars_cov_2_proteins" replace;
quit;

proc casutil incaslib="gnbr" outcaslib="gnbr" sessref="&sessionName";
    load casdata="GeneDiseaseComplete.csv" casout="GeneDiseaseComplete" replace
        vars=("UniProtID", "SecondEntityDBID");
quit;

data casuser.edges_drugbank_drug_protein / sessref="&sessionName";
    length head varchar(*) tail varchar(*);
    set repo.DBProteins;
    if drugbank_id ~= '.' and uniprot_id ~= '.';
    head = cat("drug:",drugbank_id);
    tail = cat("protein:",uniprot_id);
    source = 1;
    keep source head tail;
run;

data casuser.edges_string_protein_protein / sessref="&sessionName";
    length head varchar(*) tail varchar(*);
    set repo.stringpp;
    if UniProtID1 ~= '.' and UniProtID2 ~= '.';
    head = cat("protein:",UniProtID1);
    tail = cat("protein:",UniProtID2);
    source = 2;
    keep source head tail;
run;

data casuser.edges_cov2_disease_protein / sessref="&sessionName";
    length head varchar(*) tail varchar(*);
    set repo.sars_cov_2_proteins;
    if Preys ~= '.';
    head = &sars_cov_2;
    tail = cat("protein:",Preys);
    source = 3;
    keep source head tail;
run;

data casuser.edges_gnbr_protein_disease / sessref="&sessionName";
    length head varchar(*) tail varchar(*);
    set gnbr.genediseasecomplete;
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
/* %INCLUDE NETWORK(method1); */

/* 2. Drug-Protein and Protein-Protein subset   */
%INCLUDE NETWORK(method2);

/* 3. Drug-Protein and Protein-Protein full     */
%INCLUDE NETWORK(method3);

/* 4. Drug-Protein, Protein-Protein, and Protein-Disease */
%INCLUDE NETWORK(method4);

/* * * * * * * * * * Outputs * * * * * * * * * * * * * * * * */
proc fedsql sessref=&sessionName;
    create table casuser.all_drugs {options replace=true} as
    select name, drugbank_id
    from repositioning.dbsmallm_truth;

    create table casuser.all_clinical_trial_drugs {options replace=true} as
    select Trail_Drug as drugname,
            iDBID as drugbank_id,
            NewDrug
    from repositioning.newtruth
    where ProteinCount > 0;

    create table casuser.train {options replace=true} as
    select *
    from casuser.all_clinical_trial_drugs
    where NewDrug = 0;

    create table casuser.test {options replace=true} as
    select *
    from casuser.all_clinical_trial_drugs
    where NewDrug = 1;
quit;

data casuser.all_drugs / sessref=&sessionName;
  merge casuser.all_drugs casuser.train(in=intrain) casuser.test(in=intest);
  by drugbank_id;
  before=intrain;
  after=intest;
  keep name drugbank_id before after;
run;

%INCLUDE MACROS(candidates_knn);
/* %candidates_knn(embeddings=embed.factmac_embeddings,  output=factcandidates); */
/* %candidates_knn(embeddings=embed.network1_embeddings, output=repo.net1candidates, drugs=casuser.all_drugs); */
%candidates_knn(embeddings=embed.network2_embeddings, output=repo.net2candidates, drugs=casuser.all_drugs);
%candidates_knn(embeddings=embed.network3_embeddings, output=repo.net3candidates, drugs=casuser.all_drugs);
%candidates_knn(embeddings=embed.network4_embeddings, output=repo.net4candidates, drugs=casuser.all_drugs);

ods exclude none;

data casuser.all_drug_candidates / sessref=&sessionName;
	merge casuser.all_drugs /*repo.net1candidates(in=n1)*/ repo.net2candidates(in=n2)
          repo.net3candidates(in=n3) repo.net4candidates(in=n4);
	by drugbank_id;
	net1=n1; net2=n2; net3=n3; net4=n4;
	keep drugbank_id name before after net1 net2 net3 net4;
run;

%INCLUDE MACROS(score_candidates);
/* %score_candidates(candidates=net1, drugs=casuser.all_drug_candidates); */
%score_candidates(candidates=net2, drugs=casuser.all_drug_candidates);
%score_candidates(candidates=net3, drugs=casuser.all_drug_candidates);
%score_candidates(candidates=net4, drugs=casuser.all_drug_candidates);

%INCLUDE MACROS(tsne_vary);
/* %tsne_vary(embeddings=embed.network1_embeddings, dataout=output.VA1_net1_tsne_all, start=5, end=10, by=5, maxIters=1); */
%tsne_vary(embeddings=embed.network2_embeddings, dataout=output.VA1_net2_tsne_all, start=5, end=10, by=5, maxIters=1);
%tsne_vary(embeddings=embed.network3_embeddings, dataout=output.VA1_net3_tsne_all, start=5, end=10, by=5, maxIters=1);
%tsne_vary(embeddings=embed.network4_embeddings, dataout=output.VA1_net4_tsne_all, start=5, end=10, by=5, maxIters=1);

%INCLUDE MACROS(label_nodes);
/* %label_nodes(embeddings=output.VA1_net1_tsne_all, drugs=casuser.all_drug_candidates, candidate=net1); */
%label_nodes(embeddings=output.VA1_net2_tsne_all, drugs=casuser.all_drug_candidates, candidate=net2);
%label_nodes(embeddings=output.VA1_net3_tsne_all, drugs=casuser.all_drug_candidates, candidate=net3);
%label_nodes(embeddings=output.VA1_net4_tsne_all, drugs=casuser.all_drug_candidates, candidate=net4);

proc casutil;
	droptable incaslib="output" casdata="all_drug_candidates" quiet;
	promote incaslib="casuser" casdata="all_drug_candidates" outcaslib="output" casout="all_drug_candidates";
run;

%INCLUDE MACROS(candidates_distance);
%candidates_distance(embeddings=embed.network4_embeddings, output=net4candidates_ranked);

%INCLUDE MACROS(evaluate_ap);
%evaluate_ap(candidates=repo.net4candidates_ranked, test=casuser.all_clinical_trial_drugs, rankingCol=distance);

cas mainSession terminate;


