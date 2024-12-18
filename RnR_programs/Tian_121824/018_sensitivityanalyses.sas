/***************************************
SAS file name: 018_sensitivity_analysis.sas

Purpose: To create sensitivity analyses for badrx and IBD definitions
Author: NA
Creation Date: 2024-04-09

Output, programs (general &goutpath., tables &toutpath., and figures &foutpath.):
D:\Externe Projekte\UNC\wangje\out
D:\Externe Projekte\UNC\wangje\prog\sas

Input paths:
original raw data:  D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16
libname a  D:\Externe Projekte\UNC\wangje\data\analysis
libname raw  D:\Externe Projekte\UNC\wangje\data\raw
libname temp  D:\Externe Projekte\UNC\wangje\data\temp
Other details: CPRD-DPP4i project in collaboration with USB

[x]- Table 1 for Abrahami et. al :trimming is why:(check code and why population moves nonintuitively)
[x]- Table 1 in main manuscript and untrimmed cohort in the appendix

[ ] Check for TVE whether covariates changed between the same ID at time of intiiating comparator vs. time of initiating DPP4i

[ ] 1. The primary outcome of this study was incident IBD 6-months after the index date. We also assessed the risk of Crohn’s disease and ulcerative colitis as secondary outcomes. We performed sensitivity analyses where we required an IBD diagnosis accompanied by a supporting event in the 6 months preceding or following the diagnosis.

[X] 2. Secondary analyses [DELETED!]
Analyses were stratified by age at cohort entry (<60 and ≥60 years) and sex. To assess whether the risk of IBD varied with duration of use, we estimated separate HRs for the first 12 months, and after 12 months of follow-up. Additionally, we evaluated whether the risk for IBD varied by patients with and without pre-existing autoimmune disease and gastroenterological disease at cohort entry, since patients with pre-existing conditions tend to have more frequent encounters with the healthcare system and may therefore have more opportunity for IBD detection and diagnosis.

[ ]  you could help figure the red text/numbers in the 2nd paragraph, that would be great.
In the TVE design, we identified 89,144, 81,099, 47,131 new users of DPP4i   and  78,390 SU, 16,181 TZD, or 30,509 SGLT2i, respectively (Web Table 1-3 ). Across TVE cohorts, the mean age ranged from 59.9-63.5 years, and 39.8%-42.3% of patients were female.  The prevalence of comorbidities was similar across all three comparison cohorts, except that DPP4i initiators were more likely to be overweight compared to SU initiators and less likely to be overweight compared to SGLT2i initiators. Weighted SAMDs were <0.1 for all measured covariates except for 1) ulcerative colitis and history of SU and TZD use in the DPP4i vs. SU comparison and 2) history of insulin use in the DPP4i vs. TZD comparison, and 3) history of metformin and SGLT2i use in the DPP4i vs. SGLT2i comparison .
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all;
option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=018_sensitivity_analysis.sas, savelog=N, dataset=misc);
%include "D:\Externe Projekte\UNC\wangje\prog\sas\018_dependencies.sas";

/*===================================*\
//SECTION - A:  TVE covariate comparison
[ ] Check for TVE whether covariates changed between the same ID at time of intiiating comparator vs. time of initiating DPP4i
From datasets:
A.ABRAHAMI_ALLMERGED_DPP4I_SU
A.ABRAHAMI_ALLMERGED_DPP4I_TZD
A.ABRAHAMI_ALLMERGED_DPP4I_SGLT2I
using keepflag_prevalentuser==1 (the flag that identified DPP4i initiators who were prevalent users of the comparator drug)- created in 17_dependencies.sas lines 384, 420
excludeflag_prevalentuser == people who should have been excluded but were kept, similar to keepflag_prevalentuser
\*===================================*/
/* region */

%LET latency = 180;
%LET induction = 180;
%LET outtime = '31Dec2022'd ;
%LET ibd_def = ibd1;
%LET intime = filldate2;

/* Check per comparator ACNU */
%LET exposure = dpp4i;
%LET comparator = su;
*%LET comparator = tzd;
*%LET comparator = sglt2i;

