/***************************************
SAS file name: 014_createanalysisdata.sas

Purpose: to create analysis datasets and track all exclusions made for each ACNU cohort
Author: JHW
Creation Date: 2024-01-07

    Program and output path:
        D:\Externe Projekte\UNC\wangje\sas
        D:\Externe Projekte\UNC\wangje\sas\prog
        libname temp D:\Externe Projekte\UNC\wangje\data\temp

    Input paths:
            original raw data:  D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16
            libname a  D:\Externe Projekte\UNC\wangje\data\analysis
            libname raw  D:\Externe Projekte\UNC\wangje\data\raw
            libname temp  D:\Externe Projekte\UNC\wangje\data\temp
Other details: CPRD-DPP4i project in collaboration with USB

CHANGES:
Date: see git 
Notes: 
***************************************/
dm 'autopop on; wsave;';  
/*dm 'next explorer; detail'; dm 'keydef F2 ''next explorer; refresh''';*/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");

%setup(programName=onerx, savelog=N, dataset=dataname);

%macro createana_acnu1RX(exposure=, comparatorlist=, save=Y);
%do i = 1 %to %sysfunc(countw(&comparatorlist));
%LET comparator = %scan(&comparatorlist, &i);
    /* Bring in counts and merged dataset */
    data tmp1; set temp.allmerged_&exposure._&comparator._1yrlb;RUN;
/*===================================*\
//SECTION - Getting counts for flowchart
\*===================================*/
/* region */
    /* getting counts  */
    data tmp_counts; 
        retain exclusion_num long_text dpp4i dpp4i_diff &comparator. &comparator._diff;
        set temp.excl_013_&exposure._&comparator._1yrlb;
        dpp4i_diff=dpp4i- lag(dpp4i);
    &comparator._diff= &comparator.- lag(&comparator.); RUN;
    proc print data=tmp_counts; run;
    proc sql noprint;
        select count(*) into :num_obs from tmp_counts;
        /* getting counts from each sequential exclusion */
        insert into tmp_counts 
        set exclusion_num= &num_obs+1 ,
        long_text="Initiators after exclusions a through d (non-mutually exclusive)", 
        dpp4i            =  (select count(*) from tmp1 where dpp4i=1 and not (excludeflag_prevalentuser=1 or excludeflag_samedayinitiator=1 /*or excludeflag_prefill2initiator=1 or filldate2=.*/)),
        &comparator.     =  (select count(*) from tmp1 where dpp4i=0 and not (excludeflag_prevalentuser=1 or excludeflag_samedayinitiator=1 )),
        dpp4i_diff       = -(select count(*) from tmp1 where dpp4i=1 and     (excludeflag_prevalentuser=1 or excludeflag_samedayinitiator=1 )),
        &comparator._diff= -(select count(*) from tmp1 where dpp4i=0 and     (excludeflag_prevalentuser=1 or excludeflag_samedayinitiator=1 ));
        /* were prevalent users of the comparator drug */
        insert into tmp_counts 
            set exclusion_num= &num_obs+2 ,
            long_text="a. Were prevalent users of &exposure. or &comparator. drug", 
            dpp4i_diff		 = (select count(*) from tmp1 where dpp4i=1 and excludeflag_prevalentuser=1),
            &comparator._diff= (select count(*) from tmp1 where dpp4i=0 and excludeflag_prevalentuser=1);
            /* initiated comparator drug on the same day */
            insert into tmp_counts 
                    set exclusion_num= &num_obs+3 ,
                        long_text="b. Dual initiator of &exposure. and &comparator.", 
                        dpp4i_diff		 = (select count(*) from tmp1 where dpp4i=1 and excludeflag_samedayinitiator=1),
                        &comparator._diff= (select count(*) from tmp1 where dpp4i=0 and excludeflag_samedayinitiator=1);
        /* filled comparator drug before second prescription */
        insert into tmp_counts 
        set exclusion_num= &num_obs+4 ,
        long_text="c. KEEP for 1 rx analysis (no more exclusion for Filled drug before second prescription)", 
                dpp4i_diff       = 0,
                &comparator._diff= 0;
                /* had no second prescription */
                insert into tmp_counts 
                set exclusion_num= &num_obs+5,
