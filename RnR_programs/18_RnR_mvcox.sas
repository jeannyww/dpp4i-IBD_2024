
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=test, savelog=N, dataset=dataname);

%*;*;*';*";%*%mend;*);




%macro mvcox_analysis (exposure, comparator, basemodelvars, addedmodelvars, ana_name, data_prefix, type, induction, latency, ibd_Def, intime, outtime);
/* For TVE */
data dsn; set a.Abrahami_Notrim&data_prefix._&exposure._&comparator.; drop Alc_P_bc Alc_P_bl colo_bc colo_bl IBD_P_bc IBD_P_bl DivCol_I_bc DivCol_I_bl DivCol_P_bc DivCol_P_bl PCOS_bc PCOS_bl DiabGest_bc DiabGest_bl IBD_I_bc IBD_I_bl asthma_bc asthma_bl copd_bc copd_bl arrhyth_bc arrhyth_bl chf_bc chf_bl ihd_bc ihd_bl mi_bc mi_bl hyperten_bc hyperten_bl stroke_bc stroke_bl hyperlip_bc hyperlip_bl diab_bc diab_bl dvt_bc dvt_bl pe_bc pe_bl gout_bc 
        gout_bl pthyro_bc pthyro_bl mthyro_bc mthyro_bl depres_bc depres_bl affect_bc affect_bl suic_bc suic_bl sleep_bc sleep_bl schizo_bc schizo_bl epilep_bc epilep_bl renal_bc renal_bl GIulcer_bc GIulcer_bl RhArth_bc RhArth_bl alrhi_bc alrhi_bl glauco_bc glauco_bl migra_bc migra_bl sepsis_bc sepsis_bl pneumo_bc pneumo_bl nephr_bc nephr_bl nerop_bc nerop_bl dret_bc dret_bl psorI_bc psorI_bl psorP_bc psorP_bl vasc_bc vasc_bl SjSy_bc SjSy_bl sLup_bc sLup_bl PerArtD_bc PerArtD_bl AbdPain_bc AbdPain_bl Diarr_bc Diarr_bl BkStool_bc BkStool_bl Crohns_bc 
        Crohns_bl Ucolitis_bc Ucolitis_bl Icomitis_bc Icomitis_bl Gastent_bc Gastent_bl ColIle_bc ColIle_bl Sigmo_bc Sigmo_bl Biops_bc Biops_bl Ileo_bc Ileo_bl HBA1c_bc HBA1c_bl DPP4i_bc DPP4i_gc DPP4i_bl DPP4i_tot1yr SU_bc SU_gc SU_bl SU_tot1yr SGLT2i_bc SGLT2i_gc SGLT2i_bl SGLT2i_tot1yr TZD_bc TZD_gc TZD_bl TZD_tot1yr Insulin_bc Insulin_gc Insulin_bl Insulin_tot1yr bigua_bc bigua_gc bigua_bl bigua_tot1yr prand_bc prand_gc prand_bl prand_tot1yr agluco_bc agluco_gc agluco_bl agluco_tot1yr OAntGLP_bc OAntGLP_gc OAntGLP_bl OAntGLP_tot1yr AminoS_bc 
        AminoS_gc AminoS_bl AminoS_tot1yr Mesal_bc Mesal_gc Mesal_bl Mesal_tot1yr Sulfas_bc Sulfas_gc Sulfas_bl Sulfas_tot1yr Olsala_bc Olsala_gc Olsala_bl Olsala_tot1yr Balsal_bc Balsal_gc Balsal_bl Balsal_tot1yr ace_bc ace_gc ace_bl ace_tot1yr arb_bc arb_gc arb_bl arb_tot1yr bb_bc bb_gc bb_bl bb_tot1yr ccb_bc ccb_gc ccb_bl ccb_tot1yr nitrat_bc nitrat_gc nitrat_bl nitrat_tot1yr coronar_bc coronar_gc coronar_bl coronar_tot1yr antiarr_bc antiarr_gc antiarr_bl antiarr_tot1yr thrombo_bc thrombo_gc thrombo_bl thrombo_tot1yr antivitk_bc antivitk_gc 
        antivitk_bl antivitk_tot1yr hepar_bc hepar_gc hepar_bl hepar_tot1yr stat_bc stat_gc stat_bl stat_tot1yr fib_bc fib_gc fib_bl fib_tot1yr lla_bc lla_gc lla_bl lla_tot1yr thiaz_bc thiaz_gc thiaz_bl thiaz_tot1yr loop_bc loop_gc loop_bl loop_tot1yr kspar_bc kspar_gc kspar_bl kspar_tot1yr diurcom_bc diurcom_gc diurcom_bl diurcom_tot1yr thiaantih_bc thiaantih_gc thiaantih_bl thiaantih_tot1yr diurall_bc diurall_gc diurall_bl diurall_tot1yr ass_bc ass_gc ass_bl ass_tot1yr asscvd_bc asscvd_gc asscvd_bl asscvd_tot1yr allnsa_bc allnsa_gc allnsa_bl allnsa_tot1yr 
        para_bc para_gc para_bl para_tot1yr bago_bc bago_gc bago_bl bago_tot1yr abago_bc abago_gc abago_bl abago_tot1yr opio_bc opio_gc opio_bl opio_tot1yr acho_bc acho_gc acho_bl acho_tot1yr sterinh_bc sterinh_gc sterinh_bl sterinh_tot1yr lra_bc lra_gc lra_bl lra_tot1yr xant_bc xant_gc xant_bl xant_tot1yr ahist_bc ahist_gc ahist_bl ahist_tot1yr ahistc_bc ahistc_gc ahistc_bl ahistc_tot1yr h2_bc h2_gc h2_bl h2_tot1yr ppi_bc ppi_gc ppi_bl ppi_tot1yr  IBD_tot1yr thyro_bc thyro_gc thyro_bl thyro_tot1yr sterint_bc sterint_gc sterint_bl 
        sterint_tot1yr stersys_bc stersys_gc stersys_bl stersys_tot1yr stertop_bc stertop_gc stertop_bl stertop_tot1yr gesta_bc gesta_gc gesta_bl gesta_tot1yr pill_bc pill_gc pill_bl pill_tot1yr HRTopp_bc HRTopp_gc HRTopp_bl HRTopp_tot1yr estr_bc estr_gc estr_bl estr_tot1yr adem_bc adem_gc adem_bl adem_tot1yr apsy_bc apsy_gc apsy_bl apsy_tot1yr benzo_bc benzo_gc benzo_bl benzo_tot1yr hypno_bc hypno_gc hypno_bl hypno_tot1yr ssri_bc ssri_gc ssri_bl ssri_tot1yr li_bc li_gc li_bl li_tot1yr mao_bc mao_gc mao_bl mao_tot1yr oadep_bc oadep_gc oadep_bl 
        oadep_tot1yr mnri_bc mnri_gc mnri_bl mnri_tot1yr adep_bc adep_gc adep_bl adep_tot1yr pheny_bc pheny_gc pheny_bl pheny_tot1yr barbi_bc barbi_gc barbi_bl barbi_tot1yr succi_bc succi_gc succi_bl succi_tot1yr valpro_bc valpro_gc valpro_bl valpro_tot1yr carba_bc carba_gc carba_bl carba_tot1yr oaconvu_bc oaconvu_gc oaconvu_bl oaconvu_tot1yr aconvu_bc aconvu_gc aconvu_bl 
        aconvu_tot1yr isupp_bc isupp_gc isupp_bl isupp_tot1yr TnfAI_bc TnfAI_gc TnfAI_bl TnfAI_tot1yr Budeo_bc Budeo_gc Budeo_bl Budeo_tot1yr OtherImm_bc OtherImm_gc OtherImm_bl OtherImm_tot1yr CycloSpor_bc CycloSpor_gc CycloSpor_bl CycloSpor_tot1yr Iso_oral_bc Iso_oral_gc Iso_oral_bl Iso_oral_tot1yr Iso_top_bc Iso_top_gc Iso_top_bl Iso_top_tot1yr Myco_bc Myco_gc Myco_bl Myco_tot1yr Etan_bc Etan_gc Etan_bl Etan_tot1yr Ipili_bc Ipili_gc Ipili_bl Ipili_tot1yr Ritux_bc Ritux_gc Ritux_bl Ritux_tot1yr EndOfLine  ;
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
            if &exposure =0 and switcher_flag=2 then do;
