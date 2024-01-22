/***************************************
SAS file name: 15_PSweighting.sas

Purpose: PS weighting and T1 for each ANCU Cohort
Author: JHW
Creation Date: 2024-01-07

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
%setup(programName=15_PSweighting, savelog=N, dataset=tmp);

/*===================================*\
//SECTION - Macro
\*===================================*/
/* region */

%macro psweighting ( exposure , comparator , weight , addedmodelvars ,basemodelvars , tablerowvars, refyear  , dat, save );

    data tmp1;
        set a.allmerged_&exposure._&comparator.;
    RUN;

    /*=================*\
    PS weighting
    \*=================*/
    *%removeMetadata(tmp1);


    *  ods rtf file="&goutpath./&todaysdate.psoutput&exposure._&comparator..rtf";
    proc logistic data=tmp1 descending;
        class  entry_year (ref="&refyear.") sex (ref=first) hba1c_Cat2 (ref=first) alcohol_cat (ref=first)
        smoke_cat (ref=first) bmi_cat2(ref=first) /param=ref; 
        model &exposure. =    /*Adding further model variables and interactions VARIABLE*/
        &addedmodelvars. &basemodelvars.
        ; output out= psdsnnotrim pred=ps; run; 
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
        from tmp1
        where &exposure=1;    
        select count(*) into : n_&comparator. 
        from tmp1
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
    filename grafout "&foutpath./psplot_&exposure._&comparator.&todaysdate..tiff";
    symbol1 interpol=spline value=none line=1;
    symbol2 interpol=spline value=none line=2;
    axis1 order=(0 to 1 by 0.1) minor=none label=(a=0 j=c h=1.5 f=swiss 'Propensity Score') value=(h=1.1 f=swiss);
    axis2 minor=(n=1) label=(a=90 j=c h=1.5 f=swiss 'Density') value=(h=1.1 f=swiss);
    title "Untrimmed PS distribution for &exposure. use, by treatment status";
    proc gplot data=psplot;
        plot density*value=pop / haxis=axis1 vaxis=axis2;
        run; quit;
        title;
        /* Printing untrimmed psplot */
    goptions reset=all device=png targetdevice=png gsfname=grafout gsfmode=replace;
    filename grafout "&foutpath./psplot_&exposure._&comparator.&todaysdate..png";
    symbol1 interpol=spline value=none line=1;
    symbol2 interpol=spline value=none line=2;
    axis1 order=(0 to 1 by 0.1) minor=none label=(a=0 j=c h=1.5 f=swiss 'Propensity Score') value=(h=1.1 f=swiss);
    axis2 minor=(n=1) label=(a=90 j=c h=1.5 f=swiss 'Density') value=(h=1.1 f=swiss);
    title "Untrimmed PS distribution for &exposure. use, by treatment status";
        proc gplot data=psplot;
            plot density*value=pop / haxis=axis1 vaxis=axis2;
            run; quit;
            title;
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
    /* check for treatment effect heterogeneity */
    data psdsn; set psdsnnotrim; 
        where &treated_005 <= ps <= &untreated_995;RUN;
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
    ods rtf file="&goutpath./psoutputTRIM_&exposure._&comparator.&todaysdate..rtf";
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
    filename grafout "&foutpath./psplot_trim_&exposure._&comparator.&todaysdate..tiff";
    symbol1 interpol=spline value=none line=1;
    symbol2 interpol=spline value=none line=2;
    axis1 order=(0 to 1 by 0.1) minor=none label=(a=0 j=c h=1.5 f=swiss 'Propensity Score') value=(h=1.1 f=swiss);
    axis2 minor=(n=1) label=(a=90 j=c h=1.5 f=swiss 'Density') value=(h=1.1 f=swiss);
    title "Trimmed PS distribution for &exposure. use, by treatment status";
    proc gplot data=psplot_trim;
        plot density*value=pop / haxis=axis1 vaxis=axis2;
        run; quit;
        title;
    goptions reset=all device=png targetdevice=png gsfname=grafout gsfmode=replace;
    filename grafout "&foutpath./psplot_trim_&exposure._&comparator.&todaysdate..png";
    symbol1 interpol=spline value=none line=1;
    symbol2 interpol=spline value=none line=2;
    axis1 order=(0 to 1 by 0.1) minor=none label=(a=0 j=c h=1.5 f=swiss 'Propensity Score') value=(h=1.1 f=swiss);
    axis2 minor=(n=1) label=(a=90 j=c h=1.5 f=swiss 'Density') value=(h=1.1 f=swiss);
    title "Trimmed PS distribution for &exposure. use, by treatment status";
    proc gplot data=psplot_trim;
        plot density*value=pop / haxis=axis1 vaxis=axis2;
        run; quit;
        title;
    * check univariate analysis on weight variables by treatment status, check for extreme weights;
    proc univariate data=psdsn ; class &exposure.; var iptw siptw smrw smrwu ssmrwu; run; 

    /*=================*\
    Save Point`
    \*=================*/
    %if &save. = Y %then %do;
        data a.PS_&exposure._&comparator.; set psdsn; run;
        /* Updating exclusions for PS trimming */
        PROC SQL; 
            create table tmp_counts as select * from temp.exclusions_014_&exposure._&comparator.;
            select count(*) into : num_obs from tmp_counts;
            insert into tmp_counts
                set exclusion_num=&num_obs+1, 
                long_text="Number of observations after trimming at 0.05 treated and 0.995 untreated",
                dpp4i=&&n_&exposure._trim,
                dpp4i_diff=&&n_&exposure._trim-&&n_&exposure.,
                &comparator.=&&n_&comparator._trim,
                &comparator._diff=&&n_&comparator._trim-&&n_&comparator., 
                full=&&n_&exposure._trim+&&n_&comparator._trim;
            create table temp.exclusions_015_&exposure._&comparator. as select * from tmp_counts;
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
    %LET outname = Table1_&exposure._&comparator._&todaysdate.; 
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
    ods rtf file="&toutPath./Table1trim_&exposure._&comparator._&todaysdate..rtf";
    proc print data=table1_&exposure.v&comparator. noobs label; var row &exposure &comparator sdiff &comparator._wgt sdiff_wgt; run;
    ods rtf close;

    %mend psweighting;

