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


1. The primary outcome of this study was incident IBD 6-months after the index date. We also assessed the risk of Crohn’s disease and ulcerative colitis as secondary outcomes. We performed sensitivity analyses where we required an IBD diagnosis accompanied by a supporting event in the 6 months preceding or following the diagnosis.

2. Secondary analyses [in progress]
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
\*===================================*/
/* region */

/* Print out selected obs for TVE design accross each TVE cohort*/
PROC PRINT data=a.ABRAHAMI_PS_DPP4I_SU (obs=5); 
    run;
PROC SQL;
    /*  */
QUIT;


/* endregion //!SECTION */
/*===================================*\
//SECTION - B.1:
[ ] add analyses and code that are missing from the manuscript
(1) more rigorous IBD outcome definition: from Manuscript Page 4;
Outcome assessment section.
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
/* ibd1: 	none.  */
/* ibd2: 	{colo} or {sigmo} diagnosis within 30 days before (including) the {ibd_i} diagnosis. */
/* Ibd3:	{colo}, {sigmo} or {biops} diagnosis within 30 days before (including) the {ibd_i} diagnosis. */
/* Ibd4: 	{colo}, {Sigmo}, {Gastent} {AbdPain} {Diarr} or {BkStool} diagnosis within 30 days before (including) the {ibd_i} diagnosis. AND {AminoS}, {TnfAI}, {Budeo}, {OtherImm} or {CycloSpor} prescription within 30 days after (including) the {ibd_i} diagnosis.  */
/* Ibd5: 	Special case: only look at the first {ibd_i} diagnosis after time0. If an outcome cannot be validated, there is no outcome; do not follow further for a validated IBD diagnosis. The first {ibd_i} diagnose must be validated with a prescription of {AminoS} or a diagnose of {colo}, {Sigmo}, {Gastent} {AbdPain}, {Diarr} or {BkStool} within 182 days before and after the first {ibd_i} diagnosis (including) the date of the first {ibd_i} diagnosis. */

/* Checking frequencies before running ACNU analysis  */
PROC FREQ DATA= A.PS_DPP4I_SU_1YRLB; tables DPP4I*SU*(ibd1 ibd2 ibd3 ibd4 ibd5 ibd) / LIST MISSING ; run; 
PROC FREQ DATA= A.PS_DPP4I_TZD_1YRLB; tables DPP4I*TZD*(ibd1 ibd2 ibd3 ibd4 ibd5ibd) / LIST MISSING ; run; 
PROC FREQ DATA= A.PS_DPP4I_SGLT2I_1YRLB; tables DPP4I*sglt2I*(ibd1 ibd2 ibd3 ibd4 ibd5 ibd) / LIST MISSING ; run; 

/* Checking frequencies before running TVE anaylsis  */
PROC FREQ DATA= A.ABRAHAMI_PS_DPP4I_SU; tables DPP4I*SU*(ibd1 ibd2 ibd3 ibd4 ibd5 ibd) / LIST MISSING ; run; 
PROC FREQ DATA= A.ABRAHAMI_PS_DPP4I_TZD; tables DPP4I*TZD*(ibd1 ibd2 ibd3 ibd4 ibd5ibd) / LIST MISSING ; run; 
PROC FREQ DATA= A.ABRAHAMI_PS_DPP4I_SGLT2I; tables DPP4I*sglt2I*(ibd1 ibd2 ibd3 ibd4 ibd5 ibd) / LIST MISSING ; run; 

/* If counts sufficient, then run analysis */


/* endregion //!SECTION */
/*===================================*\
//SECTION - B.2:
[ ] add analyses and code that are missing from the manuscript (page 4, secondary analyses)
(2) Analyses were stratified by age at cohort entry (<60 and ≥60 years) 
(3) and sex. 
(4) To assess whether the risk of IBD varied with duration of use, we estimated separate HRs for the first 12 months, and after 12 months of follow-up. 
(5) Additionally, we evaluated whether the risk for IBD varied by patients with and without pre-existing autoimmune disease and gastroenterological disease at cohort entry, since patients with pre-existing conditions tend to have more frequent encounters with the healthcare system and may therefore have more opportunity for IBD detection and diagnosis.
\*===================================*/
/* region */


/* endregion //!SECTION */

/*===================================*\
//SECTION - B.3: 
[ ] fill in numbers for Tian in manuscript Results section page 6 (v6 manuscript, Tian email on 05/28/2024)
"you could help figure the red text/numbers in the 2nd paragraph, that would be great."
The red text is as follows: 
Weighted SAMDs were <0.1 for all measured covariates except for 1) ulcerative colitis and history of SU and TZD use in the DPP4i vs. SU comparison and 2) history of insulin use in the DPP4i vs. TZD comparison, and 3) history of metformin and SGLT2i use in the DPP4i vs. SGLT2i comparison .  
\*===================================*/
/* region */


/* endregion //!SECTION */

%CheckLog(
    ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);
