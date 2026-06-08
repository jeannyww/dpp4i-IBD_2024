options source source2 msglevel=I mprint mcompilenote=all mautosource nofmterr
sasautos=(SASAUTOS "/nearline/files/projects/medicare/incretinRetinopathy/programs/macros");

%setup(full, 13_MISD, saveLog=N)

libname lwork slibref=work server=server;

/*MI report with standardized difference*/

%let weight=smrw;

/****************************************/
/*when imputing for all labs, obswant=16*/
/****************************************/
proc datasets library=work kill;run;
%let obswant=16;
data labvar;
  length variable $ 20;
  input variable $;
datalines;
a1c
a1cless7
a1c7to9
a1cover9
sbp
sbpless130
sbp130to139
sbpover140
dbp
dbpless80
dbp80to89
dbpover90
ldl
ldlless100
ldl100to129
ldlover130
;
run;
/*****************************************/
/*when imputing for A1C only,   obswant=4*/
/*****************************************/
proc datasets library=work kill;run;
%let obswant=4;
data labvar;
  length variable $ 20;
  input variable $;
datalines;
a1c
a1cless7
a1c7to9
a1cover9
;
run;

/*only need to work on table1v for primary analysis*/

%macro labdata(drug1, drug2, weight, name, var, mi, mipara);
%DO mi=1 %TO &mipara %BY 1;
data lab_&drug1.v&drug2._&mi;
set ana.t1v_&weight._&drug1.v&drug2._&name._&mi nobs=obscount; /* ana.t1v_&weight_&drug1.v&drug2._primary_&mi nobs=obscount;*/
if _n_ gt (obscount-&obswant.);
run;

data labvar_&drug1.v&drug2._&mi;
	merge labvar lab_&drug1.v&drug2._&mi;
run;
data &var._&mi;
	set labvar_&drug1.v&drug2._&mi;
	if variable="&var"    then output &var._&mi;
run; 

data &var._&mi (keep=&drug1.n &drug1.freq &drug2.n &drug2.freq sdiff_ &drug2._wgtn &drug2._wgtfreq sdiff_wgt_);
		retain		 &drug1.n &drug1.freq &drug2.n &drug2.freq sdiff_ &drug2._wgtn &drug2._wgtfreq sdiff_wgt_;
	set &var._&mi;
   	&drug1.n        = input(substr(&drug1,      1, index(&drug1,'(')-1),      comma20.);
   	&drug1.freq     = input(SCAN(SUBSTR(&drug1,INDEX(&drug1,'(')+1), 1, ')'), percent10.);
  	&drug2.n        = input(substr(&drug2,      1, index(&drug2,'(')-1),      comma20.);
   	&drug2.freq     = input(SCAN(SUBSTR(&drug2,INDEX(&drug2,'(')+1), 1, ')'), percent10.);
	sdiff_          = input(sdiff, 8.);
   	&drug2._wgtn    = input(substr(&drug2._wgt, 1, index(&drug2._wgt,'(')-1), comma20.);
   	&drug2._wgtfreq = input(SCAN(SUBSTR(&drug2._wgt, INDEX(&drug2._wgt, '(')+1), 1, ')'),percent10.);
	sdiff_wgt_       = input(sdiff_wgt, 8.);
run; 
%END;
%mend;

