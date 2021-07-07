/**
  @file
  @author Neal Vaidya <neal.vaidya@sas.com>
  @brief produces stacked tsne embeddings at various perplexity levels

  @param [in] datain - dataset in 'embedding' caslib to be emebedded with tsne
  @param [out] dataout - dataset in 'visualization' caslib where tsne embeddings are output
  @param start, end, by - define perplexity values to try
  @param maxIters - maxIters parameter for proc tsne
  @param drugsonly - only calculate tsne embeddings based on nodes that begin with 'drug'
  <h4> SAS Macros </h4>
**/
%macro tsne_vary(datain, dataout, start=5, end=50, by=5, maxIters=400, drugsonly=0);
/* You may want to consider setting the maxIters to a low value for runtime. */
cas tsnesession;
libname casuser cas caslib="casuser";
libname embed cas caslib="embedding";
libname visual cas caslib="visualization";
libname public cas caslib="public";

data casuser.tsne_input;
    set embed.&datain;
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
    data        = casuser.tsne_input
    nDimensions = 2
    perplexity  = &i
    maxIters    = &maxIters;
    input         vec_:;
    output
      out      = casuser.tsne_&i
      copyvars = (node);
run;
data casuser.tsne_&i;
    set casuser.tsne_&i;
    perplexity = &i;
run;
%end;
data casuser.tsne_all;
    set
    %do i=&start %to &end %by &by;
        casuser.tsne_&i
    %end;
    ;
    length drugbank_id varchar(*);
    if substr(node, 1, 2) = 'DB' then drugbank_id = node;
run;

data casuser.tsne_all;
    merge casuser.tsne_all public.dbsmallm_truth;
    by drugbank_id;
run;

proc casutil;
    droptable casdata="&dataout" incaslib="visualization" quiet;
    promote incaslib="casuser" casdata="tsne_all" outcaslib="visualization" casout="&dataout";
quit;

cas tsnesession terminate;
%mend tsne_vary;