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
options nosymbolgen nomlogic nomprint mcompile mcompilenote=all; option MAUTOSOURCE;
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



/*===================================*\
ACNU PSWEIGHTING using the 1rx group 
\*===================================*/

%macro psweighting_1RXac ( exposure , comparator , weight , addedmodelvars ,basemodelvars , tablerowvars, refyear  , dat, save, ana_name);

    data tmp1;
        set a.allmerged1RX_&exposure._&comparator._1yrlb;
        /* 2024-12-19: JHW add- Created new variable here that is time between first and second prescription */
        diff_1st_2ndrx= filldate2-indexdate; *check that it should be a positive number;
    RUN;

	/*=================*\
    Table 1 untrimmed (appendix) - added 6/5/2024, 7/25/2024 Tian blocked this without weighted Table 1 and added untrimmed weighted Table 1 later
    \*=================*/
   /* proc format; value &exposure. 0="&comparator." 1="&exposure."; run;
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
    ods rtf file="&toutPath./ACNU_Table1_Untrimmed_&exposure._&comparator._&todaysdate..rtf";
    proc print data=tab1_untrimmed_&comparator. noobs label; var row &exposure &comparator sdiff; run;
    ods rtf close;*/



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
 ods pdf file="&foutpath.\psplot_ACNU_untrimmed_&ana_name.s_&exposure._&comparator._&todaysdate..pdf";
    symbol1 interpol=spline value=none line=1;
    symbol2 interpol=spline value=none line=2;
    axis1 order=(0 to 1 by 0.1) minor=none label=(a=0 j=c h=1.5 f=swiss 'Propensity Score') value=(h=1.1 f=swiss);
    axis2 minor=(n=1) label=(a=90 j=c h=1.5 f=swiss 'Density') value=(h=1.1 f=swiss);
    title "Untrimmed PS distribution for &exposure. use, by treatment status";
    proc gplot data=psplot;
        plot density*value=pop / haxis=axis1 vaxis=axis2;
        run; quit;
        title;
 ods pdf close;
	/*=================*\
    Table 1 untrimmed 7/25/2024 Tian added Table 1 untrimmed weighted Table 1.
    \*=================*/
    proc format; value &exposure. 0="&comparator." 1="&exposure."; run;
    proc datasets lib=work nolist nodetails; modify psdsnnotrim; 
        format &exposure. &exposure..  sex $sexf.  alcohol_cat $statusf. smoke_cat $statusf. hba1c_cat2  hba1cf. bmi_cat bmif.;
        run;
    %LET wgtvar=smrw;
    %let ds = psdsnnotrim ;
    %let colVar = &exposure.;
    %let rowVars = &tablerowvars. ;
    %LET outname = Table1notrim_&exposure._&comparator._&todaysdate.; 
    options orientation=landscape nodate nonumber nocenter;
    %table1(inds= &ds, colVar= &colVar, rowVars= &rowVars, wgtVar= ,       maxLevels=16, outfile=&outname, title=&outname, cellsize=5);

    
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
        create table table1notrim_&exposure.v&comparator. as
        select a.row, a.&exposure., a.&comparator., a.sdiff label='Unwgted Stdz Diff',
            b.&comparator._wgt, b.sdiff as sdiff_wgt label='Wgted Stdz Diff', a.order, a.roworder
        from tab1_unwgt_&exposure. as a 
        left join tab1_wgt_&exposure. (rename=(&comparator=&comparator._wgt)) as b
            on a.row=b.row and a.order=b.order and a.roworder=b.roworder
        order by order, roworder;
    quit;
    ods escapechar='~' ;
    options orientation=landscape nodate nonumber nocenter;
    ods rtf file="&toutPath./ACNU&ana_name._Table1notrim_&exposure._&comparator._&todaysdate..rtf";
    proc print data=table1notrim_&exposure.v&comparator. noobs label; var row &exposure &comparator sdiff &comparator._wgt sdiff_wgt; run;
    ods rtf close;
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
    /* 2024-12-18: JW add a flag for those who would have been trimmed to the notrim dataset beore saving   */
    data psdsnnotrim; set psdsnnotrim; 
        if &treated_005 <= ps <= &untreated_995 then trimming_flag=0;
        else trimming_flag=1;
        RUN;    
    /* Remove individuals and check for treatment effect heterogeneity */
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
	    ods rtf file="&goutpath./psoutputTRIM&ana_name._&exposure._&comparator.&todaysdate..rtf";
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
   ods pdf file="&foutpath.\psplot_ACNU_trimmed_&ana_name._&exposure._&comparator._&todaysdate..pdf";
    symbol1 interpol=spline value=none line=1;
    symbol2 interpol=spline value=none line=2;
    axis1 order=(0 to 1 by 0.1) minor=none label=(a=0 j=c h=1.5 f=swiss 'Propensity Score') value=(h=1.1 f=swiss);
    axis2 minor=(n=1) label=(a=90 j=c h=1.5 f=swiss 'Density') value=(h=1.1 f=swiss);
    title "Trimmed PS distribution for &exposure. use, by treatment status";
    proc gplot data=psplot_trim;
        plot density*value=pop / haxis=axis1 vaxis=axis2;
        run; quit;
        title;
   ods pdf close;
    * check univariate analysis on weight variables by treatment status, check for extreme weights;
    proc univariate data=psdsn ; class &exposure.; var iptw siptw smrw smrwu ssmrwu; run; 

    /*=================*\
    Save Point: 2024-12-18 JW add saving a notrim dataset
    \*=================*/

    %if &save. = Y %then %do;
        /* Saving the Notrimmed cohort for main analysis */
        data a.notrim&ana_name._&exposure._&comparator._1yrlb; set psdsnnotrim; run;
        /* Saving the PS Trimmed Cohort for sensitivity analysis #3 */
        data a.PS&ana_name._&exposure._&comparator._1yrlb; set psdsn; run;
        /* Updating exclusions for PS trimming */
        PROC SQL; 
            create table tmp_counts as select * from temp.excl_&ana_name._&exposure._&comparator._1yrlb;
            select count(*) into : num_obs from tmp_counts;
            insert into tmp_counts
                set exclusion_num=&num_obs+1, 
                long_text="Number of observations after trimming at 0.05 treated and 0.995 untreated",
                dpp4i=&&n_&exposure._trim,
                dpp4i_diff=&&n_&exposure._trim-&&n_&exposure.,
                &comparator.=&&n_&comparator._trim,
                &comparator._diff=&&n_&comparator._trim-&&n_&comparator., 
                full=&&n_&exposure._trim+&&n_&comparator._trim;
            create table temp.excl_015&ana_name._&exposure._&comparator._1yrlb as select * from tmp_counts;
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
    %table1(inds= &ds, colVar= &colVar, rowVars= &rowVars, wgtVar= , 	    maxLevels=16, outfile=&outname, title=&outname, cellsize=5);
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
    ods rtf file="&toutPath./ACNU&ana_name._Table1trim_&exposure._&comparator._&todaysdate._.rtf";
    proc print data=table1_&exposure.v&comparator. noobs label; var row &exposure &comparator sdiff &comparator._wgt sdiff_wgt; run;
    ods rtf close;

    %mend psweighting_1RXac;


