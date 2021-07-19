/**
  @file
  @author Neal Vaidya <neal.vaidya@sas.com>
  @brief Generates list of drug candidates using K-nearest-neighbors

  @param [in] embedding - the 2-layer name of the table with node embeddings
  @param [out] output - the 2-layer name of the table where the candidate list will be stored
**/
%macro candidates_knn(embeddings, output);
%let embeddings=embed.network1_embeddings;
%let output=net1candidates;
caslib private path='/tmp' libref=private;

data work.fastknn_data;
    set &embeddings;
    if scan(node, 1, ":") = "drug";
    drugbank_id = scan(node,2,":");
    nodeid = _n_;
run;

proc sql;
    drop table fastknn_query;

    create table fastknn_query as
    select distinct d.*
    from repo.truth as t inner join work.fastknn_data as d
    on d.drugbank_id = t.drugbank_id;
quit;

proc casutil outcaslib="private";
    load data=work.fastknn_data replace;
    load data=work.fastknn_query replace;
quit;

proc fastknn data=private.fastknn_data query=private.fastknn_query k=10 outdist=private.fastknn_dist;
    id nodeid;
    input vec_:;
    output out=private.nearest_neighbors;
run;

proc sql;
    create table nearest_neighbors as
    select d.*
    from private.fastknn_dist d
    where d.ReferenceID not in (select QueryID from private.fastknn_dist)
    order by QueryID, Distance;
quit;

data work.nearest_neighbors;
    set nearest_neighbors;
    by QueryID Distance;
    if first.QueryID then seqno = 0;
    seqno + 1;
run;

data private.nearest_neighbors;
    set work.nearest_neighbors;
    where seqno <= 10;
run;

proc sql;
    create table drug_label as
    select distinct a.nodeid as nodeid, b.name as name
    from fastknn_data a inner join repo.dbsmallm_truth b
    on a.drugbank_id = b.drugbank_id;

    create table candidates as
    select nn.*, agg.strength
    from private.nearest_neighbors as nn
        inner join
        (select ReferenceID, count(*) as strength
        from private.nearest_neighbors
        group by ReferenceID) as agg
    on nn.ReferenceID = agg.ReferenceID
    order by strength desc, ReferenceID, Distance;

    create table labeled_candidates as
    select a.name as candidate_drug,
           b.name as neighbor,
           candidates.*
    from
        drug_label a, candidates, drug_label b
    where
        a.nodeid = candidates.ReferenceID and
        b.nodeid = candidates.QueryID
    order by strength desc, candidate_drug, distance;
quit;

proc casutil;
    droptable incaslib="repositioning" casdata="&output";
    load data=work.labeled_candidates outcaslib="repositioning" casout="&output" promote;
quit;

caslib private drop;

proc datasets library=work noprint;
    delete nearest_neighbors;
    delete fastknn_data;
    delete fastknn_query;
run;
quit;

%mend candidates_knn;