/*				change here for single prescripion criteria*/
                long_text="d. KEEP(no more exclusion for no respective second &exposure. or &comparator. prescription)", 
                dpp4i_diff       = 0,
                &comparator._diff=0;
                
                create table tmp2 as select * 
                		 from (select * from tmp1 where dpp4i=1 and not (excludeflag_prevalentuser=1 or excludeflag_samedayinitiator=1 /*or excludeflag_prefill2initiator=1 or filldate2=.*/)) as a 
                union all corr
                select * from (select * from tmp1 where dpp4i=0 and not (excludeflag_prevalentuser=1 or excludeflag_samedayinitiator=1 
/*or excludeflag_prefill2initiator=1 or filldate2=.*/)) as b; 
    quit;
    
    PROC SQL NOPRINT; 
        select count(*) into :num_obs from tmp_counts;
        
        * Had the following diagnosed diseases before the first prescription were excluded: (a-f non-mutually exclusive)) ;
        insert into tmp_counts 
        set exclusion_num= &num_obs+1 ,
        long_text="Had the diagnosed diseases before the first prescription (a-f non-mutually exclusive)",
        dpp4i	   		 =  (select count(*) from tmp2 where dpp4i=1 and not (ibd_i_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) or PCOS_bl not in (., 0) or DiabGest_bl not in (., 0))), 
        dpp4i_diff 		 = -(select count(*) from tmp2 where dpp4i=1 and 	 (ibd_i_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) or PCOS_bl not in (., 0) or DiabGest_bl not in (., 0))),
        &comparator		 =  (select count(*) from tmp2 where dpp4i=0 and not (ibd_i_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) or PCOS_bl not in (., 0) or DiabGest_bl not in (., 0))),
        &comparator._diff=- (select count(*) from tmp2 where dpp4i=0 and 	 (ibd_i_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) or PCOS_bl not in (., 0) or DiabGest_bl not in (., 0)));
        /*  a. Had Chron's, UC, or IBD disease */
        insert into tmp_counts 
        set exclusion_num= &num_obs+2 ,
        long_text="a. b. Had history of IBD", 
        dpp4i_diff       = (select count(*) from tmp2 where dpp4i=1 and ibd_I_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and ibd_I_bl not in (., 0));
        /*  c. had ischemic colitis */
        insert into tmp_counts 
        set exclusion_num= &num_obs+4 ,
        long_text="c. Had ischemic colitis", 
        dpp4i_diff		 = (select count(*) from tmp2 where dpp4i=1 and icomitis_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and icomitis_bl not in (., 0));
        /*  d. had diverticulitis or other colitis*/
        insert into tmp_counts 
        set exclusion_num= &num_obs+5 ,
        long_text="d. Had diverticulitis or other colitis", 
        dpp4i_diff		 = (select count(*) from tmp2 where dpp4i=1 and DivCol_P_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and DivCol_P_bl not in (., 0));        
        /* e. had PCOS or gestational diabetes */
        insert into tmp_counts
        set exclusion_num= &num_obs+6,
        long_text="e. Had polycystic ovary syndrome or gestational diabetes",   
        dpp4i_diff= (select count(*) from tmp2 where dpp4i=1 and (PCOS_bl not in (., 0) or DiabGest_bl not in (., 0))),
        &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and (PCOS_bl not in (., 0) or DiabGest_bl not in (., 0)));
    /* Excluding all the IBD history and pcos and diabgest in the exclusion table */
    create table tmp3 as select * 
    from (select * from tmp2 where dpp4i=1 and not (ibd_i_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) or PCOS_bl not in (. , 0) or DiabGest_bl not in (., 0))) as a
    union all corr
    select * 
    from (select * from tmp2 where dpp4i=0 and not (ibd_i_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) or PCOS_bl not in (. , 0) or DiabGest_bl not in (., 0))) as b;
    QUIT;
    proc print data= tmp_counts  ;  