%LET tablerowvarsi = age sex entry_year  

diff_1st_2ndrx  /* added to table 1 rows, NOT in PS trimming model */

bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2 
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever  

oAntGLP_ever dpp4i_ever sglt2i_ever TZD_ever su_ever 

bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr /*num_nondmdrugs1yr_cat*/
ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 

psorp_ever vasc_ever 
RhArth_ever SjSy_ever sLup_ever 
/*IBD_ever crohns_ever ucolitis_ever*/

;

%LET interactions =     /* add interaction */ ;
/*%LET basevars_noint = sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2 nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever 
		bigua_ever insulin_ever prand_ever agluco_ever OAntGLP_ever ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever psorp_ever 
		vasc_ever RhArth_Ever SjSy_Ever sLup_ever num_nondmdrugs1yr;

%LET basevars =  age|age  &basevars_noint;
%let basemodelvars= &basevars. &interactions. ;*/

/*7/21/2024 Jeanny & Tian maybe using 1-year LL for drugs*/
%LET basevars =  age|age
sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever 

bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 

psorp_ever vasc_ever 
RhArth_ever SjSy_ever sLup_ever ;

/*%let tablerowvars= age &basevars_noint;*/

*  %let addedmodelvars= &addedDPP4ivSU;
*  %LET exposure = dpp4i;
*  %LET comparator = su;
*  %LET refyear = 2015;

