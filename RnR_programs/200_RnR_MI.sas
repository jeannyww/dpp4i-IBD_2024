options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=testMI, savelog=N, dataset=dataname);

/*===================================*\
STEP 0: Getting data 
\*===================================*/
%LET exposure = dpp4i  ;
%LET comparator = tzd;
%LET type = IT;
%LET induction = 180;   
%LET latency = 180;
%LET ibd_def = ibd1;
%LET intime = filldate2;
%LET outtime = '31Dec2022'd;

/* TVE data */
data dsntve_&exposure._&comparator.; 
	set a.Abrahami_Notrim_&exposure._&comparator.;  oneyear =&intime +365.25;
	twoyear  =&intime +730.5;
	threeyear=&intime +1095.75;
	fouryear =&intime +1460; 
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

        *if the startdate is filldate2, the date of second prescription;
            if &exposure =0 and switcher_flag=2 then do;
/*            if &exposure =0 and switchAugmentDate ne . then do;*/
                enddate= min(&ibd_def._dt, dpp4i_filldate2 +&induction, 
						&outtime /*7/29/2024 Tian & Jeany added this, fixing the error that comparator >3yr when using max 3-yr FUP*/
						, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt
						);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
                end;

        /* IT analysis  */
        /* for dpp4i initiators who were prevalent users of the comparator */
/*            else if &exposure =1 and excludeflag_prevalentuser eq 1 then do;*/
		else if &exposure =1 and switcher_flag=1/*excludeflag_prevalentuser eq 1*/ then do;
                enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
                if enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
                end;
            /* for initiators of dpp4i who never switched from the comparator */
/*            else if &exposure=1 and excludeflag_prevalentuser ne 1 then do;*/
		else if &exposure=1 and switcher_flag=0 /*excludeflag_prevalentuser ne 1*/ then do;
                enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
            end;
            /* for initiators of comparator drug who never switched */
/*            else if &exposure=0 and switchAugmentDate eq . then do;*/
		else if &exposure=0 and switcher_flag=3 /*switchAugmentDate eq .*/ then do;
                enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
            end;
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
/*		time=(enddate-(&intime.+&induction)+1)/365.25;*/
		if switcher_flag in (0,3,2) then time=(enddate-(&intime.+&induction)+1)/365.25;
		else if switcher_flag  eq 1 then time=(enddate-(&intime.+&induction))/365.25; *added so that one extra day is not doubly counted for switchers;
		* drug duration;
        time_drugdur=(min(rxchange, enddate)-(indexdate+1))/365.25;    
    	*log time and mising time;
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
format dpp4i;
/*Reiterate coding just to make sure missing and imputed variablesare correctly created*/
        hba1c_cat=.;
        *if hba1ctime<365.25 then do;
            if hba1c eq . then hba1c_cat=.; 
            else if hba1c le 53 then hba1c_cat=1; /* 7% ~ 53 mmol per mol  */
            else if hba1c gt 53 and hba1c le 64 then hba1c_cat=2 ; /* 8% ~ 64 mmol per mol */
            else if hba1c gt 64 then hba1c_cat=3; /* gt 8% or 64 mmol per mol  */
            *end;
        hba1c_cat2= hba1c_cat; 
            if hba1c_cat eq . then hba1c_cat2=4;
            format hba1c_cat2 hba1cf.; 
        /* BMI */
        bmi_cat=.;
        *if bmitime<365 then do;
		* change to all year lookback;
			if bmi eq . then bmi_cat=.;
            else if bmi<25 then bmi_cat=1;
            else if bmi ge 25 and bmi lt 30 then bmi_cat=2;
            else if bmi ge 30 then bmi_cat=3;
            *end;
            bmi_cat2= bmi_cat; 
            if bmi_cat eq . then bmi_cat2=4;
            format bmi_cat2 bmif.;