/* Reading in PS trimmed dataset and recreating time variables, lifted from 17_dependencies lines 1007*/
data dsn; 
    set a.Abrahami_PS_&exposure._&comparator; 
            /* Coding in more time variables  */
        *rxchange: for switching one class from another class;
            rxchange=min(DiscontDate, enddt,  switchAugmentDate);
            label rxchange='MIN of DisconDate, End of Continuous Enrollment, SwitchAugmentDate';
            format rxchange date9.;
        *end of drug in the drug class; 
            endofdrug=rxchange+&latency;
        if &exposure =0 and switchAugmentDate ne . then do;
                enddate= min(&ibd_def._dt, dpp4i_filldate2 +&induction);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne .    then event=1; else event=0;
                end;
        if &exposure =1 and excludeflag_prevalentuser eq 1 then do;
                enddate= min(endofdrug, &ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
                if enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
                end;
            /* for initiators of dpp4i who never switched from the comparator */
            else if &exposure=1 and excludeflag_prevalentuser ne 1 then do;
                enddate= min(endofdrug, &ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
            end;
            /* for initiators of comparator drug who never switched */
            else if &exposure=0 and switchAugmentDate eq . then do;
                enddate= min(endofdrug, &ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
            end;
        *formatting etc; 
        format enddate date9. ; label enddate ="Date min of (&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt), or switch/augment date for comparators";
        *"Date min of (death_dt, endstudy_dt, dbexit_dt, LastColl_Dt)";
        enddatedelete=min(  enddt, endstudy_dt, &outtime);  
        
        *flag to remove individuals who did not reach the induction period for followup ;
        IF indexdate<= enddatedelete<=(&intime + &induction) then deleteobs=1; 
            else deleteobs=0;
        label deleteobs="Flag to remove individuals who did not reach the induction period for followup";
        IF indexdate <= &ibd_def._dt <=(&intime + &induction) then IBDdx_inductionperiod=1;
            else IBDdx_inductionperiod=0;
        label IBDdx_inductionperiod="Flag for individuals with IBD diagnosis within the induction period";
        * followup time;
        time=(enddate-(&intime.+&induction)+1)/365.25;
        time_drugdur=(min(rxchange, enddate)-(indexdate+1))/365.25;    
    
        if time>0 then logtime=(log(time/100000))  ;
        else time=.;
        label time = "person-years" time_drugdur= "duration of treatment";
        label logtime="log(person-years)";
        *flag for individuals with IBD diagnosis ever (IBD before time 0) or IBD post-index date without regard to the induction period; 
        if indexdate<= &ibd_def._dt then IBD_postindex=1; else IBD_postindex=0;
            RUN;
/* tmp dataset for id repeats, lifted from 17_dependencies lines 1178-1188  */
PROC SQL noprint;
    create table tmp as
    SELECT id
    FROM dsn
    GROUP BY id
    HAVING COUNT(*) > 1;
    SELECT count (distinct id) as n FROM tmp;
QUIT;
/* tmp2 dataset for repeated ids */
PROC SQL noprint;
    create table tmp2 as
    select a.* from dsn as a 
    inner join tmp as b on a.id=b.id order by a.id, a.indexdate;
    select count(distinct id) as n from tmp2;
QUIT;
title "Individuals who contributed twice, first to unexposed person time, then contributed to exposed person time";
PROC FREQ DATA=tmp2;
TABLES excludeflag_prevalentuser /list missing;
RUN;
data tmp2; retain 
    id indexdate filldate2 enddate event age  sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2   oAntGLP_1yrlookback dpp4i_1yrlookback sglt2i_1yrlookback TZD_1yrlookback  su_1yrlookback nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever bigua_ever insulin_ever prand_ever agluco_ever OAntGLP_ever ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever psorp_ever vasc_ever RhArth_Ever SjSy_Ever sLup_ever num_nondmdrugs1yr; 
 set tmp2; run;
/* Manually check and printing those who contributed twice selected rows*/
PROC SQL outobs=20 ;
    select * from tmp2 order by id, indexdate;
title; 
/* Then run table1 macro unweighted those who were repeats only */
    proc format; value &exposure. 0="&comparator." 1="&exposure."; run;
    proc datasets lib=work nolist nodetails; modify tmp2; 
        format &exposure. &exposure..  sex $sexf.  alcohol_cat $statusf. smoke_cat $statusf. hba1c_cat2  hba1cf. bmi_cat bmif.;
        run;
    %LET wgtvar=;
    %let ds = tmp2 ;
    %let colVar = &exposure.;
    %let rowVars = age  sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2   oAntGLP_1yrlookback dpp4i_1yrlookback sglt2i_1yrlookback TZD_1yrlookback  su_1yrlookback
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever bigua_ever insulin_ever prand_ever agluco_ever OAntGLP_ever ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever psorp_ever vasc_ever RhArth_Ever SjSy_Ever sLup_ever num_nondmdrugs1yr;
    %LET outname = ;
    options orientation=landscape nodate nonumber nocenter;
    %table1(inds= &ds, colVar= &colVar, rowVars= &rowVars, wgtVar= , maxLevels=16, outfile=&outname, title=&outname, cellsize=5);
    *print to test; 
    data testTVE_&comparator.; 
        set final; run;
    proc print data=testTVE_&comparator. noobs label; var row &exposure &comparator sdiff; run;

    *then decide whether to print to rtf or not; 
    ods escapechar='~' ;
    options orientation=landscape nodate nonumber nocenter;
    ods rtf file="&toutPath./TVE_&exposure._&comparator._&todaysdate..rtf";
    proc print data=testTVE_&comparator. noobs label; var row &exposure &comparator sdiff; run;
    ods rtf close;
/* endregion //!SECTION */


/*===================================*\
//SECTION - B.1:
[ ] add analyses and code that are missing from the manuscript
(1) more rigorous IBD outcome definition: from Manuscript Page 4;
Outcome assessment section.
- may exclude UC and CD individually might have low counts, and we are now more focused as a methods paper 
- "We performed sensitivity analyses where we required an IBD diagnosis accompanied by a supporting event in the 6 months preceding or following the diagnosis.
- We defined a supporting event as a prescription for 5-ASA, a referral for endoscopy, a referral to gastroenterology, or at least one IBD-related symptom (abdominal pain, diarrhea or bloody stools).
- If the date of the supporting code occurred before the date of the IBD diagnostic code, we considered the date of the supporting code to be the date of the incident IBD."**this is not incorporated in the IBD definitions** 
- This seems to align with IBD4, but will run analyses for them either way.
- see 'documentation/Request for IBD and DPP4I-2024-03-03 V12.docx' for more details

Discussion page 9 highlighted in red: 
- To account for possible outcome misclassification, we also adopted more rigorous IBD definitions that incorporated clinical supporting events of IBD in sensitivity analyses
\*===================================*/
/* region */

/* Checking frequencies before analyses. The following definitions*/
/* ibd1: 	primary outcome, incident IBD 6-months after the index date  */
/* ibd2: 	{colo} or {sigmo} diagnosis within 30 days before (including) the {ibd_i} diagnosis. */
/* Ibd3:	{colo}, {sigmo} or {biops} diagnosis within 30 days before (including) the {ibd_i} diagnosis. */
/* Ibd4: 	{colo}, {Sigmo}, {Gastent} {AbdPain} {Diarr} or {BkStool} diagnosis within 30 days before (including) the {ibd_i} diagnosis. AND {AminoS}, {TnfAI}, {Budeo}, {OtherImm} or {CycloSpor} prescription within 30 days after (including) the {ibd_i} diagnosis.  */
/* Ibd5: 	Special case: only look at the first {ibd_i} diagnosis after time0. If an outcome cannot be validated, there is no outcome; do not follow further for a validated IBD diagnosis. The first {ibd_i} diagnose must be validated with a prescription of {AminoS} or a diagnose of {colo}, {Sigmo}, {Gastent} {AbdPain}, {Diarr} or {BkStool} within 182 days before and after the first {ibd_i} diagnosis (including) the date of the first {ibd_i} diagnosis. */

/* Checking frequencies before running ACNU analysis  */
PROC FREQ DATA= A.PS_DPP4I_SU_1YRLB; tables DPP4I*SU*(ibd1 ibd2 ibd3 ibd4 ibd5 ibd) / LIST MISSING ; run; 
PROC FREQ DATA= A.PS_DPP4I_TZD_1YRLB; tables DPP4I*TZD*(ibd1 ibd2 ibd3 ibd4 ibd5ibd) / LIST MISSING ; run; 
PROC FREQ DATA= A.PS_DPP4I_SGLT2I_1YRLB; tables DPP4I*sglt2I*(ibd1 ibd2 ibd3 ibd4 ibd5 ibd) / LIST MISSING ; run; 
/* If counts sufficient, then run analysis chosing the IBD definitions which have 'sufficient' counts */

%LET ibd_def = ibd4;
ods excel file="&toutpath./ACNU_&ibd_def._&todaysdate..xlsx"
options (
    Sheet_interval="NONE"
    embedded_titles="NO"
    embedded_footnotes="NO"
);
    ods excel options(sheet_name="DPP4i_SU IT" sheet_interval="NOW");
    %analysis ( exposure= dpp4i , comparator= su, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= &ibd_def., intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    ods excel options(sheet_name="DPP4i_TZD IT" sheet_interval="NOW");
    %analysis ( exposure= dpp4i , comparator= tzd, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= &ibd_def., intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_SGLT2i IT" sheet_interval="NOW");
    %analysis ( exposure= dpp4i , comparator= sglt2i, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def= &ibd_def., intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    ods excel close;

    
/* Checking frequencies before running TVE anaylsis  */
PROC FREQ DATA= A.ABRAHAMI_PS_DPP4I_SU; tables DPP4I*SU*(ibd1 ibd2 ibd3 ibd4 ibd5 ibd) / LIST MISSING ; run; 
PROC FREQ DATA= A.ABRAHAMI_PS_DPP4I_TZD; tables DPP4I*TZD*(ibd1 ibd2 ibd3 ibd4 ibd5ibd) / LIST MISSING ; run; 
PROC FREQ DATA= A.ABRAHAMI_PS_DPP4I_SGLT2I; tables DPP4I*sglt2I*(ibd1 ibd2 ibd3 ibd4 ibd5 ibd) / LIST MISSING ; run; 

/* If counts sufficient, then run analysis for IBD4 */
ods excel file="&toutpath./Abrahami_&ibd_def._&todaysdate..xlsx"
options (
    Sheet_interval="NONE"
    embedded_titles="NO"
    embedded_footnotes="NO"
);
    ods excel options(sheet_name="DPP4i_SU " sheet_interval="NOW");
    %analysis_Ab (exclude_ibd=N, exposure= dpp4i , comparator= su, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def=&ibd_def. , intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
    
    ods excel options(sheet_name="DPP4i_TZD " sheet_interval="NOW");
    %analysis_Ab (exclude_ibd=N, exposure= dpp4i , comparator= tzd, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def=&ibd_def. , intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;
        
    ods excel options(sheet_name="DPP4i_SGLT2i " sheet_interval="NOW");
    %analysis_Ab (exclude_ibd=N, exposure= dpp4i , comparator= sglt2i, ana_name=main, type= IT, weight= smrw, induction= 180, latency= 180 , ibd_def=&ibd_def. , intime= filldate2, outtime='31Dec2022'd , outdata=IT , save=N ) ;

    ods excel close; 

/* endregion //!SECTION */

/*===================================*\
//SECTION - B.3: 
[ ] fill in numbers for Tian in manuscript Results section page 6 (v6 manuscript, Tian email on 05/28/2024)
"you could help figure the red text/numbers in the 2nd paragraph, that would be great."
The red text is as follows: 
Weighted SAMDs were <0.1 for all measured covariates except for 1) ulcerative colitis and history of SU and TZD use in the DPP4i vs. SU comparison and 2) history of insulin use in the DPP4i vs. TZD comparison, and 3) history of metformin and SGLT2i use in the DPP4i vs. SGLT2i comparison .  
\*===================================*/
/* region */

%LET tablerowvarsi = age  sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2   oAntGLP_1yrlookback dpp4i_1yrlookback sglt2i_1yrlookback TZD_1yrlookback  su_1yrlookback
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever bigua_ever insulin_ever prand_ever agluco_ever OAntGLP_ever ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever psorp_ever vasc_ever RhArth_Ever SjSy_Ever sLup_ever num_nondmdrugs1yr 
/* Added for Tian */
IBD_ever crohns_ever ucolitis_ever chf_ever;


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
tablerowvars=&tablerowvarsi ,
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

/* endregion //!SECTION */


/*===================================*\
//SECTION - B.2: De-prioritizing because this is a methods paper now.
Comment on manuscript_v6 from Til May 14, 2024 "why secondary given that we want to compare these? Please check my above wording and whether something from here needs to be added above, but I think I should have captured the essence of what I understand we did so that this could be deleted here"
[X] add analyses and code that are missing from the manuscript (page 4, secondary analyses)
(2) Analyses were stratified by age at cohort entry (<60 and ≥60 years) 
(3) and stratified by sex. 
(4) To assess whether the risk of IBD varied with duration of use, we estimated separate HRs for the first 12 months, and after 12 months of follow-up. 
(5) Additionally, we evaluated whether the risk for IBD varied by patients with and without pre-existing autoimmune disease and gastroenterological disease at cohort entry, since patients with pre-existing conditions tend to have more frequent encounters with the healthcare system and may therefore have more opportunity for IBD detection and diagnosis.
\*===================================*/
/* region */


/* endregion //!SECTION */
%CheckLog(
    ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);
