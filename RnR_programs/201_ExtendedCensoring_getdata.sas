/* Program for testing how to code dataset with extended censoring criteria */
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen nosymbolgen nomlogic nomprint mcompile; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=testcensor, savelog=N, dataset=dataname);

/* Have to create this for each comparator, each ACNU, etc. */
/* Dataset that creates the TVE and ACNU*/
TEMP.ALLMERGED_DPP4I_SU
TEMP.ALLMERGED_DPP4I_TZD
TEMP.ALLMERGED_DPP4I_SGLT2I

/* Using these datasets since that have the 1yr lookback?  */
TEMP.ALLMERGED_DPP4I_SU_1YRLB
TEMP.ALLMERGED_DPP4I_TZD_1YRLB
TEMP.ALLMERGED_DPPRI_SGLT2I_1YRLB

/*===================================*\
//SECTION - DPP4i ACNU
\*===================================*/

/* For ACNU Merge with 
a.notrim_dpp4i_tzd_1yrlb*/

/* For ACNU output of 13_merge.sas */
TEMP.ALLMERGED_DPP4I_SU_1YRLB
TEMP.ALLMERGED_DPP4I_TZD_1YRLB
TEMP.ALLMERGED_DPPRI_SGLT2I_1YRLB
/* for each of the above, grab the variables */
excludeflag_prevalentuser
excludeflag_samedayinitiator
excludeflag_prefill2initiator
switchAugmentdate
/* ie, 
for DPP4i this would be easy to get
excludeflag_prevalentuser
excludeflag_samedayinitiator
excludeflag_prefill2initiator
switchAugmentdate

For DP44i vs. SU: 
TEMP.ALLMERGED_DPP4I_SU_1YRLB
su_prevalentuser
su_samedayinitiator
su_prefill2initiator
su_switchAugmentdate

Then get from 
TEMP.ALLMERGED_DPP4I_TZD_1YRLB
tzd_prevalentuser
tzd_samedayinitiator
tzd_prefill2initiator
tzd_switchAugmentdate

sglt2i_prevalentuser
TEMP.ALLMERGED_DPPRI_SGLT2I_1YRLB
sglt2i_samedayinitiator
sglt2i_prefill2initiator
sglt2i_switchAugmentdate
*/
/* Verify that the IDs and time0 match */
/* so that I can merge with the anaylsis dataset */
/* Create exposure=DPP4i */

PROC SQL;
    CREATE TABLE dpp4i_su
    AS SELECT id, indexdate, filldate2,
        dpp4i,
        excludeflag_prevalentuser as  prevalentuser_su,
        excludeflag_samedayinitiator as  samedayinitiator_su,
        excludeflag_prefill2initiator as  prefill2initiator_su,
        switchAugmentdate as switchAugmentdate_su
    FROM TEMP.NEWUSERS_DPP4I_SU
    WHERE dpp4i=1
    ORDER BY id, indexdate ;

    CREATE TABLE dpp4i_tzd
    AS SELECT id, indexdate, filldate2,
        dpp4i,
        excludeflag_prevalentuser as  prevalentuser_tzd,
        excludeflag_samedayinitiator as  samedayinitiator_tzd,
        excludeflag_prefill2initiator as  prefill2initiator_tzd,
        switchAugmentdate as switchAugmentdate_tzd
    FROM TEMP.NEWUSERS_DPP4I_tzd
    WHERE dpp4i=1
    ORDER BY id, indexdate ;

    CREATE TABLE dpp4i_sglt2i
    AS SELECT id, indexdate, filldate2,
        dpp4i,
        excludeflag_prevalentuser as  prevalentuser_sglt2i,
        excludeflag_samedayinitiator as  samedayinitiator_sglt2i,
        excludeflag_prefill2initiator as  prefill2initiator_sglt2i,
        switchAugmentdate as switchAugmentdate_sglt2i
    FROM TEMP.NEWUSERS_DPP4I_sglt2i
    WHERE dpp4i=1
    ORDER BY id, indexdate ;
quit;


