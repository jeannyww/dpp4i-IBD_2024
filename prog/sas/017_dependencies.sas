/***************************************
SAS file name: 017_dependencies.sas

Purpose: For central management of all macro dependencies for the analysis part of mimicking Abrahami's methods. 
Author: JHW
Creation Date: 2024-01-21

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
Date: 2024-01-21
Notes: harmonized macros 017_mimickAbrahami1.sas and 017_mimickAbrahami2.sas into 017_dependencies.sas. 
TODO - add counts for subsequent exclusions 
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=017_dependencies, savelog=N, dataset=_NULL_);

* When using %include, you will load all dependencies specific to the Analysis a la Abrahami, which are not to be generalized or utilized for main analysis ACNU that are true to the correct ACNU methods, so I decided not to include these macros as their own fileexist() in the main SASAUTOS macro library;

/*===================================*\
//SECTION - ## 2. Get cohorts a la Abrahami, adapted from 012_createcohorts.sas
\*===================================*/
/* region */

%macro getCohort_Ab (exposure, comparatorlist, washoutp, save); 
%do z=1 %to %sysfunc(countw(&comparatorlist.));
    %LET comparator = %scan(&comparatorlist.,&z.);
    %put &comparator.;
    /* creating the 'new use' comparator group with switch date as the next date of dpp4i drug initiation if the individual switches from comparator to dpp4i, regardless of the discontinuation date of the first useperiod */
    /* Creating the comparator group a la Abrahami*/
    PROC SQL;
        create table tmp_exclude_&comparator. as
        select distinct a.*,
        max( a.indexdate-&washoutp.<=b.discontDate and b.indexdate<a.indexdate ) as excludeflag_prevalentuser label='EXCLUSION FLAG: prevalent user of &comparator. drug',
        max(a.indexdate=b.indexdate) as excludeflag_samedayinitiator label = 'EXCLUSION FLAG: dual  initiator of &comparator. drug',
        max(a.indexdate<b.indexdate<= a.filldate2) as excludeflag_prefill2initiator label='EXCLUSION FLAG: pre-fill2 dual initiator of comparator drug before second fill date'
        from temp.&comparator._useperiods (where=(newuse=1 and useperiod=1) rename=(reason=reason1)) as a
        left join temp.&exposure._useperiods as b
        on a.id=b.id group by a.id, a.indexdate;
    QUIT;    
    /* adding back in switch/augmentation future date, which is well past the first useperiod but we will miss subsequent switch/augment dates if the person switched after the 1st use period */
    PROC SQL;
        create table _new_abrahami_&comparator. as select distinct a.*, 
        min(b.indexdate) as switchAugmentdate format=date9. label='DATE OF SWITCH/AUGMENTATION'
        from tmp_exclude_&comparator. as a 
        LEFT JOIN temp.&exposure._useperiods as b on a.id=b.id and a.indexdate<=b.indexdate /* <=a.discontDate */
        group by a.id, a.indexdate
        order by a.id, a.indexdate;
    QUIT;
    PROC SQL;
        create table new_abrahami_&comparator. as select distinct a.*,
        min(b.filldate2) as dpp4i_filldate2 format=date9. label='DATE OF SECOND FILL OF &exposure. DRUG for switch/augmentation'
        from _new_abrahami_&comparator. as a
        LEFT JOIN temp.&exposure._useperiods as b on a.id=b.id and a.switchAugmentdate<=b.filldate2 /* <=a.discontDate */
        group by a.id, a.indexdate
        order by a.id, a.indexdate;
    QUIT;
    /*  creating the exposure group a la Abrahami */
    PROC SQL;
        create table tmp_exclude_&exposure. as 
        select distinct a.*,
        max( a.indexdate-&washoutp.<=b.discontDate and b.indexdate<a.indexdate) as excludeflag_prevalentuser label='EXCLUSION FLAG: prevalent user of &exposure. drug',
        max(a.indexdate=b.indexdate) as excludeflag_samedayinitiator label = 'EXCLUSION FLAG: dual  initiator of &exposure. drug',
        max(a.indexdate<b.indexdate<= a.filldate2) as excludeflag_prefill2initiator label='EXCLUSION FLAG: pre-fill2 dual initiator of &exposure. drug before second fill date'
        from temp.&exposure._useperiods (where=(newuse=1 and useperiod=1) rename=(reason=reason1)) as a
        left join temp.&comparator._useperiods as b
        on a.id=b.id group by a.id, a.indexdate;
    QUIT;
    /* creating fake 'new use' time-varying exposure group with switch date as the next date of comparator initiation if the individual switches from dpp4i to comparator, regardless of the discontinuation date of the first use period */
    PROC SQL;
        create table new_abrahami_&exposure. as 
        select distinct a.*, min(b.indexdate) as switchAugmentdate format=date9. label='DATE OF SWITCH/AUGMENTATION'
        from tmp_exclude_&exposure. as a
        LEFT JOIN temp.&comparator._useperiods as b on a.id=b.id and a.indexdate<=b.indexdate /*  <=a.discontDate */
        group by a.id, a.indexdate
        order by a.id, a.indexdate;
    QUIT;

    /* Combining 'new use' of comparator and 'time-varying' abrahami exposure */
    data Abrahami_&exposure._&comparator. (sortedby=id indexdate);
    retain id startdt enddt useperiod indexdate filldate2  switchAugmentdate dpp4i_filldate2 discontDate newuse su dpp4i excludeflag_prevalentuser excludeflag_prefill2initiator  excludeflag_samedayinitiator reason1;
    set new_abrahami_&exposure.  (in=a)  new_abrahami_&comparator.  (in=b);
    by id indexdate;
    &exposure.=a; 
    label &exposure. = "Abrahami-defined drug class: 1= &exposure. 0= &comparator.";
    RUN;

    /* retrive counts and create a new exclusion table to track individuals */
    PROC SQL noprint; 
        CREATE TABLE tmp_id_counts AS SELECT *  FROM temp.exclusions_dpp4i_&comparator.;
        select count(*) into :num_obs from tmp_id_counts;
        INSERT INTO tmp_id_counts
        SET exclusion_num = &num_obs + 1,
        long_text = "Initiators of &exposure. or &comparator.",
        dpp4i = (select count(distinct id ) from temp.&exposure._useperiods),
        &comparator. = (select count(distinct id ) from temp.&comparator._useperiods);  

        insert into tmp_id_counts
        set exclusion_num = &num_obs + 2,
        long_text="Restricting to newuse==1 and useperiod==1", 
        dpp4i = (select count(distinct id ) from tmp_exclude_&exposure.),
        &comparator. = (select count(distinct id ) from tmp_exclude_&comparator.);
    QUIT;
proc print data=tmp_id_counts;
run;


    /* If save eq Y then save to temp folder for retrieval later */
    %if &save.=Y %then %do; 
    data temp.Abrahami_&exposure._&comparator.;set Abrahami_&exposure._&comparator.;RUN;
    data temp.Abexclusions_012_&exposure._&comparator.;set tmp_id_counts;RUN;
    %end;
%end;
%mend getCohort_Ab;

/* endregion //!SECTION */

/*===================================*\
//SECTION - ## 3. Merge cohorts a la Abrahami, adapted from 013_merge.sas
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
%macro mergeall_Ab(exposure, comparatorlist, primaryGraceP, washoutp, save=N);
        %do z=1 %to %sysfunc(countw(&comparatorlist.));
        %let comparator = %scan(&comparatorlist., &z.);
    /* Replacing newuse with the Abrahami created cohort from above, 'tmpnewuser' is a misnomer */
    data tmpnewuser;
    set temp.Abrahami_&exposure._&comparator.; RUN;
    
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
    * merging in the events dataset;
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
    label history="Number of days of recorded history in the database prior to the time0 (the number of days between the first prescription in the patients profile and the time0, historical entries prior 1987 are ignored).";
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
        /* TODO - Either complete case analysis or impute missing hba1c and bmi, currently missing category is in the model. */
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
        /* TODO - Either complete case analysis or impute missing hba1c and bmi, currently missing category is in the model. */
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
        /* *TODO - *FIXME - duration of treated diabetes -- need to request additional variable from Pascal */
        *  duration_metformin= metformin_first/365.25;
        *  label duration_metformin="Proxy for duration of treated DM: Days between first date of metformin rx and (excl) cohort entry date";

        /* *NOTE - 2024-01-22 identified bug where prevalent users were actually included. this is wrong and is fixed by overwriting the excludeflag_prevalentuser */
        if &exposure. eq 1 then excludeflag_prevalentuser =max(&comparator._ever); 
        if &exposure. eq 0 then excludeflag_prevalentuser =max(&exposure._ever);
        *if &exposure. eq 1 then excludeflag_prevalentuser =max(&comparator._tot1yr ne . and &comparator._tot1yr>0);
        *if &exposure. eq 0 then excludeflag_prevalentuser =max(&exposure._tot1yr ne . and &exposure._tot1yr>0);
        label excludeflag_prevalentuser ='EXCLUSION FLAG: prevalent user of comparator drug';
        /* formats  */    
        format sex $sexf. alcohol_cat $statusf. smoke $statusf. hba1c_cat  hba1cf. bmi_cat bmif.;
    run;
    /* If save=y then save to temp library for retreival later  */
    %if &save=Y %then %do; 
    data temp.Abrahami_allmerged_&exposure._&comparator.;
    set tmp1;RUN;

    %end;