run; 
    PROC SQL  NOPRINT; 
        select count(*) into :num_obs from tmp_counts;
        /* Initiators received treatment for IBD before the first prescription were excluded */
        insert into tmp_counts 
        set exclusion_num= &num_obs+1 ,
        long_text="Received treatment for IBD before the first prescription were excluded",
        dpp4i= (select count(*) from tmp3 where dpp4i=1 and not (AminoS_bl not in (., 0) or budeo_bl not in (., 0) or tnfai_bl not in (., 0) or otherimm_bl not in (., 0) )), 
        dpp4i_diff= -(select count(*) from tmp3 where dpp4i=1 and (AminoS_bl not in (., 0) or budeo_bl not in (., 0) or tnfai_bl not in (., 0) or otherimm_bl not in (., 0) )),
        &comparator= (select count(*) from tmp3 where dpp4i=0 and not (AminoS_bl not in (., 0) or budeo_bl not in (., 0) or tnfai_bl not in (., 0) or otherimm_bl not in (., 0) )),
        &comparator._diff= -(select count(*) from tmp3 where dpp4i=0 and (AminoS_bl not in (., 0) or budeo_bl not in (., 0) or tnfai_bl not in (., 0) or otherimm_bl not in (., 0)));
        /* a. had aminosalicylates */
        insert into tmp_counts 
        set exclusion_num= &num_obs+2 ,
        long_text="a. had aminosalicylates", 
        dpp4i_diff= (select count(*) from tmp3 where dpp4i=1 and AminoS_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp3 where dpp4i=0 and AminoS_bl not in (., 0));
        /* b. had enteral budesonide */
        insert into tmp_counts 
        set exclusion_num= &num_obs+3 ,
        long_text="b. had enteral budesonide", 
        dpp4i_diff= (select count(*) from tmp3 where dpp4i=1 and budeo_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp3 where dpp4i=0 and budeo_bl not in (., 0));
        /* c. had IBD treatment-specific TNF-alpha inhibitors */
        insert into tmp_counts 
        set exclusion_num= &num_obs+4 ,
        long_text="c. had IBD treatment-specific TNF-alpha inhibitors", 
        dpp4i_diff= (select count(*) from tmp3 where dpp4i=1 and tnfai_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp3 where dpp4i=0 and tnfai_bl not in (., 0));
        /* d. had other immunosuppressants (azathioprine, 6-mercaptopurine, methotrexate) */
        insert into tmp_counts 
        set exclusion_num= &num_obs+5 ,
        long_text="d. had other immunosuppressants (azathioprine, 6-mercaptopurine, methotrexate)", 
        dpp4i_diff= (select count(*) from tmp3 where dpp4i=1 and otherimm_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp3 where dpp4i=0 and otherimm_bl not in (., 0));
        create table tmp4 as select * 
        from (select * from tmp3 where dpp4i=1 and not (AminoS_bl not in (., 0) or budeo_bl not in (., 0) or tnfai_bl not in (., 0) or otherimm_bl not in (., 0) )) as a
        union all corr
        select * 
        from (select * from tmp3 where dpp4i=0 and not (AminoS_bl not in (., 0) or budeo_bl not in (., 0) or tnfai_bl not in (., 0) or otherimm_bl not in (., 0) )) as b;

    QUIT;
    
    PROC SQL NOPRINT; 
        select count(*) into :num_obs from tmp_counts;
        /* Initiators with the following procedures before the first prescription were excluded  */
        /* a. had colectomy, colostomy, or ileostomy */
        insert into tmp_counts 
        set exclusion_num= &num_obs+1 ,
        long_text="Initiators with colectomy, colostomy, or ileostomy before the first prescription were excluded",
        dpp4i			 =  (select count(*) from tmp4 where dpp4i=1 and not (colile_bl not in (., 0) )), 
        dpp4i_diff		 = -(select count(*) from tmp4 where dpp4i=1 and (colile_bl not in (., 0) )),
        &comparator		 =  (select count(*) from tmp4 where dpp4i=0 and not (colile_bl not in (., 0) )),
        &comparator._diff= -(select count(*) from tmp4 where dpp4i=0 and (colile_bl not in (., 0) ));
        create table tmp5 as select *
        from (select * from tmp4 where dpp4i=1 and not (colile_bl not in (., 0) )) as a
        union all corr  
        select *
        from (select * from tmp4 where dpp4i=0 and not (colile_bl not in (., 0) )) as b;
    QUIT;
    %if &comparator eq sglt2i %then %do; 
        PROC SQL NOPRINT; 
            select count(*) into :num_obs from tmp_counts;
            /* If the comparator is sglt2i then all iniators before 2012 are excluded */
            insert into tmp_counts
            set exclusion_num= &num_obs+1 ,
            long_text="Initiators before 2012 were excluded",
            dpp4i			 =  (select count(*) from tmp5 where dpp4i=1 and year(indexdate) not lt 2012),
            dpp4i_diff		 = -(select count(*) from tmp5 where dpp4i=1 and year(indexdate) lt 2012),
            &comparator		 =  (select count(*) from tmp5 where dpp4i=0 and year(indexdate) not lt 2012),
            &comparator._diff= -(select count(*) from tmp5 where dpp4i=0 and year(indexdate) lt 2012);
            create table tmp5 as select *
            from (select * from tmp4 where dpp4i=1 and year(indexdate) ge 2012) as a
            union all corr
            select *
            from (select * from tmp4 where dpp4i=0 and year(indexdate) ge 2012) as b;
        QUIT;
    %end;
    /* exclude heart failure for tzd */
    %if &comparator eq tzd  %then %do;
        PROC SQL NOPRINT; 
            select count(*) into :num_obs from tmp_counts;
            /* If the comparator is dpp4i then all initiators with history of CHF are excluded */
            insert into tmp_counts
            set exclusion_num= &num_obs+1 ,
            long_text="Initiators with history of CHF were excluded",
            dpp4i			 =  (select count(*) from tmp5 where dpp4i=1 and not (chf_bl not in (., 0))),
            dpp4i_diff		 = -(select count(*) from tmp5 where dpp4i=1 and 	  chf_bl not in (., 0)),
            &comparator		 =  (select count(*) from tmp5 where dpp4i=0 and not (chf_bl not in (., 0))),
            &comparator._diff= -(select count(*) from tmp5 where dpp4i=0 and 	  chf_bl not in (., 0));
            create table tmp6 as select *
            from (select * from tmp5 where dpp4i=1 and chf_bl  in (., 0)) as a
            union all corr
            select *
            from (select * from tmp5 where dpp4i=0 and chf_bl  in (., 0)) as b;
        QUIT;
    %end;  
    data tmp_counts;
        set tmp_counts;
        if full eq . then do;
        full=dpp4i+&comparator.;
        end;
        RUN;
		proc print ; run; 


/* endregion //!SECTION */
/*===================================*\
//SECTION - Making cuts to the analysis data set
\*===================================*/
/* region */
/* retrive from temp library and make exclusions */

data tmpana_&exposure._&comparator.;
    set tmp1;
/*remove filldate2 condition*/
    if (excludeflag_prevalentuser eq 1 or excludeflag_samedayinitiator eq 1 /*or excludeflag_prefill2initiator eq 1 or filldate2 eq .*/ ) then delete; 
    if ((ibd_i_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) )) then delete;
    if ((AminoS_bl not in (., 0) or budeo_bl not in (., 0) or tnfai_bl not in (., 0) or otherimm_bl not in (., 0) )) or (colile_bl not in (., 0) ) then delete;
    /* delete PCOS and Diagbetes, 8/10/2024 Tian added  */
    if (PCOS_bl not in (., 0) or DiabGest_bl not in (., 0)) then delete;
	/* exclude prior to 2012 for sglt2i */
    %if &comparator eq sglt2i %then %do; 
    if year(indexdate) lt 2012 then delete; 
    %end;
    /* exclude heart failure for tzd */
    %if &comparator eq tzd  %then %do;
    if chf_bl not in (., 0) then delete;
    %end;  
