/***************************************
SAS file name: 011_cleandata.sas QC 
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
                original temp data:  D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16
            libname a  D:\Externe Projekte\UNC\wangje\data\analysis
Other details: CPRD-DPP4i project in collaboration with USB

CHANGES:
Date:2024-01-10
Notes: for walkthru for virginia's OH 
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros\");
%setup(programName=QC, savelog=N, dataset=dataname);

/*=================*\
SRS
\*=================*/

%LET drug1 = dpp4i;
%LET nsample = 1000;
/* get srs of ids to test  */
proc sql; 
    create table uniqueidsdpp4 as select distinct id from temp.&drug1._eventwide; 
    create table uniqueidswIBDdpp4 as select distinct id from temp.&drug1._eventwide where ibd1=1;
    quit; 
    /* repeat and replace with different seeds to randomly check ids */
proc sql noprint outobs=&nsample; 
    create table randidsall as select * from uniqueidsdpp4 order by ranuni(12345);
    create table randidsibd as select * from uniqueidswIBDdpp4 order by ranuni(54321);
    /* sample all IBD  */
proc sql;
    create table randids as select * from randidsall union all corr select * from randidsibd;
quit;

/* Loading 'Raw Data'for drug1 */
proc sql; 
/* load raw drug drug1 information from _demog dataset  */
create table &drug1._trtmt as select a.id, a.rxdate, a.time0, a.history, a.gemscript, a.BCSDP, a.rx_dayssupply, a.DPP4i, a.SU, a.SGLT2i, a.TZD  from randids as b
inner join raw.&drug1._trtmt as a on a.id=b.id;
/* load derived use period information from _useperiod dataset   */
create table &drug1._useperiods as select * from randids as b
inner join temp.&drug1._useperiods as a on a.id=b.id;
/* load raw event information from _event dataset   */
create table &drug1._event as select * from randids as b
inner join raw.&drug1._event as a on a.id=b.id;
/* load derived wide event information from _eventwide dataset  */
create table &drug1._eventwide as select * from randids as b
inner join temp.&drug1._eventwide as a on a.id=b.id;
/* load derived demographic information from _demog dataset */
create table &drug1._demog as select * from randids as b
inner join temp.&drug1._demog as a on a.id=b.id;
quit;
*NOTE - Eventtype==7 missing seems to be a combination of eventtype==6 and eventtype==7, 
see line 915 of  D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\src\Task231122_01_231122.dpr;
PROC FREQ DATA=&drug1._event;
TABLES eventtype /list missing;
format eventtype feventtype.;
RUN;
/**/
/*proc freq data=&drug1._event;*/
/*tables eventtype;run;*/
/*proc sql; select count(distinct id) from &drug1._event where eventtype in (8,9);quit;*/
/*=================*\
CONVERT OUTCOMES TO WIDE DATASET 
\*=================*/

/* demo on sample ids _eventwide dataset creation  */
proc sort data=&drug1._event; by id eventtype eventdate ; run;
data &drug1._tmpwide;
    set &drug1._event ;
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

/*=================*\
GET USEPERIODS
\*=================*/

proc means data = &drug1._trtmt  
    STACKODS N NMISS MEAN STD MIN MAX Q1 MEDIAN Q3   ;
	class dpp4i;
var  rx_dayssupply; 
run;

/* troubleshooting the useperiods creation ; */
    %macro get_useperiods ( druglist , grace, washout, save= N );
    %do z=1 %to %sysfunc(countw(&druglist.));
        %let drug=%scan(&druglist.,&z.);
    proc sql;
        create table tmpRx_&drug. as
        select * from 
            (select a.id, a.rxdate, a.time0, a.history, a.gemscript, a.BCSDP, a.rx_dayssupply, a.DPP4i, a.SU, a.SGLT2i, a.TZD 
            from &drug._trtmt as a ) 
            left join 
            (select  b.death_dt,b.dbexit_dt, b.endstudy_dt  from &drug._tmpwide as b)
            on a.id=b.id;
    quit;
    
    data tmpRx_&drug._; set tmpRx_&drug.;
        startdt= time0-history ; format startdt date9.;
        enddt= min(death_dt, dbexit_dt, endstudy_dt); format enddt date9.; RUN;
    %let keeplist= dpp4i su sglt2i tzd gemscript BCSDP;
    /*NOTE - Check w Virginia on daysimp, maxDays, startenroll, endenroll macro parameters*/
    %useperiods(
        grace=&primaryGraceP, 
        washout=&washoutp, 
        wpgp=N, 
        daysimp=0, 
        maxDays=14,   
        multiclaim=max,
        inds= %str(tmpRx_&drug._ (where=(&drug.=1))), 
        idvar=id, 
        startenroll=startdt, 
        rxdate=rxdate, 
        endenroll=enddt, 
        dayssup=rx_dayssupply, 
        keepvars= &keeplist, outds=&drug._useperiods);
    %end;
    %mend get_useperiods;

*Running testing of useperiods macro; 
%LET druglist = dpp4i ;
%LET primaryGracep = 90;
%LET washoutp = 365;
%get_useperiods( druglist= &druglist. , grace= &primaryGracep, washout= &washoutp , save=Y);
    
proc sort data= &drug1._useperiods; by id; run;
proc sort data= &drug1._trtmt; by id; run; 
proc print data=&drug1._trtmt (obs=10); run;
proc print data=&drug1._useperiods (obs=10); run;
PROC FREQ DATA =&drug1._useperiods;
    /*NOTE -  multiple periods of new use, however demogrpahics are only available for the first period of newuse */
TABLES NEWUSE useperiod reason   /list missing;
RUN;

proc freq data=   &drug1._useperiods;
where useperiod eq 1;
tables    newuse         / list missing; 
run; 

proc print data=  &drug1._useperiods; where newuse eq 0 and useperiod eq 1  ;  
run; 


proc means data = &drug1._useperiods  STACKODS N NMISS MEAN STD MIN MAX Q1 MEDIAN Q3   ;
var  numfill; run;


/*=================*\
end of program
\*=================*/

/**/
/*proc sql;*/
/*	create table dpp_events as select distinct id from raw.dpp4i_event order by id;*/
/*	create table dpp_trtmt as select distinct id from raw.dpp4i_trtmt order by id;*/
/*quit;*/
/**/
/*data comp;*/
/*	merge dpp_events(in=a) dpp_trtmt(in=b);*/
/*	by id;*/
/*	events=a; trt=b;*/
/*run;*/
/*proc freq data=comp;tables events * trt;run;*/


proc sql;
	create table correct_death as select distinct id, 
			max(event=8) as event8, max(event=9) as event9 ,
			max(case when event=6 then event_date else . end) as last_event6_dt format=date9.
	from raw.&drug._event 
	group by id having event8=0 and event9=0;
quit;
/*first flag as death for now, rather than renaming the event to 7 before changing the actual data. do not overwrite the original file 
check to make sure its right before */
proc sql;
	create table events as select a.*, 
		case when a.event=6 then 1 else 0 end as flag_death
	from raw.&drug._event_wide as a left join correct_death as b on a.id=b.id and a.event_date=b.last_event6_dt
	order by id, event_date;
quit;


%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);
