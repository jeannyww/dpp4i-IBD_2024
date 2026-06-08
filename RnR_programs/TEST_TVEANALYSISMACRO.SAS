%macro TVE_analysis (pstrim, exclude_ibd, exposure , comparator , ana_name , type , weight , induction , latency , ibd_def , intime , outtime , numyears, outdata, save) / minoperator mindelimiter=',';

    /*===================================*\
    //SECTION - Setting up data for analysis 
    \*===================================*/
    %if %upcase(&pstrim.) eq Y %then %do; 
        data dsn; set a.Abrahami_PS&ana_name._&exposure._&comparator; run; 
    %end; 
    %else %if %upcase(&pstrim.) eq N %then %do; 
        data dsn; set a.Abrahami_Notrim&ana_name._&exposure._&comparator.; run; 
    %end; 
    /* Include or Exclude those with prevalent IBD */
    %if %upcase(&exclude_ibd.) eq Y %then %do; *exclude==Y is main analysis;
        data dsn; set dsn; where IBD_ever ne 1;RUN; 
    %end;
    %else %if %upcase(&exclude_ibd.) eq N %then %do;
        data dsn; set dsn; RUN;
    %end;

data dsn; 
		set dsn; 
*drop Alc_P_bc Alc_P_bl colo_bc colo_bl IBD_P_bc IBD_P_bl DivCol_I_bc DivCol_I_bl DivCol_P_bc DivCol_P_bl PCOS_bc PCOS_bl DiabGest_bc DiabGest_bl IBD_I_bc IBD_I_bl asthma_bc asthma_bl copd_bc copd_bl arrhyth_bc arrhyth_bl chf_bc chf_bl ihd_bc ihd_bl mi_bc mi_bl hyperten_bc hyperten_bl stroke_bc stroke_bl hyperlip_bc hyperlip_bl diab_bc diab_bl dvt_bc dvt_bl pe_bc pe_bl gout_bc 
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


/*=================*\
*!SECTION Update counts for exclusion
\*=================*/
	/* Taking a look at if switchers are deleted */
PROC SQL;
    /* Count rows of repeat ids */
    create table num_rows_fin as select ID, count(*) as num_rows_fin
    from dsn
    where (delete_flag1=0)
	group by ID;
    /* Add num_rows_fin */
    create table tve_dsn2 as select a.*, b.num_rows_fin 
    from dsn as a
    left join num_rows_fin as b
    on a.ID=b.ID;
QUIT;

data dsn; set tve_dsn2; 
if  num_rows_acnu=1 and num_rows_tve=2 and num_rows_fin=1 and ibd_ever=1 and switcher_flag=1 then 
delete_switcherdpp4i=1;
else delete_switcherdpp4i=0;run;

PROC SQL noprint; 
    create table tmp_counts as select * from temp.Abexclusions_015_&exposure._&comparator.;
	*For each exclusion, update the exclusion number and the counts;
    select count(*) into : num_obs from tmp_counts;
    insert into tmp_counts
        set exclusion_num=&num_obs+1, 
        long_text="Number of observations after excluding individuals whose endstudy_dt <= &intime. + &induction.",
        dpp4i       	  =  (select count(*) from dsn where (&exposure = 1  and deleteobs=0)),
        dpp4i_diff 		  = -(select count(*) from dsn where (&exposure = 1  and deleteobs=1)),
        &comparator.      =  (select count(*) from dsn where (&exposure ne 1 and deleteobs=0)) ,
        &comparator._diff = -(select count(*) from dsn where (&exposure ne 1 and deleteobs=1)),   
        full= (select count(*) from dsn where (deleteobs=0));
    insert into tmp_counts
        set exclusion_num=&num_obs+2, 
        long_text="Number of individuals with time0 <&ibd_def._dt <= &intime. + &induction.",
        dpp4i			  =  (select count(*) from dsn where (&exposure = 1  and IBDdx_inductionperiod=0)),
        dpp4i_diff		  = -(select count(*) from dsn where (&exposure = 1  and IBDdx_inductionperiod=1)),
        &comparator.	  =  (select count(*) from dsn where (&exposure ne 1 and IBDdx_inductionperiod=0)) ,
        &comparator._diff = -(select count(*) from dsn where (&exposure ne 1 and IBDdx_inductionperiod=1)),
        full= (select count(*) from dsn where (  deleteobs=0 and IBDdx_inductionperiod=0));
    select count(*) into : num_obs from tmp_counts;
    insert into tmp_counts
        set exclusion_num=&num_obs+1, 
        long_text="Number of individuals with positive, non-zero &type followup time (enddate-(&intime.+&induction)>0)",
        dpp4i            =  (select count(*) from dsn where (&exposure=1    and time ne .)),
        dpp4i_diff       = -(select count(*) from dsn where (&exposure=1    and time eq .)),
        &comparator.     =  (select count(*) from dsn where (&exposure ne 1 and time ne .)) ,
        &comparator._diff= -(select count(*) from dsn where (&exposure ne 1 and time eq .)),   
        full= (select count(*) from dsn where ( deleteobs=0 and IBDdx_inductionperiod=0 and time ne .));
    select count(*) into : num_obs from tmp_counts;
    insert into tmp_counts
        set exclusion_num=&num_obs+1, 
        long_text="Number dpp4i switchers who met criteria but their comparator switcher row was deleted (delete_flag=1)",
        dpp4i            =  (select count(*) from dsn where (&exposure=1    and delete_switcherdpp4i =0)),
        dpp4i_diff       = -(select count(*) from dsn where (&exposure=1    and delete_switcherdpp4i = 1)),
        &comparator.     =  (select count(*) from dsn where (&exposure ne 1 and delete_switcherdpp4i =0)) ,
        &comparator._diff= -(select count(*) from dsn where (&exposure ne 1 and delete_switcherdpp4i = 1)),   
        full= (select count(*) from dsn where ( deleteobs=0 and IBDdx_inductionperiod=0 and delete_switcherdpp4i=0));
    select * from tmp_counts;
    %if %upcase(&save) eq Y %then %do;
        create table temp.Abex_016&ANA_NAME._&exposure._&comparator._&type. as select * from tmp_counts;
        %end;