/*
%labdata (dpp, su, smrw, primary, a1cless7,   1);
%labdata (dpp, su, smrw, primary, a1c7to9,    1);
%labdata (dpp, su, smrw, primary, a1cover9,   1);
%labdata (dpp, su, smrw, primary, sbpless130, 1);
%labdata (dpp, su, smrw, primary, sbp130to139,1);
%labdata (dpp, su, smrw, primary, sbpover140, 1);
%labdata (dpp, su, smrw, primary, dbpless80,  1);
%labdata (dpp, su, smrw, primary, dbp80to89,  1);
%labdata (dpp, su, smrw, primary, dbpover90,  1);
%labdata (dpp, su, smrw, primary, ldlless100, 1);
%labdata (dpp, su, smrw, primary, ldl100to129,1);
%labdata (dpp, su, smrw, primary, ldlover130, 1);


%labdata (dpp, tzd, smrw, primary, a1cless7,   1);
%labdata (dpp, tzd, smrw, primary,  a1c7to9,    1);
%labdata (dpp, tzd, smrw, primary,  a1cover9,   1);
%labdata (dpp, tzd, smrw, primary,  sbpless130, 1);
%labdata (dpp, tzd, smrw, primary,  sbp130to139,1);
%labdata (dpp, tzd, smrw, primary,  sbpover140, 1);
%labdata (dpp, tzd, smrw, primary,  dbpless80,  1);
%labdata (dpp, tzd, smrw, primary,  dbp80to89,  1);
%labdata (dpp, tzd, smrw, primary,  dbpover90,  1);
%labdata (dpp, tzd, smrw, primary,  ldlless100, 1);
%labdata (dpp, tzd, smrw, primary,  ldl100to129,1);
%labdata (dpp, tzd, smrw, primary,  ldlover130, 1);*/


%labdata (glp, lai, smrw, primary,  a1cless7,   1, 50);
%labdata (glp, lai, smrw, primary,  a1c7to9,    1, 50);
%labdata (glp, lai, smrw, primary,  a1cover9,   1, 50);

%labdata (glp, lai, smrw, prov,  a1cless7,   1, 50);
%labdata (glp, lai, smrw, prov,  a1c7to9,    1, 50);
%labdata (glp, lai, smrw, prov,  a1cover9,   1, 50);

/*
%labdata (glp, lai, smrw, primary,  sbpless130, 1);
%labdata (glp, lai, smrw, primary,  sbp130to139,1);
%labdata (glp, lai, smrw, primary,  sbpover140, 1);
%labdata (glp, lai, smrw, primary,  dbpless80,  1);
%labdata (glp, lai, smrw, primary,  dbp80to89,  1);
%labdata (glp, lai, smrw, primary,  dbpover90,  1);
%labdata (glp, lai, smrw, primary,  ldlless100, 1);
%labdata (glp, lai, smrw, primary,  ldl100to129,1);
%labdata (glp, lai, smrw, primary,  ldlover130, 1);

/*
%labdata (glp, tzd, smrw, primary,  a1cless7,   1);
%labdata (glp, tzd, smrw, primary,  a1c7to9,    1);
%labdata (glp, tzd, smrw, primary,  a1cover9,   1);
%labdata (glp, tzd, smrw, primary,  sbpless130, 1);
%labdata (glp, tzd, smrw, primary,  sbp130to139,1);
%labdata (glp, tzd, smrw, primary,  sbpover140, 1);
%labdata (glp, tzd, smrw, primary,  dbpless80,  1);
%labdata (glp, tzd, smrw, primary,  dbp80to89,  1);
%labdata (glp, tzd, smrw, primary,  dbpover90,  1);
%labdata (glp, tzd, smrw, primary,  ldlless100, 1);
%labdata (glp, tzd, smrw, primary,  ldl100to129,1);
%labdata (glp, tzd, smrw, primary,  ldlover130, 1);*/


/*BE CAREFUL! change drug comparison &drug1=, &drug2= as the above step, and resubmit!!!!*/
%macro varmimean(var,drug1=glp,drug2=lai);/*change parameter!!!!*/
data &var._&drug1.v&drug2.;
	set &var._:;
run;
proc means data=&var._&drug1.v&drug2. stackodsoutput Mean ; 
		   var &drug1.n &drug1.freq &drug2.n &drug2.freq sdiff_ &drug2._wgtn &drug2._wgtfreq sdiff_wgt_;
ods output Summary=&var._&drug1.v&drug2._Means;  /* write statistics to data set */
run;

data &var._&drug1._&drug2;
	set &var._&drug1.v&drug2._Means ;
	length var $25; 
	var="&var";
run;
%mend;
%varmimean (var=a1cless7);
%varmimean (var=a1c7to9);
%varmimean (var=a1cover9);

