
options source source2 msglevel=I mprint mcompilenote=all mautosource nofmterr
sasautos=(SASAUTOS "/local/projects/medicare/incretinRetinopathy/programs/macros");

%setup(full, 08_primary, saveLog=N);
/************************************/
/*STEP0:Proportional Odds Assumption*/
/************************************/ 
proc freq data=dsn;
tables a1c/missing;
run;
%macro proportional(dataset, drug1, clinical, vars /*, para*/ );
proc logistic data=&dataset descending  ;
	where &clinical NE . /*and &drug1.=&para.*/;
	class    /*agecat(ref='0') DPPvsSU: AIC for Quadratic=85718.799 < AIC for Categorical=85719.209, thus use Quadratic */
			racecat(reference=first) ervisit(reference=first) hosp(reference=first) phvisit(reference=last) 
			year(reference=last) hba1c (reference=last) lipid (reference=last) hyperglycemia(reference=first)
			hospnoDM(reference=first) /*hospdaysDM(ref=first)*/ 
			ervisitDM(reference=first) eyeexam(reference=last)
			/*a1c(ref=first) sbp(ref=first) dbp(ref=first) ldl(ref=first)*/
			/param=reference;
   model &clinical = 
age|age gender   
bl_diabRetinopathy bl_nephropathy bl_neuropathy 
bl_amd bl_retinadeta bl_oretinal bl_cataract bl_glaucoma bl_ANYEDZEX_CAGDODT
bl_hypertension bl_dyslipidemia bl_ischemichtdz bl_cerebrovasculardz bl_peripheralvdz bl_COPD bl_DEPRESSION bl_cancer bl_ckd
&vars 
bl_METFORMIN bl_agi bl_meglitinide bl_ACEI bl_ARB bl_BB bl_CCB bl_STATIN bl_LOOP bl_OTHERDIURETICS bl_fenofibrate bl_ANYBADRX
racecat
year hyperglycemia 
eyeexam /*hba1c lipid*/ hospnoDM /*hospdaysDM*/ ervisitDM phvisit /*hospno hosp*/ ervisit flushot
lics
 &drug1 event/scale=none aggregate /*link=glogit*/ 
/*/unequalslopes equalslopes*/
;
run;
%mend;
*GLP vs LAI;
%proportional (dsn, glp, a1c,   bl_dpp bl_TZD bl_SULF        bl_chf);*GLP group, P=0.1856;
%proportional (dsn,glp, sbp, bl_dpp bl_TZD bl_SULF         bl_chf);*GLP group, P=0.1497;
%proportional (dsn,glp, dbp, bl_dpp bl_TZD bl_SULF         bl_chf);*GLP group, P=0.3327;
%proportional (dsn,glp, ldl, bl_dpp bl_TZD bl_SULF         bl_chf);*GLP gorup, P=0.1975;

%proportional (dsn, glp, a1c_30, bl_dpp bl_TZD bl_SULF        bl_chf);
%proportional (dsn,glp, sbp_30, bl_dpp bl_TZD bl_SULF         bl_chf);
%proportional (dsn,glp, dbp_30, bl_dpp bl_TZD bl_SULF         bl_chf);
%proportional (dsn,glp, ldl_30, bl_dpp bl_TZD bl_SULF         bl_chf);


*tried to keep only key variables such as age, sex, diabetes complications, exposure, outcome, but still violate proportional odds assumption!!!;

/****************************/
/*STEP1:MISSING data Pattern*/
/****************************/
%macro mpattern (dataset,drug1,clinical, vars);
proc mi nimpute=0 data=&dataset simple;
/*where &drug1.=&para;*/
var age agesquare gender    
bl_diabRetinopathy bl_amd bl_retinadeta bl_oretinal bl_cataract bl_glaucoma bl_ANYEDZEX_CAGDODT bl_nephropathy bl_neuropathy
bl_hypertension bl_dyslipidemia bl_ischemichtdz bl_cerebrovasculardz bl_peripheralvdz bl_COPD bl_DEPRESSION bl_cancer bl_ckd
 &vars bl_METFORMIN bl_agi bl_meglitinide bl_ACEI bl_ARB bl_BB bl_CCB bl_STATIN bl_LOOP bl_OTHERDIURETICS bl_fenofibrate bl_ANYBADRX