quit;
/*Make cuts to dataset*/
data dsn; set dsn; 
if delete_flag1=1 then delete;
/*Delete dpp4i switchers whose delete_flag1=0 but whose comparator switcher row was deleted (delete_flag=1) */ 
if num_rows_acnu=1 and num_rows_tve=2 and num_rows_fin=1 and ibd_ever=1 and switcher_flag=1
then delete;
format dpp4i; run;

proc datasets library=work nodetails nolist noprint; 
delete tve_dsn2  ; 
run; quit; 
/*===================================*\
Getting all counts for the Results Tables
\*===================================*/

%if %upcase(&exclude_ibd.) eq N %then %do; 
	/*Get counts of switchers with IBD event */
	 ods output summary=previbdevents;
	 proc means data =  dsn        
	STACKODS N NMISS SUM  maxdec=2  ; 
	where delete_flag1 ne 1 and ibd_Ever=1 and switcher_flag=1;
	class switcher_flag;
	var   event; 
	run; 
	proc print data= previbdevents  ;  
	run; 
	/*Fu timeamong prev ibd*/
	ods output summary=previbdfutime;
	proc means data =  dsn        
	STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 maxdec=2  ; 
	where delete_flag1 ne 1 and ibd_Ever=1 and switcher_flag=1;
	class switcher_flag;  *important to use switcher_flag, not switcher variable;
	var    time        ; 
	run; 
	data previbdfutime; set previbdfutime;
	median_py=
		compress(put((median), 6.1)) || " (" || compress(put((q1), 6.1)) || "-" || compress(put((q3), 6.1)) || ")"; 
	run;
	proc print data=   previbdfutime;  
	run; 
	/*Sum of median time on drug for prev ibd*/
	ods output summary=previbdtime_drugdur;
	proc means data =  dsn       
	STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 maxdec=2  ; 
	where delete_flag1 ne 1 and ibd_Ever=1 and switcher_flag=1;
	class switcher_flag;
	var    time_drugdur        ; 
	run; 
	data previbdtime_drugdur; set previbdtime_drugdur;
	 &exposure._switcher_flag=.;
	  &comparator._switcher_flag=.;
	if switcher_flag in (0,1) then &exposure._switcher_flag=switcher_flag; 
	if switcher_flag in (2,3) then &comparator._switcher_flag=switcher_flag; 
	sum_timedrug=sum;
	median_timedrug=
		compress(put((median), 6.1)) || " (" || compress(put((q1), 6.1)) || "-" || compress(put((q3), 6.1)) || ")"; 
	keep switcher_flag &exposure._switcher_flag &comparator._switcher_flag sum_timedrug median_timedrug;
	run;
	proc print data= previbdtime_drugdur  ;  
	run; 
	/*output data for prevalent IBD*/
	data previbdfutime_1; 
	retain status &exposure._switcher_flag &exposure._NObs &exposure._events &exposure._sum_py &exposure._median_py;
	merge previbdfutime previbdevents(keep=switcher_flag sum rename=(sum=&exposure._events)); 
	by switcher_flag;
	where switcher_flag=1;
	&exposure._switcher_flag=switcher_flag;
	status="Switcher with prevIBD";
	&exposure._NObs=NObs;
	&exposure._sum_py=sum;
	&exposure._median_py = median_py;
	keep status &exposure._switcher_flag &exposure._NObs &exposure._events &exposure._sum_py &exposure._median_py;
	run;
	proc print ; run; 

	data previbdswitcher_flag1;
	merge previbdfutime_1 previbdtime_drugdur;
	rename sum_timedrug=&exposure._sum_timedrug;
	rename median_timedrug=&exposure._median_timedrug;
	where &exposure._switcher_flag=1;
	by &exposure._switcher_flag;
	drop switcher_flag &comparator._switcher_flag;
	run;
	proc print ; run; 
