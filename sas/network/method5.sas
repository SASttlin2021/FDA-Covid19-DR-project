%let VIYA4=0;

/**************************************/
/* Get Nodes                          */
/**************************************/
data casuser.edges;
	set casuser.edges:;
run;

proc fedsql sessref=&sessionName;
	drop table casuser.nodes force;
	create table casuser.nodes as select distinct node from (
		select distinct head as node from casuser.edges
		union
		select distinct tail as node from casuser.edges
	) a;
quit;

data casuser.nodes;
	set casuser.nodes;
	type = scan(node, 1, ":");
run;

proc network
   links    = casuser.edges
   outNodes = casuser.network5_embeddings;
   linksvar from=head to=tail;
   nodeSimilarity
      jaccard        = false
      vector         = true
      nSamples       = 10000000
      convergenceThreshold = 0.001
	  source = &sars_cov_2 /* Just pick a random one so it doesnt compute every distance */
   ;
run;

proc casutil;
	droptable incaslib="embedding" casdata="network5_embeddings" quiet;
	promote incaslib="casuser" casdata="network5_embeddings" outcaslib="embedding" casout="network5_embeddings";
	save incaslib="embedding" outcaslib="embedding" casdata="network5_embeddings" casout="network5_embeddings.csv" replace;
quit;

proc casutil incaslib="casuser";
	droptable casdata="edges";
	droptable casdata="nodes";
quit;


