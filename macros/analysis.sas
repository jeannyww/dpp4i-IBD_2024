/***************************************
 SAS file name: analysis

Purpose: poisson rates, crude HR, weighted HR analysis macro 
Author: JHW
Creation Date: 13OCT23

   Program and output path:
           D:\Externe Projekte\UNC\wangje\sas
            D:\Externe Projekte\UNC\wangje\sas\prog
         libname temp D:\Externe Projekte\UNC\wangje\data\temp

   Input paths:
            libname raw D:\Externe Projekte\UNC\Task190813 - IBDandDPP4I (db19-1)\res\Task190813A_210429_SensitivityA
          libname a  D:\Externe Projekte\UNC\wangje\data\analysis
Other details: CPRD-DPP4i project in collaboration with USB

CHANGES:
Date: 13OCT23
Notes: initial commit
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\sas\macros");
%setup(programName=analysis, savelog=N, dataset=a0to7);

/*---------------------------------------------------------------------
%analysis(
 drugexp =  ,   *exposure drug of interest: DPP4i;
comparator =  , *comparator drug: SU TZD;    
ana_name =  ,    *analysis dataset: a0-a7;
type =  ,        *type of analysis: AT (as treated) or ITT (initial treatment);
weight =  ,       *type of weighting used: iptw, siptw, smrw, smrwu, ssmrwu;
induction =  ,    *induction period for dz initiation 180d;
latency =  ,      *latency period for dz detection 180d;
ibd_def =  ,      *IBD definition used (free text, ie main definition); 
intime =  ,       *time which analysis fu time will start, ie: entry (date of 2nd rx), initiation_date (date of 1st rx);
outtime =  ,      *time which analysis fu ends, ie for AT: '31Dec2017'd, for ITT: oneyearout twoyearout threeyearout fouryearout;
 outdata =        *freetext for your chosen name of the outdata results ;
)

%analysis ( drugexp= , comparator=, ana_name=, type=, weight=, induction=, latency=, ibd_def= , intime= , outtime= , outdata= );

%analysis ( drugexp=  
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

*poisson rates and HR analysis ;
%macro analysis ( drugexp , comparator , ana_name , type , weight , induction , latency , ibd_def , 
intime , outtime , outdata );
/*===================================*\
//SECTION - Macro 
\*===================================*/   
   
 DATA  psdsn;