%end;
%mend mergeall_Ab;

/* endregion //!SECTION */

/*===================================*\
//SECTION - ## 4. creating analysis dataset a la Abrahami, adapted from 014_createanalysis.sas
\*===================================*/
/* region */

%macro createana_Ab(exposure=, comparatorlist=, save=N);
%do i = 1 %to %sysfunc(countw(&comparatorlist));
%LET comparator = %scan(&comparatorlist, &i);
        /* Bring in counts and merged dataset */
    data tmp1; set temp.Abrahami_allmerged_&exposure._&comparator.;RUN;
    data tmpana_&exposure._&comparator.;
        set tmp1;
        if (/* excludeflag_prevalentuser eq 1 or */ excludeflag_samedayinitiator eq 1 or excludeflag_prefill2initiator eq 1 or filldate2 eq . ) then delete; 
        /* Only excluding prevalent users if the patient was an initiator of the comparator drug class */
        if (&exposure eq 1 and excludeflag_prevalentuser eq 1) then keepflag_prevalentuser=1;
        if (&exposure eq 0 and excludeflag_prevalentuser eq 1) then delete;
        /* Tailoring the Main analysis exclusion criteria to mimic Abrahami's time-varying treatment and outcome design, where prevalent users were included for dpp4i but not for the comparator */
        if keepflag_prevalentuser ne 1 then do; 
            if ((crohns_bl not in (., 0) or ucolitis_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) )) then delete;    
            if ((AminoS_bl not in (., 0) or budeo_bl not in (., 0) or tnfai_bl not in (., 0) or otherimm_bl not in (., 0) )) or (colile_bl not in (., 0) ) then delete;
            END;
        /* exclude prior to 2012 for sglt2i */
        %if &comparator eq sglt2i %then %do; 
        if year(indexdate) lt 2012 then delete; 
        %end;
        /* exclude heart failure for tzd */
        %if &comparator eq tzd  %then %do;
        if chf_bl not in (., 0) then delete;
        %end;  
    RUN; 
    /* adding counts for flowchart */
    data tmp_counts; 
        retain exclusion_num long_text dpp4i dpp4i_diff &comparator. &comparator._diff;
        set temp.Abexclusions_012_&exposure._&comparator.;
        dpp4i_diff=dpp4i- lag(dpp4i);
        &comparator._diff= &comparator.- lag(&comparator.); RUN;
    PROC SQL noprint; 
        select count(*) into :num_obs from tmp_counts;
        /* getting counts from each sequential exclusion */
        insert into tmp_counts 
        set exclusion_num= &num_obs+1 ,
            long_text="Initiators after exclusions a through c (non-mutually exclusive)", 
            dpp4i=(select count(*) from tmp1 where dpp4i=1 and not (excludeflag_samedayinitiator=1 or excludeflag_prefill2initiator=1 or filldate2=.)),
            &comparator.= (select count(*) from tmp1 where dpp4i=0 and not (excludeflag_prevalentuser eq 1 or excludeflag_samedayinitiator=1 or excludeflag_prefill2initiator=1 or filldate2=.)),
            dpp4i_diff= -(select count(*) from tmp1 where dpp4i=1 and (excludeflag_samedayinitiator=1 or excludeflag_prefill2initiator=1 or filldate2=.)),
            &comparator._diff= -(select count(*) from tmp1 where dpp4i=0 and (excludeflag_prevalentuser eq 1 or excludeflag_samedayinitiator=1 or excludeflag_prefill2initiator=1 or filldate2=.));
        /* Were prevalent users of the comaprator drug */
        insert into tmp_counts 
            set exclusion_num= &num_obs+2 ,
            long_text="a. Were prevalent users of &exposure. or &comparator. drug", 
            dpp4i_diff= (select count(*) from tmp1 where dpp4i=1 and excludeflag_prevalentuser=1),
            &comparator._diff= -(select count(*) from tmp1 where dpp4i=0 and excludeflag_prevalentuser=1);
        /* initiated comparator drug on the same day */
        insert into tmp_counts 
        set exclusion_num= &num_obs+3 ,
            long_text="b. Dual initiator of &exposure. and &comparator.", 
            dpp4i_diff= -(select count(*) from tmp1 where dpp4i=1 and excludeflag_samedayinitiator=1),
            &comparator._diff= -(select count(*) from tmp1 where dpp4i=0 and excludeflag_samedayinitiator=1);
        /* filled comparator drug before second prescription */
        insert into tmp_counts 
        set exclusion_num= &num_obs+4 ,
            long_text="c. Filled drug before second prescription", 
            dpp4i_diff= -(select count(*) from tmp1 where dpp4i=1 and excludeflag_prefill2initiator=1),
            &comparator._diff= -(select count(*) from tmp1 where dpp4i=0 and excludeflag_prefill2initiator=1);
        /* had no second prescription */
        insert into tmp_counts 
        set exclusion_num= &num_obs+5,
            long_text="d. Had no respecitve second &exposure. or &comparator. prescription", 
            dpp4i_diff= -(select count(*) from tmp1 where dpp4i=1 and filldate2=.),
            &comparator._diff= -(select count(*) from tmp1 where dpp4i=0 and filldate2=.);
    quit;
    data tmp2;
                set tmp1;
        if (/* excludeflag_prevalentuser eq 1 or */ excludeflag_samedayinitiator eq 1 or excludeflag_prefill2initiator eq 1 or filldate2 eq . ) then delete; 
        /* Only excluding prevalent users if the patient was an initiator of the comparator drug class */
        if (&exposure eq 1 and excludeflag_prevalentuser eq 1) then keepflag_prevalentuser=1;
        if (&exposure eq 0 and excludeflag_prevalentuser eq 1) then delete;

        if keepflag_prevalentuser ne 1 then do; 
            if ((crohns_bl not in (., 0) or ucolitis_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) )) then delete_IBD=1;    
            if ((AminoS_bl not in (., 0) or budeo_bl not in (., 0) or tnfai_bl not in (., 0) or otherimm_bl not in (., 0) )) then delete_ibdmeds=1;
            END;
        RUN;
    PROC SQL NOPRINT; 
        select count(*) into :num_obs from tmp_counts;        
        * Had the following diagnosed diseases before the first prescription were excluded: (a-f non-mutually exclusive)) ;
        insert into tmp_counts 
        set exclusion_num= &num_obs+1 ,
        long_text="Had the diagnosed diseases before the first prescription (a-f non-mutually exclusive)",
        dpp4i= (select count(*) from tmp2 where dpp4i=1 and delete_IBD ne 1), 
        dpp4i_diff= -(select count(*) from tmp2 where dpp4i=1 and delete_IBD eq 1)  ,
        &comparator= (select count(*) from tmp2 where dpp4i=0  and delete_IBD ne 1),
        &comparator._diff=- (select count(*) from tmp2 where dpp4i=0 and delete_IBD eq 1);
        /*  a. Had Chron's disease */
        insert into tmp_counts 
        set exclusion_num= &num_obs+2 ,
        long_text="a. Had Crohn's disease", 
        dpp4i_diff= -(select count(*) from tmp2 where dpp4i=1 and delete_IBD eq 1 and crohns_bl not in (., 0)),
        &comparator._diff= -(select count(*) from tmp2 where dpp4i=0 and delete_IBD eq 1 and crohns_bl not in (., 0));
        /*  b. had Ulcerative colitis */
        insert into tmp_counts 
        set exclusion_num= &num_obs+3 ,
        long_text="b. Had Ulcerative colitis", 
        dpp4i_diff= -(select count(*) from tmp2 where dpp4i=1 and delete_IBD eq 1 and ucolitis_bl not in (., 0)),
        &comparator._diff= -(select count(*) from tmp2 where dpp4i=0 and delete_IBD eq 1 and ucolitis_bl not in (., 0));
        /*  c. had ischemic colitis */
        insert into tmp_counts 
        set exclusion_num= &num_obs+4 ,
                long_text="c. Had ischemic colitis", 
                dpp4i_diff= -(select count(*) from tmp2 where dpp4i=1 and delete_IBD eq 1 and icomitis_bl not in (., 0)),
                &comparator._diff= -(select count(*) from tmp2 where dpp4i=0 and delete_IBD eq 1 and icomitis_bl not in (., 0));
        /*  d. had diverticulitis or other colitis*/
            insert into tmp_counts 
            set exclusion_num= &num_obs+5 ,
            long_text="d. Had diverticulitis or other colitis", 
            dpp4i_diff= -(select count(*) from tmp2 where dpp4i=1 and delete_IBD eq 1  and DivCol_P_bl not in (., 0)),
            &comparator._diff= -(select count(*) from tmp2 where dpp4i=0  and delete_IBD eq 1 and DivCol_P_bl not in (., 0));        
    QUIT;
