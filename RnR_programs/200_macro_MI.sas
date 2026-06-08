options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen nosymbolgen nomlogic nomprint mcompile; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=testMI, savelog=N, dataset=dataname);

%Mimputation(dataset=acnu, exposure=dpp4i,comparator= tzd, m=10,addedvars=oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback ); 
%Mimputation(dataset=acnu, exposure=dpp4i,comparator= sglt2i, m=10,addedvars=oAntGLP_1yrlookback su_1yrlookback TZD_1yrlookback); 
%Mimputation(dataset=acnu, exposure=dpp4i,comparator= su, m=10,addedvars=oAntGLP_1yrlookback sglt2i_1yrlookback TZD_1yrlookback); 
%Mimputation(dataset=tve, exposure=dpp4i,comparator= tzd, m=10,addedvars=oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback ); 
%Mimputation(dataset=tve, exposure=dpp4i,comparator= sglt2i, m=10,addedvars=oAntGLP_1yrlookback su_1yrlookback TZD_1yrlookback); 
%Mimputation(dataset=tve, exposure=dpp4i,comparator= su, m=10,addedvars=oAntGLP_1yrlookback sglt2i_1yrlookback TZD_1yrlookback);

%macro Mimputation(
dataset , /* EIther ACNU or TVE */
exposure, 
comparator, 
m, 
addedvars
);
%LET induction = 180;   
%LET latency = 180;
%LET ibd_def = ibd1;
%LET intime = filldate2;
%LET outtime = '31Dec2022'd;

%if %upcase(&dataset) eq TVE %then %do; 
    data dsn;
        a.Abrahami_Notrim_&exposure._&comparator.;  oneyear =&intime +365.25;
        twoyear  =&intime +730.5;
        threeyear=&intime +1095.75;
        fouryear =&intime +1460; 
        oneyearout  =oneyear   + &latency; 
        twoyearout  =twoyear   + &latency;
        threeyearout=threeyear + &latency;
        fouryearout =fouryear  + &latency;
        format oneyearout   date9.;
        format oneyear      date9.;
        format twoyear      date9.;
        format threeyear    date9.;
        format fouryear     date9.;
    
        /* Coding in more time variables  */
        *rxchange: for switching one class from another class;
            rxchange=min(DiscontDate, enddt,  switchAugmentDate);
            label rxchange='MIN of DisconDate, End of Continuous Enrollment, SwitchAugmentDate';
            format rxchange date9.;
        *end of drug in the drug class; 
            endofdrug=rxchange+&latency;

        *if the startdate is filldate2, the date of second prescription;
            if &exposure =0 and switcher_flag=2 then do;
/*            if &exposure =0 and switchAugmentDate ne . then do;*/
                enddate= min(&ibd_def._dt, dpp4i_filldate2 +&induction, 
						&outtime /*7/29/2024 Tian & Jeany added this, fixing the error that comparator >3yr when using max 3-yr FUP*/
						, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt
						);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
                end;

        /* IT analysis  */
        /* for dpp4i initiators who were prevalent users of the comparator */
/*            else if &exposure =1 and excludeflag_prevalentuser eq 1 then do;*/
		else if &exposure =1 and switcher_flag=1/*excludeflag_prevalentuser eq 1*/ then do;
                enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
                if enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
                end;
            /* for initiators of dpp4i who never switched from the comparator */
/*            else if &exposure=1 and excludeflag_prevalentuser ne 1 then do;*/
		else if &exposure=1 and switcher_flag=0 /*excludeflag_prevalentuser ne 1*/ then do;
                enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
            end;
            /* for initiators of comparator drug who never switched */
