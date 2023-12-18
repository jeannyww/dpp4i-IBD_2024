/***************************************
 SAS file name: cleandata.sas

Purpose: to clean CPRD DPP4i IBD data for all raw datasets
Author: jhw
Creation Date: 05OCT23

    Program and output path:
            D:\Externe Projekte\UNC\wangje\sas
                D:\Externe Projekte\UNC\wangje\sas\prog
            libname temp D:\Externe Projekte\UNC\wangje\data\temp

    Input paths:
                libname raw D:\Externe Projekte\UNC\Task190813 - IBDandDPP4I (db19-1)\res\Task190813A_210429_SensitivityA
             libname a  D:\Externe Projekte\UNC\wangje\data\analysis
Other details: CPRD-DPP4i project in collaboration with USB

CHANGES:
Date: 05OCT23
Notes: init commit  
***************************************/


/*cleandata*/
*looping through cleaning raw data into 1v1 data ;
%macro cleandata ( start , stop , outdat, dropvars=Y);


%do n=&start %to &stop; 

data origdat; set raw.SENSITIVITYA_&n;run;
/* region - Dummy cleaning*/
proc sql EXEC NOERRORSTOP;
  CREATE TABLE s0df as
  select * FROM
  ( SELECT distinct id, max(timep) as n_timepoints,  max(stop) as last_stop, max(start) as last_start
  from origdat
  group by id) as a

  INNER JOIN
/* keep first: create tx_at_0timep
keep last: create tx_at_lasttimep last_stop last_tx_status
 */
  (SELECT distinct id,
    tx_at_timep as tx_at_firsttimep,
	tx_status as tx_status_first
  FROM origdat
  GROUP BY id
  HAVING timep=min(timep)) as c
  ON a.id = c.id

  INNER JOIN

 ( select distinct id,
  tx_at_timep as tx_at_lasttimep,
  tx_status as tx_status_last,
  exit_reason  as exit_reason, 
  startstop as last_startstop
  from origdat
  group by id
  having timep=max(timep)) as b
  ON a.id=b.id

  INNER JOIN

  (select distinct * from origdat (drop=timep start stop startstop tx_at_timep tx_status exit_reason) as d)
  ON a.id=d.id; 

quit;

proc sql; 
create table s00df as select * from s0df as a 
  LEFT JOIN 
   
 ( select distinct id,
  max(tx_at_timep) as tx_at_rxchangetimep,
  max(tx_status) as tx_status_rxchange,
  max(stop) as rxchange_day, 
  max(timep) as rxchange_timep

  from origdat   where tx_status in (3,4)
  group by id) as e
  ON a.id = e.id;

quit; 


data s0df_aa; set s00df;
  /* formats */
  format entry exit date9.;
   /* 1st OOB: Create categories based on index tx */
  /* Create varaible that takes the very last timep , the start/stop date of timep, the exit_reason and the n_timepoints (max(time_p) in proc sql ) */

   /* create variable cohort, means which ACNU cohort the person started in  */
    length cohort $12 ;
    cohort="";
    label cohort = "Drug at index date: DPP4i; SU; SGLT2; TZD";
        if tx_at_firsttimep eq 8 then cohort="DPP4i";
        else if tx_at_firsttimep eq 4 then cohort="SU" ;
        else if tx_at_firsttimep eq 2 then cohort="SGLT2";
        else if tx_at_firsttimep eq 1 then cohort="TZD";
  RUN;




/* getting list of macro variables from csv  */

data labelin;
            infile "D:\Externe Projekte\UNC\wangje\sas\ref\labels.csv"
            dsd delimiter="," firstobs=2 ;
input cat $ var: $12. descrip : $40.;
run;

/* proc print data=labelin ; run;  */

proc sql noprint;
	  select  descrip into :condslablist separated by ' ' from labelin where cat="cond";
select  var into :condsvarlist separated by ' ' from labelin where cat="cond";

	  select  descrip into :medslablist separated by ' ' from labelin where cat="med";
select  var into :medsvarlist separated by ' ' from labelin where cat="med";
quit;
%put &condslablist &condsvarlist &medslablist &medsvarlist;
%put  &medslablist &medsvarlist;
/* executing macro */
/* Creating variables for prevalent conditions and medications,-1 for 1 year lookback  */

DATA a.a&n._&outdat.;
/*data tmp;*/
SET s0df_aa;
analysis="SENSITIVITYA_ &n.";
  * 	tmp_lookback1yr= (intnx('year', entry, -1, 'same'));
  tmp_yrslookback1= (intnx('year', entry, -1, 'same'));
  label tmp_yrslookback1= "1 year prior to study entry date";
  tmp_yrslookback50= (intnx('year', entry, -50, 'same'));  
  label tmp_yrslookback50= "50 years prior to study entry date";