data tmp2; set tmp2; where delete_IBD ne 1;RUN;
    PROC SQL  NOPRINT; 
        select count(*) into :num_obs from tmp_counts;
        /* Initiators received treatment for IBD before the first prescription were excluded */
        insert into tmp_counts 
        set exclusion_num= &num_obs+1 ,
        long_text="Received treatment for IBD before the first prescription were excluded",
        dpp4i= (select count(*) from tmp2 where dpp4i=1 and delete_ibdmeds ne 1), 
        dpp4i_diff= -(select count(*) from tmp2 where dpp4i=1 and delete_ibdmeds eq 1),
        &comparator= (select count(*) from tmp2 where dpp4i=0 and delete_ibdmeds ne 1),
        &comparator._diff= -(select count(*) from tmp2 where dpp4i=0 and delete_ibdmeds eq 1);
        /* a. had aminosalicylates */
        insert into tmp_counts 
        set exclusion_num= &num_obs+2 ,
        long_text="a. had aminosalicylates", 
        dpp4i_diff= (select count(*) from tmp2 where dpp4i=1 and delete_ibdmeds eq 1 and AminoS_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and delete_ibdmeds eq 1 and AminoS_bl not in (., 0));
        /* b. had enteral budesonide */
        insert into tmp_counts 
        set exclusion_num= &num_obs+3 ,
        long_text="b. had enteral budesonide", 
        dpp4i_diff= (select count(*) from tmp2 where dpp4i=1 and delete_ibdmeds eq 1 and budeo_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and delete_ibdmeds eq 1 and budeo_bl not in (., 0));
        /* c. had IBD treatment-specific TNF-alpha inhibitors */
        insert into tmp_counts 
        set exclusion_num= &num_obs+4 ,
        long_text="c. had IBD treatment-specific TNF-alpha inhibitors", 
        dpp4i_diff= (select count(*) from tmp2 where dpp4i=1 and delete_ibdmeds eq 1 and tnfai_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and delete_ibdmeds eq 1 and tnfai_bl not in (., 0));
        /* d. had other immunosuppressants (azathioprine, 6-mercaptopurine, methotrexate) */
        insert into tmp_counts 
        set exclusion_num= &num_obs+5 ,
        long_text="d. had other immunosuppressants (azathioprine, 6-mercaptopurine, methotrexate)", 
        dpp4i_diff= (select count(*) from tmp2 where dpp4i=1 and delete_ibdmeds eq 1 and otherimm_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and delete_ibdmeds eq 1 and otherimm_bl not in (., 0));
    QUIT;
    data tmp2; set tmp2; where delete_IBDmeds ne 1;
        if keepflag_prevalentuser ne 1 then do; if (colile_bl not in (., 0) ) then delete_colile=1;
        end; RUN;
    PROC SQL NOPRINT; 
        select count(*) into :num_obs from tmp_counts;
        /* Initiators with the following procedures before the first prescription were excluded  */
        /* a. had colectomy, colostomy, or ileostomy */
        insert into tmp_counts 
        set exclusion_num= &num_obs+1 ,
        long_text="Initiators with colectomy, colostomy, or ileostomy before the first prescription were excluded",
        dpp4i= (select count(*) from tmp2 where dpp4i=1 and delete_colile ne 1 ), 
        dpp4i_diff= -(select count(*) from tmp2 where dpp4i=1 and delete_colile eq 1),
        &comparator= (select count(*) from tmp2 where dpp4i=0 and delete_colile ne 1 ),
        &comparator._diff= -(select count(*) from tmp2 where dpp4i=0 and delete_colile eq 1);
    QUIT;
    data tmp3; set tmp2; where  delete_colile ne 1; RUN;

    %if &comparator eq sglt2i %then %do; 
            PROC SQL NOPRINT; 
            select count(*) into :num_obs from tmp_counts;
            /* If the comparator is sglt2i then all iniators before 2012 are excluded */
            insert into tmp_counts
            set exclusion_num= &num_obs+1 ,
            long_text="Initiators before 2012 were excluded",
            dpp4i= (select count(*) from tmp3 where dpp4i=1 and year(indexdate) not lt 2012),
            dpp4i_diff= -(select count(*) from tmp3 where dpp4i=1 and year(indexdate) lt 2012),
            &comparator= (select count(*) from tmp3 where dpp4i=0 and year(indexdate) not lt 2012),
            &comparator._diff= -(select count(*) from tmp3 where dpp4i=0 and year(indexdate) lt 2012);
        QUIT;
    %end;
    /* exclude heart failure for tzd */
    %if &comparator eq tzd  %then %do;
        PROC SQL NOPRINT; 
            select count(*) into :num_obs from tmp_counts;
            /* If the comparator is dpp4i then all initiators with history of CHF are excluded */
            insert into tmp_counts
            set exclusion_num= &num_obs+1 ,
            long_text="Initiators with history of CHF were excluded",
            dpp4i= (select count(*) from tmp3 where dpp4i=1 and not (chf_bl not in (., 0))),
            dpp4i_diff= -(select count(*) from tmp3 where dpp4i=1 and chf_bl not in (., 0)),
            &comparator= (select count(*) from tmp3 where dpp4i=0 and not (chf_bl not in (., 0))),
            &comparator._diff= -(select count(*) from tmp3 where dpp4i=0 and chf_bl not in (., 0));
        QUIT;
    %end;  
    /* Check that the exclusion numbers match  */
    proc sql NOPRINT;
        insert into tmp_counts set
        long_text="Check: numrows of tmpana_&exposure._&comparator. = numrows of tmp_counts",
        full= (select count(*) from tmpana_&exposure._&comparator.);
        quit;
    proc print data=tmp_counts; run;

    /* add a column of totals for full */
    data tmp_counts;
        set tmp_counts;
        if full eq . then do;
        full=dpp4i+&comparator.;
        end;
        RUN;    
    /* if save==y then save to analysis folder */
    %if &save=Y %then %do;
    data a.Abrahami_allmerged_&exposure._&comparator.;
        set  tmpana_&exposure._&comparator.;
        RUN;
    data temp.Abexclusions_014_&exposure._&comparator.;
        set tmp_counts;
        RUN;
    %end;

%end;
%mend createana_Ab;

/* endregion //!SECTION */