/*Creating numeric versions of smoke and bmi where u/unknown is coded as missing*/
/*ordering by highest frequency as the 'reference' for smoking*/
/*'u'='Unknown'= . 
's'='Current'= 3
'n'='Never'= 2
'x'='Past/quit' = 1 ;*/
smoke_miss=.; 
if smoke="u" then smoke_miss=.; 
else if smoke="s" then smoke_miss=3; 
else if smoke="n" then smoke_miss=2;
else if smoke="x" then smoke_miss=1;

/*ordering by highest frequency as the 'reference' for alcohol*/
/*'u'='Unknown'= . 
'c'='Current' = 1
'n'='Never'= 2
'x'='Past/quit' = 3 ;*/
alc_miss=.; 
if alc="u" then alc_miss=.; 
else if alc="c" then alc_miss=1 ;
else if alc="n" then alc_miss=2; 
else if alc="x" then alc_miss=3;
/*Creating a square of age*/
agesquare=age*age;
/*Numeric sex*/
sex_num=.; 
if sex='f' then sex_num=1; 
else if sex='m' then sex_num=0;
run;
data dsntve_&exposure._&comparator.; set dsntve_&exposure._&comparator.; 
if delete_flag1=1 then delete;
/*Delete dpp4i switchers whose delete_flag1=0 but whose comparator switcher row was deleted (delete_flag=1) */ 
if ibd_ever=1 then delete;
format dpp4i; run;


/*Testing variable creation*/
data test; 
	set dsntve_&exposure._&comparator. ;run;
proc freq data=  test  ; 
tables   smoke*smoke_miss alc*alc_miss    delete_flag1 ibd_ever         / list missing; 
run; 
proc freq data=test  ; 
tables          
/*Variables that I had coded*/
hba1c_Cat hba1c_cat2 bmi_cat bmi_cat2  alcohol_cat smoke_cat 
/*Original categorical variables*/
alc  smoke/ list missing; 
format alc smoke $statusf. hba1c_cat  hba1cf. bmi_cat bmif.;
run; 
proc means data =  test
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ; 
class bmi_cat2;
/*Original continuous variables*/
var        bmi      ; 
run; 
proc means data =  test
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ; 
class hba1c_cat2;
/*Original continuous variables*/
var        hba1c      ; 
run; 
/*The missing variables we want to imput are hba1c, bmi, smoke_miss, alc_miss*/

/*===================================*\
ACNU data 
\*===================================*/

/* ACNU data */
data dsnac_&exposure._&comparator.; 
	set a.notrim_&exposure._&comparator._1yrlb; 
	format dpp4i;
    /*	Dummy tve variables*/
	switcher_flag=99;
	dpp4i_filldate2=99;
    /* Time variables */
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

    /* Initial Treatment */
        enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
        format enddate date9. ; label enddate ="Date min of (&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt)";
        *"Date min of (&ibd_def._dt,death_dt, endstudy_dt, dbexit_dt, LastColl_Dt)";
 
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
	if time=. then delete_zerofollowup=1; else delete_zerofollowup=0;
    label time = "person-years" time_drugdur= "duration of treatment";        
    label logtime="log(person-years)";

    *flag for individuals with IBD diagnosis ever (IBD before time 0) or IBD post-index date without regard to the induction period; 
    IBD_ever= max(crohns_ever, ucolitis_ever);  
    label IBD_ever="Ever IBD diagnosis";
    if indexdate<= &ibd_def._dt then IBD_postindex=1; else IBD_postindex=0;
	*flag for any of the deletion criteria;
		if deleteobs=1 or IBDdx_inductionperiod=1 or delete_zerofollowup=1 then delete_flag1=1;
	else delete_flag1=0;
		label delete_flag1="Flag for people who did not reach induction pd deleteobs=1 and IBDdx_inductionperiod=1 and delete_zerofollowup=1";