SET  a.&ana_name._ps_&drugexp.v&comparator;
drop asthma_bc asthma_bl copd_bc copd_bl arrhyth_bc arrhyth_bl chf_bc chf_bl ihd_bc ihd_bl mi_bc mi_bl hyperten_bc hyperten_bl stroke_bc stroke_bl hyperlip_bc hyperlip_bl 
/* diab_bc diab_bl */ 
dvt_bc dvt_bl pe_bc pe_bl gout_bc gout_bl pthyro_bc pthyro_bl mthyro_bc mthyro_bl depres_bc depres_bl affect_bc affect_bl suic_bc suic_bl sleep_bc 
sleep_bl schizo_bc schizo_bl epilep_bc epilep_bl renal_bc renal_bl gIulcer_bc gIulcer_bl ra_bc ra_bl alrhi_bc alrhi_bl glauco_bc glauco_bl migra_bc 
migra_bl sepsis_bc sepsis_bl pneumo_bc pneumo_bl nephr_bc nephr_bl nerop_bc nerop_bl dret_bc dret_bl psorI_bc psorI_bl psorP_bc psorP_bl vasc_bc 
vasc_bl sjogr_bc sjogr_bl sle_bc sle_bl pad_bc pad_bl abdp_bc abdp_bl diarr_bc diarr_bl bstools_bc bstools_bl CD_bc CD_bl UC_bc UC_bl IC_bc IC_bl 
refendo_bc refendo_bl refgastro_bc refgastro_bl stomy_bc stomy_bl sigmoid_bc sigmoid_bl bx_bc bx_bl ileostomy_bc ileostomy_bl IBD_bc IBD_bl 
/* divertic_bc divertic_bl  */
ace_tot ace_last ace_first ace_code arb_tot arb_last arb_first arb_code bb_tot bb_last bb_first bb_code ccb_tot ccb_last ccb_first ccb_code nitrat_tot nitrat_last nitrat_first nitrat_code coronar_tot coronar_last coronar_first coronar_code antiarr_tot antiarr_last antiarr_first 
antiarr_code thrombo_tot thrombo_last thrombo_first thrombo_code antivitk_tot antivitk_last antivitk_first antivitk_code hepar_tot hepar_last hepar_first hepar_code 
/* insul_tot insul_last insul_first insul_code sulfon_tot sulfon_last sulfon_first sulfon_code bigua_tot bigua_last bigua_first bigua_code ppar_tot ppar_last ppar_first ppar_code prand_tot prand_last prand_first prand_code agluco_tot agluco_last agluco_first agluco_code adiabc_tot adiabc_last adiabc_first adiabc_code oadiab_tot oadiab_last oadiab_first oadiab_code alloadiab_tot alloadiab_last alloadiab_first alloadiab_code alladiab_tot alladiab_last alladiab_first alladiab_code */ 
stat_tot stat_last stat_first stat_code fib_tot fib_last fib_first fib_code lla_tot lla_last lla_first lla_code thiaz_tot thiaz_last thiaz_first 
thiaz_code loop_tot loop_last loop_first loop_code kspar_tot kspar_last kspar_first kspar_code diurcom_tot diurcom_last diurcom_first diurcom_code thiaantih_tot thiaantih_last thiaantih_first thiaantih_code 
diurall_tot diurall_last diurall_first diurall_code ass_tot ass_last ass_first ass_code cox2_tot cox2_last cox2_first cox2_code diclo_tot diclo_last diclo_first diclo_code ibu_tot ibu_last ibu_first ibu_code napro_tot napro_last napro_first napro_code otnsa_tot otnsa_last otnsa_first 
otnsa_code para_tot para_last para_first para_code allnsa_tot allnsa_last allnsa_first allnsa_code opio_tot opio_last opio_first opio_code acho_tot
acho_last acho_first acho_code sterinh_tot sterinh_last sterinh_first sterinh_code bago_tot bago_last bago_first bago_code abago_tot abago_last abago_first abago_code 
lra_tot lra_last lra_first lra_code xant_tot xant_last xant_first xant_code ahist_tot ahist_last ahist_first ahist_code ahistc_tot ahistc_last ahistc_first ahistc_code 
h2_tot h2_last h2_first h2_code ppi_tot ppi_last ppi_first ppi_code IBD_tot IBD_last IBD_first IBD_code thyro_tot thyro_last thyro_first thyro_code sterint_tot sterint_last sterint_first sterint_code stersys_tot stersys_last stersys_first stersys_code stertop_tot stertop_last stertop_first 
stertop_code gesta_tot gesta_last gesta_first gesta_code pill_tot pill_last pill_first pill_code adem_tot adem_last adem_first adem_code 
apsy_tot apsy_last apsy_first apsy_code benzo_tot benzo_last benzo_first benzo_code hypno_tot hypno_last hypno_first hypno_code ssri_tot ssri_last ssri_first ssri_code li_tot li_last li_first li_code
mao_tot mao_last mao_first mao_code oadep_tot oadep_last oadep_first oadep_code mnri_tot mnri_last mnri_first mnri_code adep_tot adep_last adep_first adep_code 
pheny_tot pheny_last pheny_first pheny_code barbi_tot barbi_last barbi_first barbi_code succi_tot succi_last succi_first succi_code valpro_tot valpro_last valpro_first valpro_code
carba_tot carba_last carba_first carba_code oaconvu_tot oaconvu_last oaconvu_first oaconvu_code aconvu_tot aconvu_last aconvu_first aconvu_code 
isupp_tot isupp_last isupp_first isupp_code 
/* dpp4i_tot dpp4i_last dpp4i_first dpp4i_code sulfonyl_tot sulfonyl_last sulfonyl_first sulfonyl_code  */
/* sglt2i_tot sglt2i_last sglt2i_first sglt2i_code TZD_tot TZD_last TZD_first TZD_code GLP1_tot GLP1_last GLP1_first GLP1_code */
/* metformin_tot metformin_last metformin_first metformin_code */
/* sitagliptin_tot sitagliptin_last sitagliptin_first sitagliptin_code vildagliptin_tot vildagliptin_last vildagliptin_first */
/* vildagliptin_code saxagliptin_tot saxagliptin_last saxagliptin_first saxagliptin_code linagliptin_tot linagliptin_last linagliptin_first linagliptin_code */
/* alogliptin_tot alogliptin_last alogliptin_first alogliptin_code  */
/* meglitinide_tot meglitinide_last meglitinide_first meglitinide_code 
 */ASA_tot ASA_last ASA_first ASA_code
mesala_tot mesala_last mesala_first mesala_code sulfasala_tot sulfasala_last sulfasala_first sulfasala_code 
olsala_tot olsala_last olsala_first olsala_code balsala_tot balsala_last balsala_first balsala_code
HRTopp_tot HRTopp_last HRTopp_first HRTopp_code HRToverall_tot
HRToverall_last HRToverall_first HRToverall_code TNFai_tot TNFai_last TNFai_first TNFai_code budes_tot budes_last budes_first
budes_code Adcombo_tot Adcombo_last Adcombo_first Adcombo_code immureg_tot immureg_last immureg_first immureg_code cyclosp_tot
cyclosp_last cyclosp_first cyclosp_code ;
RUN;  


/*===================================*\
//SECTION - Setting up data for rates 
\*===================================*/
   