%end;  
%if %upcase(&exclude_ibd.) eq Y	 %then %do; 
/*Create blank dummy table*/
data previbdswitcher_flag1;
status="Switcher with prevIBD";
dpp4i_switcher_flag=1;
dpp4i_NObs=.;
dpp4i_events=.;
dpp4i_sum_py=.;
dpp4i_median_py="";
dpp4i_sum_timedrug=.;
dpp4i_median_timedrug="";
;run;
%end; 

/*1) Get sum of IBD events by switcher type*/
ods output summary=event;
proc means data =  dsn        
STACKODS N NMISS SUM  maxdec=2  ; 
where delete_flag1 ne 1;
class switcher_flag;  *important to use switcher_flag, not switcher variable;
var    event        ; 
run; 
proc print data= event  ;  
run; 
/*Also get total IBD events by DPP4i/comparator*/
ods output summary= o_event;
proc means data =  dsn        
STACKODS N NMISS SUM  maxdec=2  ; 
where delete_flag1 ne 1;
class dpp4i;  *important to use switcher_flag, not switcher variable;
var    event        ; 
run;
proc print data=o_event   ;  
run; 
data o_event; set o_event; 
status="Sum";
if dpp4i = 1 then do;
&exposure._NObs=NObs;
&exposure._events=sum;
end;  
else if dpp4i =0 then do;
&comparator._NObs=NObs;
&comparator._events=sum;
end;  
keep status dpp4i 
&exposure._NObs
&exposure._events &comparator._NObs
&comparator._events;
run;
proc print data=  o_event ;  
run; 
proc sql;
create table o_eventf as select distinct status,
max(&exposure._NObs) as &exposure._NObs, max(&exposure._events) as &exposure._events,
max(&comparator._NObs) as &comparator._NObs, max(&comparator._events) as &comparator._events
from o_event; 
select * from o_eventf;
quit;
/*2) Get sum  and  median followup time by switcher type*/
ods output summary=futime;
proc means data =  dsn        
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 maxdec=2  ; 
where delete_flag1 ne 1;
class switcher_flag;  *important to use switcher_flag, not switcher variable;
var    time        ; 
run; 
data futime; set futime;
median_py=
	compress(put((median), 6.1)) || " (" || compress(put((q1), 6.1)) || "-" || compress(put((q3), 6.1)) || ")"; 
run;
proc print data=   futime;  
run; 
/*Also get sum by dpp4i status */
ods output summary= o_futime;
proc means data =  dsn        
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 maxdec=2  ; 
where delete_flag1 ne 1;
class dpp4i;  *important to use switcher_flag, not switcher variable;
var    time        ; 
run;
data o_futime; set o_futime; 
status="Sum";
if dpp4i=1 then do;
&exposure._sum_py=sum;
&exposure._median_py=
	compress(put((median), 6.1)) || " (" || compress(put((q1), 6.1)) || "-" || compress(put((q3), 6.1)) || ")"; 
end;  
if dpp4i=0 then do;
&comparator._sum_py=sum;
&comparator._median_py=
	compress(put((median), 6.1)) || " (" || compress(put((q1), 6.1)) || "-" || compress(put((q3), 6.1)) || ")"; 
end;  
keep dpp4i status &exposure._sum_py &exposure._median_py &comparator._sum_py &comparator._median_py;
run;
proc print data=  o_futime ;  
run; 
proc sql;
create table o_futimef as select distinct status, 
max(&exposure._sum_py) as &exposure._sum_py, 
max(&exposure._median_py) as &exposure._median_py,
max (&comparator._sum_py) as &comparator._sum_py, 
max(&comparator._median_py) as &comparator._median_py
from o_futime;
select * from o_futimef;
quit;

/*3) Get sum of and median time on drug by switcher type*/
ods output summary=time_drugdur;
proc means data =  dsn       
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 maxdec=2  ; 
where delete_flag1 ne 1;
class switcher_flag;
var    time_drugdur        ; 
run; 
data time_drugdur; set time_drugdur;
 &exposure._switcher_flag=.;
  &comparator._switcher_flag=.;
if switcher_flag in (0,1) then &exposure._switcher_flag=switcher_flag; 
if switcher_flag in (2,3) then &comparator._switcher_flag=switcher_flag; 
sum_timedrug=sum;
median_timedrug=
	compress(put((median), 6.1)) || " (" || compress(put((q1), 6.1)) || "-" || compress(put((q3), 6.1)) || ")"; 
