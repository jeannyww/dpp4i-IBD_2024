/***************************************
SAS file name: merge.sas

Purpose: to merge together newuser, demog, and events data for the CPRD-DPP4i project
Author: JHW
Creation Date: 27dec2024

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
Date: 
Notes: 
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\sas\macros");
%setup(programName=merge, savelog=N, dataset=dataname);

/*===================================*\
//SECTION - testing 28DEC2024
\*===================================*/
/* region */
*checking on the id matches and indexdate matches--see if there are any missing ids or indexdates;
*event_wide and demog/trtmt have mostly matching id's and can match the indexdates;
%LET exposure = dpp4i;
%LET comparator = su;
PROC SQL; 
    /* proxy for treatment dataset  */
    create table &exposure._demog as select distinct id, time0 as indexdate from temp.&exposure._demog ;
    /* event dataset */
    create table &exposure._eventwide as select distinct id from temp.&exposure._eventwide;
    /* loading newuser dataset */
    create table newusers_&exposure._&comparator. as select distinct id, indexdate as time0 from temp.newusers_&exposure._&comparator. ;
QUIT;

PROC SQL; 
QUIT;


PROC SQL;
    create table trtmtids as select  a.id, b.time0 from temp.&exposure._eventwide as a 
    inner join temp.&exposure._demog as b on a.id = b.id and a.time0=b.time0;
    
create table newusers_&exposure._&comparator. as select distinct id, indexdate as time0 from temp.newusers_&exposure._&comparator. ;
quit;
%LET dataset1 = newusers_&exposure._&comparator.;
%LET dataset2 = trtmtids;
PROC SQL;
    CREATE TABLE unequal_rows AS
    SELECT id, time0, "&dataset1. only" as dataset
    FROM &dataset1.
    WHERE NOT EXISTS (
            SELECT *
            FROM &dataset2.
            WHERE &dataset1..id = &dataset2..id
                AND &dataset1..time0= &dataset2..time0
    )
    UNION
    SELECT id, time0, "&dataset2. only" as dataset
    FROM &dataset2.
    WHERE NOT EXISTS (
            SELECT *
            FROM &dataset1.
            WHERE &dataset1..id = &dataset2..id
                AND &dataset1..time0 = &dataset2..time0
    );
QUIT;

proc sql; 
    create table &dataset2.only as SELECT id, time0, "&dataset2. only" as dataset
    FROM &dataset2.
    WHERE NOT EXISTS (
            SELECT *
            FROM &dataset1.
            WHERE &dataset1..id = &dataset2..id
                AND &dataset1..time0 = &dataset2..time0
    );
QUIT;


/* endregion //!SECTION */

/* getting random sample of IDs to test merge  */
%LET nsample = 1000;
%LET exposure = dpp4i;
%LET comparator = SGLT2i;
PROC SQL; 
    /* (one row per id + time0 combination) */ 
    create table uniqueids as select distinct id from temp.newusers_&exposure._&comparator. ;
QUIT;
    /* getting random sample of &nsample ids  */
PROC SQL outobs=&nsample; 
    create table randids as select * from uniqueids order by ranuni(54325);
QUIT;
PROC SQL; 
    /* loading random sample from newuser dataset (exposure) */
    create table newusers_&exposure._&comparator as select * from temp.newusers_&exposure._&comparator. where id in (select id from randids);
    /* loading random sample from demog dataset */
    create table &exposure._demog as select * from temp.&exposure._demog where id in (select id from randids);
    create table &comparator._demog as select * from temp.&comparator._demog where id in (select id from randids);
    /* loading events/outcomes   */
    create table &exposure._eventwide as select * from temp.&exposure._eventwide where id in (select id from randids);
    create table &comparator._eventwide as select * from temp.&comparator._eventwide where id in (select id from randids);
QUIT;

proc print data=newusers_&exposure._&comparator. (obs=10); run;
run;
proc freq data= newusers_&exposure._&comparator. ; 
    tables excludeflag_prefill2initiator excludeflag_prevalentuser excludeFlag_sameDayInitiator / missing;  RUN;

PROC SQL; 
    create table tmp_&exposure. as select distinct id , indexdate from newusers_&exposure._&comparator. 
    where &exposure eq 1;
    create table tmp_&exposure.2 as select distinct id, time0 as indexdate from &exposure._demog;
    
    create table tmp_&exposure.3 as select distinct id, time0 as indexdate from &exposure._eventwide;
QUIT;