/*removing the dpp4i format for the summary macro*/
format dpp4i;
/*Reiterate coding just to make sure missing and imputed variablesare correctly created*/
        hba1c_cat=.;
        *if hba1ctime<365.25 then do;
            if hba1c eq . then hba1c_cat=.; 
            else if hba1c le 53 then hba1c_cat=1; /* 7% ~ 53 mmol per mol  */
            else if hba1c gt 53 and hba1c le 64 then hba1c_cat=2 ; /* 8% ~ 64 mmol per mol */
            else if hba1c gt 64 then hba1c_cat=3; /* gt 8% or 64 mmol per mol  */
            *end;
        hba1c_cat2= hba1c_cat; 
            if hba1c_cat eq . then hba1c_cat2=4;
            format hba1c_cat2 hba1cf.; 
        /* BMI */
        bmi_cat=.;
        *if bmitime<365 then do;
		* change to all year lookback;
			if bmi eq . then bmi_cat=.;
            else if bmi<25 then bmi_cat=1;
            else if bmi ge 25 and bmi lt 30 then bmi_cat=2;
            else if bmi ge 30 then bmi_cat=3;
            *end;
            bmi_cat2= bmi_cat; 
            if bmi_cat eq . then bmi_cat2=4;
            format bmi_cat2 bmif.;
/*Creating numeric versions of smoke and bmi where u/unknown is coded as missing*/
/*ordering by highest frequency as the 'reference' for smoking*/
/*'u'='Unknown'= . 
's'='Current'= 3
'n'='Never'= 2
'x'='Past/quit' = 1 ;*/
smoke_miss=.; 
if smoke="u" then smoke_miss=.; 
else if smoke="s" then smoke_miss=3; 
else if smoke="n" then smoke_miss=2;
else if smoke="x" then smoke_miss=1;

/*ordering by highest frequency as the 'reference' for alcohol*/
/*'u'='Unknown'= . 
'c'='Current' = 1
'n'='Never'= 2
'x'='Past/quit' = 3 ;*/
alc_miss=.; 
if alc="u" then alc_miss=.; 
else if alc="c" then alc_miss=1 ;
else if alc="n" then alc_miss=2; 
else if alc="x" then alc_miss=3;
/*Creating a square of age*/
agesquare=age*age;
/*Numeric sex*/
sex_num=.; 
if sex='f' then sex_num=1; 
else if sex='m' then sex_num=0;
RUN;
/*/*data dsnac_&exposure._&comparator.; set dsnac_&exposure._&comparator.; */*/
/*/*if delete_flag1=1 then delete;*/*/
/*/*if ibd_ever =1 then delete;*/*/
/*/*format dpp4i; run;*/*/
/*proc freq data=  dsnac_&exposure._&comparator.  ; */
/*tables sex*sex_num/list missing;run;*/
/*/*Testing variable creations*/*/
/*proc freq data=  dsnac_&exposure._&comparator.  ; */
/*tables     chf_ever     */
/*/*Variables that I had coded*/*/
/*alc_miss*alc smoke_miss*smoke/ list missing; */
/*run; */
/*proc means data =   dsnac_&exposure._&comparator.*/
/*STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ; */
/*class hba1c_cat2;*/
/*/*Original continuous variables*/*/
/*var   hba1c     ; */
/*run; */
/**/
/*proc means data =   dsnac_&exposure._&comparator.*/
/*STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ; */
/*class bmi_cat2;*/
/*/*Original continuous variables*/*/
/*var   bmi   ; */
/*run; */
/*===================================*\
Step 0: Testing proportional odds assumption for smoke_miss and alc_miss variables
\*===================================*/
%let dataset=dsnac_&exposure._&comparator.; 
%let drug1=dpp4i; 
%let clinical=smoke_miss ;
%let clinical=alc_miss ;
%let vars= sglt2i_1yrlookback su_1yrlookback ; 

proc logistic data=&dataset descending  ;
where &clinical ne .;
class entry_year (ref=last) sex (ref=last) /param=ref; 
model &clinical   = &drug1 &vars event
age|age   
sex entry_year   
/*bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  */
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever 
/*drugs*/
bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 
/*Autoimmune*/
psorp_ever vasc_ever 
RhArth_ever SjSy_ever sLup_ever 
/scale=none aggregate 
/*link=glogit*/ 
/*/unequalslopes equalslopes*/
; 
run;
/*followup on prop odds violated*/

