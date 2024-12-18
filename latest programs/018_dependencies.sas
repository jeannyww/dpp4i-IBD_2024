/* 
16_runanalysis.sas: %analysis Lines 1-386
17_dependencies.sas: %include Lines 
*/

/*===================================*\
//SECTION - %analysis() macro from 16_runanalysis.sas: Lines 1-386
\*===================================*/
/* region */

%macro analysis ( exposure , comparator , ana_name , type , weight , induction , latency , ibd_def , intime , outtime , outdata, save ) / minoperator mindelimiter=',';

/*===================================*\
//SECTION - Setting up data for analysis 
\*===================================*/
/* region */

data dsn; set a.PS_&exposure._&comparator._1yrlb;
   * drop Alc_P_bc Alc_P_bl colo_bc colo_bl IBD_P_bc IBD_P_bl DivCol_I_bc DivCol_I_bl DivCol_P_bc DivCol_P_bl PCOS_bc PCOS_bl DiabGest_bc DiabGest_bl IBD_I_bc IBD_I_bl asthma_bc asthma_bl copd_bc copd_bl arrhyth_bc arrhyth_bl chf_bc chf_bl ihd_bc ihd_bl mi_bc mi_bl hyperten_bc hyperten_bl stroke_bc stroke_bl hyperlip_bc hyperlip_bl diab_bc diab_bl dvt_bc dvt_bl pe_bc pe_bl gout_bc gout_bl pthyro_bc pthyro_bl mthyro_bc mthyro_bl depres_bc depres_bl affect_bc affect_bl suic_bc suic_bl sleep_bc sleep_bl schizo_bc schizo_bl epilep_bc epilep_bl renal_bc renal_bl GIulcer_bc GIulcer_bl RhArth_bc RhArth_bl alrhi_bc alrhi_bl glauco_bc glauco_bl migra_bc migra_bl sepsis_bc sepsis_bl pneumo_bc pneumo_bl nephr_bc nephr_bl nerop_bc nerop_bl dret_bc dret_bl psorI_bc psorI_bl psorP_bc psorP_bl vasc_bc vasc_bl SjSy_bc SjSy_bl sLup_bc sLup_bl PerArtD_bc PerArtD_bl AbdPain_bc AbdPain_bl Diarr_bc Diarr_bl BkStool_bc BkStool_bl Crohns_bc Crohns_bl Ucolitis_bc Ucolitis_bl Icomitis_bc Icomitis_bl Gastent_bc Gastent_bl ColIle_bc ColIle_bl Sigmo_bc Sigmo_bl Biops_bc Biops_bl Ileo_bc Ileo_bl HBA1c_bc HBA1c_bl DPP4i_bc DPP4i_gc DPP4i_bl DPP4i_tot1yr SU_bc SU_gc SU_bl SU_tot1yr SGLT2i_bc SGLT2i_gc SGLT2i_bl SGLT2i_tot1yr TZD_bc TZD_gc TZD_bl TZD_tot1yr Insulin_bc Insulin_gc Insulin_bl Insulin_tot1yr bigua_bc bigua_gc bigua_bl bigua_tot1yr prand_bc prand_gc prand_bl prand_tot1yr agluco_bc agluco_gc agluco_bl agluco_tot1yr OAntGLP_bc OAntGLP_gc OAntGLP_bl OAntGLP_tot1yr AminoS_bc AminoS_gc AminoS_bl AminoS_tot1yr Mesal_bc Mesal_gc Mesal_bl Mesal_tot1yr Sulfas_bc Sulfas_gc Sulfas_bl Sulfas_tot1yr Olsala_bc Olsala_gc Olsala_bl Olsala_tot1yr Balsal_bc Balsal_gc Balsal_bl Balsal_tot1yr ace_bc ace_gc ace_bl ace_tot1yr arb_bc arb_gc arb_bl arb_tot1yr bb_bc bb_gc bb_bl bb_tot1yr ccb_bc ccb_gc ccb_bl ccb_tot1yr nitrat_bc nitrat_gc nitrat_bl nitrat_tot1yr coronar_bc coronar_gc coronar_bl coronar_tot1yr antiarr_bc antiarr_gc antiarr_bl antiarr_tot1yr thrombo_bc thrombo_gc thrombo_bl thrombo_tot1yr antivitk_bc antivitk_gc 
    antivitk_bl antivitk_tot1yr hepar_bc hepar_gc hepar_bl hepar_tot1yr stat_bc stat_gc stat_bl stat_tot1yr fib_bc fib_gc fib_bl fib_tot1yr lla_bc lla_gc lla_bl lla_tot1yr thiaz_bc thiaz_gc thiaz_bl thiaz_tot1yr loop_bc loop_gc loop_bl loop_tot1yr kspar_bc kspar_gc kspar_bl kspar_tot1yr diurcom_bc diurcom_gc diurcom_bl diurcom_tot1yr thiaantih_bc thiaantih_gc thiaantih_bl thiaantih_tot1yr diurall_bc diurall_gc diurall_bl diurall_tot1yr ass_bc ass_gc ass_bl ass_tot1yr asscvd_bc asscvd_gc asscvd_bl asscvd_tot1yr allnsa_bc allnsa_gc allnsa_bl allnsa_tot1yr 
    para_bc para_gc para_bl para_tot1yr bago_bc bago_gc bago_bl bago_tot1yr abago_bc abago_gc abago_bl abago_tot1yr opio_bc opio_gc opio_bl opio_tot1yr acho_bc acho_gc acho_bl acho_tot1yr sterinh_bc sterinh_gc sterinh_bl sterinh_tot1yr lra_bc lra_gc lra_bl lra_tot1yr xant_bc xant_gc xant_bl xant_tot1yr ahist_bc ahist_gc ahist_bl ahist_tot1yr ahistc_bc ahistc_gc ahistc_bl ahistc_tot1yr h2_bc h2_gc h2_bl h2_tot1yr ppi_bc ppi_gc ppi_bl ppi_tot1yr IBD_bc IBD_gc IBD_bl IBD_tot1yr thyro_bc thyro_gc thyro_bl thyro_tot1yr sterint_bc sterint_gc sterint_bl 
    sterint_tot1yr stersys_bc stersys_gc stersys_bl stersys_tot1yr stertop_bc stertop_gc stertop_bl stertop_tot1yr gesta_bc gesta_gc gesta_bl gesta_tot1yr pill_bc pill_gc pill_bl pill_tot1yr HRTopp_bc HRTopp_gc HRTopp_bl HRTopp_tot1yr estr_bc estr_gc estr_bl estr_tot1yr adem_bc adem_gc adem_bl adem_tot1yr apsy_bc apsy_gc apsy_bl apsy_tot1yr benzo_bc benzo_gc benzo_bl benzo_tot1yr hypno_bc hypno_gc hypno_bl hypno_tot1yr ssri_bc ssri_gc ssri_bl ssri_tot1yr li_bc li_gc li_bl li_tot1yr mao_bc mao_gc mao_bl mao_tot1yr oadep_bc oadep_gc oadep_bl 
    oadep_tot1yr mnri_bc mnri_gc mnri_bl mnri_tot1yr adep_bc adep_gc adep_bl adep_tot1yr pheny_bc pheny_gc pheny_bl pheny_tot1yr barbi_bc barbi_gc barbi_bl barbi_tot1yr succi_bc succi_gc succi_bl succi_tot1yr valpro_bc valpro_gc valpro_bl valpro_tot1yr carba_bc carba_gc carba_bl carba_tot1yr oaconvu_bc oaconvu_gc oaconvu_bl oaconvu_tot1yr aconvu_bc aconvu_gc aconvu_bl 
    aconvu_tot1yr isupp_bc isupp_gc isupp_bl isupp_tot1yr TnfAI_bc TnfAI_gc TnfAI_bl TnfAI_tot1yr Budeo_bc Budeo_gc Budeo_bl Budeo_tot1yr OtherImm_bc OtherImm_gc OtherImm_bl OtherImm_tot1yr CycloSpor_bc CycloSpor_gc CycloSpor_bl CycloSpor_tot1yr Iso_oral_bc Iso_oral_gc Iso_oral_bl Iso_oral_tot1yr Iso_top_bc Iso_top_gc Iso_top_bl Iso_top_tot1yr Myco_bc Myco_gc Myco_bl Myco_tot1yr Etan_bc Etan_gc Etan_bl Etan_tot1yr Ipili_bc Ipili_gc Ipili_bl Ipili_tot1yr Ritux_bc Ritux_gc Ritux_bl Ritux_tot1yr EndOfLine  ;

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
        dpp4i= (select count(*) from dsn where (&exposure=1 and deleteobs=0)),
        dpp4i_diff= -(select count(*) from dsn where (&exposure=1 and deleteobs=1)),
        &comparator.=(select count(*) from dsn where (&exposure ne 1 and deleteobs=0)) ,
        &comparator._diff= -(select count(*) from dsn where (&exposure ne 1 and deleteobs=1)),   
        full= (select count(*) from dsn where (deleteobs=0));
    insert into tmp_counts
        set exclusion_num=&num_obs+2, 
        long_text="Number of individuals with time0 <&ibd_def._dt <= &intime. + &induction.",
        dpp4i= (select count(*) from dsn where (&exposure=1 and IBDdx_inductionperiod=0)),
        dpp4i_diff= -(select count(*) from dsn where (&exposure=1 and IBDdx_inductionperiod=1)),
        &comparator.=(select count(*) from dsn where (&exposure ne 1 and IBDdx_inductionperiod=0)) ,
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
        dpp4i= (select count(*) from dsn where (&exposure=1 and time ne .)),
        dpp4i_diff= -(select count(*) from dsn where (&exposure=1 and time eq .)),
        &comparator.=(select count(*) from dsn where (&exposure ne 1 and time ne .)) ,
        &comparator._diff= -(select count(*) from dsn where (&exposure ne 1 and time eq .)),   
        full= (select count(*) from dsn where (time ne .));
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

