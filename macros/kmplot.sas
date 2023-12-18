/***************************************
 SAS file name: kmplot.sas

Purpose: KM plot macro 
Author: JHW
Creation Date: 31OCT23

    Program and output path:
            D:\Externe Projekte\UNC\wangje\sas
                D:\Externe Projekte\UNC\wangje\sas\prog
            libname temp D:\Externe Projekte\UNC\wangje\data\temp

    Input paths:
                libname raw D:\Externe Projekte\UNC\Task190813 - IBDandDPP4I (db19-1)\res\Task190813A_210429_SensitivityA
             libname a  D:\Externe Projekte\UNC\wangje\data\analysis
Other details: CPRD-DPP4i project in collaboration with USB

CHANGES:
Date: 31OCT23
Notes: init commit
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\sas\macros");

%kmplot(ana_name = a0,
                weight= smrw ,
                analysis=  ITT, 
                type  = ITT , 
                drugexp = DPP4i ,
                comparator= SU)

%kmplot(ana_name = ,
                weight=  ,
                analysis=  , 
                type  =  , 
                drugexp =  ,
                comparator= )

/*===================================*\
//SECTION - KM macro start
\*===================================*/
/* region */


%macro kmplot(ana_name  , 
                weight  ,
                analysis  , 
                type  , 
                drugexp ,
                comparator , 
                outtime  ,
                latency);

                
/* local macro variables   */  
%LET event = caco_&type;
%LET logtimevar = logtime_&type;
%LET timevar = time_&type;

/* reading in dataset  */
DATA  psdsn;
SET  a.&ana_name._ps_&drugexp.v&comparator;
keep  id  &drugexp  &comparator &weight entry tx_at_firsttimep dpp4i_last tzd_last sulfonyl_last dpp4i
caco exit exit_reason; 
RUN;


data dsn;
   set psdsn;
   /* where entry=date of 2nd prescription */
    oneyear  =entry+365.25;
	twoyear=entry+730.5;
	threeyear=entry+1095.75;
	fouryear =entry+1460;
	oneyearout  =oneyear   + &latency; 
	twoyearout  =twoyear   + &latency;
	threeyearout=threeyear + &latency;
	fouryearout=fouryear + &latency;
	format oneyearout   date9.;
	format oneyear      date9.;
	format twoyear      date9.;
	format threeyear    date9.;
	format fouryear     date9.;

   endofstudy='31Dec2017'd ;
   initiation_date= .;
   if tx_at_firsttimep eq 8 then do;
      initiation_date=entry-dpp4i_last;
   end;else if tx_at_firsttimep eq 4 then do;
      initiation_date=entry-sulfonyl_last;
   END;else if tx_at_firsttimep eq 1 then do;
      initiation_date=entry-TZD_last;
   END;
   
   caco_AT=caco; 
   label caco_AT = "case  status for AS Treated analysis ";
   enddate_AT=exit; /* AT exit date and AT exit_reason   */
   label enddate_AT = "enddate for as treated analysis";

   enddate_ITT= .;
   label enddate_ITT = "end date for initial treatment analysis";
   if  (exit_reason in (3,4)) then do; /*exit reason ne 1=outcome, 2=end of fu, 5=death, 6=db exit */
      enddate_ITT= min( &outtime,endofstudy );
   end;   
   else do; /*exit reason eq 1=outcome, 2=end of fu, 5=death, 6=db exit */
      enddate_ITT=min( &outtime,exit,endofstudy ); 
      end;

      if (exit_reason eq 1 and enddate_ITT<enddate_AT) then do;
         caco_ITT=0;
      end;else do; 
   caco_ITT=caco; END; 
   label caco_ITT = "case status for initial treatment analysis";

   time_ITT=(enddate_ITT-(entry+180)+1)/365.25; 
   label time_ITT="fu time for Initial Treatment analysis";
   time_AT=(enddate_AT-(entry+180)+1)/365.25; 
   label time_AT="fu time for as treated analysis";

   timedu_ITT=(enddate_ITT-entry+1)/365.25;
   label timedu_ITT = "Duration of treatment for initial treatment analysis";
   timedu_AT=(enddate_AT-entry+1)/365.25;;
   label timedu_AT = "Duration of treatment for as treated analysis";
   if time_AT>0 then logtime_AT= log(time_AT/100000); else time_AT = .; 
   if time_ITT>0 then logtime_ITT=log(time_ITT/100000); else time_itt=.; 
   RUN;

/* weighted risks    */

proc phreg data=dsn COVS ;
   MODEL &timevar*&event(0)= ; 
   strata &drugexp;
   WEIGHT &weight;
   ID id ;
    baseline out=Pred survival=_all_ lower=lower upper=upper;
   run;
proc sort data=pred; 
    by &drugexp   &timevar;
    run;
Data Pred;
   set Pred(keep=&drugexp &timevar survival lower upper);
   risk=1-survival;
   risk_upper=1-lower;
   risk_lower=1-upper;
   run;

data exp(keep=&timevar risk risk_lower risk_upper &drugexp.) unexp(keep=&timevar risk risk_lower risk_upper &drugexp.);
   set  pred;
   if &drugexp=1 then output exp;
   if &drugexp=0 then output unexp;
   run;
