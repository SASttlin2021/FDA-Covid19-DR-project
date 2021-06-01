%if %symexist(parent) %then %do;
	%end;
%else %do;
	%put localSession;
	%let sessionName = localSession;
	cas &sessionName;
	libname public cas caslib="public";
	libname casuser cas caslib="casuser";
	%end;

%if &testscript %then %do;
	%let factmacIters = 1;
	%end; 
%else %do;
	%let factmacIters = 40;
	%end;


%let sars_cov_2 = "MESH:D000086402";
%let num_factors = 10;

/*
 * Load graph into memory
 */

proc casutil incaslib="repositioning" outcaslib="casuser";
	load casdata="edges.csv" casout="edges";
	load casdata="nodes.csv" casout="nodes";
	load casdata="negative_edges.csv" casout="negative_edges";
run;

data casuser.edges;
	set casuser.edges;
	score = 1;
run;

data casuser.negative_edges;
	set casuser.negative_edges;
	score = 0;
run;

data casuser.full_network;
	set casuser.edges casuser.negative_edges;
run;

quit;

/* Embed using factmac */
proc factmac data=casuser.full_network outmodel=casuser.factmac_out nfactors=&num_factors maxiter=&factmacIters;
	input head tail /level=nominal;
	target score;
run;

/* Proc means hangs when running on data in cas for some reason*/
/* So move over to work lib then run proc means */
data work.factmac_data;
	set casuser.factmac_out;
run;

proc means data=work.factmac_data mean noprint;
	class Level;
	output out=casuser.factmac_embeddings mean=;
run;

%macro rename_cols;
data casuser.factmac_embeddings;
	set casuser.factmac_embeddings;
	drop _FREQ_ _TYPE_ Bias;
	rename Level=node;
	%do i=1 %to &num_factors %by 1;
		rename Factor&i = vec_&i;
	%end;
run;
%mend rename_cols;

%rename_cols;

%if &testscript = 0 %then %do;
proc casutil;
	droptable incaslib="embedding" casdata="factmac_embeddings" quiet;
	promote incaslib="casuser" casdata="factmac_embeddings" outcaslib="embedding";
	save incaslib="embedding" outcaslib="embedding" casdata="factmac_embeddings" casout="factmac_embeddings.csv" replace;
run;
%end;

proc casutil incaslib="casuser";
	droptable casdata="edges";
	droptable casdata="nodes";
	droptable casdata="negative_edges";
	droptable casdata="factmac_out";
	droptable casdata="factmac_embeddings";
	droptable casdata="full_network";
run;
quit;
	

%if &sessionName = "localSession" %then %do;
	cas &sessionName terminate;
	%symdel sessionName;
	%end;