/* endregion //!SECTION */
/* endregion //!SECTION */

/*===================================*\
//SECTION - Execute Macro 
PS weighting with Abrahami covariates:
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
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever /* duration_metformin */ bigua_ever SU_ever TZD_ever insulin_ever /* other oad  */ dpp4i_ever sglt2i_ever prand_ever agluco_ever OAntGLP_ever    /* other */ ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever /* Autoimmune */psorp_ever vasc_ever RhArth_Ever SjSy_Ever sLup_ever /* other drugs */num_nondmdrugs1yr num_nondmdrugs1yr_cat;


%LET interactions =     /* add interaction */ ;
%LET basevars =  age|age  sex entry_year   bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever bigua_ever insulin_ever prand_ever agluco_ever OAntGLP_ever ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever psorp_ever vasc_ever RhArth_Ever SjSy_Ever sLup_ever num_nondmdrugs1yr ;
%let basemodelvars= &basevars. &interactions. ;
%let tablerowvars= &tablerowvarsi;


*  %let addedmodelvars= &addedDPP4ivSU;
*  %LET exposure = dpp4i;
*  %LET comparator = su;
*  %LET refyear = 2015;

%LET addedDPP4ivSU = oAntGLP_1yrlookback sglt2i_1yrlookback TZD_1yrlookback;
%psweighting ( exposure= dpp4i ,
comparator= SU, 
weight= smrw, 
addedmodelvars= &addedDPP4ivSU, 
basemodelvars= &basevars. &interactions. ,
tablerowvars= &tablerowvarsi,
refyear = 2015, 
save= Y);