PROC SQL; 
    create table tmp_&exposure.demog as select distinct id as indexdate from temp.&exposure._demog;
QUIT;
%LET drug = dpp4i;
PROC SQL; 
    select count (distinct id ) as n_ids_trtmt from raw.&drug._trtmt; 
    select count (distinct id ) as n_ids_event from raw.&drug._event;
QUIT;
/* Create a temporary table to store the unequal rows */
/* comparing for IDs that are unequal  */
%macro compare(dataset1, dataset2);
    PROC SQL;
        CREATE TABLE unequal_rows AS
        SELECT *, "in &dataset1. only" as dataset
        FROM &dataset1.
        WHERE NOT EXISTS (
                SELECT *
                FROM &dataset2.
                WHERE &dataset1..id = &dataset2..id
        )
        UNION
        SELECT * , "&dataset2. only" as dataset
        FROM &dataset2.
        WHERE NOT EXISTS (
                SELECT *
                FROM &dataset1.
                WHERE &dataset1..id = &dataset2..id
        );
        QUIT;
    /* Export the unequal_rows dataset as a CSV file */
    PROC EXPORT DATA=unequal_rows
        OUTFILE="&goutpath.\Missing_IDs_&drug._Treatment_Event.csv"
        DBMS=CSV REPLACE;
    RUN;    
%mend compare;
%macro loop (druglist);
%do i=1 %to %sysfunc(countw(&druglist.));
    %let drug = %scan(&druglist.,&i.);
PROC SQL; 
    create table &drug._Treatment as select  distinct id  from raw.&drug._trtmt; 
    create table &drug._Event as select distinct id   from raw.&drug._event;
QUIT;
%compare(&drug._Treatment, &drug._Event);
%end;
%mend loop;

%loop(dpp4i su tzd sglt2i);
PROC SQL;
        CREATE TABLE unequal_rows AS
        SELECT *, "&dataset1. only" as dataset
        FROM &dataset1.
        WHERE NOT EXISTS (
                SELECT *
                FROM &dataset2.
                WHERE &dataset1..id = &dataset2..id
                    AND &dataset1..indexdate = &dataset2..indexdate
        )
        UNION
        SELECT * , "&dataset2. only" as dataset
        FROM &dataset2.
        WHERE NOT EXISTS (
                SELECT *
                FROM &dataset1.
                WHERE &dataset1..id = &dataset2..id
                    AND &dataset1..indexdate = &dataset2..indexdate
        );
QUIT;

/* Print the unequal rows */
PROC PRINT DATA=unequal_rows;
RUN;
proc sort data= tmp_&exposure. nodupkey; by id indexdate; run;
proc sort data= tmp_&exposure.2 nodupkey; by id indexdate; run; 
PROC COMPARE BASE=tmp_&exposure. COMPARE=tmp_&exposure.2 OUT=diffs OUTNOEQUAL;
    VAR id indexdate;
RUN;

/*===================================*\
//SECTION - checking unequal rows (ids that are in the events file but not in the treatment file)
\*===================================*/
/* region */

/*===================================*\
comparison for lost id's 
\*===================================*/

%macro compare(dataset1, dataset2);
    PROC SQL;
        CREATE TABLE unequal_rows AS
        SELECT *, "in &dataset1. only" as dataset
        FROM &dataset1.
        WHERE NOT EXISTS (
                SELECT *
                FROM &dataset2.
                WHERE &dataset1..id = &dataset2..id
        )
        UNION
        SELECT * , "&dataset2. only" as dataset
        FROM &dataset2.
        WHERE NOT EXISTS (
                SELECT *
                FROM &dataset1.
                WHERE &dataset1..id = &dataset2..id
        );
        QUIT;
    /* Export the unequal_rows dataset as a CSV file */
    PROC EXPORT DATA=unequal_rows
        OUTFILE="&goutpath.\Missing_IDs_&drug._Treatment_Event.csv"
        DBMS=CSV REPLACE;
    RUN;    
%mend compare;
%put &goutpath.;
%macro loop (druglist);
%do i=1 %to %sysfunc(countw(&druglist.));
    %let drug = %scan(&druglist.,&i.);
PROC SQL; 
    create table &drug._Treatment as select  distinct id  from raw.&drug._trtmt; 
    create table &drug._Event as select distinct id   from raw.&drug._event;
QUIT;
%compare(&drug._Treatment, &drug._Event);
%end;
%mend loop;

%loop(dpp4i su tzd sglt2i);

/* endregion //!SECTION */

%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);