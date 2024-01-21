/***************************************
SAS file name: 016_runanalysis.sas

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

CHANGES:
Date: see git 
Notes: etc
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=016_runanalysis, savelog=N, dataset=tmp);

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

%analysis ( exposure= , comparator=, ana_name=, type=, weight=, induction=, latency=, ibd_def= , intime= , outtime= , outdata= );

%analysis ( exposure=  
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

%macro analysis ( exposure , comparator , ana_name , type , weight , induction , latency , ibd_def , intime , outtime , outdata, save ) / minoperator mindelimiter=',';

/*===================================*\
//SECTION - Setting up data for analysis 
\*===================================*/
/* region */

data dsn; set a.ps_&exposure._&comparator;
    drop Alc_P_bc Alc_P_bl colo_bc colo_bl IBD_P_bc IBD_P_bl DivCol_I_bc DivCol_I_bl DivCol_P_bc DivCol_P_bl PCOS_bc PCOS_bl DiabGest_bc DiabGest_bl IBD_I_bc IBD_I_bl asthma_bc asthma_bl copd_bc copd_bl arrhyth_bc arrhyth_bl chf_bc chf_bl ihd_bc ihd_bl mi_bc mi_bl hyperten_bc hyperten_bl stroke_bc stroke_bl hyperlip_bc hyperlip_bl diab_bc diab_bl dvt_bc dvt_bl pe_bc pe_bl gout_bc 
    gout_bl pthyro_bc pthyro_bl mthyro_bc mthyro_bl depres_bc depres_bl affect_bc affect_bl suic_bc suic_bl sleep_bc sleep_bl schizo_bc schizo_bl epilep_bc epilep_bl renal_bc renal_bl GIulcer_bc GIulcer_bl RhArth_bc RhArth_bl alrhi_bc alrhi_bl glauco_bc glauco_bl migra_bc migra_bl sepsis_bc sepsis_bl pneumo_bc pneumo_bl nephr_bc nephr_bl nerop_bc nerop_bl dret_bc dret_bl psorI_bc psorI_bl psorP_bc psorP_bl vasc_bc vasc_bl SjSy_bc SjSy_bl sLup_bc sLup_bl PerArtD_bc PerArtD_bl AbdPain_bc AbdPain_bl Diarr_bc Diarr_bl BkStool_bc BkStool_bl Crohns_bc 
    Crohns_bl Ucolitis_bc Ucolitis_bl Icomitis_bc Icomitis_bl Gastent_bc Gastent_bl ColIle_bc ColIle_bl Sigmo_bc Sigmo_bl Biops_bc Biops_bl Ileo_bc Ileo_bl HBA1c_bc HBA1c_bl DPP4i_bc DPP4i_gc DPP4i_bl DPP4i_tot1yr SU_bc SU_gc SU_bl SU_tot1yr SGLT2i_bc SGLT2i_gc SGLT2i_bl SGLT2i_tot1yr TZD_bc TZD_gc TZD_bl TZD_tot1yr Insulin_bc Insulin_gc Insulin_bl Insulin_tot1yr bigua_bc bigua_gc bigua_bl bigua_tot1yr prand_bc prand_gc prand_bl prand_tot1yr agluco_bc agluco_gc agluco_bl agluco_tot1yr OAntGLP_bc OAntGLP_gc OAntGLP_bl OAntGLP_tot1yr AminoS_bc 
    AminoS_gc AminoS_bl AminoS_tot1yr Mesal_bc Mesal_gc Mesal_bl Mesal_tot1yr Sulfas_bc Sulfas_gc Sulfas_bl Sulfas_tot1yr Olsala_bc Olsala_gc Olsala_bl Olsala_tot1yr Balsal_bc Balsal_gc Balsal_bl Balsal_tot1yr ace_bc ace_gc ace_bl ace_tot1yr arb_bc arb_gc arb_bl arb_tot1yr bb_bc bb_gc bb_bl bb_tot1yr ccb_bc ccb_gc ccb_bl ccb_tot1yr nitrat_bc nitrat_gc nitrat_bl nitrat_tot1yr coronar_bc coronar_gc coronar_bl coronar_tot1yr antiarr_bc antiarr_gc antiarr_bl antiarr_tot1yr thrombo_bc thrombo_gc thrombo_bl thrombo_tot1yr antivitk_bc antivitk_gc 
    antivitk_bl antivitk_tot1yr hepar_bc hepar_gc hepar_bl hepar_tot1yr stat_bc stat_gc stat_bl stat_tot1yr fib_bc fib_gc fib_bl fib_tot1yr lla_bc lla_gc lla_bl lla_tot1yr thiaz_bc thiaz_gc thiaz_bl thiaz_tot1yr loop_bc loop_gc loop_bl loop_tot1yr kspar_bc kspar_gc kspar_bl kspar_tot1yr diurcom_bc diurcom_gc diurcom_bl diurcom_tot1yr thiaantih_bc thiaantih_gc thiaantih_bl thiaantih_tot1yr diurall_bc diurall_gc diurall_bl diurall_tot1yr ass_bc ass_gc ass_bl ass_tot1yr asscvd_bc asscvd_gc asscvd_bl asscvd_tot1yr allnsa_bc allnsa_gc allnsa_bl allnsa_tot1yr 
    para_bc para_gc para_bl para_tot1yr bago_bc bago_gc bago_bl bago_tot1yr abago_bc abago_gc abago_bl abago_tot1yr opio_bc opio_gc opio_bl opio_tot1yr acho_bc acho_gc acho_bl acho_tot1yr sterinh_bc sterinh_gc sterinh_bl sterinh_tot1yr lra_bc lra_gc lra_bl lra_tot1yr xant_bc xant_gc xant_bl xant_tot1yr ahist_bc ahist_gc ahist_bl ahist_tot1yr ahistc_bc ahistc_gc ahistc_bl ahistc_tot1yr h2_bc h2_gc h2_bl h2_tot1yr ppi_bc ppi_gc ppi_bl ppi_tot1yr IBD_bc IBD_gc IBD_bl IBD_tot1yr thyro_bc thyro_gc thyro_bl thyro_tot1yr sterint_bc sterint_gc sterint_bl 
    sterint_tot1yr stersys_bc stersys_gc stersys_bl stersys_tot1yr stertop_bc stertop_gc stertop_bl stertop_tot1yr gesta_bc gesta_gc gesta_bl gesta_tot1yr pill_bc pill_gc pill_bl pill_tot1yr HRTopp_bc HRTopp_gc HRTopp_bl HRTopp_tot1yr estr_bc estr_gc estr_bl estr_tot1yr adem_bc adem_gc adem_bl adem_tot1yr apsy_bc apsy_gc apsy_bl apsy_tot1yr benzo_bc benzo_gc benzo_bl benzo_tot1yr hypno_bc hypno_gc hypno_bl hypno_tot1yr ssri_bc ssri_gc ssri_bl ssri_tot1yr li_bc li_gc li_bl li_tot1yr mao_bc mao_gc mao_bl mao_tot1yr oadep_bc oadep_gc oadep_bl 
    oadep_tot1yr mnri_bc mnri_gc mnri_bl mnri_tot1yr adep_bc adep_gc adep_bl adep_tot1yr pheny_bc pheny_gc pheny_bl pheny_tot1yr barbi_bc barbi_gc barbi_bl barbi_tot1yr succi_bc succi_gc succi_bl succi_tot1yr valpro_bc valpro_gc valpro_bl valpro_tot1yr carba_bc carba_gc carba_bl carba_tot1yr oaconvu_bc oaconvu_gc oaconvu_bl oaconvu_tot1yr aconvu_bc aconvu_gc aconvu_bl 
    aconvu_tot1yr isupp_bc isupp_gc isupp_bl isupp_tot1yr TnfAI_bc TnfAI_gc TnfAI_bl TnfAI_tot1yr Budeo_bc Budeo_gc Budeo_bl Budeo_tot1yr OtherImm_bc OtherImm_gc OtherImm_bl OtherImm_tot1yr CycloSpor_bc CycloSpor_gc CycloSpor_bl CycloSpor_tot1yr Iso_oral_bc Iso_oral_gc Iso_oral_bl Iso_oral_tot1yr Iso_top_bc Iso_top_gc Iso_top_bl Iso_top_tot1yr Myco_bc Myco_gc Myco_bl Myco_tot1yr Etan_bc Etan_gc Etan_bl Etan_tot1yr Ipili_bc Ipili_gc Ipili_bl Ipili_tot1yr Ritux_bc Ritux_gc Ritux_bl Ritux_tot1yr EndOfLine  ;

   /* where indexdate=date of first Rx, filldate2=date of 2nd rx, and for the main analysis the entry=date of 2nd prescription */
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

    /* As Treated */ 
    %if %upcase(&type) eq AT %then %do;  
        enddate=min(endofdrug,switchAugmentdate , &ibd_def._dt,&outtime, discontDate,death_dt, endstudy_dt, dbexit_dt, enddt, LastColl_Dt ); /* AT exit date and AT exit_reason   */
        format enddate date9.; LABEL enddate="Date min of (&ibd_def._dt, switchAugmentdate, drug discontinuation, death_dt, endstudy_dt, dbexit_dt, enddt (end enroll), LastColl_Dt)";
        %end; 

    /* Initial Treatment */
    %else %if %upcase(&type) eq IT %then %do;
        enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
        format enddate date9. ; label enddate ="Date min of (&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt)";
        *"Date min of (&ibd_def._dt,death_dt, endstudy_dt, dbexit_dt, LastColl_Dt)";
        %end;
    %if %upcase(&type) # AT, IT %then %do;
        enddatedelete=min( &ibd_def._dt, enddt,endstudy_dt, &outtime);  
        %end;
        
    *Removing individuals who did not reach the induction period for followup ;
    IF enddatedelete<=(&intime + &induction) then deleteobs=1; 
        else deleteobs=0;
    IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne .    then event=1; else event=0;

    time=(enddate-(&intime.+&induction)+1)/365.25;
    time_drugdur=(min(rxchange, enddate)-(indexdate+1))/365.25;

    if time>0 then logtime=(log(time/100000))  ;
    else time=.;
    label time = "person-years" time_drugdur= "duration of treatment";
    