/*            if &exposure =0 and switchAugmentDate ne . then do;*/
                enddate= min(&ibd_def._dt, dpp4i_filldate2 +&induction, 
						&outtime /*7/29/2024 Tian & Jeany added this, fixing the error that comparator >3yr when using max 3-yr FUP*/
						, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt
						);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
                end;
           %end;
        *if the startdate is time0, ie the date of first prescription;
        %if %upcase(&intime) ne FILLDATE2 %then %do;
            if &exposure =0 and switcher_flag=2 then do;
/*            if &exposure =0 and switchAugmentDate ne . then do;*/
                enddate= min(&ibd_def._dt, switchAugmentDate+&induction,
							 &outtime /*7/29/2024 Tian & Jeany added this, fixing the error that comparator >3yr when using max 3-yr FUP*/
							 ,enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt
							 );
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne .    then event=1; else event=0;
                end;
        %end;

        /* IT analysis  */
        %if %upcase(&type) eq IT %then %do;

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
        %end;
        /* AT analysis */
        %if %upcase(&type) eq AT %then %do;
            /* for dpp4i initiators who were prevalent users of the comparator */
		else if &exposure =1 and switcher_flag=1/*excludeflag_prevalentuser eq 1*/ then do;
                enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt, endofdrug);
                if enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
                end;
            /* for initiators of dpp4i who never switched from the comparator */
		else if &exposure=1 and switcher_flag=0 /*excludeflag_prevalentuser ne 1*/ then do;
                enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt, endofdrug);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
            end;
            /* for initiators of comparator drug who never switched */
		else if &exposure=0 and switcher_flag=3 /*switchAugmentDate eq .*/ then do;
                enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt, endofdrug);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
            end;
        %end; 
        
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
    RUN;
	