Data plot;
   merge exp(rename=(risk=&drugexp._risk risk_lower=&drugexp._lower risk_upper=&drugexp._upper)) unexp(rename=(risk=&comparator._risk risk_lower=&comparator._lower risk_upper=&comparator._upper));
   by &timevar;
   run;


proc template;
   define style mystyle;
   parent=styles.sasweb;
      class graphwalls / 
            frameborder=off;
      class graphbackground / 
            color=white;
   end;
run;


PROC SGPLOT DATA = plot NOAUTOLEGEND DESCRIPTION=""; 
 YAXIS LABEL = 'Risk of Inflammatory Bowel Disease' LABELATTRS=(size=13pt weight=bold)  VALUES = (0 TO 0.0045 BY 0.0005) valueattrs=(size=12pt); 
 XAXIS LABEL = 'Follow-up Time (years)' 		    LABELATTRS=(size=13pt weight=bold)  VALUES = (0 TO 4 BY 0.5) valueattrs=(size=12pt); 

 title height=12pt bold " ";
 step x=&timevar y=&drugexp._risk/lineattrs=(color=blue pattern=1 thickness=2) name="&drugexp.";
 step x=&timevar y=&drugexp._lower/lineattrs=(color=blue pattern=20 thickness=1) name="&drugexp._lower";
 step x=&timevar y=&drugexp._upper/lineattrs=(color=blue pattern=20 thickness=1) name="&drugexp._upper";

 step x=&timevar y=&comparator._risk/lineattrs=(color=red  pattern=1 thickness=2) name="&comparator.";
 step x=&timevar y=&comparator._lower/lineattrs=(color=red  pattern=20 thickness=1) name="&comparator._lower";
 step x=&timevar y=&comparator._upper/lineattrs=(color=red  pattern=20 thickness=1) name="&comparator._upper";
 keylegend "&drugexp." "&comparator." /location=inside position=topleft valueattrs=(size=12pt weight=bold) NOBORDER;
FOOTNOTE;
RUN; 


/*No. of risk at 0 year*/
%let dataset=dsn;
proc sql; create table tmpp_b as select "&drugexp."    as drug ,0 as fu_year,  count(id) as total_id, "No. at risk for &comparator initiator at 0 year" as label from &dataset where &drugexp=0; quit;
proc sql; create table tmpp_a as select "&comparator." as drug,0 as fu_year, count(id) as total_id, "No. at risk for &drugexp initiator at 0 year" as label from &dataset where &drugexp=1; quit;
/*No. of risk at 0.5 year*/
proc sql; create table tmpp_c as select "&drugexp." as drug,0.5 as fu_year,  count(id) as total_id, "No. at risk for &drugexp initiator at 0.5 year" as label from &dataset where &timevar >=0.5 and &drugexp=1; quit;
proc sql; create table tmpp_d as select "&comparator." as drug,0.5 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 0.5 year" as label from &dataset where &timevar >=0.5 and &drugexp=0; quit;
/*No. of risk at 1 year*/
proc sql; create table tmpp_e as select "&drugexp." as drug,1.0 as fu_year,  count(id) as total_id, "No. at risk for &drugexp initiator at 1 year" as label from &dataset where &timevar >=1 and &drugexp=1; quit;
proc sql; create table tmpp_f as select "&comparator." as drug,1.0 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 1 year" as label from &dataset where &timevar >=1 and &drugexp=0; quit;
/*No. of risk at 1.5 year*/
proc sql; create table tmpp_g as select "&drugexp." as drug,1.5 as fu_year,  count(id) as total_id, "No. at risk for &drugexp initiator at 1.5 year" as label from &dataset where &timevar >=1.5 and &drugexp=1; quit;
proc sql; create table tmpp_h as select "&comparator." as drug,1.5 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 1.5 year" as label from &dataset where &timevar >=1.5 and &drugexp=0; quit;
/*No. of risk at 2 year*/
proc sql; create table tmpp_i as select "&drugexp." as drug,2 as fu_year,  count(id) as total_id, "No. at risk for &drugexp initiator at 2 year" as label from &dataset where &timevar >=2 and &drugexp=1; quit;
proc sql; create table tmpp_j as select "&comparator." as drug,2 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 2 year" as label from &dataset where &timevar >=2 and &drugexp=0; quit;
/*No. of risk at 2.5 year*/
proc sql; create table tmpp_k as select "&drugexp." as drug,2.5 as fu_year,  count(id) as total_id, "No. at risk for &drugexp initiator at 2.5 year" as label from &dataset where &timevar >=2.5 and &drugexp=1; quit;
proc sql; create table tmpp_l as select "&comparator." as drug,2.5 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 2.5 year" as label from &dataset where &timevar >=2.5 and &drugexp=0; quit;
/*No. of risk at 3 year*/
proc sql; create table tmpp_m as select "&drugexp." as drug,3 as fu_year,  count(id) as total_id, "No. at risk for &drugexp initiator at 3 year" as label from &dataset where &timevar >=3 and &drugexp=1; quit;
proc sql; create table tmpp_n as select "&comparator." as drug,3 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 3 year" as label from &dataset where &timevar >=3 and &drugexp=0; quit;

DATA countout;
SET tmpp_:;
RUN;
 proc sort data= countout; by drug; run;
proc transpose data=countout out=tmp prefix= fuyear; 
by drug ; 
id fu_year; run;
proc print data= tmp  ;  variables drug fuyear:;
run; 


/* endregion //!SECTION */
%mend kmplot;

