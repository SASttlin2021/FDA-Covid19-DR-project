%let VIYA4=0;

caslib private datasource=(srctype="path") path="&datapath/intermediate/network2" 
   sessref=&sessionName libref=private;

/**************************************/
/* Get Nodes                          */
/**************************************/
proc fedsql sessref=&sessionName;
   create table private.nodesDrugs {options replace=true} as 
   select distinct a.head as "node"
   from casuser.edges_drugbank_drug_protein as a;
quit;
proc fedsql sessref=&sessionName;
   create table private.nodesProteins {options replace=true} as 
   select distinct a.tail as "node", 1 as "reach"
   from casuser.edges_drugbank_drug_protein as a;
quit;

/**************************************/
/* Induce PPI graph to keep relevant  */
/* proteins (those in Drugbank)       */
/**************************************/
%if "&VIYA4"="0" %then %do;
   proc fedsql sessref=&sessionName;
         create table private.linksPPInduced {options replace=true} as
         select a.*
         from casuser.edges_string_protein_protein as a
         inner join private.nodesProteins as b
         on a.head = b.node
         inner join private.nodesProteins as c
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

data private.edges;
   set casuser.edges_drugbank_drug_protein private.linksPPinduced(in=isPP);
   if isPP then category="PPI";
run;

proc network
   links    = private.edges
   outNodes = private.network2_embeddings;
   linksvar from=head to=tail;
   nodeSimilarity
      jaccard        = false
      vector         = true
      nSamples       = 10000000
      convergenceThreshold = 0.001
   ;
run;

proc casutil;
   droptable incaslib="embedding" casdata="network1_embeddings" quiet;
   save incaslib="private" outcaslib="embedding" casdata="network2_embeddings" casout="network2_embeddings.csv" replace;
	load incaslib="embedding" casdata="network2_embeddings.csv" outcaslib="embedding" casout="network2_embeddings";
quit;

proc casutil incaslib="private";
	save casdata="edges" replace;
	save casdata="linksppinduced" replace;
	save casdata="nodesdrugs" replace;
	save casdata="nodesproteins" replace;
quit;

proc delete data=output.VA3_edges_net2; quit;
proc delete data=output.VA3_nodes_net2; quit;

data output.VA3_edges_net2(promote=YES);
   set private.edges;
run;

data output.VA3_nodes_net2(promote=YES);
   set private.nodesdrugs private.nodesproteins;
   entityType = scan(node, 1, ":");
   entity = scan(node, 2, ":");
run;

caslib private drop;