RUN;
/* Check that the exclusion numbers match  */
proc sql NOPRINT;
    insert into tmp_counts set
    long_text="Check: numrows of tmpana_&exposure._&comparator. = numrows of tmp_counts",
    full= (select count(*) from tmpana_&exposure._&comparator.);
    quit;
proc print data=tmp_counts; run;
/* endregion //!SECTION */  


/* if save==y then save to analysis folder */
    %if &save=Y %then %do;
    data a.allmerged1RX_&exposure._&comparator._1yrlb;
        set  tmpana_&exposure._&comparator.;
        RUN;

    data temp.excl_1RX_&exposure._&comparator._1yrlb;
        set tmp_counts;
        RUN;

		    %end;

%end;
%mend createana_acnu1rx;

%LET exposure = dpp4i;
%LET comparatorlist = tzd su sglt2i;
%createana_acnu1RX(exposure=&exposure, comparatorlist=&comparatorlist, save=Y);

proc print data= temp.excl_1RX_dpp4i_su_1yrlb;
proc print data= temp.excl_1RX_dpp4i_tzd_1yrlb;
proc print data= temp.excl_1RX_dpp4i_sglt2i_1yrlb;
run; 

/*===================================*\
Then create TVE analysis dataset with 1RX
\*===================================*/


/*===================================*\
//SECTION - ## 4. creating analysis dataset a la Abrahami, adapted from 014_createanalysis.sas
\*===================================*/
/* region */

%macro createana_Ab_1RX(exposure=, comparatorlist=, save=N);
%do i = 1 %to %sysfunc(countw(&comparatorlist));
%LET comparator = %scan(&comparatorlist, &i);
    /* loading in the Abrahami merged dataset */
data tmp1; /*7/17/2024: 13 patients in swithers but not in censored had 26 rows*/
	set temp.Abrahami_allmerged_&exposure._&comparator.;
        if (&exposure eq 1 and 
			excludeflag_prevalentuser /*the latest flag modified in %macro meargeall_ab above*/eq 1) 
			then keepflag_prevalentuser=1;
        IBD_ever= max(ibd_i_ever, crohns_ever, ucolitis_ever);  
        label IBD_ever="Ever IBD diagnosis";
        RUN;
	/*proc freq data=tmp1; tables ibd_ever/missing;run;*/
    /* Flagging and identifying switcher through temp datasets */
PROC SQL;
    create table overlap_&exposure._&comparator. as
    select distinct a.id, 
            b.indexdate as &comparator._index,
            a.indexdate as &exposure._index , 
            a.&exposure._ever   as &exposure.initiator_&exposure._ever,
            a.&comparator._ever as &exposure.initiator_&comparator._ever,

            b.&exposure._ever   as &comparator.initiator_&exposure._ever,
            b.&comparator._ever as &comparator.initiator_&comparator._ever,

            a.&exposure._bl     as &exposure.initiator_&exposure._bl,
            a.&comparator._bl   as &exposure.initiator_&comparator._bl,

            b.&exposure._bl     as &comparator.initiator_&exposure._bl,
            b.&comparator._bl   as &comparator.initiator_&comparator._bl, 

            a.ibd_I_bl  as &exposure.initiator_ibd_I_bl,
            a.crohns_bl   as &exposure.initiator_crohns_bl,
            a.ucolitis_bl as &exposure.initiator_ucolitis_bl,

            b.ibd_I_bl  as &comparator.initiator_ibd_I_bl, 
            b.crohns_bl   as &comparator.initiator_crohns_bl, 
            b.ucolitis_bl as &comparator.initiator_ucolitis_bl, 

            b.icomitis_bl as &comparator.initiator_icomitis_bl,
            b.DivCol_P_bl as &comparator.initiator_DivCol_P_bl,
            b.AminoS_bl   as &comparator.initiator_AminoS_bl,
            b.budeo_bl    as &comparator.initiator_budeo_bl,
            b.tnfai_bl    as &comparator.initiator_tnfai_bl,
            b.otherimm_bl as &comparator.initiator_otherimm_bl,
            b.colile_bl   as &comparator.initiator_colile_bl, 
            /* PCOS and gestational diabetes, 8/8/2024 Jeanny added */
            b.PCOS_bl as &comparator.initiator_PCOS_bl, 
            b.DiabGest_bl as &comparator.initiator_DiabGest_bl 
        from tmp1 (where=(&exposure eq 1)) as a 
        inner join tmp1 (where=(&exposure eq 0)) as b
        on a.id=b.id;
    /* Flagging ids of documented SU-->DPP4i switch */
    create table dpp4i_initiator_pu as 
	select distinct id as id_pu,    
		    1 as keepflag_prevalentuser,
		    &exposure.initiator_ibd_I_bl,
		    &exposure.initiator_crohns_bl,
		    &exposure.initiator_ucolitis_bl,

		    &comparator.initiator_ibd_I_bl, 
		    &comparator.initiator_crohns_bl, 
		    &comparator.initiator_ucolitis_bl,
		 
		    &comparator.initiator_icomitis_bl,
		    &comparator.initiator_DivCol_P_bl,
		    &comparator.initiator_AminoS_bl,
		    &comparator.initiator_budeo_bl,
		    &comparator.initiator_tnfai_bl,
		    &comparator.initiator_otherimm_bl,
		    &comparator.initiator_colile_bl, 

            /*  PCOS and gestational diabetes, 8/8/2024 Jeanny added  */
            &comparator.initiator_PCOS_bl,
            &comparator.initiator_DiabGest_bl
    from overlap_&exposure._&comparator. where (&comparator._index le &exposure._index);
    /* Creating a portion of the tmp1 to stack onto tmpana_&exposure._&comparator. */
    create table dpp4i_initiator_pu2 as 
	select b.*, 
		    a.keepflag_prevalentuser,
		    a.&exposure.initiator_ibd_I_bl,
		    a.&exposure.initiator_crohns_bl,
		    a.&exposure.initiator_ucolitis_bl,

		    a.&comparator.initiator_ibd_I_bl, 
		    a.&comparator.initiator_crohns_bl, 
		    a.&comparator.initiator_ucolitis_bl,
		 
		    a.&comparator.initiator_icomitis_bl,
		    a.&comparator.initiator_DivCol_P_bl,
		    a.&comparator.initiator_AminoS_bl,
		    a.&comparator.initiator_budeo_bl,
		    a.&comparator.initiator_tnfai_bl,
		    a.&comparator.initiator_otherimm_bl,
		    a.&comparator.initiator_colile_bl
        from dpp4i_initiator_pu as a 
        inner join 
        tmp1 (where=(keepflag_prevalentuser eq 1)) as b 
        on a.id_pu=b.id;
    QUIT;
    /* 2024-12-27: JW- will adding this identify the comparator switchers? */
    PROC SQL;
        create table dpp4i_switcherids as select distinct
        id, 
        1 as switcher_id,
        from dpp4i_initiator_pu2;
    QUIT;
    data tmp1;
        merge tmp1 (in=a) dpp4i_switcherids (in=b);
        by id;
        RUN;
    /* end 2024-12-27 edits */

