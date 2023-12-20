/*****************************************************************************************************************
 SAS file name: formats.sas
__________________________________________________________________________________________________________________

Purpose: To apply formats to data 
Author: Jeanny Wang
Creation Date: 23 sept 23

    Program and output path:
        D:\Externe Projekte\UNC\wangje\code
        D:\Externe Projekte\UNC\wangje\output
        D:\Externe Projekte\UNC\wangje\analysisdat

    Input paths: NA

Other details: applying formats as per pascals docx request file
D:\Externe Projekte\UNC\Task190813 - IBDandDPP4I (db19-1)\doc\20210429\
D:\Externe Projekte\UNC\Task190813 - IBDandDPP4I (db19-1)\doc\20210429\Request for IBD and DPP4I_V8_04.2021
__________________________________________________________________________________________________________________

CHANGES:
Date: 23 sept 23    
Notes: initial commit. see change log at https://github.com/scscriptionsh/dpp4i-cprd.
*****************************************************************************************************************/

proc format;
/* sex*/
value $sexf
'm'="Male"
'f'="Female"
;
/* alcohol, smoking, status */
value $statusf
'u'='Unknown'
's'='Current'
'c'='Current'
'n'='Never'
'x'='Past/quit';

/* BMI */
value bmif
1="<25"
2="25-30"
3=">30"
4="Missing";

/* HBa1c */
value hba1cf
1="<53 mmol/mol (<=7%)"
2="53-64 mmol/mol (7-8%)"
3=">64 mmol/mol (>8%)"
4="Missing/unknown";

/* Number of non-DM drugs in 1 yr prior to cohort entry  */
value drugs1yrcatf
0="0"
1="1"
2="2"
3="3"
4="4 or more"
;

/* Many per obs, 1=IBD */
value reasonf
1="Outcome of interest"
2="End of followup"
3="Y days after treatment discontinuation"
4="Y days after switching or adding of drug class"
5="Death"
6="Database exit";
/* for end of fu = 31dec2017d */
/* for database exit: primary care dataset from their first until their last contact with the participating practice */

/* Treatment status, exposure variable with many per obs */
value tx_statusf
1="Unchanged treatment"
2="Drug class discontinuation"
3="Switching"
4="Adding"; 

/* "Treatment at timepoint X (each available timepoint) {no comparator drug=0, sulfonylureas (SU)=1, SGLT2=2, thiazolidinediones (TZD)=3, SU+SGLT2=4, SU+TZD=5, TZD+SGLT2=6, SU+SGLT2+TZD=7; add 8 for DPP4i}." */

value tx_at_timepf
0	=	"DPP4_i=0; SU=0; SGLT2=0;TZD=0"
1	=	"DPP4_i=0; SU=0; SGLT2=0;TZD=1"
2	=	"DPP4_i=0; SU=0; SGLT2=1;TZD=0"
3	=	"DPP4_i=0; SU=0; SGLT2=1;TZD=1"
4	=	"DPP4_i=0; SU=1; SGLT2=0;TZD=0"
5	=	"DPP4_i=0; SU=1; SGLT2=0;TZD=1"
6	=	"DPP4_i=0; SU=1; SGLT2=1;TZD=0"
7	=	"DPP4_i=0; SU=1; SGLT2=1;TZD=1"
8	=	"DPP4_i=1; SU=0; SGLT2=0;TZD=0"
9	=	"DPP4_i=1; SU=0; SGLT2=0;TZD=1"
10	=	"DPP4_i=1; SU=0; SGLT2=1;TZD=0"
11	=	"DPP4_i=1; SU=0; SGLT2=1;TZD=1"
12	=	"DPP4_i=1; SU=1; SGLT2=0;TZD=0"
13	=	"DPP4_i=1; SU=1; SGLT2=0;TZD=1"
14	=	"DPP4_i=1; SU=1; SGLT2=1;TZD=0"
15	=	"DPP4_i=1; SU=1; SGLT2=1;TZD=1";
run;