/*===================================*\
Step 1: Missing data pattern
\*===================================*/

/*Test for TVE*/
%let dataset= dsntve_&exposure._&comparator.;
/*Test for acnu*/
%let dataset=dsnac_&exposure._&comparator.; 
/*First try test for ACNU*/
%let dataset=dsnac_&exposure._&comparator.; 
%let drug1=dpp4i; 
%let clinical=smoke_miss alc_miss hba1c bmi;
%let vars= sglt2i_1yrlookback su_1yrlookback ; 
proc mi nimpute=0 data=&dataset simple;
var event &drug1 &vars &clinical
age agesquare  
sex_num entry_year   
/*bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  */
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever 
/*drugs*/
bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 
/*Autoimmune*/
psorp_ever vasc_ever 
RhArth_ever SjSy_ever sLup_ever 
;
run;


/*********************************************************************/
/**STEP2: ADDING NELSON-AALEN timing, prepare dataset for MI**********/
/*********************************************************************/
** multiple imputation for baseline covariates in survival;
* estimate Nelson-Aalen estimator for cumalative hazard;
/*Test for acnu*/
%let dataset=dsnac_&exposure._&comparator.; 
ods exclude all;
ods output productlimitestimates=out;
proc lifetest data=&dataset nelson;
  time time*event(0); * time*event();
run;
ods exclude none;
proc print data=out (obs=5); var time cumhaz; run;
proc means data =  out        
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ; 
var      cumhaz        ; 
run; 
* only keep the non-missing values for cumulative hazard;
data out1;
      set out;
      if cumhaz ne .;
run;
* sort the datasets (main dataset and Nelson-Aalen estimator dataset);

/*%let dataset=dsnac_&exposure._&comparator.; */
proc sort data=&dataset; by time;
proc sort data=out1; by time; run;

* merge these two datasets;
data comb_4;
      merge &dataset (in=in) out1 (keep=time cumhaz);         
      by time;
      if in;
      retain cum 0;
    if cumhaz eq . then cumhaz = cum; * plug in most recent value of cumhaz if missing;
    cum = cumhaz;
      drop cum;
run;

/*proc print data=comb_4 (obs=5); var time cumhaz;run;*/
/*proc freq data=comb_4;tables cumhaz/missing;run;*/
ods select Position;
proc contents data= comb_4
varnum; run; 
 ods select default; 

proc freq data= &dataset   ; 
tables      event          / list missing; 
run; 
proc means data =  &dataset
        
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ; 
var      time        ; 
run; 

/**********************************************/
/**STEP3: MUTIPLE IMPUTAION NOMINAL**********/
/**********************************************/
/*Test for TVE*/
/*proc means data =   a.notrim_&exposure._&comparator._1yrlb       */
/*STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ; */
/*var      hba1c bmi        ; */
/*run; */

/*%let dataset= dsntve_&exposure._&comparator.;*/
data comb_4; set comb_4; 
keep id filldate2
switcher_flag
	bmi hba1c alc_miss smoke_miss dpp4i
	cumhaz event time logtime  time_drugdur rxchange DiscontDate enddt  switchAugmentDate
	ibd1 ibd1_dt indexdate
	switcher_flag dpp4i_filldate2
	 enddt endstudy_dt  death_dt dbexit_dt  LastColl_Dt
	oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback chf_ever TZD_1yrlookback
	diff_1st_2ndrx
	age agesquare  
	sex_num entry_year   	
	nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever 
	bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
	ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 
	psorp_ever vasc_ever 
	RhArth_ever SjSy_ever sLup_ever
	ibd_ever 
 deleteobs  IBDdx_inductionperiod  delete_zerofollowup  delete_flag1;run;

