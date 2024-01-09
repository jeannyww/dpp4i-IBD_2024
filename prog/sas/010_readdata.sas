/***************************************
SAS file name: 0_readdata.sas

Purpose: for reading in V2 of dataset 
Author: JHW
Creation Date: Created on 2023-12-16 05:36:00
Task231122 - IBDandDPP4I (db23-1)

Output, programs (general &goutpath., tables &toutpath., and figures &foutpath.):
        D:\Externe Projekte\UNC\wangje\out
        D:\Externe Projekte\UNC\wangje\prog\sas

Input paths:
            original raw data:  D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16
            libname a  D:\Externe Projekte\UNC\wangje\data\analysis
            libname raw  D:\Externe Projekte\UNC\wangje\data\raw
            libname temp  D:\Externe Projekte\UNC\wangje\data\temp

Current request:
D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Requests\2023-12-12 UNC Clean Request, New List\ Request for IBD and DPP4I-2023-12-14_V11 jw.docx

Used  code lists:
D:\External Projects\UNC\Task231122 - IBDandDPP4I (db23-1)\Codes\Lists_IBDandDPP4I_008.listler

General results:  
*   Event*, *Treatment*  CSV files
D:\External Projects\UNC \Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16\
*   Task231122_01_231122_001.log - Contains information on all code lists.
*   Task231122_01_231122_Report.txt  - Numbers collected during the creation of the study populations.


    Other details: CPRD-DPP4i project in collaboration with USB

CHANGES: see github repo 
Date: 2023-12-16 05:36:00
Notes: Cleaned up for macroprocessing 
***************************************/

options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;

option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=0_readdata.sas, savelog=N, dataset= );

/*===================================*\
//SECTION - EVENT CSV FILES 
\*===================================*/
/* region */

%macro read_eventcsv ( druglist , outlib );

    %do i=1 %to %sysfunc(countw(&druglist.));
        %let drug=%scan(&druglist.,&i.);

    data  tmp; 
        infile "D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16\Task231122_01_231122_&drug._Event\Task231122_01_231122_&drug._Event.csv" 
        dsd dlm="," firstobs=2 n=200 missover;
        length ID $ 12 eventtype 8 tmp_EventDate $ 10 tmp_EventDate_tx $ 10 badrx_BCode $ 10 badrx_GCode $ 10 EndOfLine $ 10;
        input ID $ eventtype ReadCode $ tmp_EventDate $ tmp_EventDate_tx $ badrx_BCode $ badrx_GCode $ EndOfLine $;
    data &outlib..&drug._event; set tmp;
    retain id eventtype eventdate eventdate_tx;
        if strip(tmp_eventdate) eq "" | strip(tmp_eventdate) eq "??/??/????" then tmp_eventdate="."; 
        if strip(tmp_eventdate_tx) eq "" | strip(tmp_eventdate_tx) eq "??/??/????" then tmp_eventdate_tx=".";
        eventdate=input(tmp_eventdate,mmddyy10.);
        eventdate_tx= input(tmp_eventdate_tx,mmddyy10.);
        drop tmp_eventdate tmp_eventdate_tx; 
        format eventdate eventdate_tx date9.;
    run;
    proc datasets nolist; delete tmp; run; quit;
    %end; 
    proc contents; run;
%mend read_eventcsv;

/* Run macro to read in the 4 event/outcome files into the raw libname  */
%LET druglist = dpp4i  tzd su sglt2i ;
ods excel file="&goutpath./tmp.xlsx"
options (
    Sheet_interval="NONE"
    embedded_titles="NO"
    embedded_footnotes="NO"
);
%read_eventcsv ( &druglist., raw );

ods excel close;

/* endregion //!SECTION */


/*===================================*\
//SECTION - TREATMENT CSV files 
\*===================================*/
/* region */