/*Make cuts to dataset*/
data dsn; set dsn; 
if delete_flag1=1 then delete;
if ibd_ever =1 then delete;
format dpp4i; run;

ods output ParameterEstimates = mvcoxhr;
proc phreg data=dsn covsandwich(aggregate) ;
   class  entry_year (ref="2015") sex (ref=first) hba1c_Cat2 (ref=first) alcohol_cat (ref=first) smoke_cat (ref=first) bmi_cat2(ref=first) /param=ref  ;
   model time*event(0)= &exposure. &basemodelvars. &addedmodelvars. /ties=efron rl;
run;

Data mvcoxhr_tve(keep= analysis parameter classval0 &exposure chr clcl cucl mvcox_HR);
    set mvcoxhr;
	analysis="TVE &type MVCox";
    &exposure=1;
    chr=exp(Estimate);
    clcl=exp(Estimate-1.96*StdErr);
    cucl=exp(Estimate+1.96*StdErr);
    mvcox_HR=compress(put((hazardratio),6.1))||" ("||compress(put((HRlowerCL),6.1))||"-"||compress(put((HRupperCL),6.1))||")";
run;
proc print data=mvcoxhr   ;  
run; 
/* For ACNU */
 data dsn; set a.notrim&data_prefix._&exposure._&comparator._1yrlb; drop Alc_P_bc Alc_P_bl colo_bc colo_bl IBD_P_bc IBD_P_bl DivCol_I_bc DivCol_I_bl DivCol_P_bc DivCol_P_bl PCOS_bc PCOS_bl DiabGest_bc DiabGest_bl IBD_I_bc IBD_I_bl asthma_bc asthma_bl copd_bc copd_bl arrhyth_bc arrhyth_bl chf_bc chf_bl ihd_bc ihd_bl mi_bc mi_bl hyperten_bc hyperten_bl stroke_bc stroke_bl hyperlip_bc hyperlip_bl diab_bc diab_bl dvt_bc dvt_bl pe_bc pe_bl gout_bc 
        gout_bl pthyro_bc pthyro_bl mthyro_bc mthyro_bl depres_bc depres_bl affect_bc affect_bl suic_bc suic_bl sleep_bc sleep_bl schizo_bc schizo_bl epilep_bc epilep_bl renal_bc renal_bl GIulcer_bc GIulcer_bl RhArth_bc RhArth_bl alrhi_bc alrhi_bl glauco_bc glauco_bl migra_bc migra_bl sepsis_bc sepsis_bl pneumo_bc pneumo_bl nephr_bc nephr_bl nerop_bc nerop_bl dret_bc dret_bl psorI_bc psorI_bl psorP_bc psorP_bl vasc_bc vasc_bl SjSy_bc SjSy_bl sLup_bc sLup_bl PerArtD_bc PerArtD_bl AbdPain_bc AbdPain_bl Diarr_bc Diarr_bl BkStool_bc BkStool_bl Crohns_bc 
        Crohns_bl Ucolitis_bc Ucolitis_bl Icomitis_bc Icomitis_bl Gastent_bc Gastent_bl ColIle_bc ColIle_bl Sigmo_bc Sigmo_bl Biops_bc Biops_bl Ileo_bc Ileo_bl HBA1c_bc HBA1c_bl DPP4i_bc DPP4i_gc DPP4i_bl DPP4i_tot1yr SU_bc SU_gc SU_bl SU_tot1yr SGLT2i_bc SGLT2i_gc SGLT2i_bl SGLT2i_tot1yr TZD_bc TZD_gc TZD_bl TZD_tot1yr Insulin_bc Insulin_gc Insulin_bl Insulin_tot1yr bigua_bc bigua_gc bigua_bl bigua_tot1yr prand_bc prand_gc prand_bl prand_tot1yr agluco_bc agluco_gc agluco_bl agluco_tot1yr OAntGLP_bc OAntGLP_gc OAntGLP_bl OAntGLP_tot1yr AminoS_bc 
        AminoS_gc AminoS_bl AminoS_tot1yr Mesal_bc Mesal_gc Mesal_bl Mesal_tot1yr Sulfas_bc Sulfas_gc Sulfas_bl Sulfas_tot1yr Olsala_bc Olsala_gc Olsala_bl Olsala_tot1yr Balsal_bc Balsal_gc Balsal_bl Balsal_tot1yr ace_bc ace_gc ace_bl ace_tot1yr arb_bc arb_gc arb_bl arb_tot1yr bb_bc bb_gc bb_bl bb_tot1yr ccb_bc ccb_gc ccb_bl ccb_tot1yr nitrat_bc nitrat_gc nitrat_bl nitrat_tot1yr coronar_bc coronar_gc coronar_bl coronar_tot1yr antiarr_bc antiarr_gc antiarr_bl antiarr_tot1yr thrombo_bc thrombo_gc thrombo_bl thrombo_tot1yr antivitk_bc antivitk_gc 
        antivitk_bl antivitk_tot1yr hepar_bc hepar_gc hepar_bl hepar_tot1yr stat_bc stat_gc stat_bl stat_tot1yr fib_bc fib_gc fib_bl fib_tot1yr lla_bc lla_gc lla_bl lla_tot1yr thiaz_bc thiaz_gc thiaz_bl thiaz_tot1yr loop_bc loop_gc loop_bl loop_tot1yr kspar_bc kspar_gc kspar_bl kspar_tot1yr diurcom_bc diurcom_gc diurcom_bl diurcom_tot1yr thiaantih_bc thiaantih_gc thiaantih_bl thiaantih_tot1yr diurall_bc diurall_gc diurall_bl diurall_tot1yr ass_bc ass_gc ass_bl ass_tot1yr asscvd_bc asscvd_gc asscvd_bl asscvd_tot1yr allnsa_bc allnsa_gc allnsa_bl allnsa_tot1yr 
        para_bc para_gc para_bl para_tot1yr bago_bc bago_gc bago_bl bago_tot1yr abago_bc abago_gc abago_bl abago_tot1yr opio_bc opio_gc opio_bl opio_tot1yr acho_bc acho_gc acho_bl acho_tot1yr sterinh_bc sterinh_gc sterinh_bl sterinh_tot1yr lra_bc lra_gc lra_bl lra_tot1yr xant_bc xant_gc xant_bl xant_tot1yr ahist_bc ahist_gc ahist_bl ahist_tot1yr ahistc_bc ahistc_gc ahistc_bl ahistc_tot1yr h2_bc h2_gc h2_bl h2_tot1yr ppi_bc ppi_gc ppi_bl ppi_tot1yr  IBD_tot1yr thyro_bc thyro_gc thyro_bl thyro_tot1yr sterint_bc sterint_gc sterint_bl 
        sterint_tot1yr stersys_bc stersys_gc stersys_bl stersys_tot1yr stertop_bc stertop_gc stertop_bl stertop_tot1yr gesta_bc gesta_gc gesta_bl gesta_tot1yr pill_bc pill_gc pill_bl pill_tot1yr HRTopp_bc HRTopp_gc HRTopp_bl HRTopp_tot1yr estr_bc estr_gc estr_bl estr_tot1yr adem_bc adem_gc adem_bl adem_tot1yr apsy_bc apsy_gc apsy_bl apsy_tot1yr benzo_bc benzo_gc benzo_bl benzo_tot1yr hypno_bc hypno_gc hypno_bl hypno_tot1yr ssri_bc ssri_gc ssri_bl ssri_tot1yr li_bc li_gc li_bl li_tot1yr mao_bc mao_gc mao_bl mao_tot1yr oadep_bc oadep_gc oadep_bl 
        oadep_tot1yr mnri_bc mnri_gc mnri_bl mnri_tot1yr adep_bc adep_gc adep_bl adep_tot1yr pheny_bc pheny_gc pheny_bl pheny_tot1yr barbi_bc barbi_gc barbi_bl barbi_tot1yr succi_bc succi_gc succi_bl succi_tot1yr valpro_bc valpro_gc valpro_bl valpro_tot1yr carba_bc carba_gc carba_bl carba_tot1yr oaconvu_bc oaconvu_gc oaconvu_bl oaconvu_tot1yr aconvu_bc aconvu_gc aconvu_bl 
        aconvu_tot1yr isupp_bc isupp_gc isupp_bl isupp_tot1yr TnfAI_bc TnfAI_gc TnfAI_bl TnfAI_tot1yr Budeo_bc Budeo_gc Budeo_bl Budeo_tot1yr OtherImm_bc OtherImm_gc OtherImm_bl OtherImm_tot1yr CycloSpor_bc CycloSpor_gc CycloSpor_bl CycloSpor_tot1yr Iso_oral_bc Iso_oral_gc Iso_oral_bl Iso_oral_tot1yr Iso_top_bc Iso_top_gc Iso_top_bl Iso_top_tot1yr Myco_bc Myco_gc Myco_bl Myco_tot1yr Etan_bc Etan_gc Etan_bl Etan_tot1yr Ipili_bc Ipili_gc Ipili_bl Ipili_tot1yr Ritux_bc Ritux_gc Ritux_bl Ritux_tot1yr EndOfLine  ;
