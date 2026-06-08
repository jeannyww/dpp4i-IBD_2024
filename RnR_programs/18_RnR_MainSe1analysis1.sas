/***************************************
SAS file name: 16_RnR_ACNUanalysisrun.sas

Purpose: To run the ACNU analysis - main analysis, untrimmed cohort (ACNU)
Contains: 
- LINE 35: ACNU MAIN Analysis, IT and AT
- 

Author: JHW
Creation Date: 2024-12-18

Output, programs (general &goutpath., tables &toutpath., and figures &foutpath.):
        D:\Externe Projekte\UNC\wangje\out
        D:\Externe Projekte\UNC\wangje\prog\sas

Input paths:
original raw data:  D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16
libname a  D:\Externe Projekte\UNC\wangje\data\analysis
libname raw  D:\Externe Projekte\UNC\wangje\data\raw
libname temp  D:\Externe Projekte\UNC\wangje\data\temp
Other details: CPRD-DPP4i project in collaboration with USB

CHANGES:
Date: 2024-12-18
Notes: Separated the analysis macro from running the ACNU analysis program 
***************************************/ 
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=16_RnR_ACNUanalysisrun.sas, savelog=N, dataset=dataname);
dm 'next explorer; detail';

/* Load ACNU_analysis macro */
%include "D:\Externe Projekte\UNC\wangje\prog\sas\macro_TVE_analysis.sas";
/* Load TVE_analysis macro */
%include "D:\Externe Projekte\UNC\wangje\prog\sas\macro_ACNU_analysis.sas";

/*===================================*\
//SECTION - Sensitivity analysis: three years out
\*===================================*/
/* region */
/* Lenth of x axis in years for the KM plot */
%let num=3;

%TVE_analysis (pstrim=N, exclude_ibd=Y, 
exposure= dpp4i , comparator= su,
ana_name=ITtv3yr, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime=threeyearout ,
numyears=&num, outdata=IT , save=N, data_prefix= ) ;proc print data=   tmp_counts;  
run; 

%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= su, 
ana_name=ITac3yr, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime=threeyearout ,
numyears=&num, outdata=IT , save=N, data_prefix= ) ;proc print data=   tmp_counts;  
run; 
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=su);

title ""; 
%TVE_analysis (pstrim=N, exclude_ibd=Y, 
exposure= dpp4i , comparator= tzd,
ana_name=ITtv3yr, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime=threeyearout ,
numyears=&num, outdata=IT , save=N, data_prefix= ) ;proc print data=   tmp_counts;  
run; 

%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= tzd, 
ana_name=ITac3yr, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime=threeyearout ,
numyears=&num, outdata=IT , save=N, data_prefix= ) ;proc print data=   tmp_counts;  
run; 
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=tzd);
title ""; 

%TVE_analysis (pstrim=N, exclude_ibd=Y, 
exposure= dpp4i , comparator= sglt2i,
ana_name=ITtv3yr, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime=threeyearout ,
numyears=&num, outdata=IT , save=N, data_prefix= ) ;proc print data=   tmp_counts;  
run; 
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= sglt2i, 
ana_name=ITac3yr, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime=threeyearout ,
numyears=&num, outdata=IT , save=N, data_prefix= ) ;proc print data=   tmp_counts;  
run; 
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=sglt2i);
title ""; 

/*===================================*\
//SECTION - ACNU Main Analysis IT untrimmed
\*===================================*/
/* region */

/*sglt2i*/
%let num=9;
%TVE_analysis (pstrim=N, exclude_ibd=Y, 
exposure= dpp4i , comparator= sglt2i,
ana_name=mITtv, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N, data_prefix=) ;
proc print data=   tmp_counts;  
run; 
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= sglt2i, 
ana_name=mITac, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N, data_prefix= ) ;
proc print data=   tmp_counts;  
run; 
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=sglt2i);
title ""; 


title ""; 

/*TZD*/
%let num=9;
%TVE_analysis (pstrim=N, exclude_ibd=Y, 
exposure= dpp4i , comparator= tzd,
ana_name=mITtv, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N, data_prefix=) ;
proc print data=   tmp_counts;  
run; 
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= tzd, 
ana_name=mITac, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N, data_prefix= ) ;
proc print data=   tmp_counts;  
run; 
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=tzd);
title ""; 


/*SU*/
%let num=9;
%TVE_analysis (pstrim=N, exclude_ibd=Y, 
exposure= dpp4i , comparator= SU,
ana_name=mITtv, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N, data_prefix=) ;
proc print data=   tmp_counts;  
run; 
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= SU, 
ana_name=mITac, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N, data_prefix= ) ;
proc print data=   tmp_counts;  
run; 
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=SU);
title ""; 


