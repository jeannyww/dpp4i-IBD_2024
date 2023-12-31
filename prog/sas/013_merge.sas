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
see git 
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\sas\macros");
%setup(programName=013_merge, savelog=N, dataset=temp);


/*===================================*\
//SECTION - Initializing dependencies
\*===================================*/
/* region */

/* Loading in csv that will create list for labelling the dataset */
data varlabs; 
    infile "D:\Externe Projekte\UNC\wangje\ref\labels_v11.csv" dsd missover firstobs=2;
    length codelistname $ 20 codetype $ 20 filenames $ 100;
    input codelistname $ codetype $ filenames $;
run;
data varlabs; set varlabs; 
label1= tranwrd(filenames, ".txt", "");
RUN;
proc print data= varlabs; run;
/* storing label prefixes into macro variables */
PROC SQL noprint; 
    select codelistname into :varslist separated by " " from varlabs  ;
    select codetype into :typelist separated by " " from varlabs  ;
    select label1 into :labellist separated by "|" from varlabs where codetype eq "Read" ;
QUIT;
/* verify */
%put &varslist.;
%put &typelist.;
%put &labellist.;

/* macro to iteratively label baseline variables from the label list */
%macro label ( varlist , labellist, typelist );
    %do i=1 %to %sysfunc(countw(&varlist));
    %let var=%scan(&varlist,&i, " ");
    %LET type = %scan(&typelist, &i, " ");
    %LET lab = %scan(&labellist, &i, "|");
    
    %if &type eq Read %then %do;
    label &var._bc ="Last &lab. read code prior to (excluding) time0";
    label &var._bl ="Days between last &lab. Rx prior to (excluding) time0";
    %end; %else %do;
    label &var._bc ="Last BDSCP code of &lab. Rx prior to (excluding) time0";
    label &var._gc ="Last gemscript code of &lab. Rx prior to (excluding) time0";
    label &var._bl ="Days between last &lab. Rx prior to (excluding) time0";
    label &var._tot1yr ="No. &lab. prescriptions within 365d prior to time0";
    %end;
    %end;
    %mend label;
    /* macro to merge outcome, drug class, and baseline vars, adding labels */    
    * %LET comparatorlist = su tzd sglt2i;
    * %mergeall(exposure=dpp4i, comparatorlist=&comparatorlist., primaryGraceP=90, washoutp=365, save=Y);
    %macro mergeall(exposure, comparatorlist, primaryGraceP, washoutp, save=N);
        %do z=1 %to %sysfunc(countw(&comparatorlist.));
        %let comparator = %scan(&comparatorlist., &z.);
    *printing the exclusions thus far in flowcharting the exclusions;  
