proc casutil incaslib="reposition" outcaslib="casuser" sessref="&sessionName";
    load casdata="coronaviewer.csv" casout="CoronaViewer";
    load casdata="dbsmallm_truth.csv" casout="dbsmallm_truth";
quit;

data casuser.CoronaViewer;
    set casuser.CoronaViewer;
    if ID = 17 then Positive_Trials_Completed = '2/4';
    else if ID = 19 then Positive_Trials_Completed = '2/3';
    else if ID = 74 then Positive_Trials_Completed = '2/4';
run;


proc fedsql sessref=&sessionName;
    create table casuser.Matches as select
    Coronaviewer.Drug, DBSmallm_truth.Name
    from casuser.Coronaviewer, casuser.DBSmallm_Truth where
    upcase(Coronaviewer.Drug) = upcase(DBSmallm_Truth.Name);
run;
/*219/2635 Matches with DBSmallm_Truth.csv*/

proc cas;
  session mySession;
  table.fetch  /
    format=true
    table="Matches"
    to=5;
run;
quit;

proc fedsql sessref=mySession;
    create table casuser.MatchesTruth as select
    Coronaviewer.Drug, Truth.iName
    from public.Coronaviewer, public.Truth where
    upcase(Coronaviewer.Drug) = upcase(Truth.iName);
run;
/*86/251 matches on Truth.csv*/

cas mySession terminate;