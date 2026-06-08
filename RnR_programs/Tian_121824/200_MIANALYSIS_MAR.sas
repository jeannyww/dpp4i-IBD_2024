/**********************************************************************************/
/**************************setting before******************************************/
/**********************************************************************************/
options source source2 msglevel=I mprint mcompilenote=all mautosource nofmterr
sasautos=(SASAUTOS "/nearline/files/projects/medicare/incretinRetinopathy/programs/macros");

%setup(full, 12_200MIanalysis, saveLog=Y);

libname lwork slibref=work server=server;

options symbolgen mlogic mprint;
%Macro analysismi(indata, mipara, drug1, drug2, weight, vars, name, stratify, lower, upper, clinical, clinicalcat);
%DO mipara=1 %TO 50 %BY 1;
/*clean WORK lib*/ 
proc datasets library=work kill;
run;

/* a) by _imputation_*/
data dsnmi_&mipara;
 set ana.&indata._&drug1.v&drug2.;
 if _imputation_=&mipara;
 run;
/*start here, may replace by our analytic program*/
 data dsnmi_&mipara;
   set dsnmi_&mipara;
   if &stratify in (&lower. : &upper.);
   /*cif a1c in (1);*/
   /*if a1c in (2);*/
run;

proc sql;
	title "count &drug1"; 
	select count (*) into : N&drug1._trim from  dsnmi_&mipara where &drug1.=1;
	title "count &drug2"; 
	select count (*) into : N&drug2._trim from  dsnmi_&mipara where &drug1.=0;
quit;
%put &&N&drug1._trim;
%put &&N&drug2._trim;


/* b) estimate PS */
ods output Association=ana.PS_c_&name._&mipara;  
ods trace on;
ODS rtf FILE="&outpath./psoutput_&weight._&drug1.v&drug2._&mipara..rtf";
proc logistic data=dsnmi_&mipara descending  ;
   class    
         /*agecat(ref='0') DPPvsSU: AIC for Quadratic=85718.799 < AIC for Categorical=85719.209, thus use Quadratic */
         racecat(ref=first) ervisit(ref=first) hosp(ref=first) phvisit(ref='3') 
         year(ref='2015') hba1c (ref='3') lipid (ref='1') hyperglycemia(ref=first)
         hospnoDM(ref=first) hospdaysDM(ref=first) ervisitDM(ref=first) /*eyeexam(ref='2')*/
         &clinicalcat 
         /param=ref;
   model &drug1 = 
/***************TABLE 1***********************/
age|age gender   
/*eye COMORBIDITY*/ 
bl_diabRetinopathy /*ONLY including both bl_diabRetinopahty, DOES NOT including bnFills_diabRetinopathy*/
bl_amd bl_retinadeta bl_oretinal bl_cataract bl_glaucoma bl_ANYEDZEX_CAGDODT
/*diabetic COMORBIDITY*/ 
bl_nephropathy bl_neuropathy 
/*CVD comorbidity*/
bl_hypertension bl_dyslipidemia bl_ischemichtdz bl_cerebrovasculardz bl_peripheralvdz 
/*other comorbidity*/
bl_COPD bl_DEPRESSION bl_cancer bl_ckd
/*VARIABLE*/
&vars 
/*Co-Medications*/
bl_METFORMIN bl_agi bl_meglitinide bl_ACEI bl_ARB bl_BB bl_CCB bl_STATIN bl_LOOP bl_OTHERDIURETICS bl_fenofibrate bl_ANYBADRX
/*CPT II codes*/
&clinical
/***************TABLE S3**********************/
racecat year
/*health care use*/
hyperglycemia /*eyeexam*/ 
/*hba1c lipid*/ hospnoDM /*hospdaysDM*/ ervisitDM phvisit /*hospno hosp*/ ervisit flushot lics
/*Covariates distribution for HbA1c and LDL-C test level are not weighted because they are well balanced in the crude comparison (except GLP versus LAI) and data are available for only a small portion of the population*/
/*KEY interaction*/
bl_metformin*year 
;
   output out=psdsnmi pred=psmi;
run;
ods rtf close;
ods trace off;
/********************************************/
/* Calculating PS weights */
/********************************************/

/* Calculating the marginal probability of treatment for the stabilized IPTW */
PROC MEANS DATA=psdsnmi(keep=psmi) NOPRINT;
VAR psmi;
OUTPUT OUT=psmi_mean MEAN=margmi_prob;
RUN;