%LET addedDPP4ivTZD = oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback chf_ever;
%psweighting(exposure=dpp4i,
comparator=TZD, 
weight=smrw,
addedmodelvars= &addedDPP4ivTZD,
basemodelvars= &basevars. &interactions,
tablerowvars=&tablerowvarsi chf_ever,
refyear=2015,
save=Y
);

%LET addedDPP4ivSGLT2i = oAntGLP_1yrlookback su_1yrlookback TZD_1yrlookback;
%psweighting(exposure=dpp4i,
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
ods excel file="&toutpath./Main_T1_compiled_&todaysdate..xlsx"
    options (
        Sheet_interval="NONE"
        embedded_titles="NO"
        embedded_footnotes="NO"
    );
    *dpp4i vs su;
ods excel options(sheet_name="DPP4i_SU"  sheet_interval="NOW");
    proc print data=table1_dpp4ivSU noobs label; var row dpp4i su sdiff su_wgt sdiff_wgt; run;
ods excel options(sheet_name="DPP4i_SU_plots" sheet_interval="NOW");
    goptions iback="&foutpath./psplot_dpp4i_SU&todaysdate..png" imagestyle=fit;
    proc gslide;RUN;quit; goptions reset=all;
    goptions iback="&foutpath./psplot_trim_dpp4i_SU&todaysdate..png" imagestyle=fit;
    proc gslide;RUN; quit  ; goptions reset=all;
    ods text="PS model:  &addedDPP4ivSU.  &basevars. &interactions. ";
ods excel options(sheet_name="DPP4i_SU_flowchart" sheet_interval="NOW");
    proc print data=temp.exclusions_015_dpp4i_su noobs ; run;

    *dpp4i vs TZD;
ods excel options(sheet_name="DPP4i_TZD" sheet_interval="NOW");
    proc print data=table1_dpp4ivTZD noobs label; var row dpp4i tzd sdiff tzd_wgt sdiff_wgt; run;
ods excel options(sheet_name="DPP4i_TZD_plots" sheet_interval="NOW");
    goptions iback="&foutpath./psplot_dpp4i_TZD&todaysdate..png" imagestyle=fit;
    proc gslide;RUN;quit; goptions reset=all;
    goptions iback="&foutpath./psplot_trim_dpp4i_TZD&todaysdate..png" imagestyle=fit;
    proc gslide;RUN; quit; goptions reset=all;
    ods text="PS model:  &addedDPP4ivTZD.  &basevars. &interactions. ";
ods excel options(sheet_name="DPP4i_TZD_flowchart" sheet_interval="NOW");
    proc print data=temp.exclusions_015_dpp4i_tzd noobs ; run;

    *dpp4i vs SGLT2i;
ods excel options(sheet_name="DPP4i_SGLT2i" sheet_interval="NOW");
    proc print data=table1_dpp4ivSGLT2i noobs label; var row dpp4i sglt2i sdiff sglt2i_wgt sdiff_wgt; run;
ods excel options(sheet_name="DPP4i_SGLT2i_plots" sheet_interval="NOW");
    goptions iback="&foutpath./psplot_dpp4i_SGLT2i&todaysdate..png" imagestyle=fit;
    proc gslide;RUN;quit;    goptions reset=all;
    goptions iback="&foutpath./psplot_trim_dpp4i_SGLT2i&todaysdate..png" imagestyle=fit;
    proc gslide;RUN; quit;    goptions reset=all;
    ods text="PS model:  &addedDPP4ivSGLT2i.  &basevars. &interactions. ";
ods excel options(sheet_name="DPP4i_SGLT2i_flowchart" sheet_interval="NOW");
    proc print data=temp.exclusions_015_dpp4i_sglt2i noobs ; run;

    *log summary;
ods excel options(sheet_name="Log_issues" sheet_interval="NOW");
    proc print data=temp.Log_issues noobs ; run;
ods excel close;

ods _all_ close;
/* '; * "; */; quit; run;


