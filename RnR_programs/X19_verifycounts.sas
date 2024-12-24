/***************************************
SAS file name: verifycounts

Purpose: To verify counts for IBD events between ACNU and TVE design    
Author: JHW
Creation Date: 2024-06-25

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
Date: 2024-06-25
Notes: init
Date: 2024-06-27
Notes: Added code to compare and print events between ACNU and TVE for DPP4i initiators with SU focusing on switchers, line 454 onwards
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=verifycounts, savelog=N, dataset=dataname);


/*===================================*\
//SECTION - MACRO: ACNU event counts
%LET exposure = dpp4i;
%LET comparator = su;
%LET ibd_def = ibd1;
%LET ana_name = ACNU;
%LET type = AT;
%LET induction = 180;
%LET latency = 180; 
%LET intime = filldate2;
%LET outtime = '31Dec2022'd;
\*===================================*/
/* region */


%macro count_events_ACNU ( exposure , comparator , ana_name , type ,  induction , latency , ibd_def , intime , outtime) / minoperator mindelimiter=',';
title "Counting events for &ana_name. Exposure: &exposure, Comparator: &comparator, Type: &type";
/*=================*\
Create flag for who was trimmed
\*=================*/
    data tmp1;
        set a.allmerged_&exposure._&comparator._1yrlb;
    RUN;
    data tmp2; 
        set a.PS_&exposure._&comparator._1yrlb;
    RUN;
    proc sql; 
        create table psdsnnotrim as
        select distinct a.*, b.PS
        from tmp1 as a
        left join tmp2 as b
        on a.id=b.id and a.filldate2=b.filldate2;
    quit;
    data psdsnnotrim; set psdsnnotrim; 
        if PS eq . then trimming_flag=1;
        else trimming_flag=0;
        RUN;
/*=================*\
Create events and followup time
\*=================*/
data dsn_ACNU; set psdsnnotrim;
   /* where indexdate=date of first Rx, filldate2=date of 2nd rx, and for the main analysis the entry=date of 2nd prescription */
    oneyear  =&intime +365.25;
	twoyear=&intime +730.5;
	threeyear=&intime +1095.75;
	fouryear =&intime +1460;
   * oneyear  =indexdate+365.25;
	*twoyear=indexdate+730.5;
	*threeyear=indexdate+1095.75;
	*fouryear =indexdate+1460;
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

    /* Initial Treatment */
    %if %upcase(&type) eq IT %then %do;
        enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
        format enddate date9. ; label enddate ="Date min of (&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt)";
        *"Date min of (&ibd_def._dt,death_dt, endstudy_dt, dbexit_dt, LastColl_Dt)";
        %end;

    /* As Treated */ 
    %if %upcase(&type) eq AT %then %do;  
        enddate=min(endofdrug , &ibd_def._dt,&outtime,death_dt, endstudy_dt, dbexit_dt, enddt, LastColl_Dt ); /* AT exit date and AT exit_reason   */
        format enddate date9.; LABEL enddate="Date min of (&ibd_def._dt, drug discontinuation, death_dt, endstudy_dt, dbexit_dt, enddt (end enroll), LastColl_Dt)";
        %end; 

    /* As Treated and censoring for badrx (sensitivity analysis 6 "6)	We will additionally censor patients when they receive medications that could potentially induce IBD progression [19] (Appendix 10). ") 
    we allow events to occur 180 days after stopping medication */
    %if %upcase(&type) eq ATB %then %do;
        enddate= min(endofdrug, &ibd_def._dt, &outtime, discontDate, death_dt, endstudy_dt, dbexit_dt, enddt, LastColl_Dt, (badrx_dt+ &latency) );
        format enddate date9.; label enddate="Date min of (&ibd_def._dt, drug discontinuation, death_dt, endstudy_dt, dbexit_dt, enddt (end enroll), LastColl_Dt, badrx_dt)";
        %end;
 

    /* Either  */
    %if %upcase(&type) # AT, IT %then %do;
        *"Date min of (death_dt, endstudy_dt, dbexit_dt, LastColl_Dt)";
        enddatedelete=min(  enddt, endstudy_dt, &outtime);  
        
        *flag to remove individuals who did not reach the induction period for followup ;
        IF indexdate<= enddatedelete<=(&intime + &induction) then deleteobs=1; 
            else deleteobs=0;
        label deleteobs="Flag to remove individuals who did not reach the induction period for followup";
        IF indexdate <= &ibd_def._dt <=(&intime + &induction) then IBDdx_inductionperiod=1;
            else IBDdx_inductionperiod=0;
        label IBDdx_inductionperiod="Flag for individuals with IBD diagnosis within the induction period";
        %end;
