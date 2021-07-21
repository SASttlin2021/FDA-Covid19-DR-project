/***************************************************/
/*       Macro Variables for User to Set           */
/***************************************************/
/*All you are going to have to change on your end is the path to the code and data if the folders are different on your server*/

/* Path to where the code is saved, either on disk or the folderpath in SAS Content */
%let codepath=/home/sasdemo/FDA-Covid19-DR-project/sas;
/* Path to where the data is and will be saved. All caslibs should be a **subfolder** of this.*/
%let datapath=/home/sasdemo/FDA-Covid19-DR-project/data;

/*This establishes a CAS connection, again if you have a formal procedure for session names, server information, etc. you would put that here*/
%let sessionName=mainSession;
cas &sessionName;

/* Data Location */
/* Define caslib locations so that cas can read and write data on disk, they will neeed to be created on your end*/                             
/* Repositioning - this will be where we have the full data before its prepared for the modeling                 */
/* GNBR - this is the folder where we will have the GNBR source data before its prepared for the modeling        */
/* Prepared - this is where we will place the fully prepared datasets where the modelers will grab               */
                          
caslib repositioning datasource=(srctype="path") path="&datapath/repositioning" sessref=&sessionName;
caslib gnbr          datasource=(srctype="path") path="&datapath/GNBR"          sessref=&sessionName;
caslib prepared 	 datasource=(srctype="path") path="&datapath/prepared"      sessref=&sessionName;

/* Bind sas libnames to caslibs so sas can read and write data in cas */
libname repo    cas caslib="repositioning";
libname casuser cas caslib="casuser"      ;
libname public  cas caslib="public"       ;
libname gnbr    cas caslib="gnbr"         ;
libname output  cas caslib="output"       ;
libname prepared cas caslib="prepared"    ;


/* * * * * * * * * * Load Data * * * * * * * * * * * * * * * * */
/****************************************************************************************/
/* Generate model tables from our external tables, currently: 							*/
/* 	- ChemicalDiseaseComplete, Chemical-disease interactions 							*/
/* 	- ChemicalGeneUniprot, Chemical-Protein interactions 								*/
/* 	- GeneGeneUniprot, Gene-Gene interactions                                        	*/
/* 	- GeneDiseaseUniprot, Disease-Protein interactions from GNBR 						*/
/****************************************************************************************/
/*This code loads data from the gnbr source data caslib to cas for this session         */
proc casutil incaslib="gnbr" outcaslib="gnbr" sessref="&sessionName";
	load casdata="chemicaldiseasedependency.sas7bdat" casout="ChemicalDiseaseDependency"
		importoptions=(filetype="AUTO") replace;
	load casdata="chemicaldiseasepath.sas7bdat" casout="ChemicalDiseasePath"
		importoptions=(filetype="AUTO") replace;
	load casdata="chemicalgenedependency.sas7bdat" casout="ChemicalGeneDependency"
		importoptions=(filetype="AUTO") replace;
	load casdata="chemicalgenepath.sas7bdat" casout="ChemicalGenePath"
		importoptions=(filetype="AUTO") replace;
	load casdata="genegenedependency.sas7bdat" casout="GeneGeneDependency"
		importoptions=(filetype="AUTO") replace;
	load casdata="genegenepath.sas7bdat" casout="GeneGenePath"
		importoptions=(filetype="AUTO") replace;
	load casdata="part-i-gene-disease-path-theme-distributions.txt" casout="GeneDiseasePath"
    	importoptions=(filetype="csv" delimiter='09'x getnames=FALSE) replace;
  load casdata="part-ii-dependency-paths-gene-disease-sorted.txt" casout="GeneDiseaseDependency"
    	importoptions=(filetype="csv" delimiter='09'x getnames=FALSE) replace;
quit;

/*DONE WITH THE IMPORT STEP*/


/* * * * * * * * * * Cleanse the data * * * * * * * * * */
/*Rename variables for Dependency Paths Part-ii to fit the documentation*/
data gnbr.GeneDiseaseDependency;
  set gnbr.GeneDiseaseDependency;
  rename var1=PubmedID var2=SentenceNumber var3=FirstEntityName var4=FirstEntityLocation
         var5=SecondEntityName var6=SecondEntityLocation var7=FirstEntityRaw var8=SecondEntityRaw
         var9=FirstEntityDBID var10=SecondEntityDBID var11=FirstEntityType var12=SecondEntityType
         var13=DependencyPath var14=Sentence;

run;

/*Rename variables for connections from Part-i data based on the documentation*/
data gnbr.GeneDiseasePath;
  set gnbr.GeneDiseasePath;
  rename var1=DependencyPath var2=CasualMutations var3=CasualMutations_ind var4=MutationAffectDisease
         var5=MutationAffectDisease_ind var6=DrugTargets var7=DrugTargets_ind var8=PathogenesisRole
         var9=PathogenesisRole_ind var10=TherapeuticEffect var11=TherapeuticEffect_ind var12=Polymorphisms
         var13=Polymorphisms_ind var14=PromotesProgression var15=PromotesProgression_ind var16=Biomarkers
         var17=Biomarkers_ind var18=Overexpression var19=Overexpression_ind var20=ImproperRegulation
         var21=ImproperRegulation_ind;
