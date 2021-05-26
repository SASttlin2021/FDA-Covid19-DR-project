%let VIYA4=0;

cas network2;
libname sascas1 cas caslib="casuser";
libname public cas caslib="public";

/**************************************/
/* Get Nodes                          */
/**************************************/
proc fedsql sessref=network2;
   create table casuser.nodesDrugs {options replace=true} as 
   select distinct a.drugbank_id as "node"
   from repositioning.dbproteins as a;
quit;
proc fedsql sessref=network2;
   create table casuser.nodesProteins {options replace=true} as 
   select distinct a.uniprot_id as "node", 1 as "reach"
   from repositioning.dbproteins as a;
quit;

data sascas1.linksPP;
	set repo.stringpp;
	from = UniProtID1;
	to = UniProtID2;
quit;

/**************************************/
/* Induce PPI graph to keep relevant  */
/* proteins (those in Drugbank)       */
/**************************************/
%if "&VIYA4"="0" %then %do;
   proc fedsql sessref=network2;
         create table casuser.linksPPInduced {options replace=true} as
         select a.*
         from casuser.linksPP as a
         inner join casuser.nodesProteins as b
         on a.from = b.node
         inner join casuser.nodesProteins as c
         on a.to = c.node
      ;
   quit;
%end;
%else %do;
   proc network
      links            = sascas1.linksPP
      nodesSubset      = sascas1.nodesProteins;
      linksVar
         vars          = (combined_score protein1 protein2);
      reach
         maxReach=0 /* Not supported at Viya 3.5 */
         outReachLinks = sascas1.linksPPInduced
      ;
   run;
%end;

data sascas1.links;
   set sascas1.linksDP sascas1.linksPPinduced(in=isPP);
   if isPP then category="PPI";
run;

proc network
   links    = sascas1.links
   outNodes = sascas1.method2Embeddings;
   nodeSimilarity
      jaccard        = false
      vector         = true
      nSamples       = 10000000
      convergenceThreshold = 0.001
   ;
run;

proc casutil;
	droptable incaslib="embed" casdata="network2_embeddings" quiet;
	promote incaslib="casuser" casdata="method2Embeddings" outcaslib="embed" casout="network2_embeddings";
	save incaslib="embed" outcaslib="embed" casdata="network2_embeddings" casout="network2_embeddings.csv" replace;
quit;


cas network2 terminate;