DATA _NULL_;
SET psmi_mean;
CALL SYMPUT("marg_prob",margmi_prob);
RUN;
/* Calculating weights from the propensity score */
DATA psdsnmi;
 SET psdsnmi;
 *Calculating IPTW;
 IF &drug1 = 1 THEN iptw = 1/psmi;
 ELSE IF &drug1 = 0 then iptw = 1/(1-psmi);
 *Calculating stabilized IPTW=siptw;
 IF &drug1 = 1 THEN siptw = &marg_prob/psmi;
 ELSE IF &drug1 = 0 THEN siptw = (1-&marg_prob)/(1-psmi);
 *Calculating SMRW;
 IF &drug1 = 1 THEN smrw = 1;
 ELSE IF &drug1 = 0 THEN smrw = psmi/(1-psmi);
  *Calculating SMRWU;
  	  IF &drug1 = 1 THEN smrwu = (1-psmi)/(1-(1-psmi));
 ELSE IF &drug1 = 0 THEN smrwu = 1;
  *Calculating stabilized SMRWU=ssmru, use the NEW prevalence of GLP after trimming!;
  	  IF &drug1 = 1 THEN ssmrwu = (&&N&drug1._trim)/(&&N&drug2._trim)*(1-psmi)/(1-(1-psmi));
 ELSE IF &drug1 = 0 THEN ssmrwu = 1;
 LABEL psmi = "Propensity Score MI"
 iptw = "Inverse Probability of Treatment Weight MI"
 siptw = "Stabilized Inverse Probability of Treatment Weight MI"
 smrw = "Standardized Mortality Ratio Weight"
 smrwu = "Standardized Mortality Ratio Weight in Untreated (ATU)"
 ssmrwu = "Stabilized Standardized Mortality Ratio Weight in Untreated (ATU)";
RUN;

/********************************************/
/* Evaluating the PS distribution  */
/********************************************/
/* Creating PS treatment groups for plotting */

proc kde data=psdsnmi(where=(&drug1=1));
    univar psmi/ out=temp1 bwm=0.25;
run;
quit;

proc kde data=psdsnmi(where=(&drug1=0)) ;
    univar psmi / out=temp2 bwm=0.25;
run;
quit;

data psplotmi;
   set temp1(in=a) temp2(in=b) ;
   if a then pop='&drug1';
   else if b then pop='&drug2';
     label value="Propensity Score"
         pop="Treatment"
         density="Density";
run;
proc format;
    value $label "dpp"="DPP4i"
                "glp"="GLP1RA"
             "su"="SU"
             "tzd"="TZD"
             "lai"="LAI";
run;
goptions reset=all device=png targetdevice=png gsfname=grafout gsfmode=replace ;
filename grafout "&outpath./psplotmi_&drug1.v&drug2._&mipara..png";  
symbol1 interpol=spline value=none line=1;
symbol2 interpol=spline value=none line=2;

proc gplot data=psplotmi;
    title "Distribution of Propensity Score";
    title2 "Kernel Density Estimate";
    plot density*value=pop;
   format pop $label.;
run;
quit;
/********************************************/
/* Evaluating the weights and preparing for */
/* trimming if necessary */
/********************************************/
/* Performing univariate analysis on the weight variables by treatment status
to check for extreme weights */
PROC UNIVARIATE DATA=psdsnmi;
 CLASS &drug1;
 VAR iptw siptw smrw smrwu ssmrwu;
 TITLE "Evaluating weights by treatment group";
RUN;
/* Identifying percentiles at the upper and lower extremes of the untreated and treated
 PS distributions for trimming, if needed. If other percentiles are needed, they can
 be created in the OUTPUT statement either by using a predefined SAS percentile,
 or by creating one in PCTLPTS=" */
PROC UNIVARIATE DATA=psdsnmi NOPRINT;
 CLASS &drug1;
 VAR psmi;
 OUTPUT OUT=ps_pctl MIN=min MAX=max P1=p1 P99=p99 PCTLPTS=0.5 99.5 PCTLPRE=p;
 title "Distribution of Propensity Score for &drug1 use, by &drug1 use";
RUN;
/* Labeling the percentiles at the lower extremes of the treated in macro variables which can be
 called later. Defining the minimum, 0.5th percentiles, and 1st percentile of the treated */
DATA _NULL_;
 SET ps_pctl;
 WHERE &drug1 = 1;
 CALL SYMPUT("treated_min",min);
 CALL SYMPUT("treated_05",p0_5);
 CALL SYMPUT("treated_1",p1);
RUN;
/* Labeling the percentiles at the upper extremes of the untreated in macro variables
which can be called later. Defining the maximum, 99th, and 99.5th percentile of the untreated. */
DATA _NULL_;
 SET ps_pctl;
 WHERE &drug1 = 0;
 CALL SYMPUT("untreated_max",max);
 CALL SYMPUT("untreated_99",p99);
 CALL SYMPUT("untreated_995",p99_5);
RUN;
/* When applying PS weights to analyses, these defined percentiles can be applied to trim areas
of non-overlap and individuals treated contrary to prediction.
To trim non-overlapping regions of the PS distribution, include the following statement
in the modeling procedure: WHERE &treated_min <= ps <= &untreated_max;
To trim those treated contrary to prediction, include the following
statement: WHERE &treated_05 <= ps <= &untreated_995
Trimming percentiles can be moved in progressively as far as desired */
/********************************************/

/* Checking for treatment effect  */
/* heterogeneity */

