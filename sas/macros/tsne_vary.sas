/**
  @file
  @author Neal Vaidya <neal.vaidya@sas.com>
  @brief produces stacked tsne embeddings at various perplexity levels

  @param [in] embeddings - dataset of embeddings (from network or factmac) to be emebedded with tsne
  @param [out] dataout - dataset where tsne embeddings are output
  @param start, end, by - define perplexity values to try
  @param maxIters - maxIters parameter for proc tsne
  @param drugsonly - only calculate tsne embeddings based on nodes that begin with 'drug'
  @param [in] drugs - table with drug info (including name, before, after)
  <h4> SAS Macros </h4>
**/

%macro tsne_vary(embeddings, dataout, start=5, end=50, by=5, maxIters=400, drugsonly=1, drugs=casuser.all_drugs);
/* You may want to consider setting the maxIters to a low value for runtime. */
caslib private path='/tmp' libref=private;

data private.tsne_input;
    set &embeddings;
    if &drugsonly then do;
        if scan(node, 1, ":")="drug" then output;
    end;
    else do;
        output;
    end;
run;


%do i=&start %to &end %by &by;
proc tsne
    seed        = 1
    data        = private.tsne_input
    nDimensions = 2
    perplexity  = &i
    maxIters    = &maxIters;
    input         vec_:;
    output
      out      = private.tsne_&i
      copyvars = (node);
run;
data private.tsne_&i;
    set private.tsne_&i;
    perplexity = &i;
run;
%end;
data private.tsne_all;
    set
    %do i=&start %to &end %by &by;
        private.tsne_&i
    %end;
    ;
    length drugbank_id varchar(*);
    if scan(node, 1, ":") = 'drug' then drugbank_id = scan(node,2,":");
run;

proc delete data=&dataout; quit;
data &dataout;
    set private.tsne_all;
run;

caslib private drop;

%mend tsne_vary;