%LET addedDPP4ivSU = oAntGLP_1yrlookback sglt2i_1yrlookback TZD_1yrlookback;
%psweighting_1RXac ( exposure= dpp4i ,
comparator= SU, 
weight= smrw, 
addedmodelvars= &addedDPP4ivSU, 
basemodelvars= &basevars. &interactions. ,
tablerowvars= &tablerowvarsi,
refyear = 2015, 
save= Y, ana_name=1RX);

%LET addedDPP4ivTZD = oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback chf_ever;
%psweighting_1RXac(exposure=dpp4i,
comparator=TZD, 
weight=smrw,
addedmodelvars= &addedDPP4ivTZD,
basemodelvars= &basevars. &interactions,
tablerowvars=&tablerowvarsi chf_ever,
refyear=2015,
save=Y, ANA_NAME=1RX
);

%LET addedDPP4ivSGLT2i = oAntGLP_1yrlookback su_1yrlookback TZD_1yrlookback;
%psweighting_1RXac(exposure=dpp4i,
comparator=SGLT2i, 
weight=smrw,
addedmodelvars=&addedDPP4ivSGLT2i,
basemodelvars= &basevars. &interactions,
tablerowvars=&tablerowvarsi,
refyear=2015,
save=Y, ANA_NAME=1RX
);

proc print data=temp.excl_0151rx_dpp4i_su_1yrlb noobs ; run;
proc print data=temp.excl_0151rx_dpp4i_TZD_1yrlb noobs ; run;
proc print data=temp.excl_0151rx_dpp4i_SGLT2I_1yrlb noobs ; run;

/*===================================*\
TVE PSWEIGHTING USING THE 1RX GROUP
\*===================================*/



options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen nomlogic nomprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=tmp1rx, savelog=N, dataset=dataname);
%macro psweighting_Ab1RX( exposure , comparator , weight , addedmodelvars ,basemodelvars , tablerowvars, refyear  , ana_name, save );

    data tmp1;
        set a.Ab_allmerged&ANA_NAME._&exposure._&comparator.;
        /* 2024-12-19: JHW add- Created new variable here that is time between first and second prescription */
        diff_1st_2ndrx= filldate2-indexdate; *check that it should be a positive number;
        /* 2024-12-21- JHW add, since [ a.Abrahami_allmerged_&exposure._&comparator.] includes prior to 2012 for sglt2i and those with chf for tzd cohorts */
        /* exclude prior to 2012 for sglt2i */
        %if %upcase(&comparator) eq SGLT2I %then %do; 
            if year(indexdate) lt 2012 then delete; 
        %end;
        /* exclude heart failure for tzd */
        %if %upcase(&comparator) eq TZD  %then %do;
            if chf_bl not in (., 0) then delete;
        %end;  
    RUN;
/* 2024-12-28 JW add switcher_flag */
PROC SQL;
    /* TVE repeat rows */
    create table id_counts_acnu as select ID, count(*) as num_rows_acnu 
    from tmp1 
    where excludeflag_prevalentuser ne 1
    group by ID;
    /* ACNU repeat rows */
    create table id_counts_tve as select ID, count(*) as num_rows_tve
    from tmp1
    group by ID;
    /* Merge ID counts */
    create table tmp2 as select a.*, b.num_rows_tve, c.num_rows_acnu
    from tmp1 as a
    left join id_counts_tve as b
    on a.ID=b.ID
    left join id_counts_acnu as c
    on a.ID=c.ID
    order by a.ID;
