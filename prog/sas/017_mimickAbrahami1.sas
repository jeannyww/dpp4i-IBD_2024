/***************************************
SAS file name: 017_mimickAbrahami.sas

Purpose: to recreate cohorts a la Abrahami et. al 2018 methods for DPP4i and IBD risk
Author: JHW
Creation Date: 2024-01-17

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
Date: 2024-01-17
Notes: see git @jeannywwy   
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=017_mimickAbrahami.sas, savelog=N, dataset=temp);

/*===================================*\
//SECTION - Get cohorts a la Abrahami, adapted from 012_createcohorts.sas
\*===================================*/
/* region */

%macro getCohortAbrahami (exposure, comparatorlist, washoutp, save); 
%do z=1 %to %sysfunc(countw(&comparatorlist.));
    %LET comparator = %scan(&comparatorlist.,&z.);
    %put &comparator.;

    /* Creating the comparator group a la Abrahami*/
    PROC SQL;
        create table tmp_exclude_&comparator. as
        select distinct a.*,
        max(a.indexdate-&washoutp. <= b.discontDate and b.indexdate<a.indexdate) as excludeflag_prevalentuser label='EXCLUSION FLAG: prevalent user of &comparator. drug',
        max(a.indexdate=b.indexdate) as excludeflag_samedayinitiator label = 'EXCLUSION FLAG: dual  initiator of &comparator. drug',
        max(a.indexdate<b.indexdate<= a.filldate2) as excludeflag_prefill2initiator label='EXCLUSION FLAG: pre-fill2 dual initiator of comparator drug before second fill date'
        from temp.&comparator._useperiods (where=(newuse=1 and useperiod=1) rename=(reason=reason1)) as a
        left join temp.&exposure._useperiods as b
        on a.id=b.id group by a.id, a.indexdate;
    QUIT;
    /* creating the 'new use' comparator group with switch date as the next date of dpp4i drug initiation if the individual switches from comparator to dpp4i, regardless of the discontinuation date of the first useperiod */
    PROC SQL;
        create table new_abrahami_&comparator. as select distinct a.*, min(b.indexdate) as switchAugmentdate format=date9. label='DATE OF SWITCH/AUGMENTATION' 
        from tmp_exclude_&comparator. as a 
        LEFT JOIN temp.&exposure._useperiods as b on a.id=b.id and a.indexdate<=b.indexdate /* deleting <=a.discontDate */
        group by a.id, a.indexdate
        order by a.id, a.indexdate;
    QUIT;
    /*  creating the exposure group a la Abrahami */
    PROC SQL;
        create table tmp_exclude_&exposure. as 
        select distinct a.*,
        max(a.indexdate-&washoutp. <= b.discontDate and b.indexdate<a.indexdate) as excludeflag_prevalentuser label='EXCLUSION FLAG: prevalent user of &exposure. drug',
        max(a.indexdate=b.indexdate) as excludeflag_samedayinitiator label = 'EXCLUSION FLAG: dual  initiator of &exposure. drug',
        max(a.indexdate<b.indexdate<= a.filldate2) as excludeflag_prefill2initiator label='EXCLUSION FLAG: pre-fill2 dual initiator of &exposure. drug before second fill date'
        from temp.&exposure._useperiods (where=(newuse=1 and useperiod=1) rename=(reason=reason1)) as a
        left join temp.&comparator._useperiods as b
        on a.id=b.id group by a.id, a.indexdate;
    QUIT;
    /* creating fake 'new use' time-varying exposure group with swtich date as the next date of comparator initiation if the individual switches from dpp4i to comparator, regardless of the discontinuation date of the first use period */
    PROC SQL;
        create table new_abrahami_&exposure. as 
        select distinct a.*, min(b.indexdate) as switchAugmentdate format=date9. label='DATE OF SWITCH/AUGMENTATION'
        from tmp_exclude_&exposure. as a
        LEFT JOIN temp.&comparator._useperiods as b on a.id=b.id and a.indexdate<=b.indexdate /* deleting <=a.discontDate */
        group by a.id, a.indexdate
        order by a.id, a.indexdate;
    QUIT;

    
    data Abrahami_&exposure._&comparator. (sortedby=id indexdate);
    retain id startdt enddt useperiod indexdate filldate2  switchAugmentdate discontDate newuse su dpp4i excludeflag_prevalentuser excludeflag_prefill2initiator  excludeflag_samedayinitiator reason1;
    set new_abrahami_&exposure.  (in=a)  new_abrahami_&comparator.  (in=b);
    by id indexdate;
    &exposure.=a; 
    label &exposure. = "Abrahami-defined drug class: 1= &exposure. 0= &comparator.";
    RUN;

    /* If save eq Y then save to temp folder for retrieval later */
    %if &save.=Y %then %do; 
    data temp.Abrahami_&exposure._&comparator.;set Abrahami_&exposure._&comparator.;RUN;
    %end;
