/* Initialize CAS Session */

%if %symexist(parent) %then %do;
	%end;
%else %do;
	%put localSession;
	%let sessionName = localSession;
	cas &sessionName;
	libname public cas caslib="public";
	libname casuser cas caslib="casuser";
	%end;

/* MESH ID for SARS-CoV-2, our disease of interest */
%let sars_cov_2 = "MESH:D000086402";

/*
 * Concatenate each of the edgelists into one full graph
 */

data casuser.edges;
	set casuser.edges:;
	length head_v varchar(*) tail_v varchar(*);
	head_v = head;
	tail_v = tail;
	drop head tail;
run;

data casuser.edges;
	set casuser.edges;
	rename head_v=head tail_v=tail;
run;

/* Remove duplicates and sort edgelist. Useful for later processing */
proc sort data=casuser.edges out=casuser.edges nodupkey;
	by head tail;
run;

/****************************************************************/
/* Generate node table from edgelist. Current node types are: 	*/
/* 	- Drug 														*/
/* 	- Protein 													*/
/* 	- Disease 													*/
/****************************************************************/

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
	type = scan(node, 1, ":");
run;

/* Save edge and node tables to disk */
proc casutil incaslib="casuser" outcaslib="repositioning";
	save casdata="edges" casout="edges.csv" replace;
	save casdata="nodes" casout="nodes.csv" replace;
quit;

%if &sessionName = "localSession" %then %do;
	cas &sessionName terminate;
	%symdel sessionName;
	%end;
