/***************************************
SAS file name: RnR_mainanalysis

Purpose: RnR that makes the Main Analysis the *Untrimmed* population cohort 
Author: JHW
Creation Date: 2024-12-17

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
Notes: Re-creates Main Results using the Untrimmed Cohort. The PS trimmed cohort is now sensitivity analysis 
[ ] Recreates Table 2 (study population characteristics in the untrimmed cohort)
[ ] Calculates the mean time between first and second prescription for Reviewer response 
[ ] Recreates Table 3 (IT effect estimates comparison between TVE and ACNU)
[ ] Recreates Figure 2 (Kaplan Meier with 9 years followup as X axis)
[ ] Creates initial numbers for Table 4 (this is a test program)
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=RnR_mainanalysis, savelog=N, dataset=dataname);
%include "";



%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);


/*===================================*\
//SECTION - 6. Running the 'IT Analysis' a la Abrahami, adapted from 016_analysis.sas
\*===================================*/
/* region */
/*---------------------------------------------------------------------
%analysis_Ab(
exposure =  ,   *exposure drug of interest: DPP4i;
comparator =  , *comparator drug: SU TZD;    
ana_name =  ,    *name of analysis: main, sensitivity, etc.;
type =  ,        *type of analysis: AT (as treated) or ITT (initial treatment);
weight =  ,       *type of weighting used: iptw, siptw, smrw, smrwu, ssmrwu;
induction =  ,    *induction period for dz initiation 180d;
latency =  ,      *latency period for dz detection 180d;
ibd_def =  ,      *IBD definition used (free text, ie main definition); 
intime =  ,       *time which analysis fu time will start, ie: entry (date of 2nd rx), initiation_date (date of 1st rx);
outtime =  ,      *time which analysis fu ends, ie for AT: '31Dec2017'd, for ITT: oneyearout twoyearout threeyearout fouryearout;
 outdata =        *freetext for your chosen name of the outdata results ;
)

%analysis_Ab ( exposure= , comparator=, ana_name=, type=, weight=, induction=, latency=, ibd_def= , intime= , outtime= , outdata= );

%analysis_Ab ( exposure=  
, comparator=
, ana_name=
, type=
, weight=
, induction=
, latency=
, ibd_def=
, intime=  
, outtime=  
, outdata= );

    
    ---------------------------------------------------------------------*/
    *%analysis_Ab (exclude_ibd=N, exposure= dpp4i , comparator= su, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    *%analysis_Ab (exclude_ibd=N, exposure= dpp4i , comparator= su, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime=threeyearout , outdata=IT , save=N ) ;

%let exclude_ibd=N;
%let exposure= dpp4i;
%let comparator= su;
%let ana_name=mITtv;
%let type= IT;
%let weight= smrw;
%let induction= 180;
%let latency= 180;
%let ibd_def= ibd1;
%let intime= filldate2;
%let outtime='31Dec2022'd;
%let outdata=IT;
%let save=N;
%let label1=DPP4i;
%let label2=SU;
