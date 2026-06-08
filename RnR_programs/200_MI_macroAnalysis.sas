
options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen nosymbolgen nomlogic nomprint mcompile; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=testMI, savelog=N, dataset=dataname);

%macro runMIana(analysis, exposure, comparator, ana_name, basemodelvars,addedmodelvars, tablerowvars);
/*start*/
data tmp1;
	set  temp.&analysis._MI_&exposure._&comparator.;
/*        set a.allmerged_&exposure._&comparator._1yrlb;*/
/*Recreating the variables for analysis*/
/*Recreate alc and smoke character variable*/
smoke=''; 
if smoke_miss=3 then smoke='c';
else if smoke_miss=2 then smoke='n';
else if smoke_miss=1 then smoke='x';

alc='';
if alc_miss=1 then alc='c';
else if alc_miss=2 then alc='n';
else if alc_miss=3 then alc='x';

	format smoke alc statusf.;
/*	recreate sex character variable*/
	if sex_num=1 then sex='f';
	else if sex_num=0 then sex='m';
/*Coding HBA1c and BMI categories from the imputed variables*/
/* HBa1c is in mmol per mol, */
	* change to all year lookback;
    hba1c_cat=.;
    *if hba1ctime<365.25 then do;
        if hba1c eq . then hba1c_cat=.; 
        else if hba1c le 53 then hba1c_cat=1; /* 7% ~ 53 mmol per mol  */
        else if hba1c gt 53 and hba1c le 64 then hba1c_cat=2 ; /* 8% ~ 64 mmol per mol */
        else if hba1c gt 64 then hba1c_cat=3; /* gt 8% or 64 mmol per mol  */
        *end;
    hba1c_cat2= hba1c_cat; 
        if hba1c_cat eq . then hba1c_cat2=4;
        format hba1c_cat2 hba1cf.; 
    /* BMI */
    bmi_cat=.;
    *if bmitime<365 then do;
	* change to all year lookback;
		if bmi eq . then bmi_cat=.;
        else if bmi<25 then bmi_cat=1;
        else if bmi ge 25 and bmi lt 30 then bmi_cat=2;
        else if bmi ge 30 then bmi_cat=3;
        *end;
        bmi_cat2= bmi_cat; 
        if bmi_cat eq . then bmi_cat2=4;
        format bmi_cat2 bmif.; 
run;
/*Start loop*/
%DO mipara=1 %TO 10 %BY 1;
data dsn_&mipara.; set tmp1; if _imputation_=&mipara;run;


    *  ods rtf file="&goutpath./&todaysdate.psoutput&exposure._&comparator..rtf";
    proc logistic data=dsn_&mipara. descending;
        class  entry_year (ref=first) sex (ref=first) hba1c_Cat2 (ref=first) alc (ref=first)
        smoke (ref=first) bmi_cat2(ref=first) /param=ref; 
        model &exposure. =    /*Adding further model variables and interactions VARIABLE*/
        &addedmodelvars. &basemodelvars.
        ; output out= psdsnnotrim pred=ps; run; 
/*        ods rtf close; */
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
        from dsn_&mipara.
        where &exposure=1;    
        select count(*) into : n_&comparator. 
        from dsn_&mipara.
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
 ods pdf file="&foutpath.\MI\&analysis._psplotnotrim_MI&mipara._&exposure._&comparator._&todaysdate..pdf";
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
    Table 1 untrimmed 7/25/2024 Tian added Table 1 untrimmed weighted Table 1.
    \*=================*/
    proc format; value &exposure. 0="&comparator." 1="&exposure."; run;
    proc datasets lib=work nolist nodetails; modify psdsnnotrim; 
        format &exposure. &exposure..  sex $sexf.  alc  $statusf. smoke $statusf. hba1c_cat2  hba1cf. bmi_cat2 bmif.;
        run;
    %LET wgtvar=smrw;
    %let ds = psdsnnotrim ;
    %let colVar = &exposure.;
    %let rowVars = &tablerowvars. ;
    %LET outname = Table1notrim_MI&mipara._&exposure._&comparator._&todaysdate.; 
    options orientation=landscape nodate nonumber nocenter;
    %table1(inds= &ds, colVar= &colVar, rowVars= &rowVars, wgtVar= ,       maxLevels=16, outfile=tmp, title=&outname, cellsize=5);
    title ;
    data tab1_unwgt_&exposure.; 
        set final; run;
    proc datasets lib=work nolist nodetails; delete final; run; quit;
    %table1(inds= &ds, colVar= &colVar, rowVars= &rowVars, wgtVar= &wgtvar, maxLevels=16, outfile=tmp2, title=&outname, cellsize=5);
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
    ods rtf file="&toutPath.\MI\&analysis._Table1notrim_MI&mipara._&exposure._&comparator._&todaysdate..rtf";
    proc print data=table1notrim_&exposure.v&comparator. noobs label; var row &exposure &comparator sdiff &comparator._wgt sdiff_wgt; run;
    ods rtf close;