%varmimean (var=sbpless130);
%varmimean (var=sbp130to139);
%varmimean (var=sbpover140);
%varmimean (var=dbpless80);
%varmimean (var=dbp80to89);
%varmimean (var=dbpover90);
%varmimean (var=ldlless100);
%varmimean (var=ldl100to129);
%varmimean (var=ldlover130);
/*********************************************************************/
/*if MI for all clinical meausres, then activate other lab covariates*/
/*********************************************************************/
%macro clinical(drug1,drug2,name);
data lablong;
	set 	
a1cless7_&drug1._&drug2
a1c7to9_&drug1._&drug2
a1cover9_&drug1._&drug2;
/*
sbpless130_&drug1._&drug2
sbp130to139_&drug1._&drug2
sbpover140_&drug1._&drug2
dbpless80_&drug1._&drug2
dbp80to89_&drug1._&drug2
dbpover90_&drug1._&drug2
ldlless100_&drug1._&drug2
ldl100to129_&drug1._&drug2
ldlover130_&drug1._&drug2;*/

length var $25; 
run;
proc sort data=lablong out=lablong1; 
	key var / ascending ; 
run;
proc transpose data=lablong1 out=labwide ;
	by var;
	id variable;
	var mean;
run;

data labwide1 (keep=var order &drug1. &drug2. unwtsdd wt&drug2. wtstdd);
	retain var order &drug1. &drug2. unwtsdd wt&drug2. wtstdd;
	set labwide;
	&drug1.=put(&drug1.n,COMMA12.0)||' ('||compress(put(&drug1.freq*100,4.1)||'%)');
	&drug2.=put(&drug2.n,COMMA12.0)||' ('||compress(put(&drug2.freq*100,4.1)||'%)');
	unwtsdd=put(sdiff_,12.3);
	wt&drug2.=put(&drug2._wgtn,COMMA12.0)||' ('||compress(put(&drug2._wgtfreq*100,4.1)||'%)');
	wtstdd =put(sdiff_wgt_,12.3);

	if var='a1cless7' then order=1;
	if var='a1c7to9' then order=2;
	if var='a1cover9' then order=3;
/*
if var='sbpless130' then order=4;
	if var='sbp130to139' then order=5;
	if var='sbpover140' then order=6;
	if var='dbpless80' then order=7;
	if var='dbp80to89' then order=8;
	if var='dbpover90' then order=9;
	if var='ldlless100' then order=10;
	if var='ldl100to129' then order=11;
	if var='ldlover130' then order=12;*/

run;

proc sort data=labwide1;
	by order;
run;
options orientation=landscape;
ODS rtf FILE="&outpath./labwide_&weight._&name._&drug1.v&drug2..rtf";
PROC PRINT DATA=labwide1;
title "&drug1. vs &drug2. imputed clinical measures";
RUN;
ODS rtf CLOSE;
%mend;
/*
%clinical (dpp,su);
%clinical (dpp, tzd);
%clinical (glp, tzd);*/

%clinical (glp, lai, primary);

%clinical (glp, lai, prov);


