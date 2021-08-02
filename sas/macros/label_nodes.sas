%macro label_nodes(embeddings, drugs, candidate);

caslib private datasource=(srctype="path") path="&datapath/intermediate/network2" 
   sessref=&sessionName libref=private;

data private.embeddings(replace=yes);
  length class varchar(*);
  merge &embeddings &drugs;
  by drugbank_id;
  if before=1 then do;
	class="Before";
  end; else do;
	if &candidate and after then class="Candidate and After";
	if &candidate and not after then class="Candidate and Not After";
	if not &candidate and after then class="Not Candidate and After";
	if not &candidate and not after then class="Not Candidate and Not After";
  end;
  drop drug;
run;

proc delete data=&embeddings; quit;

data &embeddings(promote=yes);
  set private.embeddings;
run; 

caslib private drop;

%mend label_nodes;