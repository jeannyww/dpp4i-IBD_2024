/***************************************
SAS file name: 012_createcohorts.sas
Task231122 - IBDandDPP4I (db23-1)

Purpose: To consolidate _demog, _trtmt, and _event datasets into one dataset, then combine for each ACNU cohort
Author: JHW
Creation Date: 26DEC2024
Output, programs (general &goutpath., tables &toutpath., and figures &foutpath.):
        D:\Externe Projekte\UNC\wangje\out
        D:\Externe Projekte\UNC\wangje\prog\sas

Input paths:
            original raw data:  D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16
            libname a  D:\Externe Projekte\UNC\wangje\data\analysis
            libname raw  D:\Externe Projekte\UNC\wangje\data\raw
            libname temp  D:\Externe Projekte\UNC\wangje\data\temp
Other details: CPRD-DPP4i project in collaboration with USB

CHANGES:
Date: see git 
Notes: etc
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=012_createcohorts, savelog=N, dataset=dataname);


/* Starting with exclusions box 0 to add sequentially to get all counts for each ACNU  */
data temp.exclusions_box0_all;
    retain exclusion_num long_text; 
    length long_text $200;
    infile datalines delimiter='|' dsd missover;
    input exclusion_num long_text $  dpp4i su tzd sglt2i full;
    datalines;
    1|Number of patients within the CPRD|||||21120880
    2|correct sex (female or male)|||||21119778
    3|present during study period (01.01.2007 - 12.31.2022)|||||13913942
    4|first study drug prescripion during study period|124930|249584|77836|72767
    5|age at time0 >= 18|124910|249490|77827|72756
    6|>= 356 days of history prior time0|105463|196718|69090|61309
    7|time0 in 2007: no study drug prescription within 365 days prior time0|105463|129203|69090|32307
    8|number of unique ids in _events dataset|105463|129203|69090|32307
    9|number of unique ids in _treatment dataset|105399|129082|69059|32289
    ;
run;
data temp.exclusions_dpp4i_su; set temp.exclusions_box0_all; keep exclusion_num long_text dpp4i su full; run;
data temp.exclusions_dpp4i_tzd; set temp.exclusions_box0_all; keep exclusion_num long_text dpp4i tzd full; run;
data temp.exclusions_dpp4i_sglt2i; set temp.exclusions_box0_all; keep exclusion_num long_text dpp4i sglt2i full; run;


/* get periods of new use for visaversa comparisons  */
/* adapted from Tian's 01_exposure_MC/MS sas programs  */
%macro newuse ( drug1 , drug2 , washoutp);
    PROC SQL;  
        create table useperiods_&drug1. as select * from  temp.&drug1._useperiods ;
        create table useperiods_&drug2. as select * from temp.&drug2._useperiods;
        create table tmp_exclude as 
        select distinct a.* , 
        max(a.indexdate-&washoutp.<=b.discontDate and b.indexdate<a.indexdate) as excludeflag_prevalentuser label='EXCLUSION FLAG: prevalent user of comparator drug', 
        max(a.indexdate=b.indexdate) as excludeflag_samedayinitiator label = 'EXCLUSION FLAG: dual  initiator of comparator drug',
        max(a.indexdate<b.indexdate<= a.filldate2) as excludeflag_prefill2initiator label='EXCLUSION FLAG: pre-fill2 dual initiator of comparator drug before second fill date'
        from useperiods_&drug1.(where= (newuse=1) rename=(reason=reason1)) as a
        LEFT JOIN useperiods_&drug2. as b on a.id=b.id group by a.id, a.indexdate; 
        
        create table new_&drug1. as
        select distinct a.* , min(b.indexdate) as switchAugmentdate format=date9. label='DATE OF SWITCH/AUGMENTATION' 
        from tmp_exclude as a 
        LEFT JOIN useperiods_&drug2. as b on a.id=b.id and a.indexdate<=b.indexdate<= a.discontDate
        group by a.id, a.indexdate
        order by a.id, a.indexdate;
    QUIT;
    
%mend newuse;

/*getCohort*/
*to create ACNU cohort for each drug/comparator combo;
%macro getCohort ( exposure , comparatorlist , save);

/* loop through each exposure comparator combination */
%do i=1 %to %sysfunc(countw(&comparatorlist.));
    %let comparator = %scan(&comparatorlist.,&i.);
    /* Get new use for exposure and comparator drug visaversa */
    %newuse ( &exposure , &comparator, 365 );
    %newuse ( &comparator , &exposure, 365 );
    /* get counts for use periods part of study flowchart and store into temp table */
    PROC SQL noprint; 
        CREATE TABLE tmp_id_counts AS SELECT *  FROM temp.exclusions_dpp4i_&comparator.;
        select count(*) into :num_obs from tmp_id_counts;
        select count(distinct id ) into :nobs1 from useperiods_&exposure.;
        select count(distinct id ) into :nobs2 from useperiods_&comparator.;
        INSERT INTO tmp_id_counts
        SET exclusion_num = &num_obs + 1,
        long_text = "Initiators of &exposure. or &comparator.",
        dpp4i = &nobs1,
        &comparator. = &nobs2;    
    QUIT;
    /* get counts for new users part of study flowchart and store in temp table */
    proc sql noprint;
        select count(*) into :num_obs from tmp_id_counts;
        select count(distinct id ) into :nobs3 from new_&exposure.;
        select count(distinct id ) into :nobs4 from new_&comparator.;
        insert into tmp_id_counts
        set exclusion_num = &num_obs + 1,
        long_text = "New users of &exposure. or &comparator.",
        dpp4i = &nobs3,
        &comparator. = &nobs4;
    quit;
    /* combine newusers for both exposure and comparator  */
    data newusers_&exposure._&comparator. (sortedby=id indexdate);
        set new_&exposure. (in=a) new_&comparator. (in=b);
        by id indexdate;
        &exposure.=a; 
        label &exposure = "Drug class: 1= &exposure. 0= &comparator.";
        RUN;
    /* If save=Y then save the newusers dataset and tmp_id_counts into temp libname   */
    %if &save.=Y %then %do;
        data temp.newusers_&exposure._&comparator. ; set newusers_&exposure._&comparator. ;
        RUN;
        data temp.exclusions_012_&exposure._&comparator.; set tmp_id_counts;
        %end;
    proc print data=tmp_id_counts; run;
    %end;
%mend getCohort;

/* run the macro  */
%let comparatorlist = su tzd SGLT2i;
%LET exposure = dpp4i;
%getCohort ( &exposure , &comparatorlist, Y );

%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);