%createvar(type='condition',var_list=&condsvarlist ,writ_list= &condslablist, yrspreindex=1 );
%createvar(type='med',var_list=&medsvarlist ,writ_list= &medslablist, yrspreindex=1 );
%createvar(type='condition',var_list=&condsvarlist ,writ_list= &condslablist, yrspreindex=50 );
%createvar(type='med',var_list=&medsvarlist ,writ_list= &medslablist, yrspreindex=50 );

/* creating additional variables for Table 1/rest of analysis */
/* creating year of cohort entry */
entry_year=year(entry);
/* BMI */
bmi_cat=.;
if bmitime<365 then do;
    if bmi<25 then bmi_cat=1;
    else if bmi ge 25 and bmi lt 30 then bmi_cat=2;
    else if bmi ge 30 then bmi_cat=3;
    end;
/* ETOH */
alcohol_cat='u';
if alcstattime<365 then do;
    alcohol_cat=alc;
end;

/* smoking */
smoke_cat='u';
if smoketime<365 then do;
    smoke_cat=smoke;
end;

/* HBa1c is in mmol per mol, */
hba1c_cat=.;
if hba1ctime<365.25 then do;
    if hba1c le 53 then hba1c_cat=1; /* 7% ~ 53 mmol per mol  */
    else if hba1c gt 53 and hba1c le 64 then hba1c_cat=2 ; /* 8% ~ 64 mmol per mol */
    else if hba1c gt 64 then hba1c_cat=3; /* gt 8% or 64 mmol per mol  */
    end;

/* total number of unique non-diabetic drugs in the year before cohort entry  */

/* duration of treated diabetes  */

/* formats and labels  */    
	format sex $sexf. alcohol_cat $statusf. smoke $statusf. hba1c_cat  hba1cf. bmi_cat bmif.;
    
label n_timepoints = "Total number of timepoints (timep)";
label tx_at_firsttimep	= "Treatment at first timepoint"; format tx_at_firsttimep tx_at_timepf.; 
label tx_at_lasttimep	= "Treatment at last timepoint"; format tx_at_lasttimep tx_at_timepf.; 
label last_start = "Last start time since cohort entry until very last tx status change";
label last_startstop = "Time from start time to stop time for very last tx timepoint";
label last_stop = "Last stop time since cohort entry date";
label tx_status_last= "Last treatment status: 1=unchanged treatment, 2=drug class discontinuation, 3=switching,4=adding";
format tx_status_last tx_statusf.;
label tx_status_first="First treatment status: 1=unchanged treatment, 2=drug class discontinuation, 3=switching,4=adding";
format tx_status_first tx_statusf.;
label exit_reason="Reason for exit {outcome of interest=1, end of follow-up=2, Y days after treatment discontinuation=3, Y days after switching or adding of drug class =4, death =5, database exit =6}";
format exit_reason reasonf. ;
label tx_status_rxchange ="Change in treatment status"; format tx_status_rxchange tx_statusf.;
label tx_at_rxchangetimep ="Status that the treatment was changed to"; format tx_at_rxchangetimep tx_at_timepf.;
label rxchange_day ="Time since cohort entry date until a change in treatment status";


%if &dropvars eq Y %then %do; 
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
acho_last acho_first acho_code sterinh_tot sterinh_last sterinh_first sterinh_code bago_tot bago_last bago_first bago_code abago_tot abago_last abago_first abago_code lra_tot lra_last lra_first lra_code xant_tot xant_last xant_first xant_code ahist_tot ahist_last ahist_first ahist_code ahistc_tot ahistc_last ahistc_first ahistc_code 
h2_tot h2_last h2_first h2_code ppi_tot ppi_last ppi_first ppi_code IBD_tot IBD_last IBD_first IBD_code thyro_tot thyro_last thyro_first thyro_code sterint_tot sterint_last sterint_first sterint_code stersys_tot stersys_last stersys_first stersys_code stertop_tot stertop_last stertop_first 
stertop_code gesta_tot gesta_last gesta_first gesta_code pill_tot pill_last pill_first pill_code adem_tot adem_last adem_first adem_code apsy_tot apsy_last apsy_first apsy_code benzo_tot benzo_last benzo_first benzo_code hypno_tot hypno_last hypno_first hypno_code ssri_tot ssri_last ssri_first ssri_code li_tot li_last li_first li_code mao_tot mao_last mao_first mao_code oadep_tot oadep_last oadep_first oadep_code mnri_tot mnri_last mnri_first mnri_code adep_tot adep_last adep_first adep_code 
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
 */ ASA_tot ASA_last ASA_first ASA_code
