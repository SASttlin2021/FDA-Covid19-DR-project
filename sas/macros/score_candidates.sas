/**
  @file
  @author Neal Vaidya <neal.vaidya@sas.com>
  @brief Score candidate list against true list
  <h4> SAS Macros </h4>
**/

%macro score_candidates(candidates,drugs);
caslib private path='/tmp' libref=private;

data private.drugs;
  set &drugs;
  candidate=&candidates;
  if not before;
  keep name drugbank_id after candidate;

title "&candidates assessment";
proc assess data=private.drugs ncuts=2 nbins=2;
  var candidate;
  target after / event='1' level=nominal;
run;
caslib private drop;
%mend score_candidates;