QUIT;
data tmp2;
    set tmp2;
    /* Creating a new switcher_flag */
    if (dpp4i=1) then do;
        if (num_rows_tve=1) and (num_rows_acnu=1) then switcher_flag=0; /* Pure DPP4i from ACNU */
        else if (num_rows_tve=1) and (num_rows_acnu=.) and (keepflag_prevalentuser=1) then switcher_flag=99; /*switcher without comparator row, switcher_flag=99 should be deleted*/
        else if (num_rows_tve=2) and (num_rows_acnu=2) then switcher_flag=0; /* pure DPP4i from ACNU */
        else if (num_rows_tve=2) and (num_rows_acnu=1) and (keepflag_prevalentuser=1) then switcher_flag=1; /* switcher to DPP4i */
        else switcher_flag=8; /*flag for edge case */
    end;
    if (dpp4i=0) then do;
        if (num_rows_tve=2) and (num_rows_acnu=1) then switcher_flag=2; /* comparator who switched */
        else if (num_rows_tve=1) and (num_rows_acnu=1) then switcher_flag=3; /* Pure comparator from ACNU */
        else if (num_rows_tve=2) and (num_rows_acnu=2) then switcher_flag=3; /* Pure comparator from ACNU */
        else switcher_flag=9; /*flag for edge case */
    end;
    format switcher_flag switcherf.;
run;
proc datasets lib=work nolist nodetails; delete id_counts_acnu id_counts_tve tmp1; run; quit;
/* Getting counts of excluded dpp4i switchers who had no comparator row */
PROC SQL;
    select count(*) into :num_switcher_flag_99
    from tmp2
    where switcher_flag=99; 
QUIT;
/* exclude dpp4i switchers who had no comparator row */
data tmp2; set tmp2; 
    if switcher_flag=99 then delete;
run;

%PUT &tablerowvars;
%LET tablerowvars=&tablerowvarsi;
	/*=================*\
    Web Table 4 comparing switchers to nonswtichers among dpp4i users 2024-12-28 JW add
    \*=================*/
proc format; value switcherff 0="puredpp4i" 1="switcher";run;
data tmptable1; 
    set tmp2; 
    where switcher_flag in (0,1);
    format switcher_flag switcherff.;
run;

options orientation=landscape nodate nonumber nocenter;
%table1(inds= tmptable1, 
    colVar= switcher_flag, 
    rowVars= &tablerowvarsi, wgtVar= , maxLevels=16, outfile= , title= , cellsize=5);
ods escapechar='~' ;
ods rtf file="&toutPath./SwitcherTable&ana_name._&exposure._&comparator._&todaysdate..rtf";
    proc print data=final noobs label; 
    var /*row switcher_flag su sdiff su_wgt sdiff_wgt*/
		row switcher puredpp4i total order rowOrder sdiff ; run;
	proc freq data=tmp2; tables num_rows_tve*num_rows_acnu*switcher_flag;run;
