/**
  @file
  @author Neal Vaidya <neal.vaidya@sas.com>
  @brief Generates list of drug candidates using K-nearest-neighbors

  @param [in] embedding - the 2-layer name of the table with node embeddings
  @param [out] output - the 2-layer name of the table where the candidate list will be stored
  @param [in] drugs - the 2-layer name of the table with the training data and drug names
**/
%macro candidates_knn(embeddings, output, drugs);
caslib private path='/tmp' libref=private;

/* Only use drugs in the "before" set for training */
data private.training;
    set &drugs;
    where before;
run;

/* Filter out non-drugs and create nodeid, numeric identifier for each drug */
/* numeric identifier is required for fastknn */
data work.fastknn_data;
    set &embeddings;
    if scan(node, 1, ":") = "drug";
    drugbank_id = scan(node,2,":");
    nodeid = _n_;
run;

/* Create fastknn "query" table from "truth" dataset */
/* This will be the set of nodes we find the neighbors of */
proc sql;
    drop table fastknn_query;

    create table fastknn_query as
    select distinct d.*
    from private.training as t inner join work.fastknn_data as d
    on d.drugbank_id = t.drugbank_id;
quit;

/* load into cas for fastknn */
proc casutil outcaslib="private";
    load data=work.fastknn_data replace;
    load data=work.fastknn_query replace;
quit;

/* Find nearest neighbors of `query` drugs among `data` drugs */
proc fastknn data=private.fastknn_data query=private.fastknn_query k=10 outdist=private.fastknn_dist;
    id nodeid;
    input vec_:;
    output out=private.nearest_neighbors;
run;

/* Remove query drugs from candidate list and sort */
proc sql;
    create table nearest_neighbors as
    select d.*
    from private.fastknn_dist d
    where d.ReferenceID not in (select QueryID from private.fastknn_dist)
    order by QueryID, Distance;
quit;

/* Keep only the top 10 nearest neighbors of each query drug */
data work.nearest_neighbors;
    set nearest_neighbors;
    by QueryID Distance;
    if first.QueryID then seqno = 0;
    seqno + 1;
run;
data work.nearest_neighbors;
    set work.nearest_neighbors;
    where seqno <= 5;
run;

proc fastclus data=work.nearest_neighbors maxc=2 maxiter=10 out=clus;
	by QueryID;
	var distance;
	ods exclude all;
run;

data private.nearest_neighbors;
	set work.clus;
	where CLUSTER=1;
run;

proc sql;
    /* Lookup table to translate between nodeid (see above) and drug name */
    create table drug_label as
    select distinct a.nodeid as nodeid, a.drugbank_id as drugbank_id, b.name as name
    from fastknn_data a inner join &drugs b
    on a.drugbank_id = b.drugbank_id;

    /* Count how frequently each drug appears in the nearest neighbors list and sort */
    /* Frequency of appearence is labeled "strength" */
    create table candidates as
    select nn.*, agg.strength
    from private.nearest_neighbors as nn
        inner join
        (select ReferenceID, count(*) as strength
        from private.nearest_neighbors
        group by ReferenceID) as agg
    on nn.ReferenceID = agg.ReferenceID
    order by strength desc, ReferenceID, Distance;

    /* labeled drugs and their respective strength, along with which query drug they appear neighbor to */
    create table labeled_candidates_with_neighbor as
    select a.name as candidate_drug,
           a.drugbank_id as candidate_drugbank_id,
           b.name as neighbor,
           candidates.*
    from
        drug_label a, candidates, drug_label b
    where
        a.nodeid = candidates.ReferenceID and
        b.nodeid = candidates.QueryID
    order by strength desc, candidate_drug, distance;

    /* just the candidates */
    create table labeled_candidates as
    select distinct candidate_drug, candidate_drugbank_id
    from labeled_candidates_with_neighbor;
quit;

data &output;
	length drug varchar(*) drugbank_id varchar(*);
	set labeled_candidates;
	drug = candidate_drug;
	drugbank_id = candidate_drugbank_id;
	keep drug drugbank_id;
run;

caslib private drop;

proc datasets library=work noprint;
    delete nearest_neighbors;
    delete fastknn_data;
    delete fastknn_query;
run;
quit;

%mend candidates_knn;