&clinical
racecat year
hyperglycemia eyeexam /*hba1c lipid*//* hospnoDM*/ /*hospdaysDM*/ ervisitDM phvisit /*hospno hosp*/ ervisit flushot lics
event &drug1.;
run;
%mend;

/*GLP vs LAI*/
%mpattern (dsn, glp, 
a1c ldl sbp dbp, 
bl_dpp bl_TZD bl_SULF bl_chf);

%mpattern (dsn,glp, 
a1c_30 ldl_30 sbp_30 dbp_30, 
bl_dpp bl_TZD bl_SULF bl_chf);

/*DPP vs SU*/
%mpattern (dsn, dpp, 
a1c ldl sbp dbp, 
bl_chf bl_glp bl_TZD bl_LAI);

proc contents data=psdsn;run;
proc freq data=psdsn; tables event/missing; run;

/*********************************************************************/
/**STEP2: ADDING NELSON-AALEN timing, prepare dataset for MI**********/
/*********************************************************************/
** multiple imputation for baseline covariates in survival;
* estimate Nelson-Aalen estimator for cumalative hazard;
ods output productlimitestimates=out;
proc lifetest data=dsn nelson;
  time time*event(0); * time*event();
run;

/* proc print data=out (obs=5); var time cumhaz; run;

proc freq data=out;
where cumhaz eq .;
tables cumhaz/missing;run; */
 
* only keep the non-missing values for cumulative hazard;
data out1;
      set out;
      if cumhaz ne .;
run;

* sort the datasets (main dataset and Nelson-Aalen estimator dataset);
proc sort data=dsn; by time;
proc sort data=out1; by time; run;

* merge these two datasets;
data comb_4;
      merge dsn (in=in) out1 (keep=time cumhaz);         
      by time;
      if in;
      retain cum 0;
    if cumhaz eq . then cumhaz = cum; * plug in most recent value of cumhaz if missing;
    cum = cumhaz;
      drop cum;
run;

proc print data=comb_4 (obs=100); var time cumhaz;run;
proc freq data=comb_4;tables cumhaz/missing;run;
* multiple imputation by chained equations;

/**********************************************/
/**STEP3: MUTIPLE IMPUTAION NORMINALI**********/
/**********************************************/
%macro mimputation (dataset,outdata, drug1, drug2, clinical, vars);
proc mi data=&dataset nimpute=50 seed=20160413 out=ana.&outdata._&drug1.v&drug2;
CLASS 
gender  bl_diabRetinopathy bl_amd bl_retinadeta bl_oretinal bl_cataract bl_glaucoma bl_ANYEDZEX_CAGDODT bl_nephropathy bl_neuropathy 
bl_hypertension bl_dyslipidemia bl_ischemichtdz bl_cerebrovasculardz bl_peripheralvdz bl_COPD bl_DEPRESSION bl_cancer bl_ckd 
&vars 
bl_METFORMIN bl_agi bl_meglitinide bl_ACEI bl_ARB bl_BB bl_CCB bl_STATIN bl_LOOP bl_OTHERDIURETICS bl_fenofibrate bl_ANYBADRX
&clinical racecat year hyperglycemia eyeexam /*hba1c lipid*/ hospnoDM /*hospdaysDM hosp  hospno*/ 
/*ervisitDM*/ phvisit ervisit flushot lics
event &drug1.;

fcs nbiter=10
logistic(&clinical/details link=glogit likelihood=augment);       