title "overlap_&exposure._&comparator.";
proc print data=overlap_&exposure._&comparator. (obs=1);run;title;
title "dpp4i_initiator_pu";proc print data=dpp4i_initiator_pu (obs=1);run;title;
title "dpp4i_initiator_pu2";proc print data=dpp4i_initiator_pu2 (obs=1);run;title;
/*delete observationa according to exclusion critiera*/
    data tmpana_&exposure._&comparator.;
        set tmp1 (where= (excludeflag_prevalentuser ne 1))
        dpp4i_initiator_pu2 (in=a);
        if a then keepflag_prevalentuser=1; else keepflag_prevalentuser=0;
        if (/* excludeflag_prevalentuser eq 1 or */ excludeflag_samedayinitiator  eq 1/* or excludeflag_prefill2initiator eq 1 or filldate2 eq . */) then delete; 
        /* Tailoring the Main analysis exclusion criteria to mimic Abrahami's time-varying treatment and outcome design, where prevalent users were included for dpp4i but not for the comparator */
        if keepflag_prevalentuser ne 1 then do; 
            if ((ibd_I_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) )) then delete;    
            if ((AminoS_bl not in (., 0) or budeo_bl not in (., 0) or tnfai_bl not in (., 0) or otherimm_bl not in (., 0) )) or (colile_bl not in (., 0) ) then delete;
            END;
        /* Excluding only prevalent users whose IBD hx was during the comparator use history */
        else if (keepflag_prevalentuser eq 1) then do;
            if ((
            &comparator.initiator_IBD_I_bl not in (., 0) or 
            &comparator.initiator_icomitis_bl not in (., 0) or 
            &comparator.initiator_DivCol_P_bl not in (., 0) )) then delete;    
            if ((&comparator.initiator_AminoS_bl not in (., 0) or 
            &comparator.initiator_budeo_bl    not in (., 0) or
            &comparator.initiator_tnfai_bl not in    (., 0) or 
            &comparator.initiator_otherimm_bl not in (., 0) )) or (&comparator.initiator_colile_bl not in (., 0) ) then delete;
            END;
        /* delete PCOS and Diagbetes Jeanny & Tian added 8/8/2024 */
        if (PCOS_bl not in (., 0) or DiabGest_bl not in (., 0)) then delete;
			/* exclude prior to 2012 for sglt2i */
        %if &comparator eq sglt2i %then %do; 
        if year(indexdate) lt 2012 then delete; 
        %end;
        /* exclude heart failure for tzd */
        %if &comparator eq tzd  %then %do;
        if chf_bl not in (., 0) then delete;
        %end;  
    RUN; 
/*******************************/
/* adding counts for flowchart */
/*******************************/
	data tmp_counts; 
        retain exclusion_num long_text dpp4i dpp4i_diff &comparator. &comparator._diff;
        set temp.Abexclusions_012_&exposure._&comparator.;
        dpp4i_diff      =  dpp4i       - lag(dpp4i);
        &comparator._diff= &comparator.- lag(&comparator.); 
	RUN;
