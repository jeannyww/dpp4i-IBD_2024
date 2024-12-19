/***************************************
SAS file name: se2_3yrout.sas
- LINE 32: ACNU 
- LINE 80: TVE

Purpose: Sensitivity analysis 2: three years out, ACNU and TVE
Author: JHW
Creation Date: 2024-12-19

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
Date: Date of Change
Notes: Change Notes
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=se2_3yrout.sas, savelog=N, dataset=dataname);

/* Load ACNU_analysis macro */
%include "D:\Externe Projekte\UNC\wangje\prog\sas\16_RnR_ACNUanalysismacro.sas";
/* Load TVE_analysis macro */
%include "D:\Externe Projekte\UNC\wangje\prog\sas\17_RnR_TVEanalysismacros.sas";

/*===================================*\
//SECTION - ACNU Sensitivity Analysis 2: three years out 
\*===================================*/
/* region */
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


/* endregion //!SECTION */ 

/*===================================*\
//SECTION - TVE Sensitivity analysis 2 (threeyearout) and 1 (including prevalent IBD, exclude_IBD=N)
\*===================================*/
 /* IT analysis  */
ods excel file="&toutpath./RnR_Se12_TVE3yrNotrim_IT_&todaysdate..xlsx"
options (
    Sheet_interval="NONE"
    embedded_titles="NO"
    embedded_footnotes="NO"
);
/* Threeyearout, excluding prevalent IBD */
    ods excel options(sheet_name="DPP4i_SU IT3yr" sheet_interval="NOW");
    %TVE_analysis (pstrim=N, exclude_ibd=Y, exposure= dpp4i , comparator= su,     ana_name=mIT3tv,     type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout , outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_TZD IT3yr" sheet_interval="NOW");
    %TVE_analysis (pstrim=N, exclude_ibd=Y, exposure= dpp4i , comparator= tzd,    ana_name=mIT3tv,     type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout , outdata=IT , save=N ) ;
        
    ods excel options(sheet_name="DPP4i_SGLT2i IT3yr" sheet_interval="NOW");
    %TVE_analysis (pstrim=N, exclude_ibd=Y, exposure= dpp4i , comparator= sglt2i, ana_name=mIT3tv,     type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout , outdata=IT , save=N ) ;
/* Se2 Threeyearout, Se1 including prevalent IBD */
    ods excel options(sheet_name="se_DPP4i_SU IT3yr" sheet_interval="NOW");
    %TVE_analysis (pstrim=N, exclude_ibd=N, exposure= dpp4i , comparator= su,     ana_name=mIT3inclIBtv, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout , outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="se_DPP4i_TZD IT3yr" sheet_interval="NOW");
    %TVE_analysis (pstrim=N, exclude_ibd=N, exposure= dpp4i , comparator= tzd,    ana_name=mIT3inclIBtv, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout , outdata=IT , save=N ) ;
        
    ods excel options(sheet_name="se_DPP4i_SGLT2i IT3yr" sheet_interval="NOW");
    %TVE_analysis (pstrim=N, exclude_ibd=N, exposure= dpp4i , comparator= sglt2i, ana_name=mIT3inclIBtv, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout , outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="Log_issues" sheet_interval="NOW");
    %CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);

    ods excel close; 
    
data table2_3yr;
	set /*a.out_dpp4ivsu_mIT3ac_it*/
		a.out_dpp4ivsu_mIT3tv_it     
		a.out_dpp4ivsu_mIT3inclIBtv_it
		/*a.out_dpp4ivtzd_mIT3ac_it*/
		a.out_dpp4ivtzd_mIT3tv_it    
		a.out_dpp4ivtzd_mIT3inclIBtv_it
		/*a.out_dpp4ivsglt2i_mIT3ac_it*/
		a.out_dpp4ivsglt2i_mIT3tv_it 
		a.out_dpp4ivsglt2i_mIT3inclIBtv_it;
run;
 ods rtf file="&toutPath./RnR_Se2_TVE3yrNotrim_IT_&todaysdate..rtf";
    proc print data=table2_3yr; 
	var &exposure Nobs n_switch mediantime time_sum event_sum IBD_event_switchers IBD_events_censored IBD_hx_sum  rate crudehr &weight.HR;
	run;
 ods rtf close;


/* AT Sensitivity Analysis 2- 3yr maximum followup */
ods excel file="&toutpath./RnR_Se12_TVE3yrNotrim_AT_&todaysdate..xlsx"
options (
Sheet_interval="NONE"
embedded_titles="NO"
embedded_footnotes="NO"
);
ods excel options(sheet_name="DPP4i_SU AT3yr" sheet_interval="NOW");
%analysis_Ab (exclude_ibd=Y, exposure= dpp4i , comparator= su, ana_name=mAT3tv, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout, outdata=AT , save=N ) ;

ods excel options(sheet_name="DPP4i_TZD AT3yr" sheet_interval="NOW");
%analysis_Ab (exclude_ibd=Y, exposure= dpp4i , comparator= tzd, ana_name=mAT3tv, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout, outdata=AT , save=N ) ;
    
ods excel options(sheet_name="DPP4i_SGLT2i AT3yr" sheet_interval="NOW");
%analysis_Ab (exclude_ibd=Y, exposure= dpp4i , comparator= sglt2i, ana_name=mAT3tv, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout, outdata=AT , save=N ) ;

ods excel options(sheet_name="se12_DPP4i_SU AT3yr" sheet_interval="NOW");
%analysis_Ab (exclude_ibd=N, exposure= dpp4i , comparator= su, ana_name=mAT3inclIBtv, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout, outdata=AT , save=N ) ;

ods excel options(sheet_name="se12_DPP4i_TZD AT3yr" sheet_interval="NOW");
%analysis_Ab (exclude_ibd=N, exposure= dpp4i , comparator= tzd, ana_name=mAT3inclIBtv, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout, outdata=AT , save=N ) ;
    
ods excel options(sheet_name="se12_DPP4i_SGLT2i AT3yr" sheet_interval="NOW");
%analysis_Ab (exclude_ibd=N, exposure= dpp4i , comparator= sglt2i, ana_name=mAT3inclIBtv, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout, outdata=AT , save=N ) ;

ods excel options(sheet_name="Log12_issues" sheet_interval="NOW");
%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);

ods excel close; 


/* endregion //!SECTION */
%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);