VAR /*MI command, not &vars!*/ 
age agesquare gender bl_diabRetinopathy bl_nephropathy bl_neuropathy bl_amd bl_retinadeta bl_oretinal bl_cataract bl_glaucoma bl_ANYEDZEX_CAGDODT
bl_hypertension bl_dyslipidemia bl_ischemichtdz bl_cerebrovasculardz bl_peripheralvdz bl_COPD bl_DEPRESSION bl_cancer bl_ckd
&vars 
bl_METFORMIN bl_agi bl_meglitinide bl_ACEI bl_ARB bl_BB bl_CCB bl_STATIN bl_LOOP bl_OTHERDIURETICS bl_fenofibrate bl_ANYBADRX
&clinical racecat year hyperglycemia eyeexam 
/*hba1c lipid*/ hospnoDM /*hospdaysDM hosp hospno can't use!!!*/
/*ervisitDM*/ 
phvisit 

ervisit flushot lics 
event &drug1. cumhaz;
run;
%mend;
*WARNING: An effect for variable a1c/sbp/dbp/ldl is a linear combination of effects, thus check if one variable predict the other;
proc freq data=dsn; tables hospnoDM*hospdaysDM hospnoDM*hospno hosp*hospno; run;
*after removing variable hospdaysDM and hospno, still shows the followin warning: 
WARNING: An effect for variable a1c/ldl is a linear combination of effects, thus check if one variable predict the other;
proc freq data=dsn; tables hosp*hospnoDM hyperglycemia*hba1c; run;
*after removing variable hosp, still shows the followin warning: 
WARNING: An effect for variable a1c/ldl is a linear combination of effects, thus check if one variable predict the other;
proc freq data=dsn; tables hba1c*a1c lipid*ldl bl_amd*eyeexam; run;

proc freq data=dsn; tables bl_ischemichtdz*bl_peripheralvdz ; run;
proc freq data=dsn; tables bl_ischemichtdz*bl_cerebrovasculardz  ; run;
*after removing variable hba1c and lipid, no more WARNING!; 


%mimputation (dsn, dsn2, dpp, su,
a1c  sbp  dbp ldl, 
bl_chf bl_glp bl_TZD bl_LAI );

%mimputation (dsn, dsn2,	glp, lai, a1c  	 sbp    dbp	   ldl,    bl_dpp bl_TZD bl_SULF bl_chf);

/*cheating SAS MI for those with clincial data*/
%mimputation (dsn, dsn_glogit,	 glp, lai, a1c  	 sbp    dbp	   ldl,    bl_dpp bl_TZD bl_SULF bl_chf);
/*ignore other clinical data*/
%mimputation (dsn, dsn_glogit_a1c,glp, lai, a1c  	 				  ,    bl_dpp bl_TZD bl_SULF bl_chf);
/*adding time*/
%mimputation (comb_4, dsn_glogit_t,	 glp, lai, a1c  	 sbp    dbp	   ldl,    bl_dpp bl_TZD bl_SULF bl_chf);
/*increase iteration No.*/
%mimputation (dsn, dsn_glogit_50,glp, lai, a1c  	 sbp    dbp	   ldl,    bl_dpp bl_TZD bl_SULF bl_chf);

/*Adding time & increase iteration No=20., No=50 never works!*/
%mimputation (comb_4, glogit_t50a1c,     glp, lai, a1c                             ,   bl_dpp bl_TZD bl_SULF bl_chf);
/*30d_t*/
%mimputation (comb_4, glogit_t50a1c_30,  glp, lai, a1c_30                          ,   bl_dpp bl_TZD bl_SULF bl_chf);
/*uf_t*/
%mimputation (comb_4, glogit_t50a1c_uf,  glp, lai, a1c_uf                          ,   bl_dpp bl_TZD bl_SULF bl_chf);
/*30uf_t*/
%mimputation (comb_4, glogit_t50a1c_30uf,glp, lai, a1c_30uf                        ,   bl_dpp bl_TZD bl_SULF bl_chf);

*sensitivity analysis, inlcuding sbp, dbp, ldl;
%mimputation (comb_4, glogit_t20,     glp, lai, a1c      sbp      dbp	   ldl	 ,  bl_dpp bl_TZD bl_SULF bl_chf);