/* Get frequencies and means of imputed variables for each imputation */

ods output list=freqsmi_&mipara. ;
PROC FREQ DATA=psdsnnotrim;
TABLES dpp4i*(alc smoke hba1c_cat2 bmi_cat2)/list missing;
RUN;
 
ods output summary=meansmi_&mipara.;
proc means data =  temp.tve_mi_dpp4i_su        
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ; 
var       hba1c bmi       ; 
run;

/* Proceed with cutting the dataset for counts and final analysis */
data dsnmi; set psdsnnotrim; 
if delete_flag1=1 then delete; 
if ibd_ever=1 then delete; run;

/*proc freq data=    dsn; */
/*tables               dpp4i / list missing; */
/*run; */

ods output summary= o_futime;
proc means data =  dsnmi     
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3
maxdec=2  ; 
where delete_flag1 ne 1;
class dpp4i;  *important to use switcher_flag, not switcher variable;
var    time        ; 
run;
data o_futime; set o_futime; 
sum_py=sum;
median_py=
	compress(put((median), 6.1)) || " (" || compress(put((q1), 6.1)) || "-" || compress(put((q3), 6.1)) || ")"; 
run;
proc print ; run; 

ods output summary=o_drugdur;
proc means data =  dsnmi      
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 maxdec=2  ; 
where delete_flag1 ne 1;
class dpp4i;
var    time_drugdur        ; 
run; 
data o_drugdur;; set o_drugdur;
keep dpp4i Nobs sum_timedrug median_timedrug ;
sum_timedrug=sum;
median_timedrug=
	compress(put((median), 6.1)) || " (" || compress(put((q1), 6.1)) || "-" || compress(put((q3), 6.1)) || ")"; 
run;

/*Count num event*/
ods output summary=event;
Proc means data=dsnmi stackods sum;
   class &drug1;
   var event;
   run;

/*Rate*/
proc sort data=dsnmi; 
	by &exposure; 
run;
%let exposure=dpp4i;
%LET event = event;
%LET logtimevar = logtime;
%LET timevar = time;
proc genmod data=dsnmi;
	where delete_flag1 ne 1;
	by &exposure;
	class id;
	model &event= /dist=poisson offset=&logtimevar maxiter=100000;
	repeated subject=id;
	estimate 'rate' int 1/exp;
	ods output estimates=rate;
run;
proc print data= rate; run;
Data rate(keep=&exposure   lbetaestimate lbetalowercl lbetauppercl lbetaStderr);
    set rate;
    if Label='Exp(rate)';
	lbetaStderr=stderr;
/*    rate=compress(put((LBetaEstimate),6.1))||" ("||compress(put((LBetaLowerCL),6.1))||"-"||compress(put((LBetaUpperCL),6.1))||")";*/
    run;

/*CrudeHR*/
ods output ParameterEstimates = crudehr;
Proc phreg data=dsnmi covsandwich(aggregate);
where delete_flag1 ne 1;
    id id;
    model &timevar*&event(0)=&exposure /ties=efron rl;
    title ' crude HR';
run;
Data crudehr(keep=  &exposure chr chr_lcl chr_ucl chr_estimate chr_stderr crude_HR);
    set crudehr;
    &exposure=1;
    chr=exp(Estimate);
    chr_lcl=exp(Estimate-1.96*StdErr);
    chr_ucl=exp(Estimate+1.96*StdErr);
	chr_estimate=estimate;
	chr_stderr=stderr;
    crude_HR=compress(put((hazardratio),6.1))||" ("||compress(put((HRlowerCL),6.1))||"-"||compress(put((HRupperCL),6.1))||")";
run;

/*SMRW HR*/
%LET weight = smrw;
ods output ParameterEstimates =&WEIGHT;
proc phreg data=dsnmi covsandwich(aggregate);
where delete_flag1 ne 1;
    id id;
    weight &weight; 
    model  &timevar*&event(0)=&exposure  /ties=efron rl;
    title 'SMRW adjusted HR';
run;
Data &WEIGHT(keep= &exposure whr whr_lcl whr_ucl whr_estimate whr_stderr  &weight._HR);
    set &WEIGHT; 
    &exposure=1;
    whr =exp(Estimate);
	whr_estimate=estimate;
	whr_stderr=stderr;
    whr_lcl=exp(Estimate-1.96*StdErr);
    whr_ucl=exp(Estimate+1.96*StdErr);
    &weight._HR=compress(put((hazardratio),6.1))||" ("||compress(put((HRlowerCL),6.1))||"-"||compress(put((HRupperCL),6.1))||")";
