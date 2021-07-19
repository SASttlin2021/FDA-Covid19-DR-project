caslib private datasource=(srctype="path") path="&datapath/intermediate/network1" 
   sessref=&sessionName libref=private;

data private.edges;
	set casuser.edges_drugbank_drug_protein;
	where head and tail;
run;

/**************************************/
/* Get Nodes                          */
/**************************************/
proc fedsql sessref=&sessionName;
	drop table private.nodes force;
	create table nodes as select distinct node from (
		select distinct head as node from private.edges
		union
		select distinct tail as node from private.edges
	) a;
quit;

data private.nodes;
	set private.nodes;
	isDrug = 0;
	if scan(node, 1, ":") = "drug" then isDrug = 1;
run;

proc sort data=private.nodes out=private.nodes nodupkey;
	by node;
run;

proc print data=private.nodes(obs=10); run;

proc network
   nodes = private.nodes
   links = private.edges;
   linksVar
      from = head
      to = tail;
   projection
      partition          = isDrug
      commonNeighbors    = true
      jaccard            = true
      cosine             = true
      outProjectionLinks = private.drugLinks
      outNeighborsList   = private.drugLinksCommonProteins;
run;

proc print data=private.drugLinks(obs=10); run;
proc print data=private.drugLinksCommonProteins(obs=10); run;

/* drugLinks shows for each pair of drugs, how many proteins they have in common (count), */
/* 		along with columns 'cosine' and 'jaccard' as measures of similarities */
/* drugLinksCommonProteins shows for each pair of drugs which protein is a common neighbor  */



/* Most Similar Drug Pairs: Common Neighbor Count */
/* proc sort data=casuser.drugLinks out=drugLinks; by descending commonNeighbors; run; */
/* proc print data=drugLinks(obs=15); run; */
/*  */
/* proc sort data=casuser.drugLinks out=drugLinks_asc; by commonNeighbors; run; */

proc network
   links    = private.drugLinks
   outNodes = private.drugEmbeddings;
   linksVar
      from = head
      to = tail /* this variable name is just a quirk because it's really a second drug*/
      weight = commonNeighbors;
   nodeSimilarity
      jaccard        = false
      vector         = true
      proximityOrder = first
      nSamples       = 10000000
/*       topK           = 2000 */
      outSimilarity  = private.drugVectorSimilarity
   ;
run;

proc casutil;
	droptable incaslib="embedding" casdata="network1_embeddings" quiet;
   save incaslib="private" outcaslib="embedding" casdata="drugEmbeddings" casout="network1_embeddings.csv" replace;
	load incaslib="embedding" casdata="network1_embeddings.csv" outcaslib="embedding" casout="network1_embeddings";

	save incaslib="private" casdata="druglinks" replace;
	save incaslib="private" casdata="druglinkscommonproteins" replace;
	save incaslib="private" casdata="drugvectorsimilarity" replace;
	save incaslib="private" casdata="edges" replace;
	save incaslib="private" casdata="nodes" replace;
quit;

proc delete data=output.VA3_edges_net1; quit;
proc delete data=output.VA3_nodes_net1; quit;

data output.VA3_edges_net1(promote=YES);
   set private.edges;
run;

data output.VA3_nodes_net1(promote=YES);
   set private.nodes;
   entityType = scan(node, 1, ":");
   entity = scan(node, 2, ":");
run;

caslib private drop;
 