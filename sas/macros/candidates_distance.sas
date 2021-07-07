/**
  @file
  @brief <Your brief here>
  <h4> SAS Macros </h4>
**/

%macro candidates_distance(embeddings, output);

%let sessionName = localsession;
cas localsession;
libname casuser cas caslib="casuser";
libname embed cas caslib="embedding";
libname public cas caslib="public";
libname repo cas caslib="repositioning";

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

proc casutil outcaslib="casuser";
    load data=work.fastknn_data replace;
    load data=work.fastknn_query replace;
quit;

proc fastknn data=casuser.fastknn_data query=casuser.fastknn_query outdist=casuser.fastknn_dist;
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
    from casuser.fastknn_dist as nn
		inner join drug_label as dl
		on nn.ReferenceID = dl.nodeid
    order by Distance;
quit;

proc casutil;
  droptable incaslib="repositioning" casdata="&output";
  load data=work.candidates outcaslib="repositioning" casout="&output" promote;

cas &sessionName terminate;

proc datasets library=work noprint;
  delete nearest_neighbors;
  delete fastknn_data;
  delete fastknn_query;
run;
quit;

%mend candidates_distance;