%end;
%mend getCohortAbrahami;

/* execute the macro */
%LET exposure = dpp4i;
%LET comparatorlist = su tzd sglt2i;
%getCohortAbrahami (exposure=&exposure.,comparatorlist= &comparatorlist.,washoutp= 365, save= Y);

/* endregion //!SECTION */

/*===================================*\
//SECTION - Merge cohorts a la Abrahami, adapted from 013_merge.sas
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
%macro mergeall(exposure, comparatorlist, primaryGraceP, washoutp, save=N);
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
    run;
    /* If save=y then save to temp library for retreival later  */
    %if &save=Y %then %do; 
    data temp.Abrahami_allmerged_&exposure._&comparator.;
    set tmp1;RUN;

    %end;
%end;
%mend mergeall;


%LET comparatorlist = su tzd sglt2i;
%mergeall(exposure=dpp4i, comparatorlist=&comparatorlist., primaryGraceP=90, washoutp=365, save=Y);

/* endregion //!SECTION */

/*===================================*\
//SECTION - creating analysis dataset a la Abrahami, adapted from 014_createanalysis.sas
\*===================================*/
/* region */

/* retrive from temp library and make exclusions */

%macro createana(exposure=, comparatorlist=, save=N);
    %do i = 1 %to %sysfunc(countw(&comparatorlist));
    %LET comparator = %scan(&comparatorlist, &i);
        /* Bring in counts and merged dataset */
        data tmp1; set temp.Abrahami_allmerged_&exposure._&comparator.;RUN;
data tmpana_&exposure._&comparator.;
    set tmp1;
    if (/* excludeflag_prevalentuser eq 1 or */ excludeflag_samedayinitiator eq 1 or excludeflag_prefill2initiator eq 1 or filldate2 eq . ) then delete; 
    if ((crohns_bl not in (., 0) or ucolitis_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) )) then delete;
    if ((AminoS_bl not in (., 0) or budeo_bl not in (., 0) or tnfai_bl not in (., 0) or otherimm_bl not in (., 0) )) or (colile_bl not in (., 0) ) then delete;
    /* exclude prior to 2012 for sglt2i */
    %if &comparator eq sglt2i %then %do; 
    if year(indexdate) lt 2012 then delete; 
    %end;
    /* exclude heart failure for tzd */
    %if &comparator eq tzd  %then %do;
    if chf_bl not in (., 0) then delete;
    %end;  
RUN;
/* if save==y then save to analysis folder */
    %if &save=Y %then %do;
    data a.Abrahami_allmerged_&exposure._&comparator.;
        set  tmpana_&exposure._&comparator.;
        RUN;
    %end;

%end;
%mend createana;

/* *SECTION run the macro */
/* %LET exposure = dpp4i;
%LET comparator = sglt2i;
%createana(exposure=&exposure, comparatorlist=&comparatorlist, save=N); */
%LET exposure = dpp4i;
%LET comparatorlist = su tzd sglt2i;
%createana(exposure=&exposure, comparatorlist=&comparatorlist, save=Y);


/* endregion //!SECTION */


/*===================================*\
//SECTION - PS weighting adapted from 015_PSweighting.sas
\*===================================*/
/* region */

