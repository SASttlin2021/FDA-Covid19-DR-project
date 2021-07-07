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

data casuser.edges;
    set casuser.edges_drugbank_drug_protein casuser.edges_string_protein_protein(in=isPP);
    where head NE '' and tail NE '';
    if isPP then category="PPI";
run;

proc network
    links    = casuser.edges
    outNodes = casuser.network3_embeddings;
    linksvar from=head to=tail;
    nodeSimilarity
      jaccard        = false
      vector         = true
      nSamples       = 10000000
      convergenceThreshold = 0.001
      source = "protein:Q5HYI8" /* Just pick a random one so it doesnt compute every distance */
    ;
run;

proc casutil;
    droptable incaslib="embedding" casdata="network3_embeddings" quiet;
    promote incaslib="casuser" casdata="network3_embeddings" outcaslib="embedding" casout="network3_embeddings";
    save incaslib="embedding" outcaslib="embedding" casdata="network3_embeddings" casout="network3_embeddings.csv" replace;
quit;

proc casutil incaslib="casuser";
    droptable casdata="edges";
    droptable casdata="nodesdrugs";
    droptable casdata="nodesproteins";
quit;