keep switcher_flag &exposure._switcher_flag &comparator._switcher_flag sum_timedrug median_timedrug;
run;
proc print data= time_drugdur  ;  
run; 
/*Get sum of and median time on drug overall by dpp4i*/
ods output summary=o_drugdur;
proc means data =  dsn       
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 maxdec=2  ; 
where delete_flag1 ne 1;
class dpp4i;
var    time_drugdur        ; 
run; 
data o_drugdur; set o_drugdur;
status="Sum";
sum_timedrug=sum;
median_timedrug=
	compress(put((median), 6.1)) || " (" || compress(put((q1), 6.1)) || "-" || compress(put((q3), 6.1)) || ")"; 
if dpp4i=1 then do; 
&exposure._median_timedrug=median_timedrug; 
&exposure._sum_timedrug=sum_timedrug; 
end;  
if dpp4i=0 then do; 
&comparator._median_timedrug=median_timedrug; 
&comparator._sum_timedrug=sum_timedrug; 
end;  
keep status &exposure._sum_timedrug &exposure._median_timedrug &comparator._sum_timedrug
&comparator._median_timedrug ; 
run;
proc print data= o_drugdur  ;  
run; 
proc sql;
create table o_drugdurf as select distinct 
status, max(&exposure._sum_timedrug) as &exposure._sum_timedrug, 
max(&exposure._median_timedrug) as &exposure._median_timedrug, max(&comparator._sum_timedrug) as &comparator._sum_timedrug,
max(&comparator._median_timedrug) as &comparator._median_timedrug
from o_drugdur; 
select * from o_drugdurf; quit;

/*4) Output data for puredpp4i switcher_flag=0 */
data futime_0; 
retain status &exposure._switcher_flag &exposure._NObs &exposure._events &exposure._sum_py &exposure._median_py;
merge futime event(keep=switcher_flag sum rename=(sum=&exposure._events)); 
by switcher_flag;
where switcher_flag=0;
&exposure._switcher_flag=switcher_flag;
status="Noswitch";
&exposure._NObs=NObs;
&exposure._sum_py=sum;
&exposure._median_py = median_py;
keep status &exposure._switcher_flag &exposure._NObs &exposure._events &exposure._sum_py &exposure._median_py;
run;

data switcher_flag0;
merge futime_0 time_drugdur;
rename sum_timedrug=&exposure._sum_timedrug;
rename median_timedrug=&exposure._median_timedrug;
where &exposure._switcher_flag=0;
by &exposure._switcher_flag;
drop switcher_flag &comparator._switcher_flag;
run;
proc print data=switcher_flag0 ; run; 

/*5) Output data for switcherdpp4i switcher_flag=1*/
data futime_1; 
retain status &exposure._switcher_flag &exposure._NObs &exposure._events &exposure._sum_py &exposure._median_py;
merge futime event(keep=switcher_flag sum rename=(sum=&exposure._events)); 
by switcher_flag;
where switcher_flag=1;
&exposure._switcher_flag=switcher_flag;
status="Switcher";
&exposure._NObs=NObs;
&exposure._sum_py=sum;
&exposure._median_py = median_py;
keep status &exposure._switcher_flag &exposure._NObs &exposure._events &exposure._sum_py &exposure._median_py;
run;
proc print ; run; 

data switcher_flag1;
merge futime_1 time_drugdur;
rename sum_timedrug=&exposure._sum_timedrug;
rename median_timedrug=&exposure._median_timedrug;
where &exposure._switcher_flag=1;
by &exposure._switcher_flag;
drop switcher_flag &comparator._switcher_flag;
run;
proc print ; run; 

/*6) Furthermore, for  Output data for switcher comparator switcher_flag=2*/

data futime_2; 
retain status &comparator._switcher_flag &comparator._NObs &comparator._events &comparator._sum_py &comparator._median_py;
merge futime event(keep=switcher_flag sum rename=(sum=&comparator._events)); 
by switcher_flag;
where switcher_flag=2;
&comparator._switcher_flag=switcher_flag;
status="Switcher";
&comparator._NObs=NObs;
&comparator._sum_py=sum;
&comparator._median_py = median_py;
keep status &comparator._switcher_flag &comparator._NObs &comparator._events &comparator._sum_py &comparator._median_py;
run;
proc print ; run; 

data switcher_flag2;
merge futime_2 time_drugdur;
rename sum_timedrug=&comparator._sum_timedrug;
rename median_timedrug=&comparator._median_timedrug;
where &comparator._switcher_flag=2;
by &comparator._switcher_flag;
drop switcher_flag &exposure._switcher_flag;
run;
proc print ; run; 

/*For switcher_flag=2, disaggregate between switchers with two rows and switchers where their dpp4i row was excluded*/
proc freq data=   dsn ; 
where delete_flag1 ne 1 and switcher_flag eq 2;
tables   switcher_flag*num_rows_fin / list missing; 
run; 
/*counts by numrows*/
ods output summary=disaggevent;
proc means data =  dsn        
STACKODS N NMISS SUM  maxdec=2  ; 
where delete_flag1 ne 1 and switcher_flag eq 2;
class switcher_flag num_rows_fin;  *important to use switcher_flag, not switcher variable;
var    event        ; 
run; 
proc print data= disaggevent  ;  
run; 
/*disagg futime*/
ods output summary=disaggfutime;
proc means data =  dsn        
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 maxdec=2  ; 
where delete_flag1 ne 1 and switcher_flag eq 2;
class switcher_flag num_rows_fin;  *important to use switcher_flag, not switcher variable;
var    time        ; 
run; 
data disaggfutime; set disaggfutime;
median_py=
	compress(put((median), 6.1)) || " (" || compress(put((q1), 6.1)) || "-" || compress(put((q3), 6.1)) || ")"; 