/* NOTE         */
    *Creating event variable and followup time variable; 
    IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;

    time=(enddate-(&intime.+&induction)+1)/365.25;
    time_drugdur=(min(rxchange, enddate)-(indexdate+1))/365.25;

    if time>0 then logtime=(log(time/100000))  ;
    else time=.;
    label time = "person-years" time_drugdur= "duration of treatment";        
    label logtime="log(person-years)";

    *flag for individuals with IBD diagnosis ever (IBD before time 0) or IBD post-index date without regard to the induction period; 
    IBD_ever= max(crohns_ever, ucolitis_ever);  
    label IBD_ever="Ever IBD diagnosis";
    if indexdate<= &ibd_def._dt then IBD_postindex=1; else IBD_postindex=0;
RUN;


/* Potential area for number discrepancy */
/* Trimming */
PROC FREQ DATA=dsn_ACNU;
TABLES dpp4i*trimming_flag*event /list missing;
RUN;
/* exclusion of who did not reach the induction period for followup */
PROC FREQ DATA=dsn_ACNU; 
TABLES dpp4i*trimming_flag*excludeflag_prevalentuser*deleteobs*event /list missing;
RUN;
/* individuals had IBD diagnosis within the induction period */
PROC FREQ DATA=dsn_ACNU; 
TABLES dpp4i*trimming_flag*excludeflag_prevalentuser*IBDdx_inductionperiod*event /list missing;
RUN;
/* IBD defintion */
PROC FREQ DATA=dsn_ACNU; 
TABLES dpp4i*trimming_flag*excludeflag_prevalentuser*IBDdx_inductionperiod*&ibd_def /list missing;
RUN;
PROC FREQ DATA=dsn_ACNU; 
TABLES dpp4i*trimming_flag*excludeflag_prevalentuser*IBDdx_inductionperiod*&ibd_def*event /list missing;
RUN;
RUN;
PROC FREQ DATA=dsn_ACNU; 
TABLES dpp4i*trimming_flag*excludeflag_prevalentuser*IBDdx_inductionperiod*&ibd_def*event*IBD_EVER /list missing;
RUN;
/* individuals with missing fu time ? */
PROC FREQ DATA=dsn_ACNU; 
WHERE time eq .; 
TABLES dpp4i*trimming_flag*excludeflag_prevalentuser*event /list missing;
RUN;
/* number events when all exclusions are applied */
PROC FREQ DATA=dsn_ACNU; 
WHERE deleteobs=0 and IBDdx_inductionperiod=0 and time ne .;
TABLES dpp4i*trimming_flag*excludeflag_prevalentuser*&ibd_def*event /list missing;
RUN;

PROC FREQ DATA=dsn_ACNU; 
TABLES dpp4i*excludeflag_prevalentuser*&ibd_def*event /list missing;
RUN;
title; 

/* count numbers of event  */
ods output summary=event;
Proc means data=dsn_ACNU sum stackods ;
    where time ne .; 
    class &exposure trimming_flag;
    var event;
run;
/* Count ibd_def. diagnosis that were not considered events */
Proc means data=dsn_ACNU sum stackods ;
    where time ne .; 
    class &exposure trimming_flag;
    var &ibd_def. ;
run;
Proc means data=dsn_ACNU sum stackods ;
    where time ne . and  event eq 0; 
    class &exposure trimming_flag;
    var &ibd_def. ;RUN;

%mend count_events_ACNU;

/* '; * "; */; quit; run;

/* endregion //!SECTION */

/*===================================*\
//SECTION - MACRO: TVE event counts 
%LET exposure = dpp4i;
%LET comparator = su;
%LET ibd_def = ibd1;
%LET ana_name = TVE;
%LET type = AT;
%LET induction = 180;
%LET latency = 180; 
%LET intime = filldate2;
%LET outtime = '31Dec2022'd;

\*===================================*/
/* region */

%macro count_events_TVE (exposure , comparator ,  ana_name , type,  induction , latency,ibd_def,  intime,outtime) / minoperator mindelimiter=',';
title "Counting events for &ana_name. Exposure: &exposure, Comparator: &comparator, Type: &type";
/*=================*\
Create flag for who was trimmed
\*=================*/
    data tmp1;
        set a.Abrahami_allmerged_&exposure._&comparator;
    RUN;
    data tmp2; 
        set a.Abrahami_PS_&exposure._&comparator.;
    RUN;
    proc sql;
        create table psdsnnotrim as
        select distinct a.*, b.PS
        from tmp1 as a
        left join tmp2 as b
        on a.id=b.id and a.filldate2=b.filldate2;
    quit;
    data psdsnnotrim; set psdsnnotrim; 
        if PS eq . then trimming_flag=1;
        else trimming_flag=0;
        RUN;