/*===================================*\
//SECTION - ## 5. PS weighting adapted from 015_PSweighting.sas
\*===================================*/
/* region */
%macro psweighting_Ab ( exposure , comparator , weight , addedmodelvars ,basemodelvars , tablerowvars, refyear  , dat, save );

    data tmp1;
        set a.Abrahami_allmerged_&exposure._&comparator.;
    RUN;

    /*=================*\
    PS weighting
    \*=================*/
    *%removeMetadata(tmp1);


    *  ods rtf file="&goutpath./&todaysdate.psoutput&exposure._&comparator..rtf";
    proc logistic data=tmp1 descending;
        class  entry_year (ref="&refyear.") sex (ref=first) hba1c_Cat2 (ref=first) alcohol_cat (ref=first)
        smoke_cat (ref=first) bmi_cat2(ref=first) /param=ref; 
        model &exposure. =    /*Adding further model variables and interactions VARIABLE*/
        &addedmodelvars. &basemodelvars.
        ; output out= psdsnnotrim pred=ps; run; 
        ods rtf close; 
    /* Calculating the marginal probability of treatment for the stabilized IPTW */
        PROC MEANS DATA=psdsnnotrim(keep=ps) ;
            VAR ps;
            OUTPUT OUT=ps_mean MEAN=marg_prob;
        RUN;
        
        DATA _NULL_;
            SET ps_mean;
            CALL SYMPUT("marg_prob",trim(left(put(marg_prob, BEST12.))));
        RUN;
        %put &marg_prob;
    /* calculating weights from PS */
    proc sql NOPRINT;
        select count(*) into : n_&exposure. 
        from tmp1
        where &exposure=1;    
        select count(*) into : n_&comparator. 
        from tmp1
        where &exposure=0;
    quit;
    %put &&n_&exposure; 
    %put &&n_&comparator;

    /*=================*\
    Untrimmed weights
    \*=================*/

    data psdsnnotrim;
        set psdsnnotrim;
        label ps = "Propensity score";  
        *IPTW; if &exposure. eq 1 then iptw=1/ps; 
        else if &exposure. eq 0 then iptw=1/(1-ps);
        label iptw = "Inverse probability of treatment weight (ATE)";
        *SIPTW; if &exposure. eq 1 then siptw=&marg_prob/PS; 
        else if &exposure. eq 0 then siptw=(1-&marg_prob)/(1-PS);    
        label siptw = "Stabilized Inverse probability of treatmen (ATE)"; 
        *SMRW; if &exposure. eq 1 then smrw=1;
        else if &exposure. eq 0 then smrw=ps/(1-ps);
        label smrw = "Standardized mortality ratio weight (ATT)";
        *SMRWU; if &exposure. eq 1 then smrwu=(1-ps)/(1-(1-ps));
        else if &exposure. eq 0 then smrwu=1;
        label smrwu = "Standardized mortality ratio weight in Untreated (ATU)";
        *SSMRWU; IF &exposure = 1 THEN ssmrwu = (1-ps)/(1-(1-ps))*(&&n_&exposure/(&&n_&exposure+&&n_&comparator))/(&&n_&comparator/(&&n_&exposure+&&n_&comparator)) ;
        ELSE IF &exposure = 0 THEN ssmrwu = 1;
        label ssmrwu = "Stabilized Standardized mortality ratio weight in Untreated (ATU)";
    RUN;
    /* visualizing distribution using kernel density estimation */
    proc kde data=psdsnnotrim (where=(&exposure. = 1)) ;
        univar ps (gridl=0 gridu=1)/ out=ps_&exposure. bwm=0.25;
        run; quit;
    proc kde data=psdsnnotrim (where=(&exposure. = 0)) ;
        univar ps (gridl=0 gridu=1)/ out=ps_&comparator. bwm=0.25;
        run; quit;
    data psplot; set ps_&exposure. (in=a) ps_&comparator. (in=b); 
        if a then pop="&exposure."; 
        else if b then pop="&comparator."; 
        label value = "Propensity Score" pop="Treatment" density="Density";run;

    /* Printing untrimmed psplot */
    goptions reset=all device=png targetdevice=tiff gsfname=grafout gsfmode=replace;
    filename grafout "&foutpath./Abrahami_psplot_&exposure._&comparator.&todaysdate..tiff";
    symbol1 interpol=spline value=none line=1;
    symbol2 interpol=spline value=none line=2;
    axis1 order=(0 to 1 by 0.1) minor=none label=(a=0 j=c h=1.5 f=swiss 'Propensity Score') value=(h=1.1 f=swiss);
    axis2 minor=(n=1) label=(a=90 j=c h=1.5 f=swiss 'Density') value=(h=1.1 f=swiss);
    title "Untrimmed PS distribution for &exposure. use, by treatment status";
    proc gplot data=psplot;
        plot density*value=pop / haxis=axis1 vaxis=axis2;
        run; quit;
        title;
        /* Printing untrimmed psplot */
    goptions reset=all device=png targetdevice=png gsfname=grafout gsfmode=replace;
    filename grafout "&foutpath./Abrahami_psplot_&exposure._&comparator.&todaysdate..png";
    symbol1 interpol=spline value=none line=1;
    symbol2 interpol=spline value=none line=2;
    axis1 order=(0 to 1 by 0.1) minor=none label=(a=0 j=c h=1.5 f=swiss 'Propensity Score') value=(h=1.1 f=swiss);
    axis2 minor=(n=1) label=(a=90 j=c h=1.5 f=swiss 'Density') value=(h=1.1 f=swiss);
    title "Untrimmed PS distribution for &exposure. use, by treatment status";
        proc gplot data=psplot;
            plot density*value=pop / haxis=axis1 vaxis=axis2;
            run; quit;
            title;
    /*=================*\
    TRIMMING
    \*=================*/

    /* Evaluating weights and preparing for trimming */
    * Univariate analyses on weight varialbes by treatment status checking for extreme weights;
    proc univariate data=psdsnnotrim ; class &exposure.; var iptw siptw smrw smrwu ssmrwu; run; quit;
    /*Identify percentiles for trimming, additional percentiles can be added in the output statement by creating one in PCTLPTS=*/
    proc univariate data=psdsnnotrim ; class &exposure.; 
    var ps;
    output out=ps_pctl min=min max=max p1=p1 p5=p5 p10=p10 p90=p90 p95=p95 p99=p99 PCTLPTS=0.5 99.5 pctlpre=p;
    title "Distribution of propensity score for &exposure. use, by treatment status";
    run; quit;
    proc print data=ps_pctl; run; 
    /* Creating macro variables for the LOWER PCTL of PS for the treated */
    data _NULL_; set ps_pctl; where &exposure.=1;
        call symput("treated_min", trim(left(put(min, BEST12.)))); 
        call symput("treated_005", trim(left(put(p0_5, BEST12.)))); 
        call symput("treated_01", trim(left(put(p1, BEST12.)))); 
        call symput("treated_05", trim(left(put(p5, BEST12.)))); 
        call symput("treated_10", trim(left(put(p10, BEST12.)))); 
        RUN;
    %put &treated_min. &treated_005. &treated_01. &treated_05. &treated_10.;
    /* Creating macro variables for the UPPER PCTL of PS for the untreated */
    data _NULL_; set ps_pctl; where &exposure.=0;
        call symput("untreated_max", trim(left(put(max, BEST12.))));
        call symput("untreated_90", trim(left(put(p90, BEST12.))));
        call symput("untreated_95", trim(left(put(p95, BEST12.))));
        call symput("untreated_99", trim(left(put(p99, BEST12.))));
        call symput("untreated_995", trim(left(put(p99_5, BEST12.))));
        RUN;
    %put &untreated_max. &untreated_90. &untreated_95. &untreated_99. &untreated_995.;
    /* check for treatment effect heterogeneity */
    data psdsn; set psdsnnotrim; 
        where &treated_005 <= ps <= &untreated_995;RUN;
    PROC SQL NOPRINT; 
        title "count &exposure.";
        select count(*) into : n_&exposure._trim from psdsn where &exposure.=1;
        title "count &comparator.";
        select count(*) into : n_&comparator._trim from psdsn where &exposure.=0;
    QUIT;
    %put &&n_&exposure._trim;
    %put &&n_&comparator._trim;

    /*=================*\
    TRIMMED REESTIMATE PS post-trimming
    \*=================*/
    ods rtf file="&goutpath./Abrahami_psoutputTRIM_&exposure._&comparator.&todaysdate..rtf";
    proc logistic data=psdsn desc;
        class entry_year (ref="&refyear.") sex (ref=first) hba1c_Cat2 (ref=first) alcohol_cat (ref=first) smoke_cat (ref=first) bmi_cat2(ref=first) /param=ref;
        model &exposure. =  &addedmodelvars. &basemodelvars. ; 
        output out= psdsn pred=ps; run;
    ods rtf close;
    *  calculate marginal probability of treatment for the stabilized IPTW;
    proc means data=psdsn(keep=ps) noprint;
        var ps;
        output OUT=ps_mean MEAN=marg_prob;RUN;
    DATA _NULL_;
        set ps_mean;
        call symput("marg_prob",trim(left(put(marg_prob, BEST12.))));RUN;
    %put &marg_prob.;
    /* calculating weights from PS */
    data psdsn; set psdsn;
        label ps = "Propensity score";  
        *IPTW; if &exposure. eq 1 then iptw=1/ps; 
        else if &exposure. eq 0 then iptw=1/(1-ps);
        label iptw = "Inverse probability of treatment weight (ATE)";
        *SIPTW; if &exposure. eq 1 then siptw=&marg_prob/PS; 
        else if &exposure. eq 0 then siptw=(1-&marg_prob)/(1-PS);    
        label siptw = "Stabilized Inverse probability of treatmen (ATE)"; 
        *SMRW; if &exposure. eq 1 then smrw=1;
        else if &exposure. eq 0 then smrw=ps/(1-ps);
        label smrw = "Standardized mortality ratio weight (ATT)";
        *SMRWU; if &exposure. eq 1 then smrwu=(1-ps)/(1-(1-ps));
        else if &exposure. eq 0 then smrwu=1;
        label smrwu = "Standardized mortality ratio weight in Untreated (ATU)";
        *SSMRWU; IF &exposure = 1 THEN ssmrwu = (&&n_&exposure._trim/(&&n_&exposure._trim+&&n_&comparator._trim))/(&&n_&comparator._trim/(&&n_&exposure._trim+&&n_&comparator._trim)) *(1-ps)/(1-(1-ps));
        ELSE IF &exposure = 0 THEN ssmrwu = 1;
        label ssmrwu = "Stabilized Standardized mortality ratio weight in Untreated (ATU)";
        RUN;
    *Evaluating PS post-trimming distribution;
    proc kde data=psdsn (where=(&exposure. = 1)) ;
        univar ps (gridl=0 gridu=1)/ out=ps_&exposure._trim bwm=0.25;
        run; quit;
    proc kde data=psdsn (where=(&exposure. = 0)) ;
        univar ps (gridl=0 gridu=1)/ out=ps_&comparator._trim bwm=0.25;
        run; quit;
    data psplot_trim; set ps_&exposure._trim (in=a) ps_&comparator._trim (in=b); 
        if a then pop="&exposure."; 
        else if b then pop="&comparator."; 
        label value = "Propensity Score" pop="Treatment" density="Density";run;
    /* Printing trimmed psplot */
    goptions reset=all device=png targetdevice=tiff gsfname=grafout gsfmode=replace;
    filename grafout "&foutpath./Abrahami_psplot_trim_&exposure._&comparator.&todaysdate..tiff";
    symbol1 interpol=spline value=none line=1;
    symbol2 interpol=spline value=none line=2;
    axis1 order=(0 to 1 by 0.1) minor=none label=(a=0 j=c h=1.5 f=swiss 'Propensity Score') value=(h=1.1 f=swiss);
    axis2 minor=(n=1) label=(a=90 j=c h=1.5 f=swiss 'Density') value=(h=1.1 f=swiss);
    title "Trimmed PS distribution for &exposure. use, by treatment status";
    proc gplot data=psplot_trim;
        plot density*value=pop / haxis=axis1 vaxis=axis2;
        run; quit;
        title;
    goptions reset=all device=png targetdevice=png gsfname=grafout gsfmode=replace;
    filename grafout "&foutpath./Abrahami_psplot_trim_&exposure._&comparator.&todaysdate..png";
    symbol1 interpol=spline value=none line=1;
    symbol2 interpol=spline value=none line=2;
    axis1 order=(0 to 1 by 0.1) minor=none label=(a=0 j=c h=1.5 f=swiss 'Propensity Score') value=(h=1.1 f=swiss);
    axis2 minor=(n=1) label=(a=90 j=c h=1.5 f=swiss 'Density') value=(h=1.1 f=swiss);
    title "Trimmed PS distribution for &exposure. use, by treatment status";
    proc gplot data=psplot_trim;
        plot density*value=pop / haxis=axis1 vaxis=axis2;
        run; quit;
        title;
    * check univariate analysis on weight variables by treatment status, check for extreme weights;
    proc univariate data=psdsn ; class &exposure.; var iptw siptw smrw smrwu ssmrwu; run; 

    /*=================*\
    Save Point`
    \*=================*/
    %if &save. = Y %then %do;
        data a.Abrahami_PS_&exposure._&comparator.; set psdsn; run;
        /* Updating exclusions for PS trimming */
        PROC SQL; 
            create table tmp_counts as select * from temp.Abexclusions_014_&exposure._&comparator.;
            select count(*) into : num_obs from tmp_counts;
            insert into tmp_counts
                set exclusion_num=&num_obs+1, 
                long_text="Number of observations after trimming at 0.05 treated and 0.995 untreated",
                dpp4i=&&n_&exposure._trim,
                dpp4i_diff=&&n_&exposure._trim-&&n_&exposure.,
                &comparator.=&&n_&comparator._trim,
                &comparator._diff=&&n_&comparator._trim-&&n_&comparator., 
                full=&&n_&exposure._trim+&&n_&comparator._trim;
            create table temp.Abexclusions_015_&exposure._&comparator. as select * from tmp_counts;
        QUIT;
    %end;%else %do; %end;

    /*=================*\
    Table 1 trimmed
    \*=================*/
    proc format; value &exposure. 0="&comparator." 1="&exposure."; run;
    proc datasets lib=work nolist nodetails; modify psdsn; 
        format &exposure. &exposure..  sex $sexf.  alcohol_cat $statusf. smoke_cat $statusf. hba1c_cat2  hba1cf. bmi_cat bmif.;
        run;
    %LET wgtvar=smrw;
    %let ds = psdsn ;
    %let colVar = &exposure.;
    %let rowVars = &tablerowvars. ;
    %LET outname = Table1_&exposure._&comparator._&todaysdate.; 
    options orientation=landscape nodate nonumber nocenter;
    %table1(inds= &ds, colVar= &colVar, rowVars= &rowVars, wgtVar= , maxLevels=16, outfile=&outname, title=&outname, cellsize=5);

    
    title ;
    data tab1_unwgt_&exposure.; 
        set final; run;
    proc datasets lib=work nolist nodetails; delete final; run; quit;
    %table1(inds= &ds, colVar= &colVar, rowVars= &rowVars, wgtVar= &wgtvar, maxLevels=16, outfile=&outname, title=&outname, cellsize=5);
    title;
    data tab1_wgt_&exposure.; 
        set final; run;
    proc datasets lib=work nolist nodetails; delete final; run; quit;
    /* Joining tables together */
    proc sql;
        create table table1_&exposure.v&comparator. as
        select a.row, a.&exposure., a.&comparator., a.sdiff label='Unwgted Stdz Diff',
            b.&comparator._wgt, b.sdiff as sdiff_wgt label='Wgted Stdz Diff', a.order, a.roworder
        from tab1_unwgt_&exposure. as a 
        left join tab1_wgt_&exposure. (rename=(&comparator=&comparator._wgt)) as b
            on a.row=b.row and a.order=b.order and a.roworder=b.roworder
        order by order, roworder;
    quit;
    ods escapechar='~' ;
    options orientation=landscape nodate nonumber nocenter;
    ods rtf file="&toutPath./Abrahami_Table1trim_&exposure._&comparator._&todaysdate..rtf";
    proc print data=table1_&exposure.v&comparator. noobs label; var row &exposure &comparator sdiff &comparator._wgt sdiff_wgt; run;
    ods rtf close;

