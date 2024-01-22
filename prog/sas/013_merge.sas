/***************************************
SAS file name: 013_merge

Purpose: merging and getting counts of each ACNU    (Active Comparator New User Cohorts)
Author: JHW
Creation Date: 
28DEC2024
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
    select label1 into :labellist separated by "|" from varlabs ;
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
        %LET lab =%scan(&labellist, &i, "|");
        
        &var._1yrlookback=.;        
        if &var._bl in (0, .) then &var._1yrlookback=0;
        else if (&var._bl>=1 and &var._bl<=365) then &var._1yrlookback=1;
        else if (&var._bl>365) then &var._1yrlookback=0;

        &var._ever=.; 
        if &var._bl in (0, .) then &var._ever=0;
        else if (&var._bl>=1) then &var._ever=1;
        
        %if &type eq Read %then %do;
        label &var._bc ="Last &lab. read code prior to (excluding) time0";
        label &var._bl ="Days between last &lab. read code prior to (excluding) time0";
        label &var._1yrlookback = "&lab. read code within 365d prior to time0";
        label &var._ever = "&lab. read code ever prior to time0 using all lookback";
        
        %end; %else %do;
        &var._1yrlookback=.;        
        if &var._tot1yr in (0, .) then &var._1yrlookback=0;
        else if (&var._tot1yr>=1 ) then &var._1yrlookback=1;

        label &var._bc ="Last BDSCP code of &lab. Rx prior to (excluding) time0";
        label &var._gc ="Last gemscript code of &lab. Rx prior to (excluding) time0";
        label &var._bl ="Days between last &lab. Rx prior to (excluding) time0";
        label &var._tot1yr ="No. &lab. prescriptions within 365d prior to time0";
        label &var._1yrlookback = "&lab. Rx within 365d prior to time0";
        label &var._ever = "&lab. Rx ever prior to time0 using all lookback";
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
    /* Baseline vars- crude  */
        /* HBa1c is in mmol per mol, */
        hba1c_cat=.;
        if hba1ctime<365.25 then do;
            if hba1c le 53 then hba1c_cat=1; /* 7% ~ 53 mmol per mol  */
            else if hba1c gt 53 and hba1c le 64 then hba1c_cat=2 ; /* 8% ~ 64 mmol per mol */
            else if hba1c gt 64 then hba1c_cat=3; /* gt 8% or 64 mmol per mol  */
            end;
        hba1c_cat2= hba1c_cat; 
            if hba1c_cat eq . then hba1c_cat2=4;
            format hba1c_cat2 hba1cf.; 
        /* BMI */
        bmi_cat=.;
        if bmitime<365 then do;
            if bmi<25 then bmi_cat=1;
            else if bmi ge 25 and bmi lt 30 then bmi_cat=2;
            else if bmi ge 30 then bmi_cat=3;
            end;
            bmi_cat2= bmi_cat; 
            if bmi_cat eq . then bmi_cat2=4;
            format bmi_cat2 bmif.; 
        /* creating additional variables for Table 1/rest of analysis */
        /* creating year of cohort entry */
        entry_year=year(time0);
        /* ETOH */
        alcohol_cat='u';
        if alctime<365 then do;
            alcohol_cat=alc;
        end;
        /* smoking */
        smoke_cat='u';
        if smoketime<365 then do;
            smoke_cat=smoke;
        end;
        /* HBa1c is in mmol per mol, */
        hba1c_cat=.;
        if hba1ctime<365.25 then do;
            if hba1c le 53 then hba1c_cat=1; /* 7% ~ 53 mmol per mol  */
            else if hba1c gt 53 and hba1c le 64 then hba1c_cat=2 ; /* 8% ~ 64 mmol per mol */
            else if hba1c gt 64 then hba1c_cat=3; /* gt 8% or 64 mmol per mol  */
            end;
        /* total number of unique non-diabetic drugs in the year before cohort entry  */
        num_nondmdrugs1yr=sum(ace_1yrlookback,arb_1yrlookback,bb_1yrlookback,ccb_1yrlookback,nitrat_1yrlookback,coronar_1yrlookback,antiarr_1yrlookback,thrombo_1yrlookback,antivitk_1yrlookback,hepar_1yrlookback,stat_1yrlookback,fib_1yrlookback,lla_1yrlookback,thiaz_1yrlookback,loop_1yrlookback,kspar_1yrlookback,diurcom_1yrlookback,thiaantih_1yrlookback,diurall_1yrlookback,ass_1yrlookback, asscvd_1yrlookback, allnsa_1yrlookback,para_1yrlookback,allnsa_1yrlookback,opio_1yrlookback,acho_1yrlookback,sterinh_1yrlookback,bago_1yrlookback,abago_1yrlookback,lra_1yrlookback,xant_1yrlookback,ahist_1yrlookback,ahistc_1yrlookback,h2_1yrlookback,ppi_1yrlookback,thyro_1yrlookback,sterint_1yrlookback,stersys_1yrlookback,stertop_1yrlookback,adem_1yrlookback,apsy_1yrlookback,benzo_1yrlookback,hypno_1yrlookback,ssri_1yrlookback,li_1yrlookback,mao_1yrlookback,oadep_1yrlookback,mnri_1yrlookback,adep_1yrlookback,pheny_1yrlookback,barbi_1yrlookback,succi_1yrlookback,valpro_1yrlookback,carba_1yrlookback,oaconvu_1yrlookback,aconvu_1yrlookback,isupp_1yrlookback)  ;
        label num_nondmdrugs1yr="Total number of unique non-diabetic drugs in the year before cohort entry ";
        num_nondmdrugs1yr_cat=.; 
            if num_nondmdrugs1yr<4 then num_nondmdrugs1yr_cat=num_nondmdrugs1yr;
            else if num_nondmdrugs1yr ge 4 then num_nondmdrugs1yr_cat=4;
        label num_nondmdrugs1yr_cat = "Total number of non-DM drugs in 1 yr before cohort entry";
        format num_nondmdrugs1yr_cat drugs1yrcatf. ; 
        /* *FIXME - duration of treated diabetes -- need to request additional variable from Pascal */
        *  duration_metformin= metformin_first/365.25;
        *  label duration_metformin="Proxy for duration of treated DM: Days between first date of metformin rx and (excl) cohort entry date";
        /* formats and labels  */    
        format sex $sexf. alcohol_cat $statusf. smoke $statusf. hba1c_cat  hba1cf. bmi_cat bmif.;
        /* 2024-01-22 identified bug where prevalent users were actually included. this is wrong and is fixed by overwriting the excludeflag_prevalentuser */
        if &exposure. eq 1 then excludeflag_prevalentuser =max(&comparator._tot1yr ne . and &comparator._tot1yr>0);
        if &exposure. eq 0 then excludeflag_prevalentuser =max(&exposure._tot1yr ne . and &exposure._tot1yr>0);
        label excludeflag_prevalentuser ='EXCLUSION FLAG: prevalent user of comparator drug';
    run;
    /* If save=y then save to temp library for retreival later  */
    %if &save=Y %then %do; 
    data temp.allmerged_&exposure._&comparator.;
    set tmp1;RUN;
    data temp.exclusions_013_&exposure._&comparator.;
    set tmp_counts;RUN;
    %end;