ods rtf close;
proc datasets lib=work nolist nodetails; delete final; run; quit;
    /*=================*\
    Table 1 untrimmed (appendix) - added 6/5/2024, 7/20/2024 Tian blocked this without weighted Table 1 and added untrimmed weighted Table 1 later
    \*=================*/
  /*  proc format; value &exposure. 0="&comparator." 1="&exposure."; run;
    proc datasets lib=work nolist nodetails; modify tmp2; 
        format &exposure. &exposure..  sex $sexf.  alcohol_cat $statusf. smoke_cat $statusf. hba1c_cat2  hba1cf. bmi_cat bmif.;
     run;
    %LET wgtvar=;
    %let ds = tmp2 ;
    %let colVar = &exposure.;
    %let rowVars = &tablerowvars. ;
    %LET outname = ;*Table1_Abrahami_Untrimmed_&exposure._&comparator._&todaysdate.; 
    options orientation=landscape nodate nonumber nocenter;

    %table1(inds= &ds, colVar= &colVar, rowVars= &rowVars, wgtVar= , maxLevels=16, outfile=&outname, title=&outname, cellsize=5);

    data tab1_untrimmed_&comparator.; 
        set final; 
	run;
    proc datasets lib=work nolist nodetails; delete final; run; quit;

    ods escapechar='~' ;
    options orientation=landscape nodate nonumber nocenter;
    ods rtf file="&toutPath./Abrahami_Table1_Untrimmed_&exposure._&comparator._&todaysdate..rtf";
    proc print data=tab1_untrimmed_&comparator. noobs label; var row &exposure &comparator sdiff; run;
    ods rtf close;
*/

    /*=================*\
    PS weighting
    \*=================*/
    *%removeMetadata(tmp2);


    *  ods rtf file="&goutpath./&todaysdate.psoutput&exposure._&comparator..rtf";
    proc logistic data=tmp2 descending;
        class  entry_year (ref="&refyear.") sex (ref=first) hba1c_Cat2 (ref=first) alcohol_cat (ref=first)
        smoke_cat (ref=first) bmi_cat2(ref=first) /param=ref; 
        model &exposure. =    /*Adding further model variables and interactions VARIABLE*/
        &addedmodelvars. &basemodelvars.; 
	output out= psdsnnotrim pred=ps; run; 
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
        from tmp2
        where &exposure=1;    
        select count(*) into : n_&comparator. 
        from tmp2
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
    ods pdf file= "&foutpath./psplot_TVE&ana_name._untrimmed_&exposure._&comparator._&todaysdate..pdf";
    symbol1 interpol=spline value=none line=1;
    symbol2 interpol=spline value=none line=2;
    axis1 order=(0 to 1 by 0.1) minor=none label=(a=0 j=c h=1.5 f=swiss 'Propensity Score') value=(h=1.1 f=swiss);
    axis2 minor=(n=1) label=(a=90 j=c h=1.5 f=swiss 'Density') value=(h=1.1 f=swiss);
    title "Untrimmed PS distribution for &exposure. use, by treatment status";
    proc gplot data=psplot;
        plot density*value=pop / haxis=axis1 vaxis=axis2;
        run; quit;
        title;
    ods pdf close;
      
	/*=================*\
    Table 1 untrimmed 7/20/2024 Tian added Table 1 untrimmed weighted Table 1.
    \*=================*/
    proc format; value &exposure. 0="&comparator." 1="&exposure."; run;
    proc datasets lib=work nolist nodetails; modify psdsnnotrim; 
        format &exposure. &exposure..  sex $sexf.  alcohol_cat $statusf. smoke_cat $statusf. hba1c_cat2  hba1cf. bmi_cat bmif.;
        run;
    %LET wgtvar=smrw;
    %let ds = psdsnnotrim ;
    %let colVar = &exposure.;
    %let rowVars = &tablerowvars. ;
    %LET outname = TVETable1notrim_&exposure._&comparator._&todaysdate.; 
   	options orientation=landscape nodate nonumber nocenter;
    %table1(inds= &ds, colVar= &colVar, rowVars= &rowVars, wgtVar= ,      
maxLevels=16, outfile=&outname, title=&outname, cellsize=5);

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
        create table table1notrim_&exposure.v&comparator. as
        select a.row, a.&exposure., a.&comparator., a.sdiff label='Unwgted Stdz Diff',
            b.&comparator._wgt, b.sdiff as sdiff_wgt label='Wgted Stdz Diff', a.order, a.roworder
        from tab1_unwgt_&exposure. as a 
        left join tab1_wgt_&exposure. (rename=(&comparator=&comparator._wgt)) as b
            on a.row=b.row and a.order=b.order and a.roworder=b.roworder
        order by order, roworder;
    quit;
    ods escapechar='~' ;
    options orientation=landscape nodate nonumber nocenter;
    ods rtf file="&toutPath./TVE&ana_name._Table1notrim_&exposure._&comparator._&todaysdate..rtf";
    proc print data=table1notrim_&exposure.v&comparator. noobs label; var row &exposure &comparator sdiff &comparator._wgt sdiff_wgt; run;
    ods rtf close;

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
    /* Add flag for those who would have been trimmed to the notrim dataset  */
    data psdsnnotrim; set psdsnnotrim; 
        if &treated_005 <= ps <= &untreated_995 then trimming_flag=0; 
        else trimming_flag=1;
        RUN;
    /* check for treatment effect heterogeneity */
    data psdsn; set psdsnnotrim; 
        where &treated_005 <= ps <= &untreated_995;RUN;

	data trimmed_individuals; set psdsnnotrim; 
        where ps< &treated_005 or ps > &untreated_995;RUN;
    data trimmed_individuals_&exposure. trimmed_individuals_&comparator.;
		set trimmed_individuals; 
		if &exposure=1 then output trimmed_individuals_&exposure.;
		else output trimmed_individuals_&comparator.;
	run;

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
    ods rtf file="&goutpath./TV&ana_name._psoutputTRIM_&exposure._&comparator.&todaysdate..rtf";
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
    ods pdf file="&foutpath./psplot_TVE&ana_name._trimmed_&exposure._&comparator._&todaysdate..pdf";
    symbol1 interpol=spline value=none line=1;
    symbol2 interpol=spline value=none line=2;
    axis1 order=(0 to 1 by 0.1) minor=none label=(a=0 j=c h=1.5 f=swiss 'Propensity Score') value=(h=1.1 f=swiss);
    axis2 minor=(n=1) label=(a=90 j=c h=1.5 f=swiss 'Density') value=(h=1.1 f=swiss);
    title "Trimmed PS distribution for &exposure. use, by treatment status";
    proc gplot data=psplot_trim;
        plot density*value=pop / haxis=axis1 vaxis=axis2;
        run; quit;
        title;
    ods pdf close; 
 
    * check univariate analysis on weight variables by treatment status, check for extreme weights;
    proc univariate data=psdsn ; class &exposure.; var iptw siptw smrw smrwu ssmrwu; run; 

    /*=================*\
    Save Point: Add saving the notrim dataset 
    \*=================*/
    %if &save. = Y %then %do;
        /* Saving Notrimmed cohort for main analysis */
        data a.Abrahami_Notrim&ANA_NAME._&exposure._&comparator.; set psdsnnotrim; run;
        /* Saving PS trimmed cohort for sensitivity analyses */
        data a.Abrahami_PS&ANA_NAME._&exposure._&comparator.; set psdsn; run;

        PROC SQL; 
            create table tmp_counts as select * from temp.abexclusions_1rx_dpp4i_&comparator.;
            select count(*) into : num_obs from tmp_counts;
        /* Updating exclusions for removing switchers whose comparator row was excluded */
            insert into tmp_counts
                set exclusion_num=&num_obs+1, 
                long_text="Number of observations after removing switchers whose comparator row was excluded",
                dpp4i= (select count(*) from psdsnnotrim where dpp4i=1),
                &comparator.= (select count(*) from psdsnnotrim where dpp4i=0),
                dpp4i_diff= -&num_switcher_flag_99;
        /* Updating exclusions for PS trimming */
            insert into tmp_counts
                set exclusion_num=&num_obs+2, 
                long_text="Number of observations after trimming at 0.05 treated and 0.995 untreated",
                dpp4i=&&n_&exposure._trim,
                dpp4i_diff=&&n_&exposure._trim-&&n_&exposure.,
                &comparator.=&&n_&comparator._trim,
                &comparator._diff=&&n_&comparator._trim-&&n_&comparator., 
                full=&&n_&exposure._trim+&&n_&comparator._trim;
            create table temp.Abex_015&ANA_NAME._&exposure._&comparator. as select * from tmp_counts;
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
   %LET outname = TVETable1trim_&exposure._&comparator._&todaysdate.; 
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
    ods rtf file="&toutPath./TVE&ana_name._Table1trim_&exposure._&comparator._&todaysdate..rtf";
    proc print data=table1_&exposure.v&comparator. noobs label; var row &exposure &comparator sdiff &comparator._wgt sdiff_wgt; run;
	
	proc print data= temp.Abex_015&ANA_NAME._&exposure._&comparator. ;run;
	
	ods rtf close;