%mend psweighting_Ab;

/* endregion //!SECTION */

/*===================================*\
//SECTION - ## 6. Analysis a la Abrahami, adapted from 016_analysis.sas
\*===================================*/
/* region */

%macro analysis_Ab ( exposure , comparator , ana_name , type , weight , induction , latency , ibd_def , intime , outtime , outdata, save ) / minoperator mindelimiter=',';

    /*===================================*\
    //SECTION - Setting up data for analysis 
    \*===================================*/
        data dsn; set a.Abrahami_PS_&exposure._&comparator;
        drop Alc_P_bc Alc_P_bl colo_bc colo_bl IBD_P_bc IBD_P_bl DivCol_I_bc DivCol_I_bl DivCol_P_bc DivCol_P_bl PCOS_bc PCOS_bl DiabGest_bc DiabGest_bl IBD_I_bc IBD_I_bl asthma_bc asthma_bl copd_bc copd_bl arrhyth_bc arrhyth_bl chf_bc chf_bl ihd_bc ihd_bl mi_bc mi_bl hyperten_bc hyperten_bl stroke_bc stroke_bl hyperlip_bc hyperlip_bl diab_bc diab_bl dvt_bc dvt_bl pe_bc pe_bl gout_bc 
        gout_bl pthyro_bc pthyro_bl mthyro_bc mthyro_bl depres_bc depres_bl affect_bc affect_bl suic_bc suic_bl sleep_bc sleep_bl schizo_bc schizo_bl epilep_bc epilep_bl renal_bc renal_bl GIulcer_bc GIulcer_bl RhArth_bc RhArth_bl alrhi_bc alrhi_bl glauco_bc glauco_bl migra_bc migra_bl sepsis_bc sepsis_bl pneumo_bc pneumo_bl nephr_bc nephr_bl nerop_bc nerop_bl dret_bc dret_bl psorI_bc psorI_bl psorP_bc psorP_bl vasc_bc vasc_bl SjSy_bc SjSy_bl sLup_bc sLup_bl PerArtD_bc PerArtD_bl AbdPain_bc AbdPain_bl Diarr_bc Diarr_bl BkStool_bc BkStool_bl Crohns_bc 
        Crohns_bl Ucolitis_bc Ucolitis_bl Icomitis_bc Icomitis_bl Gastent_bc Gastent_bl ColIle_bc ColIle_bl Sigmo_bc Sigmo_bl Biops_bc Biops_bl Ileo_bc Ileo_bl HBA1c_bc HBA1c_bl DPP4i_bc DPP4i_gc DPP4i_bl DPP4i_tot1yr SU_bc SU_gc SU_bl SU_tot1yr SGLT2i_bc SGLT2i_gc SGLT2i_bl SGLT2i_tot1yr TZD_bc TZD_gc TZD_bl TZD_tot1yr Insulin_bc Insulin_gc Insulin_bl Insulin_tot1yr bigua_bc bigua_gc bigua_bl bigua_tot1yr prand_bc prand_gc prand_bl prand_tot1yr agluco_bc agluco_gc agluco_bl agluco_tot1yr OAntGLP_bc OAntGLP_gc OAntGLP_bl OAntGLP_tot1yr AminoS_bc 
        AminoS_gc AminoS_bl AminoS_tot1yr Mesal_bc Mesal_gc Mesal_bl Mesal_tot1yr Sulfas_bc Sulfas_gc Sulfas_bl Sulfas_tot1yr Olsala_bc Olsala_gc Olsala_bl Olsala_tot1yr Balsal_bc Balsal_gc Balsal_bl Balsal_tot1yr ace_bc ace_gc ace_bl ace_tot1yr arb_bc arb_gc arb_bl arb_tot1yr bb_bc bb_gc bb_bl bb_tot1yr ccb_bc ccb_gc ccb_bl ccb_tot1yr nitrat_bc nitrat_gc nitrat_bl nitrat_tot1yr coronar_bc coronar_gc coronar_bl coronar_tot1yr antiarr_bc antiarr_gc antiarr_bl antiarr_tot1yr thrombo_bc thrombo_gc thrombo_bl thrombo_tot1yr antivitk_bc antivitk_gc 
        antivitk_bl antivitk_tot1yr hepar_bc hepar_gc hepar_bl hepar_tot1yr stat_bc stat_gc stat_bl stat_tot1yr fib_bc fib_gc fib_bl fib_tot1yr lla_bc lla_gc lla_bl lla_tot1yr thiaz_bc thiaz_gc thiaz_bl thiaz_tot1yr loop_bc loop_gc loop_bl loop_tot1yr kspar_bc kspar_gc kspar_bl kspar_tot1yr diurcom_bc diurcom_gc diurcom_bl diurcom_tot1yr thiaantih_bc thiaantih_gc thiaantih_bl thiaantih_tot1yr diurall_bc diurall_gc diurall_bl diurall_tot1yr ass_bc ass_gc ass_bl ass_tot1yr asscvd_bc asscvd_gc asscvd_bl asscvd_tot1yr allnsa_bc allnsa_gc allnsa_bl allnsa_tot1yr 
        para_bc para_gc para_bl para_tot1yr bago_bc bago_gc bago_bl bago_tot1yr abago_bc abago_gc abago_bl abago_tot1yr opio_bc opio_gc opio_bl opio_tot1yr acho_bc acho_gc acho_bl acho_tot1yr sterinh_bc sterinh_gc sterinh_bl sterinh_tot1yr lra_bc lra_gc lra_bl lra_tot1yr xant_bc xant_gc xant_bl xant_tot1yr ahist_bc ahist_gc ahist_bl ahist_tot1yr ahistc_bc ahistc_gc ahistc_bl ahistc_tot1yr h2_bc h2_gc h2_bl h2_tot1yr ppi_bc ppi_gc ppi_bl ppi_tot1yr IBD_bc IBD_gc IBD_bl IBD_tot1yr thyro_bc thyro_gc thyro_bl thyro_tot1yr sterint_bc sterint_gc sterint_bl 
        sterint_tot1yr stersys_bc stersys_gc stersys_bl stersys_tot1yr stertop_bc stertop_gc stertop_bl stertop_tot1yr gesta_bc gesta_gc gesta_bl gesta_tot1yr pill_bc pill_gc pill_bl pill_tot1yr HRTopp_bc HRTopp_gc HRTopp_bl HRTopp_tot1yr estr_bc estr_gc estr_bl estr_tot1yr adem_bc adem_gc adem_bl adem_tot1yr apsy_bc apsy_gc apsy_bl apsy_tot1yr benzo_bc benzo_gc benzo_bl benzo_tot1yr hypno_bc hypno_gc hypno_bl hypno_tot1yr ssri_bc ssri_gc ssri_bl ssri_tot1yr li_bc li_gc li_bl li_tot1yr mao_bc mao_gc mao_bl mao_tot1yr oadep_bc oadep_gc oadep_bl 
        oadep_tot1yr mnri_bc mnri_gc mnri_bl mnri_tot1yr adep_bc adep_gc adep_bl adep_tot1yr pheny_bc pheny_gc pheny_bl pheny_tot1yr barbi_bc barbi_gc barbi_bl barbi_tot1yr succi_bc succi_gc succi_bl succi_tot1yr valpro_bc valpro_gc valpro_bl valpro_tot1yr carba_bc carba_gc carba_bl carba_tot1yr oaconvu_bc oaconvu_gc oaconvu_bl oaconvu_tot1yr aconvu_bc aconvu_gc aconvu_bl 
        aconvu_tot1yr isupp_bc isupp_gc isupp_bl isupp_tot1yr TnfAI_bc TnfAI_gc TnfAI_bl TnfAI_tot1yr Budeo_bc Budeo_gc Budeo_bl Budeo_tot1yr OtherImm_bc OtherImm_gc OtherImm_bl OtherImm_tot1yr CycloSpor_bc CycloSpor_gc CycloSpor_bl CycloSpor_tot1yr Iso_oral_bc Iso_oral_gc Iso_oral_bl Iso_oral_tot1yr Iso_top_bc Iso_top_gc Iso_top_bl Iso_top_tot1yr Myco_bc Myco_gc Myco_bl Myco_tot1yr Etan_bc Etan_gc Etan_bl Etan_tot1yr Ipili_bc Ipili_gc Ipili_bl Ipili_tot1yr Ritux_bc Ritux_gc Ritux_bl Ritux_tot1yr EndOfLine  ;
       /* where entry=date of 2nd prescription */
    oneyear  =indexdate+365.25;
	twoyear=indexdate+730.5;
	threeyear=indexdate+1095.75;
	fouryear =indexdate+1460;
	oneyearout  =oneyear   + &latency; 
	twoyearout  =twoyear   + &latency;
	threeyearout=threeyear + &latency;
	fouryearout=fouryear + &latency;
	format oneyearout   date9.;
	format oneyear      date9.;
	format twoyear      date9.;
	format threeyear    date9.;
	format fouryear     date9.;
    
        /* Coding in more time variables  */
        *rxchange: for switching one class from another class;
            rxchange=min(DiscontDate, enddt,  switchAugmentDate);
            label rxchange='MIN of DisconDate, End of Continuous Enrollment, SwitchAugmentDate';
            format rxchange date9.;
        *end of drug in the drug class; 
            endofdrug=rxchange+&latency;
    
        /* The implementation of 'Initial Treatment' a la Abrahami */
        /* for the initiators of the comparator who switch from comparator to exposure: */
        *if the startdate is filldate2, the date of second prescription;
        %if %upcase(&intime) eq FILLDATE2 %then %do;
            if &exposure =0 and switchAugmentDate ne . then do;
                enddate= min(&ibd_def._dt, dpp4i_filldate2 +&induction);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne .    then event=1; else event=0;
                end;
            %end;
        *if the startdate is time0, ie the date of first presription;
        %if %upcase(&intime) ne FILLDATE2 %then %do;
            if &exposure =0 and switchAugmentDate ne . then do;
                enddate= min(&ibd_def._dt, switchAugmentDate+&induction);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne .    then event=1; else event=0;
                end;
        %end;
        /* for dpp4i initiators who were prevalent users of the comparator */
        else if &exposure =1 and excludeflag_prevalentuser eq 1 then do;
            enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
            if enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
            end;
        /* for initiators of dpp4i who never switched from the comparator */
        else if &exposure=1 and excludeflag_prevalentuser ne 1 then do;
            enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
            IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
        end;
        /* for initiators of comparator drug who never switched */
        else if &exposure=0 and switchAugmentDate eq . then do;
            enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
            IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
        end;
        
        *fromatting etc; 
        format enddate date9. ; label enddate ="Date min of (&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt), or switch/augment date for comparators";
        *"Date min of (&ibd_def._dt,death_dt, endstudy_dt, dbexit_dt, LastColl_Dt)";
        enddatedelete=min( &ibd_def._dt, enddt,endstudy_dt, &outtime);  
            
        *Removing individuals who did not reach the induction period for followup ;
        IF enddatedelete<=(&intime + &induction) then deleteobs=1; 
            else deleteobs=0;
    
        time=(enddate-(&intime.+&induction)+1)/365.25;
        time_drugdur=(min(rxchange, enddate)-(indexdate+1))/365.25;    
    
        if time>0 then logtime=(log(time/100000))  ;
        else time=.;
        label time = "person-years" time_drugdur= "duration of treatment";
        IBD_ever= max(crohns_ever, ucolitis_ever);  
    RUN;