Data out_&exposure.v&comparator._&ana_name._&outdata.;
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
ods excel options(sheet_interval="NOW");
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

proc print data= out_&exposure.v&comparator._&ana_name._&outdata. ; 
run; 

%mend analysis;
/* endregion //!SECTION */


/*===================================*\
//SECTION - ## 6. Analysis a la Abrahami, adapted from 016_analysis.sas
\*===================================*/
/* region */



%macro analysis_Ab (exclude_ibd, exposure , comparator , ana_name , type , weight , induction , latency , ibd_def , intime , outtime , outdata, save ) / minoperator mindelimiter=',';

    /*===================================*\
    //SECTION - Setting up data for analysis 
    \*===================================*/
        %if &exclude_ibd. eq Y %then %do;
            data dsn; set a.Abrahami_PS_&exposure._&comparator; where IBD_ever ne 1;RUN; 
        %end;
        %else %if &exclude_ibd. eq N %then %do;
            data dsn; set a.Abrahami_PS_&exposure._&comparator; RUN;
        %end;
        data dsn; set dsn; 
        drop Alc_P_bc Alc_P_bl colo_bc colo_bl IBD_P_bc IBD_P_bl DivCol_I_bc DivCol_I_bl DivCol_P_bc DivCol_P_bl PCOS_bc PCOS_bl DiabGest_bc DiabGest_bl IBD_I_bc IBD_I_bl asthma_bc asthma_bl copd_bc copd_bl arrhyth_bc arrhyth_bl chf_bc chf_bl ihd_bc ihd_bl mi_bc mi_bl hyperten_bc hyperten_bl stroke_bc stroke_bl hyperlip_bc hyperlip_bl diab_bc diab_bl dvt_bc dvt_bl pe_bc pe_bl gout_bc 
        gout_bl pthyro_bc pthyro_bl mthyro_bc mthyro_bl depres_bc depres_bl affect_bc affect_bl suic_bc suic_bl sleep_bc sleep_bl schizo_bc schizo_bl epilep_bc epilep_bl renal_bc renal_bl GIulcer_bc GIulcer_bl RhArth_bc RhArth_bl alrhi_bc alrhi_bl glauco_bc glauco_bl migra_bc migra_bl sepsis_bc sepsis_bl pneumo_bc pneumo_bl nephr_bc nephr_bl nerop_bc nerop_bl dret_bc dret_bl psorI_bc psorI_bl psorP_bc psorP_bl vasc_bc vasc_bl SjSy_bc SjSy_bl sLup_bc sLup_bl PerArtD_bc PerArtD_bl AbdPain_bc AbdPain_bl Diarr_bc Diarr_bl BkStool_bc BkStool_bl Crohns_bc 
        Crohns_bl Ucolitis_bc Ucolitis_bl Icomitis_bc Icomitis_bl Gastent_bc Gastent_bl ColIle_bc ColIle_bl Sigmo_bc Sigmo_bl Biops_bc Biops_bl Ileo_bc Ileo_bl HBA1c_bc HBA1c_bl DPP4i_bc DPP4i_gc DPP4i_bl DPP4i_tot1yr SU_bc SU_gc SU_bl SU_tot1yr SGLT2i_bc SGLT2i_gc SGLT2i_bl SGLT2i_tot1yr TZD_bc TZD_gc TZD_bl TZD_tot1yr Insulin_bc Insulin_gc Insulin_bl Insulin_tot1yr bigua_bc bigua_gc bigua_bl bigua_tot1yr prand_bc prand_gc prand_bl prand_tot1yr agluco_bc agluco_gc agluco_bl agluco_tot1yr OAntGLP_bc OAntGLP_gc OAntGLP_bl OAntGLP_tot1yr AminoS_bc 
        AminoS_gc AminoS_bl AminoS_tot1yr Mesal_bc Mesal_gc Mesal_bl Mesal_tot1yr Sulfas_bc Sulfas_gc Sulfas_bl Sulfas_tot1yr Olsala_bc Olsala_gc Olsala_bl Olsala_tot1yr Balsal_bc Balsal_gc Balsal_bl Balsal_tot1yr ace_bc ace_gc ace_bl ace_tot1yr arb_bc arb_gc arb_bl arb_tot1yr bb_bc bb_gc bb_bl bb_tot1yr ccb_bc ccb_gc ccb_bl ccb_tot1yr nitrat_bc nitrat_gc nitrat_bl nitrat_tot1yr coronar_bc coronar_gc coronar_bl coronar_tot1yr antiarr_bc antiarr_gc antiarr_bl antiarr_tot1yr thrombo_bc thrombo_gc thrombo_bl thrombo_tot1yr antivitk_bc antivitk_gc 
        antivitk_bl antivitk_tot1yr hepar_bc hepar_gc hepar_bl hepar_tot1yr stat_bc stat_gc stat_bl stat_tot1yr fib_bc fib_gc fib_bl fib_tot1yr lla_bc lla_gc lla_bl lla_tot1yr thiaz_bc thiaz_gc thiaz_bl thiaz_tot1yr loop_bc loop_gc loop_bl loop_tot1yr kspar_bc kspar_gc kspar_bl kspar_tot1yr diurcom_bc diurcom_gc diurcom_bl diurcom_tot1yr thiaantih_bc thiaantih_gc thiaantih_bl thiaantih_tot1yr diurall_bc diurall_gc diurall_bl diurall_tot1yr ass_bc ass_gc ass_bl ass_tot1yr asscvd_bc asscvd_gc asscvd_bl asscvd_tot1yr allnsa_bc allnsa_gc allnsa_bl allnsa_tot1yr 
        para_bc para_gc para_bl para_tot1yr bago_bc bago_gc bago_bl bago_tot1yr abago_bc abago_gc abago_bl abago_tot1yr opio_bc opio_gc opio_bl opio_tot1yr acho_bc acho_gc acho_bl acho_tot1yr sterinh_bc sterinh_gc sterinh_bl sterinh_tot1yr lra_bc lra_gc lra_bl lra_tot1yr xant_bc xant_gc xant_bl xant_tot1yr ahist_bc ahist_gc ahist_bl ahist_tot1yr ahistc_bc ahistc_gc ahistc_bl ahistc_tot1yr h2_bc h2_gc h2_bl h2_tot1yr ppi_bc ppi_gc ppi_bl ppi_tot1yr IBD_bc IBD_gc IBD_bl IBD_tot1yr thyro_bc thyro_gc thyro_bl thyro_tot1yr sterint_bc sterint_gc sterint_bl 
        sterint_tot1yr stersys_bc stersys_gc stersys_bl stersys_tot1yr stertop_bc stertop_gc stertop_bl stertop_tot1yr gesta_bc gesta_gc gesta_bl gesta_tot1yr pill_bc pill_gc pill_bl pill_tot1yr HRTopp_bc HRTopp_gc HRTopp_bl HRTopp_tot1yr estr_bc estr_gc estr_bl estr_tot1yr adem_bc adem_gc adem_bl adem_tot1yr apsy_bc apsy_gc apsy_bl apsy_tot1yr benzo_bc benzo_gc benzo_bl benzo_tot1yr hypno_bc hypno_gc hypno_bl hypno_tot1yr ssri_bc ssri_gc ssri_bl ssri_tot1yr li_bc li_gc li_bl li_tot1yr mao_bc mao_gc mao_bl mao_tot1yr oadep_bc oadep_gc oadep_bl 
        oadep_tot1yr mnri_bc mnri_gc mnri_bl mnri_tot1yr adep_bc adep_gc adep_bl adep_tot1yr pheny_bc pheny_gc pheny_bl pheny_tot1yr barbi_bc barbi_gc barbi_bl barbi_tot1yr succi_bc succi_gc succi_bl succi_tot1yr valpro_bc valpro_gc valpro_bl valpro_tot1yr carba_bc carba_gc carba_bl carba_tot1yr oaconvu_bc oaconvu_gc oaconvu_bl oaconvu_tot1yr aconvu_bc aconvu_gc aconvu_bl 
        aconvu_tot1yr isupp_bc isupp_gc isupp_bl isupp_tot1yr TnfAI_bc TnfAI_gc TnfAI_bl TnfAI_tot1yr Budeo_bc Budeo_gc Budeo_bl Budeo_tot1yr OtherImm_bc OtherImm_gc OtherImm_bl OtherImm_tot1yr CycloSpor_bc CycloSpor_gc CycloSpor_bl CycloSpor_tot1yr Iso_oral_bc Iso_oral_gc Iso_oral_bl Iso_oral_tot1yr Iso_top_bc Iso_top_gc Iso_top_bl Iso_top_tot1yr Myco_bc Myco_gc Myco_bl Myco_tot1yr Etan_bc Etan_gc Etan_bl Etan_tot1yr Ipili_bc Ipili_gc Ipili_bl Ipili_tot1yr Ritux_bc Ritux_gc Ritux_bl Ritux_tot1yr EndOfLine  ;
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
/*=================*\
*!SECTION Update counts for exclusion
\*=================*/
PROC SQL noprint; 
    create table tmp_counts as select * from temp.Abexclusions_015_&exposure._&comparator.;
    select count(*) into : num_obs from tmp_counts;
    insert into tmp_counts
        set exclusion_num=&num_obs+1, 
        long_text="Number of observations after excluding individuals whose endstudy_dt <= &intime. + &induction.",
        dpp4i= (select count(*) from dsn where (&exposure=1 and deleteobs=0)),
        dpp4i_diff= -(select count(*) from dsn where (&exposure=1 and deleteobs=1)),
        &comparator.=(select count(*) from dsn where (&exposure ne 1 and deleteobs=0)) ,
        &comparator._diff= -(select count(*) from dsn where (&exposure ne 1 and deleteobs=1)),   
        full= (select count(*) from dsn where (deleteobs=0));
    insert into tmp_counts
        set exclusion_num=&num_obs+2, 
        long_text="Number of individuals with time0 <&ibd_def._dt <= &intime. + &induction.",
        dpp4i= (select count(*) from dsn where (&exposure=1 and IBDdx_inductionperiod=0)),
        dpp4i_diff= -(select count(*) from dsn where (&exposure=1 and IBDdx_inductionperiod=1)),
        &comparator.=(select count(*) from dsn where (&exposure ne 1 and IBDdx_inductionperiod=0)) ,
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
        dpp4i= (select count(*) from dsn where (&exposure=1 and time ne .)),
        dpp4i_diff= -(select count(*) from dsn where (&exposure=1 and time eq .)),
        &comparator.=(select count(*) from dsn where (&exposure ne 1 and time ne .)) ,
        &comparator._diff= -(select count(*) from dsn where (&exposure ne 1 and time eq .)),   
        full= (select count(*) from dsn where (time ne .));
    select * from tmp_counts;
    %if %upcase(&save) eq Y %then %do;
        create table temp.Abexclusions_016_&exposure._&comparator._&type. as select * from tmp_counts;
        %end;
