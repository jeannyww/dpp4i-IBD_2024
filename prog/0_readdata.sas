/***************************************
 SAS file name: 0_readdata.sas

Purpose: for reading in V2 of dataset 
Author: JHW
Creation Date: Created on 2023-12-16 05:36:00
Task231122 - IBDandDPP4I (db23-1)

    Program and output path:
            D:\Externe Projekte\UNC\wangje\sas
                D:\Externe Projekte\UNC\wangje\sas\prog
            libname temp D:\Externe Projekte\UNC\wangje\data\temp

    Input paths:

Current request:
D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Requests\2023-12-12 UNC Clean Request, New List\ Request for IBD and DPP4I-2023-12-14_V11 jw.docx

Used  code lists:
D:\External Projects\UNC\Task231122 - IBDandDPP4I (db23-1)\Codes\Lists_IBDandDPP4I_008.listler

General results:
D:\External Projects\UNC \Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16\


  *   Task231122_01_231122_001.log                 Contains information on all code lists.
  *   Task231122_01_231122_Report.txt             Numbers collected during the creation of the study populations.
  *   Event*, *Treatment*                                    CSV files


    Other details: CPRD-DPP4i project in collaboration with USB

CHANGES: see github repo 
Date: 2023-12-16 05:36:00
Notes: Cleaned up for macroprocessing 
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\sas\macros");
%setup(programName=0_readdata.sas, savelog=N, dataset= );

/*===================================*\
//SECTION - EVENT CSV FILES 
\*===================================*/
/* region */


/* Reading in a dummy of the event csvs */
data sample; 
    infile "D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16\Task231122_01_231122_DPP4i_Event\Task231122_01_231122_DPP4i_Event.csv" dlm="," firstobs=2 obs=1000 end=eol;
    length ID $ 11 eventtype 8 EventDate $ 10 EventDate_tx $ 10 badrx_BCode $ 10 badrx_GCode $ 10 EndOfLine $ 10;
    input ID $ eventtype ReadCode $ EventDate $ EventDate_tx $ badrx_BCode $ badrx_GCode $ EndOfLine $;
run;

/* testing readin using proc import for csv      */
proc import datafile="D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16\Task231122_01_231122_DPP4i_Event\Task231122_01_231122_DPP4i_Event.csv" out=dpp_event2 dbms=csv replace;
    getnames=yes;RUN;
proc import datafile="D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16\Task231122_01_231122_DPP4i_Event\Task231122_01_231122_DPP4i_Event.csv" out=dpp_event2 dbms=csv replace;
    getnames=yes;
guessingrows=1000000; RUN;
data raw.dpp_event2; set dpp_event2; run;   

data a.dpp_event; 
    infile "D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16\Task231122_01_231122_DPP4i_Event\Task231122_01_231122_DPP4i_Event.csv" dlm="," firstobs=2 ;
    length ID $ 11 eventtype 8 EventDate $ 10 EventDate_tx $ 10 badrx_BCode $ 10 badrx_GCode $ 10 EndOfLine $ 10;
    input ID $ eventtype ReadCode $ EventDate $ EventDate_tx $ badrx_BCode $ badrx_GCode $ EndOfLine $;
run;

/* Proc import is substantially slower than data step infile. For efficiency, use data step infile. avoid proc import unless overnight guessingrows= at least 1000000  */

/*read_eventcsv2*/
*using proc import this time;
%macro read_eventcsv2 ( drug  );
    proc import datafile="D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16\Task231122_01_231122_&drug._Event\Task231122_01_231122_&drug._Event.csv" out=raw.&drug._event dbms=csv replace;
        getnames=yes;
        guessingrows=1000000; RUN;
%mend read_eventcsv2;

/*read_eventcsv*/
*descrip;
%macro read_eventcsv ( druglist  );

    %do i=1 %to %sysfunc(countw(&druglist.));
        %let drug=%scan(&druglist.,&i.);

    data raw.&drug._event; 
        infile "D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16\Task231122_01_231122_&drug._Event\Task231122_01_231122_&drug._Event.csv" dlm="," firstobs=2 ;
        length ID $ 11 eventtype 8 EventDate $ 10 EventDate_tx $ 10 badrx_BCode $ 10 badrx_GCode $ 10 EndOfLine $ 10;
        input ID $ eventtype ReadCode $ EventDate $ EventDate_tx $ badrx_BCode $ badrx_GCode $ EndOfLine $;
    run;

    %end; 
%mend read_eventcsv;

%LET druglist = dpp4i  tzd su sglt2i ;
%read_eventcsv ( &druglist. );

/* endregion //!SECTION */


/*===================================*\
//SECTION - TREATMENT CSV files 
\*===================================*/
/* region */


/* reading in a dummy of the followup rx csv files  */
data sample; 
    infile "D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16\Task231122_01_231122_DPP4i_Treatment\Task231122_01_231122_DPP4i_Treatment.csv" dlm="," firstobs=2 obs=5; 
RUN;
proc import datafile="D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16\Task231122_01_231122_DPP4i_Treatment\Task231122_01_231122_DPP4i_Treatment.csv" out=raw.dpp_trtmt dbms=csv replace;
getnames=yes; *guessingrows=max; RUN;

/* guessing rows below is a test using the smallest size dataset (sglt2i) to see if SAS can efficiently (slowly) derive the proper variable type, length, and formats for the datasets
For future datasets, avoid using proc import go directly to data step infile now that known formats can be ascertained from guessingrows !=max*/
proc import datafile="D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16\Task231122_01_231122_SGLT2i_Treatment\Task231122_01_231122_SGLT2i_Treatment.csv" out=raw.sglt_trtmt dbms=csv replace;
getnames=yes;guessingrows=1000000; RUN;

/*NOTE: RAW.SGLT_TRTMT data set was successfully created.
NOTE: The data set RAW.SGLT_TRTMT has 2652065 observations and 488 variables.
NOTE: PROCEDURE IMPORT used (Total process time):
      real time           2:27:44.66
      user cpu time       2:24:44.45
*/


/* TODO - Send Medicare WG meeting agenda ; Send agenda for CPRD meeting today */


/* endregion //!SECTION */

%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);