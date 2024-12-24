/***************************************
SAS file name: 017_RnR_TVEanalysis.sas

Purpose: To run analysis that mimic Abrahami et al methods for 2018 dpp4i-IBD paper
Author: JHW
Creation Date: 2024-01-21

Output, programs (general &goutpath., tables &toutpath., and figures &foutpath.):
        D:\Externe Projekte\UNC\wangje\out
        D:\Externe Projekte\UNC\wangje\prog\sas

Input paths:
            original raw data:  D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16
            libname a  D:\Externe Projekte\UNC\wangje\data\analysis
            libname raw  D:\Externe Projekte\UNC\wangje\data\raw
            libname temp  D:\Externe Projekte\UNC\wangje\data\temp
Other details: CPRD-DPP4i project in collaboration with USB

CHANGES:2024-04-09- ADDED AT(?) ANALYSIS SEE LINE 257 
Date: 2024-01-21
Notes: see git 

Date: 2024-05-22
Notes: Remove AT analysis now 
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen  nomlogic nomprint  ; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=017_RnR_TVEanalysis.sas, savelog=n, dataset=dataname);

* 1. Loads into the work library macros, global variables, specific to the Analysis a la Abrahami, not to be utilized for main analysis ACNU cohorts;
%include "D:\Externe Projekte\UNC\wangje\prog\sas\17_RnR_TVEanalysismacros.sas";

/*===================================*\
//SECTION - 2. Get cohorts a la Abrahami, adapted from 012_createcohorts.sas
\*===================================*/

%LET exposure = dpp4i;
%let comparator=sglt2i;
%LET comparatorlist =sglt2i ;
%let washoutp=365;
%let save=Y;
/*%LET comparatorlist = su tzd sglt2i;*/
%getCohort_Ab (exposure=&exposure.,comparatorlist= &comparatorlist.,washoutp= 365, save= Y, exclude_reverseswitcher=N);
/*%getCohort_Ab (exposure=&exposure.,comparatorlist= &comparatorlist.,washoutp= 365, save= Y, exclude_reverseswitcher=Y);*/


/* endregion //!SECTION */

/*===================================*\
//SECTION - 3. Merge cohorts a la Abrahami, adapted from 013_merge.sas
\*===================================*/
/* region */
/*%LET comparatorlist = su tzd sglt2i;*/
%let primarygracep=90;
%let washoutp=365;
%mergeall_Ab(exposure=dpp4i, comparatorlist=&comparatorlist., primaryGraceP=90, washoutp=365, save=Y);

/* endregion //!SECTION */

/*===================================*\
//SECTION - 4. creating analysis dataset a la Abrahami, adapted from 014_createana_Ablysis.sas
\*===================================*/
/* region */

/* %LET exposure = dpp4i;
%LET comparator = sglt2i;
%createana_Ab(exposure=&exposure, comparatorlist=&comparatorlist, save=N); */
/*%LET exposure = dpp4i;
%LET comparatorlist = su tzd sglt2i;*/
%createana_Ab(exposure=&exposure, comparatorlist=&comparatorlist, save=Y);
/* endregion //!SECTION */

/*===================================*\
//SECTION - 5. PS weighting adapted from 015_PSweighting.sas
Execute Macro PS weighting with Abrahami covariates:
- Adjusted for age, sex, year of cohort entry, body mass index, alcohol related disorders (including alcoholism, alcoholic cirrhosis of liver, alcoholic hepatitis,
- and hepatic failure), smoking status, haemoglobin A1c (last lab result b4 cohort entry), 
- at any time before cohort entry: microvascular (nephropathy, neuropathy, retinopathy) and macrovascular (myocardial infarction,stroke, peripheral arteriopathy) complications of diabetes, 
- duration of treated diabetes,
- antidiabetic drugs used before cohort entry, 
- use of aspirin, nonsteroidal
- anti-inflammatory drugs, hormonal replacement therapy, oral contraceptives, other autoimmune conditions, 
- total number of unique non-diabetic drugs in year before cohort entry.
\*===================================*/
/* region */

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
/******************** in the PS model *****************************/
%LET interactions =     /* add interaction */ ;