%mend psweighting_Ab1RX;

/* endregion //!SECTION */
/* endregion //!SECTION */

/*need to do All avaialbe lookback to replicate Abrahami study, also using 1year lookback has % is not close to % by Abrahami!!!!*/
%LET tablerowvarsi = age
sex entry_year   

diff_1st_2ndrx  /* added to table 1 rows, NOT in PS trimming model */

bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2 
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever  

oAntGLP_ever dpp4i_ever sglt2i_ever TZD_ever su_ever 

bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 

psorp_ever vasc_ever 
RhArth_ever SjSy_ever sLup_ever 
IBD_ever crohns_ever ucolitis_ever
;
%LET interactions =     /* add interaction */ ;

%LET basevars =  age|age
sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever 

bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 

psorp_ever vasc_ever 
RhArth_ever SjSy_ever sLup_ever ;

%LET addedDPP4ivSU = oAntGLP_1yrlookback sglt2i_1yrlookback TZD_1yrlookback;
%let weight=smrw;
%let addedmodelvars= &addedDPP4ivSU;
%let refyear = 2015;
%psweighting_Ab1RX( exposure= dpp4i ,
comparator= SU, 
weight= smrw, 
addedmodelvars= &addedDPP4ivSU, 
basemodelvars= &basevars. &interactions. ,
tablerowvars= &tablerowvarsi,
refyear = 2015, ana_name=1rx,
save= Y);