PROC SQL;
    CREATE TABLE dpp4i_su
    SELECT id, indexdate,
        dpp4i,
        excludeflag_prevalentuser as , prevalentuser_su
        excludeflag_samedayinitiator as , samedayinitiator_su
        excludeflag_prefill2initiator as , prefill2initiator_su
        switchAugmentdate as switchAugmentdate_su
    FROM TEMP.ALLMERGED_DPP4I_SU_1YRLB
    WHERE dpp4i=1
    GROUP BY id, indexdate
    ORDER BY id, indexdate ;

    CREATE TABLE dpp4i_tzd
    SELECT id, indexdate,
        dpp4i,
        excludeflag_prevalentuser as , prevalentuser_tzd
        excludeflag_samedayinitiator as , samedayinitiator_tzd
        excludeflag_prefill2initiator as , prefill2initiator_tzd
        switchAugmentdate as switchAugmentdate_tzd
    FROM TEMP.ALLMERGED_DPP4I_tzd_1YRLB
    WHERE dpp4i=1
    GROUP BY id, indexdate
    ORDER BY id, indexdate ;

    CREATE TABLE dpp4i_sglt2i
    SELECT id, indexdate,
        dpp4i,
        excludeflag_prevalentuser as , prevalentuser_sglt2i
        excludeflag_samedayinitiator as , samedayinitiator_sglt2i
        excludeflag_prefill2initiator as , prefill2initiator_sglt2i
        switchAugmentdate as switchAugmentdate_sglt2i
    FROM TEMP.ALLMERGED_DPP4I_sglt2i_1YRLB
    WHERE dpp4i=1
    GROUP BY id, indexdate
    ORDER BY id, indexdate ;
QUIT;

/*===================================*\
//SECTION - Comparators (SU, SGLT2i, TZD), ACNU
\*===================================*/

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
        %end;
    proc print data=tmp_id_counts; run;
    %end;
%mend getCohort;

/* run the macro  */
/* %LET exposure = dpp4i;
%let comparatorlist = su tzd SGLT2i;
%getCohort ( &exposure , &comparatorlist, Y ); */

/* Then create 
temp.newusers_su_dpp4i (check if this is similar to dpp4i_su)
temp.newusers_su_sglt2i
temp.newusers_su_tzd */ 
%let comparatorlist = su;
%LET exposure = dpp4i tzd SGLT2i;
%getCohort ( &exposure , &comparatorlist, Y );

PROC SQL;
    CREATE TABLE su_dpp4i
    SELECT id, indexdate,
        su,
        excludeflag_prevalentuser as , prevalentuser_dpp4i
        excludeflag_samedayinitiator as , samedayinitiator_dpp4i
        excludeflag_prefill2initiator as , prefill2initiator_dpp4i
        switchAugmentdate as switchAugmentdate_dpp4i
    FROM temp.newusers_su_dpp4i 
    WHERE su=1
    GROUP BY id, indexdate
    ORDER BY id, indexdate ;

    CREATE TABLE su_tzd
    SELECT id, indexdate,
        su,
        excludeflag_prevalentuser as , prevalentuser_tzd
        excludeflag_samedayinitiator as , samedayinitiator_tzd
        excludeflag_prefill2initiator as , prefill2initiator_tzd
        switchAugmentdate as switchAugmentdate_tzd
    FROM temp.newusers_su_tzd
    WHERE su=1
    GROUP BY id, indexdate
    ORDER BY id, indexdate ;

    CREATE TABLE su_sglt2i
    SELECT id, indexdate,
        su,
        excludeflag_prevalentuser as , prevalentuser_sglt2i
        excludeflag_samedayinitiator as , samedayinitiator_sglt2i
        excludeflag_prefill2initiator as , prefill2initiator_sglt2i
        switchAugmentdate as switchAugmentdate_sglt2i
    FROM temp.newusers_su_sglt2i
    WHERE su=1
    GROUP BY id, indexdate
    ORDER BY id, indexdate ;
QUIT;

/* SGLT2i */
/*temp.newusers_sglt2i_dpp4i
temp.newusers_sglt2i_su
temp.newusers_sglt2i_tzd*/
%let comparatorlist = SGLT2i ;
%LET exposure = dpp4i su tzd ;
%getCohort ( &exposure , &comparatorlist, Y );

/* TZD */
/*temp.newusers_tzd_dpp4i
temp.newusers_tzd_su
temp.newusers_tzd_sglt2i*/
%let comparatorlist = tzd ;
%LET exposure = dpp4i su  SGLT2i;
%getCohort ( &exposure , &comparatorlist, Y );

/*===================================*\
//SECTION - TVE
\*===================================*/
/* For TVE Merge within
a.abrahami_notrim_dpp4i_tzd
*/
/* First take all dates from */
/* For TVE the output of %mergeall_ab from 17 dependencies.sas  */
TEMP.ABRAHAMI_ALLMERGED_DPP4I_SU
TEMP.ABRAHAMI_ALLMERGED_DPP4I_TZD
TEMP.ABRAHAMI_ALLMERGED_DPP4I_SGLT2I
/*  */
temp.Abrahami_allmerged_&exposure._&comparator.


/* For all other comparators */
%LET exposure = dpp4i;
%let comparator=sglt2i;
%LET comparatorlist =sglt2i ;
%let washoutp=365;
%let save=Y;
/*%LET comparatorlist = su tzd sglt2i;*/
%getCohort_Ab (exposure=&exposure.,comparatorlist= &comparatorlist.,washoutp= 365, save= Y, exclude_reverseswitcher=N);