title "tmp_counts"; proc print data=tmp_counts;run;title;
title "temp.Abexclusions_012_&exposure._&comparator."; proc print data=temp.Abexclusions_012_&exposure._&comparator.;run;title;

    PROC SQL noprint; 
        select count(*) into :num_obs from tmp_counts;
        /* getting counts from each sequential exclusion */
        insert into tmp_counts 
        set exclusion_num= &num_obs+1 ,
            long_text="Initiators after exclusions a through d (non-mutually exclusive)", 
            dpp4i=              (select count(*) from tmp1 where dpp4i=1 and not (excludeflag_prevalentuser eq 1 or excludeflag_samedayinitiator=1 /*or excludeflag_prefill2initiator=1 or filldate2=.*/)),
            &comparator.=       (select count(*) from tmp1 where dpp4i=0 and not (excludeflag_prevalentuser eq 1 or excludeflag_samedayinitiator=1 /*or excludeflag_prefill2initiator=1 or filldate2=.*/)),
            dpp4i_diff=        -(select count(*) from tmp1 where dpp4i=1 and     (excludeflag_prevalentuser eq 1 or excludeflag_samedayinitiator=1 /*or excludeflag_prefill2initiator=1 or filldate2=.*/)),
            &comparator._diff= -(select count(*) from tmp1 where dpp4i=0 and     (excludeflag_prevalentuser eq 1 or excludeflag_samedayinitiator=1 /*or excludeflag_prefill2initiator=1 or filldate2=.*/));
        /* Were prevalent users of the comparator drug */
        insert into tmp_counts 
            set exclusion_num= &num_obs + 2 ,
            long_text = "a. Were prevalent users of &exposure. or &comparator. drug", 
            dpp4i_diff       = -(select count(*) from tmp1 where dpp4i=1 and excludeflag_prevalentuser=1),
            &comparator._diff= -(select count(*) from tmp1 where dpp4i=0 and excludeflag_prevalentuser=1);
        /* initiated comparator drug on the same day */
        insert into tmp_counts 
        set exclusion_num= &num_obs+3 ,
            long_text="b. Dual initiator of &exposure. and &comparator.", 
            dpp4i_diff       = -(select count(*) from tmp1 where dpp4i=1 and excludeflag_samedayinitiator=1),
            &comparator._diff= -(select count(*) from tmp1 where dpp4i=0 and excludeflag_samedayinitiator=1);
        /* filled comparator drug before second prescription */
        insert into tmp_counts 
        set exclusion_num= &num_obs+4 ,
            long_text="c.KEEP FOR 1RX analysis (Filled drug before second prescription)", 
            dpp4i_diff=        0,
            &comparator._diff= 0;
        /* had no second prescription */
        insert into tmp_counts 
        set exclusion_num= &num_obs+5,
            long_text="d. KEEP FOR 1RX analysis (Had no respective second &exposure. or &comparator. prescription)" , 
            dpp4i_diff=    0,
            &comparator._diff= 0;
    quit;
title "tmp_counts"; proc print data=tmp_counts;run;title;

    data tmp2;
        set tmp1 (where= (excludeflag_prevalentuser ne 1))

        dpp4i_initiator_pu2 (in=a);
        if a then keepflag_prevalentuser=1; else keepflag_prevalentuser=0;
        if (/* excludeflag_prevalentuser eq 1 or */ excludeflag_samedayinitiator  eq 1 /*or excludeflag_prefill2initiator eq 1 or filldate2 eq .*/ ) then delete; 
        if keepflag_prevalentuser ne 1 then do; 
            if ((ibd_I_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) )) then delete_IBD=1;    
            if ((AminoS_bl not in (., 0) or budeo_bl    not in (., 0) or tnfai_bl    not in (., 0) or otherimm_bl not in (., 0) )) then delete_ibdmeds=1;
            END;
           else if (keepflag_prevalentuser eq 1) then do;
                if ((&comparator.initiator_ibd_I_bl not in (., 0) or &comparator.initiator_icomitis_bl not in (., 0) or &comparator.initiator_DivCol_P_bl not in (., 0) )) then delete_IBD=1;    
                if ((&comparator.initiator_AminoS_bl not in (., 0) or &comparator.initiator_budeo_bl    not in (., 0) or &comparator.initiator_tnfai_bl    not in (., 0) or &comparator.initiator_otherimm_bl not in (., 0) )) or (&comparator.initiator_colile_bl not in (., 0) ) then delete_ibdmeds=1;
            END;
     RUN;

    PROC SQL NOPRINT; 
        select count(*) into :num_obs from tmp_counts;        
        * Had the following diagnosed diseases before the first prescription were excluded: (a-f non-mutually exclusive)) ;
        insert into tmp_counts 
        set exclusion_num= &num_obs+1 ,
        long_text="* Adding back DPP4i initiators who were prevalent users of comparator drug",
        dpp4i=   (select count(*) from tmp1 where dpp4i=1 and not (excludeflag_prevalentuser eq 1 or excludeflag_samedayinitiator=1 /*or excludeflag_prefill2initiator=1 or filldate2=.*/)) + (select count(*) from tmp2 where dpp4i=1 and keepflag_prevalentuser=1),
        dpp4i_diff       = (select count(*) from tmp2 where dpp4i=1 and keepflag_prevalentuser=1),
        &comparator      = (select count(*) from tmp1 where dpp4i=0 and not (excludeflag_prevalentuser eq 1 or excludeflag_samedayinitiator=1/* or excludeflag_prefill2initiator=1 or filldate2=.*/)),
        &comparator._diff=0;
        insert into tmp_counts 
        set exclusion_num= &num_obs+2 ,
        long_text="Had the diagnosed diseases before the first prescription (a-f non-mutually exclusive)",
        dpp4i            = (select count (*) from tmp2 where dpp4i =1 and not (delete_IBD eq 1 or (PCOS_bl not in (.,0) or DiabGest_bl not in (., 0)))) , 
        dpp4i_diff       =-(select count(*) from tmp2 where dpp4i=1 and (delete_IBD eq 1 or (PCOS_bl not in (.,0) or DiabGest_bl not in (., 0))))  ,
        &comparator      = (select count (*) from tmp2 where dpp4i =0 and not (delete_IBD eq 1 or (PCOS_bl not in (.,0) or DiabGest_bl not in (., 0)))) ,
        &comparator._diff=-(select count(*) from tmp2 where dpp4i=0 and (delete_IBD eq 1 or (PCOS_bl not in (.,0) or DiabGest_bl not in (., 0)))) ;
        /*  a. Had any IBD diagnosis */
        insert into tmp_counts 
        set exclusion_num= &num_obs+3 ,
        long_text="a. b. Had prevalent IBD diagnosis", 
        dpp4i_diff       = -(select count(*) from tmp2 where dpp4i=1 and delete_IBD eq 1 and IBD_I_bl not in (., 0)),
        &comparator._diff= -(select count(*) from tmp2 where dpp4i=0 and delete_IBD eq 1 and IBD_I_bl not in (., 0));
        /*  c. had ischemic colitis */
        insert into tmp_counts 
        set exclusion_num= &num_obs+5 ,
                long_text="c. Had ischemic colitis", 
                dpp4i_diff= -(select count(*) from tmp2 where dpp4i=1 and delete_IBD eq 1 and icomitis_bl not in (., 0)),
         &comparator._diff= -(select count(*) from tmp2 where dpp4i=0 and delete_IBD eq 1 and icomitis_bl not in (., 0));
        /*  d. had diverticulitis or other colitis*/
        insert into tmp_counts 
            set exclusion_num= &num_obs+6 ,
            long_text="d. Had diverticulitis or other colitis", 
               dpp4i_diff= -(select count(*) from tmp2 where dpp4i=1 and delete_IBD eq 1 and DivCol_P_bl not in (., 0)),
        &comparator._diff= -(select count(*) from tmp2 where dpp4i=0 and delete_IBD eq 1 and DivCol_P_bl not in (., 0));   
        /* e. had PCOS or gestational diabetes (at anytime, regardless of switcher status), 8/8/2024 Jeanny added*/
        insert into tmp_counts 
            set exclusion_num= &num_obs+7 ,
            long_text="e. Had PCOS or gestational diabetes", 
            dpp4i_diff= -(select count(*) from tmp2 where dpp4i=1 and (PCOS_bl not in (., 0) or DiabGest_bl not in (., 0))),
            &comparator._diff= -(select count(*) from tmp2 where dpp4i=0 and (PCOS_bl not in (., 0) or DiabGest_bl not in (., 0)));
    QUIT;

