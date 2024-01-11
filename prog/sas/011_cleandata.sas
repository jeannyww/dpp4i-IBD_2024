/***************************************
SAS file name: 011_cleandata.sas

Purpose: To clean the respective data into one obs per unique id for analysis and to create the final analysis dataset
Author: JHW
Creation Date:  Todays date: 2023-12-20 

    Program and output path:
            D:\Externe Projekte\UNC\wangje\sas
            D:\Externe Projekte\UNC\wangje\sas\prog
            libname temp D:\Externe Projekte\UNC\wangje\data\temp

    Input paths:
            original raw data:  D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16
            libname a  D:\Externe Projekte\UNC\wangje\data\analysis
Other details: CPRD-DPP4i project in collaboration with USB

CHANGES: see git 
Date: Date of Change
Notes: Change Notes
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; 
option MAUTOSOURCE;option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");

%setup(programName=011_cleandata.sas, savelog=N, dataset=dataname);

/*===================================*\
//SECTION - Cleaning the Events file 
\*===================================*/
/* region */

/*cleanevents*/
*descrip;
%macro cleanevents ( Druglist , save= N );

%do i=1 %to %sysfunc(countw(&druglist.));
%let drug=%scan(&druglist.,&i.);

data tmpevent_ ; set raw.&drug._event ; run;

/* deriving death date */
proc sql;
	create table correct_death as select distinct id, 
			max(eventtype=8) as event8, max(eventtype=9) as event9 ,
			max(case when eventtype=6 then eventdate else . end) as last_event6_dt format=date9.
	from tmpevent_
	group by id having event8=0 and event9=0;
    
quit;
PROC SQL; 
    create table _tmpevent_ as select a.*, 
        (case when a.eventtype=6 then  1 else 0 end) as flag_death
        from tmpevent_ as a 
        left join
        correct_death as b
        on a.id=b.id and a.eventdate=b.last_event6_dt
        order by id, eventdate;
QUIT;
proc sort data= tmpevent_; by id eventtype eventdate ; run;
data _tmpevent_wide&drug.;
        set tmpevent_ ;
        by id eventtype ; 
        length ibd1_code ibd2_code ibd3_code ibd4_code ibd5_code badrx_Bcode badRx_Gcode $ 10; 
        retain ibd1_dt ibd1_code ibd1
            ibd2_dt ibd2_code ibd2
            ibd3_dt ibd3_code ibd3
            ibd4_dt ibd4tx_dt ibd4_code ibd4
            ibd5_dt ibd5_code ibd5
            badrx_dt badrx_Bcode badrx_Gcode badrx
            death_dt dbexit_dt LastColl_Dt endstudy_dt;
        format ibd1_dt ibd2_dt ibd3_dt ibd4_dt ibd4tx_dt ibd5_dt badrx_dt death_dt dbexit_dt LastColl_Dt endstudy_dt date9.;
    
        if first.id then do;
            ibd1_dt = .; ibd1_code = ""; ibd1 = .;
            ibd2_dt = .; ibd2_code = ""; ibd2 = .;
            ibd3_dt = .; ibd3_code = ""; ibd3 = .;
            ibd4_dt = .; ibd4tx_dt = .; ibd4_code = ""; ibd4 = .;
            ibd5_dt = .; ibd5_code = ""; ibd5 = .;
            badrx_dt = .; badrx_Bcode = ""; badrx_Gcode = ""; badrx=.;
            death_dt = .; dbexit_dt = .; LastColl_Dt = .; endstudy_dt = '31DEC2022'd;
        end;
    
        if eventtype = 1 then do;
            ibd1_dt = eventdate;
            ibd1_code = readcode;
            ibd1 = 1;
        end; 
    
        if eventtype = 2 then do;
            ibd2_dt = eventdate;
            ibd2_code = readcode;
            ibd2 = 1;
        end; 
    
        if eventtype = 3 then do;
            ibd3_dt = eventdate;
            ibd3_code = readcode;
            ibd3 = 1;
        end; 
    
        if eventtype = 4 then do;
            ibd4_dt = eventdate;
            ibd4tx_dt = eventdate_tx;
            ibd4_code = readcode;
            ibd4 = 1;
        end; 
    
        if eventtype = 5 then do;
            ibd5_dt = eventdate;
            ibd5_code = readcode;
            ibd5 = 1;
        end; 
    
        if eventtype = 6 then do;
            if first.eventtype then do; 
            badrx_dt = eventdate;
            badrx_Bcode = badrx_Bcode;
            badrx_Gcode = badrx_Gcode;
            badrx=1; 
            END;
        end; 
        *if eventtype = 7 then death_dt = eventdate;
        *adding derived death below, but update to the above line when data are updated;
        if flag_death = 1 then death_dt = last_event6_dt;
        if eventtype = 8 then dbexit_dt = eventdate;
        if eventtype = 9 then LastColl_Dt = eventdate;
        if last.id then output;
        drop eventtype eventdate readcode eventdate_tx endofline ;
    run;
    
    PROC SQL; 
        create table tmp2event_wide&drug. as select distinct a.*, b.time0 from _tmpevent_wide&drug. as a 
        inner join raw.&drug._trtmt as b on a.id = b.id;
    quit;
    /* you can also add derived event_type7 here as well   */
