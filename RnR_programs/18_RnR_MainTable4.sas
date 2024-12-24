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

/* Load ACNU_analysis macro */
%include "D:\Externe Projekte\UNC\wangje\prog\sas\16_RnR_ACNUanalysismacro.sas";
/* Load TVE_analysis macro */
%include "D:\Externe Projekte\UNC\wangje\prog\sas\17_RnR_TVEanalysismacros.sas";

/*===================================*\
//SECTION - ACNU IT Main Analysis, focusing on the DPP4i vs. TZD cohort for counts
\*===================================*/
/* region */

/* DSN ACNU  */
%ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= tzd, ana_name=mITac, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , num_years=9, outdata=IT , save=N ) ;

data dsn_ACNU; 
    set dsn; 
RUN;  

proc print data=a.out_dpp4ivtzd_mITac_it;
    RUN;

/* Events */
PROC FREQ DATA=dsn_ACNU;
TABLES dpp4i*event /list missing;
RUN;

/* Person-time */
proc means data=dsn_ACNU 
    STACKODS N NMISS MEAN STD MIN MAX Q1 MEDIAN Q3   ;
class dpp4i ;
var  time ; 
run;

/*===================================*\
//SECTION - TVE counts, focusing on the DPP4i vs. TZD cohort
\*===================================*/
/* region */


%TVE_analysis (pstrim=N, exclude_ibd=Y, exposure= dpp4i , comparator= tzd, ana_name=mITtv, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , num_years=9, outdata=IT , save=N ) ;

data dsn_TVE;
    set dsn;    
run;

proc print data=out_dpp4ivtzd_mITtv_it;
    RUN;

/* Based on switcher variable created in line 169 of %getCohort_Ab() macro from program 17_RnR_TVEanalysismacros */
/* 
0=pure exposure (dpp4i)
1=switcher (dpp4i person time after switch from comparator)

2= comparator who switched to DPP4i later 
3= pure comparator 

4= early switcher w/o filldate2
5= reverse switcher w/o filldate2
6= pure comparator w/o filldate2*/

/* Events */
PROC FREQ DATA=dsn_tve;
TABLES dpp4i*event /list missing;
RUN;

PROC FREQ DATA=dsn_tve;
TABLES dpp4i*switcher*event /list missing;
RUN;

proc means data= dsn_tve sum stackods;
    class dpp4i; 
    var event; 
    RUN;

/* Person time */
proc means data= dsn_tve  STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ;
class  dpp4i ;
var  time ; 
run;

/* “Among DPP4i users, switchers and non-switchers had a median follow-up of XXX and YYY, respectively.” */
proc means data= dsn_tve  STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ;
where dpp4i=1;
class  switcher ;
var  time ; 
run;

proc means data= dsn_tve  STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ;
where dpp4i=0;
class  switcher ;
var  time ; 
run;


/* endregion //!SECTION */
%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);



