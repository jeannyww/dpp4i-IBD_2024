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