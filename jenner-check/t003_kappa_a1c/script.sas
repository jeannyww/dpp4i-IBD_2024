/* Adapted from RnR_programs/Tian_121824/200_MI_MODEL_1 glogit.sas
   Source: the %kappa() macro and its "a1c" agreement-count dataset, copied
   verbatim. The macro's own ods graphics/gpath lines (which point at
   &OutPath., undefined outside the full pipeline) are dropped; the PROC
   FREQ agreement/kappa logic is untouched. */

/*iternation=5,GLOGIT, clinical data missing*/
data a1c;
   input true $ prediction $ count;
   datalines;
a1cless7 a1cless7 3012
a1cless7 a1c7to9 4302
a1cless7 a1cover9 2311
a1c7to9 a1cless7 4363
a1c7to9 a1c7to9 8391
a1c7to9 a1cover9 4616
a1cover9 a1cless7 2410
a1cover9 a1c7to9 4623
a1cover9 a1cover9 3117
;
run;

%macro kappa(dataset);
proc freq data=&dataset order=data;
   tables true*prediction /
          agree noprint plots=agreeplot;
   test kappa;
   weight count;
run;
%mend;
%kappa (a1c)