/* TABLE 1*/ 
%include "/nearline/files/projects/medicare/incretinRetinopathy/programs/macros/table1.sas";

/*%LET drug1=glp;
%LET drug2=lai;*/
%LET wgtvar=&weight. ;

proc format; value &drug1. 0="&drug2." 1="&drug1."; run;
proc datasets lib=work nolist nodetails; modify psdsnmi; format &drug1. &drug1..; run;

   %table1(inds=psdsnmi, colVar=&drug1., rowVars=

age gender  
/*TableS3*/
racecat year
/*eye COMORBIDITY*/ 
bl_diabRetinopathy
/*ONLY including both bl_diabRetinopahty, DOES NOT including bnFills_diabRetinopathy*/
bl_amd bl_retinadeta bl_oretinal bl_cataract bl_glaucoma bl_ANYEDZEX_CAGDODT
/*diabetic COMORBIDITY*/ 
bl_nephropathy bl_neuropathy
/*CVD comorbidity*/
bl_hypertension bl_dyslipidemia bl_ischemichtdz bl_cerebrovasculardz bl_peripheralvdz bl_chf
/*other comorbidity*/
bl_COPD bl_DEPRESSION bl_cancer bl_ckd
/*Co-Medications*/
bl_METFORMIN bl_sulf bl_tzd bl_dpp bl_glp bl_lai 
bl_agi bl_meglitinide bl_ACEI bl_ARB bl_BB bl_CCB bl_STATIN bl_LOOP bl_OTHERDIURETICS bl_fenofibrate bl_ANYBADRX
/*health care use*/
hyperglycemia /*eyeexam*/ /*bl_smoking*/
/*hba1c lipid*/ hospnoDM /*hospdaysDM*/ ervisitDM phvisit /*hospno hosp*/ ervisit flushot lics
/*CPT II codes*/
&clinical
, 
wgtVar=, maxLevels=8, outfile=Table1sd, title=);

data tab1_unwgt_&drug1.; 
      set final; 
   run;
   proc datasets lib=work nolist nodetails; delete final; run; quit;

   %table1(inds=psdsnmi, colVar=&drug1., rowVars=
 age gender  
/*TableS3*/
racecat year
/*eye COMORBIDITY*/ 
bl_diabRetinopathy
/*ONLY including both bl_diabRetinopahty, DOES NOT including bnFills_diabRetinopathy*/
bl_amd bl_retinadeta bl_oretinal bl_cataract bl_glaucoma bl_ANYEDZEX_CAGDODT
/*diabetic COMORBIDITY*/ 
bl_nephropathy bl_neuropathy
/*CVD comorbidity*/
bl_hypertension bl_dyslipidemia bl_ischemichtdz bl_cerebrovasculardz bl_peripheralvdz bl_chf
/*other comorbidity*/
bl_COPD bl_DEPRESSION bl_cancer bl_ckd
/*Co-Medications*/
bl_METFORMIN bl_sulf bl_tzd bl_dpp bl_glp bl_lai 
bl_agi bl_meglitinide bl_ACEI bl_ARB bl_BB bl_CCB bl_STATIN bl_LOOP bl_OTHERDIURETICS bl_fenofibrate bl_ANYBADRX
/*health care use*/
hyperglycemia /*eyeexam*/ /*bl_smoking*/
/*hba1c lipid*/ hospnoDM /*hospdaysDM*/ ervisitDM phvisit /*hospno hosp*/ ervisit flushot lics
/*CPT II codes*/
&clinical
, 
wgtVar=&weight., maxLevels=8, outfile=Table1sd, title=);
   
proc print data=tab1_unwgt_&drug1;run;
proc sql;
   create table table1mi as
   select a.row, a.&drug1., a.&drug2., a.sdiff label='Unwgted Stdz Diff',
      b.&drug2._wgt, b.sdiff as sdiff_wgt label='Wgted Stdz Diff', a.order, a.roworder
   from tab1_unwgt_&drug1. as a left join final(rename=(&drug2=&drug2._wgt)) as b
      on a.row=b.row and a.order=b.order and a.roworder=b.roworder
   order by order, roworder;
quit;


ods escapechar='~' ;
ods rtf file="&OutPath./Table 1mi_&drug1._&drug2._&mipara..rtf";
proc print data=table1mi noobs label; var row &drug1 &drug2 sdiff &drug2._wgt sdiff_wgt; run;
ods rtf close;

data ana.t1v_&weight._&drug1.v&drug2._&name._&mipara;
   set table1mi;
run;

   /* WEIGHTED TABLE 1 
 %table1( )

data unwgt; set final ; rename sdiff=sdiff_unwgt dpp=dpp_unwgt tzd=tzd_unwgt; run;

%table1(wgtVar=smrw)

data wgt; set final ; rename sdiff=sdiff_wgt tzd=tzd_wgt; drop dpp; run;

data final;
   merge unwgt wgt;
   by order order2 row;
run;


proc print data=final label;
   var row dpp_unwgt tzd_unwgt sdiff_unwgt tzd_wgt sdiff_wgt;
   label sdiff_unwgt='Unwgted Std Diff' sdiff_wgt='Wgted Std Diff' ;
run;*/