run;
proc print data=   disaggfutime;  
run; 
/*disagg time on drug*/
ods output summary=disaggtime_drugdur;
proc means data =  dsn       
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 maxdec=2  ; 
where delete_flag1 ne 1 and switcher_flag eq 2;
class switcher_flag num_rows_fin;  *important to use switcher_flag, not switcher variable;
var    time_drugdur        ; 
run; 
data disaggtime_drugdur; set disaggtime_drugdur;
 &exposure._switcher_flag=.;
  &comparator._switcher_flag=.;
if switcher_flag in (0,1) then &exposure._switcher_flag=switcher_flag; 
if switcher_flag in (2,3) then &comparator._switcher_flag=switcher_flag; 
sum_timedrug=sum;
median_timedrug=
	compress(put((median), 6.1)) || " (" || compress(put((q1), 6.1)) || "-" || compress(put((q3), 6.1)) || ")"; 
keep switcher_flag &exposure._switcher_flag &comparator._switcher_flag sum_timedrug median_timedrug;
run;
proc print data= disaggtime_drugdur  ;  
run; 
/*switcher_flag 2 disaggregated*/

data disaggfutime_2; 
length status $30.;
retain status &comparator._switcher_flag &comparator._NObs &comparator._events &comparator._sum_py &comparator._median_py;
merge disaggfutime disaggevent(keep=switcher_flag sum rename=(sum=&comparator._events)); 
by switcher_flag;
where switcher_flag=2;
&comparator._switcher_flag=switcher_flag;
if num_rows_fin=2 then status="Switcher with DPP4i";
if num_rows_fin=1 then status="Switcher without DPP4i";
&comparator._NObs=NObs;
&comparator._sum_py=sum;
&comparator._median_py = median_py;
keep status &comparator._switcher_flag &comparator._NObs &comparator._events &comparator._sum_py &comparator._median_py;
run;
proc print ; run; 

data disaggswitcher_flag2;
merge disaggfutime_2 disaggtime_drugdur;
rename sum_timedrug=&comparator._sum_timedrug;
rename median_timedrug=&comparator._median_timedrug;
where &comparator._switcher_flag=2;
by &comparator._switcher_flag;
drop switcher_flag &exposure._switcher_flag;
run;
proc print ; run; 
/*6) Output data for pure comparator comparator switcher_flag=3*/

data futime_3; 
retain status &comparator._switcher_flag &comparator._NObs &comparator._events &comparator._sum_py &comparator._median_py;
merge futime event(keep=switcher_flag sum rename=(sum=&comparator._events)); 
by switcher_flag;
where switcher_flag=3;
&comparator._switcher_flag=switcher_flag;
status="Noswitch";
&comparator._NObs=NObs;
&comparator._sum_py=sum;
&comparator._median_py = median_py;
keep status &comparator._switcher_flag &comparator._NObs &comparator._events &comparator._sum_py &comparator._median_py;
run;
proc print ; run; 

data switcher_flag3;
merge futime_3 time_drugdur;
rename sum_timedrug=&comparator._sum_timedrug;
rename median_timedrug=&comparator._median_timedrug;
where &comparator._switcher_flag=3;
by &comparator._switcher_flag;
drop switcher_flag &exposure._switcher_flag;
run;
proc print ; run; 

/*7) get Incident Rates*/
proc sort data=dsn; 
	by &exposure; 
run;
%let exposure=dpp4i;
%LET event = event;
%LET logtimevar = logtime;
%LET timevar = time;
proc genmod data=dsn;
	where delete_flag1 ne 1;
	by &exposure;
	* class id;
	model &event= /dist=poisson offset=&logtimevar maxiter=100000;
	* repeated subject=id;
	estimate 'rate' int 1/exp;
	ods output estimates=rate;
run;
proc print data= rate; run;
Data rate(keep=&exposure rate);
    set rate;
    if Label='Exp(rate)';
    rate=compress(put((LBetaEstimate),6.1))||" ("||compress(put((LBetaLowerCL),6.1))||"-"||compress(put((LBetaUpperCL),6.1))||")";
    run;
proc transpose data= rate out=rate_t prefix=rate_&exposure.; var  rate; id &exposure.;run;
data rate_t; set rate_t; 
status="Sum";run;
proc print data= rate_t; run; 