data dsn_TVE; set psdsnnotrim; 
    /* where entry=date of 2nd prescription */
    oneyear  =&intime +365.25;
	twoyear=&intime +730.5;
	threeyear=&intime +1095.75;
	fouryear =&intime +1460;
   * oneyear  =indexdate+365.25;
	*twoyear=indexdate+730.5;
	*threeyear=indexdate+1095.75;
	*fouryear =indexdate+1460;
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

        /* 01 May 2024: checked that current code correctly  incorporates how &outtime is not used among those who were on the comparator (non-dpp4i) who then subsequently switched to dpp4i*/
    
        /* The implementation of 'Initial Treatment' a la Abrahami */
        /* for the initiators of the comparator who switch from comparator to exposure: */
        *if the startdate is filldate2, the date of second prescription;
        %if %upcase(&intime) eq FILLDATE2 %then %do;
            if &exposure =0 and switchAugmentDate ne . then do;
                enddate= min(&ibd_def._dt, dpp4i_filldate2 +&induction);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne .    then event=1; else event=0;
                end;
            %end;
        *if the startdate is time0, ie the date of first prescription;
        %if %upcase(&intime) ne FILLDATE2 %then %do;
            if &exposure =0 and switchAugmentDate ne . then do;
                enddate= min(&ibd_def._dt, switchAugmentDate+&induction);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne .    then event=1; else event=0;
                end;
        %end;

        /* IT analysis  */
        %if %upcase(&type) eq IT %then %do;

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
        %end;
        /* AT analysis */
        %else %if %upcase(&type) eq AT %then %do;
            /* for dpp4i initiators who were prevalent users of the comparator */
            else if &exposure =1 and excludeflag_prevalentuser eq 1 then do;
                enddate= min(endofdrug, &ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
                if enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
                end;
            /* for initiators of dpp4i who never switched from the comparator */
            else if &exposure=1 and excludeflag_prevalentuser ne 1 then do;
                enddate= min(endofdrug, &ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
            end;
            /* for initiators of comparator drug who never switched */
            else if &exposure=0 and switchAugmentDate eq . then do;
                enddate= min(endofdrug, &ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
            end;
        %end; 
        
        *formatting etc; 
        format enddate date9. ; label enddate ="Date min of (&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt), or switch/augment date for comparators";
        *"Date min of (death_dt, endstudy_dt, dbexit_dt, LastColl_Dt)";
        enddatedelete=min(  enddt, endstudy_dt, &outtime);  
        
        *flag to remove individuals who did not reach the induction period for followup ;
        IF indexdate<= enddatedelete<=(&intime + &induction) then deleteobs=1; 
            else deleteobs=0;
        label deleteobs="Flag to remove individuals who did not reach the induction period for followup";
        IF indexdate <= &ibd_def._dt <=(&intime + &induction) then IBDdx_inductionperiod=1;
            else IBDdx_inductionperiod=0;
        label IBDdx_inductionperiod="Flag for individuals with IBD diagnosis within the induction period";
        * followup time;
        time=(enddate-(&intime.+&induction)+1)/365.25;
        time_drugdur=(min(rxchange, enddate)-(indexdate+1))/365.25;    
    
        if time>0 then logtime=(log(time/100000))  ;
        else time=.;
        label time = "person-years" time_drugdur= "duration of treatment";
        label logtime="log(person-years)";
        *flag for individuals with IBD diagnosis ever (IBD before time 0) or IBD post-index date without regard to the induction period; 
        if indexdate<= &ibd_def._dt then IBD_postindex=1; else IBD_postindex=0;
    RUN;


/* Potential area for number discrepancy */
/* Trimming */
PROC FREQ DATA=dsn_TVE;
TABLES dpp4i*trimming_flag*event /list missing;
RUN;
/* exclusion of who did not reach the induction period for followup */
PROC FREQ DATA=dsn_TVE; 
TABLES dpp4i*trimming_flag*excludeflag_prevalentuser*deleteobs*event /list missing;
RUN;
/* individuals had IBD diagnosis within the induction period */
PROC FREQ DATA=dsn_TVE; 
TABLES dpp4i*trimming_flag*excludeflag_prevalentuser*IBDdx_inductionperiod*event /list missing;
RUN;
/* IBD defintion */
PROC FREQ DATA=dsn_TVE; 
TABLES dpp4i*trimming_flag*excludeflag_prevalentuser*IBDdx_inductionperiod*&ibd_def*IBD_EVER /list missing;
RUN;
PROC FREQ DATA=dsn_TVE; 
TABLES dpp4i*trimming_flag*excludeflag_prevalentuser*IBDdx_inductionperiod*&ibd_def*event*IBD_EVER /list missing;
RUN;
/* individuals with missing fu time ? */
PROC FREQ DATA=dsn_TVE; 
WHERE time eq .; 
TABLES dpp4i*trimming_flag*excludeflag_prevalentuser*event /list missing;
RUN;
/* number events when all exclusions are applied */
PROC FREQ DATA=dsn_TVE; 
WHERE deleteobs=0 and IBDdx_inductionperiod=0 and time ne .;
TABLES dpp4i*trimming_flag*excludeflag_prevalentuser*&ibd_def*event*IBD_EVER /list missing;
RUN;

proc means data=dsn_TVE 
    STACKODS N NMISS MEAN STD MIN MAX Q1 MEDIAN Q3   ;
    where time ne .; 
    class &exposure excludeflag_prevalentuser;    
    var  time time_drugdur ; 
run;

PROC FREQ DATA=dsn_TVE; 
TABLES dpp4i*excludeflag_prevalentuser*event /list missing;
RUN;
title; 

/* count numbers of event  */
ods output summary=event;
Proc means data=dsn_TVE sum stackods ;
    where time ne .; 
    class &exposure;
    var event;
run;
/* count numbers of switchers */
ods output summary=switchers;
Proc means data=dsn_TVE sum stackods ;
    where time ne .; 
    class &exposure;
    var excludeflag_prevalentuser;RUN;
data switchers (rename=(sum=n_switch)); 
    set switchers;RUN;
/* count numbers with a history of IBD */
ods output summary=IBD_hx;
Proc means data=dsn_TVE sum stackods ;
    where time ne .; 
    class &exposure;
    var IBD_ever ;RUN;
data IBD_hx (rename=(sum=IBD_hx_sum)); 
    set IBD_hx;RUN;
/* count number of switchers who had a subsequent diagnosis of IBD */
ods output summary=IBD_event_switchers;
Proc means data=dsn_TVE sum stackods ;
    where time ne . and excludeflag_prevalentuser eq 1; 
    class &exposure;
    var &ibd_def. ;RUN;
data IBD_event_switchers (rename=(sum=IBD_event_switchers)); 
    set IBD_event_switchers;RUN;
/* count events missed due to events being attributed to Dpp4i initiators who were prevalent users of the comparator  (events that would have been in the comparator's person time as it would be in our Main IT analysis if not for the censoring at 180+switch/augment/fill2date date )*/
ods output summary= IBD_events_censored;
Proc means data=dsn_TVE sum stackods ;
    where time ne . and  event eq 0; 
    class &exposure;
    var &ibd_def. ;RUN;

Proc means data=dsn_TVE sum stackods ;
    where time ne . ; 
    class &exposure;
    var &ibd_def. IBD_ever event;RUN;
Proc means data=dsn_TVE sum stackods ;
    where time ne . and  event eq 0; 
    class &exposure;
    var &ibd_def. IBD_ever event;RUN;
/* data IBD_events_censored (rename=(sum=IBD_events_censored)); set IBD_events_censored;RUN; */

%mend count_events_TVE;
/* endregion //!SECTION */

/*===================================*\
//SECTION - EXECUTE: Manually compare TVE AND ACNU first for DPP4i SU
\*===================================*/
/* region */

/* Creating datasets to compare TVE and ACNU */
%count_events_ACNU ( 
exposure = dpp4i,
comparator = su,
ana_name = ACNU,
type = IT,
induction = 180,
latency = 180,
ibd_def = ibd1,
intime = filldate2,
outtime = '31Dec2022'd
);

%count_events_TVE ( 
exposure = dpp4i,
comparator = su,
ana_name = TVE,
type = IT,
induction = 180,
latency = 180;,
ibd_def = ibd1,
intime = filldate2,
outtime = '31Dec2022'd);

%let ibd_def=ibd1;
/*successfully got row number=53*/
data dsn_TVE_dpp_ibdswitchers;
	set dsn_TVE;
if  deleteobs=0 and IBDdx_inductionperiod=0 and time ne .;
if dpp4i=1 and trimming_flag=0 and excludeflag_prevalentuser=1 and ibd1=1 and event=1 and ibd_ever=0;
run; 
proc print data=dsn_TVE_dpp_ibdswitchers;run;
proc sql; select count(distinct ID) as unique_IDs from dsn_TVE_dpp_ibdswitchers; quit;*53;
proc freq data=dsn_TVE_dpp_ibdswitchers; tables switcher/missing; run;

/*successfully got row number=49*/
data dsn_TVE_su_ibdcensored;
	set dsn_TVE;
if  deleteobs=0 and IBDdx_inductionperiod=0 and time ne .;
if dpp4i=0 and trimming_flag=0 and excludeflag_prevalentuser=0 and ibd1=1 and event=0 and ibd_ever=0;
run; 
proc print data=dsn_TVE_su_ibdcensored;run;
proc sql; select count(distinct ID) as unique_IDs from dsn_TVE_su_ibdcensored; quit;*49;
proc freq data=dsn_TVE_su_ibdcensored; tables switcher/missing; run;
proc freq data=dsn_TVE_dpp_ibdswitchers; tables switcher/missing; run;


/*method 2: merge*/
proc sort data= dsn_TVE_su_ibdcensored;by id;run;
proc sort data= dsn_TVE_dpp_ibdswitchers; by id; run;
data IBD_dppswitcher_not_in_sucensor;/*n=13*/
	merge dsn_TVE_su_ibdcensored (in=inA) dsn_TVE_dpp_ibdswitchers (in=inB);
	by id;
	if inB and not inA;
	format endofdrug date9.;
run;
data IBD_sucensore_not_in_dppswitcher;/*n=9*/
	merge dsn_TVE_su_ibdcensored (in=inA) dsn_TVE_dpp_ibdswitchers (in=inB);
	by id;
	if inA and not inB;
	format endofdrug date9.;
run;
data IBD_sucensore_and_dppswitcher_d;/*n=40in DPP4i person time*/
	merge dsn_TVE_su_ibdcensored (in=inA) dsn_TVE_dpp_ibdswitchers (in=inB);
	by id;
	if inA and inB;
	format endofdrug date9.;
run;
data IBD_sucensore_and_dppswitcher_s;/*n=40 in SU person time*/
	merge dsn_TVE_dpp_ibdswitchers(in=inA) dsn_TVE_su_ibdcensored (in=inB);
	by id;
	if inA and inB;
	format endofdrug date9.;
run;
title "switcher type for those in 53 IBD switchers but not in 49 IBD censored";
proc freq data=IBD_dppswitcher_not_in_sucensor; tables switcher/missing;run;
title;
title "those in 53 IBD switchers but not in 49 IBD censored";
proc print data=IBD_dppswitcher_not_in_sucensor;
var id useperiod indexdate filldate2 switchaugmentdate excludeflag_prevalentuser dpp4i_filldate2 discontdate newuse su dpp4i switcher num_rows
event ibd1_dt enddate death_dt dbexit_dt  LastColl_Dt endofdrug;
run;
title;

title "switcher type for those in 49 IBD censored but not in 53 IBD switchers";
proc freq data=IBD_sucensore_not_in_dppswitcher; tables switcher/missing;run;
title;
title "those in 49 IBD censored but not in 53 IBD switchers";
proc print data=IBD_sucensore_not_in_dppswitcher;
var id useperiod indexdate filldate2 switchaugmentdate excludeflag_prevalentuser dpp4i_filldate2 discontdate newuse su dpp4i switcher num_rows
event ibd1_dt enddate death_dt dbexit_dt  LastColl_Dt endofdrug;
run;
title;

title "switcher type for those in 49 IBD censored and 53 IBD switchers";
proc freq data=IBD_sucensore_and_dppswitcher; tables switcher/missing;run;
title;
title "those in 49 IBD censored and 53 IBD switchers in DPP4i person-time";
proc print data=IBD_sucensore_and_dppswitcher_d;
var id useperiod indexdate filldate2 switchaugmentdate excludeflag_prevalentuser dpp4i_filldate2 discontdate newuse su dpp4i switcher
event ibd1_dt enddate death_dt dbexit_dt  LastColl_Dt endofdrug;
run;
title;
title "those in 49 IBD censored and 53 IBD switchers in SU person-time";
proc print data=IBD_sucensore_and_dppswitcher_s;
var id useperiod indexdate filldate2 switchaugmentdate excludeflag_prevalentuser dpp4i_filldate2 discontdate newuse su dpp4i switcher
event ibd1_dt enddate death_dt dbexit_dt  LastColl_Dt endofdrug;
run;
title;

*stack these 2 datasets and sort by ID;
data IBD_sucensore_and_dppswitcher; set IBD_sucensore_and_dppswitcher_d IBD_sucensore_and_dppswitcher_s; run;
proc sort data=IBD_sucensore_and_dppswitcher; by id; run; 
title "those in 49 IBD censored and 53 IBD switchers in both DPP4i and SU person-time";
proc print data=IBD_sucensore_and_dppswitcher;
var id useperiod indexdate filldate2 switchaugmentdate excludeflag_prevalentuser dpp4i_filldate2 discontdate newuse su dpp4i switcher
event ibd1_dt enddate death_dt dbexit_dt  LastColl_Dt endofdrug;
run;
title;
/*check key flags for 9 patients*/
/* Adding a row number to dataset A */
data dsn_with_rownum;
    set dsn;
    row_num = _N_;
run;

/* Merge dataset B with A_with_rownum to find row numbers */
proc sql;
    create table Result as
    select B.ID, 		   B.row_num, 
		   A.useperiod, A.indexdate, A.filldate2, A.switchaugmentdate, A.excludeflag_prevalentuser, A.dpp4i_filldate2, A.discontdate, 
		   A.newuse, A.su, A.dpp4i, A.switcher, A.event, A.ibd1_dt, A.enddate, A.death_dt, A.dbexit_dt, A.LastColl_Dt, A.endofdrug
    from IBD_sucensore_not_in_dppswitcher /*9 patients*/ as A
    left join dsn_with_rownum as B
    on A.ID = B.ID;
quit;

proc print data=Result; 
run;

/* check other variables in addtion to key flags for 9 patients*/
proc sql;
    create table Result_Aall as
    select B.ID, 
		   B.row_num, 
		   A.*
    from IBD_sucensore_not_in_dppswitcher as A
    left join dsn_with_rownum as B
    on A.ID = B.ID;
quit;

/* Display the result */
proc print data=Result_Aall; 
run;

/*check if those 9 patiens are included twice in the DSN analytic cohort*/
data Result_Aall_drop_rowN(drop=row_num); set Result_Aall;run;

proc sort data=Result_Aall_drop_rowN out=sorted nodupkey dupout=duplicates; by _all_ ;run;

proc print data=duplicates; run;



/*check key flags for 13 patients*/
/* Adding a row number to dataset A 
*/

/* Merge dataset B with A_with_rownum to find row numbers */
%macro check_switcher_row(dat_switcher,dat);
data &dat._2;
    set &dat.;
    row_num = _N_;
	if IBD_ever ne 1;
run;

%if &dat = dsn %then %do;
proc sql;
    create table swithcer_row_print as
    select B.ID format $12., B.row_num, 
		  b.dpp4i, B.SWITCHER, b.newuse, a.num_rows, b.indexdate, b.filldate2 , b.switchaugmentdate, b.excludeflag_prevalentuser, b.dpp4i_filldate2, b.discontdate, 
		   b.event, b.ibd1_dt, b.enddate,/* b.death_dt,*/ b.dbexit_dt, b.LastColl_Dt, b.endofdrug FORMAT DATE9.
    from &dat_switcher.  as A
    left join &dat._2 as B on A.ID = B.ID  ;
quit;
proc sort data=swithcer_row_print ; by id dpp4i;run;
%end;
%else %if &dat NE dsn %then %do;
proc sql;
    create table swithcer_row_print as
    select B.ID, B.row_num format $12.,  b.dpp4i as dpp4i_2, b.indexdate as indexdate_2, b.filldate2 as filldate2_2, b.switchaugmentdate as switchaugmentdate_2, b.newuse as newuse_2
		  a.dpp4i, a.SWITCHER, a.newuse, a.num_rows, a.indexdate, a.filldate2 , a.switchaugmentdate, a.excludeflag_prevalentuser, a.dpp4i_filldate2, a.discontdate, 
		   a.event, a.ibd1_dt, a.enddate, /*a.death_dt,*/ a.dbexit_dt, a.LastColl_Dt, a.endofdrug FORMAT DATE9.
    from &dat_switcher.  as A
    left join &dat._2 as B on A.ID = B.ID  ;
proc sort data=swithcer_row_print ; by id dpp4i_2;run;
quit;
%end;
proc print data=swithcer_row_print; run;
%mend;



%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, dsn);
%check_switcher_row(IBD_sucensore_not_in_dppswitcher/*9*/, dsn);/*18 OBSERVATIONS*/

%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, tmpana_&exposure._&comparator.);
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, tmp1);/*%createana_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, dpp4i_initiator_pu2/*requinring distinct ID*/);
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, dpp4i_initiator_pu/*requinring distinct ID*/);

