/***************************************
SAS file name: 16_RnR_ACNUanalysisrun.sas

Purpose: To run the ACNU analysis - main analysis, untrimmed cohort (ACNU)
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

%include "D:\Externe Projekte\UNC\wangje\prog\sas\16_RnR_ACNUanalysismacro.sas";

/*===================================*\
//SECTION - Example of Macro Execution, edit this/ copy and paste and replace the macro parameters  to produce some of the sensitivity analyses, more code does need to be written for UC/CD outcomes but can be incorporated as a next step 
\*===================================*/
/* region */


*%ACNU_analysis ( exposure= dpp4i , comparator= su, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
*%ACNU_analysis ( exposure= dpp4i , comparator= su, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout , outdata=IT , save=N ) ;

/* endregion //!SECTION */

/*===================================*\
//SECTION - Execute the macro
\*===================================*/
/* region */


ods excel file="&toutpath.\RnR_MainACNU_Notrim_&todaysdate..xlsx"
options (
Sheet_interval="NONE"
embedded_titles="NO"
embedded_footnotes="NO"
);

    ods excel options(sheet_name="DPP4i_SU IT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= su, ana_name=mITac, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_TZD IT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= tzd, ana_name=mITac, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_SGLT2i IT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= sglt2i, ana_name=mITac, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_SU AT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= su, ana_name=mATac, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=AT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_TZD AT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= tzd, ana_name=mATac, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=AT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_SGLT2i AT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= sglt2i, ana_name=mATac, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=AT , save=N ) ;
    
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
		a.out_dpp4ivsglt2i_mATac_at
		a.out_dpp4ivsu_mATac3_at     
		a.out_dpp4ivtzd_mATac3_at    
		a.out_dpp4ivsglt2i_mATac3_at; 
run;
 ods rtf file="&toutPath./RnR_MainACNU_Notrim_AT_&todaysdate..rtf";
    proc print data=table2_acnu_AT; 
	var &exposure Nobs n_switch mediantime time_sum event_sum IBD_event_switchers IBD_events_censored IBD_hx_sum  rate crudehr &weight.HR;
	run;
 ods rtf close;



/* endregion //!SECTION */

/* Sensitivity analysis 3: threeyearout */

ods excel file="&toutpath.\RnR_Se2_ACNU3yrNotrim_&todaysdate..xlsx"
options (
Sheet_interval="NONE"
embedded_titles="NO"
embedded_footnotes="NO"
);
    ods excel options(sheet_name="DPP4i_SU IT 3y" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= su, ana_name=mITac3, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout, outdata=IT , save=N ) ;

    ods excel options(sheet_name="DPP4i_TZD IT 3y" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= tzd, ana_name=mITac3, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout, outdata=IT , save=N ) ;    

    ods excel options(sheet_name="DPP4i_SGLT2i IT 3y" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= sglt2i, ana_name=mITac3, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout, outdata=IT , save=N ) ;

    ods excel options(sheet_name="DPP4i_SU AT 3y" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= su, ana_name=mATac3, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout, outdata=AT , save=N ) ;

    ods excel options(sheet_name="DPP4i_TZD AT 3y" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= tzd, ana_name=mATac3, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout, outdata=AT , save=N ) ;

    ods excel options(sheet_name="DPP4i_SGLT2i AT 3y" sheet_interval="NOW");
    %ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= sglt2i, ana_name=mATac3, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout, outdata=AT , save=N ) ;
ods excel close; 
/* Printing out the Table results  */
data table2_mITac3;
	set a.out_dpp4ivsu_mITac3_it     
		a.out_dpp4ivtzd_mITac3_it    
		a.out_dpp4ivsglt2i_mITac3_it; 
run;
 ods rtf file="&toutPath./RnR_Se2_ACNU3yrNotrim_mITac3_&todaysdate..rtf";
    proc print data=table2_mITac3; 
	var &exposure Nobs n_switch mediantime time_sum event_sum IBD_event_switchers IBD_events_censored IBD_hx_sum  rate crudehr &weight.HR;
	run;
 ods rtf close; 

%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);