* d) Calculating Rate and Hazard Ratio *;

%Macro rate(type, induction, latency, def, in, out, outdata);


ODS RTF FILE="&outpath./table2mi_&mipara._output.rtf";
data dsnmi;
   set psdsnmi;
   endofstudy='30Sep2015'd;
   endofdrug = /*rxchangeeach*/ rxchange+&latency;
   if &type  ='ITT'  then enddate=min(threeyear, &def, death_dt, endPartAB, endofstudy);
   if &type  ='AT'   then enddate=min(endofdrug, &def, death_dt, endPartAB, endofstudy, &out
/****SENSITIVITY ANALYSIS 6****: censore adding LAI for DPP4 comparison and GLP vs TZD: date_LAI*/
/*,date_LAI*/
/************************************************************************************************/ 
/***********SENSITIVITY ANALYSIS 7****: censore adding "bad or good RX" ************************/
   /*,date_tamoxifen,    date_quinine,    date_chloroquine, date_mefloquine, date_digoxin,     date_ethambutol, 
       date_allopurinol,  date_sildenafil, date_docetaxel,   date_niacin,     date_latanoprost, date_isocarboxazid, 
       date_isotretinoin, date_vigabatrin, date_fingolimod,  date_interferon, date_fenofibrate */ 
/***********************************************************************************************/
                           );  
   IF  enddate<=&in then delete;
 else if enddate> &in and enddate=&def and &def ne . 
   then event=1; 
   else event=0;  
        time = (enddate-(&induction+&in)+1)/365.25;                      
 label   time = "person-year";   
      if   time > 0 then logtime=log(time/1000);
    else time =.;
      timedu = (enddate-(&induction+indexdate)+1)/365.25;
 label timedu = "duration fo Tx";
run;
/*******************************/
/*Calculate MEDIAN of follow-up*/
/*******************************/
ods output summary=mediantime;
Proc means data=dsnmi N sum median q1 q3;
   class &drug1;
   var time timedu;
   run;
Data mediantime(keep=&drug1 Nobs mediantime time_sum mediantimedu timedu_sum time_median time_q1 time_q3);        
   set mediantime;
   mediantime  =compress(put((time_median),  6.2))||" ("||compress(put((time_q1),  6.2))||"-"||compress(put((time_q3),  6.2))||")";  
   mediantimedu=compress(put((timedu_median),6.2))||" ("||compress(put((timedu_q1),6.2))||"-"||compress(put((timedu_q3),6.2))||")";  
   format time_sum 8.0;
   format timedu_sum 8.0;
   run;


   



/*******************************/
/******count NO. of event*******/
/*******************************/
ods output summary=event;
Proc means data=dsnmi sum;
   class &drug1;
   var event;
   run;

/*********************************/
/*Incidence Rate by POISSON model*/
/*********************************/
proc sort data=dsnmi; 
   by &drug1; 
run;

proc genmod data=dsnmi;
   by &drug1;
   class bene_id;
   model event= /dist=poisson offset=logtime;
   repeated subject=bene_id;
   estimate 'rate' int 1/exp;
   ods output estimates=rate;
   run;

Data rate(keep=&drug1 rate lbetaestimate lbetalowercl lbetauppercl);
   set rate;
   if Label='Exp(rate)';
   rate=compress(put((LBetaEstimate),6.1))||" ("||compress(put((LBetaLowerCL),6.1))||"-"||compress(put((LBetaUpperCL),6.1))||")";
   run;

*crude HR*;
ods output ParameterEstimates = crudehr;
Proc phreg data=dsnmi covsandwich(aggregate);
   id bene_id;
   model time*event(0)=&drug1 /ties=efron rl;
   title ' crude HR';
run;

Data crudehr(keep=&drug1 chr clcl cucl crudehr);
   set crudehr;
   &drug1=1;
   chr=exp(Estimate);
   clcl=exp(Estimate-1.96*StdErr);
   cucl=exp(Estimate+1.96*StdErr);
   crudehr=compress(put((hazardratio),6.2))||" ("||compress(put((HRlowerCL),6.2))||"-"||compress(put((HRupperCL),6.2))||")";
   run;

*adjusted HR-&weight*;
ods output ParameterEstimates =&WEIGHT;
proc phreg data=dsnmi covsandwich(aggregate);
   id bene_id;
   weight &weight; 
   model time*event(0)=&drug1 /ties=efron rl;
   title 'SMRW adjusted HR';
run;

Data &WEIGHT(keep=&drug1 whr wlcl wucl &weight.HR);
   set &WEIGHT;
   &drug1=1;
   whr=exp(Estimate);
   wlcl=exp(Estimate-1.96*StdErr);
   wucl=exp(Estimate+1.96*StdErr);
   &weight.hr=compress(put((hazardratio),6.2))||" ("||compress(put((HRlowerCL),6.2))||"-"||compress(put((HRupperCL),6.2))||")";
   run;