proc print data=temp.exclusions_012_&exposure._&comparator.; run;

    *NOTE - is restricting to the first use period ok for now? bc we do not have demogrpahic info on subsequent useperiods past the first useperiod;
    *starting with the newusers dataset, we will merge in the demographic and events datasets;
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
    /* adding labels */    
    data tmp1; set tmp_allmerged_&exposure._&comparator.; 
    %label(&varslist., &labellist., &typelist.);
    label ID="Patient ID";
    label time0="Date of First RX Fill";
    label startdt="Start Date of continuous enrollment period";
    label enddt="End Date of continuous enrollment period";
    label reason1="Reason for Censoring (for determining continuous use period of drug)";
    label gemscript="gemscript code for first prescription of exposure or comparator drug ";
    label BCSDP="BCSDP code for first prescription of exposure or comparator drug";
    label su="Drug class: 1=su 0=other";
    label sglt2i="Drug class: 1=sglt2i 0=other";
    label tzd="Drug class: 1=tzd 0=other ";
    label badrx_BCode="BDSCP Code of first prescription of 'IBD-causing-drug'";
    label badrx_GCode="gemscript Code of first prescription of 'IBD-causing-drug'";
    label ibd1_code="Read code of IBD diagnosis meeting definition 1: first IBD dx";
    label ibd2_code="Read code of IBD diagnosis meeting definition 2: colo, sigmo w/n 30d before IBD dx";
    label ibd3_code="Read code of IBD diagnosis meeting definition 3: colo, sigmo, biops w/n 30d before IBD dx";
    label ibd4_code="Read code of IBD diagnosis meeting definition 4: colo/sigmo/Gi symptoms 30d before and IBD tx rx 30d after IBD dx";
    label ibd5_code="Read code of IBD diagnosis meeting definition 5: meeting Abrahami definition of validated dx";
    label ibd1="IBD outcome meeting definition 1: first IBD dx";
    label ibd2="IBD outcome meeting definition 2: colo, sigmo w/n 30d before IBD dx";
    label ibd3="IBD outcome meeting definition 3: colo, sigmo, biops w/n 30d before IBD dx";
    label ibd4="IBD outcome meeting definition 4: colo/sigmo/Gi symptoms 30d before and IBD tx rx 30d after IBD dx";
    label ibd5="IBD outcome meeting definition 5: meeting Abrahami definition of validated dx";
    label ibd1_dt="Date of validated IBD diagnosis meeting definition 1: first IBD dx";
    label ibd2_dt="Date of validated IBD diagnosis meeting definition 2: colo, sigmo w/n 30d before IBD dx";
    label ibd3_dt="Date of validated IBD diagnosis meeting definition 3: colo, sigmo, biops w/n 30d before IBD dx";
    label ibd4_dt="Date of validated IBD diagnosis meeting definition 4: colo/sigmo/Gi symptoms 30d before and IBD tx rx 30d after IBD dx";
    label ibd4tx_dt="Date of Rx for IBD treatment w/n 30 days after IBD dx definition 4";
    label ibd5_dt="Date of validated IBD diagnosis meeting definition 5: meeting Abrahami definition of validated dx";
    label badrx_dt="Date of the first prescription of 'IBD-causing-drug' ";
    label badrx="Censoring: prescription of 'IBD-causing-drug' after time0";
    label death_dt="Date of death ";
    label dbexit_dt="Date of database exit";
    label LastColl_Dt="Date of last collection of data after time0";
    label endstudy_dt="Date of end study 31.12.22";
    label rxdate_tmp="delete";
    label time0_tmp="delete";
    label age="Age at time0 (first prescription of drug class)";
    label sex="Sex (m=male, f=female)";
    label smoke="Smoking status (n = non-smoker, s = current smoker, x = ex-smoker, u = unknown; closest recording prior to the time0)";
    label smoketime="Smoking status time (number of days between the last recording before the time0 and the time0)";
    label height="Height (closest recording prior to the time0, if not found then the first recording after the time0)";
    label heighttime="Height time (number of days between the last recording before the time0 [or the first recording after the i.d.] and the time0)";
    label weight="Weight (closest recording prior to the time0)";
    label weighttime="Weight time (number of days between the last recording before the time0 and the time0)";
    label bmi="BMI (closest recording prior to the time0, ignore BMI values <12 and > 60)";
    label bmitime="BMI time (number of days between the last recording before the time0 and the time0)";
    label alc="Last alcohol status prior to the time0 (u = unknown, c = current, n = never, x = ex; if not found: the first recording within three years after the time0)";
    label alctime="Last alcohol status prior to the time0/time (number of days between the last recording before the time0 [or the first recording after the i.d.] and the time0)";
    label alcunit="Units per week for recorded value of last alcohol status prior the time0 (if not found the first recording within three years after the time0)";
    label alcavg="Average units per week for all recorded alcohol units prior the time0";
    label hba1c="HBA1c level before time0 (closest recording prior to the time0)";
    label hba1ctime="HBA1c level/time (number of days between the last recording before the time0 and the time0)";
    label hba1cno="Number of HBA1c recordings within the last three years prior to the time0";
    label hba1cavg="Average HBA1c level within the last three years before the time0";
    label history="Number of days of recorded history in the database prior to the time0 (the number of days between the first prescription in the patients’ profile and the time0, historical entries prior 1987 are ignored).";
    label GPyearDx="Practice visits last year based on diagnoses = number of practice visits in the 365 days immediately prior to the time0 (count only visits at separate dates)";
    label GPyearDxRx="Practice visits last year based on diagnoses and prescriptions = number of practice visits in the 365 days immediately prior to the time0 (count only visits at separate dates)";
    run;
    /* If save=y then save to temp library for retreival later  */
    %if &save=Y %then %do; 
    data temp.allmerged_&exposure._&comparator.;
    set tmp1;RUN;
    data temp.exclusions_013_&exposure._&comparator.;
    set tmp_counts;RUN;
    %end;
%end;
%mend;


/* endregion //!SECTION */

/*===================================*\
//SECTION - Running the macro 
\*===================================*/
/* region */


%LET comparatorlist = su tzd sglt2i;
%mergeall(exposure=dpp4i, comparatorlist=&comparatorlist., primaryGraceP=90, washoutp=365, save=Y);

/* endregion //!SECTION */

%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);