%macro psweighting ( exposure , comparator , weight , addedmodelvars ,basemodelvars , tablerowvars, refyear  , dat, save );

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

    %mend psweighting;

/* endregion //!SECTION */
/* endregion //!SECTION */

/*===================================*\
//SECTION - Execute Macro 
PS weighting with Abrahami covariates:
- Adjusted for age, sex, year of cohort entry, body mass index, alcohol related disorders (including alcoholism, alcoholic cirrhosis of liver, alcoholic hepatitis,
- and hepatic failure), smoking status, haemoglobin A1c (last lab result b4 cohort entry), 
- at any time before cohort entry: microvascular (nephropathy, neuropathy, retinopathy) and macrovascular (myocardial infarction,stroke, peripheral arteriopathy) complications of diabetes, 
- duration of treated diabetes,
- antidiabetic drugs used before cohort entry, 
- use of aspirin, nonsteroidal
- anti-inflammatory drugs, hormonal replacement therapy, oral contraceptives, other autoimmune conditions, 
- total number of unique non-diabetic drugs in year before cohort entry.
\*===================================*/
/* region */

*  %LET tablerowvarsi =   age  sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  
*  nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever /* duration_metformin */  dpp4i_ever SU_ever TZD_ever sglt2i_ever insulin_ever /* other oad  */   bigua_ever  prand_ever agluco_ever OAntGLP_ever    /* other */ ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever /* Autoimmune */psorp_ever vasc_ever RhArth_Ever SjSy_Ever sLup_ever /* other drugs */num_nondmdrugs1yr num_nondmdrugs1yr_cat;

*  %LET interactions =     /* Interaction */ ;
*  %LET basevars =  age|age  sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever bigua_ever  agluco_ever ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever psorp_ever vasc_ever RhArth_Ever SjSy_Ever sLup_ever num_nondmdrugs1yr ;
*  %LET addedDPP4ivSU = oAntGLP_1yrlookback sglt2i_1yrlookback TZD_1yrlookback;
*  %let addedmodelvars= &addedDPP4ivSU;
*  %let basemodelvars= &basevars. &interactions. ;
*  %let tablerowvars= &tablerowvarsi;

%LET tablerowvarsi =   age  sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever /* duration_metformin */ bigua_ever SU_ever TZD_ever insulin_ever /* other oad  */ dpp4i_ever sglt2i_ever prand_ever agluco_ever OAntGLP_ever    /* other */ ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever /* Autoimmune */psorp_ever vasc_ever RhArth_Ever SjSy_Ever sLup_ever /* other drugs */num_nondmdrugs1yr num_nondmdrugs1yr_cat;


%LET interactions =     /* add interaction */ ;
%LET basevars =  age|age  sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever bigua_ever insulin_ever prand_ever agluco_ever OAntGLP_ever ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever psorp_ever vasc_ever RhArth_Ever SjSy_Ever sLup_ever num_nondmdrugs1yr ;
%let basemodelvars= &basevars. &interactions. ;
%let tablerowvars= &tablerowvarsi;


*  %let addedmodelvars= &addedDPP4ivSU;
*  %LET exposure = dpp4i;
*  %LET comparator = su;
*  %LET refyear = 2015;

%LET addedDPP4ivSU = oAntGLP_1yrlookback sglt2i_1yrlookback TZD_1yrlookback;
%psweighting ( exposure= dpp4i ,
comparator= SU, 
weight= smrw, 
addedmodelvars= &addedDPP4ivSU, 
basemodelvars= &basevars. &interactions. ,
tablerowvars= &tablerowvarsi,
refyear = 2015, 
save= Y);

%LET addedDPP4ivTZD = oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback chf_ever;
%psweighting(exposure=dpp4i,
comparator=TZD, 
weight=smrw,
addedmodelvars= &addedDPP4ivTZD,
basemodelvars= &basevars. &interactions,
tablerowvars=&tablerowvarsi chf_ever,
refyear=2015,
save=Y
);