quit;
proc print data= tmp_counts; run; 
data dsn; set dsn; if time eq . then delete;run;

PROC SQL noprint;
    create table tmp as
    SELECT id
    FROM dsn
    GROUP BY id
    HAVING COUNT(*) > 1;
    SELECT count (distinct id) as n FROM tmp;
QUIT;
*selecting all of the individuals who contributed twice, first to unexposed person time, then contributed to exposed person time ;
PROC SQL noprint;
    create table tmp2 as
    select a.* from dsn as a 
    inner join tmp as b on a.id=b.id order by a.id, a.indexdate;
    select count(distinct id) as n from tmp2;
QUIT;
title "Individuals who contributed twice, first to unexposed person time, then contributed to exposed person time";
PROC FREQ DATA=tmp2;
TABLES excludeflag_prevalentuser /list missing;
RUN;
proc means data=dsn 
    STACKODS N NMISS MEAN STD MIN MAX Q1 MEDIAN Q3   ;
    where time ne .; 
    class &exposure excludeflag_prevalentuser;    
    var  time time_drugdur ; 
run;

PROC FREQ DATA=dsn; 
TABLES dpp4i*excludeflag_prevalentuser*event /list missing;
RUN;
title; 
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
/* combine median followup time and median drug duration  */
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
/* count numbers of switchers */
ods output summary=switchers;
Proc means data=dsn sum stackods ;
    where time ne .; 
    class &exposure;
    var excludeflag_prevalentuser;RUN;