/*7/21/2024 Jeanny & Tian maybe using 1-year LL for drugs*/
%LET basevars =  age|age
sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever 

bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 

psorp_ever vasc_ever 
RhArth_ever SjSy_ever sLup_ever ;

/*%let basemodelvars= &basevars. &interactions. ;*/
/******************** in the PS model *****************************/


*  %let addedmodelvars= &addedDPP4ivSU;
*  %LET exposure = dpp4i;
*  %LET comparator = su;
*  %LET refyear = 2015;

%LET addedDPP4ivSU = oAntGLP_1yrlookback sglt2i_1yrlookback TZD_1yrlookback;
%let weight=smrw;
%let addedmodelvars= &addedDPP4ivSU;
%let refyear = 2015;
%psweighting_Ab( exposure= dpp4i ,
comparator= SU, 
weight= smrw, 
/******************** in the PS model *****************************/
addedmodelvars= &addedDPP4ivSU, 
basemodelvars= &basevars. &interactions. ,
/******************** in the PS model *****************************/
tablerowvars= &tablerowvarsi,
refyear = 2015, 
save= Y);
/* Testing table comparing pre-switch to post-switch */
/* Question about who are switchers compared to? */
/* Based on switcher variable created in line 169 of %getCohort_Ab() macro from program 17_RnR_TVEanalysismacros */
/* 
0= pure exposure (dpp4i)
1= switcher to dpp4i (dpp4i person time after switch from comparator)
2= comparator (comparator person time before switching to DPP4i later) 
3= pure comparator 
4= early switcher w/o filldate2
5= reverse switcher w/o filldate2
6= pure comparator w/o filldate2*/

PROC FREQ DATA=a.Abrahami_Notrim_dpp4i_su ;
TABLES dpp4i*switcher /list missing; *switcher=0, 1,2, or 3;
RUN;
/* Web Table 4: Key patient characteristics between switchers and non-switchers in Dipeptidyl Peptidase-4 inhibitors (DPP4i) group in each comparison.*/
data tmptable1; 
    set a.Abrahami_Notrim_dpp4i_su; 
    /* Among the same person, compare Preswitch (2) to post-switch (1) */
        *where switcher in (1,2);
    /* among dpp4i=1, Pure dpp4i (0) vs those who switched to dpp4i (1) */
        where switcher in (0,1);
    /* among dpp4i=0, Pure comparator (2) vs. comparator who later switched to dpp4i (3) */
        *where dpp4i in (2,3);
        format switcher switcherf.;
    run;
options orientation=landscape nodate nonumber nocenter;
%table1(inds= tmptable1, 
    colVar= switcher, /* or switcher */
    rowVars= &tablerowvarsi, wgtVar= , maxLevels=16, outfile= , title= , cellsize=5);
proc print data=final;
run;

/* switcher*/
proc format;
value switcherf
0="puredpp4i"
1="switcher";
run;

/*
ods escapechar='~' ;
ods rtf file="&toutPath./Tmpswitchtable_&todaysdate..rtf";
    proc print data=final noobs label; 
    var row &exposure &comparator sdiff &comparator._wgt sdiff_wgt; run;
ods rtf close;
*/

/* 2024-12-21- rerun for untrimmed cohort  */
%LET addedDPP4ivTZD = oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback chf_ever;
%let addedmodelvars= &addedDPP4ivtzd;
%psweighting_Ab(exposure=dpp4i,
comparator=TZD, 
weight=smrw,
addedmodelvars= &addedDPP4ivTZD,
basemodelvars= &basevars. &interactions,
tablerowvars=&tablerowvarsi chf_ever,
refyear=2015,
save=Y
);


%LET addedDPP4ivSGLT2i = oAntGLP_1yrlookback su_1yrlookback TZD_1yrlookback;
%let addedmodelvars= &addedDPP4ivsglt2i;
%psweighting_Ab(exposure=dpp4i,
comparator=SGLT2i, 
weight=smrw,
addedmodelvars=&addedDPP4ivSGLT2i,
basemodelvars= &basevars. &interactions,
tablerowvars=&tablerowvarsi,
refyear=2015,
save=Y
);

/*7/13/2024 some errors identified*/
%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);