RUN;
/*=================*\
Update counts for exclusion
\*=================*/
PROC SQL; 
    create table tmp_counts as select * from temp.exclusions_015_&exposure._&comparator.;
    select count(*) into : num_obs from tmp_counts;
    insert into tmp_counts
        set exclusion_num=&num_obs+1, 
        long_text="Number of observations after excluding individuals whose &ibd_def._dt or endstudy_dt <= &intime. + &induction.",
        dpp4i= (select count(*) from dsn where (&exposure=1 and deleteobs=0)),
        dpp4i_diff= -(select count(*) from dsn where (&exposure=1 and deleteobs=1)),
        &comparator.=(select count(*) from dsn where (&exposure ne 1 and deleteobs=0)) ,
        &comparator._diff= -(select count(*) from dsn where (&exposure ne 1 and deleteobs=1)),   
        full= (select count(*) from dsn where (deleteobs=0));
    select * from tmp_counts;
QUIT;
data dsn; set dsn; if deleteobs=1 then delete; run;
proc sql;
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
    create table temp.exclusions_016_&exposure._&comparator._&type. as select * from tmp_counts;
    %end;
quit;
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
/* endregion //!SECTION */
/*===================================*\
//SECTION - output results 
\*===================================*/
Data &outdata;
    length type $ 32 ;
    length analysis $ 32 ;   
    merge mediantimetmp   event  (rename=(sum=event_sum)) rate crudehr &weight;
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
    Nobs type nmiss
    mediantime mediantimedu time_sum event_sum rate crudehr &weight.HR analysis induction latency exp unexp);
    set &outdata;
    exp="&exposure.";
    unexp="&comparator.";
    label event_Sum="No. of Event";
    label time_Sum = "Person-year";
