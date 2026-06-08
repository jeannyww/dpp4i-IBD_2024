/***************************************
SAS file name: psweighting_Ab

Purpose: macro rewritten that now includes creating Table 1 and Web Table 4 for TVE analysis 
and excludes dpp4i switchers who did not have corresponding comparator rows . 
Author: JHW
Creation Date: 2024-12-28

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
Date: Date of Change
Notes: Change Notes
***************************************/
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=psweighting_Ab, savelog=N, dataset=dataname);



/*===================================*\
//SECTION - ## 5. PS weighting adapted from 015_PSweighting.sas
\*===================================*/
/* region */

%macro psweighting_Ab ( exposure , comparator , weight , addedmodelvars ,basemodelvars , tablerowvars, refyear  , dat, save );

    data tmp1;
        set a.Abrahami_allmerged_&exposure._&comparator.;
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
proc format; value switcherf 0="puredpp4i" 1="switcher";run;
data tmptable1; 
    set tmp2; 
    where switcher_flag in (0,1);
    format switcher_flag switcherf.;
run;

ods escapechar='~' ;
ods rtf file="&toutPath./SwitcherTable_&exposure._&comparator._&todaysdate..rtf";
    proc print data=final noobs label; 
    var /*row switcher_flag su sdiff su_wgt sdiff_wgt*/
		row switcher puredpp4i total order rowOrder sdiff ; run;
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
    ods pdf file= "&foutpath./psplot_TVE_untrimmed_&exposure._&comparator._&todaysdate..pdf";
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
    ods rtf file="&toutPath./TVE_Table1notrim_&exposure._&comparator._&todaysdate..rtf";
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
    ods rtf file="&goutpath./TVE_psoutputTRIM_&exposure._&comparator.&todaysdate..rtf";
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
    ods pdf file="&foutpath./psplot_TVE_trimmed_&exposure._&comparator._&todaysdate..pdf";
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
        data a.Abrahami_Notrim_&exposure._&comparator.; set psdsnnotrim; run;
        /* Saving PS trimmed cohort for sensitivity analyses */
        data a.Abrahami_PS_&exposure._&comparator.; set psdsn; run;

        PROC SQL; 
            create table tmp_counts as select * from temp.Abexclusions_014_&exposure._&comparator.;
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
            create table temp.Abexclusions_015_&exposure._&comparator. as select * from tmp_counts;
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
    ods rtf file="&toutPath./TVE_Table1trim_&exposure._&comparator._&todaysdate..rtf";
    proc print data=table1_&exposure.v&comparator. noobs label; var row &exposure &comparator sdiff &comparator._wgt sdiff_wgt; run;
    ods rtf close;

%mend psweighting_Ab;

/* endregion //!SECTION */


%CheckLog( ,ext=LOG,subdir=N,keyword=,exclude=,out=temp.Log_issues,pm=N,sound=N,relog=N,print=Y,to=,cc=,logdef=LOG,dirext=N,shadow=Y,abort=N,test=);