data switchers (rename=(sum=n_switch)); 
    set switchers;RUN;
/* count numbers with a history of IBD */
ods output summary=IBD_hx;
Proc means data=dsn sum stackods ;
    where time ne .; 
    class &exposure;
    var IBD_ever ;RUN;
data IBD_hx (rename=(sum=IBD_hx_sum)); 
    set IBD_hx;RUN;
/* count number of switchers who had a subsequent diagnosis of IBD */
ods output summary=IBD_event_switchers;
Proc means data=dsn sum stackods ;
    where time ne . and excludeflag_prevalentuser eq 1; 
    class &exposure;
    var &ibd_def. ;RUN;
data IBD_event_switchers (rename=(sum=IBD_event_switchers)); 
    set IBD_event_switchers;RUN;
/* count events missed due to events being attributed to Dpp4i initiators who were prevalent users of the comparator  (events that would have been in the comparator's person time as it would be in our Main IT analysis if not for the censoring at 180+switch/augment/fill2date date )*/
ods output summary= IBD_events_censored;
Proc means data=dsn sum stackods ;
    where time ne . and  event eq 0; 
    class &exposure;
    var &ibd_def. ;RUN;
data IBD_events_censored (rename=(sum=IBD_events_censored)); 
    set IBD_events_censored;RUN;