%mimputation (dsn, glogit_30,   glp, lai, a1c_30   sbp_30   dbp_30   ldl_30,   bl_dpp bl_TZD bl_SULF bl_chf);


/*30uf_t_a1conly*/
%mimputation (comb_4, dsn_glogit_30uf_t_a1c, glp, lai, a1c_30uf 						  , bl_dpp bl_TZD bl_SULF bl_chf);

%mimputation (dsn,dsn2,glp,tzd, bl_dpp        bl_SULF  bl_lai);


*impute_a1c=0 N=37145, impute_a1c=1 N=368660, impute_a1c=9 N=37145, impute_a1c=9 N=37145;
/*******************/
/*check sensitivity*/
/*******************/
proc freq data=ana.dsn_glogit_cumhaz_glpvlai;tables a1c impute_a1c  impute_a1c_mi  a1c_mi/missing;run;
proc freq data=ana.anadata_glpvlai_mi;tables a1c impute_a1c  impute_a1c_mi  a1c_mi/missing;run;
proc freq data=dsn;tables a1c impute_a1c  impute_a1c_mi  a1c_mi/missing;run;

%macro misensitivity (method,analysis, var, flag, newflag, mivar);
/*combine and RENAME variables to make 2*2 table later*/
data ana.MI0_&method._&var ana.MI9_&method._&var (rename=(&flag=&newflag &var=&mivar));
    set ana.dsn_&method._&analysis._glpvlai(keep=&var &flag bene_id);
     if &flag=0 then output ana.MI0_&method._&var /*true value*/;
else if &flag=9 then output ana.MI9_&method._&var /*imputed value*/;
run;

proc sort data=ana.MI0_&method._&var; by bene_ID;run;
proc sort data=ana.MI9_&method._&var; by bene_ID;run;

/*combine dataset w/ true and dataset w/ imputed value*/
data ana.MI_&method._&var;
	merge ana.MI0_&method._&var ana.MI9_&method._&var;
	by bene_id;
run;

proc sgplot data=ana.MI_&method._&var;
scatter x=&var Y=&mivar;
run;
ODS rtf FILE="&outpath./accuracy_&method._&analysis._%sysfunc(date(),date.).rtf";
proc freq data=ana.MI_&method._&var;
tables &var*&mivar/nocol nopercent;
ODS rtf close;
run;
%mend;

%misensitivity (glogit, prim,  	   a1c,      impute_a1c,      impute_a1c_mi,      a1c_mi);
%misensitivity (glogit, t,	   	   a1c,      impute_a1c,      impute_a1c_mi,      a1c_mi);
%misensitivity (glogit, 50,    	   a1c,      impute_a1c,      impute_a1c_mi,      a1c_mi);
%misensitivity (glogit, 30uf_t_a1c,a1c_30uf, impute_a1c_30uf, impute_a1c_30uf_mi, a1c_30uf_mi);
%misensitivity (glogit, a1c,   a1c,      impute_a1c,      impute_a1c_mi,      a1c_mi);
%misensitivity (vio,    prim,  a1c,      impute_a1c,      impute_a1c_mi,      a1c_mi);
%misensitivity (glogit, 30,    a1c_30,   impute_a1c_30,   impute_a1c_30_mi,   a1c_30_mi);
%misensitivity (vio,    30,    a1c_30,   impute_a1c_30,   impute_a1c_30_mi,   a1c_30_mi);
%misensitivity (glogit, 30uf,  a1c_30uf, impute_a1c_30uf, impute_a1c_30uf_mi, a1c_30uf_mi);
%misensitivity (vio,    30uf,  a1c_30uf, impute_a1c_30uf, impute_a1c_30uf_mi, a1c_30uf_mi);

/*iternation=5,GLOGIT, clinical data missing*/
data a1c;
   input true $ prediction $ count;
   datalines;
