/**
  @file
  @brief <Your brief here>
  <h4> SAS Macros </h4>
**/

%macro candidates_distance(embeddings, output);

caslib private path='/tmp' libref=private;

data work.fastknn_data;
  set &embeddings;
  if scan(node, 1, ":") = "drug" or node=&sars_cov_2;
  drugbank_id = scan(node,2,":");
  nodeid = _n_;
run;

data work.fastknn_query;
  set work.fastknn_data;
  where node=&sars_cov_2;
run;

proc casutil outcaslib="private";
    load data=work.fastknn_data replace;
    load data=work.fastknn_query replace;
quit;

proc fastknn data=private.fastknn_data query=private.fastknn_query outdist=private.fastknn_dist;
  id nodeid;
  input vec_:;
run;

proc sql;
    create table drug_label as
    select distinct a.nodeid as nodeid, b.name as name, a.drugbank_id as drugbank_id
    from fastknn_data a inner join repo.dbsmallm_truth b
    on a.drugbank_id = b.drugbank_id;

    create table candidates as
    select nn.*, dl.*
    from private.fastknn_dist as nn
		inner join drug_label as dl
		on nn.ReferenceID = dl.nodeid
    order by Distance;
quit;

proc casutil;
  droptable incaslib="repositioning" casdata="&output";
  load data=work.candidates outcaslib="repositioning" casout="&output";
quit;

proc datasets library=work noprint;
  delete nearest_neighbors;
  delete fastknn_data;
  delete fastknn_query;
run;
quit;

caslib private drop;

%mend candidates_distance;

