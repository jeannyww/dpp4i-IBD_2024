/***************************************
SAS file name: 18_RnR_Se3_pstrim.sas

Purpose: Sensitivity Analysis 3
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
%setup(programName=18_RnR_Se3_pstrim.sas, savelog=N, dataset=dataname);

/* Load ACNU_analysis macro */
%include "D:\Externe Projekte\UNC\wangje\prog\sas\16_RnR_ACNUanalysismacro.sas";
/* Load TVE_analysis macro */
%include "D:\Externe Projekte\UNC\wangje\prog\sas\17_RnR_TVEanalysismacros.sas";

/*===================================*\
//SECTION - Sensitivity Analysis 3: ACNU, PS Trimmed 
\*===================================*/
/* region */
ods excel file="&toutpath.\RnR_Se3ACNU_trim_&todaysdate..xlsx"
options (
Sheet_interval="NONE"
embedded_titles="NO"
embedded_footnotes="NO"
);

    ods excel options(sheet_name="DPP4i_SU IT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=Y, exposure= dpp4i , comparator= su, ana_name=mITac, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_TZD IT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=Y, exposure= dpp4i , comparator= tzd, ana_name=mITac, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_SGLT2i IT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=Y, exposure= dpp4i , comparator= sglt2i, ana_name=mITac, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_SU AT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=Y, exposure= dpp4i , comparator= su, ana_name=mATac, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=AT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_TZD AT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=Y, exposure= dpp4i , comparator= tzd, ana_name=mATac, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=AT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_SGLT2i AT" sheet_interval="NOW");
    %ACNU_analysis (pstrim=Y, exposure= dpp4i , comparator= sglt2i, ana_name=mATac, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=AT , save=N ) ;
    
    ods excel options(sheet_name="Log_issues" sheet_interval="NOW");

    %CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);

ods excel close; 


/* Printing Table Results  */
	data table2_mITac;
	set a.out_dpp4ivsu_mITac_it     
		a.out_dpp4ivtzd_mITac_it    
		a.out_dpp4ivsglt2i_mITac_it;
run;
 ods rtf file="&toutPath./RnR_Se3ACNU_trim_IT_&todaysdate..rtf";
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
 ods rtf file="&toutPath./RnR_Se3ACNU_trim_AT_&todaysdate..rtf";
    proc print data=table2_acnu_AT; 
	var &exposure Nobs n_switch mediantime time_sum event_sum IBD_event_switchers IBD_events_censored IBD_hx_sum  rate crudehr &weight.HR;
	run;
 ods rtf close;
/* endregion //!SECTION */

/*===================================*\
//SECTION - TVE Sensitivity Analysis 3: PS Trimmed
\*===================================*/
/* region */


/* Main IT analysis and Se analysis 1 (including prevalent IBD) */
ods excel file="&toutpath./RnR_MainSe1TVE_Notrim_IT_&todaysdate..xlsx"
options (
    Sheet_interval="NONE"
    embedded_titles="NO"
    embedded_footnotes="NO"
);
    /* IT analysis, pstrim=Y */
    /* Exclude IBD=Y */
    ods excel options(sheet_name="DPP4i_SU IT" sheet_interval="NOW");
    %TVE_analysis (pstrim=Y, exclude_ibd=Y, exposure= dpp4i , comparator= su, ana_name=mITtv, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_TZD IT" sheet_interval="NOW");
    %TVE_analysis (pstrim=Y, exclude_ibd=Y, exposure= dpp4i , comparator= tzd, ana_name=mITtv, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
        
    ods excel options(sheet_name="DPP4i_SGLT2i IT" sheet_interval="NOW");
    %TVE_analysis (pstrim=Y, exclude_ibd=Y, exposure= dpp4i , comparator= sglt2i, ana_name=mITtv, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    
    /* AT analysis, pstrim=Y */
    /* Exclude IBD=Y */
    ods excel options(sheet_name="DPP4i_SU AT" sheet_interval="NOW");
    %analysis_Ab (ps_trim=Y, exclude_ibd=Y, exposure= dpp4i , comparator= su, ana_name=mATtv, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=AT , save=N ) ;

    ods excel options(sheet_name="DPP4i_TZD AT" sheet_interval="NOW");
    %analysis_Ab (ps_trim=Y, exclude_ibd=Y, exposure= dpp4i , comparator= tzd, ana_name=mATtv, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=AT , save=N ) ;
        
    ods excel options(sheet_name="DPP4i_SGLT2i AT" sheet_interval="NOW");
    %analysis_Ab (ps_trim=Y, exclude_ibd=Y, exposure= dpp4i , comparator= sglt2i, ana_name=mATtv, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=AT , save=N ) ;
    
    /* Check log */
    ods excel options(sheet_name="Log_issues" sheet_interval="NOW");
    %CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);

    ods excel close; 

/* Save TVE IT Table 1 */
data table2_primary_tve;
	set /*a.out_dpp4ivsu_mITac_it*/
		a.out_dpp4ivsu_mITtv_it     
		/*a.out_dpp4ivtzd_mITac_it*/
		a.out_dpp4ivtzd_mITtv_it    
		/*a.out_dpp4ivsglt2i_mITac_it*/
		a.out_dpp4ivsglt2i_mITtv_it ;
run;
 ods rtf file="&toutPath./RnR_Se3TVE_trim_IT_&todaysdate..rtf";
    proc print data=table2_primary_tve; 
	var &exposure Nobs n_switch mediantime time_sum event_sum IBD_event_switchers IBD_events_censored IBD_hx_sum  rate crudehr &weight.HR;
	run;
 ods rtf close;

/* endregion //!SECTION */

%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);