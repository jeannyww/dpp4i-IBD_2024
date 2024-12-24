/***************************************
SAS file name: 016_RnR_ACNUanalysismacro.sas

Purpose: To run main analysis for each ACNU cohort
Author: JHW
Creation Date: 2024-01-09

Output, programs (general &goutpath., tables &toutpath., and figures &foutpath.):
        D:\Externe Projekte\UNC\wangje\out
        D:\Externe Projekte\UNC\wangje\prog\sas

Input paths:
            original raw data:  D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16
            libname a  D:\Externe Projekte\UNC\wangje\data\analysis
            libname raw  D:\Externe Projekte\UNC\wangje\data\raw
            libname temp  D:\Externe Projekte\UNC\wangje\data\temp
Other details: CPRD-DPP4i project in collaboration with USB

Date: 2024-04-09
CHANGES: line 441 added template code for sensitivity analyses 

Date: 2024-04-16
CHANGES: To Resolve the following error "different sample size of AT and IT analysis in ACNU cohort. Sample size should be the same, inclusion/exclusion criteria should not be based on future events during follow-up (like "enddate").""

-	(latency pd between dz onset and dz dx)
-	Induction (taking drug to dz onset) 


Date: 2024-05-01
CHANGES: checked 3yearsout, lines 89-92

Date: 2024-05-22
CHANGES: using new 1yrlb dataset, run during Virginia office hours today 

Date: 2024-12-18
CHANGES: Separated the analysis macro from using the macro to run this analysis 
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=16_runanalysis, savelog=Y, dataset=tmp);

proc template; define style mystyle;
    parent=styles.sasweb;
        class graphwalls /frameborder=off;
        class graphbackground / color=white;
    end;run;
/*---------------------------------------------------------------------
%analysis(
exposure =  ,   *exposure drug of interest: DPP4i;
comparator =  , *comparator drug: SU TZD;    
ana_name =  ,    *name of analysis: main, sensitivity, etc.;
type =  ,        *type of analysis: AT (as treated) or ITT (initial treatment);
weight =  ,       *type of weighting used: iptw, siptw, smrw, smrwu, ssmrwu;
induction =  ,    *induction period for dz initiation 180d;
latency =  ,      *latency period for dz detection 180d;
ibd_def =  ,      *IBD definition used (free text, ie main definition); 
intime =  ,       *time which analysis fu time will start, ie: entry (date of 2nd rx), initiation_date (date of 1st rx);
outtime =  ,      *time which analysis fu ends, ie for AT: '31Dec2017'd, for ITT: oneyearout twoyearout threeyearout fouryearout;
 outdata =        *freetext for your chosen name of the outdata results ;
)

%ACNU_analysis ( exposure= , comparator=, ana_name=, type=, weight=, induction=, latency=, ibd_def= , intime= , outtime= , outdata= );

%ACNU_analysis ( exposure=  
, comparator=
, ana_name=
, type=
, weight=
, induction=
, latency=
, ibd_def=
, intime=  
, outtime=  
, outdata= );
---------------------------------------------------------------------*/

/*===================================*\
//SECTION - First- Creating Macro
\*===================================*/

%macro ACNU_analysis (pstrim, exposure , comparator , ana_name , type , weight , induction , latency , ibd_def , intime , outtime, numyears ,outdata, save) / minoperator mindelimiter=',';

/*===================================*\
//SECTION - Setting up data for analysis 
\*===================================*/
/* region */

/* 2024-12-18 added option to use Trimmed vs Notrim dataset (these datasets were created in line 308 of program 15_RnR_PSweighting.sas) */
%if %upcase(&pstrim.) eq Y %then %do; 
    /* TRIMMED for sensitivity analysis */
    data dsn; set a.PS_&exposure._&comparator._1yrlb; run;
%end; %else %if %upcase(&pstrim.) eq N %then %do;
    /* Untrimmed for main analysis now */
    data dsn; set a.notrim_&exposure._&comparator._1yrlb; run;
%end;

