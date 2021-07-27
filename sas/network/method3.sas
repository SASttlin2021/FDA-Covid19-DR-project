%let VIYA4=0;

caslib private datasource=(srctype="path") path="&datapath/intermediate/network3" 
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

data private.edges;
    set casuser.edges_drugbank_drug_protein casuser.edges_string_protein_protein(in=isPP);
    if head NE '' and tail NE '';
    if isPP then category="PPI";
run;

proc network
    links    = private.edges
    outNodes = private.network3_embeddings;
    linksvar from=head to=tail;
    nodeSimilarity
      jaccard        = false
      vector         = true
      nSamples       = 10000000
      source = "protein:Q5HYI8" /* Just pick a random one so it doesnt compute every distance */
    ;
run;

proc casutil;
    droptable incaslib="embedding" casdata="network3_embeddings" quiet;
    save incaslib="private" outcaslib="embedding" casdata="network3_embeddings" casout="network3_embeddings.csv" replace;
	load incaslib="embedding" casdata="network3_embeddings.csv" outcaslib="embedding" casout="network3_embeddings";
quit;

proc casutil incaslib="private";
    save casdata="edges" replace;
    save casdata="nodesdrugs" replace;
    save casdata="nodesproteins" replace;
quit;

proc delete data=output.VA3_edges_net3; quit;
proc delete data=output.VA3_nodes_net3; quit;

data output.VA3_edges_net3(promote=YES);
   set private.edges;
run;

data output.VA3_nodes_net3(promote=YES);
   set private.nodesdrugs private.nodesproteins;
   entityType = scan(node, 1, ":");
   entity = scan(node, 2, ":");
run;

caslib private drop;