title "tmp_counts"; proc print data=tmp_counts;run;title;

data tmp2; set tmp2; where delete_IBD ne 1;RUN;
/* Further excluding any PCOS or Gestational Diabetes, 8/8/2024, Jeanny added */
data tmp2; set tmp2; if PCOS_bl in (., 0) and DiabGest_bl in (., 0);RUN;
/*proc sql; select count(*) as row_count from tmp2;run;/*7/7/2024 latest results: before deleting 123137, after deleting 121163*/

    PROC SQL  NOPRINT; 
        select count(*) into :num_obs from tmp_counts;
        /* Initiators received treatment for IBD before the first prescription were excluded */
        insert into tmp_counts 
        set exclusion_num= &num_obs+1 ,
        long_text="Received treatment for IBD before the first prescription were excluded",
        dpp4i            =  (select count(*) from tmp2 where dpp4i=1 and delete_ibdmeds ne 1), 
        dpp4i_diff       = -(select count(*) from tmp2 where dpp4i=1 and delete_ibdmeds eq 1),
        &comparator      =  (select count(*) from tmp2 where dpp4i=0 and delete_ibdmeds ne 1),
        &comparator._diff= -(select count(*) from tmp2 where dpp4i=0 and delete_ibdmeds eq 1);
        /* a. had aminosalicylates */
        insert into tmp_counts 
        set exclusion_num= &num_obs+2 ,
        long_text="a. had aminosalicylates", 
        dpp4i_diff       = (select count(*) from tmp2 where dpp4i=1 and delete_ibdmeds eq 1 and AminoS_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and delete_ibdmeds eq 1 and AminoS_bl not in (., 0));
        /* b. had enteral budesonide */
        insert into tmp_counts 
        set exclusion_num= &num_obs+3 ,
        long_text        ="b. had enteral budesonide", 
        dpp4i_diff       = (select count(*) from tmp2 where dpp4i=1 and delete_ibdmeds eq 1 and budeo_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and delete_ibdmeds eq 1 and budeo_bl not in (., 0));
        /* c. had IBD treatment-specific TNF-alpha inhibitors */
        insert into tmp_counts 
        set exclusion_num= &num_obs+4 ,
        long_text="c. had IBD treatment-specific TNF-alpha inhibitors", 
        dpp4i_diff       = (select count(*) from tmp2 where dpp4i=1 and delete_ibdmeds eq 1 and tnfai_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and delete_ibdmeds eq 1 and tnfai_bl not in (., 0));
        /* d. had other immunosuppressants (azathioprine, 6-mercaptopurine, methotrexate) */
        insert into tmp_counts 
        set exclusion_num= &num_obs+5 ,
        long_text="d. had other immunosuppressants (azathioprine, 6-mercaptopurine, methotrexate)", 
        dpp4i_diff       = (select count(*) from tmp2 where dpp4i=1 and delete_ibdmeds eq 1 and otherimm_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and delete_ibdmeds eq 1 and otherimm_bl not in (., 0));
    QUIT;