/********************************************************/
/*******sets of 2 by 2 tables  used in the PAPER!********/
/********************************************************/
*The P-value for Cochran-Mantel-Haenszel  for A1C distribution across GLP1RA vs LAI between true and imputed data (glogit) <0.0001. ;
data a1c;
 input lab $ treatment $ a1clevel $ count @@;
 datalines;
 crude glp a1cless7 342 crude glp a1c7to9 566 crude glp a1cover9 221
 crude lai a1cless7 1711 crude lai a1c7to9 3033 crude lai a1cover9 1910
 impute glp a1cless7 3084 impute glp a1c7to9 4592 impute glp a1cover9 1885
 impute lai a1cless7 24086 impute lai a1c7to9 35080 impute lai a1cover9 23683
 ;

 *The P-value for Cochran-Mantel-Haenszel  for A1C distribution across GLP1RA vs LAI between true vs imputed data (Proportional Odds Assumption Violated) <0.0001. ;
 data a1c;
 input lab $ treatment $ a1clevel $ count @@;
 datalines;
 crude glp a1cless7 342 crude glp a1c7to9 566 crude glp a1cover9 221
 crude lai a1cless7 1711 crude lai a1c7to9 3033 crude lai a1cover9 1910
 impute glp a1cless7 3151 impute glp a1c7to9 4400 impute glp a1cover9 2011
 impute lai a1cless7 22784 impute lai a1c7to9 37771 impute lai a1cover9 22294
 ;
 
 proc freq data=a1c order=data;
 weight count;
 tables lab*treatment*a1clevel/cmh nocol nopct;
 run;
 *The P-value for Cochran-Mantel-Haenszel  for A1C distribution across GLP1RA vs LAI between imputed data (glogit) vs imputed data (Proportional Odds Assumption Violated) <0.0001. ;
 data a1c;
 input lab $ treatment $ a1clevel $ count @@;
 datalines;
 impute_g glp a1cless7 3084 impute_g glp a1c7to9 4592 impute_g glp a1cover9 1885
 impute_g lai a1cless7 24086 impute_g lai a1c7to9 35080 impute_g lai a1cover9 23683
 impute_v glp a1cless7 3151 impute_v glp a1c7to9 4400 impute_v glp a1cover9 2011
 impute_v lai a1cless7 22784 impute_v lai a1c7to9 37771 impute_v lai a1cover9 22294
 ;
proc freq data=a1c order=data;
 weight count;
 tables lab*treatment*a1clevel/cmh nocol nopct;
 run;










 /*******************************************/
/***sets of s by 2 tables, igore! ***********/
/********************************************/
*The P-value for Mantel-Haenszel Chi-square for A1C distribution across GLP1RA vs LAI between true and imputed data (glogit) <0.0001. ;
data a1c;
 input lab $ a1clevel $ treatment $ count @@;
 datalines;
 crude a1cless7 glp 342 crude a1cless7 lai 1711
 crude a1c7to9 glp 566 crude a1c7to9 lai 3033
 crude a1cover9 glp 221 crude a1cover9 lai 1910
 impute a1cless7 glp 3084 impute a1cless7 lai 24086
 impute a1c7to9 glp 4592 impute a1c7to9 lai 35080
 impute a1cover9 glp 1885 impute a1cover9 lai 23683
 ;
*The P-value for Mantel-Haenszel Chi-square for A1C distribution across GLP1RA vs LAI between true vs imputed data (Proportional Odds Assumption Violated) <0.0001. ;
 data a1c;
 input lab $ a1clevel $ treatment $ count @@;
 datalines;
 crude a1cless7 glp 342 crude a1cless7 lai 1711
 crude a1c7to9 glp 566 crude a1c7to9 lai 3033
 crude a1cover9 glp 221 crude a1cover9 lai 1910
 impute a1cless7 glp 3151 impute a1cless7 lai 22784
 impute a1c7to9 glp 4400 impute a1c7to9 lai 37771
 impute a1cover9 glp 2011 impute a1cover9 lai 22294
 ;

 *The P-value for Mantel-Haenszel Chi-square for A1C distribution across GLP1RA vs LAI between imputed data (glogit) vs imputed data (Proportional Odds Assumption Violated) <0.0001. ;
 data a1c;
 input lab $ a1clevel $ treatment $ count @@;
 datalines;
 crude a1cless7 glp 3084 crude a1cless7 lai 24086
 crude a1c7to9 glp 4592 crude a1c7to9 lai 35080
 crude a1cover9 glp 1885 crude a1cover9 lai 23683
 impute a1cless7 glp 3151 impute a1cless7 lai 22784
 impute a1c7to9 glp 4400 impute a1c7to9 lai 37771
 impute a1cover9 glp 2011 impute a1cover9 lai 22294
 ;

proc freq order=data;
	weight count;
	tables a1clevel*treatment/chisq;
	tables lab*a1clevel*treatment/chisq cmh;
	tables lab*a1clevel*treatment/scores=modridit cmh;
run;