a1cless7 a1cless7 3012
a1cless7 a1c7to9 4302
a1cless7 a1cover9 2311
a1c7to9 a1cless7 4363
a1c7to9 a1c7to9 8391
a1c7to9 a1cover9 4616
a1cover9 a1cless7 2410
a1cover9 a1c7to9 4623
a1cover9 a1cover9 3117
;
run;

data a1c_ordinal;
   input true $ prediction $ count;
   datalines;
a1cless7 a1cless7 2934
a1cless7 a1c7to9 4506
a1cless7 a1cover9 2185
a1c7to9 a1cless7 4414
a1c7to9 a1c7to9 8099
a1c7to9 a1cover9 4857
a1cover9 a1cless7 2269
a1cover9 a1c7to9 4708
a1cover9 a1cover9 3173
;
run;

data a1c_30;
   input true $ prediction $ count;
   datalines;
a1cless7 a1cless7 730
a1cless7 a1c7to9 1267
a1cless7 a1cover9 883
a1c7to9 a1cless7 1243
a1c7to9 a1c7to9 3536
a1c7to9 a1cover9 2471
a1cover9 a1cless7 853
a1cover9 a1c7to9 2406
a1cover9 a1cover9 2051
;
run;
data a1c_30_ordinal;
   input true $ prediction $ count;
   datalines;
a1cless7 a1cless7 676
a1cless7 a1c7to9 1324
a1cless7 a1cover9 862
a1c7to9 a1cless7 1483
a1c7to9 a1c7to9 3353
a1c7to9 a1cover9 2414
a1cover9 a1cless7 840
a1cover9 a1c7to9 2443
a1cover9 a1cover9 2027
;
run;

data a1c_30uf;
   input true $ prediction $ count;
   datalines;
a1cless7 a1cless7 778
a1cless7 a1c7to9 1291
a1cless7 a1cover9 771
a1c7to9 a1cless7 1291
a1c7to9 a1c7to9 3508
a1c7to9 a1cover9 2326
a1cover9 a1cless7 908
a1cover9 a1c7to9 2390
a1cover9 a1cover9 1907
;
run;

data a1c_30uf_t;
   input true $ prediction $ count;
   datalines;
a1cless7 a1cless7 803
a1cless7 a1c7to9 1327
a1cless7 a1cover9 875
a1c7to9 a1cless7 1328
a1c7to9 a1c7to9 3560
a1c7to9 a1cover9 2377
a1cover9 a1cless7 951
a1cover9 a1c7to9 2308
a1cover9 a1cover9 2101
;
run;

data a1c_30uf_t_a1c;
   input true $ prediction $ count;
   datalines;
a1cless7 a1cless7 825
a1cless7 a1c7to9 1264
a1cless7 a1cover9 916
a1c7to9 a1cless7 1403
a1c7to9 a1c7to9 3443
a1c7to9 a1cover9 2419
a1cover9 a1cless7 911
a1cover9 a1c7to9 2358
a1cover9 a1cover9 2091
;
run;

data a1c_30uf_ordinal;
   input true $ prediction $ count;
   datalines;
a1cless7 a1cless7 715
a1cless7 a1c7to9 1331
a1cless7 a1cover9 794
a1c7to9 a1cless7 1361
a1c7to9 a1c7to9 3329
a1c7to9 a1cover9 2435
a1cover9 a1cless7 882
a1cover9 a1c7to9 2276
a1cover9 a1cover9 2047
;
run;

/*iternation=5,GLOGIT, clinical data missing*/
data a1c_t;
   input true $ prediction $ count;
   datalines;
a1cless7 a1cless7 3366
a1cless7 a1c7to9 4418
a1cless7 a1cover9 2481
a1c7to9 a1cless7 4540
a1c7to9 a1c7to9 8570
a1c7to9 a1cover9 4885
a1cover9 a1cless7 2670
a1cover9 a1c7to9 4686
a1cover9 a1cover9 3299
;
run;
/*iternation=50,GLOGIT, clinical data missing*/
data a1c_50;
   input true $ prediction $ count;
   datalines;
