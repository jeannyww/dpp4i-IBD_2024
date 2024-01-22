/***************************************
SAS file name: 017_mimickAbrahami.sas

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

CHANGES:
Date: 2024-01-21
Notes: see git @jeannyww
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen nosymbolgen nomlogic nomprint nomcompile ; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=017_mimickAbrahami.sas, savelog=N, dataset=dataname);

* 1. Loads into the work library macros, global variables, specific to the Analysis a la Abrahami, not to be utilized for main analysis ACNU cohorts;
%include "D:\Externe Projekte\UNC\wangje\prog\sas\017_dependencies.sas";

/*===================================*\
//SECTION - 2. Get cohorts a la Abrahami, adapted from 012_createcohorts.sas
\*===================================*/

/* execute the macro */
%LET exposure = dpp4i;
%LET comparatorlist = su tzd sglt2i;
%getCohort_Ab (exposure=&exposure.,comparatorlist= &comparatorlist.,washoutp= 365, save= Y);

/* endregion //!SECTION */

/*===================================*\
//SECTION - 3. Merge cohorts a la Abrahami, adapted from 013_merge.sas
\*===================================*/
/* region */
%LET comparatorlist = su tzd sglt2i;
%mergeall_Ab(exposure=dpp4i, comparatorlist=&comparatorlist., primaryGraceP=90, washoutp=365, save=Y);

/* endregion //!SECTION */

/*===================================*\
//SECTION - 4. creating analysis dataset a la Abrahami, adapted from 014_createana_Ablysis.sas
\*===================================*/
/* region */

/* %LET exposure = dpp4i;
%LET comparator = sglt2i;
%createana_Ab(exposure=&exposure, comparatorlist=&comparatorlist, save=N); */
%LET exposure = dpp4i;
%LET comparatorlist = su tzd sglt2i;
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

*  %LET tablerowvarsi =   age  sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  
*  nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever /* duration_metformin */  dpp4i_ever SU_ever TZD_ever sglt2i_ever insulin_ever /* other oad  */   bigua_ever  prand_ever agluco_ever OAntGLP_ever    /* other */ ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever /* Autoimmune */psorp_ever vasc_ever RhArth_Ever SjSy_Ever sLup_ever /* other drugs */num_nondmdrugs1yr num_nondmdrugs1yr_cat;

*  %LET interactions =     /* Interaction */ ;
*  %LET basevars =  age|age  sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever bigua_ever  agluco_ever ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever psorp_ever vasc_ever RhArth_Ever SjSy_Ever sLup_ever num_nondmdrugs1yr ;
*  %LET addedDPP4ivSU = oAntGLP_1yrlookback sglt2i_1yrlookback TZD_1yrlookback;
*  %let addedmodelvars= &addedDPP4ivSU;
*  %let basemodelvars= &basevars. &interactions. ;
*  %let tablerowvars= &tablerowvarsi;

%LET tablerowvarsi =   age  sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever /* duration_metformin */ bigua_ever SU_ever TZD_ever insulin_ever /* other oad  */ dpp4i_ever sglt2i_ever prand_ever agluco_ever OAntGLP_ever    /* other */ ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever /* Autoimmune */psorp_ever vasc_ever RhArth_Ever SjSy_Ever sLup_ever /* other drugs */num_nondmdrugs1yr num_nondmdrugs1yr_cat crohns_ever ucolitis_ever Icomitis_ever;


%LET interactions =     /* add interaction */ ;
%LET basevars =  age|age  sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever bigua_ever insulin_ever prand_ever agluco_ever OAntGLP_ever ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever psorp_ever vasc_ever RhArth_Ever SjSy_Ever sLup_ever num_nondmdrugs1yr ;
%let basemodelvars= &basevars. &interactions. ;


*  %let addedmodelvars= &addedDPP4ivSU;
*  %LET exposure = dpp4i;
*  %LET comparator = su;
*  %LET refyear = 2015;

%LET addedDPP4ivSU = oAntGLP_1yrlookback sglt2i_1yrlookback TZD_1yrlookback;
%psweighting_Ab( exposure= dpp4i ,
comparator= SU, 
weight= smrw, 
addedmodelvars= &addedDPP4ivSU, 
basemodelvars= &basevars. &interactions. ,
tablerowvars= &tablerowvarsi,
refyear = 2015, 
save= Y);

%LET addedDPP4ivTZD = oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback chf_ever;
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
%psweighting_Ab(exposure=dpp4i,
comparator=SGLT2i, 
weight=smrw,
addedmodelvars=&addedDPP4ivSGLT2i,
basemodelvars= &basevars. &interactions,
tablerowvars=&tablerowvarsi,
refyear=2015,
save=Y
);