/*8) get Crude HR*/
ods output ParameterEstimates = crudehr;
Proc phreg data=dsn covsandwich(aggregate);
where delete_flag1 ne 1;
    id id;
    model &timevar*&event(0)=&exposure /ties=efron rl;
    title ' crude HR';
run;
Data crudehr(keep= status &exposure chr clcl cucl crude_HR);
    set crudehr;
	status="Sum";
    &exposure=1;
    chr=exp(Estimate);
    clcl=exp(Estimate-1.96*StdErr);
    cucl=exp(Estimate+1.96*StdErr);
    crude_HR=compress(put((hazardratio),6.1))||" ("||compress(put((HRlowerCL),6.1))||"-"||compress(put((HRupperCL),6.1))||")";
run;
proc print data=crudehr   ;  
run; 

/*9) get Adjusted HR*/
%LET weight = smrw;
ods output ParameterEstimates =&WEIGHT;
proc phreg data=dsn covsandwich(aggregate);
where delete_flag1 ne 1;
    id id;
    weight &weight; 
    model  &timevar*&event(0)=&exposure  /ties=efron rl;
    title 'SMRW adjusted HR';
run;
Data &WEIGHT(keep=status &exposure whr wlcl wucl &weight._HR);
    set &WEIGHT;
	status="Sum";
    &exposure=1;
    whr =exp(Estimate);
    wlcl=exp(Estimate-1.96*StdErr);
    wucl=exp(Estimate+1.96*StdErr);
    &weight._HR=compress(put((hazardratio),6.1))||" ("||compress(put((HRlowerCL),6.1))||"-"||compress(put((HRupperCL),6.1))||")";
run;

/*===================================*\
Put all results together 
\*===================================*/
/*No switchers*/
proc print data=  switcher_flag0 ; *dpp4;
proc print data=   switcher_flag3;  *comparator;
/*Switchers*/
proc print data=  switcher_flag1; *dpp4;
proc print data=  switcher_flag2 ; *comparator;
run; 
/*By overal dpp4i status*/
proc print data= o_eventf  ; 
proc print data=  o_futimef ; 
proc print data=o_drugdurf;  
run; 
proc sql;
create table overallf as select a.status,
a.&exposure._NObs, a.&exposure._events, 
b.&exposure._sum_py, b.&exposure._median_py,
c.&exposure._sum_timedrug, 
c.&exposure._median_timedrug, d.rate_dpp4i1 as &exposure._eventrate, 
a.&comparator._NObs, a.&comparator._events, 
b.&comparator._sum_py , b.&comparator._median_py, 
c.&comparator._sum_timedrug, 
c.&comparator._median_timedrug, d.rate_dpp4i0 as &comparator._eventrate,
e.crude_HR, f.smrw_HR
from o_eventf as a
full join o_futimef as b
on a.status = b.status 
full join o_drugdurf as c 
on a.status=c.status
full join rate_t as d
on a.status=d.status
full join crudehr as e  
on a.status=e.status
full join smrw as f
on a.status=f.status;
select * from overallf;
quit;
/*Rates and HRs*/
proc print data=  rate_t ;  
proc print data=  crudehr ;  
proc print data=  smrw ;  
run; 

/*Stack dpp4i*/
data &exposure._results; 
length status $30.;
set switcher_flag0 switcher_flag1 previbdswitcher_flag1 overallf; 
drop &comparator._: ;
run;
title "Among &exposure."; 
proc print ; run; 
/*Stack comparator*/
data &comparator._results; 
length status $30.;
set switcher_flag3 switcher_flag2 disaggswitcher_flag2 overallf;
drop &exposure._:; run;
title "Among &comparator."; 
proc print ; run; 
/*Combine in one table*/
/*Wide version*/
data summaryTVE_W_&exposure._&comparator.;
merge &exposure._results (drop = crude_HR smrw_HR) &comparator._results ;
analysis=	"TVE &type. &ana_name." ;
run;
title "Summary results &exposure. &comparator."; 
proc print ; run; 
/*Long version*/
proc sql;
create table summaryTVE_L_&exposure._&comparator.
as select * from 
	(select 
	"TVE &type. &ana_name." as analysis, 
	&exposure._switcher_flag as switcher_flag, 
	"&exposure." as drug, 
	status, 
	&exposure._NObs as NObs,
	&exposure._events as events, 
	&exposure._sum_py as sum_py, 
	&exposure._median_py as median_py,
	&exposure._sum_timedrug as sum_timedrug, 
	&exposure._median_timedrug as median_timedrug, 
	&exposure._eventrate as eventrate,
	crude_HR, smrw_HR
/*	,"" as crude_HR, "" as smrw_HR*/
	from &exposure._results)
union all corr 
	(select 
	"TVE &type. &ana_name." as analysis, 
	&comparator._switcher_flag as switcher_Flag,
	"&comparator." as drug, 
	status, 
	&comparator._NObs as NObs,
	&comparator._events as events, 
	&comparator._sum_py as sum_py ,
	 &comparator._median_py as median_py, 
	&comparator._sum_timedrug as sum_timedrug, 
	&comparator._median_timedrug as median_timedrug, 
	&comparator._eventrate as eventrate , 
	"" as crude_HR, "" as smrw_HR
/*	crude_HR, smrw_HR*/
	from &comparator._results);
