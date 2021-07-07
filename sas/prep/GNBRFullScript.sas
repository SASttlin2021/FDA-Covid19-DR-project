/*Pull in Data sources from the server*/
/*In this current version, files need to be manually uploaded to the server from the GNBR website and then brought in via proc import*/
proc import datafile = "/opt/sas/viya/config/data/cas/default/public/GNBR/part-i-chemical-disease-path-theme-distributions.txt"
 out = work.ChemicalDiseasePath
 dbms = dlm
 replace;
 getnames=no;
 delimiter = '09'x;
run;
proc import datafile = "/opt/sas/viya/config/data/cas/default/public/GNBR/part-i-chemical-gene-path-theme-distributions.txt"
 out = work.ChemicalGenePath
 dbms = dlm
 replace;
 getnames=no;
 delimiter = '09'x;
run;
proc import datafile = "/opt/sas/viya/config/data/cas/default/public/GNBR/part-i-gene-disease-path-theme-distributions.txt"
 out = work.GeneDiseasePath
 dbms = dlm
 replace;
 getnames=no;
 delimiter = '09'x;
run;
proc import datafile = "/opt/sas/viya/config/data/cas/default/public/GNBR/part-i-gene-gene-path-theme-distributions.txt"
 out = work.GeneGenePath
 dbms = dlm
 replace;
 getnames=no;
 delimiter = '09'x;
run;
proc import datafile = "/opt/sas/viya/config/data/cas/default/public/GNBR/part-ii-dependency-paths-chemical-disease-sorted-with-themes.txt"
 out = work.ChemicalDiseaseDependencyThemes
 dbms = dlm
 replace;
 Getnames = No;
 delimiter = '09'x;
run;
proc import datafile = "/opt/sas/viya/config/data/cas/default/public/GNBR/part-ii-dependency-paths-chemical-disease-sorted.txt"
 out = work.ChemicalDiseaseDependency
 dbms = dlm
 replace;
 Getnames = No;
 delimiter = '09'x;
run;
proc import datafile = "/opt/sas/viya/config/data/cas/default/public/GNBR/part-ii-dependency-paths-chemical-gene-sorted-with-themes.txt"
 out = work.ChemicalGeneDependencyThemes
 dbms = dlm
 replace;
 Getnames = No;
 delimiter = '09'x;
run;
proc import datafile = "/opt/sas/viya/config/data/cas/default/public/GNBR/part-ii-dependency-paths-chemical-gene-sorted.txt"
 out = work.ChemicalGeneDependency
 dbms = dlm
 replace;
 Getnames = No;
 delimiter = '09'x;
run;
proc import datafile = "/opt/sas/viya/config/data/cas/default/public/GNBR/part-ii-dependency-paths-gene-gene-sorted-with-themes.txt"
 out = work.GeneGeneDependencyThemes
 dbms = dlm
 replace;
 Getnames = No;
 delimiter = '09'x;
run;
proc import datafile = "/opt/sas/viya/config/data/cas/default/public/GNBR/part-ii-dependency-paths-gene-gene-sorted.txt"
 out = work.GeneGeneDependency
 dbms = dlm
 replace;
 Getnames = No;
 delimiter = '09'x;
run;

proc import datafile = "/opt/sas/viya/config/data/cas/default/public/GNBR/part-ii-dependency-paths-gene-disease-sorted.txt"
 out = work.GeneDiseaseDependency
 dbms = dlm
 replace;
 Getnames = No;
 delimiter = '09'x;
run;

/*Relabel Data from original coding in data sources*/
/*Rename variables for Dependency Paths Part-ii to fit the documentation*/
data work.ChemicalDiseaseDependency;
	set work.ChemicalDiseaseDependency;
	rename var1=PubmedID var2=SentenceNumber var3=FirstEntityName var4=FirstEntityLocation var5=SecondEntityName var6=SecondEntityLocation var7=FirstEntityRaw 
    var8=SecondEntityRaw var9=FirstEntityDBID var10=SecondEntityDBID var11=FirstEntityType var12=SecondEntityType var13=DependencyPath var14=Sentence;
run;

data work.ChemicalGeneDependency;
	set work.ChemicalGeneDependency;
	rename var1=PubmedID var2=SentenceNumber var3=FirstEntityName var4=FirstEntityLocation var5=SecondEntityName var6=SecondEntityLocation var7=FirstEntityRaw 
    var8=SecondEntityRaw var9=FirstEntityDBID var10=SecondEntityDBID var11=FirstEntityType var12=SecondEntityType var13=DependencyPath var14=Sentence;