/*=================*\
*!SECTION Update counts for exclusion
\*=================*/
PROC SQL noprint; 
    create table tmp_counts as select * from temp.Abexclusions_015_&exposure._&comparator.;
    select count(*) into : num_obs from tmp_counts;
    insert into tmp_counts
        set exclusion_num=&num_obs+1, 
        long_text="Number of observations after excluding individuals whose &ibd_def._dt or endstudy_dt <= &intime. + &induction.",
        dpp4i= (select count(*) from dsn where (&exposure=1 and deleteobs=0)),
        dpp4i_diff= -(select count(*) from dsn where (&exposure=1 and deleteobs=1)),
        &comparator.=(select count(*) from dsn where (&exposure ne 1 and deleteobs=0)) ,
        &comparator._diff= -(select count(*) from dsn where (&exposure ne 1 and deleteobs=1)),   
        full= (select count(*) from dsn where (deleteobs=0));
    *select * from tmp_counts;
QUIT;
data dsn; set dsn; if deleteobs=1 then delete; run;
proc sql noprint;
    select count(*) into : num_obs from tmp_counts;
    insert into tmp_counts
        set exclusion_num=&num_obs+1, 
        long_text="Number of individuals with positive, non-zero &type followup time (enddate-(&intime.+&induction)>0)",
        dpp4i= (select count(*) from dsn where (&exposure=1 and time ne .)),
        dpp4i_diff= -(select count(*) from dsn where (&exposure=1 and time eq .)),
        &comparator.=(select count(*) from dsn where (&exposure ne 1 and time ne .)) ,
        &comparator._diff= -(select count(*) from dsn where (&exposure ne 1 and time eq .)),   
        full= (select count(*) from dsn where (time ne .));
    select * from tmp_counts;
    %if %upcase(&save) eq Y %then %do;
        create table temp.Abexclusions_016_&exposure._&comparator._&type. as select * from tmp_counts;
        %end;