/* 2024-12-21- JW: Running the rest of the lines below are not necessary */
ods _all_ close;
goptions reset=all;quit;
/* Print flowcharts and Tables */
*Printing outputs for each ACNU cohort;
ods excel file="&toutpath./Abrahami_T1_compiled_&todaysdate..xlsx"
    options (
        Sheet_interval="NONE"
        embedded_titles="NO"
        embedded_footnotes="NO"
    );
    *dpp4i vs su;
ods excel options(sheet_name="DPP4i_SU"  sheet_interval="NOW");
    proc print data=table1_dpp4ivSU noobs label; var row dpp4i_pretrim su_pretrim sdiff_pretrim dpp4i su sdiff su_wgt sdiff_wgt; run;
	proc contents data=table1_dpp4ivsu;run;
	proc print data=table1_dpp4ivsu;run;
ods excel options(sheet_name="DPP4i_SU_plots" sheet_interval="NOW");
    goptions iback="&foutpath./Abrahami_psplot_dpp4i_SU&todaysdate..png" imagestyle=fit;
    proc gslide;RUN;quit; goptions reset=all;
    goptions iback="&foutpath./Abrahami_psplot_trim_dpp4i_SU&todaysdate..png" imagestyle=fit;
    proc gslide;RUN; quit  ; goptions reset=all;
    ods text="PS model:  &addedDPP4ivSU.  &basevars. &interactions. ";
/* ods excel options(sheet_name="DPP4i_SU_flowchart" sheet_interval="NOW");
    proc print data=temp.exclusions_015_dpp4i_su noobs ; run;
 */
    *dpp4i vs TZD;
ods excel options(sheet_name="DPP4i_TZD" sheet_interval="NOW");
    proc print data=table1_dpp4ivTZD noobs label; var row dpp4i_pretrim tzd_pretrim sdiff_pretrim dpp4i tzd sdiff tzd_wgt sdiff_wgt; run;
ods excel options(sheet_name="DPP4i_TZD_plots" sheet_interval="NOW");
    goptions iback="&foutpath./Abrahami_psplot_dpp4i_TZD&todaysdate..png" imagestyle=fit;
    proc gslide;RUN;quit; goptions reset=all;
    goptions iback="&foutpath./Abrahami_psplot_trim_dpp4i_TZD&todaysdate..png" imagestyle=fit;
    proc gslide;RUN; quit; goptions reset=all;
    ods text="PS model:  &addedDPP4ivTZD.  &basevars. &interactions. ";
/* ods excel options(sheet_name="DPP4i_TZD_flowchart" sheet_interval="NOW");
    proc print data=temp.exclusions_015_dpp4i_tzd noobs ; run;
 */
    *dpp4i vs SGLT2i;
ods excel options(sheet_name="DPP4i_SGLT2i" sheet_interval="NOW");
    proc print data=table1_dpp4ivSGLT2i noobs label; var row dpp4i_pretrim sglt2i_pretrim sdiff_pretrim dpp4i sglt2i sdiff sglt2i_wgt sdiff_wgt; run;
ods excel options(sheet_name="DPP4i_SGLT2i_plots" sheet_interval="NOW");
    goptions iback="&foutpath./Abrahami_psplot_dpp4i_SGLT2i&todaysdate..png" imagestyle=fit;
    proc gslide;RUN;quit;    goptions reset=all;
    goptions iback="&foutpath./Abrahami_psplot_trim_dpp4i_SGLT2i&todaysdate..png" imagestyle=fit;
    proc gslide;RUN; quit;    goptions reset=all;
    ods text="PS model:  &addedDPP4ivSGLT2i.  &basevars. &interactions. ";
/* ods excel options(sheet_name="DPP4i_SGLT2i_flowchart" sheet_interval="NOW");
    proc print data=temp.exclusions_015_dpp4i_sglt2i noobs ; run;
 */
    *log summary;
ods excel options(sheet_name="Log_issues" sheet_interval="NOW");
    proc print data=temp.Log_issues noobs ; run;
ods excel close;

ods _all_ close;
/* '; * "; */; quit; run;


/* endregion //!SECTION */



%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);
