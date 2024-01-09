/***************************************
SAS file name: 011_cleandata.sas QC 
Task231122 - IBDandDPP4I (db23-1)

Purpose: To consolidate _demog, _trtmt, and _event datasets into one dataset, then combine for each ACNU cohort
Author: JHW
Creation Date: 26DEC2024
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
Date: see git 
Notes: etc
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=QC, savelog=N, dataset=dataname);


%LET drug = dpp4i;
%LET nsample = 1000;
/* get srs of ids to test  */
proc sql; create table uniqueids as select distinct id from temp.&drug._eventwide; 
    quit; 
    /* repeat and replace with different seeds to randomly check ids */
proc sql outobs=&nsample; 
    create table randids as select * from uniqueids order by ranuni(12345);
quit;
proc sql; 
/* load temp drug exposure information from _demog dataset  */
create table _trtmt as select a.id, a.rxdate, a.time0, a.history, a.gemscript, a.BCSDP, a.rx_dayssupply, a.DPP4i, a.SU, a.SGLT2i, a.TZD  from randids as b
inner join raw.&drug._trtmt as a on a.id=b.id;
/* load use period information from _useperiod dataset   */
create table _useperiods as select * from randids as b
inner join temp.&drug._useperiods as a on a.id=b.id;
/* load event information from _event dataset   */
create table _event as select * from randids as b
inner join raw.&drug._event as a on a.id=b.id;
/* load wide event information from _eventwide dataset  */
create table _eventwide as select * from randids as b
inner join temp.&drug._eventwide as a on a.id=b.id;
quit;

/* troubleshooting the useperiods creation ; trouble shooting is complete */

proc sort data= _useperiods; by id; run;
proc sort data= _trtmt; by id; run; 
proc print data=_trtmt (obs=10); run;
proc print data=_useperiods (obs=10); run;
PROC FREQ DATA=_useperiods;
TABLES NEWUSE useperiod reason numfill  /list missing;
RUN;


/* troubleshooting the _eventwide dataset creation  */

proc sort data= _event; by id eventtype eventdate ; run;
data tmpwide;
    set _event ;
    by id eventtype ; 
    length ibd1_code ibd2_code ibd3_code ibd4_code ibd5_code badrx_Bcode badRx_Gcode $ 10; 
    retain ibd1_dt ibd1_code ibd1
        ibd2_dt ibd2_code ibd2
        ibd3_dt ibd3_code ibd3
        ibd4_dt ibd4tx_dt ibd4_code ibd4
        ibd5_dt ibd5_code ibd5
        badrx_dt badrx_Bcode badrx_Gcode badrx
        death_dt dbexit_dt LastColl_Dt endstudy_dt;
    format ibd1_dt ibd2_dt ibd3_dt ibd4_dt ibd4tx_dt ibd5_dt badrx_dt death_dt dbexit_dt LastColl_Dt endstudy_dt date9.;

    if first.id then do;
        ibd1_dt = .; ibd1_code = ""; ibd1 = .;
        ibd2_dt = .; ibd2_code = ""; ibd2 = .;
        ibd3_dt = .; ibd3_code = ""; ibd3 = .;
        ibd4_dt = .; ibd4tx_dt = .; ibd4_code = ""; ibd4 = .;
        ibd5_dt = .; ibd5_code = ""; ibd5 = .;
        badrx_dt = .; badrx_Bcode = ""; badrx_Gcode = ""; badrx=.;
        death_dt = .; dbexit_dt = .; LastColl_Dt = .; endstudy_dt = '31DEC2022'd;
    end;

    if eventtype = 1 then do;
        ibd1_dt = eventdate;
        ibd1_code = readcode;
        ibd1 = 1;
    end; 

    if eventtype = 2 then do;
        ibd2_dt = eventdate;
        ibd2_code = readcode;
        ibd2 = 1;
    end; 

    if eventtype = 3 then do;
        ibd3_dt = eventdate;
        ibd3_code = readcode;
        ibd3 = 1;
    end; 

    if eventtype = 4 then do;
        ibd4_dt = eventdate;
        ibd4tx_dt = eventdate_tx;
        ibd4_code = readcode;
        ibd4 = 1;
    end; 

    if eventtype = 5 then do;
        ibd5_dt = eventdate;
        ibd5_code = readcode;
        ibd5 = 1;
    end; 

    if eventtype = 6 then do;
        if first.eventtype then do; 
        badrx_dt = eventdate;
        badrx_Bcode = badrx_Bcode;
        badrx_Gcode = badrx_Gcode;
        badrx=1; 
        END;
    end; 
    if eventtype = 7 then death_dt = eventdate;
    if eventtype = 8 then dbexit_dt = eventdate;
    if eventtype = 9 then LastColl_Dt = eventdate;
    if last.id then output;
    drop eventtype eventdate readcode eventdate_tx endofline ;
run;

%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);