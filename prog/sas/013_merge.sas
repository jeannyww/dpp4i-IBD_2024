/***************************************
SAS file name: 013_merge

Purpose: merging and getting counts of each ACNU    (Active Comparator New User Cohorts)
Author: JHW
Creation Date: 
28DEC2024
    Program and output path:
        D:\Externe Projekte\UNC\wangje\sas
        D:\Externe Projekte\UNC\wangje\sas\prog
        libname temp D:\Externe Projekte\UNC\wangje\data\temp

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
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\sas\macros");
%setup(programName=013_merge, savelog=N, dataset=temp);

* %LET comparatorlist = su tzd sglt2i;
* %mergeall(exposure=dpp4i, comparatorlist=&comparatorlist., primaryGraceP=90, washoutp=365, save=Y);
%macro mergeall(exposure, comparatorlist, primaryGraceP, washoutp, save=N);
%do i=1 %to %sysfunc(countw(&comparatorlist.));
    %let comparator = %scan(&comparatorlist., &i.);
    *printing the exclusions thus far in flowcharting the exclusions;  
    proc print data=temp.exclusions_012_&exposure._&comparator.; run;

    *NOTE - is restricting to the first use period ok for now? bc we do not have demogrpahic info on subsequent useperiods past the first useperiod;
    *loading the newusers dataset;
    data tmpnewuser;
        set temp.newusers_&exposure._&comparator.; RUN;

    *loading the demographic dataset;
    data tmpdemog_&exposure.;
        set temp.&exposure._demog;    RUN;

    data tmpdemog_&comparator.;
        set temp.&comparator._demog;    RUN;

    *loading the events dataset;
    data tmpevents_&exposure.;
        set temp.&exposure._eventwide;    RUN;

    data tmpevents_&comparator.;
        set temp.&comparator._eventwide;    RUN;
    *starting with the newusers dataset, we will merge in the demographic and events datasets;
    *saving counts of periods of newuse for documentation and storing in exclusions tables;
    proc sql noprint;
        create table tmp_counts as select * from temp.exclusions_012_&exposure._&comparator.;
        select count(*) into :num_obs from tmp_counts;
        *getting counts of new use periods for each drug group;
        insert into tmp_counts
            set exclusion_num = &num_obs + 1,
            long_text="Total number of newuse periods of &exposure. or &comparator. using grace=&primarygracep.days, washout=&washoutp.days",
            dpp4i = (select count(*) from (select distinct id, useperiod from tmpnewuser where &exposure. = 1)),
            &comparator. =( select count (*) from (select distinct id, useperiod from tmpnewuser where &exposure. = 0));
        *getting counts of distinct id where newuse ==1 for each drug group;
        insert into tmp_counts
            set exclusion_num = &num_obs + 2,
            long_text="Restricting newuse period to the first useperiod for &exposure. or &comparator.",
            dpp4i = (select count(*) from (select distinct id, indexdate from tmpnewuser where &exposure. = 1 and useperiod = 1)),
            &comparator. = (select count(*) from (select distinct id, indexdate from tmpnewuser where &exposure. = 0 and useperiod = 1));
    quit;
    proc print data=tmp_counts; run;
    * first merging in the events dataset;
    PROC SQL; 
        create table tmp_allmerged_&exposure. as select * from (select *, indexdate as time0 from tmpnewuser where &exposure.=1 and useperiod=1) as a
        inner join (select * from tmpevents_&exposure.) as b
        on a.id = b.id and a.time0 = b.time0
        inner join (select * from tmpdemog_&exposure.) as c
        on a.id = c.id and a.time0 = c.time0;

        create table tmp_allmerged_&comparator. as select * from (select *, indexdate as time0 from tmpnewuser where &exposure.=0 and useperiod=1) as a
        inner join (select * from tmpevents_&comparator.) as b
        on a.id = b.id and a.time0 = b.time0
        inner join (select * from tmpdemog_&comparator.) as c
        on a.id = c.id and a.time0 = c.time0;
    QUIT;
    *stacking the exposure and comparator datasets together, coded to keep duplicate rows and only same columns;
    PROC SQL; 
        create table tmp_allmerged_&exposure._&comparator. as 
        select * from tmp_allmerged_&exposure. 
        union all corresponding 
        select * from tmp_allmerged_&comparator.;
    QUIT;

    %if &save=Y %then %do; 
        data temp.allmerged_&exposure._&comparator.;
            set tmp_allmerged_&exposure._&comparator.;RUN;
        data temp.exclusions_013_&exposure._&comparator.;
            set tmp_counts;RUN;
    %end;
%end;
%mend;

%LET comparatorlist = su tzd sglt2i;
%mergeall(exposure=dpp4i, comparatorlist=&comparatorlist., primaryGraceP=90, washoutp=365, save=Y);


%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);