/* 2024-12-21- rerun for untrimmed cohort  */
%LET addedDPP4ivTZD = oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback chf_ever;
%let addedmodelvars= &addedDPP4ivtzd;
%psweighting_Ab1RX(exposure=dpp4i,
comparator=TZD, 
weight=smrw,
addedmodelvars= &addedDPP4ivTZD,
basemodelvars= &basevars. &interactions,
tablerowvars=&tablerowvarsi chf_ever,
refyear=2015,ana_name=1rx,
save=Y
);

%LET addedDPP4ivSGLT2i = oAntGLP_1yrlookback su_1yrlookback TZD_1yrlookback;
%let addedmodelvars= &addedDPP4ivsglt2i;
%psweighting_Ab1RX(exposure=dpp4i,
comparator=SGLT2i, 
weight=smrw,
addedmodelvars=&addedDPP4ivSGLT2i,
basemodelvars= &basevars. &interactions,
tablerowvars=&tablerowvarsi,
refyear=2015,ana_name=1rx,
save=Y
);


/* acnu */
proc print data=temp.excl_0151rx_dpp4i_su_1yrlb noobs ; run;
proc print data=temp.excl_0151rx_dpp4i_TZD_1yrlb noobs ; run;
proc print data=temp.excl_0151rx_dpp4i_SGLT2I_1yrlb noobs ; run;
/* tve */
/* proc print data=temp.Abex_015&ANA_NAME._&exposure._&comparator.;
run; */
proc print data=temp.abEX_0151rx_dpp4i_su noobs ; run;
proc print data=temp.abEX_0151rx_dpp4i_TZD noobs ; run;
proc print data=temp.abEX_0151rx_dpp4i_SGLT2I noobs ; run;


/*===================================*\
Run analysis
\*===================================*/
/* Load ACNU_analysis macro */
%include "D:\Externe Projekte\UNC\wangje\prog\sas\macro_TVE_analysis.sas";
/* Load TVE_analysis macro */
%include "D:\Externe Projekte\UNC\wangje\prog\sas\macro_ACNU_analysis.sas";

/*SU*/
%TVE_analysis (pstrim=N, exclude_ibd=Y, 
exposure= dpp4i , comparator= SU,
ana_name=1RX, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= indexdate, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N,  data_prefix=1rx ) ;
proc print data=      tmp_counts; ;  
run; 
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= SU, 
ana_name=1RX, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= indexdate, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N, data_prefix=1rx ) ;
proc print data=      tmp_counts; ;  
run; 
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=SU);

/*TZD*/
%TVE_analysis (pstrim=N, exclude_ibd=Y, 
exposure= dpp4i , comparator= tzd,
ana_name=1RX, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= indexdate, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N,  data_prefix=1rx ) ;
proc print data=      tmp_counts; ;  
run; 
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= tzd, 
ana_name=1RX, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= indexdate, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N, data_prefix=1rx ) ;
proc print data=      tmp_counts; ;  
run; 
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=tzd);



/* SGLT2I */
%TVE_analysis (pstrim=N, exclude_ibd=Y, 
exposure= dpp4i , comparator=SGLT2I,
ana_name=1RX, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= indexdate, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N,  data_prefix=1rx ) ;
proc print data=      tmp_counts; ;  
run; 
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator=SGLT2I, 
ana_name=1RX, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= indexdate, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N, data_prefix=1rx ) ;
proc print data=      tmp_counts; ;  
run; 
/*Combining table for output of main results */
%summarize(exposure=dpp4i, comparator=SGLT2I);