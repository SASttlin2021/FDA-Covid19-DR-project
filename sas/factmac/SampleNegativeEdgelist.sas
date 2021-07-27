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
proc surveyselect data=private.nodes out=private.negative1 method=URS outhits sampsize=&negativeSamples;
run;
proc surveyselect data=private.nodes out=private.negative2 method=URS outhits outrandom sampsize=&negativeSamples;
run;

data private.negative1;
	set private.negative1;
	length head varchar(*);
	head = strip(NODE);
	keep head;

data private.negative2;
	set private.negative2;
	length tail varchar(*);
	tail = strip(NODE);
	keep tail;

data private.negative_edges;
	merge private.negative1 private.negative2;
run;

/* Sort and remove duplicates */
proc sort data=private.negative_edges out=private.negative_edges nodupkey;
	by head tail;
run;
	

/* Create index on table for faster processing */
proc casutil;
	index casdata="negative_edges" casout="negative_edges" replace indexvars={"head", "tail"};
	index casdata="edges" casout="edges" replace indexvars={"head", "tail"};
run;


/* Remove edges from the negative edgelist which appear in the positive edgelist */
data private.negative_edges;
	merge private.negative_edges (in=inneg) private.edges (in=inpos);
	by head tail;
	if not inpos;
	drop source;
run;

%if &testscript = 0 %then %do;
proc casutil incaslib="private" outcaslib="private";
	save casdata="negative_edges" casout="negative_edges.csv" replace;
	droptable casdata="negative1";
	droptable casdata="negative2";
run;
%end;

