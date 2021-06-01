%let VIYA4=0;


/**************************************/
/* Get Nodes                          */
/**************************************/
proc fedsql sessref=&sessionName;
   create table casuser.nodesDrugs {options replace=true} as 
   select distinct a.head as "node"
   from casuser.edges_drugbank_drug_protein as a;
quit;
proc fedsql sessref=&sessionName;
   create table casuser.nodesProteins {options replace=true} as 
   select distinct a.tail as "node", 1 as "reach"
   from casuser.edges_drugbank_drug_protein as a;
quit;

/**************************************/
/* Induce PPI graph to keep relevant  */
/* proteins (those in Drugbank)       */
/**************************************/
%if "&VIYA4"="0" %then %do;
   proc fedsql sessref=&sessionName;
         create table casuser.linksPPInduced {options replace=true} as
         select a.*
         from casuser.edges_string_protein_protein as a
         inner join casuser.nodesProteins as b
         on a.head = b.node
         inner join casuser.nodesProteins as c
         on a.tail = c.node
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

data casuser.edges;
   set casuser.edges_drugbank_drug_protein casuser.linksPPinduced(in=isPP);
   if isPP then category="PPI";
run;

proc network
   links    = casuser.edges
   outNodes = casuser.network2_embeddings;
   linksvar from=head to=tail;
   nodeSimilarity
      jaccard        = false
      vector         = true
      nSamples       = 10000000
      convergenceThreshold = 0.001
   ;
run;

proc casutil;
	droptable incaslib="embedding" casdata="network2_embeddings" quiet;
	promote incaslib="casuser" casdata="network2_embeddings" outcaslib="embedding" casout="network2_embeddings";
	save incaslib="embedding" outcaslib="embedding" casdata="network2_embeddings" casout="network2_embeddings.csv" replace;
quit;

proc casutil incaslib="casuser";
	droptable casdata="edges";
	droptable casdata="linksppinduced";
	droptable casdata="nodesdrugs";
	droptable casdata="nodesproteins";
quit;

