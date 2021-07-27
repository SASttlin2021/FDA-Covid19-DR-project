/* Initialize CAS Session */

caslib private datasource=(srctype="path") path="&datapath/intermediate/factmac" 
   sessref=&sessionName libref=private;

/* MESH ID for SARS-CoV-2, our disease of interest */
%let sars_cov_2 = "MESH:D000086402";

/*
 * Concatenate each of the edgelists into one full graph
 */

data private.edges;
	set casuser.edges:;
	length head_v varchar(*) tail_v varchar(*);
	head_v = head;
	tail_v = tail;
	drop head tail;
run;

data private.edges;
	set private.edges;
	rename head_v=head tail_v=tail;
run;

/* Remove duplicates and sort edgelist. Useful for later processing */
/* proc sort data=casuser.edges out=casuser.edges nodupkey; */
/* 	by head tail; */
/* run; */

/****************************************************************/
/* Generate node table from edgelist. Current node types are: 	*/
/* 	- Drug 														*/
/* 	- Protein 													*/
/* 	- Disease 													*/
/****************************************************************/

proc fedsql sessref=&sessionName;
	drop table private.nodes force;
	create table private.head as select distinct head as node from private.edges;
	create table private.tail as select distinct tail as node from private.edges;
quit;

data private.nodes;
	set private.head private.tail;
	type = scan(node, 1, ":");
run;

/* Save edge and node tables to disk */
proc casutil incaslib="private" outcaslib="private";
	save casdata="edges" casout="edges.csv" replace;
	save casdata="nodes" casout="nodes.csv" replace;
quit;