/*Test for acnu*/
%let dataset=comb_4; 
%let drug1= dpp4i ; 
%let drug2=tzd; 
%let outdata= acnu_MI ;
%let clinical = ; 
%let vars= oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback  ; 
%let m=1;
proc mi data=&dataset nimpute=&m seed=20240107 out=temp.&outdata._&drug1._&drug2. ;*a.&outdata._&drug1._&drug2;
CLASS  alc_miss smoke_miss
/* event &drug1 &vars &clinical */
/*	sex_num */
	entry_year   
	/*bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  */
/*	nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever */
	/*drugs*/
/*	bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr */
/*	ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever */
	/*Autoimmune*/
/*	psorp_ever vasc_ever */
/*	RhArth_ever SjSy_ever sLup_ever*/
	;
fcs nbiter=10 logistic( alc_miss smoke_miss /details link=glogit likelihood=augment) reg( bmi hba1c /details); 
VAR  bmi hba1c alc_miss smoke_miss
	cumhaz event &drug1 &vars &clinical
	age agesquare  
	sex_num entry_year   
	/*bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  */
	nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever 
	/*drugs*/
	bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
	ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 
	/*Autoimmune*/
	psorp_ever vasc_ever 
	RhArth_ever SjSy_ever sLup_ever;
run;

/**/
/*ERROR: Invalid Operation.*/
/*ERROR: Termination due to Floating Point Exception*/
ods select Position;
proc contents data=  &outdata._&drug1._&drug2.
varnum; run; 
 ods select default; 
proc freq data=   &outdata._&drug1._&drug2.  ; 
tables      _Imputation_          / list missing; 
run; 
proc means data =  &outdata._&drug1._&drug2. 
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ; 
var    hba1c bmi          ; 
run; 

proc means data =   a.notrim_&exposure._&comparator._1yrlb       
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ; 
var      hba1c bmi        ; 
run; 

proc freq data=   &outdata._&drug1._&drug2.  ; 
by   _imputation_;
tables           smoke_miss alc_miss   chf_ever  / list missing; 
run; 

proc freq data=   a.notrim_&exposure._&comparator._1yrlb   ; 
tables           smoke alc   chf_ever  / list missing; 
run; 
/**/
/*ERROR: Invalid Operation.*/
/*ERROR: Termination due to Floating Point Exception*/
/*===================================*\
ACNU MI PS weighting test
\*===================================*/

data tmp1;
	set  &outdata._&drug1._&drug2.;
/*        set a.allmerged_&exposure._&comparator._1yrlb;*/
/*Recreating the variables for analysis*/
/*Recreate alc and smoke character variable*/
smoke=''; 
if smoke_miss=3 then smoke='c';
else if smoke_miss=2 then smoke='n';
else if smoke_miss=1 then smoke='x';

alc='';
if alc_miss=1 then alc='c';
else if alc_miss=2 then alc='n';
else if alc_miss=3 then alc='x';

	format smoke alc statusf.;
/*	recreate sex character variable*/
	if sex_num=1 then sex='f';
	else if sex_num=0 then sex='m';
/*Coding HBA1c and BMI categories from the imputed variables*/
/* HBa1c is in mmol per mol, */
	* change to all year lookback;
    hba1c_cat=.;
    *if hba1ctime<365.25 then do;
        if hba1c eq . then hba1c_cat=.; 
        else if hba1c le 53 then hba1c_cat=1; /* 7% ~ 53 mmol per mol  */
        else if hba1c gt 53 and hba1c le 64 then hba1c_cat=2 ; /* 8% ~ 64 mmol per mol */
        else if hba1c gt 64 then hba1c_cat=3; /* gt 8% or 64 mmol per mol  */
        *end;
    hba1c_cat2= hba1c_cat; 
        if hba1c_cat eq . then hba1c_cat2=4;
        format hba1c_cat2 hba1cf.; 
    /* BMI */
    bmi_cat=.;
    *if bmitime<365 then do;
	* change to all year lookback;
		if bmi eq . then bmi_cat=.;
        else if bmi<25 then bmi_cat=1;
        else if bmi ge 25 and bmi lt 30 then bmi_cat=2;
        else if bmi ge 30 then bmi_cat=3;
        *end;
        bmi_cat2= bmi_cat; 
        if bmi_cat eq . then bmi_cat2=4;
        format bmi_cat2 bmif.; 