Data &outdata;
   length type $ 20 ;
   merge  mediantime event rate /*wtrate*/ crudehr &weight;
   by &drug1;
   ana="&type";
   type="&def";
   latency=&latency;
   induction=&induction;
   run;

Proc sort data=&outdata; 
   by descending &drug1; 
run;

ODS RTF CLOSE;
%mend;


/* rate(type, induction, latency, def, in, out, outdata);*/
/*PRIMARY/SECONDARY ANALYSIS; '30Sep2015'd=20361*/
  %rate('AT', 0, 30, def2, indexdate,   20361, dsnmi1);   *primary;
/*%rate('AT', 0, 30, def2, indexdate, sixmonths, dsn1);*/ *secondary_less6mon;
/*%rate('AT', 0, 30, def2, sixmonths, oneyear,  dsn1);*/  *secondary_6to12mon;
/*%rate('AT', 0, 30, def2, oneyear,   20361,    dsn1);*/  *secondary_over12mon;

/*SENSITIVITY ANALYSIS 1: Various Latency*/
/*%rate('AT',    0, 0, def2, dsn1);*/
/*%rate('AT',    0, 60, def2, dsn1);*/
/*%rate('AT',    0, 90, def2, dsn1);*/
/*%rate('AT',    0, 180, def2, dsn1);*/

/*SENSITIVITY ANALYSIS 2: ITT*/
/*%rate('ITT',   0, 30, def2, dsn1);*/

/*SENSITIVITY ANALYSIS 3: Secondary Outcome*/ /*after sensitivity analysis 3, GO BACK TO primary analysis mode!!!*/
/*%rate('AT' ,    0, 30, def3, dsn1);*/
/*%rate('AT' ,    0, 30, dx_retinopathy_icd9, dsn1);*/
/*PRIMARY/SECONDARY ANALYSIS*/


Data outmi_&drug1.v&drug2._&mipara
(keep=
&drug1 Nobs 
mediantime 
time_sum event_sum 
rate 
crudehr &weight.HR whr wlcl wucl
ana induction latency exp unexp 
time_median time_q1 time_q3 lbetaestimate lbetalowercl lbetauppercl chr clcl cucl);
   set dsnmi1;
   exp="&drug1";
   unexp="&drug2";
   label event_Sum="No. of Event"
          time_Sum = "Person-year";
   run;
/*reorder variables*/
Data ana.outmi_&weight._&drug1.v&drug2._&name._&mipara;
   retain 
&drug1 Nobs 
mediantime 
time_sum event_sum 
rate 
crudehr &weight.HR whr wlcl wucl
ana induction latency exp unexp
time_median time_q1 time_q3 lbetaestimate lbetalowercl lbetauppercl chr clcl cucl; 
   set outmi_&drug1.v&drug2._&mipara;
run;

/*may end here for "replacing"*/

%END;
%Mend;

/****************************************************************************************************************************/
/*******************************************STEP 1. RUN ANALYSIS*************************************************************/
/****************************************************************************************************************************/
/*ATU, can't include SU in PS model othwise weighted SD>0.1:
%analysismi(dsn_glogit_t20, 1, glp, lai, smrw, bl_chf bl_dpp bl_TZD  bl_dpp*year bl_dpp*age bl_dpp*age*age, primary, a1c, 0, 2, a1c sbp dbp ldl, a1c(ref='1') sbp(ref=first) dbp(ref=first) ldl(ref=first)); 
*a1c<7%;
%analysismi(dsn_glogit_t20, 1, glp, lai, smrw, bl_chf bl_dpp bl_TZD  bl_dpp*year bl_dpp*age bl_dpp*age*age, a1cless7,a1c, 0, 0, a1c sbp dbp ldl, a1c(ref='1') sbp(ref=first) dbp(ref=first) ldl(ref=first));
*a1c 7-9%; 
%analysismi(dsn_glogit_t20, 1, glp, lai, smrw, bl_chf bl_dpp bl_TZD  bl_dpp*year bl_dpp*age bl_dpp*age*age, a1c7to9, a1c, 1, 1, a1c sbp dbp ldl, a1c(ref='1') sbp(ref=first) dbp(ref=first) ldl(ref=first)); 
*a1c >9%; 
%analysismi(dsn_glogit_t20, 1, glp, lai, smrw, bl_chf bl_dpp bl_TZD  bl_dpp*year bl_dpp*age bl_dpp*age*age, a1cover9,a1c, 2, 2, a1c sbp dbp ldl, a1c(ref='1') sbp(ref=first) dbp(ref=first) ldl(ref=first));*/ 

*ATT, include SU in PS model;


%analysismi(glogit_t50a1c,      1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, primary,   a1c,      0, 2, a1c           , a1c     (ref='1')                                           );
%analysismi(glogit_t50a1c_uf,   1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, prim_uf,   a1c_uf,   0, 2, a1c_uf        , a1c_uf  (ref='1')                                           );
%analysismi(glogit_t50a1c_30,   1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, primary30, a1c_30,   0, 2, a1c_30        , a1c_30  (ref='1')                                           );

