/***************************************
SAS file name: 012_createcohorts.sas
Task231122 - IBDandDPP4I (db23-1)

Purpose: To consolidate _demog, _trtmt, and _event datasets into one dataset, then combine for each ACNU cohort
Author: JHW
Creation Date: 26DEC2024
Last Modified: 26DEC2024    
    Program and output path:
            D:\Externe Projekte\UNC\wangje\sas
                D:\Externe Projekte\UNC\wangje\sas\prog
            libname temp D:\Externe Projekte\UNC\wangje\data\temp

    Input paths:
                original raw data:  D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16
            libname a  D:\Externe Projekte\UNC\wangje\data\analysis
Other details: CPRD-DPP4i project in collaboration with USB

CHANGES:
Date: Date of Change
Notes: Change Notes
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\sas\macros");
%setup(programName=012_createcohorts, savelog=N, dataset=dataname);





%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);