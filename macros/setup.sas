/**setup*/
*Assigning libnames, titles, footnotes for project, run for sample;
%macro setup ( programName , savelog , dataset);

%GLOBAL ProjDir progpath LogPath LogDate;
%LET ProjDir = D:\Externe Projekte\UNC\wangje;
%let progpath = D:\Externe Projekte\UNC\wangje\sas\prog;
%let logpath =  &progpath.\log ;
%LET LogDate = %sysfunc(date(),yymmddn8.);

/* if save log specified, adapted from Virginia's setup.sas macro  */
      %IF &saveLog = Y %THEN %DO;
         %LET programNameP = %SYSFUNC(translate(&programName,_,/));
         proc printto new log="&LogPath./&logDate._&programNameP..log"; run;
         options fullstimer mprint;
      %END;

/* defining libnames */
LIBNAME raw "&projdir.\data\raw";/* raw datasets */
LIBNAME a "&projdir.\data\analysis";/* analysis datasets */

/* Output datasets */
LIBNAME temp  "&projdir.\data\temp";

%GLOBAL goutpath toutpath foutpath;
/* Defining outpaths */
%LET goutpath = &projdir.\sas\out\;
%LET toutpath = &projdir.\sas\out\tables;
%LET foutpath = &projdir.\sas\out\figures;

/* including formats */
%include "&projdir.\sas\formats\formats.sas";

/* define footnotes and titles */
      %GLOBAL footnote1 footnote2 todaysdate;
      %LET todaysdate = %SYSFUNC(today(), DATE9.);
      %LET footnote1 = %STR(j=l "Program: &ProgPath./&programName..sas");
      %LET footnote2 = %STR(j=l "Run on the &dataset. dataset by &SYSUSERID. on &SYSDATE. ");

footnote1 &footnote1.;
footnote2 &footnote2.;
%mend setup;