/*            else if &exposure=0 and switchAugmentDate eq . then do;*/
		else if &exposure=0 and switcher_flag=3 /*switchAugmentDate eq .*/ then do;
                enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
                IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;
            end;
        *formatting etc; 
        format enddate date9. ; 
		label enddate ="Date min of (&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt), or switch/augment date for comparators";
        *"Date min of (death_dt, endstudy_dt, dbexit_dt, LastColl_Dt)";
        enddatedelete=min(enddt, endstudy_dt, &outtime);  
        
        *flag to remove individuals who did not reach the induction period for followup ;
        IF indexdate <= enddatedelete<=(&intime + &induction) then deleteobs=1; 			else deleteobs=0;
        label deleteobs            ="Flag to remove individuals who did not reach the induction period for followup";
        IF indexdate <= &ibd_def._dt <=(&intime + &induction) then IBDdx_inductionperiod=1; else IBDdx_inductionperiod=0;
        label IBDdx_inductionperiod="Flag for individuals with IBD diagnosis within the induction period";
        * followup time;
/*		time=(enddate-(&intime.+&induction)+1)/365.25;*/
		if switcher_flag in (0,3,2) then time=(enddate-(&intime.+&induction)+1)/365.25;
		else if switcher_flag  eq 1 then time=(enddate-(&intime.+&induction))/365.25; *added so that one extra day is not doubly counted for switchers;
		* drug duration;
        time_drugdur=(min(rxchange, enddate)-(indexdate+1))/365.25;    
    	*log time and mising time;
        if time>0 then logtime=(log(time/100000))  ;
        else time=.;
        if time=. then delete_zerofollowup=1; else delete_zerofollowup=0;
        label time = "person-years" time_drugdur= "duration of treatment";
        label logtime="log(person-years)";
        *flag for individuals with IBD diagnosis ever (IBD before time 0) or IBD post-index date without regard to the induction period; 
        if indexdate<= &ibd_def._dt then IBD_postindex=1; else IBD_postindex=0;
		*flag for any of the deletion criteria;
		if deleteobs=1 or IBDdx_inductionperiod=1 or delete_zerofollowup=1 then delete_flag1=1; else delete_flag1=0;
		label delete_flag1="Flag for people who did not reach induction pd deleteobs=1 and IBDdx_inductionperiod=1 and delete_zerofollowup=1";
    /*Reiterate coding just to make sure missing and imputed variablesare correctly created*/
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
        /*Creating numeric versions of smoke and bmi where u/unknown is coded as missing*/
        /*ordering by highest frequency as the 'reference' for smoking*/
        /*'u'='Unknown'= . 
        's'='Current'= 3
        'n'='Never'= 2
        'x'='Past/quit' = 1 ;*/
        smoke_miss=.; 
        if smoke="u" then smoke_miss=.; 
        else if smoke="s" then smoke_miss=3; 
        else if smoke="n" then smoke_miss=2;
        else if smoke="x" then smoke_miss=1;

        /*ordering by highest frequency as the 'reference' for alcohol*/
        /*'u'='Unknown'= . 
        'c'='Current' = 1
        'n'='Never'= 2
        'x'='Past/quit' = 3 ;*/
        alc_miss=.; 
        if alc="u" then alc_miss=.; 
        else if alc="c" then alc_miss=1 ;
        else if alc="n" then alc_miss=2; 
        else if alc="x" then alc_miss=3;
        /*Creating a square of age*/
        agesquare=age*age;
        /*Numeric sex*/
        sex_num=.; 
        if sex='f' then sex_num=1; 
        else if sex='m' then sex_num=0;
    run;