%LET addedDPP4ivSGLT2i = oAntGLP_1yrlookback su_1yrlookback TZD_1yrlookback;
%psweighting(exposure=dpp4i,
comparator=SGLT2i, 
weight=smrw,
addedmodelvars=&addedDPP4ivSGLT2i,
basemodelvars= &basevars. &interactions,
tablerowvars=&tablerowvarsi,
refyear=2015,
save=Y
);


%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);

ods _all_ close;
goptions reset=all;quit;
*Printing outputs for each ACNU cohort;
ods excel file="&toutpath./Abrahami_T1_compiled_&todaysdate..xlsx"
    options (
        Sheet_interval="NONE"
        embedded_titles="NO"
        embedded_footnotes="NO"
    );
    *dpp4i vs su;
ods excel options(sheet_name="DPP4i_SU"  sheet_interval="NOW");
    proc print data=table1_dpp4ivSU noobs label; var row dpp4i su sdiff su_wgt sdiff_wgt; run;
ods excel options(sheet_name="DPP4i_SU_plots" sheet_interval="NOW");
    goptions iback="&foutpath./Abrahami_psplot_dpp4i_SU&todaysdate..png" imagestyle=fit;
    proc gslide;RUN;quit; goptions reset=all;
    goptions iback="&foutpath./Abrahami_psplot_trim_dpp4i_SU&todaysdate..png" imagestyle=fit;
    proc gslide;RUN; quit  ; goptions reset=all;
    ods text="PS model:  &addedDPP4ivSU.  &basevars. &interactions. ";
/* ods excel options(sheet_name="DPP4i_SU_flowchart" sheet_interval="NOW");
    proc print data=temp.exclusions_015_dpp4i_su noobs ; run;
 */
    *dpp4i vs TZD;
ods excel options(sheet_name="DPP4i_TZD" sheet_interval="NOW");
    proc print data=table1_dpp4ivTZD noobs label; var row dpp4i tzd sdiff tzd_wgt sdiff_wgt; run;
ods excel options(sheet_name="DPP4i_TZD_plots" sheet_interval="NOW");
    goptions iback="&foutpath./Abrahami_psplot_dpp4i_TZD&todaysdate..png" imagestyle=fit;
    proc gslide;RUN;quit; goptions reset=all;
    goptions iback="&foutpath./Abrahami_psplot_trim_dpp4i_TZD&todaysdate..png" imagestyle=fit;
    proc gslide;RUN; quit; goptions reset=all;
    ods text="PS model:  &addedDPP4ivTZD.  &basevars. &interactions. ";
/* ods excel options(sheet_name="DPP4i_TZD_flowchart" sheet_interval="NOW");
    proc print data=temp.exclusions_015_dpp4i_tzd noobs ; run;
 */
    *dpp4i vs SGLT2i;
ods excel options(sheet_name="DPP4i_SGLT2i" sheet_interval="NOW");
    proc print data=table1_dpp4ivSGLT2i noobs label; var row dpp4i sglt2i sdiff sglt2i_wgt sdiff_wgt; run;
ods excel options(sheet_name="DPP4i_SGLT2i_plots" sheet_interval="NOW");
    goptions iback="&foutpath./Abrahami_psplot_dpp4i_SGLT2i&todaysdate..png" imagestyle=fit;
    proc gslide;RUN;quit;    goptions reset=all;
    goptions iback="&foutpath./Abrahami_psplot_trim_dpp4i_SGLT2i&todaysdate..png" imagestyle=fit;
    proc gslide;RUN; quit;    goptions reset=all;
    ods text="PS model:  &addedDPP4ivSGLT2i.  &basevars. &interactions. ";
/* ods excel options(sheet_name="DPP4i_SGLT2i_flowchart" sheet_interval="NOW");
    proc print data=temp.exclusions_015_dpp4i_sglt2i noobs ; run;
 */
    *log summary;
ods excel options(sheet_name="Log_issues" sheet_interval="NOW");
    proc print data=temp.Log_issues noobs ; run;
ods excel close;

ods _all_ close;
/* '; * "; */; quit; run;