/*===================================*\
main analysis AT untrimmed
\*===================================*/

title "NO pstrim"; 
%TVE_analysis (pstrim=N, exclude_ibd=Y, 
exposure= dpp4i , comparator= tzd,
ana_name=mATtv, type= AT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=AT , save=N ) ;
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= tzd, 
ana_name=mATac, type= AT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=AT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=tzd);
title ""; 
title "NO pstrim"; 
%TVE_analysis (pstrim=N, exclude_ibd=Y, 
exposure= dpp4i , comparator= su,
ana_name=mATtv, type= AT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=AT , save=N ) ;
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= su, 
ana_name=mATac, type= AT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=AT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=su);
title ""; 
title "NO pstrim"; 
%TVE_analysis (pstrim=N, exclude_ibd=Y, 
exposure= dpp4i , comparator= sglt2i,
ana_name=mATtv, type= AT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=AT , save=N ) ;
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= sglt2i, 
ana_name=mATac, type= AT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=AT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator= sglt2i);


title "YES ps trim"; 
%ACNU_analysis (pstrim=Y, 
exposure= dpp4i , comparator= sglt2i, 
ana_name=mATac, type= AT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=AT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator= sglt2i);
title ""; 

/*===================================*\
sensitivity AT analysis with extended censoring criteria
extended censoring criteria in as-treated ACNU analyses to include patients starting SU, TZD, or SGLT2i (for non-comparator drug) during follow-up
\*===================================*/
%LET num = 9;
title "NO pstrim extended censoring AT dpp4 v tzd"; 
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= tzd, 
ana_name=mATac, type= ATEXT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=ATEXT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=tzd);
title ""; 
title "NO pstrim extended censoring AT dpp4 v su"; 
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= su, 
ana_name=mATac, type= ATEXT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=ATEXT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=su);
title ""; 
title "NO pstrim extended censoring AT dpp4 v sglt2i";  
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= sglt2i, 
ana_name=mATac, type= ATEXT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=ATEXT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator= sglt2i);
/*===================================*\
main analysis IT threeyearout
\*===================================*/

%let num=3;
%TVE_analysis (pstrim=N, exclude_ibd=Y, 
exposure= dpp4i , comparator= tzd,
ana_name=mIT3tv, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime=threeyearout ,
numyears=&num, outdata= IT , save=N ) ;
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= tzd, 
ana_name=mITac3, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime=threeyearout ,
numyears=&num, outdata= IT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=tzd);


title ""; 
%TVE_analysis (pstrim=N, exclude_ibd=Y, 
exposure= dpp4i , comparator= su,
ana_name=mIT3tv, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime=threeyearout ,
numyears=&num, outdata= IT , save=N ) ;
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= su, 
ana_name=mITac3, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime=threeyearout ,
numyears=&num, outdata= IT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=su);
title ""; 
title ""; 
%TVE_analysis (pstrim=N, exclude_ibd=Y, 
exposure= dpp4i , comparator= sglt2i,
ana_name=mIT3tv, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime=threeyearout ,
numyears=&num, outdata= IT , save=N ) ;
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= sglt2i, 
ana_name=mITac3, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime=threeyearout ,
numyears=&num, outdata= IT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator= sglt2i);
title ""; 

/*===================================*\
//SECTION - ACNU IT untrimmed INCLIBD Exclude_IBD=N
\*===================================*/
/* region */

%let num=9;
%TVE_analysis (pstrim=N, exclude_ibd=N, 
exposure= dpp4i , comparator= sglt2i,
ana_name=mITinclIBtv, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= sglt2i, 
ana_name=mITinclIBac, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=sglt2i);
title ""; 

%TVE_analysis (pstrim=N, exclude_ibd=N, 
exposure= dpp4i , comparator= tzd,
ana_name=mITinclIBtv, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= tzd, 
ana_name=mITinclIBac, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=tzd);
title ""; 

%TVE_analysis (pstrim=N, exclude_ibd=N, 
exposure= dpp4i , comparator= su,
ana_name=mITinclIBtv, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= su, 
ana_name=mITinclIBac, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=su);
title ""; 



/*===================================*\
//SECTION - ACNU Main Analysis IT TRIMMED
\*===================================*/
/* region */