/* note: need to clarify what the variable index date means--seems that it might mean the 
date of the 2nd rx of the drug?  */
data dsn;
   set psdsn;
   /* where entry=date of 2nd prescription */
    oneyear  =&intime.+365.25;
	twoyear=&intime.+730.5;
	threeyear=&intime.+1095.75;
	fouryear =&intime.+1460;
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

   /* outcome */
   caco_AT=caco; 
   label caco_AT = "case  status for AS Treated analysis ";
   enddate_AT=exit; /* AT exit date and AT exit_reason   */
   label enddate_AT = "enddate for as treated analysis";
   /* followup */
   time_AT=(enddate_AT-(&intime.+180)+1)/365.25; 
   label time_AT="fu time for as treated analysis";
   /* treatment duration */
   if exit_reason in (3,4) then do; /* switching or discontinuation */
   timedu_AT=(enddate_AT-180+1-initiation_date)/365.25;
   end; else if tx_status_rxchange ne . then do;
  timedu_AT=(&intime.-initiation_date+rxchange_day)/365.25;
   end;
else  do; 
   timedu_AT=(enddate_AT-initiation_date)/365.25;
   end; 
   label timedu_AT = "Duration of treatment for as treated analysis";
   if time_AT>0 then logtime_AT= log(time_AT/100000); else time_AT = .; 
   
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
   time_ITT=(enddate_ITT-(&intime.+180)+1)/365.25; 
   label time_ITT="fu time for Initial Treatment analysis";
   timedu_ITT=(enddate_ITT-&intime.+1)/365.25;
   label timedu_ITT = "Duration of treatment for initial treatment analysis";

   if time_ITT>0 then logtime_ITT=log(time_ITT/100000); else time_itt=.; 
   RUN;
 
/* endregion //!SECTION */

/*===================================*\
//SECTION - Getting median futime, dutime, and counts
\*===================================*/
/* median time of followup */
ods output summary=mediantime;
   proc means data = dsn 
      STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ;
        where time_&type ne .; 
   class &drugexp;
   var time_&type ;
   run;

ods output summary=mediantimedu;
   proc means data = dsn 
      STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ;
        where time_&type ne .; 
   class &drugexp;
   var  timedu_&type;
   run;

data mediantime(keep=&drugexp  NMISS Nobs mediantime sum );			
   set mediantime;
   mediantime  =compress(put((median),  6.2))||" ("||compress(put((q1),  6.2))||"-"||compress(put((q3),  6.2))||")"; 
   format sum 8.0;
   run; 
   
data mediantimedu(keep=&drugexp mediantimedu );			
   set mediantimedu;
   mediantimedu=compress(put((median),6.2))||" ("||compress(put((q1),6.2))||"-"||compress(put((q3),6.2))||")";  
   format sum 8.0;
   run; 

data mediantimetmp (rename=(sum=time_sum)) ; 
merge mediantime mediantimedu; by &drugexp; run;

/* count numbers of event  */
ods output summary=event;
Proc means data=dsn sum stackods;
        where time_&type ne .; 
   class &drugexp;
   var caco_&type  ;
   run;
   
   /* endregion //!SECTION */
/*===================================*\
//SECTION - Incident Rates Poisson
\*===================================*/
proc sort data=dsn; 
	by &drugexp; 
run;

%LET event = caco_&type;
%LET logtimevar = logtime_&type;
%LET timevar = time_&type;
proc genmod data=dsn;
   by &drugexp;
   * class id;
   model &event= /dist=poisson offset=&logtimevar maxiter=100000;
   * repeated subject=id;
   estimate 'rate' int 1/exp;
   ods output estimates=rate;
   run;
Data rate(keep=&drugexp rate);
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
   model &timevar*&event(0)=&drugexp /ties=efron rl;
   title ' crude HR';
run;
Data crudehr(keep=&drugexp chr clcl cucl crudehr);
   set crudehr;
   &drugexp=1;
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
   model  &timevar*&event(0)=&drugexp  /ties=efron rl;
   title 'SMRW adjusted HR';
run;
Data &WEIGHT(keep=&drugexp whr wlcl wucl &weight.HR);
   set &WEIGHT;
   &drugexp=1;
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
length analysis $ 32 ;   merge mediantimetmp   event  (rename=(sum=event_sum)) rate crudehr &weight;
   by &drugexp;
   analysis="&ana_name. &type. &outdata.";
   type="&ibd_def";
   latency=&latency;
   induction=&induction;
   run;
Proc sort data=&outdata; 
	by descending &drugexp; 
run;
Data tmpout1
(keep=&drugexp 
Nobs Nmiss
mediantime mediantimedu time_sum event_sum rate crudehr &weight.HR analysis induction latency exp unexp);
   set &outdata;
   exp="&drugexp";
   unexp="&comparator";
   label event_Sum="No. of Event";
   		 label time_Sum = "Person-year";
   run;

     Data out_&drugexp.v&comparator._&ana_name._&outdata.;
      retain &drugexp Nobs  time_sum event_sum rate crudehr &weight.HR analysis induction latency exp unexp; 
      set tmpout1;
      
   format event_sum best12.;
    format Nobs COMMA12. event_sum COMMA12. time_sum COMMA12. ;
   run;
   
proc print ; run; 
 /* endregion //!SECTION */
 /* endregion //!SECTION */
%mend analysis;
  
* %CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);
