
data casuser.edges;
	set casuser.edges_drugbank_drug_protein;
	where head and tail;
run;

/**************************************/
/* Get Nodes                          */
/**************************************/
proc fedsql sessref=&sessionName;
	drop table casuser.nodes force;
	create table nodes as select distinct node from (
		select distinct head as node from casuser.edges
		union
		select distinct tail as node from casuser.edges
	) a;
quit;

data casuser.nodes;
	set casuser.nodes;
	isDrug = 0;
	if scan(node, 1, ":") = "drug" then isDrug = 1;
run;

proc sort data=casuser.nodes out=casuser.nodes nodupkey;
	by node;
run;

proc print data=casuser.nodes(obs=10); run;

proc network
   nodes = casuser.nodes
   links = casuser.edges;
   linksVar
      from = head
      to = tail;
   projection
      partition          = isDrug
      commonNeighbors    = true
      jaccard            = true
      cosine             = true
      outProjectionLinks = casuser.drugLinks
      outNeighborsList   = casuser.drugLinksCommonProteins;
run;

proc print data=casuser.drugLinks(obs=10); run;
proc print data=casuser.drugLinksCommonProteins(obs=10); run;

/* drugLinks shows for each pair of drugs, how many proteins they have in common (count), */
/* 		along with columns 'cosine' and 'jaccard' as measures of similarities */
/* drugLinksCommonProteins shows for each pair of drugs which protein is a common neighbor  */



/* Most Similar Drug Pairs: Common Neighbor Count */
/* proc sort data=casuser.drugLinks out=drugLinks; by descending commonNeighbors; run; */
/* proc print data=drugLinks(obs=15); run; */
/*  */
/* proc sort data=casuser.drugLinks out=drugLinks_asc; by commonNeighbors; run; */

proc network
   links    = casuser.drugLinks
   outNodes = casuser.drugEmbeddings;
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
      outSimilarity  = casuser.drugVectorSimilarity
   ;
run;

proc casutil;
	droptable incaslib="embedding" casdata="network1_embeddings" quiet;
	promote incaslib="casuser" casdata="drugEmbeddings" outcaslib="embedding" casout="network1_embeddings";
	save incaslib="embedding" outcaslib="embedding" casdata="network1_embeddings" casout="network1_embeddings.csv" replace;

	droptable incaslib="casuser" casdata="druglinks";
	droptable incaslib="casuser" casdata="druglinkscommonproteins";
	droptable incaslib="casuser" casdata="drugvectorsimilarity";
	droptable incaslib="casuser" casdata="edges";
	droptable incaslib="casuser" casdata="nodes";
quit;

