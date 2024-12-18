

%macro getCohort_Ab (exposure, comparatorlist, washoutp, save); 
%do z=1 %to %sysfunc(countw(&comparatorlist.));
    %LET comparator = %scan(&comparatorlist.,&z.);
    %put &comparator.;
    /* creating the 'new use' comparator group with switch date as the next date of dpp4i drug initiation if the individual switches from comparator to dpp4i, regardless of the discontinuation date of the first useperiod */
    /**********************************************/
	/* Creating the comparator group a la Abrahami*/
	/**********************************************/
    PROC SQL;
        create table tmp_exclude_&comparator. /*all from comparator*/ as
        select distinct a.*,
        max( a.indexdate-&washoutp.<=b.discontDate and b.indexdate<a.indexdate ) as excludeflag_prevalentuser 
																					label='EXCLUSION FLAG: prevalent user of &comparator. drug',
        max(a.indexdate=b.indexdate) as excludeflag_samedayinitiator 
																	label = 'EXCLUSION FLAG: dual  initiator of &comparator. drug',
        max(a.indexdate<b.indexdate<= a.filldate2) as excludeflag_prefill2initiator 
																	label='EXCLUSION FLAG: pre-fill2 dual initiator of comparator drug before second fill date'
        from temp.&comparator._useperiods /*generated from 11_cleandata.sas*/ (where=(newuse=1 and useperiod=1) rename=(reason=reason1)) as a
        left join temp.&exposure._useperiods as b
        on a.id=b.id group by a.id, a.indexdate;
    QUIT;    

	/*
	title "tmp_exclude_&comparator"; proc print data=tmp_exclude_&comparator. (obs=5);run;title;
	title "temp.&exposure._useperiods"; 	proc print data=temp.&exposure._useperiods (obs=5);run;title;
	proc freq data=temp.dpp4i_useperiods; tables dpp4i newuse useperiod indexdate/missing;run;*/

    /* maybe add inner join for 'pure switchers?' */
    /* adding back in switch/augmentation future date, 
	which is well past the first useperiod but we will miss subsequent switch/augment dates if the person switched after the 1st use period */
    PROC SQL;
        create table _new_abrahami_&comparator. as select distinct a.*, 
        min(b.indexdate/*has not missing data!*/) as switchAugmentdate format=date9. label='DATE OF SWITCH/AUGMENTATION' /*might be mixed */
        from tmp_exclude_&comparator. as a  /*only comparator use periods*/
        LEFT JOIN temp.&exposure._useperiods as b  /* only dpp4i useperiods, but maybe should restrict to newuse=1 and useperiod=1? */
        on a.id=b.id and a.indexdate<=b.indexdate /* <=a.discontDate */
        group by a.id, a.indexdate
        order by a.id, a.indexdate;
    QUIT;
/*
title "_new_abrahami_&comparator."; proc print data=_new_abrahami_su (obs=5);run;title;
proc freq data=_new_abrahami_&comparator; tables filldate2/missing;run;*/


    PROC SQL; /*different from newuse macro*/
        create table new_abrahami_&comparator. as select distinct a.*,
        min(b.filldate2) as dpp4i_filldate2 format=date9. label='DATE OF SECOND FILL OF &exposure. DRUG for switch/augmentation'
        from _new_abrahami_&comparator. as a
        LEFT JOIN temp.&exposure._useperiods as b 
        on a.id=b.id and a.switchAugmentdate<=b.filldate2 /* <=a.discontDate */
        group by a.id, a.indexdate
        order by a.id, a.indexdate;
    QUIT; /* end of comparator*/

/*title "table new_abrahami_&comparator."; proc print data= new_abrahami_&comparator. (obs=10) ; run;*/
    /****************************************************/
    /*  DPP4i creating the exposure group a la Abrahami */
    /****************************************************/
    PROC SQL;
        create table tmp_exclude_&exposure. as 
        select distinct a.*,
        max( a.indexdate-&washoutp.<=b.discontDate and b.indexdate<a.indexdate) as excludeflag_prevalentuser 
																	 label ='EXCLUSION FLAG: prevalent user of &exposure. drug',
        max(a.indexdate=b.indexdate) as excludeflag_samedayinitiator label ='EXCLUSION FLAG: dual  initiator of &exposure. drug',
        max(a.indexdate<b.indexdate<= a.filldate2) as excludeflag_prefill2initiator 
																	 label ='EXCLUSION FLAG: pre-fill2 dual initiator of &exposure. drug before second fill date'
        from temp.&exposure._useperiods (where=(newuse=1 and useperiod=1) rename=(reason=reason1)) as a
        left join temp.&comparator._useperiods as b
        on a.id=b.id group by a.id, a.indexdate;
    QUIT;

/*
title " tmp_exclude_&exposure."; proc print data=tmp_exclude_&exposure. (obs=5); run;title;*/
/* FOR DPP4I creating fake 'new use' time-varying exposure group with switch date 
as the next date of comparator initiation if the individual switches from dpp4i to comparator, regardless of the discontinuation date of the first use period */
    PROC SQL;
        create table new_abrahami_&exposure. as 
        select distinct a.*, min(b.indexdate) as switchAugmentdate format=date9. label='DATE OF SWITCH/AUGMENTATION'
        from tmp_exclude_&exposure. as a
        LEFT JOIN temp.&comparator._useperiods as b 
        on a.id=b.id and a.indexdate<=b.indexdate /*  <=a.discontDate */
        group by a.id, a.indexdate
        order by a.id, a.indexdate;
    QUIT;