%analysismi(proov_t50a1c,       1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year,  prov,     a1c,      0, 2, a1c           , a1c     (ref='1')                                           );
%analysismi(proov_t50a1c_uf,    1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year,  provuf,   a1c_uf,   0, 2, a1c_uf        , a1c_uf  (ref='1')                                           );
%analysismi(proov_t50a1c_30,    1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year,  prov30,   a1c_30,   0, 2, a1c_30        , a1c_30  (ref='1')                                           );

/*not necessary, most measured within 30 days not followed by antoehr test/hospitalization
%analysismi(glogit_t50a1c_30uf, 1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, prim_30uf, a1c_30uf, 0, 2, a1c_30uf      , a1c_30uf(ref='1')                                           );*/

*PRIMARY, a1c<7%, a1c 7-9%,a1c >9%; 
%analysismi(glogit_t50a1c,      1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a1cless7,  a1c,      0, 0, a1c           , a1c(ref='0')                                              );
%analysismi(glogit_t50a1c,      1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a7to9,     a1c,      1, 1, a1c           , a1c(ref='1')                                              );
%analysismi(glogit_t50a1c,      1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, agt9,      a1c,      2, 2, a1c           , a1c(ref='2')                                              );
*Unfollow, a1c<7%, a1c 7-9%,a1c >9%; 
%analysismi(glogit_t50a1c_uf,   1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, alt7uf,     a1c_uf,   0, 0, a1c_uf        , a1c_uf(ref='0')                                              );
%analysismi(glogit_t50a1c_uf,   1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a7t9uf,     a1c_uf,   1, 1, a1c_uf        , a1c_uf(ref='1')                                              );
%analysismi(glogit_t50a1c_uf,   1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, agt9uf,     a1c_uf,   2, 2, a1c_uf        , a1c_uf(ref='2')                                              );
*Last30, a1c<7%, a1c 7-9%,a1c >9%; 
%analysismi(glogit_t50a1c_30,   1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, alt730,     a1c_30,   0, 0, a1c_30        , a1c_30(ref='0')                                              );
%analysismi(glogit_t50a1c_30,   1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a7t930,     a1c_30,   1, 1, a1c_30        , a1c_30(ref='1')                                              );
%analysismi(glogit_t50a1c_30,   1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, agt930,     a1c_30,   2, 2, a1c_30        , a1c_30(ref='2')                                              );

*PRIMARY, a1c<7%, a1c 7-9%,a1c >9%; 
%analysismi(proov_t50a1c,      1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a7p,      a1c,      0, 0, a1c           , a1c(ref='0')                                              );
%analysismi(proov_t50a1c,      1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a79p,     a1c,      1, 1, a1c           , a1c(ref='1')                                              );
%analysismi(proov_t50a1c,      1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a9p,      a1c,      2, 2, a1c           , a1c(ref='2')                                              );
*Unfollow, a1c<7%, a1c 7-9%,a1c >9%; 
%analysismi(proov_t50a1c_uf,   1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a7puf,    a1c_uf,   0, 0, a1c_uf        , a1c_uf(ref='0')                                              );
%analysismi(proov_t50a1c_uf,   1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a79puf,   a1c_uf,   1, 1, a1c_uf        , a1c_uf(ref='1')                                              );
%analysismi(proov_t50a1c_uf,   1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a9puf,     a1c_uf,   2, 2, a1c_uf        , a1c_uf(ref='2')                                              );
*Last30, a1c<7%, a1c 7-9%,a1c >9%;
%analysismi(proov_t50a1c_30,   1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a7p30,     a1c_30,   0, 0, a1c_30        , a1c_30(ref='0')                                              );
%analysismi(proov_t50a1c_30,   1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a79p30,    a1c_30,   1, 1, a1c_30        , a1c_30(ref='1')                                              );
%analysismi(proov_t50a1c_30,   1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a9p30,     a1c_30,   2, 2, a1c_30        , a1c_30(ref='2')                                              );
/*
%analysismi(glogit_t20a1c, 1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a1conly, a1c, 0, 2, a1c           , a1c(ref='1')                                              );
%analysismi(dsn_glogit_t20, 1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, primary, a1c, 0, 2, a1c sbp dbp ldl, a1c(ref='1') sbp(ref=first) dbp(ref=first) ldl(ref=first)); 
*a1c<7%;
%analysismi(dsn_glogit_t20, 1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a1cless7,a1c, 0, 0, a1c sbp dbp ldl, a1c(ref='0') sbp(ref=first) dbp(ref=first) ldl(ref=first));
*a1c 7-9%; 
%analysismi(dsn_glogit_t20, 1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a1c7to9, a1c, 1, 1, a1c sbp dbp ldl, a1c(ref='1') sbp(ref=first) dbp(ref=first) ldl(ref=first)); 
*a1c >9%; 
%analysismi(dsn_glogit_t20, 1, glp, lai, smrw, bl_chf bl_dpp bl_TZD bl_SULF bl_dpp*year bl_TZD*year bl_sulf*year, a1cover9,a1c, 2, 2, a1c sbp dbp ldl, a1c(ref='2') sbp(ref=first) dbp(ref=first) ldl(ref=first)); 












/****************************************************************************************************/
/******************************STEP 2. SUMMARIZE ANALYSIS: TABLE 2.**********************************/
/****************************************************************************************************/
*resubmit analysis each time before combining data!;
/****************************************************************************************************/
%let weight=smrw;
%macro table2mi(drug1,drug2,name);
Data table2mi_&drug1.v&drug2._&name;
   set ana.outmi_&weight._&drug1.v&drug2._&name.:; 
     label time_Sum = "Person-year"
          event_Sum = "No. of Event";
       if event_Sum NE 0;
   run;