a1cless7 a1cless7 32793
a1cless7 a1c7to9 44351
a1cless7 a1cover9 25506
a1c7to9 a1cless7 45313
a1c7to9 a1c7to9 85831
a1c7to9 a1cover9 48806
a1cover9 a1cless7 26084
a1cover9 a1c7to9 47534
a1cover9 a1cover9 32932
;
run;

/*iternation=50,GLOGIT, clinical data missing*/
data a1c_t20;
   input true $ prediction $ count;
   datalines;
a1cless7 a1cless7 32381
a1cless7 a1c7to9 44322
a1cless7 a1cover9 25947
a1c7to9 a1cless7 45196
a1c7to9 a1c7to9 86285
a1c7to9 a1cover9 48469
a1cover9 a1cless7 25771
a1cover9 a1c7to9 48100
a1cover9 a1cover9 32679
;
run;
%macro kappa(dataset);
ods graphics /imagename="agree_&dataset._%sysfunc(date(),date.)" imagefmt=tiff;
ods listing style=mystyle gpath="&OutPath.";  
proc freq data=&dataset order=data;
   tables true*prediction /
          agree noprint plots=agreeplot;
   test kappa;
   weight count;
run;
ods graphics off;
%mend;
%kappa (a1c)
%kappa (a1c_t)
%kappa (a1c_t50)
%kappa (a1c_ordinal)
%kappa (a1c_30)
%kappa (a1c_30_ordinal)
%kappa (a1c_30uf)
%kappa (a1c_30uf_t)
%kappa (a1c_30uf_t_a1c)
%kappa (a1c_30uf_ordinal)





%macro output (method1,method2,var,mivar);
ods rtf file="&outpath./sensitivity_&var..rtf";
proc freq data=ana.MI_&method1._&var;
tables &var*&mivar/nocol nopercent;
run;

proc freq data=ana.MI_&method2._&var;
tables &var*&mivar/nocol nopercent;
run;
ods rtf close;
%mend;
%output (glogit,vio,a1c,     a1c_mi);
%output (glogit,vio,a1c_30,  a1c_30_mi);
%output (glogit,vio,a1c_30uf,a1c_30uf_mi);


proc freq data=ana.anadata_glpvlai_mi_30uf; 
tables a1c_30uf*impute_a1c_30uf/missing;
run; 
proc freq data=ana.dsn_glogit_glpvlai; 
tables a1c*impute_a1c/missing;
run; 

proc contents data=ana.MI0_a1c_glogit;run;*N=37415;
proc freq data=ana.MI0_a1c_glogit; tables a1c*impute_a1c;run;
proc contents data=ana.MI9_a1c_glogit;run;*N=37415;

proc contents data=ana.MI_a1c_glogit;run;*N=37415;
proc print data=ana.MI_a1c_glogit(obs=5);run; 

/************************************/
/****check correlation***************/
/************************************/
%macro corr(drug1,clinical, vars);
ods graphics on;
title 'measures of association';
proc corr data=dsn pearson spearman kendall hoeffding plots=matrix(histogram);
	var age gender bl_diabRetinopathy bl_nephropathy bl_neuropathy bl_amd bl_retinadeta bl_oretinal bl_cataract bl_glaucoma bl_ANYEDZEX_CAGDODT
bl_hypertension bl_dyslipidemia bl_ischemichtdz bl_cerebrovasculardz bl_peripheralvdz bl_COPD bl_DEPRESSION bl_cancer bl_ckd
&vars bl_METFORMIN bl_agi bl_meglitinide bl_ACEI bl_ARB bl_BB bl_CCB bl_STATIN bl_LOOP bl_OTHERDIURETICS bl_fenofibrate bl_ANYBADRX
&clinical
racecat year hyperglycemia eyeexam hba1c lipid hospnoDM hospdaysDM ervisitDM phvisit hospno hosp ervisit flushot lics 
event &drug1.;
run;
ods graphics off;
%mend;
%corr(dpp, a1c ldl sbp dbp, bl_chf bl_glp bl_TZD bl_LAI); 

