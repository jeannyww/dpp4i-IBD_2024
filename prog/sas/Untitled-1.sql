
/*===================================*\
//SECTION - ACNU event counts
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

%macro count_events_ACNU ( exposure , comparator , ana_name , type ,  induction , latency , ibd_def , intime , outtime  ) / minoperator mindelimiter=',';

/*===================================*\
//SECTION - Setting up data for analysis 
\*===================================*/
/* region */

data dsn_ACNU; set A.ALLMERGED_&exposure._&comparator._1YRLB;
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
/* exclusion of who did not reach the induction period for followup */
PROC FREQ DATA=dsn_ACNU; 
TABLES dpp4i*excludeflag_prevalentuser*deleteobs*event /list missing;
RUN;
/* individuals had IBD diagnosis within the induction period */
PROC FREQ DATA=dsn_ACNU; 
TABLES dpp4i*excludeflag_prevalentuser*IBDdx_inductionperiod*event /list missing;
RUN;
/* individuals with missing fu time ? */
PROC FREQ DATA=dsn_ACNU; 
WHERE time eq .; 
TABLES dpp4i*excludeflag_prevalentuser*event /list missing;
RUN;
/* number events when all exclusions are applied */
PROC FREQ DATA=dsn_ACNU; 
WHERE deleteobs=0 and IBDdx_inductionperiod=0 and time ne .;
TABLES dpp4i*excludeflag_prevalentuser*event /list missing;
RUN;

proc means data=dsn_ACNU 
    STACKODS N NMISS MEAN STD MIN MAX Q1 MEDIAN Q3   ;
    where time ne .; 
    class &exposure excludeflag_prevalentuser;    
    var  time time_drugdur ; 
run;

PROC FREQ DATA=dsn_ACNU; 
TABLES dpp4i*excludeflag_prevalentuser*event /list missing;
RUN;
title; 

/* Do not have to run but incase you want to compare median time of followup */
ods output summary=mediantime;
proc means data = dsn_ACNU STACKODS  N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3;
    where time ne .; 
    class &exposure;
    var time ;
run;

ods output summary=mediantimedu;
proc means data = dsn_ACNU STACKODS  N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3;
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

data mediantimetmp(rename=(sum=time_sum)); 
    merge mediantime mediantimedu; 
    by &exposure; 
run;

/* count numbers of event  */
ods output summary=event;
Proc means data=dsn_ACNU sum stackods ;
    where time ne .; 
    class &exposure;
    var event;
run;
/* Count ibd_def. diagnosis that were not considered events */
Proc means data=dsn_ACNU sum stackods ;
    where time ne .; 
    class &exposure;
    var &ibd_def. ;
run;
Proc means data=dsn_ACNU sum stackods ;
    where time ne . and  event eq 0; 
    class &exposure;
    var &ibd_def. ;RUN;

%mend count_events_ACNU;
