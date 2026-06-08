/***************************************
SAS file name: 17_RnR_switcherWebTable4.sas

Purpose: To run analysis that mimic Abrahami et al methods for 2018 dpp4i-IBD paper
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
Date: 2024-12-27
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen  nomlogic nomprint  ; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=17_RnR_switcherWebTable4.sas, savelog=n, dataset=dataname);

/**/
/* Create a data set with dates */
data work.ds;
    format mydate1 mydate2 mydate3 date9.;
    input mydate1 :date9. mydate2 :date9. mydate3 :date9.;
    datalines;
13JUN2020 20JUL2020 31DEC2020
;
run;
data ds; set ds; 
diff12=mydate2-mydate1; 
diff23=mydate3-mydate2;
diff13=mydate3-mydate1; run;
proc print data=  ds ;  
run; 
proc datasets library=work nodetails nolist noprint; 
delete ds  ; 
run; quit; 
/**/
%let num=9;
%TVE_analysis (pstrim=N, exclude_ibd=y, 
exposure= dpp4i , comparator= sglt2i,
ana_name=mITtv, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;

/*Look at the ID where IBD_ever=1*/

title "TVE";
proc means data=dsn STACKODS N NMISS sum MEAN STD MIN MAX Q1 MEDIAN Q3   ;
where delete_flag1=0;
class dpp4i switcher_flag;
var  time event; 
run;

 /* Taking a look at if switchers are deleted */
PROC SQL;
    /* Count rows of repeat ids */
    create table num_rows_fin as select ID, count(*) as num_rows_fin
    from dsn
    where (delete_flag1=0)
	group by ID;
    /* Add num_rows_fin */
    create table tve_dsn2 as select a.*, b.num_rows_fin 
    from dsn as a
    left join num_rows_fin as b
    on a.ID=b.ID;
QUIT;
proc datasets library=work nolist nodetails; 
delete  dsn ; 
run; quit; 
proc freq data=  tve_dsn2  ; 
tables         num_rows_fin * delete_flag1  *switcher_flag   / list missing; 
run; 
/*These are the exact same numbers*/
title "TVE";
proc means data= tve_dsn2 STACKODS sum MAXDEC=2;
where ibd_ever ne 1;
class delete_flag1;
var time  event; run;
title "ACNU"; 
proc means data= acnu_dsn STACKODS sum MAXDEC=2; 
class delete_flag1;
var time  event;run;

title "TVE";
proc means data= tve_dsn2 STACKODS sum MAXDEC=2; 
where ibd_ever ne 1;
class switcher_flag delete_flag1;
var time  event ; run;
proc means data= tve_dsn2 STACKODS sum MAXDEC=2; 
where ibd_ever ne 1;
class switcher_flag deleteobs ibddx_inductionperiod delete_zerofollowup;
var time   ; run;
title "ACNU"; 
proc means data= acnu_dsn STACKODS sum MAXDEC=2; 
class dpp4i delete_flag1;
var time  event;run;

PROC FREQ DATA=tve_dsn2;
tables switcher_flag*event/list missing;run;
PROC FREQ DATA=tve_dsn2;
TABLES dpp4i*num_rows_acnu*num_rows_tve*num_rows_fin*switcher_flag*delete_flag1/list missing;
RUN;   
PROC FREQ DATA=tve_dsn2;
where switcher_flag ne 1;
TABLES dpp4i*num_rows_acnu*num_rows_tve*num_rows_fin*switcher_flag*delete_flag1/list missing;
RUN;   
proc freq data= tve_dsn2   ; 
tables   switcher_flag*delete_flag1             / list missing; 
run; 


%let num=9;
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= sglt2i, 
ana_name=mITac, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;

data acnu_dsn; set dsn; run;

 proc means data =  acnu_dsn        
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 maxdec=2  ; 
where delete_flag1 ne 1;
class dpp4i;
var     event time        ; 
run; 
/*Writing draft code for the Table 4*/
/*** ACNU Row*/
/*For Dpp4i and comparator users column , the count of IBD and person time*/
%let dat=acnu_dsn;
/*%let dat=tve_dsn2;*/
data dsn ; set &dat; where ibd_ever ne 1 and delete_flag1 ne 1;run;
ods trace on / label listing;
ods output summary=tmpdpp4i;
 proc means data =  dsn        
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 maxdec=2  ; 
where delete_flag1 ne 1;
class dpp4i;
var     event time        ; 
run; 
proc print data=   tmpdpp4i;  
run; 
ods trace off;
/*incidence rates */
proc sort data=dsn; 
	by dpp4i; 
run;

%let exposure=dpp4i;
%LET event = event;
%LET logtimevar = logtime;
%LET timevar = time;
    proc genmod data=dsn;
	where delete_flag1 ne 1;
    by &exposure;
    * class id;
    model &event= /dist=poisson offset=&logtimevar maxiter=100000;
    * repeated subject=id;
    estimate 'rate' int 1/exp;
    ods output estimates=rate;
    run;
	proc print data= rate; run;
    Data rate(keep=&exposure rate);
    set rate;
    if Label='Exp(rate)';
    rate=compress(put((LBetaEstimate),6.1))||" ("||compress(put((LBetaLowerCL),6.1))||"-"||compress(put((LBetaUpperCL),6.1))||")";
    run;
	proc print data= rate; run;
/*unadjusted HR*/
*crude HR*;
ods output ParameterEstimates = crudehr;
Proc phreg data=dsn covsandwich(aggregate);
where delete_flag1 ne 1;
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
proc print data=crudehr   ;  
run; 

/*Adjusted aHR*/
*adjusted HR-&weight*;
%LET weight = smrw;
ods output ParameterEstimates =&WEIGHT;
proc phreg data=dsn covsandwich(aggregate);
where delete_flag1 ne 1;
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
proc print data=  smrw ;  
run; 
/****Now TVe*/

%let dat=tve_dsn2;
data dsn ; set &dat; where ibd_ever ne 1 and delete_flag1 ne 1;run;

ods output summary=events;
 proc means data =  dsn        
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 maxdec=2  ; 
where delete_flag1 ne 1;
class switcher_flag;
var     event         ; 
run; 
proc print data=  events ;  
run; 
ods output summary=persontime;
 proc means data =  dsn        
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 maxdec=2  ; 
where delete_flag1 ne 1;
class switcher_flag;
var     time         ; 
run;
proc print data=  persontime ;  
run; 
proc means data = acnu_dsn 
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ; 
var       time       ; 
run; 


/*incidence rates */
proc sort data=dsn; 
	by dpp4i; 
run;
%let exposure=dpp4i;
%LET event = event;
%LET logtimevar = logtime;
%LET timevar = time;
    proc genmod data=dsn;
	where delete_flag1 ne 1;
    by &exposure;
    * class id;
    model &event= /dist=poisson offset=&logtimevar maxiter=100000;
    * repeated subject=id;
    estimate 'rate' int 1/exp;
    ods output estimates=rate;
    run;
	proc print data= rate; run;
    Data rate(keep=&exposure rate);
    set rate;
    if Label='Exp(rate)';
    rate=compress(put((LBetaEstimate),6.1))||" ("||compress(put((LBetaLowerCL),6.1))||"-"||compress(put((LBetaUpperCL),6.1))||")";
    run;
	proc print data= rate; run;

	
/*unadjusted HR*/
*crude HR*;
ods output ParameterEstimates = crudehr;
Proc phreg data=dsn covsandwich(aggregate);
where delete_flag1 ne 1;
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
proc print data=crudehr   ;  
run; 

/*Adjusted aHR*/
*adjusted HR-&weight*;
%LET weight = smrw;
ods output ParameterEstimates =&WEIGHT;
proc phreg data=dsn covsandwich(aggregate);
where delete_flag1 ne 1;
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
proc print data=  smrw ;  
run; 
/*end of code */

title "TVE";
proc means data= tve_dsn2 STACKODS sum; 
class switcher_flag delete_flag1;
var time  event; run;
title "ACNU"; 
proc means data= acnu_dsn STACKODS sum; 
class dpp4i delete_flag1;
var time  event;run;

title "TVE";
proc means data= tve_dsn2 STACKODS sum;
where  delete_flag1 eq 0;
var time  event; run;
title "ACNU"; 
proc means data= acnu_dsn STACKODS sum;
where delete_flag1 eq 0; 
var time  event;run;

title "TVE";
proc means data=tve_dsn2 STACKODS N NMISS sum MEAN STD MIN MAX Q1 MEDIAN Q3  MAXDEC=2 ;
where delete_flag1=0;
class dpp4i switcher_flag;
var  time event; 
run;
title "ACNU";
proc means data=acnu_dsn STACKODS N NMISS sum MEAN STD MIN MAX Q1 MEDIAN Q3  MAXDEC=2 ;
where delete_flag1=0;
class dpp4i;
var  time event; 
run;


title "TVE";
proc means data=tve_dsn2 STACKODS N NMISS sum MEAN STD MIN MAX Q1 MEDIAN Q3   MAXDEC=2;
/*where delete_flag1=0;*/
class dpp4i switcher_flag;
var  time event; 
run;
title "ACNU";
proc means data=acnu_dsn STACKODS N NMISS sum MEAN STD MIN MAX Q1 MEDIAN Q3    MAXDEC=2;
/*where delete_flag1=0;*/
class dpp4i;
var  time event; 
run;
/*Comparing the person time and way that it is counted between TVE and ACNU */
/*what is the 33988 people's swithcer=3 in TVE*/
proc sql;
create table comp3_ids as select distinct id as tve3_ids, time0 as tve_time0, time as tve_time, event as tve_event, 
switcher_flag
from tve_dsn2
where switcher_flag=3
; 
quit;
/*Are those 33988 people found in the acnu*/
proc sql; 
create table overlap as select a.id as acnu_ids, b.tve3_ids, a.dpp4i,a.time0 as acnu_time0, b.tve_time0
, a.time as acnu_time, a.event as acnu_event, 
b.tve_time, b.tve_event, b.switcher_Flag
from (select * from acnu_dsn where dpp4i=0) as a
inner join 
comp3_ids as b
on a.id = b.tve3_ids;
quit;
/*they overlap and their persontime is the exact same. the puredpp4i and the pureswitchers are not the issue*/
proc means data =  overlap
STACKODS N NMISS sum MEAN STD MIN MAX Q1 MEDIAN Q3 MAXDEC=2  ;
class switcher_flag dpp4i; 
var    acnu_event acnu_time    tve_event tve_time      ; 
run; 
proc freq data=    tve_dsn2; 
tables           dpp4iinitiator_crohns_bl*ibd_ever    sglt2iinitiator_crohns_bl / list missing; 
run; 


/*This means that the switchers are the issue*/
/*Compare the switchers ids*/
proc sql;
create table comp21_ids
as select id as tve_id, switcher_flag, time0 as tve_time0, filldate2 as tve_filldate2, switchAugmentDate as tve_switchaugdt, 
dpp4i_filldate2, enddate as tve_enddate, event as tve_event, time as tve_time, delete_flag1 as tve_deleteflag /*ibd_ever, ibd1_dt, ibd1_code,ibd_bl, IBD_bc, 
IBD_gc,dpp4iinitiator_ibd_ever ,sglt2iinitiator_ibd_ever*/
from tve_dsn2
where switcher_flag in (1,2) and ibd_ever ne 1
	;
quit;
proc sql;
create table overlapswitchers as
select distinct a.*
from acnu_dsn as a
inner join 
comp21_ids as b
on a.id=b.tve_id;
quit;
proc freq data= overlapswitchers   ; 
tables  dpp4i              / list missing; 
run; 
proc means data =  overlapswitchers
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 MAXDEC  ; 
var  time event            ; 
run; 
proc sql;
create table whyswitch as 
select a.*, b.time0 as acnu_time0, b.filldate2 as acnu_filldate2, b.switchAugmentdate as acnu_switchaugdt,
b.enddate as acnu_enddate, b.event as acnu_event, b.time as acnu_time, b.delete_flag1 as acnu_deleteflag
from comp21_ids as a
left join 
overlapswitchers as b
on a.tve_id=b.id
order by a.tve_id, a.switcher_flag;
quit;
data whyswitch;
set whyswitch; 
tve_time1=365.25*tve_time;
tve_time2=(tve_enddate-(tve_filldate2+180)+0.5);
acnu_time1=365.25*acnu_time;
acnu_time2=(acnu_enddate-(acnu_filldate2+180)+1);
run;
data tmptest; 
set whyswitch; where tve_deleteflag eq 1;run;
/* Find the IDs in tve_dsn2 where delete_flag1 = 1 and switcher_flag in (1,2)*/
proc sql;
CREATE TABLE tvedelete as 
select distinct id from tve_dsn2
where delete_flag1=1 and switcher_flag in (1,2);
run;
quit;
/*553 unique ids*/
proc sql; 
create table testdelete as
select a.* 
from whyswitch as a
inner join tvedelete as b
on a.tve_id = b.id;
quit;
proc freq data= testdelete   ; 
tables    switcher_flag*  tve_deleteflag  *acnu_deleteflag        / list missing; 
run; 
data test; set testdelete; where acnu_deleteflag eq 1 and tve_deleteflag eq 1;run;
proc print data=  tve_dsn2 ;  where id eq '11003~21013';run;


title "ACNU"; 
proc freq data=    whyswitch; 
tables dpp4iinitiator_ibd_ever sglt2iinitiator_ibd_ever        ibd_ever       / list missing; 
run; 
PROC SQL;
QUIT;
/*proc print data=whyswitch (obs=10);where tve_id eq '11002~19604'; run; */
proc means data= whyswitch STACKODS sum nmiss maxdec=2; 
class switcher_flag;
var acnu_time tve_time tve_time1 tve_time2 acnu_time1  acnu_event tve_event;run;

/*end today*/
data dsn; 
    set notrim_tve;
		/* where entry=date of 2nd prescription */
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
	fouryearout =fouryear  + &latency;
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

        /* 01 May 2024: checked that current code correctly  incorporates how &outtime is not used 
			among those who were on the comparator (non-dpp4i) who then subsequently switched to dpp4i*/
    
        /* The implementation of 'Initial Treatment' a la Abrahami */
        /* for the initiators of the comparator who switch from comparator to exposure: */
        *if the startdate is filldate2, the date of second prescription;
        %if %upcase(&intime) eq FILLDATE2 %then %do;
            if &exposure =0 and switcher_flag=2 /*switchAugmentDate ne .*/ then do;
/*			if &exposure =0 and switchAugmentDate ne . then do;*/
                enddate= min(&ibd_def._dt, dpp4i_filldate2 +&induction, 
						&outtime /*7/29/2024 Tian & Jeany added this, fixing the error that comparator >3yr when using max 3-yr FUP*/
						);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne .    then event=1; else event=0;
                end;
           %end;
        *if the startdate is time0, ie the date of first prescription;
        %if %upcase(&intime) ne FILLDATE2 %then %do;
            if &exposure =0 and switcher_flag=2 /*switchAugmentDate ne .*/ then do;
                enddate= min(&ibd_def._dt, switchAugmentDate+&induction,
							 &outtime /*7/29/2024 Tian & Jeany added this, fixing the error that comparator >3yr when using max 3-yr FUP*/
							 );
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne .    then event=1; else event=0;
                end;
        %end;

        /* IT analysis  */
        %if %upcase(&type) eq IT %then %do;

        /* for dpp4i initiators who were prevalent users of the comparator */
            else if &exposure =1 and switcher_flag=1/*excludeflag_prevalentuser eq 1*/ then do;
                enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
                if enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
                end;
            /* for initiators of dpp4i who never switched from the comparator */
            else if &exposure=1 and switcher_flag=0 /*excludeflag_prevalentuser ne 1*/ then do;
                enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
            end;
            /* for initiators of comparator drug who never switched */
            else if &exposure=0 and switcher_flag=3 /*switchAugmentDate eq .*/ then do;
                enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
            end;
        %end;
        /* AT analysis */
        /*%else %if %upcase(&type) eq AT %then %do;*/
            /* for dpp4i initiators who were prevalent users of the comparator */
            /*else if &exposure =1 and excludeflag_prevalentuser eq 1 then do;
                enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt, endofdrug);
                if enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
                end;*/
            /* for initiators of dpp4i who never switched from the comparator */
/*           else if &exposure=1 and excludeflag_prevalentuser ne 1 then do;*/
/*                enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt, endofdrug);*/
/*                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;*/
/*            end;*/
            /* for initiators of comparator drug who never switched */
         /*   else if &exposure=0 and switchAugmentDate eq . then do;
                enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt, endofdrug);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
            end;
        %end; */
        
        *formatting etc; 
        format enddate date9. ; 
		label enddate ="Date min of (&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt), or switch/augment date for comparators";
        *"Date min of (death_dt, endstudy_dt, dbexit_dt, LastColl_Dt)";
        enddatedelete=min(enddt, endstudy_dt, &outtime);  
        
        *flag to remove individuals who did not reach the induction period for followup ;
        IF indexdate <= enddatedelete<=(&intime + &induction) then deleteobs=1; 			else deleteobs=0;
        label deleteobs            ="Flag to remove individuals who did not reach the induction period for followup";
        IF indexdate <= &ibd_def._dt <=(&intime + &induction) then IBDdx_inductionperiod=1; else IBDdx_inductionperiod=0;
        label IBDdx_inductionperiod="Flag for individuals with IBD diagnosis within the induction period";
        * followup time;
        time=(enddate-(&intime.+&induction)+1)/365.25;
        time_drugdur=(min(rxchange, enddate)-(indexdate+1))/365.25;    
		*flag for zero followup;
        if time>0 then logtime=(log(time/100000))  ;         
		else time=.;
        if time=. then delete_zerofollowup=1; else delete_zerofollowup=0;
        label time = "person-years" time_drugdur= "duration of treatment";
        label logtime="log(person-years)";
        *flag for individuals with IBD diagnosis ever (IBD before time 0) or IBD post-index date without regard to the induction period; 
        if indexdate<= &ibd_def._dt then IBD_postindex=1; else IBD_postindex=0;
		*flag for any of the deletion criteria;
		if deleteobs=1 or IBDdx_inductionperiod=1 or delete_zerofollowup=1 then delete_flag1=1; else delete_flag1=0;
		label delete_flag1="Flag for people who did not reach induction pd deleteobs=1 and IBDdx_inductionperiod=1 and delete_zerofollowup=1";
	RUN;
proc print data=   tmp_counts;  
run; 
/* Taking a look at if switchers are deleted */
PROC SQL;
    /* Count rows of repeat ids */
    create table num_rows_fin as select ID, count(*) as num_rows_fin
    from dsn
    where (delete_flag1=0)
	group by ID;
    /* Add num_rows_fin */
    create table dsn2 as select a.*, b.num_rows_fin 
    from dsn as a
    left join num_rows_fin as b
    on a.ID=b.ID;
QUIT;
PROC FREQ DATA=dsn2;
TABLES dpp4i*num_rows_acnu*num_rows_tve*num_rows_fin*switcher_flag*delete_flag1/list missing;
RUN;

DATA dsn2; 
set dsn2; 
		*flag for making a new switcher flag;
		switcher_flag_fin=switcher_flag;
		if switcher_flag=2 and dpp4i=0 and num_rows_tve=2 and num_rows_fin=1 and delete_flag1=0 then switcher_flag_fin=3;
		if switcher_flag=1 and dpp4i=1 and num_rows_tve=2 and num_rows_fin=1 and delete_flag1=0 then switcher_flag_fin=88; *delete switchers whose comparator person time was had delete_flag1=1 ;
run;


/* Check exclusions here */
proc freq data=   dsn2 ; 
tables       delete_flag1*switcher_flag * switcher_flag_fin/ list missing; 
run; 

PROC FREQ DATA=dsn2;
TABLES dpp4i*num_rows_acnu*num_rows_tve*num_rows_fin*switcher_flag*delete_flag1/list missing;
RUN;
PROC FREQ DATA=dsn2;
WHERE deleteobs eq 0 and IBDdx_inductionperiod eq 0 and delete_zerofollowup eq 0;
TABLES dpp4i*num_rows_acnu*num_rows_tve*num_rows_fin*switcher_flag*deleteobs*IBDdx_inductionperiod*delete_zerofollowup /list missing;
RUN;


/*===================================*\
2024-12-29 code- for testing macro that recreates Table 1 untrimmed for TVE cohorts
\*===================================*/
/* Rewritten psweighting_Ab macro  */
%include "D:\Externe Projekte\UNC\wangje\prog\sas\17_testmacropsweighting_Ab.sas";

/*need to do All avaialbe lookback to replicate Abrahami study, also using 1year lookback has % is not close to % by Abrahami!!!!*/
%LET tablerowvarsi = age
sex entry_year   

diff_1st_2ndrx  /* added to table 1 rows, NOT in PS trimming model */

bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2 
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever  

oAntGLP_ever dpp4i_ever sglt2i_ever TZD_ever su_ever 

bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 

psorp_ever vasc_ever 
RhArth_ever SjSy_ever sLup_ever 
IBD_ever crohns_ever ucolitis_ever
;
/******************** in the PS model *****************************/
%LET interactions =     /* add interaction */ ;

/*7/21/2024 Jeanny & Tian maybe using 1-year LL for drugs*/
%LET basevars =  age|age
sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever 

bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 

psorp_ever vasc_ever 
RhArth_ever SjSy_ever sLup_ever ;

/*%let basemodelvars= &basevars. &interactions. ;*/
/******************** in the PS model *****************************/
*  %let addedmodelvars= &addedDPP4ivSU;
*  %LET exposure = dpp4i;
*  %LET comparator = su;
*  %LET refyear = 2015;

%LET addedDPP4ivSU = oAntGLP_1yrlookback sglt2i_1yrlookback TZD_1yrlookback;
%let weight=smrw;
%let addedmodelvars= &addedDPP4ivSU;
%let refyear = 2015;
%psweighting_Ab( exposure= dpp4i ,
comparator= SU, 
weight= smrw, 
/******************** in the PS model *****************************/
addedmodelvars= &addedDPP4ivSU, 
basemodelvars= &basevars. &interactions. ,
/******************** in the PS model *****************************/
tablerowvars= &tablerowvarsi,
refyear = 2015, 
save= Y);
proc print data= temp.Abexclusions_015_dpp4i_SU;RUN;

/**Continuing with the other comparators */

/* TZD */
%LET addedDPP4ivTZD = oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback chf_ever;
%let addedmodelvars= &addedDPP4ivtzd;
%psweighting_Ab(exposure=dpp4i,
comparator=TZD, 
weight=smrw,
addedmodelvars= &addedDPP4ivTZD,
basemodelvars= &basevars. &interactions,
tablerowvars=&tablerowvarsi chf_ever,
refyear=2015,
save=Y
);
proc print data= temp.Abexclusions_015_dpp4i_tzd;RUN;

/* SGLT2i */
%LET addedDPP4ivSGLT2i = oAntGLP_1yrlookback su_1yrlookback TZD_1yrlookback;
%let addedmodelvars= &addedDPP4ivsglt2i;
%psweighting_Ab(exposure=dpp4i,
comparator=SGLT2i, 
weight=smrw,
addedmodelvars=&addedDPP4ivSGLT2i,
basemodelvars= &basevars. &interactions,
tablerowvars=&tablerowvarsi,
refyear=2015,
save=Y
);
proc print data= temp.Abexclusions_015_dpp4i_sglt2i;RUN;
/* end */

/* Other: */
/* Looking at some IDs */
/* options compress=no; */
title "a.notrim_dpp4i_SU_1yrlb";
PROC SQL outobs=10;
    SELECT ID
    FROM a.notrim_dpp4i_SU_1yrlb
    ORDER BY ID desc ;
QUIT;
PROC SQL;
    /* should be 136143*/
    SELECT COUNT(DISTINCT ID) AS unique_id_count
    from a.notrim_dpp4i_SU_1yrlb;
QUIT;
/* See if other ID's are truncated? */
title "RAW.DPP4I_TRTMT";
PROC SQL outobs=10;
    SELECT ID
    FROM RAW.DPP4I_TRTMT
    ORDER BY ID desc ;
QUIT;
title "TEMP.DPP4I_USEPERIODS";
PROC SQL outobs=10;
    SELECT ID
    FROM TEMP.DPP4I_USEPERIODS
    ORDER BY ID desc ;
    QUIT;
title "TEMP.NEWUSERS_DPP4I_SU";
PROC SQL outobs=10;
    SELECT ID
    FROM TEMP.NEWUSERS_DPP4I_SU
    ORDER BY ID desc ;
    QUIT;
title "TEMP.ALLMERGED_DPP4I_SU";
PROC SQL outobs=10;
    SELECT ID
    FROM TEMP.ALLMERGED_DPP4I_SU
    ORDER BY ID desc ;
    QUIT;
title "TEMP.ALLMERGED_DPP4I_SU_1YRLB";
PROC SQL outobs=10;
    SELECT ID
    FROM TEMP.ALLMERGED_DPP4I_SU_1YRLB
    ORDER BY ID desc ;
    QUIT;
/*===================================*\
2024-12-27 code
\*===================================*/
        
/* code from 2024-12-27         */

proc sort data= a.abrahami_Notrim_dpp4i_su;by id;run;
DATA testswitcher;
    merge 
        a.Abrahami_Notrim_dpp4i_su 
        id_counts;
    by ID; 
    /* Try to recreate switcher2 flag */
    if (dpp4i=1 and num_rows2=1) then switcher2=0; /* Pure dpp4i */
    else if (dpp4i=1 and num_rows2=2) then switcher2=1; /* switcher2 to dpp4i */
    else if (dpp4i=0 and num_rows2=1) then switcher2=3; /* Pure comparator */
    else if (dpp4i=0 and num_rows2=2) then switcher2=2; /* comparator who switched */
    else switcher2=.; /* missing */

    /* Create a flag for whether dpp4i_filldate2 ne . */
    if dpp4i_filldate2 ne . then dpp4i_filldate2_flag=1;
    else dpp4i_filldate2_flag=.;
RUN;
*keeping only IDs with overlap;
PROC SQL;
    create table id_overlap as select id from id_counts where num_rows=2;
QUIT;

PROC SQL;
    /* Taking only the DPP4i switchers who have a duplicate row for SU */
    /* 21673 */
    create table dpp4i_switcher_ids as 
        select distinct ID from testswitcher
        where switcher2=1 and keepflag_prevalentuser=1;
    /* 21673 */
    create table su_switcher as 
        select a.id, a.indexdate,
            case when b.ID is not null then 1 else 0 end as suswitcher_flag
        from (select * from testswitcher2 where switcher2=2) as a
        left join dpp4i_switcher_ids as b
        on a.ID=b.ID;
    create table testswitcher2 as 
        select a.*, b.suswitcher_flag from testswitcher2 as a 
        left join su_switcher as b
        on a.ID=b.ID and a.indexdate=b.indexdate;
QUIT;



/*===================================*\
2024-12-27 code 
\*===================================*/

/* 2024-12-27 code  */
%LET tablerowvarsi = age
sex entry_year   

diff_1st_2ndrx  /* added to table 1 rows, NOT in PS trimming model */

bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2 
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever  

oAntGLP_ever dpp4i_ever sglt2i_ever TZD_ever su_ever 

bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 

psorp_ever vasc_ever 
RhArth_ever SjSy_ever sLup_ever 
IBD_ever crohns_ever ucolitis_ever
;

/* Testing table comparing pre-switch to post-switch */
/* Question about who are switchers compared to? */
/* Based on switcher variable created in line 169 of %getCohort_Ab() macro from program 17_RnR_TVEanalysismacros */
/* 
0= pure exposure (dpp4i)
1= switcher to dpp4i (dpp4i person time after switch from comparator)
2= comparator (comparator person time before switching to DPP4i later) 
3= pure comparator 
4= early switcher w/o filldate2
5= reverse switcher w/o filldate2
6= pure comparator w/o filldate2*/

/* Testing frequencies  */
PROC FREQ DATA=a.Abrahami_Notrim_dpp4i_su ;
TABLES dpp4i*switcher /list missing; *switcher=0, 1,2, or 3;
RUN;
PROC FREQ DATA=a.Abrahami_Notrim_dpp4i_su ;
TABLES dpp4i*switcher*keepflag_prevalentuser /list missing; *switcher=0, 1,2, or 3;
RUN;

/* Looking at the switcher=. */
proc print data=a.Abrahami_Notrim_dpp4i_su (obs=20);
    where switcher eq .;
    var dpp4i switcher indexdate filldate2  switchAugmentDate  dpp4i_filldate2;
run;

/* Getting repeated IDs from ACNU */
PROC SQL;
    create table id_counts as select ID, count(*) as num_rows2 
    from a.notrim_dpp4i_SU_1yrlb
    group by ID;
QUIT;

PROC FREQ DATA=id_counts;
TABLES num_rows2 /list missing; /* how many unique IDs would have num_rows=2? */
RUN;

/* Try recreating switcher flag? */
PROC SQL;
    create table id_counts as select ID, count(*) as num_rows2 
    from a.Abrahami_Notrim_dpp4i_su 
    group by ID;
QUIT;

PROC FREQ DATA=id_counts;
TABLES num_rows2 /list missing; /* how many unique IDs would have num_rows=2? */
RUN;

proc sort data= a.abrahami_Notrim_dpp4i_su;by id;run;
DATA testswitcher;
    merge 
        a.Abrahami_Notrim_dpp4i_su 
        id_counts;
    by ID; 

    /* Try to recreate switcher2 flag */
    if (dpp4i=1 and num_rows2=1) then switcher2=0; /* Pure dpp4i */
    else if (dpp4i=1 and num_rows2=2) then switcher2=1; /* switcher2 to dpp4i */
    else if (dpp4i=0 and num_rows2=1) then switcher2=3; /* Pure comparator */
    else if (dpp4i=0 and num_rows2=2) then switcher2=2; /* comparator who switched */
    else switcher2=.; /* missing */

    /* Create a flag for whether dpp4i_filldate2 ne . */
    if dpp4i_filldate2 ne . then dpp4i_filldate2_flag=1;
    else dpp4i_filldate2_flag=.;
RUN;

/* Check whether switcher and switcher2 are the similar or different */
PROC FREQ DATA=testswitcher;
/* Should switcher2=2 and switcher2=1 have same counts?~23657?*/
TABLES switcher switcher2 /list missing;
TABLES switcher*switcher2 /list missing;
RUN;
proc freq data=testswitcher;
TABLES dpp4i*switcher2 /list missing;
TABLES dpp4i*num_rows2 /list missing;
TABLES switcher*dpp4i_filldate2_flag/list missing;
TABLES switcher2*dpp4i_filldate2_flag/list missing;
RUN;
/* Check whether keepflag_prevalentuser would be the same as switcher2=1? */
PROC FREQ DATA=testswitcher;
TABLES  switcher2*keepflag_prevalentuser /list missing;
RUN;
PROC FREQ DATA=testswitcher;
TABLES num_rows num_rows2 /list missing;
RUN;

proc print data=testswitcher (obs=20);
    where switcher eq .;
    var dpp4i switcher indexdate filldate2  switchAugmentDate  dpp4i_filldate2;
run;
proc print data=testswitcher (obs=20);
    where switcher2 = 0 and keepflag_prevalentuser=1;
    var dpp4i switcher indexdate filldate2  switchAugmentDate  dpp4i_filldate2;
run;
proc print data=testswitcher (obs=20);
    where switcher2 = 1 and keepflag_prevalentuser=.;
    var dpp4i switcher indexdate filldate2  switchAugmentDate  dpp4i_filldate2;
run;

/* If the above are not consistent, then keep only overlap */
*keeping only overlap ids?;
PROC SQL;
    create table id_overlap as select id from id_counts where num_rows=2;
QUIT;

/* (1) If the id_overlap < excludeflag_prevalentuser*/
PROC SQL;
    create table prevalentuser as
    select * from testswitcher
    where keepflag_prevalentuser=1;
QUIT;
PROC SQL;
    create table dpp4i_switcher as 
    select a.* from 
    prevalentuser as a
    inner join id_overlap as b
    on a.ID=b.ID ; 
QUIT;
PROC SQL;
    create table testswitcher2 as
    /* remove dpp4i switchers */
    select * from testswitcher where keepflag_prevalentuser=0
    union all corresponding
    /* stacking on top the dpp4i switchers with overlap */
    select * from dpp4i_switcher;
QUIT;
PROC FREQ DATA=testswitcher2;   
TABLES switcher2*keepflag_prevalentuser /list missing;
RUN;


/* (2) if id_overlap > excludeflag_prevalentuser */
PROC SQL;
    /* Taking only the DPP4i switchers who have a duplicate row for SU */
    /* 21673 */
    create table dpp4i_switcher_ids as 
        select distinct ID from testswitcher2
        where switcher2=1 and keepflag_prevalentuser=1;
    /* 21673 */
    create table su_switcher as 
        select a.id, a.indexdate,
            case when b.ID is not null then 1 else 0 end as suswitcher_flag
        from (select * from testswitcher2 where switcher2=2) as a
        left join dpp4i_switcher_ids as b
        on a.ID=b.ID;
    create table testswitcher2 as 
        select a.*, b.suswitcher_flag from testswitcher2 as a 
        left join su_switcher as b
        on a.ID=b.ID and a.indexdate=b.indexdate;
QUIT;


PROC FREQ DATA=su_switcher;
TABLES switcher_flag /list missing;
RUN;

PROC FREQ DATA=testswitcher2;       
TABLES switcher2*keepflag_prevalentuser*suswitcher_flag /list missing;
RUN;


/* Web Table 4: Key patient characteristics between switchers and non-switchers in Dipeptidyl Peptidase-4 inhibitors (DPP4i) group in each comparison.*/
data tmptable1; 
    set testswitcher; 
    /* Among the same person, compare Preswitch (2) to post-switch (1) */
        *where switcher in (1,2);
    /* among dpp4i=1, Pure dpp4i (0) vs those who switched to dpp4i (1) */
        where switcher in (0,1);
    /* among dpp4i=0, Pure comparator (2) vs. comparator who later switched to dpp4i (3) */
        *where dpp4i in (2,3);
        format switcher switcherf.;
    run;
/* switcher*/
proc format;
value switcherf
0="puredpp4i"
1="switcher";
run;
options orientation=landscape nodate nonumber nocenter;
%table1(inds= tmptable1, 
    colVar= switcher, /* or switcher */
    rowVars= &tablerowvarsi, wgtVar= , maxLevels=16, outfile= , title= , cellsize=5);
proc print data=final;
run;


/*
ods escapechar='~' ;
ods rtf file="&toutPath./Tmpswitchtable_&todaysdate..rtf";
    proc print data=final noobs label; 
    var row &exposure &comparator sdiff &comparator._wgt sdiff_wgt; run;
ods rtf close;
*/

/* 2024-12-21- rerun for untrimmed cohort  */
%LET addedDPP4ivTZD = oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback chf_ever;
%let addedmodelvars= &addedDPP4ivtzd;
%psweighting_Ab(exposure=dpp4i,
comparator=TZD, 
weight=smrw,
addedmodelvars= &addedDPP4ivTZD,
basemodelvars= &basevars. &interactions,
tablerowvars=&tablerowvarsi chf_ever,
refyear=2015,
save=Y
);


%LET addedDPP4ivSGLT2i = oAntGLP_1yrlookback su_1yrlookback TZD_1yrlookback;
%let addedmodelvars= &addedDPP4ivsglt2i;
%psweighting_Ab(exposure=dpp4i,
comparator=SGLT2i, 
weight=smrw,
addedmodelvars=&addedDPP4ivSGLT2i,
basemodelvars= &basevars. &interactions,
tablerowvars=&tablerowvarsi,
refyear=2015,
save=Y
);

/*7/13/2024 some errors identified*/
%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);