/* Data output */
TEMP.NEWUSERS_DPP4I_SU
TEMP.NEWUSERS_DPP4I_TZD
TEMP.NEWUSERS_DPP4I_SGLT2I


temp.newusers_tzd_sglt2i
temp.newusers_tzd_su
temp.newusers_tzd_dpp4i

temp.newusers_sglt2i_dpp4i
temp.newusers_sglt2i_su
temp.newusers_sglt2i_tzd

temp.newusers_su_dpp4i
temp.newusers_su_sglt2i
temp.newusers_su_tzd

/* try eget extended censor macro */

/* get extended censor for SU */
%LET drug1 = su;
%LET drug2 = dpp4i;
%LET drug3 = tzd;
%LET drug4 = sglt2i;

%macro getextendedcensor(drug1, drug2, drug3, drug4);
PROC SQL;
    CREATE TABLE &drug1._&drug2.
    AS SELECT id, indexdate, filldate2,
        &drug1,
        excludeflag_prevalentuser as  prevalentuser_&drug2.,
        excludeflag_samedayinitiator as  samedayinitiator_&drug2.,
        excludeflag_prefill2initiator as  prefill2initiator_&drug2.,
        switchAugmentdate as switchAugmentdate_&drug2.
    FROM TEMP.NEWUSERS_&drug1._&drug2.
    WHERE &drug1=1
    ORDER BY id, indexdate ;

    CREATE TABLE &drug1._&drug3.
    AS SELECT id, indexdate, filldate2,
        &drug1,
        excludeflag_prevalentuser as  prevalentuser_&drug3.,
        excludeflag_samedayinitiator as  samedayinitiator_&drug3.,
        excludeflag_prefill2initiator as  prefill2initiator_&drug3.,
        switchAugmentdate as switchAugmentdate_&drug3.
    FROM TEMP.NEWUSERS_&drug1._&drug3.
    WHERE &drug1=1
    ORDER BY id, indexdate ;

    CREATE TABLE &drug1._&drug4.
    AS SELECT id, indexdate, filldate2,
        &drug1,
        excludeflag_prevalentuser as  prevalentuser_&drug4.,
        excludeflag_samedayinitiator as  samedayinitiator_&drug4.,
        excludeflag_prefill2initiator as  prefill2initiator_&drug4.,
        switchAugmentdate as switchAugmentdate_&drug4.
    FROM TEMP.NEWUSERS_&drug1._&drug4.
    WHERE &drug1=1
    ORDER BY id, indexdate ;
quit;
proc sql;
	CREATE TABLE &drug1._extendedcensor 
	as select b.id, b.indexdate, b.filldate2, b.&drug1., 
	b.prevalentuser_&drug2., b.samedayinitiator_&drug2., b.prefill2initiator_&drug2., b.switchAugmentdate_&drug2.,
    c.prevalentuser_&drug3., c.samedayinitiator_&drug3., c.prefill2initiator_&drug3., c.switchAugmentdate_&drug3.,
    d.prevalentuser_&drug4., d.samedayinitiator_&drug4., d.prefill2initiator_&drug4., d.switchAugmentdate_&drug4.
	from &drug1._&drug2. as b
	inner join &drug1._&drug3. as c
	on b.id=c.id and b.indexdate=c.indexdate
	inner join &drug1._&drug4. as d
	on b.id=d.id and b.indexdate=d.indexdate;
quit;
%mend getextendedcensor;

%getextendedcensor(dpp4i, su, sglt2i, tzd);
%getextendedcensor(su, dpp4i, sglt2i, tzd);
%getextendedcensor(sglt2i, su, dpp4i, tzd);
%getextendedcensor(tzd, su, dpp4i, sglt2i);