*select * from summaryresultsL_&exposure._&comparator.;
quit;
title ""; 

/*10) Weighted KM plot*/
    /* weighted risks    */
    proc phreg data=dsn COVS ;
		where delete_flag1 eq 0;
        MODEL &timevar*&event(0)= ; 
        strata &exposure;
        WEIGHT &weight;
        ID id ;
        baseline out=Pred survival=_all_ lower=lower upper=upper ;
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


    data   exp(keep=&timevar risk risk_lower risk_upper &exposure.) 
         unexp(keep=&timevar risk risk_lower risk_upper &exposure.);
        set  pred;
        if &exposure=1 then output exp;
        if &exposure=0 then output unexp;
    run;


	Data plot;
		merge exp(rename=(risk=&exposure._risk   risk_lower=&exposure._lower   risk_upper=&exposure._upper)) 
		    unexp(rename=(risk=&comparator._risk risk_lower=&comparator._lower risk_upper=&comparator._upper));
		by &timevar;
	run;

proc template;
	define style mystyle;
	parent=styles.sasweb;
	class graphwalls/frameborder=off;
	class graphbackground/color=white;
	end;
run;

/* Trigger ods excel to create a new sheet for the plots and main results */
/*ods excel options(sheet_interval="NOW");*/
/*ods graphics /noborder reset=index imagename="test" imagefmt=tiff;*/
ods graphics /noborder reset=index imagename="wKM_&ana_name._&exposure.v&comparator._%sysfunc(date(),date.)" imagefmt=tiff;
ods listing style=mystyle gpath="&fOutPath.";  

PROC SGPLOT DATA = plot NOAUTOLEGEND DESCRIPTION=""; 
    YAXIS LABEL = 'Risk of Inflammatory Bowel Disease' LABELATTRS=(size=13pt weight=bold)  VALUES = (0 TO 0.0045 BY 0.0005) valueattrs=(size=12pt); 
    /* 2024-12-18 JW change to a macro variable &numyears for KM followup */
    XAXIS LABEL = 'Follow-up Time (years)' LABELATTRS=(size=13pt weight=bold)  VALUES = (0 TO &numyears. BY 0.5)       valueattrs=(size=12pt);
    title height=12pt bold " ";
    step x=&timevar y=&exposure._risk /lineattrs=(color=blue pattern=1  thickness=2) name="&exposure.";
    step x=&timevar y=&exposure._lower/lineattrs=(color=blue pattern=20 thickness=1) name="&exposure._lower";
    step x=&timevar y=&exposure._upper/lineattrs=(color=blue pattern=20 thickness=1) name="&exposure._upper";

    step x=&timevar y=&comparator._risk /lineattrs=(color=red  pattern=1  thickness=2) name="&comparator.";
    step x=&timevar y=&comparator._lower/lineattrs=(color=red  pattern=20 thickness=1) name="&comparator._lower";
    step x=&timevar y=&comparator._upper/lineattrs=(color=red  pattern=20 thickness=1) name="&comparator._upper";
    keylegend "&exposure." "&comparator." /location=inside position=topleft valueattrs=(size=12pt weight=bold) NOBORDER;
    FOOTNOTE;
    RUN; 
ods graphics off;
title "Exclusion table &exposure. v &comparator."; 
proc sql;
select * from tmp_counts;quit;
title ""; 