quit;
proc print data= tmp_counts; run; 
data dsn; set dsn; if time eq . then delete;run;

PROC SQL noprint;
    create table tmp as
    SELECT id
    FROM dsn
    GROUP BY id
    HAVING COUNT(*) > 1;
    SELECT count (distinct id) as n FROM tmp;
QUIT;
*selecting all of the individuals who contributed twice, first to unexposed person time, then contributed to exposed person time ;
PROC SQL noprint;
    create table tmp2 as
    select a.* from dsn as a 
    inner join tmp as b on a.id=b.id order by a.id, a.indexdate;
    select count(distinct id) as n from tmp2;
QUIT;
title "Individuals who contributed twice, first to unexposed person time, then contributed to exposed person time";
PROC FREQ DATA=tmp2;
TABLES excludeflag_prevalentuser /list missing;
RUN;
proc means data=dsn 
    STACKODS N NMISS MEAN STD MIN MAX Q1 MEDIAN Q3   ;
    where time ne .; 
    class &exposure excludeflag_prevalentuser;    
    var  time time_drugdur ; 
run;

PROC FREQ DATA=dsn; 
TABLES dpp4i*excludeflag_prevalentuser*event /list missing;
RUN;
title; 
/*===================================*\
//SECTION - Getting median futime, dutime, and counts
\*===================================*/
/* median time of followup */
ods output summary=mediantime;
proc means data = dsn STACKODS  N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3;
    where time ne .; 
    class &exposure;
    var time ;
run;

ods output summary=mediantimedu;
proc means data = dsn STACKODS  N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3;
    where time ne .; 
    class &exposure;
    var  time_drugdur;
run;

data mediantime(keep=&exposure NMISS Nobs mediantime sum );			
    set mediantime;
    mediantime = compress(put((median), 6.2)) || " (" || compress(put((q1), 6.2)) || "-" || compress(put((q3), 6.2)) || ")"; 
    format sum 8.0;
run; 
    
data mediantimedu(keep=&exposure mediantimedu );			
    set mediantimedu;
    mediantimedu = compress(put((median), 6.2)) || " (" || compress(put((q1), 6.2)) || "-" || compress(put((q3), 6.2)) || ")";  
    format sum 8.0;
run; 
/* combine median followup time and median drug duration  */
data mediantimetmp(rename=(sum=time_sum)); 
    merge mediantime mediantimedu; 
    by &exposure; 
run;

/* count numbers of event  */
ods output summary=event;
Proc means data=dsn sum stackods ;
    where time ne .; 
    class &exposure;
    var event;
run;
/* count numbers of switchers */
ods output summary=switchers;
Proc means data=dsn sum stackods ;
    where time ne .; 
    class &exposure;
    var excludeflag_prevalentuser;RUN;
data switchers (rename=(sum=n_switch)); 
    set switchers;RUN;
/* count numbers with a history of IBD */
ods output summary=IBD_hx;
Proc means data=dsn sum stackods ;
    where time ne .; 
    class &exposure;
    var IBD_ever ;RUN;
data IBD_hx (rename=(sum=IBD_hx_sum)); 
    set IBD_hx;RUN;
/* count number of switchers who had a subsequent diagnosis of IBD */
ods output summary=IBD_event_switchers;
Proc means data=dsn sum stackods ;
    where time ne . and excludeflag_prevalentuser eq 1; 
    class &exposure;
    var &ibd_def. ;RUN;
data IBD_event_switchers (rename=(sum=IBD_event_switchers)); 
    set IBD_event_switchers;RUN;
/* count events missed due to events being attributed to Dpp4i initiators who were prevalent users of the comparator  (events that would have been in the comparator's person time as it would be in our Main IT analysis if not for the censoring at 180+switch/augment/fill2date date )*/
ods output summary= IBD_events_censored;
Proc means data=dsn sum stackods ;
    where time ne . and  event eq 0; 
    class &exposure;
    var &ibd_def. ;RUN;
data IBD_events_censored (rename=(sum=IBD_events_censored)); 
    set IBD_events_censored;RUN;
/* above outputs will be stored in work lib and merged in //Section- Output Results */

    /*===================================*\
    //SECTION - Incident Rates Poisson
    \*===================================*/
    proc sort data=dsn; 
        by &exposure; 
    run;

    %LET event = event;
    %LET logtimevar = logtime;
    %LET timevar = time;
    proc genmod data=dsn;
        by &exposure;
        * class id;
        model &event= /dist=poisson offset=&logtimevar maxiter=100000;
        * repeated subject=id;
        estimate 'rate' int 1/exp;
        ods output estimates=rate;
        run;
        Data rate(keep=&exposure rate);
        set rate;
        if Label='Exp(rate)';
        rate=compress(put((LBetaEstimate),6.1))||" ("||compress(put((LBetaLowerCL),6.1))||"-"||compress(put((LBetaUpperCL),6.1))||")";
    run;

    /*===================================*\
    //SECTION - Calculating Hazard ratios   
    \*===================================*/

    *crude HR*;
    ods output ParameterEstimates = crudehr;
    Proc phreg data=dsn covsandwich(aggregate);
        id id;
        model &timevar*&event(0)=&exposure /ties=efron rl;
        title ' crude HR';
    run;
    Data crudehr(keep=&exposure chr clcl cucl crudehr);
        set crudehr;
        &exposure=1;
        chr=exp(Estimate);
        clcl=exp(Estimate-1.96*StdErr);
        cucl=exp(Estimate+1.96*StdErr);
        crudehr=compress(put((hazardratio),6.2))||" ("||compress(put((HRlowerCL),6.2))||"-"||compress(put((HRupperCL),6.2))||")";
    run;

    *adjusted HR-&weight*;
    %LET weight = smrw;
    ods output ParameterEstimates =&WEIGHT;
    proc phreg data=dsn covsandwich(aggregate);
        id id;
        weight &weight; 
        model  &timevar*&event(0)=&exposure  /ties=efron rl;
        title 'SMRW adjusted HR';
    run;
    Data &WEIGHT(keep=&exposure whr wlcl wucl &weight.HR);
        set &WEIGHT;
        &exposure=1;
        whr =exp(Estimate);
        wlcl=exp(Estimate-1.96*StdErr);
        wucl=exp(Estimate+1.96*StdErr);
        &weight.hr=compress(put((hazardratio),6.2))||" ("||compress(put((HRlowerCL),6.2))||"-"||compress(put((HRupperCL),6.2))||")";
    run;

    /*===================================*\
    //SECTION - output results 
    \*===================================*/