%end;
%mend mergeall;


/* endregion //!SECTION */

/*===================================*\
//SECTION - Running the macro 
\*===================================*/
/* region */


%LET comparatorlist = su tzd sglt2i;
%mergeall(exposure=dpp4i, comparatorlist=&comparatorlist., primaryGraceP=90, washoutp=365, save=Y);

/* getting a preliminary proc contents from which to draw analysis dataset from */
ods excel file="&toutpath./Merged_full_contentsandcounts.xlsx"
options (
    Sheet_interval="PROC" /* PROC | TABLE | NONE */
    embedded_titles="NO"
    embedded_footnotes="NO"
);
ods excel options(sheet_name="dpp4i_su contents" sheet_interval="NOW");
proc contents data= temp.allmerged_dpp4i_su varnum; run;
ods excel options(sheet_name="dpp4i_su counts" sheet_interval="NOW");
proc print data=temp.exclusions_013_dpp4i_su; run;
ods excel options(sheet_name="dpp4i_tzd contents" sheet_interval="NOW");
proc contents data= temp.allmerged_dpp4i_tzd varnum; run;
ods excel options(sheet_name="dpp4i_tzd counts" sheet_interval="NOW");
proc print data=temp.exclusions_013_dpp4i_tzd; run;
ods text="NOTE: no exclusions yet made for heart failure";
ods excel options(sheet_name="dpp4i_sglt2i contents" sheet_interval="NOW");
proc contents data= temp.allmerged_dpp4i_sglt2i varnum; run;
ods excel options(sheet_name="dpp4i_sglt2i counts" sheet_interval="NOW");
proc print data= temp.exclusions_013_dpp4i_sglt2i; run;
ods text="NOTE: no exclusions yet made for year 2012 onwards";
ods excel close;

/* endregion //!SECTION */

%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);