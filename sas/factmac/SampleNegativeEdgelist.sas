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
	%let negativeSamples = 1;
	%end; 
%else %do;
	%let negativeSamples = 10000000;
	%end;

/************************************************************************************************************/
/* Generate sample of _Negative_ edgelist for edges which do not appear in the dataset. 					*/
/* The intention is for the negative edgelist sample to be roughly the same size as the positive edgelist 	*/
/************************************************************************************************************/


/* Sample heads and tails from node table */
proc surveyselect data=casuser.nodes out=casuser.negative1 method=URS outhits sampsize=&negativeSamples;
run;
proc surveyselect data=casuser.nodes out=casuser.negative2 method=URS outhits outrandom sampsize=&negativeSamples;
run;

data casuser.negative1;
	set casuser.negative1;
	length head varchar(*);
	head = strip(NODE);
	keep head;

data casuser.negative2;
	set casuser.negative2;
	length tail varchar(*);
	tail = strip(NODE);
	keep tail;

data casuser.negative_edges;
	merge casuser.negative1 casuser.negative2;
run;

/* Sort and remove duplicates */
proc sort data=casuser.negative_edges out=casuser.negative_edges nodupkey;
	by head tail;
run;
	

/* Create index on table for faster processing */
proc casutil;
	index casdata="negative_edges" casout="negative_edges" replace indexvars={"head", "tail"};
	index casdata="edges" casout="edges" replace indexvars={"head", "tail"};
run;


/* Remove edges from the negative edgelist which appear in the positive edgelist */
data casuser.negative_edges;
	merge casuser.negative_edges (in=inneg) casuser.edges (in=inpos);
	by head tail;
	if not inpos;
	drop source;
run;

%if &testscript = 0 %then %do;
proc casutil incaslib="casuser" outcaslib="repositioning";
	save casdata="negative_edges" casout="negative_edges.csv" replace;
	droptable casdata="negative1";
	droptable casdata="negative2";
run;
%end;

%if &sessionName = "localSession" %then %do;
	cas &sessionName terminate;
	%symdel sessionName;
	%end;