/*     proc sql; 
        create table tmpevent_wide&drug. as select a.*, b.last_event6_dt as death_dt
        from tmp2event_wide&drug. as a 
        left join 
        (select b.id, b.correct_death from correct_death as b)
        on a.id=b.id 
        order by id;
    QUIT; */
    

%if &save. = Y %then %do;
    data temp.&drug._eventwide; set tmpevent_wide&drug.; run;
    %end;
%else %do; %end; %end;
%mend cleanevents;

%LET druglist = dpp4i su tzd sglt2i;
%cleanevents(  druglist=&druglist., save=Y );


/* endregion //!SECTION */


/*===================================*\
//SECTION - RX trtmt getting use periods 
\*===================================*/
/* region */
/* Reading rx   */
/*get_useperiods*/
 *descrip;



%macro get_useperiods ( druglist , grace, washout, maxDaysP, save= N );

%do z=1 %to %sysfunc(countw(&druglist.));
    %let drug=%scan(&druglist.,&z.);
    
    data tmptrtmt_; set raw.&drug._trtmt; run;

proc sql;
    create table tmpRx_&drug. as
    select * from 
        (select a.id, a.rxdate, a.time0, a.history, a.gemscript, a.BCSDP, a.rx_dayssupply, a.DPP4i, a.SU, a.SGLT2i, a.TZD 
        from tmptrtmt_ as a ) 
        left join 
        (select * from tmpevent_wide&drug. as b)
        on a.id=b.id;
quit;

data tmpRx_&drug._; set tmpRx_&drug.;
    startdt= time0-history ; format startdt date9.;
    enddt= min(death_dt, dbexit_dt, endstudy_dt); format enddt date9.; RUN;
%let keeplist= dpp4i su sglt2i tzd gemscript BCSDP;
%useperiods(
    grace=&primaryGraceP, 
    washout=&washoutp, 
    wpgp=N, 
    daysimp=0, 
    maxDays=&maxDaysP,   
    multiclaim=max,
    inds= %str(tmpRx_&drug._ (where=(&drug.=1))), 
    idvar=id, 
    startenroll=startdt, 
    rxdate=rxdate, 
    endenroll=enddt, 
    dayssup=rx_dayssupply, 
    keepvars= &keeplist, outds=&drug._useperiods);

    
%if &save. = Y %then %do;

    data temp.&drug._useperiods; set &drug._useperiods; run;
    %end;

%end;
%mend get_useperiods;

%LET druglist = dpp4i su tzd sglt2i ;
%LET primaryGracep = 90;
%LET washoutp = 360;
%LET maxdaysaccum = 14; * Maximum days supply of drug a patient should be allowed to accumulate;
%get_useperiods( druglist= &druglist. , grace= &primaryGracep, washout= &washoutp , maxDaysP=&maxdaysaccum ,save=Y);


/* pascals' existing system to determine days supply:  "information on dosing instructions and duration may be incomplete, I have created an algorithm to fill in missing information as sensibly as possible.	For example, I look at the information from the last prescription. Or I use default values that we have previously determined. Thereby I look at how a medication was most frequently prescribed in the database and then use these values if I have no other information." */
    
    /* endregion //!SECTION */

/*===================================*\
//SECTION - Demographics 
\*===================================*/
/* region */

/* subsetting  demographic dataset  */
%macro get_demog ( druglist );
%do i=1 %to %sysfunc(countw(&druglist.));
    %let drug=%scan(&druglist.,&i.);
    data tmpDemog_&drug._; set raw.&drug._trtmt;
    drop rxdate gemscript BCSDP rx_dayssupply DPP4i SU SGLT2i TZD;     
        run;
    proc sql;
    select count(unique id) as n from tmpDemog_&drug._; quit;

