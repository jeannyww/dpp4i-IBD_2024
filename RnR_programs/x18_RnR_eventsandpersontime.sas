/***************************************
SAS file name: 16_RnR_ACNUanalysisrun.sas

Purpose: To run the ACNU analysis - main analysis, untrimmed cohort (ACNU)
Contains: 
- LINE 35: ACNU MAIN Analysis, IT and AT
- 

Author: JHW
Creation Date: 2024-12-18

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
Date: 2024-12-18
Notes: Separated the analysis macro from running the ACNU analysis program 
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=16_RnR_ACNUanalysisrun.sas, savelog=N, dataset=dataname);

/* Load ACNU_analysis macro */
%include "D:\Externe Projekte\UNC\wangje\prog\sas\16_RnR_ACNUanalysismacro.sas";
/* Load TVE_analysis macro */
%include "D:\Externe Projekte\UNC\wangje\prog\sas\17_RnR_TVEanalysismacros.sas";

/*===================================*\
//SECTION - ACNU IT Main Analysis, focusing on the DPP4i vs. TZD cohort for counts
\*===================================*/
/* region */

%LET exposure = dpp4i;
%LET comparator = tzd;
%LET intime = FILLDATE2;
%LET outtime = '31Dec2022';
%LET induction = 180;
%LET latency = 180;
%LET ibd_def = ibd1;

/* DSN ACNU  */
    *%ACNU_analysis (pstrim=N, exposure= dpp4i , comparator= tzd, ana_name=mITac, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;

data dsn_ACNU; 
    /* Set to untrimmed cohort */
    set a.notrim_&exposure._&comparator._1yrlb; 
   /* where indexdate=date of first Rx, filldate2=date of 2nd rx, and for the main analysis the entry=date of 2nd prescription */
    oneyear  =&intime +365.25;
	twoyear  =&intime +730.5;
	threeyear=&intime +1095.75;
	fouryear =&intime +1460;
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
    /* Initial Treatment  */
        enddate= min(			&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
        format enddate date9. ; label enddate ="Date min of (&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt)";

        *"Date min of (death_dt, endstudy_dt, dbexit_dt, LastColl_Dt)";
        enddatedelete=min(enddt, endstudy_dt, &outtime);  
        
        *flag to remove individuals who did not reach the induction period for followup ;
        IF indexdate<= enddatedelete<=(&intime + &induction) then deleteobs=1; 
            else deleteobs=0;
        label deleteobs="Flag to remove individuals who did not reach the induction period for followup";
        IF indexdate <= &ibd_def._dt <=(&intime + &induction) then IBDdx_inductionperiod=1;
            else IBDdx_inductionperiod=0;
        label IBDdx_inductionperiod="Flag for individuals with IBD diagnosis within the induction period";

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
data dsn_ACNUcut; set dsn_ACNU; 
    if deleteobs=1 then delete;
    if IBDdx_inductionperiod=1 then delete; 
    if time eq . then delete; run;

/* Getting the 131 TBD cases for DPP4i users */
proc PROC FREQ DATA=dsn_ACNUcut;
TABLES event /list missing;
RUN;
/* Getting the 287,967 person-time for DPP4i, ACNU */
proc means data=dataname 
    STACKODS N NMISS MEAN STD MIN MAX Q1 MEDIAN Q3   ;
var  variables ; 
run;
/* Getting the rate per 100,000 py */
proc genmod data=dsn_ACNUcut; 
    by &exposure; 
    
/*===================================*\
//SECTION - TVE counts, focusing on the DPP4i vs. TZD cohort
\*===================================*/
/* region */


/* endregion //!SECTION */
    *%TVE_analysis (pstrim=N, exclude_ibd=Y, exposure= dpp4i , comparator= tzd, ana_name=mITtv, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
data dsn_TVE;
    set a.Abrahami_Notrim_&exposure._&comparator.;
    /* where entry=date of 2nd prescription */
    oneyear  =&intime +365.25;
	twoyear=&intime +730.5;
	threeyear=&intime +1095.75;
	fouryear =&intime +1460;
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
            if &exposure =0 and switchAugmentDate ne . then do;
                enddate= min(&ibd_def._dt, dpp4i_filldate2 +&induction);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne .    then event=1; else event=0;
                end;
       /* IT analysis  */
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
data dsn_TVEcut; set dsn_TVE; 
    if deleteobs=1 then delete; /*delete zero person time persons*/
    if IBDdx_inductionperiod=1 then delete; 
run;
    
/* endregion //!SECTION */

PROC FREQ DATA=dsn_ACNU;
TABLES trimming_flag event/list missing;
PROC FREQ DATA=dsn_TVE;
TABLES trimming_flag event/list missing;
RUN;
/* Switchers? */
data dsn_TVE_dpp_ibdswitchers;
	set dsn_TVE;
if  deleteobs=0 and IBDdx_inductionperiod=0 and time ne .;
if dpp4i=1 and trimming_flag=0 and excludeflag_prevalentuser=1 and ibd1=1 and event=1 and ibd_ever=0;
run; 


%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);



