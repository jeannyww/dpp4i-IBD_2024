/***************************************
SAS file name: ZS_QC_2024-02-26.sas

Purpose: Zoey Qc of code
Author: JHW
Creation Date: 2024-02-26

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
Date: 2024-02-26
Notes:edits and comments 
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=ZS_QC_2, savelog=N, dataset=dataname);

libname out 'D:\Externe Projekte\UNC\wangje\data\analysis';
libname temp 'D:\Externe Projekte\UNC\wangje\data\temp';

proc print data=out.allmerged_dpp4i_sglt2i(obs=10);run;

proc freq data=out.allmerged_dpp4i_sglt2i;tables dpp4i;run;
proc freq data=out.allmerged_dpp4i_su;tables dpp4i;run;


proc contents data=out.abrahami_allmerged_dpp4i_sglt2i varnum;run;
proc sql;
	create table abrahami_comp as select coalesce (a.id, b.id) as id, 
		a.dpp4i as dpp_sglt, a.indexdate as sglt format=date9., b.dpp4i as dpp_su, b.indexdate as su format=date9.,
		case when a.indexdate=. and year(b.indexdate)>=2012 then 1 when a.indexdate=. and year(b.indexdate)<2012 then 1.5
			 when b.indexdate=. then 2 when a.indexdate ne b.indexdate then 3 else 0 end as flag
             from out.abrahami_allmerged_dpp4i_sglt2i(where=(dpp4i=1)) as a full join out.abrahami_allmerged_dpp4i_su(where=(dpp4i=1)) as b on a.id=b.id;
            quit;
            proc format; value flag 1='SU only' 1.5='Pre-2012' 2='SGLT only' 3='Different Date' 0='In both Cohorts';
proc freq data=abrahami_comp;tables flag; format flag flag.; run;


proc print data=abrahami_comp(obs=10);where su ne sglt and flag in (1,2); run;
proc print data=temp.abrahami_allmerged_dpp4i_su;where id="&id";run;

proc print data=temp.useperiods_su;where id="&id";run;
/*%LET id=10001~10997;*/
/*%LET id=10001~10997;*SGLT only:  10AUG2012; */

%LET id=*********; *SGLT only: 12AUG2013;
*Start of data (2007?): prevalent user of SU;
*Aug 2013: augment with DPP (continue on SU);
*Apr 2015: augment with SGLT (continue on both DPP and SU);
proc print data=temp.abrahami_allmerged_dpp4i_su; where id="&id";run;
*PROBLEM: THIS PERSON IS DROPPED FROM THE SU COHORT BECUASE THEY WERE A PREVALENT USER OF SU AT THE START OF THE DATA 
(and are therefore not in the su_useperiods and therefore do not have an SU period of use in the analytic dataset);
proc print data=out.abrahami_allmerged_dpp4i_su; where id="&id";run;


ods html close; ods listing;

proc print data=comp;where id="&id"; title 'Comparison';run;

proc sql; 
    select min(rxdate) format=date9. label='First DPP Fill' from raw.dpp4i_trtmt where id="&id";
select min(rxdate) format=date9. label='First SGLT Fill' from raw.sglt2i_trtmt where id="&id";
select min(rxdate) format=date9. label='First SU Fill' from raw.su_trtmt where id="&id";
quit;


proc print data=raw.dpp4i_trtmt;where id="&id"; title 'DPP4'; var id rxdate dpp4i su sglt2i tzd rx_dayssupply; run;
proc print data=raw.sglt2i_trtmt;where id="&id"; title 'SGLT2'; var id rxdate dpp4i su sglt2i tzd rx_dayssupply; run;
proc print data=raw.su_trtmt;where id="&id"; title 'SU'; var id rxdate dpp4i su sglt2i tzd rx_dayssupply; run;

proc print data=temp.su_useperiods;where id="&id";run;

proc print data=temp.allmerged_dpp4i_sglt2i;where id="&id"; var id indexdate dpp4i su sglt2i tzd excludeFlag:; run;
proc print data=temp.allmerged_dpp4i_su;where id="&id";  var id indexdate dpp4i su sglt2i tzd excludeFlag:; run;