/*title "new_abrahami_&exposure."; proc print data=new_abrahami_&exposure.(obs=5); run;title;
proc freq data=new_abrahami_&exposure.; tables &exposure. filldate2/missing;run;*/
    /**************************************************************************/
    /* Combining 'new use' of comparator and 'time-varying' abrahami exposure */
    /**************************************************************************/
        /*Jeanny - I do not understand why I did this. */
    data Abrahami_&exposure._&comparator. (sortedby=id indexdate);
    retain id startdt enddt useperiod indexdate filldate2  switchAugmentdate dpp4i_filldate2 discontDate 
           newuse su dpp4i excludeflag_prevalentuser excludeflag_prefill2initiator  excludeflag_samedayinitiator reason1;
    set new_abrahami_&exposure.  (in=a)  new_abrahami_&comparator.  (in=b);
    by id indexdate;
    &exposure.=a; 
    label &exposure. = "Abrahami-defined drug class: 1= &exposure. 0= &comparator.";
    RUN;
/*
title "Abrahami_&exposure._&comparator."; proc print data=Abrahami_&exposure._&comparator. (obs=20);run;
proc freq data=Abrahami_&exposure._&comparator.; tables dpp4i*su/missing; run;
title "Abrahami_&exposure._&comparator. dpp4i=1, dpp4i_filldate2 NE ."; 
proc print data=Abrahami_&exposure._&comparator. (obs=10);where dpp4i=0 and dpp4i_filldate2 NE . and filldate2 NE .; run;

title "new_abrahami_&exposure.";proc print data=new_abrahami_&exposure. (obs=5);run;title;
title "new_abrahami_&comparator.";proc print data=new_abrahami_&comparator.(obs=5);where dpp4i_filldate2 NE . and excludeflag_prevalentuser=1; run;title;
proc freq data=new_abrahami_&comparator.; tables dpp4i excludeflag_prevalentuser ;run;*/
    /* retrive counts and create a new exclusion table to track individuals */
proc sql; 
create table id_counts as select ID, 
count(*) as num_rows from Abrahami_&exposure._&comparator.  
group by ID; 
quit;

data merge_Abrahami_&exposure._&comparator.; 
merge Abrahami_&exposure._&comparator. (IN=a) id_counts (IN=b);
by ID;
if a;
run;

data final_Abrahami_&exposure._&comparator.;
 set merge_Abrahami_&exposure._&comparator.;
 by ID;
if (dpp4i=1) /*exposure*/or 
(dpp4i=0 and filldate2> dpp4i_filldate2 )/*switched to dpp4i later*/ or
(dpp4i=0 and dpp4i_filldate2 =. ); /*pure comparator, never switched to dpp4i later*/

if (dpp4i=1 and num_rows=1)  then switcher=0 ; /*pure exposure*/
else if (dpp4i=1 and num_rows=2) then switcher=1; /*switcher*/
else if (dpp4i=0 and filldate2> dpp4i_filldate2 ) then switcher=2;/*comparator switched to dpp4i later*/ 
else if (dpp4i=0 and dpp4i_filldate2 =. ) then switcher = 3;/*pure comparator*/
run;


proc sql; select count(*) as row_count from merge_Abrahami_&exposure._&comparator.;run;
proc sql; select count(*) as row_count from final_Abrahami_&exposure._&comparator.;run;

proc print data=merge_Abrahami_&exposure._&comparator.(obs=20);run;
proc print data=final_Abrahami_&exposure._&comparator.(obs=20);run;



    PROC SQL noprint; 
        CREATE TABLE tmp_id_counts AS SELECT *  FROM temp.exclusions_dpp4i_&comparator.;
        select count(*) into :num_obs from tmp_id_counts;
        INSERT INTO tmp_id_counts
        SET exclusion_num = &num_obs + 1,
        long_text = "Initiators of &exposure. or &comparator.",
        dpp4i = (select count(distinct id ) from temp.&exposure._useperiods),
        &comparator. = (select count(distinct id ) from temp.&comparator._useperiods);  

        insert into tmp_id_counts
        set exclusion_num = &num_obs + 2,
        long_text="Restricting to newuse==1 and useperiod==1", 

        dpp4i = (select count(distinct id ) from tmp_exclude_&exposure.),
        &comparator. = (select count(distinct id ) from tmp_exclude_&comparator.);
    QUIT;
proc print data=tmp_id_counts;
run;


    /* If save eq Y then save to temp folder for retrieval later */
    %if &save.=Y %then %do; 
    data temp.Abrahami_&exposure._&comparator.;set final_Abrahami_&exposure._&comparator.;RUN;
    data temp.Abexclusions_012_&exposure._&comparator.;set tmp_id_counts;RUN;
    %end;
%end;
%mend getCohort_Ab; 