run;


/*Need to also convert all dependency paths to lowercase so we can preform the necessary joins*/
/*This assumes there is a GNBR library already created*/
data GNBR.GeneGeneDependency(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.GeneGeneDependency;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath Sentence;
	rename Dependency_Path = DependencyPath;
run;

data GNBR.GeneGenePath(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.GeneGenePath;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath;
	rename Dependency_Path = DependencyPath;
run;

data GNBR.GeneDiseaseDependency(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.GeneDiseaseDependency;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath Sentence;
	rename Dependency_Path = DependencyPath;
run;

data GNBR.GeneDiseasePath(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.GeneDiseasePath;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath;
	rename Dependency_Path = DependencyPath;
run;

data GNBR.ChemicalDiseaseDependency(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.ChemicalDiseaseDependency;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath;
	rename Dependency_Path = DependencyPath;
run;

data GNBR.ChemicalDiseasePath(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.ChemicalDiseasePath;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath;
	rename Dependency_Path = DependencyPath;
run;

data GNBR.ChemicalGeneDependency(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.ChemicalGeneDependency;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath;
	rename Dependency_Path = DependencyPath;
run;

data GNBR.ChemicalGenePath(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.ChemicalGenePath;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath;
	rename Dependency_Path = DependencyPath;
run;


/*Once the datasets are in CAS with the standardized DependencyPath, its time to investigate the data and start parsing out the GeneIds from the Dependency datasets*/
data GNBR.ChemicalGeneDependency(replace=yes copies=0);
	set GNBR.ChemicalGeneDependency;
	if find(SecondEntityDBID, 'Tax') ge 1 then CleanFlag = 1;
	else CleanFlag = 0;
run;

/*Next steps: Pull out anything after 'Tax' starts and create its own field of taxonomy with the full string, so we can still have information around species type, 
after this we can move onto the GNBR Integration to pull together GNBR datasets*/

/*Extract Taxonomy ID from the SecondEntityDBID, once it's extracted we can remove the delimiters to just get the ID, also leaving blanks for DBIDs without Taxonomy*/
data GNBR.ChemicalGeneDependency(replace=yes copies=0);
	set GNBR.ChemicalGeneDependency;
	if CleanFlag = 1 then 
		do;
			Taxonomy=substr(SecondEntityDBID, index(SecondEntityDBID, ":"));
			Taxonomy=compress(Taxonomy,":)");	
		end;
		else Taxonomy=.;
run;

/*The next step is to remove the taxonomy IDs from the original SecondEntityDBID so that we can use these numbers to join with DrugBank*/
data GNBR.ChemicalGeneDependency(replace=yes copies=0);
	set GNBR.ChemicalGeneDependency;
	if CleanFlag = 1 then 
		do;
			SecondEntityDBID= scan(SecondEntityDBID,1, '(');
		end;
		else SecondEntityDBID=SecondEntityDBID;
run;

/*Parse out two IDs in field*/
data GNBR.ChemicalGeneDependency(replace=yes copies=0);
	set GNBR.ChemicalGenedependency;
	if Cleanflag = 0 then
		do;
			ID2=scan(SecondEntityDBID, 2,";");
			ID3=scan(SecondEntityDBID, 3, ";");
		end;
	else if CleanFlag = 1 then
		do;
			ID2=.;
			ID3=.;
		end;
	SecondEntityDBID=scan(SecondEntityDBID, 1, ";");	 
run;

/*Now that we have the Taxonomy extracted and the DB IDs cleaned its time to convert data types to prepare for joining and drop unneeded variables*/
data GNBR.ChemicalGeneDependency(replace=yes copies=0);
	length SecondEntityDBID_ 8;
	length Taxonomy_ 8;
	length ID2_ 8;
	length ID3_ 8;
	set GNBR.ChemicalGeneDependency;
	SecondEntityDBID_ = SecondEntityDBID;
	Taxonomy_ = Taxonomy;
	ID2_ = ID2;
	ID3_ = ID3;
	drop SecondEntityDBID Taxonomy SecondDBID CleanFlag else ID2 ID3;
	rename SecondEntityDBID_ = SecondEntityDBID;
	rename Taxonomy_ = Taxonomy;
	rename ID2_ = ID2;
	rename ID3_ = ID3;
run;

/*Join newly added GNBR CAS data together to create completed datasets of the Dendrograms Gene-Gene Gene-Disease Gene-Chemical Chemical-Disease*/
proc fedsql sessref=&sessionName;
	create table GNBR.GeneGeneComplete {options replace=true copies=0} as
	select GeneGenePath.*, GeneGeneDependency.FirstEntityName, GeneGeneDependency.FirstEntityDBID, 
	GeneGeneDependency.SecondEntityName, GeneGeneDependency.SecondEntityDBID
	from GNBR.GeneGenePath, GNBR.GeneGeneDependency 
	where GeneGenePath.DependencyPath = GeneGeneDependency.DependencyPath;
quit;

/*Join newly added GNBR CAS data together to create completed datasets of the Dendrograms Gene-Gene Gene-Disease Gene-Chemical Chemical-Disease*/
proc fedsql sessref=&sessionName;
	create table GNBR.GeneDiseaseComplete {options replace=true copies=0} as
	select GeneDiseasePath.*, GeneDiseaseDependency.FirstEntityName, GeneDiseaseDependency.FirstEntityDBID, 
	GeneDiseaseDependency.SecondEntityName, GeneDiseaseDependency.SecondEntityDBID
	from GNBR.GeneDiseasePath, GNBR.GeneDiseaseDependency 
	where GeneDiseasePath.DependencyPath = GeneDiseaseDependency.DependencyPath;
quit;

/*Join newly added GNBR CAS data together to create completed datasets of the Dendrograms Gene-Gene Gene-Disease Gene-Chemical Chemical-Disease*/
proc fedsql sessref=&sessionName;
	create table GNBR.ChemicalGeneComplete {options replace=true copies=0} as
	select ChemicalGenePath.*, ChemicalGeneDependency.FirstEntityName, ChemicalGeneDependency.FirstEntityDBID, 
	ChemicalGeneDependency.SecondEntityName, ChemicalGeneDependency.SecondEntityDBID, ChemicalGeneDependency.Taxonomy, ChemicalGeneDependency.Sentence
	from GNBR.ChemicalGenePath, GNBR.ChemicalGeneDependency 
	where ChemicalGenePath.DependencyPath = ChemicalGeneDependency.DependencyPath;
quit;

/*Join newly added GNBR CAS data together to create completed datasets of the Dendrograms Gene-Gene Gene-Disease Gene-Chemical Chemical-Disease*/
proc fedsql sessref=&sessionName;
	create table GNBR.ChemicalDiseaseComplete {options replace=true copies=0} as
	select ChemicalDiseasePath.*, ChemicalDiseaseDependency.FirstEntityName, ChemicalDiseaseDependency.FirstEntityDBID, 
	ChemicalDiseaseDependency.SecondEntityName, ChemicalDiseaseDependency.SecondEntityDBID, ChemicalDiseaseDependency.Sentence
	from GNBR.ChemicalDiseasePath, GNBR.ChemicalDiseaseDependency 
	where ChemicalDiseasePath.DependencyPath = ChemicalDiseaseDependency.DependencyPath;
quit;


/*This first join we are using the first GeneID extracted, we could use the second GeneID since its a Gene-Gene relationship but that would be up to the team*/
proc fedsql sessref=&sessionName;
	create table GNBR.GeneGeneUniprot {options replace=true copies=0} as
	select GeneGeneComplete.*, UniprotGeneIDS.GeneID, UniprotGeneIDS.UniProtID
	from GNBR.GeneGeneComplete left outer join public.UniprotGeneIDS
	on (GeneGeneComplete.SecondEntityDBID = UniprotGeneIDS.GeneID);
quit; 

/*We are joing this data on the first GeneID extracted, some instances there were multiple IDs but we are going off of the first one for now*/
proc fedsql sessref=&sessionName;
	create table  GNBR.ChemicalGeneUniprot {options replace=true copies=0} as
	select ChemicalGeneComplete.*, UniprotGeneIDS.GeneID, UniprotGeneIDS.UniProtID 
	from GNBR.ChemicalGeneComplete left outer join public.UniprotGeneIDS
	on (ChemicalGeneComplete.SecondEntityDBID = UniprotGeneIDS.GeneID);
quit; 

/*The final join is a bit more simple, only one GeneID from this Dendrogram, so we will do a join on that*/
proc fedsql sessref=&sessionName;
	create table GNBR.GeneDiseaseUniprot {options replace=true copies=0} as
	select GeneDiseaseComplete.*, UniprotGeneIDS.GeneID, UniprotGeneIDS.UniProtID 
	from GNBR.GeneDiseaseComplete left outer join public.UniprotGeneIDS
	on (GeneDiseaseComplete.FirstEntityDBID = UniprotGeneIDS.GeneID);
quit; 

/* * * * * * * * * * Load final data to the prepared cas lib for the modelers * * * * * * * * * */

proc casutil outcaslib="prepared" sessref=&sessionName;
	save casdata="GeneDiseaseUniprot" incaslib="gnbr" casout="GeneDiseaseUniprot.csv" replace;
	save casdata="ChemicalGeneUniprot" incaslib="gnbr" casout="ChemicalGeneUniprot.csv" replace;
	save casdata="GeneGeneUniprot" incaslib="gnbr" casout="GeneGeneUniprot.csv" replace;
	save casdata="ChemicalDiseaseComplete" incaslib="gnbr" casout="ChemicalDiseaseComplete.csv" replace;
quit; 