DATA lgshr_t; 
SET table2mi_&drug1.v&drug2._&name.(WHERE=(&drug1=1)); 
log_whr=LOG(whr); 
log_wse=(LOG(wucl)-LOG(wlcl))/(2*1.96); 
RUN; 

DATA lgshr_tc; 
SET table2mi_&drug1.v&drug2._&name.(WHERE=(&drug1=1)); 
log_chr=LOG(chr); 
log_cse=(LOG(cucl)-LOG(clcl))/(2*1.96); 
RUN; 

*** Combine transformed estimates; 
PROC MIANALYZE DATA=lgshr_t; 
ODS OUTPUT PARAMETERESTIMATES=mian_lgshr_t; 
MODELEFFECTS log_whr; 
STDERR log_wse; 
RUN;

PROC MIANALYZE DATA=lgshr_tc; 
ODS OUTPUT PARAMETERESTIMATES=mian_lgshr_tc; 
MODELEFFECTS log_chr; 
STDERR log_cse; 
RUN;

*** Back-transform combined values; 
DATA mian_lgshr_&drug1.v&drug2._&name;
	SET mian_lgshr_t; 
		Estimate_back = EXP(ESTIMATE); 			  *Pooled odds ratio; 
		LCL_back=Estimate_back*EXP(-1.96*STDERR); *Pooled lower limit; 
		UCL_back=Estimate_back*EXP(+1.96*STDERR); *Pooled upper limit; 
		miwhr=compress(put((estimate_back),6.2))||" ("||compress(put((lcl_back),6.2))||"-"||compress(put((ucl_back),6.2))||")";
run;

data mi_lgshr_acnu; set mi_lgshr_acnu; 
	Estimate_pool = EXP(ESTIMATE); 			  *Pooled odds ratio; 
	LCL_pool=Estimate_pool*EXP(-1.96*STDERR); *Pooled lower limit; 
	UCL_pool=Estimate_pool*EXP(+1.96*STDERR); *Pooled upper limit; 
	miwhr=compress(put((estimate_pool),6.2))||" ("||compress(put((lcl_pool),6.2))||"-"||compress(put((ucl_pool),6.2))||")";
run;
proc print data=   mi_lgshr_acnu;  
run; 

DATA mian_lgshrc_&drug1.v&drug2._&name;
	SET mian_lgshr_tc; 
		Estimate_backc = EXP(ESTIMATE); 			*Pooled odds ratio; 
		LCL_backc=Estimate_backc*EXP(-1.96*STDERR); *Pooled lower limit; 
		UCL_backc=Estimate_backc*EXP(+1.96*STDERR); *Pooled upper limit; 
		michr=compress(put((estimate_backc),6.2))||" ("||compress(put((lcl_backc),6.2))||"-"||compress(put((ucl_backc),6.2))||")";
run;


proc means data=table2mi_&drug1.v&drug2._&name mean noprint;
  	 var Nobs time_median time_q1 time_q3 time_sum event_sum lbetaestimate lbetalowercl lbetauppercl;
   		class &drug1.;
      output out=meanMedianRate_&drug1.v&drug2._&name 
      mean( Nobs  time_median  time_q1  time_q3  time_sum  event_sum  lbetaestimate  lbetalowercl  lbetauppercl)=
          MNobs Mtime_median Mtime_q1 Mtime_q3 Mtime_sum Mevent_sum Mlbetaestimate Mlbetalowercl Mlbetauppercl; 
   run;

data MedianRate_&drug1._&name (keep=&drug1. MNobs Mmediantime Mtime_sum Mevent_sum Mrate) 
	 medianrate_&drug2._&name (keep=&drug1. MNobs Mmediantime Mtime_sum Mevent_sum Mrate);
   set meanMedianRate_&drug1.v&drug2._&name;
   Mmediantime  =compress(put((Mtime_median),  6.2))||" ("||compress(put((Mtime_q1),  6.2))||"-"||compress(put((Mtime_q3),  6.2))||")";  
   		   Mrate=compress(put((MLBetaEstimate),6.1))||" ("||compress(put((MLBetaLowerCL),6.1))||"-"||compress(put((MLBetaUpperCL),6.1))||")";
   if &drug1.=1 then output medianrate_&drug1._&name;
   else if &drug1.=0 then output medianrate_&drug2._&name;