run;
proc freq data=  tmp1  ; 
tables               alc smoke / list missing; 
run; 
proc means data =  tmp1        
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ; 
class hba1c_cat2;
var        hba1c      ; 
run; 
proc means data =  tmp1        
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ; 
class bmi_cat2;
var        bmi     ; 
run; 

/*save tmp1 in the analysis dataset folder once ok with the rest of the analysis*/

%let mipara=4;
%let ana_name=MI;
%let basemodelvars= age agesquare
sex entry_year  bmi_cat2 alc smoke hba1c_Cat2  
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever 

bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 

psorp_ever vasc_ever 
RhArth_ever SjSy_ever sLup_ever; 
%let addedmodelvars= oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback ;

%LET tablerowvars = age sex entry_year  

diff_1st_2ndrx  /* added to table 1 rows, NOT in PS trimming model */

bmi_cat2 alc smoke hba1c_Cat2 
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever  

oAntGLP_ever dpp4i_ever sglt2i_ever TZD_ever su_ever 

bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr /*num_nondmdrugs1yr_cat*/
ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 

psorp_ever vasc_ever 
RhArth_ever SjSy_ever sLup_ever 
/*IBD_ever crohns_ever ucolitis_ever*/

;

     
/*ods select Position;*/
/*proc contents data= tmp1*/
/*varnum; run; */
/* ods select default; */
/*estimate PS untrimmed*/
    /*=================*\
    PS weighting
    \*=================*/
    *%removeMetadata(tmp1);

data dsn_&mipara.; set tmp1; if _imputation_=&mipara;run;

    *  ods rtf file="&goutpath./&todaysdate.psoutput&exposure._&comparator..rtf";
    proc logistic data=dsn_&mipara. descending;
        class  entry_year (ref=first) sex (ref=first) hba1c_Cat2 (ref=first) alc (ref=first)
        smoke (ref=first) bmi_cat2(ref=first) /param=ref; 
        model &exposure. =    /*Adding further model variables and interactions VARIABLE*/
        &addedmodelvars. &basemodelvars.
        ; output out= psdsnnotrim pred=ps; run; 