run;

data work.GeneGeneDependency;
	set work.GeneGeneDependency;
	rename var1=PubmedID var2=SentenceNumber var3=FirstEntityName var4=FirstEntityLocation var5=SecondEntityName var6=SecondEntityLocation var7=FirstEntityRaw 
    var8=SecondEntityRaw var9=FirstEntityDBID var10=SecondEntityDBID var11=FirstEntityType var12=SecondEntityType var13=DependencyPath var14=Sentence;
run;

data work.GeneDiseaseDependency;
	set work.GeneDiseaseDependency;
	rename var1=PubmedID var2=SentenceNumber var3=FirstEntityName var4=FirstEntityLocation var5=SecondEntityName var6=SecondEntityLocation var7=FirstEntityRaw 
    var8=SecondEntityRaw var9=FirstEntityDBID var10=SecondEntityDBID var11=FirstEntityType var12=SecondEntityType var13=DependencyPath var14=Sentence;
run;

/*Rename variables for connections from Part-i data*/
data work.ChemicalDiseasePath;
	set work.ChemicalDiseasePath;
	rename var4=InhibitsCellGrowth var5=CellGrowth_ind var12=PathogenesisRole var13=Pathogenesis_ind var14=Biomarkers var15=Biomarkers_ind var10=Alleviates 
	var11=Alleviates_ind var1=DependencyPath var8=Prevents var9=Prevents_ind var6=SideEffects var7=SideEffects_ind var2=Treatment var3=Treatment_ind;
	If _N_ = 1 then delete;
run;

data work.ChemicalGenePath;
	set work.ChemicalGenePath;
	rename var1=DependencyPath var2=Agonism var3=Agonism_ind var4=Antagonism var5=Antagonism_ind var6=BindingLigand var7=BindingLigand_ind
	var8=IncreaseExpression var9=IncreaseExpression_ind var10=DecreaseExpression var11=DecreaseExpression_ind var12=AffectsExpression var13=AffectsExpression_ind 
	var14=Inhibits var15=Inhibits_ind var16=Transport var17=Transport_ind var18=Metabolism var19=Metabolism_ind var20=EnzymeActivity var21=EnzymeActivity_ind;
	If _N_ = 1 then delete;
run;

data work.GeneDiseasePath;
	set work.GeneDiseasePath;
	rename var1=DependencyPath var2=CasualMutations var3=CasualMutations_ind var4=MutationAffectDisease var5=MutationAffectDisease_ind var6=DrugTargets var7=DrugTargets_ind 
	var8=PathogenesisRole var9=PathogenesisRole_ind var10=TherapeuticEffect var11=TherapeuticEffect_ind var12=Polymorphisms var13=Polymorphisms_ind 
	var14=PromotesProgression var15=PromotesProgression_ind var16=Biomarkers var17=Biomarkers_ind var18=Overexpression var19=Overexpression_ind var20=ImproperRegulation var21=ImproperRegulation_ind;
	If _N_ = 1 then delete;
run;

data work.GeneGenePath;
	set work.GeneGenePath;
	rename var1=DependencyPath var2=BindingLigand var3=BindingLigand_ind var4=EnhancesResponse var5=EnhancesResponse_ind var6=Activates var7=Activates_ind 
	var8=IncreasesExpression var9=IncreasesExpression_ind var10=AffectsExpression var11=AffectsExpression_ind var12=SignalingPathway var13=SignalingPathway_ind 
	var14=SameComplex var15=SameComplex_ind var16=Regulation var17=Regulation_ind var18=CellPopProduction var19=CellPopProduction_ind;
	If _N_ = 1 then delete;
run;

/*Load up caslibs and connect to CAS*/
/*Create CAS session and set mycas to active CASLib*/
cas casauto sessopts=(caslib='casuser');
libname mycas cas readtransfersize=1000; /*Used for just our race image to deal with memory issues*/


/*caslib GNBR datasource=(srctype="path") path="/opt/sas/viya/config/data/cas/default/public/GNBR/" global;*/

proc casutil;
	load data=work.ChemicalDiseasePath outcaslib="mycas"
	casout="Chemical_Disease_Path" replace;
run;
proc casutil;
	load data=work.ChemicalGenePath outcaslib="mycas"
	casout="Chemical_Gene_Path" replace;