title "DSN means of fu time by event that goes into proc phreg &exposure. v &comparator.";
proc means data = dsn         
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ;
where delete_flag1=0;
class dpp4i event; 
var    &timevar          ; 
run; 
title "pred data output from the proc phreg BASELINE statement &exposure. v &comparator.";
proc means data = pred         
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ;
class dpp4i; 
var    &timevar          ; 
run;
title "Summary output Long version &exposure. v &comparator.";
proc sql;
select * from summaryTVE_L_&exposure._&comparator.;
quit;
title "Summary output Wide Version &exposure. v &comparator."; 
proc sql;
select * from summaryTVE_W_&exposure._&comparator.;
quit;
title "Number at Risk  &exposure. v &comparator."; 
 
    /*No. of risk at 0 year*/
    %let dataset=dsn;
    proc sql noprint; create table tmpp_b as select "&exposure."   as drug length=12,0 as fu_year,   count(id) as total_id, "No. at risk for &comparator initiator at 0 year" as label length=60 from &dataset where &exposure=0; quit;
    proc sql noprint; create table tmpp_a as select "&comparator." as drug length=12,0 as fu_year,   count(id) as total_id, "No. at risk for &exposure initiator at 0 year" as label length=60 from &dataset where &exposure=1; quit;
    /*No. of risk at 0.5 year*/
    proc sql noprint; create table tmpp_c as select "&exposure."   as drug length=12,0.5 as fu_year, count(id) as total_id, "No. at risk for &exposure initiator at 0.5 year" as label length=60 from &dataset where &timevar >=0.5 and &exposure=1; quit;
    proc sql noprint; create table tmpp_d as select "&comparator." as drug length=12,0.5 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 0.5 year" as label length=60 from &dataset where &timevar >=0.5 and &exposure=0; quit;
    /*No. of risk at 1 year*/
    proc sql noprint; create table tmpp_e as select "&exposure."   as drug length=12,1.0 as fu_year, count(id) as total_id, "No. at risk for &exposure initiator at 1 year" as label length=60 from &dataset where &timevar >=1 and &exposure=1; quit;
    proc sql noprint; create table tmpp_f as select "&comparator." as drug length=12,1.0 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 1 year" as label length=60 from &dataset where &timevar >=1 and &exposure=0; quit;
    /*No. of risk at 1.5 year*/
    proc sql noprint; create table tmpp_g as select "&exposure."   as drug length=12,1.5 as fu_year, count(id) as total_id, "No. at risk for &exposure initiator at 1.5 year" as label length=60 from &dataset where &timevar >=1.5 and &exposure=1; quit;
    proc sql noprint; create table tmpp_h as select "&comparator." as drug length=12,1.5 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 1.5 year" as label length=60 from &dataset where &timevar >=1.5 and &exposure=0; quit;
    /*No. of risk at 2 year*/
    proc sql noprint; create table tmpp_i as select "&exposure."   as drug length=12,2 as fu_year,   count(id) as total_id, "No. at risk for &exposure initiator at 2 year" as label length=60 from &dataset where &timevar >=2 and &exposure=1; quit;
    proc sql noprint; create table tmpp_j as select "&comparator." as drug length=12,2 as fu_year,   count(id) as total_id, "No. at risk for &comparator initiator at 2 year" as label length=60 from &dataset where &timevar >=2 and &exposure=0; quit;
    /*No. of risk at 2.5 year*/
    proc sql noprint; create table tmpp_k as select "&exposure."   as drug length=12,2.5 as fu_year, count(id) as total_id, "No. at risk for &exposure initiator at 2.5 year" as label length=60 from &dataset where &timevar >=2.5 and &exposure=1; quit;
    proc sql noprint; create table tmpp_l as select "&comparator." as drug length=12,2.5 as fu_year, count(id) as total_id, "No. at risk for &comparator initiator at 2.5 year" as label length=60 from &dataset where &timevar >=2.5 and &exposure=0; quit;
    /*No. of risk at 3 year*/
    proc sql noprint; create table tmpp_m as select "&exposure."   as drug length=12,3 as fu_year,   count(id) as total_id, "No. at risk for &exposure initiator at 3 year" as label length=60 from &dataset where &timevar >=3 and &exposure=1; quit;
    proc sql noprint; create table tmpp_n as select "&comparator." as drug length=12,3 as fu_year,   count(id) as total_id, "No. at risk for &comparator initiator at 3 year" as label length=60 from &dataset where &timevar >=3 and &exposure=0; quit;
title "IBD_ever/prevalent IBD"; 
proc means data =  dsn        
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 maxdec=2  ; 
where delete_flag1 eq 0;
class switcher_flag ibd_ever;  *important to use switcher_flag, not switcher variable;
var    time    event    ; 
run;
/* endregion //!SECTION */

title ""; 


%mend TVE_analysis;


%macro summarize(exposure, comparator);
/*Long version*/
/*ACNU*/
title "Summary output Long version &exposure. v &comparator.";
proc sql;
select * from summaryACNU_L_&exposure._&comparator.;
quit;
/*TVE*/
title "Summary output Long version &exposure. v &comparator.";
proc sql;
select * from summaryTVE_L_&exposure._&comparator.;
quit;
/*stack long versions*/
proc sql;
create table summary_L_&exposure._&comparator.
as select * from 
 summaryACNU_L_&exposure._&comparator.
union all corr
(select * from 
summaryTVE_L_&exposure._&comparator.);
quit;
/*Wide Versions*/
/*ACNU*/
title "Summary output Wide Version &exposure. v &comparator."; 
proc sql;
select * from summaryACNU_W_&exposure._&comparator.;
quit;
/*TVE*/
proc sql;
select * from summaryTVE_W_&exposure._&comparator.;
quit;
data summary_W_&exposure._&comparator.; retain analysis;
length status $20.;
set summaryACNU_W_&exposure._&comparator. summaryTVE_W_&exposure._&comparator.;
run;
/* Final print of both output */
title "Summary output Wide Version &exposure. v &comparator."; 
proc print data= summary_W_&exposure._&comparator.;
run;
title "Summary output Long Version &exposure. v &comparator."; 
proc print data=summary_L_&exposure._&comparator.; run; 

%mend summarize;