/*        ods rtf close; */
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
        from dsn_&mipara.
        where &exposure=1;    
        select count(*) into : n_&comparator. 
        from dsn_&mipara.
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
 ods pdf file="&foutpath.\MI\psplot_ACNU_untrimmed_&ana_name.s_&exposure._&comparator._&todaysdate..pdf";
    symbol1 interpol=spline value=none line=1;
    symbol2 interpol=spline value=none line=2;
    axis1 order=(0 to 1 by 0.1) minor=none label=(a=0 j=c h=1.5 f=swiss 'Propensity Score') value=(h=1.1 f=swiss);
    axis2 minor=(n=1) label=(a=90 j=c h=1.5 f=swiss 'Density') value=(h=1.1 f=swiss);
    title "Untrimmed PS distribution for &exposure. use, by treatment status";
    proc gplot data=psplot;
        plot density*value=pop / haxis=axis1 vaxis=axis2;
        run; quit;
        title;
 ods pdf close;
	/*=================*\
    Table 1 untrimmed 7/25/2024 Tian added Table 1 untrimmed weighted Table 1.
    \*=================*/
    proc format; value &exposure. 0="&comparator." 1="&exposure."; run;
    proc datasets lib=work nolist nodetails; modify psdsnnotrim; 
        format &exposure. &exposure..  sex $sexf.  alc  $statusf. smoke $statusf. hba1c_cat2  hba1cf. bmi_cat2 bmif.;
        run;
    %LET wgtvar=smrw;
    %let ds = psdsnnotrim ;
    %let colVar = &exposure.;
    %let rowVars = &tablerowvars. ;
    %LET outname = Table1notrim_MI&mipara._&exposure._&comparator._&todaysdate.; 
    options orientation=landscape nodate nonumber nocenter;
    %table1(inds= &ds, colVar= &colVar, rowVars= &rowVars, wgtVar= ,       maxLevels=16, outfile=tmp, title=&outname, cellsize=5);
    title ;
    data tab1_unwgt_&exposure.; 
        set final; run;
    proc datasets lib=work nolist nodetails; delete final; run; quit;
    %table1(inds= &ds, colVar= &colVar, rowVars= &rowVars, wgtVar= &wgtvar, maxLevels=16, outfile=tmp2, title=&outname, cellsize=5);
    title;
    data tab1_wgt_&exposure.; 
        set final; run;
    proc datasets lib=work nolist nodetails; delete final; run; quit;
    /* Joining tables together */
    proc sql;
        create table table1notrim_&exposure.v&comparator. as
        select a.row, a.&exposure., a.&comparator., a.sdiff label='Unwgted Stdz Diff',
            b.&comparator._wgt, b.sdiff as sdiff_wgt label='Wgted Stdz Diff', a.order, a.roworder
        from tab1_unwgt_&exposure. as a 
        left join tab1_wgt_&exposure. (rename=(&comparator=&comparator._wgt)) as b
            on a.row=b.row and a.order=b.order and a.roworder=b.roworder
        order by order, roworder;
    quit;
    ods escapechar='~' ;
    options orientation=landscape nodate nonumber nocenter;
    ods rtf file="&toutPath.\MI\ACNU_Table1notrim_MI&mipara._&exposure._&comparator._&todaysdate..rtf";
    proc print data=table1notrim_&exposure.v&comparator. noobs label; var row &exposure &comparator sdiff &comparator._wgt sdiff_wgt; run;
    ods rtf close;
	proc freq data=    psdsnnotrim; 
tables      deleteobs IBDdx_inductionperiod delete_zerofollowup/ list missing; 
run; 

data dsnmi; set psdsnnotrim; 
if delete_flag1=1 then delete; 
if ibd_ever=1 then delete; run;

/*Remove this when run actual MI this is temporary bc forgot to include this variable*/
data dsnmi; set dsnmi; time_drugdur=2;    	*log time and mising time;
        if time>0 then logtime=(log(time/100000))  ;
        else time=.;run;
/*proc freq data=    dsn; */
/*tables               dpp4i / list missing; */
/*run; */

/*calculate median followup*/
ods output summary=mediantime;
Proc means data=dsnmi stackods N sum median q1 q3;
   class &exposure;
   var time time_drugdur;
   run;
Data mediantime(keep=&exposure Nobs mediantime time_sum mediantimedu timedu_sum time_median time_q1 time_q3);        
   set mediantime;
   mediantime  =compress(put((time_median),  6.2))||" ("||compress(put((time_q1),  6.2))||"-"||compress(put((time_q3),  6.2))||")";  
   mediantimedu=compress(put((timedu_median),6.2))||" ("||compress(put((timedu_q1),6.2))||"-"||compress(put((timedu_q3),6.2))||")";  
   format time_sum 8.0;
   format timedu_sum 8.0;
   run;
/*Count num event*/
ods output summary=event;
Proc means data=dsnmi stackods sum;
   class &drug1;
   var event;
   run;

/*Rate*/
proc sort data=dsnmi; 
	by &exposure; 
run;
%let exposure=dpp4i;
%LET event = event;
%LET logtimevar = logtime;
%LET timevar = time;
proc genmod data=dsnmi;
	where delete_flag1 ne 1;
	by &exposure;
	class id;
	model &event= /dist=poisson offset=&logtimevar maxiter=100000;
	repeated subject=id;
	estimate 'rate' int 1/exp;
	ods output estimates=rate;
run;
proc print data= rate; run;
Data rate(keep=&exposure   lbetaestimate lbetalowercl lbetauppercl lbetaStderr);
    set rate;
    if Label='Exp(rate)';
	lbetaStderr=stderr;