mesala_tot mesala_last mesala_first mesala_code sulfasala_tot sulfasala_last sulfasala_first sulfasala_code 
olsala_tot olsala_last olsala_first olsala_code balsala_tot balsala_last balsala_first balsala_code
HRTopp_tot HRTopp_last HRTopp_first HRTopp_code HRToverall_tot
HRToverall_last HRToverall_first HRToverall_code TNFai_tot TNFai_last TNFai_first TNFai_code budes_tot budes_last budes_first
budes_code Adcombo_tot Adcombo_last Adcombo_first Adcombo_code immureg_tot immureg_last immureg_first immureg_code cyclosp_tot
cyclosp_last cyclosp_first cyclosp_code ;
%end; %else %do; %end; 
RUN;

/* printing output */
ods excel file="&goutpath./&todaysdate._a&n._&outdat..xlsx"
  options (
    Sheet_interval="NONE"
    embedded_titles="NO"
    embedded_footnotes="NO"
);

ods excel options(
      sheet_name="a&n._&outdat."
      sheet_interval="NOW");

proc contents data= 	a.a&n._&outdat.
varnum; run;
 ods select default;

ods excel options(
      sheet_name="freqs"
      sheet_interval="NOW");
proc freq data= a.a&n._&outdat.  ;
tables   tx_at_firsttimep
 caco exp   exit_reason tx_status_first
  tx_status_last

     / list missing;
run;


ods excel options(
      sheet_name="Unweighted_T1"
      sheet_interval="NOW");

%let ds = a.a&n._&outdat. ;
%let colVar = cohort;
%let rowVars =history cohortdays
 exp caco tx_status_first  tx_at_firsttimep tx_status_last tx_at_lasttimep
exit_reason
age sex entry_year bmi_cat alcohol_cat smoke hba1c_cat

bl1yr_asthma
bl1yr_copd
bl1yr_arrhyth
bl1yr_chf
bl1yr_ihd
bl1yr_mi
bl1yr_nephr
bl1yr_nerop
bl1yr_dret
bl1yr_hyperten
bl1yr_stroke
bl1yr_hyperlip
bl1yr_diab
bl1yr_dvt
bl1yr_pe
bl1yr_gout
bl1yr_pthyro
bl1yr_mthyro
bl1yr_depres
bl1yr_affect
bl1yr_suic
bl1yr_sleep
bl1yr_schizo
bl1yr_epilep
bl1yr_renal
bl1yr_gIulcer
bl1yr_ra
bl1yr_alrhi
bl1yr_glauco
bl1yr_migra
bl1yr_sepsis
bl1yr_pneumo
bl1yr_psorI
bl1yr_psorP
bl1yr_vasc
bl1yr_sjogr
bl1yr_sle
bl1yr_pad
bl1yr_abdp
bl1yr_diarr
bl1yr_bstools
bl1yr_IBD
bl1yr_CD
bl1yr_UC
bl1yr_IC
bl1yr_refendo
bl1yr_refgastro
bl1yr_stomy
bl1yr_sigmoid
bl1yr_bx
bl1yr_ileostomy
bl1yr_divertic



bl1yr_insul
bl1yr_metformin
bl1yr_sulfon
bl1yr_bigua
bl1yr_ppar
bl1yr_prand
bl1yr_agluco
bl1yr_adiabc
bl1yr_oadiab
bl1yr_alloadiab
bl1yr_alladiab
bl1yr_dpp4i
bl1yr_sitagliptin
bl1yr_vildagliptin
bl1yr_saxagliptin
bl1yr_linagliptin
bl1yr_alogliptin
bl1yr_sulfonyl
bl1yr_sglt2i
bl1yr_TZD
bl1yr_GLP1
bl1yr_meglitinide
bl1yr_Adcombo

bl1yr_ace
bl1yr_arb
bl1yr_bb
bl1yr_ccb
bl1yr_nitrat
bl1yr_coronar
bl1yr_antiarr
bl1yr_thrombo
bl1yr_antivitk
bl1yr_hepar
bl1yr_stat
bl1yr_fib
bl1yr_lla
bl1yr_thiaz
bl1yr_loop
bl1yr_kspar
bl1yr_diurcom
bl1yr_thiaantih
bl1yr_diurall
bl1yr_ass
bl1yr_cox2
bl1yr_diclo
bl1yr_ibu
bl1yr_napro
bl1yr_otnsa
bl1yr_para
bl1yr_allnsa
bl1yr_opio
bl1yr_acho
bl1yr_sterinh
bl1yr_bago
bl1yr_abago
bl1yr_lra
bl1yr_xant
bl1yr_ahist
bl1yr_ahistc
bl1yr_h2
bl1yr_ppi
bl1yr_thyro
bl1yr_sterint
bl1yr_stersys
bl1yr_stertop
bl1yr_adem
bl1yr_apsy
bl1yr_benzo
bl1yr_hypno
bl1yr_ssri
bl1yr_li
bl1yr_mao
bl1yr_oadep
bl1yr_mnri
bl1yr_adep
bl1yr_pheny
bl1yr_barbi
bl1yr_succi
bl1yr_valpro
bl1yr_carba
bl1yr_oaconvu
bl1yr_aconvu
bl1yr_isupp