proc print data=temp.&comparator._useperiods(obs=1);run;
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, temp.&comparator._useperiods);/*%getcohort_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, temp.&exposure._useperiods);/*%getcohort_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, tmp_exclude_&comparator.);/*%getcohort_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, _new_abrahami_&comparator.);/*%getcohort_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, tmp_exclude_&exposure.);/*%getcohort_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, new_abrahami_&comparator.);/*%getcohort_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, new_abrahami_&exposure.);/*%getcohort_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, Abrahami_&exposure._&comparator.);/*%getcohort_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, merge_Abrahami_&exposure._&comparator.);/*%getcohort_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, final_Abrahami_&exposure._&comparator.);/*%getcohort_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, temp.Abrahami_&exposure._&comparator.);/*%getcohort_Ab*/

%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, temp.Abrahami_allmerged_&exposure._&comparator.);/*%mergealls_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, a.Abrahami_allmerged_&exposure._&comparator.);/*%createana_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, temp.Abrahami_allmerged_&exposure._&comparator.);/*%createana_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, a.Abrahami_PS_&exposure._&comparator.);/*psweighting_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, a.Abrahami_PS_&exposure._&comparator.);/*psweighting_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, psdsnnotrim);/*psweighting_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, psdsn);/*psweighting_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, trimmed_individuals);/*psweighting_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, trimmed_individuals_&comparator.);/*psweighting_Ab*/
%check_switcher_row(IBD_dppswitcher_not_in_sucensor/*13*/, trimmed_individuals_&exposure.);/*psweighting_Ab*/