run;
proc casutil;
	load data=work.GeneDiseasePath outcaslib="mycas"
	casout="Gene_Disease_Path" replace;
run;
proc casutil;
	load data=work.GeneGenePath outcaslib="mycas"
	casout="Gene_Gene_Path" replace;
run;
proc casutil;
	load data=work.GeneGeneDependency outcaslib="mycas"
	casout="Gene_Gene_Dependency" replace;
run;

proc casutil;
	load data=work.ChemicalGeneDependency outcaslib="mycas"
	casout="Chemical_Gene_Dependency" replace;
run;

proc casutil;
	load data=work.ChemicalDiseaseDependency outcaslib="mycas"
	casout="Chemical_Disease_Dependency" replace;
run;
proc casutil;
	load data=work.GeneDiseaseDependency outcaslib="mycas"
	casout="Gene_Disease_Dependency" replace;
run;

/*Clear Work Directory For Space*/
proc datasets library=work kill nolist;
/*DONE WITH THE IMPORT STEP*/
/*Transfer Data from SAS compute engine to CAS, change dependency path variable, dropping the raw sentance, and making 0 in memory copies to save space*/
/*Need to also convert all dependency paths to lowercase so we can preform the necessary joins*/
/*This assumes there is a GNBR library already created*/
data mycas.GeneGeneDependency(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.GeneGeneDependency;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath Sentence;
	rename Dependency_Path = DependencyPath;
run;

data mycas.GeneGenePath(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.GeneGenePath;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath;
	rename Dependency_Path = DependencyPath;
run;

data mycas.GeneDiseaseDependency(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.GeneDiseaseDependency;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath Sentence;
	rename Dependency_Path = DependencyPath;
run;

data mycas.GeneDiseasePath(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.GeneDiseasePath;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath;
	rename Dependency_Path = DependencyPath;
run;

data mycas.ChemicalDiseaseDependency(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.ChemicalDiseaseDependency;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath;
	rename Dependency_Path = DependencyPath;
run;

data mycas.ChemicalDiseasePath(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.ChemicalDiseasePath;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath;
	rename Dependency_Path = DependencyPath;
run;

data mycas.ChemicalGeneDependency(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.ChemicalGeneDependency;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath;
	rename Dependency_Path = DependencyPath;
run;

data mycas.ChemicalGenePath(replace=yes copies=0);
	length Dependency_Path varchar(200);
	set GNBR.ChemicalGenePath;
	Dependency_Path = lowcase(DependencyPath);
	drop DependencyPath;
	rename Dependency_Path = DependencyPath;
run;

/*Once the datasets are in CAS with the standardized DependencyPath, its time to investigate the data and start parsing out the GeneIds from the Dependency datasets*/
data mycas.ChemicalGeneDependency(replace=yes copies=0);
	set mycas.ChemicalGeneDependency;
	if find(SecondEntityDBID, 'Tax') ge 1 then CleanFlag = 1;
	else CleanFlag = 0;
run;
/*Next steps: Pull out anything after 'Tax' starts and create its own field of taxonomy with the full string, so we can still have information around species type, 
after this we can move onto the GNBR Integration to pull together GNBR datasets*/

/*Extract Taxonomy ID from the SecondEntityDBID, once it's extracted we can remove the delimiters to just get the ID, also leaving blanks for DBIDs without Taxonomy*/
data mycas.ChemicalGeneDependency(replace=yes copies=0);
	set mycas.ChemicalGeneDependency;
	if CleanFlag = 1 then 
		do;
			Taxonomy=substr(SecondEntityDBID, index(SecondEntityDBID, ":"));
			Taxonomy=compress(Taxonomy,":)");	
		end;
		else Taxonomy=.;
run;

/*The next step is to remove the taxonomy IDs from the original SecondEntityDBID so that we can use these numbers to join with DrugBank*/
data mycas.ChemicalGeneDependency(replace=yes copies=0);
	set mycas.ChemicalGeneDependency;
	if CleanFlag = 1 then 
		do;
			SecondEntityDBID= scan(SecondEntityDBID,1, '(');
		end;
		else SecondEntityDBID=SecondEntityDBID;
run;

/*Parse out two IDs in field*/
data mycas.ChemicalGeneDependency(replace=yes copies=0);
	set mycas.ChemicalGenedependency;
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
data mycas.ChemicalGeneDependency(replace=yes copies=0);
	length SecondEntityDBID_ 8;
	length Taxonomy_ 8;
	length ID2_ 8;
	length ID3_ 8;
	set mycas.ChemicalGeneDependency;
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

/*Make sure the run this code before doing any joins, this will bring your data from mycas to casuser so you can do the FedSQL joins*/
cas casauto sessopts=(Timeout=9700 LOCALE="en_US" caslib=PUBLIC);
caslib _all_ assign;

/*Join newly added GNBR CAS data together to create completed datasets of the Dendrograms Gene-Gene Gene-Disease Gene-Chemical Chemical-Disease*/
proc fedsql sessref=casauto;
	create table casuser.GeneGeneComplete {options replace=true copies=0} as
	select GeneGenePath.*, GeneGeneDependency.FirstEntityName, GeneGeneDependency.FirstEntityDBID, 
	GeneGeneDependency.SecondEntityName, GeneGeneDependency.SecondEntityDBID
	from casuser.GeneGenePath, casuser.GeneGeneDependency 
	where GeneGenePath.DependencyPath = GeneGeneDependency.DependencyPath;
quit;

/*Join newly added GNBR CAS data together to create completed datasets of the Dendrograms Gene-Gene Gene-Disease Gene-Chemical Chemical-Disease*/
proc fedsql sessref=casauto;
	create table casuser.GeneDiseaseComplete {options replace=true copies=0} as
	select GeneDiseasePath.*, GeneDiseaseDependency.FirstEntityName, GeneDiseaseDependency.FirstEntityDBID, 
	GeneDiseaseDependency.SecondEntityName, GeneDiseaseDependency.SecondEntityDBID
	from casuser.GeneDiseasePath, casuser.GeneDiseaseDependency 
	where GeneDiseasePath.DependencyPath = GeneDiseaseDependency.DependencyPath;
quit;

/*Join newly added GNBR CAS data together to create completed datasets of the Dendrograms Gene-Gene Gene-Disease Gene-Chemical Chemical-Disease*/
proc fedsql sessref=casauto;
	create table casuser.ChemicalGeneComplete {options replace=true copies=0} as
	select ChemicalGenePath.*, ChemicalGeneDependency.FirstEntityName, ChemicalGeneDependency.FirstEntityDBID, 
	ChemicalGeneDependency.SecondEntityName, ChemicalGeneDependency.SecondEntityDBID, ChemicalGeneDependency.Taxonomy, ChemicalGeneDependency.Sentence
	from casuser.ChemicalGenePath, casuser.ChemicalGeneDependency 
	where ChemicalGenePath.DependencyPath = ChemicalGeneDependency.DependencyPath;
quit;

/*Join newly added GNBR CAS data together to create completed datasets of the Dendrograms Gene-Gene Gene-Disease Gene-Chemical Chemical-Disease*/
proc fedsql sessref=casauto;
	create table casuser.ChemicalDiseaseComplete {options replace=true copies=0} as
	select ChemicalDiseasePath.*, ChemicalDiseaseDependency.FirstEntityName, ChemicalDiseaseDependency.FirstEntityDBID, 
	ChemicalDiseaseDependency.SecondEntityName, ChemicalDiseaseDependency.SecondEntityDBID, ChemicalDiseaseDependency.Sentence
	from casuser.ChemicalDiseasePath, casuser.ChemicalDiseaseDependency 
	where ChemicalDiseasePath.DependencyPath = ChemicalDiseaseDependency.DependencyPath;
quit;

/*Load in Uniprot CSV of GeneIDs*/
proc casutil;
	load file="/opt/sas/viya/config/data/cas/default/public/FDA/UniProtGeneIDs.csv" 
	outcaslib="Casuser" casout="UniprotGeneID";
run;

/*This first join we are using the first GeneID extracted, we could use the second GeneID since its a Gene-Gene relationship but that would be up to the team*/
proc fedsql sessref=casauto;
	create table casuser.GeneGeneUniprot {options replace=true copies=0} as
	select GeneGeneComplete.*, UniprotGeneID.GeneID, UniprotGeneID.UniProtID
	from casuser.GeneGeneComplete left outer join casuser.UniprotGeneID
	on (GeneGeneComplete.SecondEntityDBID = UniprotGeneID.GeneID);
quit; 

/*We are joing this data on the first GeneID extracted, some instances there were multiple IDs but we are going off of the first one for now*/
proc fedsql sessref=casauto;
	create table  casuser.ChemicalGeneUniprot {options replace=true copies=0} as
	select ChemicalGeneComplete.*, UniprotGeneID.GeneID, UniprotGeneID.UniProtID 
	from casuser.ChemicalGeneComplete left outer join casuser.UniprotGeneID
	on (ChemicalGeneComplete.SecondEntityDBID = UniprotGeneID.GeneID);
quit; 

/*The final join is a bit more simple, only one GeneID from this Dendrogram, so we will do a join on that*/
proc fedsql sessref=casauto;
	create table casuser.GeneDiseaseUniprot {options replace=true copies=0} as
	select GeneDiseaseComplete.*, UniprotGeneID.GeneID, UniprotGeneID.UniProtID 
	from casuser.GeneDiseaseComplete left outer join casuser.UniprotGeneID
	on (GeneDiseaseComplete.FirstEntityDBID = UniprotGeneID.GeneID);
quit; 

/*Now we can drop the unneeded tables in the casuser library to add space for new tables*/
proc casutil;
	droptable casdata="ChemicalDiseaseDependency" incaslib="Casuser";
	droptable casdata="ChemicalDiseasePath" incaslib="Casuser";
	droptable casdata="ChemicalGeneDependency" incaslib="Casuser";
	droptable casdata="ChemicalGenePath" incaslib="Casuser";
	droptable casdata="GeneDiseaseDependency" incaslib="Casuser";
	droptable casdata="GeneDiseasePath" incaslib="Casuser";
	droptable casdata="GeneGeneDependency" incaslib="Casuser";
	droptable casdata="GeneGenePath" incaslib="Casuser";
run;
	
/*Use First Entity Location, take the last two numbers seperated by the comma and minus them (that gets the length of the word), next we find the first word that begins with
the extracted entity name and parse out everything after that first letter with the length coming from the entity location information*/
data casuser.CDNormalizedEntityLength;
	set casuser.Chemicaldiseasecomplete;
	ChemicalLocation = index(Sentence, FirstEntityName);
run;

data casuser.CDNormalizedEntityLength;
	set casuser.CDNormalizedEntityLength;
	Chemical_Name_Full = substr(Sentence, ChemicalLocation, 70);
	Chemical_Name = scan(Chemical_Name_Full, 1, '');
	drop ChemicalLocation;
run;

/*Lets count the amount of times we were only able to pull the number or letter*/
data casuser.CDDrugChemicalExtracts;
	set casuser.CDNormalizedEntityLength;
		if length(Chemical_Name) =< 1 then flag=1;
		else flag=0;
run;

/*Repeat the same process for Chemical - Gene Dendrogram*/
data casuser.CGNormalizedEntityLength;
	set casuser.Chemicalgenecomplete;
	ChemicalLocation = index(Sentence, FirstEntityName);
run;

data casuser.CGNormalizedEntityLength;
	set casuser.CGNormalizedEntityLength;
	Chemical_Name_Full = substr(Sentence, ChemicalLocation, 70);
	Chemical_Name = scan(Chemical_Name_Full, 1, '');
	drop ChemicalLocation;
run;

/*Lets count the amount of times we were only able to pull the number or letter*/
data casuser.CGDrugChemicalExtracts;
	set casuser.CGNormalizedEntityLength;
		if length(Chemical_Name) =< 1 then flag=1;
		else flag=0;
run;

proc casutil;
	droptable casdata="CDNormalizedEntityLength" incaslib="Casuser";
	droptable casdata="CGNormalizedEntityLength" incaslib="Casuser";
run;

/*We can try several merges on the different DrugBank sets (MDS_100Drugs_V1, Truth, DBSmall_Truth)*/
/*DBSmall_Truth to start for Chemical Gene*/
proc fedsql sessref=casauto;
	create table casuser.DBSmallChemicalGene {options replace=true copies=0} as
	select CGDrugChemicalExtracts.*, DBSmallM_Truth.*
	from casuser.CGDrugChemicalExtracts left outer join public.DBSmallM_Truth
	on (upcase(CGDrugChemicalExtracts.Chemical_Name) = upcase(DBSmallM_Truth.name));
quit;

data casuser.DBSmallChemicalGene;
	set casuser.DBSmallChemicalGene;
	where name is not missing;
	drop Chemical_Name_Full name Sentence;
run; /*88661 Records*/

/*Next on to try is merging on the truth dataset for Chemical Gene*/
proc fedsql sessref=casauto;
	create table casuser.CGDrugBankTruth {options replace=true copies=0} as
	select CGDrugChemicalExtracts.*, Truth.*
	from casuser.CGDrugChemicalExtracts left outer join public.Truth
	on (upcase(CGDrugChemicalExtracts.Chemical_Name) = upcase(Truth.iName));
quit;

data casuser.CGDrugBankTruth;
	set casuser.CGDrugBankTruth;
	where iName is not missing;
	drop Chemical_Name_Full iName Sentence;
run;/*20688*/


/*Finally we will try the MDS_100Drugs_V1 dataset for Chemical Gene*/
proc fedsql sessref=casauto;
	create table casuser.CGDrugBankMDS {options replace=true copies=0} as
	select CGDrugChemicalExtracts.*, MDS_100Drugs_V1.*
	from casuser.CGDrugChemicalExtracts left outer join public.MDS_100Drugs_V1
	on (upcase(CGDrugChemicalExtracts.Chemical_Name) = upcase(MDS_100Drugs_V1.name));
quit;

data casuser.CGDrugBankMDS;
	set casuser.CGDrugBankMDS;
	where name is not missing;
	drop Chemical_Name_Full name Sentence;
run;/*11638*/

/*DBSmall_Truth*/
proc fedsql sessref=casauto;
	create table casuser.DBSmallChemicalDisease {options replace=true copies=0} as
	select CDDrugChemicalExtracts.*, DBSmallM_Truth.*
	from casuser.CDDrugChemicalExtracts left outer join public.DBSmallM_Truth
	on (upcase(CDDrugChemicalExtracts.Chemical_Name) = upcase(DBSmallM_Truth.name));
quit;

data casuser.DBSmallChemicalDisease;
	set casuser.DBSmallChemicalDisease;
	where name is not missing;
	drop Chemical_Name_Full name Sentence;
run;/*62119*/


/*Truth*/
proc fedsql sessref=casauto;
	create table casuser.CDDrugBankTruth {options replace=true copies=0} as
	select CDDrugChemicalExtracts.*, Truth.*
	from casuser.CDDrugChemicalExtracts left outer join public.Truth
	on (upcase(CDDrugChemicalExtracts.Chemical_Name) = upcase(Truth.iName));
quit;

data casuser.CDDrugBankTruth;
	set casuser.CDDrugBankTruth;
	where iName is not missing;
	drop Chemical_Name_Full iName Sentence;
run;/*20708*/

/*MDS_100Drugs_V1*/
proc fedsql sessref=casauto;
	create table casuser.CDDrugBankMDS {options replace=true copies=0} as
	select CDDrugChemicalExtracts.Chemical_Name, MDS_100Drugs_V1.*
	from casuser.CDDrugChemicalExtracts left outer join public.MDS_100Drugs_V1
	on (upcase(CDDrugChemicalExtracts.Chemical_Name) = upcase(MDS_100Drugs_V1.name));
quit;

data casuser.CDDrugBankMDS;
	set casuser.CDDrugBankMDS;
	where name is not missing;
	drop Chemical_Name_Full name Sentence;
run;/*9183*/

/*Finally Promote completely tables to be used by the team*/
/*Only will drop tables after first run, this can be used if data is being updated*/

/*proc casutil;
	droptable casdata="DBSmallChemicalGene" incaslib="CASUSER";
	droptable casdata="CGDrugBankTruth" incaslib="CASUSER";
	droptable casdata="DBSmallChemicalDisease" incaslib="CASUSER";
	droptable casdata="CDDrugBankTruth" incaslib="CASUSER";
	droptable casdata="GeneGeneUniprot" incaslib="CASUSER";
	droptable casdata="ChemicalGeneUniprot" incaslib="CASUSER";
	droptable casdata="GeneDiseaseUniprot" incaslib="CASUSER";
quit;*/

proc casutil outcaslib="public";
	promote casdata="DBSmallChemicalGene" incaslib="CASUSER";
	promote casdata="CGDrugBankTruth" incaslib="CASUSER";
	promote casdata="DBSmallChemicalDisease" incaslib="CASUSER";
	promote casdata="CDDrugBankTruth" incaslib="CASUSER";
	promote casdata="GeneGeneUniprot" incaslib="CASUSER";
	promote casdata="ChemicalGeneUniprot" incaslib="CASUSER";
	promote casdata="GeneDiseaseUniprot" incaslib="CASUSER";
quit;