run;
Data MedianRateco_&drug1.v&drug2._&name;
   retain &drug1. MNobs Mmediantime Mtime_sum Mevent_sum Mrate;
   set medianrate_&drug1._&name medianrate_&drug2._&name;
   format MNobs COMMA12. Mevent_sum COMMA12. Mtime_sum COMMA12. ;
run;

data hrcrudewt_&drug1.v&drug2._&name (keep=&drug1. MNobs Mmediantime Mtime_sum Mevent_sum Mrate michr miwhr);
	merge MedianRateco_&drug1.v&drug2._&name 
		  mian_lgshrc_&drug1.v&drug2._&name 
		  mian_lgshr_&drug1.v&drug2._&name;
run;

data table2mi_&drug1.v&drug2._&name (drop= chr clcl cucl whr wlcl wucl time_median time_q1 time_q3 lbetaestimate lbetalowercl lbetauppercl);
   set table2mi_&drug1.v&drug2._&name;
run;

options orientation=landscape;
ODS rtf FILE="&outpath./table2mi_&weight._&drug1.v&drug2._&name..rtf";
Proc Print DATA=hrcrudewt_&drug1.v&drug2._&name;
title "&name &drug1. vs &drug2. Mean No., Mediantime,PY, #Event, crudeHR, weightHR";
run;

PROC PRINT DATA=mian_lgshr_&drug1.v&drug2._&name;
title "&name &drug1. vs &drug2. Mean of weighted HR from MI analysis";
RUN;

PROC PRINT DATA=mian_lgshrc_&drug1.v&drug2._&name;
title "&name &drug1. vs &drug2. Mean of crude HR from MI analysis";
RUN;

Proc Print DATA=MedianRateco_&drug1.v&drug2._&name;
title "&name &drug1. vs &drug2. Mean No., Mediantime,PY, #Event";
run;

PROC PRINT DATA=table2mi_&drug1.v&drug2._&name;
title "&name &drug1. vs &drug2. results from each MI analysis";
RUN;

ODS rtf CLOSE;
%mend;

%table2mi (glp,lai,primary);
%table2mi (glp,lai,prim_uf);
%table2mi (glp,lai,primary30);

%table2mi (glp,lai,prov);
%table2mi (glp,lai,provuf);
%table2mi (glp,lai,prov30);
/*
%table2mi (glp,lai,prim_30uf);*/

%table2mi (glp,lai,a1cless7);
%table2mi (glp,lai,a7to9);
%table2mi (glp,lai,agt9);

%table2mi (glp,lai,alt7uf);
%table2mi (glp,lai,a7t9uf);
%table2mi (glp,lai,agt9uf);

%table2mi (glp,lai,alt730);
%table2mi (glp,lai,a7t930);
%table2mi (glp,lai,agt930);

*violation of proportional odds assumption;
%table2mi (glp,lai,a7p);
%table2mi (glp,lai,a79p);
%table2mi (glp,lai,a9p);

%table2mi (glp,lai,a7puf);
%table2mi (glp,lai,a79puf);
%table2mi (glp,lai,a9puf);

%table2mi (glp,lai,a7p30);
%table2mi (glp,lai,a79p30);
%table2mi (glp,lai,a9p30);








%table2mi (dpp,su, primary);
%table2mi (dpp,tzd,primary);
%table2mi (glp,tzd,primary);
/**/

%table2mi (dpp,su, a1cless7);
%table2mi (dpp,tzd,a1cless7);
%table2mi (glp,tzd,a1cless7);
/**/
%table2mi (dpp,su, a1c7to9);
%table2mi (dpp,tzd,a1c7to9);
%table2mi (glp,tzd,a1c7to9);
/**/
%table2mi (dpp,su, a1cover9);
%table2mi (dpp,tzd,a1cover9);
%table2mi (glp,tzd,a1cover9);

/***************************************************************************************************/
/***************************************************************************************************/
/************************************PROGRAM IS OVER!OVER!OVER!*************************************/
/***************************************************************************************************/
/***************************************************************************************************/

/***************************************************************************************************/
/**************Average C statistic of MI ***********************************************************/
/***************************************************************************************************/
%Macro Cstatistic(name);
data ps_c;
set ana.ps_c_&name._: ;
run;
proc contents data=ps_c;run;
data c (keep= Label2 cValue2);
set ps_c;
if label1 = "Pairs";
run;
proc contents data=c;run;
data c_statistic;
   set c;
   Cvalue = input(cValue2, 8.);
run;
proc contents data=c_statistic;run;
proc sql;
	select label2, mean(Cvalue) as C_statistic from c_statistic;
quit;
%mend;
%Cstatistic(prov)