proc print data=psdsnnotrim(obs=1);run;
proc print data=psdsn(obs=1);run;
proc print data=trimmed_individuals_&comparator.; where missing(id); run;

 


proc sql;
	create table IBD_switcher_not_in_censor as
	select * from ACNU_su_dpp4i
	where not exists (select * from TVE_su_dpp4i where TVE_su_dpp4i.ID = ACNU_su_dpp4i.ID);
	create table TVE_noACNU as
	select * from TVE_su_dpp4i
	where not exists (select * from ACNU_su_dpp4i where ACNU_su_dpp4i.ID = TVE_su_dpp4i.ID);
quit;

* Create new dataset of only individuals flagged with IBD1, keeping variables which were used to create the event variable;
data ACNU_su_dpp4i; set dsn_ACNU; 
    keep id dpp4i excludeflag_prevalentuser filldate2 switchAugmentDate enddate &ibd_def._dt 
    ibd1 IBD_ever event deleteobs trimming_flag ; 
    where ibd1 eq 1; RUN;

data TVE_su_dpp4i; set dsn_TVE; 
    keep id dpp4i excludeflag_prevalentuser filldate2 dpp4i_filldate2 switchAugmentDate enddate &ibd_def._dt 
    ibd1 IBD_ever event deleteobs trimming_flag; 
    where ibd1 eq 1; RUN;