run; 
/*merge output together*/
Data dsnmi_&mipara.;
   length type $ 20 variable $20 ;
   merge  o_futime event o_drugdur rate /*wtrate*/ crudehr &weight;
   by &exposure;
   mipara= &mipara.;
    analysis="MI &analysis. IT ";
    type="&ibd_def.";
   latency=&latency;
   induction=&induction;
   run;
   proc print ; run; 
/*end loop here*/
%END;

/*Summarize*/
Data temp.outmi_res_&exposure._&comparator. ;
   set dsnmi_: ;
   exp="&exposure";
   unexp="&comparator";
   label event_Sum="No. of Event"
          time_Sum = "Person-year";
   run;
   
Data temp.outmi_means_&exposure._&comparator.;
    set meansmi_: ;
   exp="&exposure";
   unexp="&comparator";RUN;

Data temp.outmi_freqs_&exposure._&comparator.;
    set freqsmi_: ;
   exp="&exposure";
   unexp="&comparator";RUN;
%mend runMIana;


;
/**/
%LET basemodelvarsi = age agesquare
sex entry_year  bmi_cat2 alc smoke hba1c_Cat2  
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever 
ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 
psorp_ever vasc_ever 
RhArth_ever SjSy_ever sLup_ever;
%LET addedmodelvarsi = oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback;
%LET tablerowvarsi = age sex entry_year  
diff_1st_2ndrx  /* added to table 1 rows, NOT in PS trimming model */
bmi_cat2 alc smoke hba1c_Cat2 
bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever  
oAntGLP_ever dpp4i_ever sglt2i_ever TZD_ever su_ever 
bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr /*num_nondmdrugs1yr_cat*/
ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 
psorp_ever vasc_ever 
RhArth_ever SjSy_ever sLup_ever ;
/*MI get estimates for each iteration*/

/* DPP4i vs. SU */
%LET addedmodelvarsi = oAntGLP_1yrlookback sglt2i_1yrlookback tzd_1yrlookback;
%runMIana(analysis=ACNU, 
exposure=dpp4i, 
comparator=SU,
ana_name=MI,
basemodelvars= &basemodelvarsi,
addedmodelvars= &addedmodelvarsi,
tablerowvars = tablerowvarsi);

%runMIana(analysis=TVE, 
exposure=dpp4i, 
comparator=SU,
ana_name=MI,
basemodelvars= &basemodelvarsi,
addedmodelvars= &addedmodelvarsi,
tablerowvars = tablerowvarsi);

/* DPP4i vs. TZD */
%LET addedmodelvarsi = oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback;
%runMIana(analysis=ACNU, 
exposure=dpp4i, 
comparator=tzd,
ana_name=MI,
basemodelvars= &basemodelvarsi,
addedmodelvars= &addedmodelvarsi,
tablerowvars = tablerowvarsi);

%runMIana(analysis=TVE, 
exposure=dpp4i, 
comparator=tzd,
ana_name=MI,
basemodelvars= &basemodelvarsi,
addedmodelvars= &addedmodelvarsi,
tablerowvars = tablerowvarsi);

/* DPP4i vs sglt2i */

%LET addedmodelvarsi = oAntGLP_1yrlookback su_1yrlookback tzd_1yrlookback;
%runMIana(analysis=ACNU, 
exposure=dpp4i, 
comparator=tzd,
ana_name=MI,
basemodelvars= &basemodelvarsi,
addedmodelvars= &addedmodelvarsi,
tablerowvars = tablerowvarsi);

%runMIana(analysis=TVE, 
exposure=dpp4i, 
comparator=tzd,
ana_name=MI,
basemodelvars= &basemodelvarsi,
addedmodelvars= &addedmodelvarsi,
tablerowvars = tablerowvarsi);

/*MI look at estimates and group them together */



/*pool*/
 /* data lgshr_t; 
 set outmi_&exposure.v&comparator.; where dpp4i =1; run; */

*** Combine transformed estimates; 
/* PROC MIANALYZE DATA=lgshr_t; 
ODS OUTPUT PARAMETERESTIMATES=mian_lgshr_t; 
MODELEFFECTS whr_estimate; 
STDERR whr_stderr; 
RUN;

PROC MIANALYZE DATA=lgshr_t; 
ODS OUTPUT PARAMETERESTIMATES=mian_lgshr_tc; 
MODELEFFECTS chr_estimate; 
STDERR chr_stderr; 
RUN; */