/* Merge and compile of counts, persontime, incidence rates, unweighted and SMR-weighted HRs */
    Data &outdata;
        length type $ 32 ;
        length analysis $ 32 ;   
        merge mediantimetmp   
        event  (rename=(sum=event_sum)) switchers (keep= &exposure n_switch) ibd_hx (keep= &exposure IBD_hx_sum) 
        ibd_event_switchers (keep= &exposure IBD_event_switchers)
        IBD_events_censored (keep= &exposure IBD_events_censored) 
        rate crudehr &weight;
        by &exposure;
        analysis="&ana_name. &type. &outdata.";
        type="&ibd_def.";
        latency=&latency;
        induction=&induction;
    run;
    Proc sort data=&outdata; 
        by descending &exposure; 
    run;
    Data tmpout1
        (keep=&exposure 
        Nobs n_switch type nmiss
        mediantime mediantimedu time_sum event_sum IBD_event_switchers IBD_events_censored IBD_hx_sum rate crudehr &weight.HR analysis induction latency exp unexp);
        set &outdata;
        exp="&exposure.";
        unexp="&comparator.";
        label event_Sum="No. of Event";
        label time_Sum = "Person-year";
    run;
    Data out_&exposure.v&comparator._&ana_name._&outdata.;
        retain TYPE &exposure Nobs n_switch  time_sum event_sum IBD_event_switchers IBD_events_censored IBD_hx_sum  rate crudehr &weight.HR analysis induction latency exp unexp; 
        set tmpout1;
            
        format event_sum best12.;
        format Nobs COMMA12. event_sum COMMA12. time_sum COMMA12. ;
    run;

    /*===================================*\
    //SECTION - KM plots 
    \*===================================*/
    /* region */
    /* weighted risks    */
    proc phreg data=dsn COVS ;
        MODEL &timevar*&event(0)= ; 
        strata &exposure;
        WEIGHT &weight;
        ID id ;
        baseline out=Pred survival=_all_ lower=lower upper=upper;
        run;
    proc sort data=pred; 
        by &exposure   &timevar;
        run;
    Data Pred;
        set Pred(keep=&exposure &timevar survival lower upper);
        risk=1-survival;
        risk_upper=1-lower;
        risk_lower=1-upper;
    run;

    data exp(keep=&timevar risk risk_lower risk_upper &exposure.) unexp(keep=&timevar risk risk_lower risk_upper &exposure.);
        set  pred;
        if &exposure=1 then output exp;
        if &exposure=0 then output unexp;
    run;
    Data plot;
    merge exp(rename=(risk=&exposure._risk risk_lower=&exposure._lower risk_upper=&exposure._upper)) unexp(rename=(risk=&comparator._risk risk_lower=&comparator._lower risk_upper=&comparator._upper));
        by &timevar;
    run;
/* Trigger ods excel to create a new sheet for the plots and main results */
ods excel options(sheet_interval="NOW");
    PROC SGPLOT DATA = plot NOAUTOLEGEND DESCRIPTION=""; 
    YAXIS LABEL = 'Risk of Inflammatory Bowel Disease' LABELATTRS=(size=13pt weight=bold)  VALUES = (0 TO 0.0045 BY 0.0005) valueattrs=(size=12pt); 
    XAXIS LABEL = 'Follow-up Time (years)' 		    LABELATTRS=(size=13pt weight=bold)  VALUES = (0 TO 4 BY 0.5) valueattrs=(size=12pt); 

    title height=12pt bold " ";
    step x=&timevar y=&exposure._risk/lineattrs=(color=blue pattern=1 thickness=2) name="&exposure.";
    step x=&timevar y=&exposure._lower/lineattrs=(color=blue pattern=20 thickness=1) name="&exposure._lower";
    step x=&timevar y=&exposure._upper/lineattrs=(color=blue pattern=20 thickness=1) name="&exposure._upper";

    step x=&timevar y=&comparator._risk/lineattrs=(color=red  pattern=1 thickness=2) name="&comparator.";
    step x=&timevar y=&comparator._lower/lineattrs=(color=red  pattern=20 thickness=1) name="&comparator._lower";
    step x=&timevar y=&comparator._upper/lineattrs=(color=red  pattern=20 thickness=1) name="&comparator._upper";
    keylegend "&exposure." "&comparator." /location=inside position=topleft valueattrs=(size=12pt weight=bold) NOBORDER;
    FOOTNOTE;
    RUN; 


    /*No. of risk at 0 year*/
    %let dataset=dsn;
    proc sql noprint; create table tmpp_b as select "&exposure."    as drug length=12 ,0 as fu_year,  count(id) as total_id, "No. at risk for &comparator initiator at 0 year" as label length=60 from &dataset where &exposure=0; quit;
    proc sql noprint; create table tmpp_a as select "&comparator." as drug length=12,0 as fu_year, count(id) as total_id, "No. at risk for &exposure initiator at 0 year" as label length=60 from &dataset where &exposure=1; quit;
    /*No. of risk at 0.5 year*/
    proc sql noprint; create table tmpp_c as select "&exposure." as drug length=12,0.5 as fu_year,  count(id) as total_id, "No. at risk for &exposure initiator at 0.5 year" as label length=60 from &dataset where &timevar >=0.5 and &exposure=1; quit;
    proc sql noprint; create table tmpp_d as select "&comparator." as drug length=12,0.5 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 0.5 year" as label length=60 from &dataset where &timevar >=0.5 and &exposure=0; quit;
    /*No. of risk at 1 year*/
    proc sql noprint; create table tmpp_e as select "&exposure." as drug length=12,1.0 as fu_year,  count(id) as total_id, "No. at risk for &exposure initiator at 1 year" as label length=60 from &dataset where &timevar >=1 and &exposure=1; quit;
    proc sql noprint; create table tmpp_f as select "&comparator." as drug length=12,1.0 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 1 year" as label length=60 from &dataset where &timevar >=1 and &exposure=0; quit;
    /*No. of risk at 1.5 year*/
    proc sql noprint; create table tmpp_g as select "&exposure." as drug length=12,1.5 as fu_year,  count(id) as total_id, "No. at risk for &exposure initiator at 1.5 year" as label length=60 from &dataset where &timevar >=1.5 and &exposure=1; quit;
    proc sql noprint; create table tmpp_h as select "&comparator." as drug length=12,1.5 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 1.5 year" as label length=60 from &dataset where &timevar >=1.5 and &exposure=0; quit;
    /*No. of risk at 2 year*/
    proc sql noprint; create table tmpp_i as select "&exposure." as drug length=12,2 as fu_year,  count(id) as total_id, "No. at risk for &exposure initiator at 2 year" as label length=60 from &dataset where &timevar >=2 and &exposure=1; quit;
    proc sql noprint; create table tmpp_j as select "&comparator." as drug length=12,2 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 2 year" as label length=60 from &dataset where &timevar >=2 and &exposure=0; quit;
    /*No. of risk at 2.5 year*/
    proc sql noprint; create table tmpp_k as select "&exposure." as drug length=12,2.5 as fu_year,  count(id) as total_id, "No. at risk for &exposure initiator at 2.5 year" as label length=60 from &dataset where &timevar >=2.5 and &exposure=1; quit;
    proc sql noprint; create table tmpp_l as select "&comparator." as drug length=12,2.5 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 2.5 year" as label length=60 from &dataset where &timevar >=2.5 and &exposure=0; quit;
    /*No. of risk at 3 year*/
    proc sql noprint; create table tmpp_m as select "&exposure." as drug length=12,3 as fu_year,  count(id) as total_id, "No. at risk for &exposure initiator at 3 year" as label length=60 from &dataset where &timevar >=3 and &exposure=1; quit;
    proc sql noprint; create table tmpp_n as select "&comparator." as drug length=12,3 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 3 year" as label length=60 from &dataset where &timevar >=3 and &exposure=0; quit;
    /* endregion //!SECTION */
    *gathering all results for print;
    DATA countout;
        SET tmpp_:;
        outcome_def="&ibd_def.";
    RUN;
    proc sort data= countout; by drug; run;
    proc transpose data=countout out=tmp prefix= fuyear; 
        by drug ; 
        id fu_year; run;
    proc print data= tmp  ;  
        variables drug fuyear:;
    run; 
    /* reprint of the unweighted and SMR-weighted results */
    proc print data= out_&exposure.v&comparator._&ana_name._&outdata. ; 
    run; 
%mend analysis_Ab;

/* endregion //!SECTION */

/*===================================*\
//SECTION - ## Multivariable Cox model by Abrahami standards 
* TODO - later
\*===================================*/
/* region */

/* endregion //!SECTION */