/*TODO- from Tian Is there a way to output cohort of 60 IBD switchers, and the cohort of the 49 IBD censored */
/* 60 IBD Switchers */
proc print data= TVE_su_dpp4i; 
where  (event eq 1) and (ibd1 eq 1) and (dpp4i eq 1) and (excludeflag_prevalentuser=1);
RUN;
proc contents data=TVE_su_dpp4i;run;
/*define switchers by excludeflag_prevalentuser (all switchers are labled)*/
proc print data=TVE_su_dpp4i (obs=50);run;
ods output summary=IBD_event_switchers;
Proc means data=TVE_su_dpp4i sum stackods ;
    where /*time ne . and */excludeflag_prevalentuser eq 1; 
    class dpp4i;
    var ibd1;
RUN;
data IBD_event_switchers (rename=(sum=IBD_event_switchers)); 
    set IBD_event_switchers;
RUN;
proc print data=IBD_event_switchers;run;

data IBD_event_switchers_raw; set TVE_su_dpp4i ; where excludeflag_prevalentuser eq 1 and dpp4i=1; RUN;
proc print data=IBD_event_switchers_raw;run;/*n=65*/

/* 49 IBD censored  */
proc print data=TVE_su_dpp4i; 
where  (event eq 0) and (ibd1 eq 1) and (dpp4i eq 0);  
RUN;
/* count events missed due to events being attributed to Dpp4i initiators who were prevalent users of the comparator  
(events that would have been in the comparator's person time as it would be in our Main IT analysis 
if not for the censoring at 180+switch/augment/fill2date date )*/
ods output summary= IBD_events_censored;
Proc means data=TVE_su_dpp4i sum stackods ;
    where /*time ne .and*/  event eq 0; 
    class dpp4i;
    var ibd1;
