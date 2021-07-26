%macro label_nodes(embeddings, drugs, candidate);


data &embeddings(replace=yes promote=yes);
  length class varchar(*);
  merge &embeddings &drugs;
  by drugbank_id;
  candidate=incand;
  if before then class="Before";
  if &candidate and after then class="Candidate and After";
  if &candidate and not after then class="Candidate and Not After";
  if not &candidate and after then class="Not Candidate and After";
  if not &candidate and not after then class="Not Candidate and Not After";
  drop drug;
run;

%mend label_nodes;