/* Create events and follow-up time */
data dsn; set dsn;
   /* where indexdate=date of first Rx, filldate2=date of 2nd rx, and for the main analysis the entry=date of 2nd prescription */
    oneyear  =&intime +365.25;
	twoyear  =&intime +730.5;
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
        enddate= min(			&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
        format enddate date9. ; label enddate ="Date min of (&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt)";
        *"Date min of (&ibd_def._dt,death_dt, endstudy_dt, dbexit_dt, LastColl_Dt)";
        %end;

    /* As Treated */ 
    %if %upcase(&type) eq AT %then %do;  
        enddate= min(endofdrug, &ibd_def._dt, enddt, endstudy_dt, &outtime, death_dt, dbexit_dt, LastColl_Dt ); /* AT exit date and AT exit_reason   */
        format enddate date9.; LABEL enddate="Date min of (&ibd_def._dt, drug discontinuation, death_dt, endstudy_dt, dbexit_dt, enddt (end enroll), LastColl_Dt)";
        %end; 

    /* As Treated and censoring for badrx (sensitivity analysis 6 "6)	
	We will additionally censor patients when they receive medications that could potentially induce IBD progression [19] (Appendix 10). ") 
    we allow events to occur 180 days after stopping medication */
    %if %upcase(&type) eq ATB %then %do;
        enddate= min(endofdrug, &ibd_def._dt,  enddt, endstudy_dt, &outtime, death_dt, dbexit_dt,LastColl_Dt, discontDate, (badrx_dt+ &latency) );
        format enddate date9.; label enddate="Date min of (&ibd_def._dt, drug discontinuation, death_dt, endstudy_dt, dbexit_dt, enddt (end enroll), LastColl_Dt, badrx_dt)";
        %end;
 

    /* Either  */
    %if %upcase(&type) # AT, IT %then %do;
        *"Date min of (death_dt, endstudy_dt, dbexit_dt, LastColl_Dt)";
        enddatedelete=min(enddt, endstudy_dt, &outtime);  
        
        *flag to remove individuals who did not reach the induction period for followup ;
        IF indexdate<= enddatedelete<=(&intime + &induction) then deleteobs=1; 
            else deleteobs=0;
        label deleteobs="Flag to remove individuals who did not reach the induction period for followup";
        IF indexdate <= &ibd_def._dt <=(&intime + &induction) then IBDdx_inductionperiod=1;
            else IBDdx_inductionperiod=0;
        label IBDdx_inductionperiod="Flag for individuals with IBD diagnosis within the induction period";
        %end;

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
/*=================*\
Update counts for exclusion
\*=================*/
PROC SQL noprint; 
    create table tmp_counts as select * from temp.excl_015_&exposure._&comparator._1yrlb;
    select count(*) into : num_obs from tmp_counts;
    insert into tmp_counts
        set exclusion_num=&num_obs+1, 
        long_text="Number of observations after excluding individuals whose endstudy_dt <= &intime. + &induction.",
        dpp4i            =  (select count(*) from dsn where (&exposure=1    and deleteobs=0)),
        dpp4i_diff       = -(select count(*) from dsn where (&exposure=1    and deleteobs=1)),
        &comparator.     =  (select count(*) from dsn where (&exposure ne 1 and deleteobs=0)) ,
        &comparator._diff= -(select count(*) from dsn where (&exposure ne 1 and deleteobs=1)),   
        full             =  (select count(*) from dsn where (deleteobs=0));
    insert into tmp_counts
        set exclusion_num=&num_obs+2, 
        long_text        ="Number of individuals with time0 <&ibd_def._dt <= &intime. + &induction.",
        dpp4i            =  (select count(*) from dsn where (&exposure=1    and IBDdx_inductionperiod=0)),
        dpp4i_diff       = -(select count(*) from dsn where (&exposure=1    and IBDdx_inductionperiod=1)),
        &comparator.     =  (select count(*) from dsn where (&exposure ne 1 and IBDdx_inductionperiod=0)) ,
        &comparator._diff= -(select count(*) from dsn where (&exposure ne 1 and IBDdx_inductionperiod=1)),
        full= (select count(*) from dsn where (IBDdx_inductionperiod=0));
QUIT;
data dsn; set dsn; 
    if deleteobs=1 then delete;
    if IBDdx_inductionperiod=1 then delete; run;
proc sql noprint;
    select count(*) into : num_obs from tmp_counts;
    insert into tmp_counts
        set exclusion_num=&num_obs+1, 
        long_text="Number of individuals with positive, non-zero &type followup time (enddate-(&intime.+&induction)>0)",
        dpp4i            =  (select count(*) from dsn where (&exposure=1    and time ne .)),
        dpp4i_diff       = -(select count(*) from dsn where (&exposure=1    and time eq .)),
        &comparator.     =  (select count(*) from dsn where (&exposure ne 1 and time ne .)) ,
        &comparator._diff= -(select count(*) from dsn where (&exposure ne 1 and time eq .)),   
        full             =  (select count(*) from dsn where (time ne .));
    select * from tmp_counts;
%if %upcase(&save) eq Y %then %do;
    create table temp.excl_016_&exposure._&comparator._1yr&type. as select * from tmp_counts;
    %end;
quit;
proc print data= tmp_counts; run;
data dsn; set dsn; if time eq . then delete; run;
/* endregion //!SECTION */

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
    mediantime   = compress(put((median), 6.1)) || " (" || compress(put((q1), 6.1)) || "-" || compress(put((q3), 6.1)) || ")"; 
    format sum 8.0;
run; 
    
data mediantimedu(keep=&exposure mediantimedu );			
    set mediantimedu;
    mediantimedu = compress(put((median), 6.1)) || " (" || compress(put((q1), 6.1)) || "-" || compress(put((q3), 6.1)) || ")";  
    format sum 8.0;
run; 

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

/* endregion //!SECTION */

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

/* endregion //!SECTION */

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
    crudehr=compress(put((hazardratio),6.1))||" ("||compress(put((HRlowerCL),6.1))||"-"||compress(put((HRupperCL),6.1))||")";
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
    &weight.hr=compress(put((hazardratio),6.1))||" ("||compress(put((HRlowerCL),6.1))||"-"||compress(put((HRupperCL),6.1))||")";
run;
/* endregion //!SECTION */
/*===================================*\
//SECTION - output results 
\*===================================*/
/* Merge and compile of counts, persontime, incidence rates, unweighted and SMR-weighted HRs */

Data &outdata;
    length type $ 32 ;
    length analysis $ 32 ;   
    merge mediantimetmp   event  (rename=(sum=event_sum)) rate crudehr &weight;
    by &exposure;
    analysis="&ana_name. &type. &outdata.";
    type="&ibd_def.";
    latency=&latency;
    induction=&induction;
    n_switch=.;
    IBD_event_switchers=.;  
    IBD_events_censored=.;
    IBD_hx_sum=.;
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

Data a.out_&exposure.v&comparator._&ana_name._&outdata.;
        retain TYPE &exposure Nobs n_switch mediantime time_sum event_sum IBD_event_switchers IBD_events_censored IBD_hx_sum  rate crudehr &weight.HR analysis induction latency exp unexp; 
        set tmpout1;
            
        format event_sum best12.;
        format Nobs COMMA12. event_sum COMMA12. time_sum COMMA12. ibd_event_switchers COMMA12. IBD_events_censored COMMA12. IBD_hx_sum COMMA12. n_switch COMMA12. ;
run;

 /* endregion //!SECTION */
/*===================================*\
//SECTION - KM plots 
\*===================================*/
/* region */
/*ods excel options(sheet_interval="NOW");*/
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

data exp(keep=&timevar risk risk_lower risk_upper &exposure.) 
   unexp(keep=&timevar risk risk_lower risk_upper &exposure.);
set  pred;
if &exposure=1 then output exp;
if &exposure=0 then output unexp;
run;
/*
Data plot;
	merge exp(rename=(risk=&exposure   risk_lower=&exposure._lower   risk_upper=&comparator._upper)) 
	    unexp(rename=(risk=&comparator risk_lower=&comparator._lower risk_upper=&comparator._upper));
	by &timevar;
run;*/


Data plot;
	merge exp(rename=(risk=&exposure._risk   risk_lower=&exposure._lower   risk_upper=&exposure._upper)) 
	    unexp(rename=(risk=&comparator._risk risk_lower=&comparator._lower risk_upper=&comparator._upper));
	by &timevar;
run;

proc template;
	define style mystyle;
	parent=styles.sasweb;
	class graphwalls/frameboarder=off;
	class graphbackground/color=white;
	end;
run;

ods graphics /noborder reset=index imagename="wKM_&ana_name._&exposure.v&comparator._%sysfunc(date(),date.)" imagefmt=tiff;
ods listing style=mystyle gpath="&fOutPath.";  

PROC SGPLOT DATA = plot NOAUTOLEGEND DESCRIPTION=""; 
YAXIS LABEL = 'Risk of Inflammatory Bowel Disease' LABELATTRS=(size=13pt weight=bold)  VALUES = (0 TO 0.0045 BY 0.0005) valueattrs=(size=12pt); 
/* 2024-12-18 JW change to a variable &numyears for KM followup */
    XAXIS LABEL = 'Follow-up Time (years)' LABELATTRS=(size=13pt weight=bold)  VALUES = (0 TO &numyears. BY 0.5)       valueattrs=(size=12pt); 

title height=12pt bold " ";
step x=&timevar y=&exposure._risk /lineattrs=(color=blue pattern=1  thickness=2) name="&exposure._risk";
step x=&timevar y=&exposure._lower/lineattrs=(color=blue pattern=20 thickness=1) name="&exposure._lower";
step x=&timevar y=&exposure._upper/lineattrs=(color=blue pattern=20 thickness=1) name="&exposure._upper";

step x=&timevar y=&comparator._risk /lineattrs=(color=red  pattern=1  thickness=2) name="&comparator._risk";
step x=&timevar y=&comparator._lower/lineattrs=(color=red  pattern=20 thickness=1) name="&comparator._lower";
step x=&timevar y=&comparator._upper/lineattrs=(color=red  pattern=20 thickness=1) name="&comparator._upper";
keylegend "&exposure._risk" "&comparator._risk" /location=inside position=topleft valueattrs=(size=12pt weight=bold) NOBORDER;
FOOTNOTE;
RUN; 
ods graphics off;

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

DATA countout;
SET tmpp_:;
outcome_def="&ibd_def.";
RUN;
proc sort data= countout; by drug; run;
proc transpose data=countout out=tmp prefix= fuyear; 
by drug ; 
id fu_year; run;
proc print data= tmp  ;  variables drug fuyear:;
run; 

proc print data= a.out_&exposure.v&comparator._&ana_name._&outdata. ; 
run; 

ods listing;
/* endregion //!SECTION */

%mend ACNU_analysis;

/* endregion //!SECTION */
