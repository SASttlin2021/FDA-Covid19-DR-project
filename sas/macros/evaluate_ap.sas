

%macro evaluate_ap(candidates, truth, rankingCol);

/* %let candidates=repo.net5candidates2; */
/* %let truth=repo.truth; */
/* %let rankingCol = distance; */

caslib private path='/tmp' libref=private;
proc sort data=&candidates out=private.candidates;
	by drugbank_id;
run;
proc sort data=&truth out=private.truth;
	by drugbank_id;
run;

data private.merged;
	merge private.candidates(in=pin) private.truth(in=tin);
	by drugbank_id;
	in_pred = pin; in_truth=tin;
	if in_pred;
	if in_truth then accurate=1; else accurate=0;
	keep name drugbank_id in_pred in_truth &rankingCol;

proc sql;
	create table work.merged as
	select *, sum(in_truth) as P
	from private.merged
	order by &rankingCol;
quit;


data work.merged;
	set work.merged;
	retain TP FP avg_p;
	if _n_ = 1 then do;
		TP=0;
		FP=0;
		avg_p = 0;
	end;
	if in_truth then TP+1;
	else FP+1;
	precision = TP/(TP+FP);
	recall = TP/P;
	avg_p + (precision * (recall - lag1(recall)));
run;	

data work.avg_p;
	set work.merged end=eof;
	if eof;
	keep avg_p;
run;

proc print data=work.avg_p; run; quit;

proc datasets;
	delete avg_p;
	delete merged;
run;
quit;

caslib private drop;
%mend evaluate_ap;