proc print data=out.allmerged_dpp4i_sglt2i;where id="&id";;var id indexdate dpp4i su sglt2i tzd excludeFlag:; run;
proc print data=out.allmerged_dpp4i_su;where id="&id"; var id indexdate dpp4i su sglt2i tzd excludeFlag:; run;

PROC CONTENTS DATA=

proc print data=temp.exclusions_013_dpp4i_sglt2i; where id"&id"; run;


/*********************************************************************/
*DPP ARM OF COMBINED COHORT: SHOULD BE THE SAME AS THE DPP ARM OF ANY OF THE THREE COHORTS;
*IF THERE ARE LEGITIMATE DIFFERENCES BETWEEN THE COHORTS, WE NEED TO DETERMINE WHICH ONES WOULD BE INCLUDED IN THE OVERALL COHORT;
*IF THERE ARE NOT LEGITIMATE DIFFERENCES BETWEEN THE COHORTS, THEN WE NEED TO FIGURE OUT WHY WE HAVE DIFFERENCES NOW.


*COMPARATOR ARM OF COMBINED COHORT: SHOULD BE EARLIEST USE OF ANY OF THE THREE COHORTS;

/**********************************************************************************************************************************************/
/*ZS begin*/

/*Look into ID=**********/
libname out 'D:\Externe Projekte\UNC\wangje\data\analysis' access=readonly;
    libname temp 'D:\Externe Projekte\UNC\wangje\data\temp' access=readonly;
%LET id=*********; *SGLT only: 12AUG2013;

*VP note:;
*Start of data (2007?): prevalent user of SU;
    *Aug 2013: augment with DPP (continue on SU);
*Apr 2015: augment with SGLT (continue on both DPP and SU);
proc print data=temp.abrahami_allmerged_dpp4i_su; where id="&id";title 'DPP4i_su temp';run;
*PROBLEM: THIS PERSON IS DROPPED FROM THE SU COHORT BECUASE THEY WERE A PREVALENT USER OF SU AT THE START OF THE DATA 
(and are therefore not in the su_useperiods and therefore do not have an SU period of use in the analytic dataset);
proc print data=out.abrahami_allmerged_dpp4i_su; where id="&id";title 'DPP4i_su out';run;

/*No record of this ID from su_trtmt or tzd_trtmt, but found records from the SGLT2i and DPP4i datasets */
proc print data=temp.su_useperiods;where id="&id";title 'SU useperiods';run;
proc print data=raw.su_trtmt;where id="&id"; title 'SU trtmt'; var id rxdate dpp4i su sglt2i tzd rx_dayssupply; run;
proc print data=raw.sglt2i_trtmt;where id="&id"; title 'SGLT2i trtmt'; var id rxdate dpp4i su sglt2i tzd rx_dayssupply; run;
proc print data=temp.sglt2i_useperiods;where id="&id"; title 'SGLT2i useperiods'; run;
proc print data=raw.dpp4i_trtmt;where id="&id"; title 'DPP4i trtmt'; var id rxdate dpp4i su sglt2i tzd rx_dayssupply; run;
proc print data=temp.dpp4i_useperiods;where id="&id"; title 'DPP4i useperiods';run;


proc print data=temp.abrahami_allmerged_dpp4i_sglt2i; where id="&id";title 'DPP4i_sglt2i temp';run;
proc print data=out.abrahami_allmerged_dpp4i_sglt2i; where id="&id";title 'DPP4i_sglt2i out';run;

proc print data=temp.abrahami_allmerged_dpp4i_tzd; where id="&id";title 'DPP4i_tzd temp';run;
proc print data=out.abrahami_allmerged_dpp4i_tzd; where id="&id";title 'DPP4i_tzd out';run;
/*ZS end*/
/**********************************************************************************************************************************************/

/*===================================*\
//SECTION - Jeanny Start
\*===================================*/
/* region */

* printing in the analyses dataset used in the dependencies; 

/* endregion //!SECTION */


%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);