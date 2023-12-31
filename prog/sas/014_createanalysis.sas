/***************************************
SAS file name: createanalysisdata.sas

Purpose: to create analysis data set for DPP4i project of all 3 ACNU cohorts
Author: JHW
Creation Date: 30DEC2024

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
Date: 30DEC2024
Notes:          
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\sas\macros");
%setup(programName=createanalysis, savelog=N, dataset=dataname);

/*===================================*\
//SECTION - Creating labels for dataset
\*===================================*/
/* region */


/* endregion //!SECTION */

/*===================================*\
//SECTION - Getting counts for flowchart
\*===================================*/
/* region */



* loading the merged datasets;
%LET exposure = dpp4i;
%LET comparatorlist = su tzd sglt2i;
%LET i = 2;
%LET comparator = %scan(&comparatorlist, &i);

proc print data=temp.exclusions_013_&exposure._&comparator.; run;
run;
data tmp1; set temp.allmerged_&exposure._&comparator.;RUN;
proc contents data= tmp1 varnum; run;  
proc sql; select count(distinct id ) as uniqueids from tmp1; quit;
proc sql; select count(distinct id ) as uniqueids from tmp1 group by dpp4i; quit;

/* getting counts  */
data tmp_counts; 
    retain exclusion_num long_text dpp4i dpp4i_diff &comparator. &comparator._diff;
    set temp.exclusions_013_&exposure._&comparator.;
    dpp4i_diff=dpp4i- lag(dpp4i);
&comparator._diff= &comparator.- lag(&comparator.); RUN;
proc print data=tmp_counts; run;

proc sql noprint;
    select count(*) into :num_obs from tmp_counts;
    /* getting counts from each sequential exclusion */
    insert into tmp_counts 
    set exclusion_num= &num_obs+1 ,
    long_text="Initiators after exclusions a through d (non-mutually exclusive)", 
    dpp4i=(select count(*) from tmp1 where dpp4i=1 and not (excludeflag_prevalentuser=1 or excludeflag_samedayinitiator=1 or excludeflag_prefill2initiator=1 or filldate2=.)),
    &comparator.= (select count(*) from tmp1 where dpp4i=0 and not (excludeflag_prevalentuser=1 or excludeflag_samedayinitiator=1 or excludeflag_prefill2initiator=1 or filldate2=.)),
    dpp4i_diff= -(select count(*) from tmp1 where dpp4i=1 and (excludeflag_prevalentuser=1 or excludeflag_samedayinitiator=1 or excludeflag_prefill2initiator=1 or filldate2=.)),
    &comparator._diff= -(select count(*) from tmp1 where dpp4i=0 and (excludeflag_prevalentuser=1 or excludeflag_samedayinitiator=1 or excludeflag_prefill2initiator=1 or filldate2=.));
    /* were prevalent users of the comparator drug */
    insert into tmp_counts 
        set exclusion_num= &num_obs+2 ,
        long_text="a. Were prevalent users of &exposure. or &comparator. drug", 
        dpp4i_diff= (select count(*) from tmp1 where dpp4i=1 and excludeflag_prevalentuser=1),
        &comparator._diff= (select count(*) from tmp1 where dpp4i=0 and excludeflag_prevalentuser=1);
        /* initiated comparator drug on the same day */
        insert into tmp_counts 
                set exclusion_num= &num_obs+3 ,
                    long_text="b. Dual initiator of &exposure. and &comparator.", 
                    dpp4i_diff= (select count(*) from tmp1 where dpp4i=1 and excludeflag_samedayinitiator=1),
                    &comparator._diff= (select count(*) from tmp1 where dpp4i=0 and excludeflag_samedayinitiator=1);
    /* filled comparator drug before second prescription */
    insert into tmp_counts 
    set exclusion_num= &num_obs+4 ,
    long_text="c. Filled drug before second prescription", 
            dpp4i_diff= (select count(*) from tmp1 where dpp4i=1 and excludeflag_prefill2initiator=1),
            &comparator._diff= (select count(*) from tmp1 where dpp4i=0 and excludeflag_prefill2initiator=1);
            /* had no second prescription */
            insert into tmp_counts 
            set exclusion_num= &num_obs+5,
            long_text="d. Had no respecitve second &exposure. or &comparator. prescription", 
            dpp4i_diff= (select count(*) from tmp1 where dpp4i=1 and filldate2=.),
            &comparator._diff= (select count(*) from tmp1 where dpp4i=0 and filldate2=.);
            
            create table tmp2 as select * 
            from (select * from tmp1 where dpp4i=1 and not (excludeflag_prevalentuser=1 or excludeflag_samedayinitiator=1 or excludeflag_prefill2initiator=1 or filldate2=.)) as a 
            union all corr
            select * from (select * from tmp1 where dpp4i=0 and not (excludeflag_prevalentuser=1 or excludeflag_samedayinitiator=1 or excludeflag_prefill2initiator=1 or filldate2=.)) as b; 