%corr(glp, a1c_30 ldl_30 sbp_30 dbp_30, bl_dpp bl_TZD bl_SULF bl_chf); 



proc freq data=ana.dsn2_glpvlai;tables a1c*glp sbp*glp dbp*glp ldl*glp;run;



/*******************************************************/
/**STEP3: CHOOSE the MODE value (skip for now)**********/
/*******************************************************
proc print data=ana.dsn2 (obs=20);run;
proc contents data=ana.dsn2 ;run; 
proc freq data=dsn2;
by bene_id;
tables a1c / out=dsn3;
run;
proc sort data=dsn3;
by bene_id count;
run;
data dsn4;
    set dsn3;
    by bene_id;
    if last.bene_id then output;
run;
/****************************************/
/**STEP4: ANALYSIS***********************/
/****************************************/
%macro mianalysis (dataset,para, clinical,drug1, drug2);
proc freq data=ana.&dataset._&drug1.v&drug2.;
by _imputation_;
tables &clinical /nofreq;
where &drug1=&para;
ods output onewayfreqs=&dataset._freqs;

data &dataset._se;
set &dataset._freqs;
stderr=sqrt(percent*(100-percent)/199);
run;

proc sort data=&dataset._se;
by &clinical _imputation_;
run;

proc mianalyze data=&dataset._se edf=100;
by &clinical; modeleffects percent; stderr stderr;
ods output 
parameterestimates = &dataset._mianalyze_parms 
varianceinfo       = &dataset._minalyze_varinfo;
run;

ODS csv FILE="&outpath./imputation_&drug1.v&drug2._&para..csv";/*modify*/
proc print data=&dataset._se ;run;
ODS csv CLOSE;

options orientation=landscape;
ODS rtf FILE="&outpath./parms_&drug1.v&drug2._&para..rtf";/*modify*/
proc print data=&dataset._mianalyze_parms ;
title "Covarites distribution";
run;
ODS rtf CLOSE;

ODS csv FILE="&outpath./varinfo_&drug1.v&drug2._&para..csv";/*modify*/
proc print data=&dataset._minalyze_varinfo;run;
ODS csv CLOSE;
%mend;
%mianalysis (dsn2,1, a1c sbp dbp ldl, dpp,su);
%mianalysis (dsn2,0, a1c sbp dbp ldl, dpp,su);

%mianalysis (dsn2,1, a1c sbp dbp ldl, dpp,tzd);
%mianalysis (dsn2,0, a1c sbp dbp ldl, dpp,tzd);

%mianalysis (dsn2,1, a1c sbp dbp ldl, glp,lai);
%mianalysis (dsn2,0, a1c sbp dbp ldl, glp,lai);

%mianalysis (dsn2,	 1, a1c sbp dbp ldl, glp,lai);
%mianalysis (dsn2,	 0, a1c sbp dbp ldl, glp,lai);
%mianalysis (dsn2_30,1, a1c_30 sbp_30 dbp_30 ldl_30, glp,lai);
%mianalysis (dsn2_30,0, a1c_30 sbp_30 dbp_30 ldl_30, glp,lai);

%mianalysis (dsn2,1, a1c sbp dbp ldl, glp,tzd);
%mianalysis (dsn2,0, a1c sbp dbp ldl, glp,tzd);

/*%mianalysis (dsn2,1,glp,tzd,glp);*/
/*%mianalysis (dsn2,0,glp,tzd,tzd);*/
proc print data=dsn2_glp(obs=10);run;


/***************************/
/****MERGE drug1 & drug2****/
/***************************/
%macro merge(outdata,drug1,drug2);
data ana.&outdata._&drug1.v&drug2;
  set ana.&outdata._&drug1.v&drug2._&drug1. ana.&outdata._&drug1.v&drug2._&drug2.;
run;
%mend;
%merge(dsn2_30,glp,lai);