RUN;
data IBD_events_censored (rename=(sum=IBD_events_censored)); 
    set IBD_events_censored;
RUN;

data IBD_events_censored_raw; set TVE_su_dpp4i ; where event eq 0 and dpp4i=0; RUN;
proc print data=IBD_events_censored_raw;run;/*n=121*/


proc print data=IBD_events_censored;run;
/* Check the ids are the same. Expecting this to be zero, all ids should be the same. */
/* Remove NOPRINT if running on your own */
PROC SQL /*NOPRINT*/;/*5 rows obsreved!*/
    select distinct * from TVE_su_dpp4i
    where id not in (select id from ACNU_su_dpp4i)
    order by id , filldate2;
QUIT;

PROC SQL /*NOPRINT*/;/*no rows obsreved!*/
    select distinct * from ACNU_su_dpp4i
    where id not in (select id from TVE_su_dpp4i)
    order by id , filldate2;
QUIT;
/* Hopefully selects all ids (rows and duplicate ids) that are from switchers */
PROC SQL NOPRINT;
    select distinct * from TVE_su_dpp4i
    where id in (select id from TVE_su_dpp4i where excludeflag_prevalentuser=1)
    order by id , filldate2;
QUIT;

PROC SQL;/*5 rows obsreved!*/
    create tmp1 as select distinct id, filldate2 from dsn_TVE
    where id not in (select id from dsn_ACNU)
    order by id , filldate2;
QUIT;

/* Or maybe try: */
* Selecting all observations where the id from SU initiators with a switchAugmentDate to verify that the code from line 284 was written correctly ;
PROC SQL NOPRINT;
    select distinct * from TVE_su_dpp4i
    where id in (select id from TVE_su_dpp4i where dpp4i eq 0 and switchAugmentDate ne .)
    order by id , filldate2;
QUIT;
/* Printing out ACNU observations from the switchers (where did the 60 people come from?)*/
PROC SQL NOPRINT; 
    /* Hopefully this will print out only individuals with dpp4i =0 (the su) */
    select distinct * from ACNU_su_dpp4i
    where id in (select id from TVE_su_dpp4i where excludeflag_prevalentuser=1 and dpp4i eq 1)
    order by id , filldate2;
    /* Compare with the ibd1 from the TVE cohort */
    select * from TVE_su_dpp4i 
    where excludeflag_prevalentuser=1 and dpp4i eq 1
    order by id, filldate2;
QUIT;

/* endregion //!SECTION */

/*===================================*\
//SECTION - EXECUTE: Print to Excel Summary counts 
\*===================================*/
/* region */

/* For Inital Treatment (IT) our main analysis  */
/* Printing results into excel  */
ods excel file="&toutpath./IT_Checkeventcounts_&todaysdate..xlsx"
  options (
    Sheet_interval="NONE"
    embedded_titles="NO"
    embedded_footnotes="NO"
);

    ods text="DPP4i_SU"; ods excel options( sheet_name="DPP4i_SU" sheet_interval="NOW");