/*save_extendedcensor*/
*combine and save into the main analysis dataset;
%macro save_extendedcensor ( comparator );
/*join with a.notrim_DPP4i_SU_1yrlb*/
proc sql;
/*849*/
create table ac_dpp4i_&comparator.0 
as select a.* , b.*
from a.notrim_dpp4i_&comparator._1yrlb as a
left join 
dpp4i_extendedcensor as b
on a.id=b.id and a.indexdate=b.indexdate
where a.dpp4i=1;
quit;
proc sql;
/*849*/
create table ac_dpp4i_&comparator.1 
as select a.* , b.*
from a.notrim_dpp4i_&comparator._1yrlb as a
left join 
&comparator._extendedcensor as b
on a.id=b.id and a.indexdate=b.indexdate
where a.dpp4i=0;
quit;
/*combine and resave as the analysis dataset*/
/* data a.notrim_dpp4i_&comparator._1yrlb ; */
data dpp4i_&comparator._extendedcensor; 
set
ac_dpp4i_&comparator.0 
ac_dpp4i_&comparator.1;
extended_switchaugmentdt=min(of 
switchAugmentdate
switchAugmentdate_dpp4i
switchAugmentdate_su
switchAugmentdate_tzd
switchAugmentdate_sglt2i);
format extended_switchaugmentdt date9.;
length drug_switched_to $10.;
if extended_switchaugmentdt =. then drug_switched_to= 'none';
else if extended_switchaugmentdt = switchAugmentdate_dpp4i then drug_switched_to = 'dpp4i';
else if extended_switchaugmentdt = switchAugmentdate_su then drug_switched_to = 'su';
else if extended_switchaugmentdt = switchAugmentdate_tzd then drug_switched_to = 'tzd';
else if extended_switchaugmentdt = switchAugmentdate_sglt2i then drug_switched_to = 'sglt2i';
label 
id = 'Patient ID'
dpp4i = 'DPP-4 Inhibitor'
indexdate = 'Index Date'
filldate2 = 'Fill Date'
switchAugmentdate = 'Switch/Augment Date to the comparator drug'
switchAugmentdate_dpp4i = 'Switch/Augment Date to DPP4i'
switchAugmentdate_su = 'Switch/Augment Date to SU'
switchAugmentdate_tzd = 'Switch/Augment Date to TZD'
switchAugmentdate_sglt2i = 'Switch/Augment Date to SGLT2i'
extended_switchaugmentdt = 'Extended Switch/Augment (min date of dpp4i, su, tzd, and sglt2i switchaugment)'
drug_switched_to = 'Drug Switched To for the sensitivity analysis with extended censoring criteria';
if switchAugmentdate eq . then switchmainAT=0; else switchmainAT=1;
label switchmainAT='flag for switchaugmentdate in the main AT analysis (no extended censoring criteria)';
run; 
%mend save_extendedcensor;

%save_extendedcensor(su);
%save_extendedcensor(tzd);
%save_extendedcensor(sglt2i);



%macro save_extendedcensor ( comparator );
/*join with a.notrim_DPP4i_SU_1yrlb*/
proc sql;
/*849*/
create table ac_dpp4i_&comparator.0 
as select a.* , b.*
from psdsnnotrim as a
left join 
temp.dpp4i_extendedcensor as b
on a.id=b.id and a.indexdate=b.indexdate
where a.dpp4i=1;
quit;
proc sql;
/*849*/
create table ac_dpp4i_&comparator.1 
as select a.* , b.*
from psdsnnotrim as a
left join 
temp.&comparator._extendedcensor as b
on a.id=b.id and a.indexdate=b.indexdate
where a.dpp4i=0;
quit;
/*combine and resave as the analysis dataset*/
 data psdsnnotrim ; 
/*data dpp4i_&comparator._extendedcensor; */
set
ac_dpp4i_&comparator.0 
ac_dpp4i_&comparator.1;
extended_switchaugmentdt=min(of 
switchAugmentdate
switchAugmentdate_dpp4i
switchAugmentdate_su
switchAugmentdate_tzd
switchAugmentdate_sglt2i);
format extended_switchaugmentdt date9.;
length drug_switched_to $10.;
if extended_switchaugmentdt =. then drug_switched_to= 'none';
else if extended_switchaugmentdt = switchAugmentdate_dpp4i then drug_switched_to = 'dpp4i';
else if extended_switchaugmentdt = switchAugmentdate_su then drug_switched_to = 'su';
else if extended_switchaugmentdt = switchAugmentdate_tzd then drug_switched_to = 'tzd';
else if extended_switchaugmentdt = switchAugmentdate_sglt2i then drug_switched_to = 'sglt2i';
label 
id = 'Patient ID'
dpp4i = 'DPP-4 Inhibitor'
indexdate = 'Index Date'
filldate2 = 'Fill Date'
switchAugmentdate = 'Switch/Augment Date to the comparator drug'
switchAugmentdate_dpp4i = 'Switch/Augment Date to DPP4i'
switchAugmentdate_su = 'Switch/Augment Date to SU'
switchAugmentdate_tzd = 'Switch/Augment Date to TZD'
switchAugmentdate_sglt2i = 'Switch/Augment Date to SGLT2i'
extended_switchaugmentdt = 'Extended Switch/Augment (min date of dpp4i, su, tzd, and sglt2i switchaugment)'
drug_switched_to = 'Drug Switched To for the sensitivity analysis with extended censoring criteria';
if switchAugmentdate eq . then switchmainAT=0; else switchmainAT=1;
label switchmainAT='flag for switchaugmentdate in the main AT analysis (no extended censoring criteria)';
run; 
%mend save_extendedcensor;

%save_extendedcensor(comparator= &comparator.);
%save_extendedcensor(su);
%save_extendedcensor(tzd);
%save_extendedcensor(sglt2i);