format dpp4i;
   /* where indexdate=date of first Rx, filldate2=date of 2nd rx, and for the main analysis the entry=date of 2nd prescription */
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
format dpp4i;
RUN;

/*Make cuts to dataset*/
data dsn; set dsn; 
if delete_flag1=1 then delete;
if ibd_ever =1 then delete;
format dpp4i; run;

ods output ParameterEstimates = mvcoxhr;
proc phreg data=dsn covsandwich(aggregate) ;
   class  entry_year (ref="2015") sex (ref=first) hba1c_Cat2 (ref=first) alcohol_cat (ref=first) smoke_cat (ref=first) bmi_cat2(ref=first) /param=ref  ;
   model time*event(0)= &exposure. &basemodelvars. &addedmodelvars. /ties=efron rl;
run;

Data mvcoxhr_acnu(keep= analysis parameter classval0 &exposure chr clcl cucl mvcox_HR);
    set mvcoxhr;
	analysis ="ACNU &type. MVCox";
    &exposure=1;
    chr=exp(Estimate);
    clcl=exp(Estimate-1.96*StdErr);
    cucl=exp(Estimate+1.96*StdErr);
    mvcox_HR=compress(put((hazardratio),6.1))||" ("||compress(put((HRlowerCL),6.1))||"-"||compress(put((HRupperCL),6.1))||")";