/* above outputs will be stored in work lib and merged in //Section- Output Results */

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
        class id;
        model &event= /dist=poisson offset=&logtimevar maxiter=100000;
        repeated subject=id;
        estimate 'rate' int 1/exp;
        ods output estimates=rate;
        run;
        Data rate(keep=&exposure rate);
        set rate;
        if Label='Exp(rate)';
        rate=compress(put((LBetaEstimate),6.1))||" ("||compress(put((LBetaLowerCL),6.1))||"-"||compress(put((LBetaUpperCL),6.1))||")";
    run;

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

    /*===================================*\
    //SECTION - output results 
    \*===================================*/
/* Merge and compile of counts, persontime, incidence rates, unweighted and SMR-weighted HRs */
    Data &outdata;
        length type $ 32 ;
        length analysis $ 32 ;   
        merge mediantimetmp   
        event  (rename=(sum=event_sum)) switchers (keep= &exposure n_switch) ibd_hx (keep= &exposure IBD_hx_sum) 
        ibd_event_switchers (keep= &exposure IBD_event_switchers)
        IBD_events_censored (keep= &exposure IBD_events_censored) 
        rate crudehr &weight;
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
        Nobs n_switch type nmiss
        mediantime mediantimedu time_sum event_sum IBD_event_switchers IBD_events_censored IBD_hx_sum rate crudehr &weight.HR analysis induction latency exp unexp);
        set &outdata;
        exp="&exposure.";
        unexp="&comparator.";
        label event_Sum="No. of Event";
        label time_Sum = "Person-year";
    run;
    Data out_&exposure.v&comparator._&ana_name._&outdata.;
        retain TYPE &exposure Nobs n_switch mediantime time_sum event_sum IBD_event_switchers IBD_events_censored IBD_hx_sum  rate crudehr &weight.HR analysis induction latency exp unexp; 
        set tmpout1;
            
        format event_sum best12.;
        format Nobs COMMA12. event_sum COMMA12. time_sum COMMA12. ibd_event_switchers COMMA12. IBD_events_censored COMMA12. IBD_hx_sum COMMA12. n_switch COMMA12. ;
    run;

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
/* Trigger ods excel to create a new sheet for the plots and main results */
ods excel options(sheet_interval="NOW");
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
    /* endregion //!SECTION */
    *gathering all results for print;
    DATA countout;
        SET tmpp_:;
        outcome_def="&ibd_def.";
    RUN;
    proc sort data= countout; by drug; run;
    proc transpose data=countout out=tmp prefix= fuyear; 
        by drug ; 
        id fu_year; run;
    proc print data= tmp  ;  
        variables drug fuyear:;
    run; 
    /* reprint of the unweighted and SMR-weighted results */
    proc print data= out_&exposure.v&comparator._&ana_name._&outdata. ; 
    run; 
