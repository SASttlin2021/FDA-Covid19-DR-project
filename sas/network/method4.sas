%let VIYA4=0;

caslib private datasource=(srctype="path") path="&datapath/intermediate/network4" 
   sessref=&sessionName libref=private;

/**************************************/
/* Get Nodes                          */
/**************************************/
data private.edges;
	set casuser.edges:;
run;

proc fedsql sessref=&sessionName;
	drop table private.nodes force;
	create table private.nodes as select distinct node from (
		select distinct head as node from private.edges
		union
		select distinct tail as node from private.edges
	) a;
quit;

data private.nodes;
	set private.nodes;
	type = scan(node, 1, ":");
run;

proc network
   links    = private.edges
   outNodes = private.network4_embeddings;
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
	droptable incaslib="embedding" casdata="network1_embeddings" quiet;
    save incaslib="private" outcaslib="embedding" casdata="network4_embeddings" casout="network4_embeddings.csv" replace;
	load incaslib="embedding" casdata="network4_embeddings.csv" outcaslib="embedding" casout="network4_embeddings";
quit;

proc casutil incaslib="private";
	save casdata="edges" replace;
	save casdata="nodes" replace;
quit;

proc delete data=output.VA3_edges_net4; quit;
proc delete data=output.VA3_nodes_net4; quit;

data output.VA3_edges_net4(promote=YES);
   set private.edges;
run;

data output.VA3_nodes_net4(promote=YES);
   set private.nodes;
   entityType = scan(node, 1, ":");
   entity = scan(node, 2, ":");
run;

caslib private drop;