/*    rate=compress(put((LBetaEstimate),6.1))||" ("||compress(put((LBetaLowerCL),6.1))||"-"||compress(put((LBetaUpperCL),6.1))||")";*/
    run;

/*CrudeHR*/
ods output ParameterEstimates = crudehr;
Proc phreg data=dsn covsandwich(aggregate);
where delete_flag1 ne 1;
    id id;
    model &timevar*&event(0)=&exposure /ties=efron rl;
    title ' crude HR';
run;
Data crudehr(keep=  &exposure chr chr_lcl chr_ucl chr_estimate chr_stderr);
    set crudehr;
    &exposure=1;
    chr=exp(Estimate);
    clcl=exp(Estimate-1.96*StdErr);
    cucl=exp(Estimate+1.96*StdErr);
	chr_estimate=estimate;
	chr_stderr=stderr;
/*    crude_HR=compress(put((hazardratio),6.1))||" ("||compress(put((HRlowerCL),6.1))||"-"||compress(put((HRupperCL),6.1))||")";*/
run;

/*SMRW HR*/
%LET weight = smrw;
ods output ParameterEstimates =&WEIGHT;
proc phreg data=dsn covsandwich(aggregate);
where delete_flag1 ne 1;
    id id;
    weight &weight; 
    model  &timevar*&event(0)=&exposure  /ties=efron rl;
    title 'SMRW adjusted HR';
run;
Data &WEIGHT(keep=status &exposure whr whr_lcl whr_ucl whr_estimate whr_stderr );
    set &WEIGHT; 
    &exposure=1;
    whr =exp(Estimate);
	whr_estimate=estimate;
	whr_stderr=stderr;
    wlcl=exp(Estimate-1.96*StdErr);
    wucl=exp(Estimate+1.96*StdErr);
/*    &weight._HR=compress(put((hazardratio),6.1))||" ("||compress(put((HRlowerCL),6.1))||"-"||compress(put((HRupperCL),6.1))||")";*/
run;
/*merge output together*/
Data dsnmi_&mipara.;
   length type $ 20 ;
   merge  mediantime event rate /*wtrate*/ crudehr &weight;
   by &exposure;
   mipara= &mipara.;
    analysis="&ana_name. &type. ";
    type="&ibd_def.";
   latency=&latency;
   induction=&induction;
   run;
/*end loop here*/
 
/*Summarize*/
Data outmi_&exposure.v&comparator. 
(keep=
&exposure Nobs 
mediantime 
time_sum event_sum 
rate  lbetaestimate lbetalowercl lbetauppercl lbetaStderr
crude_HR chr chr_lcl chr_ucl chr_estimate chr_stderr
&weight._hr whr whr_lcl whr_ucl whr_estimate whr_stderr 
ana induction latency exp unexp 
time_median time_q1 time_q3 );
   set dsnmi: ;
   exp="&exposure";
   unexp="&comparator";
   label event_Sum="No. of Event"
          time_Sum = "Person-year";
   run;
/*reorder variables*/
Data foutmi_&weight._&exposure.v&comparator._&name. ;
   retain 
&exposure Nobs 
mediantime 
time_sum event_sum 
rate  lbetaestimate lbetalowercl lbetauppercl lbetaStderr
crude_HR chr chr_lcl chr_ucl chr_estimate chr_stderr
&weight._hr whr whr_lcl whr_ucl whr_estimate whr_stderr 
ana induction latency exp unexp 
time_median time_q1 time_q3 ; 
   set outmi_&exposure.v&comparator. ;
run;


   proc print data=temp.tveoutmi_res_dpp4i_&comparator.; run;    
   proc print data=temp.tveoutmi_means_dpp4i_&comparator.; run;    
   proc print data=temp.tveoutmi_freqs_dpp4i_&comparator.; run; 

   proc print data=temp.acnuoutmi_res_dpp4i_&comparator.; run;
   proc print data=temp.acnuoutmi_means_dpp4i_&comparator.; run;
   proc print data=temp.acnuoutmi_freqs_dpp4i_&comparator.; run;