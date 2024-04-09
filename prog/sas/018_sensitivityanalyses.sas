/***************************************
SAS file name: 018_sensitivity_analysis.sas

Purpose: To create sensitivity analyses for badrx and IBD definitions
Author: NA
Creation Date: 2024-04-09

Output, programs (general &goutpath., tables &toutpath., and figures &foutpath.):
        D:\Externe Projekte\UNC\wangje\out
        D:\Externe Projekte\UNC\wangje\prog\sas

Input paths:
            original raw data:  D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16
            libname a  D:\Externe Projekte\UNC\wangje\data\analysis
            libname raw  D:\Externe Projekte\UNC\wangje\data\raw
            libname temp  D:\Externe Projekte\UNC\wangje\data\temp
Other details: CPRD-DPP4i project in collaboration with USB
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=018_sensitivity_analysis.sas, savelog=N, dataset=dataname);

/*===================================*\
//SECTION - Loading data 
\*===================================*/
/* region */


/* endregion //!SECTION */

/*===================================*\
//SECTION - Bad RX
\*===================================*/
/* region */


/* endregion //!SECTION */  

/*===================================*\
//SECTION - IBD sub-definitions
\*===================================*/
/* region */


/* endregion //!SECTION */


%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);