/* eliminate duplicates from the demog dataset */
proc sort data=tmpDemog_&drug._ out=temp.&drug._demog nodupkey;
    by id time0 age sex smoke smoketime height heighttime weight weighttime bmi bmitime alc alctime alcunit alcavg hba1c hba1ctime hba1cno hba1cavg history GPyearDx GPyearDxRx Alc_P_bc Alc_P_bl colo_bc colo_bl IBD_P_bc IBD_P_bl DivCol_I_bc DivCol_I_bl DivCol_P_bc DivCol_P_bl PCOS_bc PCOS_bl DiabGest_bc DiabGest_bl IBD_I_bc IBD_I_bl asthma_bc asthma_bl copd_bc copd_bl arrhyth_bc arrhyth_bl chf_bc chf_bl ihd_bc ihd_bl mi_bc mi_bl hyperten_bc hyperten_bl stroke_bc stroke_bl hyperlip_bc hyperlip_bl diab_bc diab_bl dvt_bc dvt_bl pe_bc pe_bl gout_bc 
    gout_bl pthyro_bc pthyro_bl mthyro_bc mthyro_bl depres_bc depres_bl affect_bc affect_bl suic_bc suic_bl sleep_bc sleep_bl schizo_bc schizo_bl epilep_bc epilep_bl renal_bc renal_bl GIulcer_bc GIulcer_bl RhArth_bc RhArth_bl alrhi_bc alrhi_bl glauco_bc glauco_bl migra_bc migra_bl sepsis_bc sepsis_bl pneumo_bc pneumo_bl nephr_bc nephr_bl nerop_bc nerop_bl dret_bc dret_bl psorI_bc psorI_bl psorP_bc psorP_bl vasc_bc vasc_bl SjSy_bc SjSy_bl sLup_bc sLup_bl PerArtD_bc PerArtD_bl AbdPain_bc AbdPain_bl Diarr_bc Diarr_bl BkStool_bc BkStool_bl Crohns_bc 
    Crohns_bl Ucolitis_bc Ucolitis_bl Icomitis_bc Icomitis_bl Gastent_bc Gastent_bl ColIle_bc ColIle_bl Sigmo_bc Sigmo_bl Biops_bc Biops_bl Ileo_bc Ileo_bl HBA1c_bc HBA1c_bl DPP4i_bc DPP4i_gc DPP4i_bl DPP4i_tot1yr SU_bc SU_gc SU_bl SU_tot1yr SGLT2i_bc SGLT2i_gc SGLT2i_bl SGLT2i_tot1yr TZD_bc TZD_gc TZD_bl TZD_tot1yr Insulin_bc Insulin_gc Insulin_bl Insulin_tot1yr bigua_bc bigua_gc bigua_bl bigua_tot1yr prand_bc prand_gc prand_bl prand_tot1yr agluco_bc agluco_gc agluco_bl agluco_tot1yr OAntGLP_bc OAntGLP_gc OAntGLP_bl OAntGLP_tot1yr AminoS_bc 
    AminoS_gc AminoS_bl AminoS_tot1yr Mesal_bc Mesal_gc Mesal_bl Mesal_tot1yr Sulfas_bc Sulfas_gc Sulfas_bl Sulfas_tot1yr Olsala_bc Olsala_gc Olsala_bl Olsala_tot1yr Balsal_bc Balsal_gc Balsal_bl Balsal_tot1yr ace_bc ace_gc ace_bl ace_tot1yr arb_bc arb_gc arb_bl arb_tot1yr bb_bc bb_gc bb_bl bb_tot1yr ccb_bc ccb_gc ccb_bl ccb_tot1yr nitrat_bc nitrat_gc nitrat_bl nitrat_tot1yr coronar_bc coronar_gc coronar_bl coronar_tot1yr antiarr_bc antiarr_gc antiarr_bl antiarr_tot1yr thrombo_bc thrombo_gc thrombo_bl thrombo_tot1yr antivitk_bc antivitk_gc 
    antivitk_bl antivitk_tot1yr hepar_bc hepar_gc hepar_bl hepar_tot1yr stat_bc stat_gc stat_bl stat_tot1yr fib_bc fib_gc fib_bl fib_tot1yr lla_bc lla_gc lla_bl lla_tot1yr thiaz_bc thiaz_gc thiaz_bl thiaz_tot1yr loop_bc loop_gc loop_bl loop_tot1yr kspar_bc kspar_gc kspar_bl kspar_tot1yr diurcom_bc diurcom_gc diurcom_bl diurcom_tot1yr thiaantih_bc thiaantih_gc thiaantih_bl thiaantih_tot1yr diurall_bc diurall_gc diurall_bl diurall_tot1yr ass_bc ass_gc ass_bl ass_tot1yr asscvd_bc asscvd_gc asscvd_bl asscvd_tot1yr allnsa_bc allnsa_gc allnsa_bl allnsa_tot1yr 
    para_bc para_gc para_bl para_tot1yr bago_bc bago_gc bago_bl bago_tot1yr abago_bc abago_gc abago_bl abago_tot1yr opio_bc opio_gc opio_bl opio_tot1yr acho_bc acho_gc acho_bl acho_tot1yr sterinh_bc sterinh_gc sterinh_bl sterinh_tot1yr lra_bc lra_gc lra_bl lra_tot1yr xant_bc xant_gc xant_bl xant_tot1yr ahist_bc ahist_gc ahist_bl ahist_tot1yr ahistc_bc ahistc_gc ahistc_bl ahistc_tot1yr h2_bc h2_gc h2_bl h2_tot1yr ppi_bc ppi_gc ppi_bl ppi_tot1yr IBD_bc IBD_gc IBD_bl IBD_tot1yr thyro_bc thyro_gc thyro_bl thyro_tot1yr sterint_bc sterint_gc sterint_bl 
    sterint_tot1yr stersys_bc stersys_gc stersys_bl stersys_tot1yr stertop_bc stertop_gc stertop_bl stertop_tot1yr gesta_bc gesta_gc gesta_bl gesta_tot1yr pill_bc pill_gc pill_bl pill_tot1yr HRTopp_bc HRTopp_gc HRTopp_bl HRTopp_tot1yr estr_bc estr_gc estr_bl estr_tot1yr adem_bc adem_gc adem_bl adem_tot1yr apsy_bc apsy_gc apsy_bl apsy_tot1yr benzo_bc benzo_gc benzo_bl benzo_tot1yr hypno_bc hypno_gc hypno_bl hypno_tot1yr ssri_bc ssri_gc ssri_bl ssri_tot1yr li_bc li_gc li_bl li_tot1yr mao_bc mao_gc mao_bl mao_tot1yr oadep_bc oadep_gc oadep_bl 
    oadep_tot1yr mnri_bc mnri_gc mnri_bl mnri_tot1yr adep_bc adep_gc adep_bl adep_tot1yr pheny_bc pheny_gc pheny_bl pheny_tot1yr barbi_bc barbi_gc barbi_bl barbi_tot1yr succi_bc succi_gc succi_bl succi_tot1yr valpro_bc valpro_gc valpro_bl valpro_tot1yr carba_bc carba_gc carba_bl carba_tot1yr oaconvu_bc oaconvu_gc oaconvu_bl oaconvu_tot1yr aconvu_bc aconvu_gc aconvu_bl 
    aconvu_tot1yr isupp_bc isupp_gc isupp_bl isupp_tot1yr TnfAI_bc TnfAI_gc TnfAI_bl TnfAI_tot1yr Budeo_bc Budeo_gc Budeo_bl Budeo_tot1yr OtherImm_bc OtherImm_gc OtherImm_bl OtherImm_tot1yr CycloSpor_bc CycloSpor_gc CycloSpor_bl CycloSpor_tot1yr Iso_oral_bc Iso_oral_gc Iso_oral_bl Iso_oral_tot1yr Iso_top_bc Iso_top_gc Iso_top_bl Iso_top_tot1yr Myco_bc Myco_gc Myco_bl Myco_tot1yr Etan_bc Etan_gc Etan_bl Etan_tot1yr Ipili_bc Ipili_gc Ipili_bl Ipili_tot1yr Ritux_bc Ritux_gc Ritux_bl Ritux_tot1yr EndOfLine  ;
run;
proc sql;
select count(unique id) as n from temp.&drug._demog; quit;
/* tmpDemog_&drug. is our demographic variables dataset that we will merge into the analysis dataset when we are done */
%end;
%mend;
%let druglist= dpp4i su  tzd sglt2i;
%get_demog( druglist= &druglist. );
/* endregion //!SECTION */


%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);