%end;
%if %upcase(&dataset) eq ACNU %then %do; 
    data dsn; 
	set a.notrim_&exposure._&comparator._1yrlb; 
	format dpp4i;
    /*	Dummy tve variables*/
	switcher_flag=99;
	dpp4i_filldate2=99;
    /* Time variables */
    oneyear  =&intime +365.25;
	twoyear  =&intime +730.5;
	threeyear=&intime +1095.75;
	fouryear =&intime +1460;
	oneyearout  =oneyear   + &latency; 
	twoyearout  =twoyear   + &latency;
	threeyearout=threeyear + &latency;
	fouryearout=fouryear + &latency;
	format oneyearout   date9.;
	format oneyear      date9.;
	format twoyear      date9.;
	format threeyear    date9.;
	format fouryear     date9.;

    /* Coding in more time variables  */
    *rxchange: for switching one class from another class;
        rxchange=min(DiscontDate, enddt,  switchAugmentDate);
        label rxchange='MIN of DisconDate, End of Continuous Enrollment, SwitchAugmentDate';
        format rxchange date9.;
    *end of drug in the drug class; 
        endofdrug=rxchange+&latency;

    /* Initial Treatment */
        enddate= min(&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt);
        format enddate date9. ; label enddate ="Date min of (&ibd_def._dt, enddt, endstudy_dt,&outtime, death_dt, dbexit_dt,  LastColl_Dt)";
        *"Date min of (&ibd_def._dt,death_dt, endstudy_dt, dbexit_dt, LastColl_Dt)";
 
        *"Date min of (death_dt, endstudy_dt, dbexit_dt, LastColl_Dt)";
        enddatedelete=min(enddt, endstudy_dt, &outtime);  
        
        *flag to remove individuals who did not reach the induction period for followup ;
        IF indexdate<= enddatedelete<=(&intime + &induction) then deleteobs=1; 
            else deleteobs=0;
        label deleteobs="Flag to remove individuals who did not reach the induction period for followup";
        IF indexdate <= &ibd_def._dt <=(&intime + &induction) then IBDdx_inductionperiod=1;
            else IBDdx_inductionperiod=0;
        label IBDdx_inductionperiod="Flag for individuals with IBD diagnosis within the induction period";


    *Creating event variable and followup time variable; 
    IF enddate>(&intime + &induction) and enddate=&ibd_def._dt and &ibd_def ne . then event=1; else event=0;

    time=(enddate-(&intime.+&induction)+1)/365.25;
    time_drugdur=(min(rxchange, enddate)-(indexdate+1))/365.25;

    if time>0 then logtime=(log(time/100000))  ;
    else time=.;
	if time=. then delete_zerofollowup=1; else delete_zerofollowup=0;
    label time = "person-years" time_drugdur= "duration of treatment";        
    label logtime="log(person-years)";

    *flag for individuals with IBD diagnosis ever (IBD before time 0) or IBD post-index date without regard to the induction period; 
    IBD_ever= max(crohns_ever, ucolitis_ever);  
    label IBD_ever="Ever IBD diagnosis";
    if indexdate<= &ibd_def._dt then IBD_postindex=1; else IBD_postindex=0;
	*flag for any of the deletion criteria;
		if deleteobs=1 or IBDdx_inductionperiod=1 or delete_zerofollowup=1 then delete_flag1=1;
	else delete_flag1=0;
		label delete_flag1="Flag for people who did not reach induction pd deleteobs=1 and IBDdx_inductionperiod=1 and delete_zerofollowup=1";
/*removing the dpp4i format for the summary macro*/
format dpp4i;
/*Reiterate coding just to make sure missing and imputed variablesare correctly created*/
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
        /*Creating numeric versions of smoke and bmi where u/unknown is coded as missing*/
        /*ordering by highest frequency as the 'reference' for smoking*/
        /*'u'='Unknown'= . 
        's'='Current'= 3
        'n'='Never'= 2
        'x'='Past/quit' = 1 ;*/
        smoke_miss=.; 
        if smoke="u" then smoke_miss=.; 
        else if smoke="s" then smoke_miss=3; 
        else if smoke="n" then smoke_miss=2;
        else if smoke="x" then smoke_miss=1;

        /*ordering by highest frequency as the 'reference' for alcohol*/
        /*'u'='Unknown'= . 
        'c'='Current' = 1
        'n'='Never'= 2
        'x'='Past/quit' = 3 ;*/
        alc_miss=.; 
        if alc="u" then alc_miss=.; 
        else if alc="c" then alc_miss=1 ;
        else if alc="n" then alc_miss=2; 
        else if alc="x" then alc_miss=3;
        /*Creating a square of age*/
        agesquare=age*age;
        /*Numeric sex*/
        sex_num=.; 
        if sex='f' then sex_num=1; 
        else if sex='m' then sex_num=0;
    RUN;

