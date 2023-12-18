/**
  @file
  @brief <Your brief here>
  <h4> SAS Macros </h4>
**/
%macro table2(name, analysis);
Data table2_&analysis;
   set ana.out_dppvsu_&name ana.out_dppvtzd_&name;
     label time_Sum = "Person-year"
          event_Sum = "No. of Event";
	 format Nobs COMMA12. event_sum COMMA12. time_sum COMMA12. ;
   run;
data table2_&analysis;
	set table2_&analysis;

options orientation=landscape;
ODS rtf FILE="&outpath./table2_&name._&analysis._%sysfunc(date(),date.).rtf";
PROC PRINT DATA=table2_&analysis;
title "&name &analysis";
RUN;
ODS rtf CLOSE;
%mend table2;