/* 2024-12-21- JW: Running the rest of the lines below are not necessary */
ods _all_ close;
goptions reset=all;quit;
/* Print flowcharts and Tables */
*Printing outputs for each ACNU cohort;
ods excel file="&toutpath./Abrahami_T1_compiled_&todaysdate..xlsx"
    options (
        Sheet_interval="NONE"
        embedded_titles="NO"
        embedded_footnotes="NO"
    );
    *dpp4i vs su;
ods excel options(sheet_name="DPP4i_SU"  sheet_interval="NOW");
    proc print data=table1_dpp4ivSU noobs label; var row dpp4i_pretrim su_pretrim sdiff_pretrim dpp4i su sdiff su_wgt sdiff_wgt; run;
	proc contents data=table1_dpp4ivsu;run;
	proc print data=table1_dpp4ivsu;run;
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
    proc print data=table1_dpp4ivTZD noobs label; var row dpp4i_pretrim tzd_pretrim sdiff_pretrim dpp4i tzd sdiff tzd_wgt sdiff_wgt; run;
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
    proc print data=table1_dpp4ivSGLT2i noobs label; var row dpp4i_pretrim sglt2i_pretrim sdiff_pretrim dpp4i sglt2i sdiff sglt2i_wgt sdiff_wgt; run;
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


/* endregion //!SECTION */



%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);