%mend analysis_Ab;


/* endregion //!SECTION */

/*===================================*\
//SECTION - ## 5. PS weighting adapted from 015_PSweighting.sas
\*===================================*/
/* region */
%macro psweighting_Ab ( exposure , comparator , weight , addedmodelvars ,basemodelvars , refyear  , dat, save );

    data tmp1;
        set a.Abrahami_allmerged_&exposure._&comparator.;
    RUN;

    /*=================*\
    Table 1 untrimmed (appendix) - added 6/5/2024
    \*=================*/
    proc format; value &exposure. 0="&comparator." 1="&exposure."; run;
    proc datasets lib=work nolist nodetails; modify tmp1; 
        format &exposure. &exposure..  sex $sexf.  alcohol_cat $statusf. smoke_cat $statusf. hba1c_cat2  hba1cf. bmi_cat bmif.;
        run;
    %LET wgtvar=;
    %let ds = tmp1 ;
    %let colVar = &exposure.;
    %let rowVars = &tablerowvars. ;
    %LET outname = ;*Table1_Abrahami_Untrimmed_&exposure._&comparator._&todaysdate.; 
    options orientation=landscape nodate nonumber nocenter;
    %table1(inds= &ds, colVar= &colVar, rowVars= &rowVars, wgtVar= , maxLevels=16, outfile=&outname, title=&outname, cellsize=5);

    data tab1_untrimmed_&comparator.; 
        set final; run;
    proc datasets lib=work nolist nodetails; delete final; run; quit;

    ods escapechar='~' ;
    options orientation=landscape nodate nonumber nocenter;
    ods rtf file="&toutPath./Abrahami_Table1_Untrimmed_&exposure._&comparator._&todaysdate..rtf";
    proc print data=tab1_untrimmed_&comparator. noobs label; var row &exposure &comparator sdiff; run;
    ods rtf close;


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
        /* Updating exclusions for PS trimming */
        PROC SQL; 
            create table tmp_counts as select * from temp.Abexclusions_014_&exposure._&comparator.;
            select count(*) into : num_obs from tmp_counts;
            insert into tmp_counts
                set exclusion_num=&num_obs+1, 
                long_text="Number of observations after trimming at 0.05 treated and 0.995 untreated",
                dpp4i=&&n_&exposure._trim,
                dpp4i_diff=&&n_&exposure._trim-&&n_&exposure.,
                &comparator.=&&n_&comparator._trim,
                &comparator._diff=&&n_&comparator._trim-&&n_&comparator., 
                full=&&n_&exposure._trim+&&n_&comparator._trim;
            create table temp.Abexclusions_015_&exposure._&comparator. as select * from tmp_counts;
        QUIT;
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

%mend psweighting_Ab;
/* endregion //!SECTION */