%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);

ods _all_ close;
goptions reset=all;quit;
*Printing outputs for each ACNU cohort;
ods excel file="&toutpath./Abrahami_T1_compiled_&todaysdate..xlsx"
    options (
        Sheet_interval="NONE"
        embedded_titles="NO"
        embedded_footnotes="NO"
    );
    *dpp4i vs su;
ods excel options(sheet_name="DPP4i_SU"  sheet_interval="NOW");
    proc print data=table1_dpp4ivSU noobs label; var row dpp4i su sdiff su_wgt sdiff_wgt; run;
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
    proc print data=table1_dpp4ivTZD noobs label; var row dpp4i tzd sdiff tzd_wgt sdiff_wgt; run;
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
    proc print data=table1_dpp4ivSGLT2i noobs label; var row dpp4i sglt2i sdiff sglt2i_wgt sdiff_wgt; run;
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

/*===================================*\
//SECTION - 6. Running the 'Analysis' a la Abrahami, adapted from 016_analysis.sas
\*===================================*/
/* region */
/*---------------------------------------------------------------------
%analysis_Ab(
exposure =  ,   *exposure drug of interest: DPP4i;
comparator =  , *comparator drug: SU TZD;    
ana_name =  ,    *name of analysis: main, sensitivity, etc.;
type =  ,        *type of analysis: AT (as treated) or ITT (initial treatment);
weight =  ,       *type of weighting used: iptw, siptw, smrw, smrwu, ssmrwu;
induction =  ,    *induction period for dz initiation 180d;
latency =  ,      *latency period for dz detection 180d;
ibd_def =  ,      *IBD definition used (free text, ie main definition); 
intime =  ,       *time which analysis fu time will start, ie: entry (date of 2nd rx), initiation_date (date of 1st rx);
outtime =  ,      *time which analysis fu ends, ie for AT: '31Dec2017'd, for ITT: oneyearout twoyearout threeyearout fouryearout;
 outdata =        *freetext for your chosen name of the outdata results ;
)

%analysis_Ab ( exposure= , comparator=, ana_name=, type=, weight=, induction=, latency=, ibd_def= , intime= , outtime= , outdata= );

%analysis_Ab ( exposure=  
, comparator=
, ana_name=
, type=
, weight=
, induction=
, latency=
, ibd_def=
, intime=  
, outtime=  
, outdata= );
---------------------------------------------------------------------*/

proc template; define style mystyle;
    parent=styles.sasweb;
        class graphwalls /frameborder=off;
        class graphbackground / color=white;
    end;run;
ods excel file="&toutpath./Abrahami_T2compiled_&todaysdate..xlsx"
options (
    Sheet_interval="NONE"
    embedded_titles="NO"
    embedded_footnotes="NO"
);
    ods excel options(sheet_name="DPP4i_SU IT" sheet_interval="NOW");
    %analysis_Ab ( exposure= dpp4i , comparator= su, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    ods excel options(sheet_name="DPP4i_TZD IT" sheet_interval="NOW");
    %analysis_Ab ( exposure= dpp4i , comparator= tzd, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    ods excel options(sheet_name="DPP4i_SGLT2i IT" sheet_interval="NOW");
    %analysis_Ab ( exposure= dpp4i , comparator= sglt2i, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    ods excel options(sheet_name="DPP4i_SU AT" sheet_interval="NOW");
    %analysis_Ab ( exposure= dpp4i , comparator= su, ana_name=main, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=AT , save=N ) ;
    ods excel options(sheet_name="DPP4i_TZD AT" sheet_interval="NOW");
    %analysis_Ab ( exposure= dpp4i , comparator= tzd, ana_name=main, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=AT , save=N ) ;
    ods excel options(sheet_name="DPP4i_SGLT2i AT" sheet_interval="NOW");
    %analysis_Ab ( exposure= dpp4i , comparator= sglt2i, ana_name=main, type= AT, weight= smrw, induction= 180, latency= 180 , ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd , outdata=AT , save=N ) ;
    ods excel options(sheet_name="Log_issues" sheet_interval="NOW");
    %CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);

    ods excel close; 


/* endregion //!SECTION */

/*===================================*\
//SECTION - 6. Running multivariable cox regression a la Abrahami, adapted from 016_analysis.sas
*TODO - Code in multivariable coxPH to supplement the weighted coxPH.
adapted from Tian's code in archived_ref: 
09_anaRUN_MS/MC
11_sensitivity_coxregression_MS/MC
\*===================================*/
/* region */


/* endregion //!SECTION */

%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);