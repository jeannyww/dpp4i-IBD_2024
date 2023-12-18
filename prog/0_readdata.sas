/***************************************
 SAS file name: 0_readdata.sas

Purpose: for reading in V2 of dataset 
Author: JHW
Creation Date: Created on 2021-04-29 10:00:00

    Program and output path:
            D:\Externe Projekte\UNC\wangje\sas
                D:\Externe Projekte\UNC\wangje\sas\prog
            libname temp D:\Externe Projekte\UNC\wangje\data\temp

    Input paths:
                libname raw D:\Externe Projekte\UNC\Task190813 - IBDandDPP4I (db19-1)\res\Task190813A_210429_SensitivityA
             libname a  D:\Externe Projekte\UNC\wangje\data\analysis
Other details: CPRD-DPP4i project in collaboration with USB

CHANGES:
Date: Date of Change
Notes: Change Notes
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\sas\macros");
%setup(programName=0_readdata.sas, savelog=N, dataset= );




%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);