%count_events_ACNU ( 
exposure = dpp4i,
comparator = su,
ana_name = ACNU,
type = IT,
induction = 180,
latency = 180;,
ibd_def = ibd1,
intime = filldate2,
outtime = '31Dec2022'd
);

    ods text="DPP4i_SU"; ods excel options( sheet_name="DPP4i_SU" sheet_interval="NOW");

%count_events_TVE ( 
exposure = dpp4i,
comparator = su,
ana_name = TVE,
type = IT,
induction = 180,
latency = 180;,
ibd_def = ibd1,
intime = filldate2,
outtime = '31Dec2022'd);

    ods text="DPP4i_TZD";
    ods excel options( sheet_name="DPP4i_TZD" sheet_interval="NOW");

%count_events_ACNU ( 
exposure = dpp4i,
comparator = TZD,
ana_name = ACNU,
type = IT,
induction = 180,
latency = 180;,
ibd_def = ibd1,
intime = filldate2,
outtime = '31Dec2022'd
);

    ods text="DPP4i_TZD";
    ods excel options( sheet_name="DPP4i_TZD" sheet_interval="NOW");

%count_events_TVE ( 
exposure = dpp4i,
comparator = TZD,
ana_name = TVE,
type = IT,
induction = 180,
latency = 180;,
ibd_def = ibd1,
intime = filldate2,
outtime = '31Dec2022'd);

    ods text="DPP4i_SGLT2i";
    ods excel options( sheet_name="DPP4i_SGLT2i" sheet_interval="NOW");
%count_events_ACNU ( 
exposure = dpp4i,
comparator = SGLT2i,
ana_name = ACNU,
type = IT,
induction = 180,
latency = 180;,
ibd_def = ibd1,
intime = filldate2,
outtime = '31Dec2022'd
);

    ods text="DPP4i_SGLT2i";
    ods excel options( sheet_name="DPP4i_SGLT2i" sheet_interval="NOW");

%count_events_TVE ( 
exposure = dpp4i,
comparator = SGLT2i,
ana_name = TVE,
type = IT,
induction = 180,
latency = 180;,
ibd_def = ibd1,
intime = filldate2,
outtime = '31Dec2022'd);
ods excel close;



/* OK TO NOT RUN, Lower priority because AS Treated/AT might have less predictable ibd-->event counts */
ods excel file="&toutpath./AT_Checkeventcounts_&todaysdate..xlsx"
  options (
    Sheet_interval="NONE"
    embedded_titles="NO"
    embedded_footnotes="NO"
);

    ods text="DPP4i_SU"; ods excel options( sheet_name="DPP4i_SU" sheet_interval="NOW");

%count_events_ACNU ( 
exposure = dpp4i,
comparator = su,
ana_name = ACNU,
type = AT,
induction = 180,
latency = 180;,
ibd_def = ibd1,
intime = filldate2,
outtime = '31Dec2022'd
);

    ods text="DPP4i_SU"; ods excel options( sheet_name="DPP4i_SU" sheet_interval="NOW");

%count_events_TVE ( 
exposure = dpp4i,
comparator = su,
ana_name = TVE,
type = AT,
induction = 180,
latency = 180;,
ibd_def = ibd1,
intime = filldate2,
outtime = '31Dec2022'd);

    ods text="DPP4i_TZD";
    ods excel options( sheet_name="DPP4i_TZD" sheet_interval="NOW");

%count_events_ACNU ( 
exposure = dpp4i,
comparator = TZD,
ana_name = ACNU,
type = AT,
induction = 180,
latency = 180;,
ibd_def = ibd1,
intime = filldate2,
outtime = '31Dec2022'd
);

    ods text="DPP4i_TZD";
    ods excel options( sheet_name="DPP4i_TZD" sheet_interval="NOW");

%count_events_TVE ( 
exposure = dpp4i,
comparator = TZD,
ana_name = TVE,
type = AT,
induction = 180,
latency = 180;,
ibd_def = ibd1,
intime = filldate2,
outtime = '31Dec2022'd);

    ods text="DPP4i_SGLT2i";
    ods excel options( sheet_name="DPP4i_SGLT2i" sheet_interval="NOW");
%count_events_ACNU ( 
exposure = dpp4i,
comparator = SGLT2i,
ana_name = ACNU,
type = AT,
induction = 180,
latency = 180;,
ibd_def = ibd1,
intime = filldate2,
outtime = '31Dec2022'd
);

    ods text="DPP4i_SGLT2i";
    ods excel options( sheet_name="DPP4i_SGLT2i" sheet_interval="NOW");

%count_events_TVE ( 
exposure = dpp4i,
comparator = SGLT2i,
ana_name = TVE,
type = AT,
induction = 180,
latency = 180;,
ibd_def = ibd1,
intime = filldate2,
outtime = '31Dec2022'd);
ods excel close;
/* endregion //!SECTION */


%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);