%let num=9;
%TVE_analysis (pstrim=Y, exclude_ibd=Y, 
exposure= dpp4i , comparator= sglt2i,
ana_name=mITtvtrim, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;
%ACNU_analysis (pstrim=Y, 
exposure= dpp4i , comparator= sglt2i, 
ana_name=mITactrim, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=sglt2i);
title ""; 

%TVE_analysis (pstrim=Y, exclude_ibd=Y, 
exposure= dpp4i , comparator= tzd,
ana_name=mITtvtrim, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;
%ACNU_analysis (pstrim=Y, 
exposure= dpp4i , comparator= tzd, 
ana_name=mITactrim, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=tzd);
title ""; 

%TVE_analysis (pstrim=Y, exclude_ibd=Y, 
exposure= dpp4i , comparator= su,
ana_name=mITtvtrim, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;
%ACNU_analysis (pstrim=Y, 
exposure= dpp4i , comparator= su, 
ana_name=mITactrim, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=su);
title ""; 

/*=================*\
Excel output if necessary but old code
\*=================*/

%LET num=9; *variable numyears for max years of KM plot ;

ods excel file="&toutpath.\RnR_MainACNU_Notrim_&todaysdate..xlsx"
options (
Sheet_interval="NONE"
embedded_titles="NO"
embedded_footnotes="NO"
);

    ods excel options(sheet_name="DPP4i_SU IT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= su, ana_name=mITac, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_TZD IT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= tzd, ana_name=mITac, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_SGLT2i IT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= sglt2i, ana_name=mITac, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_SU AT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= su, ana_name=mATac, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=AT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_TZD AT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= tzd, ana_name=mATac, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=AT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_SGLT2i AT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= sglt2i, ana_name=mATac, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=AT , save=N ) ;
    
    ods excel options(sheet_name="Log_issues" sheet_interval="NOW");

    %CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);

    ods excel close; 

/* Printing Table Results  */
	data table2_mITac;
	set a.out_dpp4ivsu_mITac_it     
		a.out_dpp4ivtzd_mITac_it    
		a.out_dpp4ivsglt2i_mITac_it;
run;
 ods rtf file="&toutPath./RnR_MainACNU_Notrim_IT_&todaysdate..rtf";
    proc print data=table2_mITac; 
	var &exposure Nobs n_switch mediantime time_sum event_sum IBD_event_switchers IBD_events_censored IBD_hx_sum  rate crudehr &weight.HR;
	run;
 ods rtf close;


 	data table2_acnu_AT;
	set a.out_dpp4ivsu_mATac_at     
		a.out_dpp4ivtzd_mATac_at    
		a.out_dpp4ivsglt2i_mATac_at; 
run;
 ods rtf file="&toutPath./RnR_MainACNU_Notrim_AT_&todaysdate..rtf";
    proc print data=table2_acnu_AT; 
	var &exposure Nobs n_switch mediantime time_sum event_sum IBD_event_switchers IBD_events_censored IBD_hx_sum  rate crudehr &weight.HR;
	run;
 ods rtf close;

/* endregion //!SECTION */

/*===================================*\
//SECTION -  TVE MAIN analysis (pstrim=N, exclude_IBD=Y) and SENSITIVITY ANALYSIS 1 (including prevalent IBD), IT and AT 
\*===================================*/

/* Main IT analysis and Se analysis 1 (including prevalent IBD) */
ods excel file="&toutpath./RnR_MainSe1TVE_Notrim_IT_&todaysdate..xlsx"
options (
    Sheet_interval="NONE"
    embedded_titles="NO"
    embedded_footnotes="NO"
);
    /* Exclude IBD=Y */
    ods excel options(sheet_name="DPP4i_SU IT" sheet_interval="NOW");
    %TVE_analysis (pstrim=N, exclude_ibd=Y, exposure= dpp4i , comparator= su, ana_name=mITtv, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_TZD IT" sheet_interval="NOW");
    %TVE_analysis (pstrim=N, exclude_ibd=Y, exposure= dpp4i , comparator= tzd, ana_name=mITtv, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=IT , save=N ) ;
        
    ods excel options(sheet_name="DPP4i_SGLT2i IT" sheet_interval="NOW");
    %TVE_analysis (pstrim=N, exclude_ibd=Y, exposure= dpp4i , comparator= sglt2i, ana_name=mITtv, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=IT , save=N ) ;
    
    /* Exclude IBD=N */
    ods excel options(sheet_name="se1_DPP4i_SU IT" sheet_interval="NOW");
    %TVE_analysis (pstrim=N, exclude_ibd=N, exposure= dpp4i , comparator= su, ana_name=mITinclIBtv, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=IT , save=N) ;
    
    ods excel options(sheet_name="se1_DPP4i_TZD IT" sheet_interval="NOW");
    %TVE_analysis (pstrim=N, exclude_ibd=N, exposure= dpp4i , comparator= tzd, ana_name=mITinclIBtv, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=IT , save=N ) ;
        
    ods excel options(sheet_name="se1_DPP4i_SGLT2i IT" sheet_interval="NOW");
    %TVE_analysis (pstrim=N, exclude_ibd=N, exposure= dpp4i , comparator= sglt2i, ana_name=mITinclIBtv, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="Log_issues" sheet_interval="NOW");
    %CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);

    ods excel close; 

data table2_primary_tve;
	set /*a.out_dpp4ivsu_mITac_it*/
		a.out_dpp4ivsu_mITtv_it     
		a.out_dpp4ivsu_mITinclIBtv_it
		/*a.out_dpp4ivtzd_mITac_it*/
		a.out_dpp4ivtzd_mITtv_it    
		a.out_dpp4ivtzd_mITinclIBtv_it
		/*a.out_dpp4ivsglt2i_mITac_it*/
		a.out_dpp4ivsglt2i_mITtv_it 
		a.out_dpp4ivsglt2i_mITinclIBtv_it;
run;
 ods rtf file="&toutPath./RnR_MainSe1TVE_Notrim_IT_&todaysdate..rtf";
    proc print data=table2_primary_tve; 
	var &exposure Nobs n_switch mediantime time_sum event_sum IBD_event_switchers IBD_events_censored IBD_hx_sum  rate crudehr &weight.HR;
	run;
 ods rtf close;

 
/* Added AT analysis  */
ods excel file="&toutpath./RnR_MainSe12TVE_Notrim_AT_&todaysdate..xlsx"
options (
Sheet_interval="NONE"
embedded_titles="NO"
embedded_footnotes="NO"
);
ods excel options(sheet_name="DPP4i_SU AT" sheet_interval="NOW");
%analysis_Ab (ps_trim=N, exclude_ibd=Y, exposure= dpp4i , comparator= su, ana_name=mATtv, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=AT , save=N ) ;

ods excel options(sheet_name="DPP4i_TZD AT" sheet_interval="NOW");
%analysis_Ab (ps_trim=N, exclude_ibd=Y, exposure= dpp4i , comparator= tzd, ana_name=mATtv, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=AT , save=N ) ;
    
ods excel options(sheet_name="DPP4i_SGLT2i AT" sheet_interval="NOW");
%analysis_Ab (ps_trim=N, exclude_ibd=Y, exposure= dpp4i , comparator= sglt2i, ana_name=mATtv, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=AT , save=N ) ;

ods excel options(sheet_name="se_DPP4i_SU AT" sheet_interval="NOW");
%analysis_Ab (ps_trim=N, exclude_ibd=N, exposure= dpp4i , comparator= su, ana_name=mATinclIBtv, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=AT , save=N ) ;

ods excel options(sheet_name="se_DPP4i_TZD AT" sheet_interval="NOW");
%analysis_Ab (ps_trim=N, exclude_ibd=N, exposure= dpp4i , comparator= tzd, ana_name=mATinclIBtv, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=AT , save=N ) ;
    
ods excel options(sheet_name="se_DPP4i_SGLT2i AT" sheet_interval="NOW");
%analysis_Ab (ps_trim=N, exclude_ibd=N, exposure= dpp4i , comparator= sglt2i, ana_name=mATinclIBtv, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , numyears=&num, outdata=AT , save=N ) ;

ods excel options(sheet_name="Log_issues" sheet_interval="NOW");
%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);
 
ods excel close; 

data table2_tve_AT;
	set /*a.out_dpp4ivsu_mATac_At*/
		a.out_dpp4ivsu_mATtv_At     
		a.out_dpp4ivsu_mATinclIBtv_At
		/*a.out_dpp4ivtzd_mATac_At*/
		a.out_dpp4ivtzd_mATtv_At    
		a.out_dpp4ivtzd_mATinclIBtv_At
		/*a.out_dpp4ivsglt2i_mATac_At*/
		a.out_dpp4ivsglt2i_mATtv_At 
		a.out_dpp4ivsglt2i_mATinclIBtv_At;
run;
 ods rtf file="&toutPath./RnR_MainSe1TVE_Notrim_AT_&todaysdate..rtf";
    proc print data=table2_primary_tve; 
	var &exposure Nobs n_switch mediantime time_sum event_sum IBD_event_switchers IBD_events_censored IBD_hx_sum  rate crudehr &weight.HR;
	run;
 ods rtf close;

%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);