title "tmp_counts"; proc print data=tmp_counts;run;title;

data tmp2; set tmp2; where delete_IBDmeds ne 1;
        if  keepflag_prevalentuser ne 1 then do; if (colile_bl not in (., 0) )    then delete_colile=1;
   else if (keepflag_prevalentuser eq 1 and &comparator.initiator_colile_bl eq 1) then delete_colile=1;
        end;         
        RUN;

    PROC SQL NOPRINT; 
        select count(*) into :num_obs from tmp_counts;
        /* Initiators with the following procedures before the first prescription were excluded  */
        /* a. had colectomy, colostomy, or ileostomy */
        insert into tmp_counts 
        set exclusion_num= &num_obs+1 ,
        long_text="Initiators with colectomy, colostomy, or ileostomy before the first prescription were excluded",
        dpp4i            =  (select count(*) from tmp2 where dpp4i=1 and delete_colile ne 1), 
        dpp4i_diff       = -(select count(*) from tmp2 where dpp4i=1 and delete_colile eq 1),
        &comparator      =  (select count(*) from tmp2 where dpp4i=0 and delete_colile ne 1),
        &comparator._diff= -(select count(*) from tmp2 where dpp4i=0 and delete_colile eq 1);
    QUIT;

data tmp3; set tmp2; where  delete_colile ne 1; RUN;
title "tmp_counts";proc print data=tmp_counts;run;title;


    %if &comparator eq sglt2i %then %do; 
            PROC SQL NOPRINT; 
            select count(*) into :num_obs from tmp_counts;
            /* If the comparator is sglt2i then all iniators before 2012 are excluded */
            insert into tmp_counts
            set exclusion_num= &num_obs+1 ,
            long_text="Initiators before 2012 were excluded",
            dpp4i            =  (select count(*) from tmp3 where dpp4i=1 and year(indexdate) not lt 2012),
            dpp4i_diff       = -(select count(*) from tmp3 where dpp4i=1 and year(indexdate)     lt 2012),
            &comparator      =  (select count(*) from tmp3 where dpp4i=0 and year(indexdate) not lt 2012),
            &comparator._diff= -(select count(*) from tmp3 where dpp4i=0 and year(indexdate)     lt 2012);
        QUIT;
    %end;
    /* exclude heart failure for tzd */
    %if &comparator eq tzd  %then %do;
        PROC SQL NOPRINT; 
            select count(*) into :num_obs from tmp_counts;
            /* If the comparator is dpp4i then all initiators with history of CHF are excluded */
            insert into tmp_counts
            set exclusion_num= &num_obs+1 ,
            long_text="Initiators with history of CHF were excluded",
            dpp4i            =  (select count(*) from tmp3 where dpp4i=1 and not (chf_bl not in (., 0))),
            dpp4i_diff       = -(select count(*) from tmp3 where dpp4i=1 and      chf_bl not in (., 0)),
            &comparator      =  (select count(*) from tmp3 where dpp4i=0 and not (chf_bl not in (., 0))),
            &comparator._diff= -(select count(*) from tmp3 where dpp4i=0 and      chf_bl not in (., 0));
        QUIT;
    %end;  

    /* Check that the exclusion numbers match  */
    proc sql NOPRINT;
        insert into tmp_counts set
        long_text="Check: numrows of tmpana_&exposure._&comparator. = numrows of tmp_counts",
        full= (select count(*) from tmpana_&exposure._&comparator./*not tmp3? *JW- tmp3 was a temporary dataset only for counting exclusions per step*/);
        quit;
    title "tmp_counts"; proc print data=tmp_counts; run; title;

    /* add a column of totals for full */
    data tmp_counts;
        set tmp_counts;
        if full eq . then do;
        full=dpp4i+&comparator.;
        end;
        RUN; 
    title "tmp_counts"; proc print data=tmp_counts; run; title;
 
    /* if save==y then save to analysis folder */
    /* 2024-12-21: JW add : Make the exclusions on tmp3 before saving the dataset in line 815 */
    data tmp3; set tmp3;   
        /* exclude prior to 2012 for sglt2i */    
        %if &comparator eq sglt2i %then %do; 
        if year(indexdate) lt 2012 then delete; 
        %end;
        /* exclude heart failure for tzd */
        %if &comparator eq tzd  %then %do;
        if chf_bl not in (., 0) then delete;
        %end;  
    RUN; /* end add */ 

    %if &save=Y %then %do;
    data a.Ab_allmerged1RX_&exposure._&comparator.;
        set  /*tmpana_&exposure._&comparator. 8/8/2024 Tian replaced this by tmp3 */ tmp3;
        RUN;
    data temp.Abexclusions_1RX_&exposure._&comparator.;
        set tmp_counts;
        RUN;
    %end;

%end;
%mend createana_Ab_1rx;

%LET exposure = dpp4i;
%LET comparatorlist = su tzd sglt2i;
%createana_Ab_1rx(exposure=&exposure, comparatorlist=&comparatorlist, save=Y);

proc print data= temp.Abexclusions_1RX_dpp4i_su ;  
proc print data= temp.Abexclusions_1RX_dpp4i_tzd ;  
proc print data= temp.Abexclusions_1RX_dpp4i_sglt2i ;  
run; 