run;

Data out_&exposure.v&comparator._&ana_name._&outdata.;
    retain &exposure Nobs TYPE time_sum event_sum rate crudehr &weight.HR analysis induction latency exp unexp; 
    set tmpout1;
        
    format event_sum best12.;
    format Nobs COMMA12. event_sum COMMA12. time_sum COMMA12. ;
run;
    
proc print ; 
run; 
 /* endregion //!SECTION */
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
proc sql; create table tmpp_b as select "&exposure."    as drug length=12 ,0 as fu_year,  count(id) as total_id, "No. at risk for &comparator initiator at 0 year" as label length=60 from &dataset where &exposure=0; quit;
proc sql; create table tmpp_a as select "&comparator." as drug length=12,0 as fu_year, count(id) as total_id, "No. at risk for &exposure initiator at 0 year" as label length=60 from &dataset where &exposure=1; quit;
/*No. of risk at 0.5 year*/
proc sql; create table tmpp_c as select "&exposure." as drug length=12,0.5 as fu_year,  count(id) as total_id, "No. at risk for &exposure initiator at 0.5 year" as label length=60 from &dataset where &timevar >=0.5 and &exposure=1; quit;
proc sql; create table tmpp_d as select "&comparator." as drug length=12,0.5 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 0.5 year" as label length=60 from &dataset where &timevar >=0.5 and &exposure=0; quit;
/*No. of risk at 1 year*/
proc sql; create table tmpp_e as select "&exposure." as drug length=12,1.0 as fu_year,  count(id) as total_id, "No. at risk for &exposure initiator at 1 year" as label length=60 from &dataset where &timevar >=1 and &exposure=1; quit;
proc sql; create table tmpp_f as select "&comparator." as drug length=12,1.0 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 1 year" as label length=60 from &dataset where &timevar >=1 and &exposure=0; quit;
/*No. of risk at 1.5 year*/
proc sql; create table tmpp_g as select "&exposure." as drug length=12,1.5 as fu_year,  count(id) as total_id, "No. at risk for &exposure initiator at 1.5 year" as label length=60 from &dataset where &timevar >=1.5 and &exposure=1; quit;
proc sql; create table tmpp_h as select "&comparator." as drug length=12,1.5 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 1.5 year" as label length=60 from &dataset where &timevar >=1.5 and &exposure=0; quit;
/*No. of risk at 2 year*/
proc sql; create table tmpp_i as select "&exposure." as drug length=12,2 as fu_year,  count(id) as total_id, "No. at risk for &exposure initiator at 2 year" as label length=60 from &dataset where &timevar >=2 and &exposure=1; quit;
proc sql; create table tmpp_j as select "&comparator." as drug length=12,2 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 2 year" as label length=60 from &dataset where &timevar >=2 and &exposure=0; quit;
/*No. of risk at 2.5 year*/
proc sql; create table tmpp_k as select "&exposure." as drug length=12,2.5 as fu_year,  count(id) as total_id, "No. at risk for &exposure initiator at 2.5 year" as label length=60 from &dataset where &timevar >=2.5 and &exposure=1; quit;
proc sql; create table tmpp_l as select "&comparator." as drug length=12,2.5 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 2.5 year" as label length=60 from &dataset where &timevar >=2.5 and &exposure=0; quit;
/*No. of risk at 3 year*/
proc sql; create table tmpp_m as select "&exposure." as drug length=12,3 as fu_year,  count(id) as total_id, "No. at risk for &exposure initiator at 3 year" as label length=60 from &dataset where &timevar >=3 and &exposure=1; quit;
proc sql; create table tmpp_n as select "&comparator." as drug length=12,3 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 3 year" as label length=60 from &dataset where &timevar >=3 and &exposure=0; quit;

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

/* endregion //!SECTION */
%mend analysis;

/* endregion //!SECTION */
        ods excel file="&toutpath./TestT2_compiled_&todaysdate..xlsx"
        options (
            Sheet_interval="PROC"
            embedded_titles="NO"
            embedded_footnotes="NO"
        );
    %analysis ( exposure= dpp4i , comparator= su, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    %analysis ( exposure= dpp4i , comparator= tzd, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    %analysis ( exposure= dpp4i , comparator= sglt2i, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    %analysis ( exposure= dpp4i , comparator= su, ana_name=main, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=AT , save=N ) ;
    %analysis ( exposure= dpp4i , comparator= tzd, ana_name=main, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=AT , save=N ) ;
    %analysis ( exposure= dpp4i , comparator= sglt2i, ana_name=main, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=AT , save=N ) ;


	
    
%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);

ods excel close; 