run;

data mvcox_&exposure._&comparator.; set 
mvcoxhr_acnu
mvcoxhr_tve; 
ClassVal0="&comparator.";
run;

proc print data= mvcox_&exposure._&comparator.  ;  
where parameter="dpp4i";
run; 
proc print data= mvcox_&exposure._&comparator.  ;  
run; 
/**/
%mend mvcox_analysis;

/* Getting the adjustment variables from the PS weighting anaylsis */
%LET basevars =  age|age
sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever 

bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 

psorp_ever vasc_ever 
RhArth_ever SjSy_ever sLup_ever ;

%LET addedDPP4ivSU = oAntGLP_1yrlookback sglt2i_1yrlookback TZD_1yrlookback;
%mvcox_analysis (
exposure=dpp4i,
comparator=SU,
basemodelvars= &basevars,
addedmodelvars= &addedDPP4ivSU,
ana_name= MVCox,
data_prefix=,
type= IT,
induction=180,
latency=180,
ibd_Def=ibd1,
intime=filldate2,
outtime='31Dec2022'd);

%LET addedDPP4ivTZD = oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback;
%mvcox_analysis (
exposure=dpp4i,
comparator=TZD,
basemodelvars= &basevars,
addedmodelvars= &addedDPP4ivTZD,
ana_name= MVCox,
data_prefix=,
type= IT,
induction=180,
latency=180,
ibd_Def=ibd1,
intime=filldate2,
outtime='31Dec2022'd);

%LET addedDPP4ivSGLT2i = oAntGLP_1yrlookback su_1yrlookback TZD_1yrlookback;
%mvcox_analysis (
exposure=dpp4i,
comparator=sglt2i,
basemodelvars= &basevars,
addedmodelvars= &addedDPP4ivsglt2i,
ana_name= MVCox,
data_prefix=,
type= IT,
induction=180,
latency=180,
ibd_Def=ibd1,
intime=filldate2,
outtime='31Dec2022'd);


/* Draft macro stuff */