quit;

PROC SQL; 
    select count(*) into :num_obs from tmp_counts;
    
    * Had the following diagnosed diseases before the first prescription were excluded: (a-f non-mutually exclusive)) ;
    insert into tmp_counts 
    set exclusion_num= &num_obs+1 ,
    long_text="Had the diagnosed diseases before the first prescription (a-f non-mutually exclusive)",
    dpp4i= (select count(*) from tmp2 where dpp4i=1 and not (crohns_bl not in (., 0) or ucolitis_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) )), 
    dpp4i_diff= -(select count(*) from tmp2 where dpp4i=1 and (crohns_bl not in (., 0) or ucolitis_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) )),
    &comparator= (select count(*) from tmp2 where dpp4i=0 and not (crohns_bl not in (., 0) or ucolitis_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) )),
    &comparator._diff=- (select count(*) from tmp2 where dpp4i=0 and (crohns_bl not in (., 0) or ucolitis_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0)));
    /*  a. Had Chron's disease */
    insert into tmp_counts 
    set exclusion_num= &num_obs+2 ,
    long_text="a. Had Crohn's disease", 
    dpp4i_diff= (select count(*) from tmp2 where dpp4i=1 and crohns_bl not in (., 0)),
    &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and crohns_bl not in (., 0));
    /*  b. had Ulcerative colitis */
    insert into tmp_counts 
    set exclusion_num= &num_obs+3 ,
    long_text="b. Had Ulcerative colitis", 
    dpp4i_diff= (select count(*) from tmp2 where dpp4i=1 and ucolitis_bl not in (., 0)),
    &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and ucolitis_bl not in (., 0));
    /*  c. had ischemic colitis */
    insert into tmp_counts 
    set exclusion_num= &num_obs+4 ,
            long_text="c. Had ischemic colitis", 
            dpp4i_diff= (select count(*) from tmp2 where dpp4i=1 and icomitis_bl not in (., 0)),
            &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and icomitis_bl not in (., 0));
    /*  d. had diverticulitis or other colitis*/
        insert into tmp_counts 
        set exclusion_num= &num_obs+5 ,
        long_text="d. Had diverticulitis or other colitis", 
        dpp4i_diff= (select count(*) from tmp2 where dpp4i=1 and DivCol_P_bl not in (., 0)),
        &comparator._diff= (select count(*) from tmp2 where dpp4i=0 and DivCol_P_bl not in (., 0));        
create table tmp3 as select * 
from (select * from tmp2 where dpp4i=1 and not (crohns_bl not in (., 0) or ucolitis_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) )) as a
union all corr
select * 
from (select * from tmp2 where dpp4i=0 and not (crohns_bl not in (., 0) or ucolitis_bl not in (., 0) or icomitis_bl not in (., 0) or DivCol_P_bl not in (., 0) )) as b;
QUIT;

PROC SQL; 
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

PROC SQL; 
    select count(*) into :num_obs from tmp_counts;
    /* Initiators with the following procedures before the first prescription were excluded  */
    /* a. had colectomy, colostomy, or ileostomy */
    insert into tmp_counts 
    set exclusion_num= &num_obs+1 ,
    long_text="Initiators with colectomy, colostomy, or ileostomy before the first prescription were excluded",
    dpp4i= (select count(*) from tmp4 where dpp4i=1 and not (colile_bl not in (., 0) )), 
    dpp4i_diff= -(select count(*) from tmp4 where dpp4i=1 and (colile_bl not in (., 0) )),
    &comparator= (select count(*) from tmp4 where dpp4i=0 and not (colile_bl not in (., 0) )),
    &comparator._diff= -(select count(*) from tmp4 where dpp4i=0 and (colile_bl not in (., 0) ));
    create table tmp5 as select *
    from (select * from tmp4 where dpp4i=1 and not (colile_bl not in (., 0) )) as a
    union all corr  
    select *
    from (select * from tmp4 where dpp4i=0 and not (colile_bl not in (., 0) )) as b;
QUIT;
proc print data=tmp_counts; run;
run;


/* endregion //!SECTION */


%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);