%end;

/* Add N-A hazard */
ods exclude all;
ods output productlimitestimates=out;
proc lifetest data=dsn nelson;
  time time*event(0); * time*event();
run;
ods exclude none;
proc print data=out (obs=5); var time cumhaz; run;
proc means data =  out        
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3   ; 
var      cumhaz        ; 
run; 
* only keep the non-missing values for cumulative hazard;
data out1;
      set out;
      if cumhaz ne .;
run;
* sort the datasets (main dataset and Nelson-Aalen estimator dataset);

/*%let dataset=dsnac_&exposure._&comparator.; */
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

/* cut to only necessary variables */
data comb_4; set comb_4; 
keep id filldate2 dpp4i_filldate2  
switcher_flag
	bmi hba1c alc_miss smoke_miss dpp4i
	cumhaz event time logtime  time_drugdur rxchange DiscontDate enddt  switchAugmentDate
	ibd1 ibd1_dt indexdate
	switcher_flag dpp4i_filldate2
	 enddt endstudy_dt  death_dt dbexit_dt  LastColl_Dt
	oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback chf_ever TZD_1yrlookback
	diff_1st_2ndrx
	age agesquare  
	sex_num entry_year   	
	nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever 
	bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
	ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 
	psorp_ever vasc_ever 
	RhArth_ever SjSy_ever sLup_ever
	ibd_ever 
 deleteobs  IBDdx_inductionperiod  delete_zerofollowup  delete_flag1;run;

/* Run MI */

proc mi data=comb_4 nimpute=&m seed=20240107 out=temp.&dataset._MI_&exposure._&comparator. ;*a.&outdata._&drug1._&drug2;
CLASS  alc_miss smoke_miss
/*	event &drug1 &vars &clinical*/
/*	sex_num */
	entry_year   
	/*bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  */
/*	nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever */
	/*drugs*/
/*	bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr */
/*	ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever */
	/*Autoimmune*/
/*	psorp_ever vasc_ever */
/*	RhArth_ever SjSy_ever sLup_ever*/
	;
fcs nbiter=10 logistic( alc_miss smoke_miss/details link=glogit likelihood=augment) reg( bmi hba1c /details); 
VAR  bmi hba1c alc_miss smoke_miss
	cumhaz event &exposure &addedvars
	age agesquare  
	sex_num entry_year   
	/*bmi_cat2 alcohol_cat smoke_cat hba1c_Cat2  */
	nephr_ever nerop_ever dret_ever mi_ever stroke_ever PerArtD_ever 
	/*drugs*/
	bigua_ever insulin_ever prand_ever agluco_ever num_nondmdrugs1yr 
	ass_ever allnsa_ever hrtopp_ever estr_ever gesta_ever pill_ever 
	/*Autoimmune*/
	psorp_ever vasc_ever 
	RhArth_ever SjSy_ever sLup_ever;
run;
%mend Mimputation;


%Mimputation(acnu, dpp4i, tzd, m=10,oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback ); 
%Mimputation(acnu, dpp4i, sglt2i, m=10,oAntGLP_1yrlookback su_1yrlookback TZD_1yrlookback); 
%Mimputation(acnu, dpp4i, su, m=10,oAntGLP_1yrlookback sglt2i_1yrlookback TZD_1yrlookback); 
%Mimputation(tve, dpp4i, tzd, m=10,oAntGLP_1yrlookback sglt2i_1yrlookback su_1yrlookback ); 
%Mimputation(tve, dpp4i, sglt2i, m=10,oAntGLP_1yrlookback su_1yrlookback TZD_1yrlookback); 
%Mimputation(tve, dpp4i, su, m=10,oAntGLP_1yrlookback sglt2i_1yrlookback TZD_1yrlookback);





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
%mend runMIana;

