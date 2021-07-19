/**
  Prepare table of Gene-Disease relationships from GNBR
*/

/**Pull in Data sources from the server*/
/*In this current version, files need to be manually uploaded to the server from the GNBR website 
  and then brought in via proc casutil*/
proc casutil incaslib="gnbr" outcaslib="gnbr" sessref="&sessionName";
  load casdata="part-i-gene-disease-path-theme-distributions.txt" casout="GeneDiseasePath"
    importoptions=(filetype="csv" delimiter='09'x getnames=FALSE) replace;
  load casdata="part-ii-dependency-paths-gene-disease-sorted.txt" casout="GeneDiseaseDependency"
    importoptions=(filetype="csv" delimiter='09'x getnames=FALSE) replace;
quit;

/*Relabel Data from original coding in data sources*/

/*Rename variables for Dependency Paths Part-ii to fit the documentation*/
data gnbr.GeneDiseaseDependency;
  set gnbr.GeneDiseaseDependency;
  length DependencyPath varchar(*);

  rename var1=PubmedID var2=SentenceNumber var3=FirstEntityName var4=FirstEntityLocation
         var5=SecondEntityName var6=SecondEntityLocation var7=FirstEntityRaw var8=SecondEntityRaw
         var9=FirstEntityDBID var10=SecondEntityDBID var11=FirstEntityType var12=SecondEntityType
         /*var13=DependencyPath*/ var14=Sentence;

  DependencyPath = lowcase(var13);
  drop var13;
run;

/*Rename variables for connections from Part-i data*/
data gnbr.GeneDiseasePath;
  set gnbr.GeneDiseasePath;
  length DependencyPath varchar(*);

  rename /*var1=DependencyPath*/ var2=CasualMutations var3=CasualMutations_ind var4=MutationAffectDisease
         var5=MutationAffectDisease_ind var6=DrugTargets var7=DrugTargets_ind var8=PathogenesisRole
         var9=PathogenesisRole_ind var10=TherapeuticEffect var11=TherapeuticEffect_ind var12=Polymorphisms
         var13=Polymorphisms_ind var14=PromotesProgression var15=PromotesProgression_ind var16=Biomarkers
         var17=Biomarkers_ind var18=Overexpression var19=Overexpression_ind var20=ImproperRegulation
         var21=ImproperRegulation_ind;

  DependencyPath = lowcase(var1);
  drop var1;
/* 	If _N_ = 1 then delete; */
run;

proc fedsql sessref=&sessionName;
  create table casuser.GeneDiseaseComplete {options replace=true copies=0} as
  select GeneDiseasePath.*, GeneDiseaseDependency.FirstEntityName, GeneDiseaseDependency.FirstEntityDBID,
  GeneDiseaseDependency.SecondEntityName, GeneDiseaseDependency.SecondEntityDBID
  from gnbr.GeneDiseasePath, gnbr.GeneDiseaseDependency
  where GeneDiseasePath.DependencyPath = GeneDiseaseDependency.DependencyPath;
quit;

proc casutil;
  load file="/opt/sas/viya/config/data/cas/default/public/FDA/UniProtGeneIDs.csv"
  outcaslib="Casuser" casout="UniprotGeneID";
quit;

proc fedsql sessref=&sessionName;
  create table casuser.GeneDiseaseUniprot {options replace=true copies=0} as
  select GeneDiseaseComplete.*, UniprotGeneID.GeneID, UniprotGeneID.UniProtID
  from casuser.GeneDiseaseComplete left outer join casuser.UniprotGeneID
  on (GeneDiseaseComplete.FirstEntityDBID = UniprotGeneID.GeneID);
quit;

proc casutil outcaslib="gnbr";
  save casdata="GeneDiseaseUniprot" incaslib="casuser" casout="GeneDiseaseComplete.csv" replace;
quit;