%macro read_trtmtcsv ( druglist, outlib);
    %do i=1 %to %sysfunc(countw(&druglist.));
        %let drug=%scan(&druglist.,&i.);
    data tmp; 
        infile "D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16\Task231122_01_231122_&drug._Treatment\Task231122_01_231122_&drug._Treatment.csv" 
        dsd dlm="," firstobs=2 n=200 missover ; 
        length ID $ 12 rxdate_tmp $ 10 gemscript $ 10 BCSDP $ 10 rx_dayssupply 8 DPP4i 8 SU 8 SGLT2i 8 TZD 8 time0_tmp $ 10 age 8 sex $ 10 smoke $ 10 smoketime 8 height 8 heighttime 8 weight 8 weighttime 8 bmi 8 bmitime 8 alc $ 10 alctime 8 alcunit 8 alcavg 8 hba1c 8 hba1ctime 8 hba1cno 8 hba1cavg 8 history 8 GPyearDx 8 GPyearDxRx 8 Alc_P_bc $ 10 Alc_P_bl 8 colo_bc $ 10 colo_bl 8 IBD_P_bc $ 10 IBD_P_bl 8 DivCol_I_bc $ 10 DivCol_I_bl 8 DivCol_P_bc $ 10 DivCol_P_bl 8 PCOS_bc $ 10 PCOS_bl 8 DiabGest_bc $ 10 DiabGest_bl 8 IBD_I_bc $ 10 IBD_I_bl 8 asthma_bc $ 10 asthma_bl 8 copd_bc $ 10 copd_bl 8 arrhyth_bc $ 10 arrhyth_bl 8 chf_bc $ 10 chf_bl 8 ihd_bc $ 10 ihd_bl 8 mi_bc $ 10 mi_bl 8 hyperten_bc $ 10 hyperten_bl 8 stroke_bc $ 10 stroke_bl 8 hyperlip_bc $ 10 hyperlip_bl 8 diab_bc $ 10 diab_bl 8 dvt_bc $ 10 dvt_bl 8 pe_bc $ 10 pe_bl 8 gout_bc $ 10 gout_bl 8 pthyro_bc $ 10 pthyro_bl 8 mthyro_bc $ 10 mthyro_bl 8 depres_bc $ 10 depres_bl 8 affect_bc $ 10 affect_bl 8 suic_bc $ 10 suic_bl 8 sleep_bc $ 10 sleep_bl 8 schizo_bc $ 10 schizo_bl 8 epilep_bc $ 10 epilep_bl 8 renal_bc $ 10 renal_bl 8 GIulcer_bc $ 10 GIulcer_bl 8 RhArth_bc $ 10 RhArth_bl 8 alrhi_bc $ 10 alrhi_bl 8 glauco_bc $ 10 glauco_bl 8 migra_bc $ 10 migra_bl 8 sepsis_bc $ 10 sepsis_bl 8 pneumo_bc $ 10 pneumo_bl 8 nephr_bc $ 10 nephr_bl 8 nerop_bc $ 10 nerop_bl 8 dret_bc $ 10 dret_bl 8 psorI_bc $ 10 psorI_bl 8 psorP_bc $ 10 psorP_bl 8 vasc_bc $ 10 vasc_bl 8 SjSy_bc $ 10 SjSy_bl 8 sLup_bc $ 10 sLup_bl 8 PerArtD_bc $ 10 PerArtD_bl 8 AbdPain_bc $ 10 AbdPain_bl 8 Diarr_bc $ 10 Diarr_bl 8 BkStool_bc $ 10 BkStool_bl 8 Crohns_bc $ 10 Crohns_bl 8 Ucolitis_bc $ 10 Ucolitis_bl 8 Icomitis_bc $ 10 Icomitis_bl 8 Gastent_bc $ 10 Gastent_bl 8 ColIle_bc $ 10 ColIle_bl 8 Sigmo_bc $ 10 Sigmo_bl 8 Biops_bc $ 10 Biops_bl 8 Ileo_bc $ 10 Ileo_bl 8 HBA1c_bc $ 10 HBA1c_bl 8 DPP4i_bc $ 10 DPP4i_gc $ 10 DPP4i_bl 8 DPP4i_tot1yr 8 SU_bc $ 10 SU_gc $ 10 SU_bl 8 SU_tot1yr 8 SGLT2i_bc $ 10 SGLT2i_gc $ 10 SGLT2i_bl 8 SGLT2i_tot1yr 8 TZD_bc $ 10 TZD_gc $ 10 TZD_bl 8 TZD_tot1yr 8 Insulin_bc $ 10 Insulin_gc $ 10 Insulin_bl 8 Insulin_tot1yr 8 bigua_bc $ 10 bigua_gc $ 10 bigua_bl 8 bigua_tot1yr 8 prand_bc $ 10 prand_gc $ 10 prand_bl 8 prand_tot1yr 8 agluco_bc $ 10 agluco_gc $ 10 agluco_bl 8 agluco_tot1yr 8 OAntGLP_bc $ 10 OAntGLP_gc $ 10 OAntGLP_bl 8 OAntGLP_tot1yr 8 AminoS_bc $ 10 AminoS_gc $ 10 AminoS_bl 8 AminoS_tot1yr 8 Mesal_bc $ 10 Mesal_gc $ 10 Mesal_bl 8 Mesal_tot1yr 8 Sulfas_bc $ 10 Sulfas_gc $ 10 Sulfas_bl 8 Sulfas_tot1yr 8 Olsala_bc $ 10 Olsala_gc $ 10 Olsala_bl 8 Olsala_tot1yr 8 Balsal_bc $ 10 Balsal_gc $ 10 Balsal_bl 8 Balsal_tot1yr 8 ace_bc $ 10 ace_gc $ 10 
        ace_bl 8 ace_tot1yr 8 arb_bc $ 10 arb_gc $ 10 arb_bl 8 arb_tot1yr 8 bb_bc $ 10 bb_gc $ 10 bb_bl 8 bb_tot1yr 8 ccb_bc $ 10 ccb_gc $ 10 ccb_bl 8 ccb_tot1yr 8 nitrat_bc $ 10 nitrat_gc $ 10 nitrat_bl 8 nitrat_tot1yr 8 coronar_bc $ 10 coronar_gc $ 10 coronar_bl 8 coronar_tot1yr 8 antiarr_bc $ 10 antiarr_gc $ 10 antiarr_bl 8 antiarr_tot1yr 8 thrombo_bc $ 10 thrombo_gc $ 10 thrombo_bl 8 thrombo_tot1yr 8 antivitk_bc $ 10 antivitk_gc $ 10 antivitk_bl 8 antivitk_tot1yr 8 hepar_bc $ 10 hepar_gc $ 10 hepar_bl 8 hepar_tot1yr 8 stat_bc $ 10 stat_gc $ 10 stat_bl 8 stat_tot1yr 8 fib_bc $ 10 fib_gc $ 10 fib_bl 8 fib_tot1yr 8 lla_bc $ 10 lla_gc $ 10 lla_bl 8 lla_tot1yr 8 thiaz_bc $ 10 thiaz_gc $ 10 thiaz_bl 8 thiaz_tot1yr 8 loop_bc $ 10 loop_gc $ 10 loop_bl 8 loop_tot1yr 8 kspar_bc $ 10 kspar_gc $ 10 kspar_bl 8 kspar_tot1yr 8 diurcom_bc $ 10 diurcom_gc $ 10 diurcom_bl 8 diurcom_tot1yr 8 thiaantih_bc $ 10 thiaantih_gc $ 10 thiaantih_bl 8 thiaantih_tot1yr 8 diurall_bc $ 10 diurall_gc $ 10 diurall_bl 8 diurall_tot1yr 8 ass_bc $ 10 ass_gc $ 10 ass_bl 8 ass_tot1yr 8 asscvd_bc $ 10 asscvd_gc $ 10 asscvd_bl 8 asscvd_tot1yr 8 allnsa_bc $ 10 allnsa_gc $ 10 allnsa_bl 8 
        allnsa_tot1yr 8 para_bc $ 10 para_gc $ 10 para_bl 8 para_tot1yr 8 bago_bc $ 10 bago_gc $ 10 bago_bl 8 bago_tot1yr 8 abago_bc $ 10 abago_gc $ 10 abago_bl 8 abago_tot1yr 8 opio_bc $ 10 opio_gc $ 10 opio_bl 8 opio_tot1yr 8 acho_bc $ 10 acho_gc $ 10 acho_bl 8 acho_tot1yr 8 sterinh_bc $ 10 sterinh_gc $ 10 sterinh_bl 8 sterinh_tot1yr 8 lra_bc $ 10 lra_gc $ 10 lra_bl 8 lra_tot1yr 8 xant_bc $ 10 xant_gc $ 10 xant_bl 8 xant_tot1yr 8 ahist_bc $ 10 ahist_gc $ 10 ahist_bl 8 ahist_tot1yr 8 ahistc_bc $ 10 ahistc_gc $ 10 ahistc_bl 8 ahistc_tot1yr 8 h2_bc $ 10 h2_gc $ 10 h2_bl 8 h2_tot1yr 
        8 ppi_bc $ 10 ppi_gc $ 10 ppi_bl 8 ppi_tot1yr 8 IBD_bc $ 10 IBD_gc $ 10 IBD_bl 8 IBD_tot1yr 8 thyro_bc $ 10 thyro_gc $ 10 thyro_bl 8 thyro_tot1yr 8 sterint_bc $ 10 sterint_gc $ 10 sterint_bl 8 sterint_tot1yr 8 stersys_bc $ 10 stersys_gc $ 10 stersys_bl 8 stersys_tot1yr 8 stertop_bc $ 10 stertop_gc $ 10 stertop_bl 8 stertop_tot1yr 8 gesta_bc $ 10 gesta_gc $ 10 gesta_bl 8 gesta_tot1yr 8 pill_bc $ 10 pill_gc $ 10 pill_bl 8 pill_tot1yr 8 HRTopp_bc $ 10 HRTopp_gc $ 10 HRTopp_bl 8 HRTopp_tot1yr 8 estr_bc $ 10 estr_gc $ 10 estr_bl 8 estr_tot1yr 8 adem_bc $ 10 adem_gc $ 10 adem_bl 
        8 adem_tot1yr 8 apsy_bc $ 10 apsy_gc $ 10 apsy_bl 8 apsy_tot1yr 8 benzo_bc $ 10 benzo_gc $ 10 benzo_bl 8 benzo_tot1yr 8 hypno_bc $ 10 hypno_gc $ 
        10 hypno_bl 8 hypno_tot1yr 8 ssri_bc $ 10 ssri_gc $ 10 ssri_bl 8 ssri_tot1yr 8 li_bc $ 10 li_gc $ 10 li_bl 8 li_tot1yr 8 mao_bc $ 10 mao_gc $ 10 
        mao_bl 8 mao_tot1yr 8 oadep_bc $ 10 oadep_gc $ 10 oadep_bl 8 oadep_tot1yr 8 mnri_bc $ 10 mnri_gc $ 10 mnri_bl 8 mnri_tot1yr 8 adep_bc $ 10 adep_gc $ 10 adep_bl 8 adep_tot1yr 8 pheny_bc $ 10 pheny_gc $ 10 pheny_bl 8 pheny_tot1yr 8 barbi_bc $ 10 barbi_gc $ 10 barbi_bl 8 barbi_tot1yr 8 succi_bc $ 10 succi_gc $ 10 succi_bl 8 succi_tot1yr 8 valpro_bc $ 10 valpro_gc $ 10 valpro_bl 8 valpro_tot1yr 8 carba_bc $ 10 carba_gc $ 10 carba_bl 8 
        carba_tot1yr 8 oaconvu_bc $ 10 oaconvu_gc $ 10 oaconvu_bl 8 oaconvu_tot1yr 8 aconvu_bc $ 10 aconvu_gc $ 10 aconvu_bl 8 aconvu_tot1yr 8 isupp_bc $ 10 isupp_gc $ 10 isupp_bl 8 isupp_tot1yr 8 TnfAI_bc $ 10 TnfAI_gc $ 10 TnfAI_bl 8 TnfAI_tot1yr 8 Budeo_bc $ 10 Budeo_gc $ 10 Budeo_bl 8 Budeo_tot1yr 8 OtherImm_bc $ 10 OtherImm_gc $ 10 OtherImm_bl 8 OtherImm_tot1yr 8 CycloSpor_bc $ 10 CycloSpor_gc $ 10 CycloSpor_bl 8 CycloSpor_tot1yr 8 Iso_oral_bc $ 10 Iso_oral_gc $ 10 Iso_oral_bl 8 Iso_oral_tot1yr 8 Iso_top_bc $ 10 Iso_top_gc $ 10 Iso_top_bl 8 Iso_top_tot1yr 8 Myco_bc $ 10 Myco_gc $ 10 Myco_bl 8 Myco_tot1yr 8 Etan_bc $ 10 Etan_gc $ 10 Etan_bl 8 Etan_tot1yr 8 Ipili_bc $ 10 Ipili_gc $ 10 Ipili_bl 8 Ipili_tot1yr 8 Ritux_bc $ 10 Ritux_gc $ 10 Ritux_bl 8 Ritux_tot1yr 8 EndOfLine $ 10
        ;
        input ID $ rxdate_tmp $ gemscript $ BCSDP $ rx_dayssupply  DPP4i  SU  SGLT2i  TZD  time0_tmp $ age  sex $ smoke $ smoketime  height  heighttime  weight  weighttime  bmi  bmitime  alc $ alctime  alcunit  alcavg  hba1c  hba1ctime  hba1cno  hba1cavg  history  GPyearDx  GPyearDxRx  Alc_P_bc $ Alc_P_bl  colo_bc $ colo_bl  IBD_P_bc $ IBD_P_bl  DivCol_I_bc $ DivCol_I_bl  DivCol_P_bc $ DivCol_P_bl  PCOS_bc $ PCOS_bl  DiabGest_bc $ DiabGest_bl  IBD_I_bc 
        $ IBD_I_bl  asthma_bc $ asthma_bl  copd_bc $ copd_bl  arrhyth_bc $ arrhyth_bl  chf_bc $ chf_bl  ihd_bc $ ihd_bl  mi_bc $ mi_bl  hyperten_bc $ hyperten_bl  stroke_bc $ stroke_bl  hyperlip_bc $ hyperlip_bl  diab_bc $ diab_bl  dvt_bc $ dvt_bl  pe_bc $ pe_bl  gout_bc $ gout_bl  pthyro_bc $ pthyro_bl  mthyro_bc $ mthyro_bl  depres_bc $ depres_bl  affect_bc $ affect_bl  suic_bc $ suic_bl  sleep_bc $ sleep_bl  schizo_bc $ schizo_bl  epilep_bc $ epilep_bl  renal_bc $ renal_bl  GIulcer_bc $ GIulcer_bl  RhArth_bc $ RhArth_bl  alrhi_bc $ alrhi_bl  glauco_bc $ glauco_bl  migra_bc $ migra_bl  sepsis_bc $ sepsis_bl  pneumo_bc $ pneumo_bl  nephr_bc $ nephr_bl  nerop_bc $ nerop_bl  dret_bc $ dret_bl  psorI_bc $ psorI_bl  psorP_bc $ psorP_bl  vasc_bc $ vasc_bl  SjSy_bc $ SjSy_bl  sLup_bc $ sLup_bl  PerArtD_bc $ PerArtD_bl  AbdPain_bc $ AbdPain_bl  Diarr_bc $ Diarr_bl  BkStool_bc $ BkStool_bl  Crohns_bc $ Crohns_bl  Ucolitis_bc $ Ucolitis_bl  Icomitis_bc $ Icomitis_bl  Gastent_bc $ Gastent_bl  ColIle_bc $ ColIle_bl  Sigmo_bc $ Sigmo_bl  Biops_bc $ Biops_bl  Ileo_bc $ Ileo_bl  HBA1c_bc $ HBA1c_bl  DPP4i_bc $ DPP4i_gc $ DPP4i_bl  DPP4i_tot1yr  SU_bc $ SU_gc $ SU_bl  SU_tot1yr  SGLT2i_bc $ SGLT2i_gc $ SGLT2i_bl  SGLT2i_tot1yr  TZD_bc $ TZD_gc $ TZD_bl  TZD_tot1yr  Insulin_bc $ Insulin_gc $ Insulin_bl  Insulin_tot1yr  bigua_bc $ bigua_gc $ bigua_bl  bigua_tot1yr  prand_bc $ prand_gc $ prand_bl  prand_tot1yr  agluco_bc $ agluco_gc $ agluco_bl  agluco_tot1yr  OAntGLP_bc $ OAntGLP_gc $ OAntGLP_bl  OAntGLP_tot1yr  AminoS_bc $ AminoS_gc $ AminoS_bl  AminoS_tot1yr  Mesal_bc $ Mesal_gc $ Mesal_bl 
        Mesal_tot1yr  Sulfas_bc $ Sulfas_gc $ Sulfas_bl  Sulfas_tot1yr  Olsala_bc $ Olsala_gc $ Olsala_bl  Olsala_tot1yr  Balsal_bc $ Balsal_gc $ Balsal_bl  Balsal_tot1yr  ace_bc $ ace_gc $ ace_bl  ace_tot1yr  arb_bc $ arb_gc $ arb_bl  arb_tot1yr  bb_bc $ bb_gc $ bb_bl  bb_tot1yr  ccb_bc $ ccb_gc $ ccb_bl  ccb_tot1yr  nitrat_bc $ nitrat_gc $ nitrat_bl  nitrat_tot1yr  coronar_bc $ coronar_gc $ coronar_bl  coronar_tot1yr  antiarr_bc $ antiarr_gc $ antiarr_bl  antiarr_tot1yr  thrombo_bc $ thrombo_gc $ thrombo_bl  thrombo_tot1yr  antivitk_bc $ antivitk_gc $ antivitk_bl  antivitk_tot1yr  hepar_bc $ hepar_gc $ hepar_bl  hepar_tot1yr  stat_bc $ stat_gc $ stat_bl  stat_tot1yr  fib_bc $ fib_gc $ fib_bl  fib_tot1yr  lla_bc $ lla_gc 
        $ lla_bl  lla_tot1yr  thiaz_bc $ thiaz_gc $ thiaz_bl  thiaz_tot1yr  loop_bc $ loop_gc $ loop_bl  loop_tot1yr  kspar_bc $ kspar_gc $ kspar_bl  kspar_tot1yr  diurcom_bc $ diurcom_gc $ diurcom_bl  diurcom_tot1yr  thiaantih_bc $ thiaantih_gc $ thiaantih_bl  thiaantih_tot1yr  diurall_bc $ diurall_gc $ diurall_bl  diurall_tot1yr  ass_bc $ ass_gc $ ass_bl  ass_tot1yr  asscvd_bc $ asscvd_gc $ asscvd_bl  asscvd_tot1yr  allnsa_bc $ allnsa_gc $ allnsa_bl  allnsa_tot1yr  para_bc $ para_gc $ para_bl  para_tot1yr  bago_bc $ bago_gc $ bago_bl  bago_tot1yr  abago_bc $ abago_gc $ abago_bl  
        abago_tot1yr  opio_bc $ opio_gc $ opio_bl  opio_tot1yr  acho_bc $ acho_gc $ acho_bl  acho_tot1yr  sterinh_bc $ sterinh_gc $ sterinh_bl  sterinh_tot1yr  lra_bc $ lra_gc $ lra_bl  lra_tot1yr  xant_bc $ xant_gc $ xant_bl  xant_tot1yr  ahist_bc $ ahist_gc $ ahist_bl  ahist_tot1yr  ahistc_bc $ 
        ahistc_gc $ ahistc_bl  ahistc_tot1yr  h2_bc $ h2_gc $ h2_bl  h2_tot1yr  ppi_bc $ ppi_gc $ ppi_bl  ppi_tot1yr  IBD_bc $ IBD_gc $ IBD_bl  IBD_tot1yr  thyro_bc $ thyro_gc $ thyro_bl  thyro_tot1yr  sterint_bc $ sterint_gc $ sterint_bl  sterint_tot1yr  stersys_bc $ stersys_gc $ stersys_bl  stersys_tot1yr  stertop_bc $ stertop_gc $ stertop_bl  stertop_tot1yr  gesta_bc $ gesta_gc $ gesta_bl  gesta_tot1yr  pill_bc $ pill_gc $ pill_bl  pill_tot1yr  HRTopp_bc $ HRTopp_gc $ HRTopp_bl  HRTopp_tot1yr  estr_bc $ estr_gc $ estr_bl  estr_tot1yr  adem_bc $ adem_gc $ adem_bl  adem_tot1yr  apsy_bc $ apsy_gc $ apsy_bl  apsy_tot1yr  benzo_bc $ benzo_gc $ benzo_bl  benzo_tot1yr  hypno_bc $ hypno_gc $ hypno_bl  hypno_tot1yr  ssri_bc $ ssri_gc $ ssri_bl  ssri_tot1yr  li_bc $ li_gc $ li_bl  li_tot1yr  mao_bc $ mao_gc $ mao_bl  mao_tot1yr  oadep_bc $ oadep_gc $ oadep_bl  oadep_tot1yr  mnri_bc $ mnri_gc $ mnri_bl  mnri_tot1yr  adep_bc $ adep_gc $ adep_bl  adep_tot1yr  pheny_bc $ pheny_gc $ pheny_bl  pheny_tot1yr  barbi_bc $ barbi_gc $ barbi_bl  barbi_tot1yr  succi_bc $ succi_gc $ succi_bl  succi_tot1yr  valpro_bc $ valpro_gc $ valpro_bl  valpro_tot1yr  carba_bc $ carba_gc $ carba_bl  carba_tot1yr  oaconvu_bc $ oaconvu_gc $ oaconvu_bl  oaconvu_tot1yr  aconvu_bc $ aconvu_gc $ aconvu_bl  aconvu_tot1yr  isupp_bc $ 
        isupp_gc $ isupp_bl  isupp_tot1yr  TnfAI_bc $ TnfAI_gc $ TnfAI_bl  TnfAI_tot1yr  Budeo_bc $ Budeo_gc $ Budeo_bl  Budeo_tot1yr  OtherImm_bc $ OtherImm_gc $ OtherImm_bl  OtherImm_tot1yr  CycloSpor_bc $ CycloSpor_gc $ CycloSpor_bl  CycloSpor_tot1yr  Iso_oral_bc $ Iso_oral_gc $ Iso_oral_bl  Iso_oral_tot1yr  Iso_top_bc $ Iso_top_gc $ Iso_top_bl  Iso_top_tot1yr  Myco_bc $ Myco_gc $ Myco_bl  Myco_tot1yr  Etan_bc $ Etan_gc $ Etan_bl  Etan_tot1yr  Ipili_bc $ Ipili_gc $ Ipili_bl  Ipili_tot1yr  Ritux_bc $ Ritux_gc $ Ritux_bl  Ritux_tot1yr  EndOfLine $ ;
    data &outlib..&drug._trtmt; 
        set tmp; retain id rxdate time0;
        if strip(rxdate_tmp) eq "" | strip(rxdate_tmp) eq "??/??/????" then rxdate_tmp=".";
        if strip(time0_tmp) eq "" | strip(time0_tmp) eq "??/??/????" then time0_tmp=".";
        rxdate=input(rxdate_tmp,mmddyy10.);
        time0=input(time0_tmp,mmddyy10.);
        format rxdate time0 date9.;
        RUN;
    %end;
%mend read_trtmtcsv ;


/* Run macro to read in the 4 treatment files into the raw libname  */
%LET druglist = dpp4i  tzd su sglt2i ;
%read_trtmtcsv ( &druglist. , raw);



/* endregion //!SECTION */

%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);