bl1yr_ASA
bl1yr_mesala
bl1yr_sulfasala
bl1yr_olsala
bl1yr_balsala
bl1yr_HRTopp
bl1yr_HRToverall
bl1yr_gesta
bl1yr_pill
bl1yr_TNFai
bl1yr_budes
bl1yr_immureg
bl1yr_cyclosp
bl1yr_nsaids

bl50yr_asthma
bl50yr_copd
bl50yr_arrhyth
bl50yr_chf
bl50yr_ihd
bl50yr_mi
bl50yr_nephr
bl50yr_nerop
bl50yr_dret
bl50yr_hyperten
bl50yr_stroke
bl50yr_hyperlip
bl50yr_diab
bl50yr_dvt
bl50yr_pe
bl50yr_gout
bl50yr_pthyro
bl50yr_mthyro
bl50yr_depres
bl50yr_affect
bl50yr_suic
bl50yr_sleep
bl50yr_schizo
bl50yr_epilep
bl50yr_renal
bl50yr_gIulcer
bl50yr_ra
bl50yr_alrhi
bl50yr_glauco
bl50yr_migra
bl50yr_sepsis
bl50yr_pneumo
bl50yr_psorI
bl50yr_psorP
bl50yr_vasc
bl50yr_sjogr
bl50yr_sle
bl50yr_pad
bl50yr_abdp
bl50yr_diarr
bl50yr_bstools
bl50yr_IBD
bl50yr_CD
bl50yr_UC
bl50yr_IC
bl50yr_refendo
bl50yr_refgastro
bl50yr_stomy
bl50yr_sigmoid
bl50yr_bx
bl50yr_ileostomy
bl50yr_divertic



bl50yr_insul
bl50yr_metformin
bl50yr_sulfon
bl50yr_bigua
bl50yr_ppar
bl50yr_prand
bl50yr_agluco
bl50yr_adiabc
bl50yr_oadiab
bl50yr_alloadiab
bl50yr_alladiab
bl50yr_dpp4i
bl50yr_sitagliptin
bl50yr_vildagliptin
bl50yr_saxagliptin
bl50yr_linagliptin
bl50yr_alogliptin
bl50yr_sulfonyl
bl50yr_sglt2i
bl50yr_TZD
bl50yr_GLP1
bl50yr_meglitinide
bl50yr_Adcombo

bl50yr_ace
bl50yr_arb
bl50yr_bb
bl50yr_ccb
bl50yr_nitrat
bl50yr_coronar
bl50yr_antiarr
bl50yr_thrombo
bl50yr_antivitk
bl50yr_hepar
bl50yr_stat
bl50yr_fib
bl50yr_lla
bl50yr_thiaz
bl50yr_loop
bl50yr_kspar
bl50yr_diurcom
bl50yr_thiaantih
bl50yr_diurall
bl50yr_ass
bl50yr_cox2
bl50yr_diclo
bl50yr_ibu
bl50yr_napro
bl50yr_otnsa
bl50yr_para
bl50yr_allnsa
bl50yr_opio
bl50yr_acho
bl50yr_sterinh
bl50yr_bago
bl50yr_abago
bl50yr_lra
bl50yr_xant
bl50yr_ahist
bl50yr_ahistc
bl50yr_h2
bl50yr_ppi
bl50yr_thyro
bl50yr_sterint
bl50yr_stersys
bl50yr_stertop
bl50yr_adem
bl50yr_apsy
bl50yr_benzo
bl50yr_hypno
bl50yr_ssri
bl50yr_li
bl50yr_mao
bl50yr_oadep
bl50yr_mnri
bl50yr_adep
bl50yr_pheny
bl50yr_barbi
bl50yr_succi
bl50yr_valpro
bl50yr_carba
bl50yr_oaconvu
bl50yr_aconvu
bl50yr_isupp

bl50yr_ASA
bl50yr_mesala
bl50yr_sulfasala
bl50yr_olsala
bl50yr_balsala
bl50yr_HRTopp
bl50yr_HRToverall
bl50yr_gesta
bl50yr_pill
bl50yr_TNFai
bl50yr_budes
bl50yr_immureg
bl50yr_cyclosp
bl50yr_nsaids

GPyearDx
GPyearDxRx

;
%let outname = a&n._&outdat. ;
 OPTIONS ORIENTATION=LANDSCAPE;

%table1(inds= &ds, colVar= &colVar, rowVars= &rowVars, wgtVar=, maxLevels=16, outfile=&outname, title=&outname, cellsize=5);


ods excel close;


%end;

%mend cleandata;
