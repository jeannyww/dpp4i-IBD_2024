options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; option MAUTOSOURCE;
option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");
%setup(programName=16_RnR_ACNUanalysisrun.sas, savelog=N, dataset=dataname);

/* Load ACNU_analysis macro */
%include "D:\Externe Projekte\UNC\wangje\prog\sas\16_RnR_ACNUanalysismacro.sas";
/* Load TVE_analysis macro */
%include "D:\Externe Projekte\UNC\wangje\prog\sas\17_RnR_TVEanalysismacros.sas";


/* TVE */
%TVE_analysis (pstrim=N, exclude_ibd=y, 
exposure= dpp4i , comparator= tzd,
ana_name=mITtv, type= IT, 
weight= smrw, induction= 180, latency= 180 ,
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;
 /* Taking a look at if switchers are deleted */
PROC SQL;
    /* Count rows of repeat ids */
    create table num_rows_fin as select ID, count(*) as num_rows_fin
    from dsn
    where (delete_flag1=0)
	group by ID;
    /* Add num_rows_fin */
    create table tve_dsn2 as select a.*, b.num_rows_fin 
    from dsn as a
    left join num_rows_fin as b
    on a.ID=b.ID;
QUIT;
proc datasets library=work nolist nodetails; 
delete  dsn ; 
run; quit; 
proc freq data=  tve_dsn ; 
tables         num_rows_fin * delete_flag1  *switcher_flag   / list missing; 
run; 

/* ACNU */
%let num=9;
%ACNU_analysis (pstrim=N, 
exposure= dpp4i , comparator= tzd, 
ana_name=mITac, type= IT, weight= smrw, 
induction= 180, latency= 180 , 
ibd_def= ibd1, intime= filldate2, outtime='31Dec2022'd ,
numyears=&num, outdata=IT , save=N ) ;

data acnu_dsn; set dsn; run;

/* Testing */

title "TVE";
proc means data= tve_dsn2 STACKODS sum; 
class switcher_flag delete_flag1;
var time  event; run;
title "ACNU"; 
proc means data= acnu_dsn STACKODS sum; 
class dpp4i delete_flag1;
var time  event;run;

title "TVE";
proc means data= tve_dsn2 STACKODS sum;
where  delete_flag1 eq 0;
var time  event; run;
title "ACNU"; 
proc means data= acnu_dsn STACKODS sum;
where delete_flag1 eq 0; 
var time  event;run;

title "TVE";
proc means data=tve_dsn2 STACKODS N NMISS sum MEAN STD MIN MAX Q1 MEDIAN Q3  MAXDEC=2 ;
where delete_flag1=0;
class dpp4i switcher_flag;
var  time event; 
run;
title "ACNU";
proc means data=acnu_dsn STACKODS N NMISS sum MEAN STD MIN MAX Q1 MEDIAN Q3  MAXDEC=2 ;
where delete_flag1=0;
class dpp4i;
var  time event; 
run;


title "TVE";
proc means data=tve_dsn2 STACKODS N NMISS sum MEAN STD MIN MAX Q1 MEDIAN Q3   MAXDEC=2;
/*where delete_flag1=0;*/
class dpp4i switcher_flag;
var  time event; 
run;
title "ACNU";
proc means data=acnu_dsn STACKODS N NMISS sum MEAN STD MIN MAX Q1 MEDIAN Q3    MAXDEC=2;
/*where delete_flag1=0;*/
class dpp4i;
var  time event; 
run;


/*Comparing the person time and way that it is counted between TVE and ACNU */
/*what is the 33988 people's swithcer=3 in TVE*/
proc sql;
create table comp3_ids as select distinct id as tve3_ids, time0 as tve_time0, time as tve_time, event as tve_event, 
switcher_flag
from tve_dsn2
where switcher_flag=3
; 
quit;
/*Are those 33988 people found in the acnu*/
proc sql; 
create table overlap as select a.id as acnu_ids, b.tve3_ids, a.dpp4i,a.time0 as acnu_time0, b.tve_time0
, a.time as acnu_time, a.event as acnu_event, 
b.tve_time, b.tve_event, b.switcher_Flag
from (select * from acnu_dsn where dpp4i=0) as a
inner join 
comp3_ids as b
on a.id = b.tve3_ids;
quit;
/*they overlap and their persontime is the exact same. the puredpp4i and the pureswitchers are not the issue*/
proc means data =  overlap
STACKODS N NMISS sum MEAN STD MIN MAX Q1 MEDIAN Q3 MAXDEC=2  ;
class switcher_flag dpp4i; 
var    acnu_event acnu_time    tve_event tve_time      ; 
run; 
proc freq data=    tve_dsn2; 
tables           dpp4iinitiator_crohns_bl*ibd_ever    sglt2iinitiator_crohns_bl / list missing; 
run; 


/*This means that the switchers are the issue*/
/*Compare the switchers ids*/
proc sql;
create table comp21_ids
as select id as tve_id, switcher_flag, time0 as tve_time0, filldate2 as tve_filldate2, switchAugmentDate as tve_switchaugdt, 
dpp4i_filldate2, enddate as tve_enddate, event as tve_event, time as tve_time, delete_flag1 as tve_deleteflag /*ibd_ever, ibd1_dt, ibd1_code,ibd_bl, IBD_bc, 
IBD_gc,dpp4iinitiator_ibd_ever ,sglt2iinitiator_ibd_ever*/
from tve_dsn2
where switcher_flag in (1,2) and ibd_ever ne 1
	;
quit;
proc sql;
create table overlapswitchers as
select distinct a.*
from acnu_dsn as a
inner join 
comp21_ids as b
on a.id=b.tve_id;
quit;
proc freq data= overlapswitchers   ; 
tables  dpp4i              / list missing; 
run; 
proc means data =  overlapswitchers
STACKODS N NMISS SUM MEAN STD MIN MAX Q1 MEDIAN Q3 MAXDEC  ; 
var  time event            ; 
run; 
proc sql;
create table whyswitch as 
select a.*, b.time0 as acnu_time0, b.filldate2 as acnu_filldate2, b.switchAugmentdate as acnu_switchaugdt,
b.enddate as acnu_enddate, b.event as acnu_event, b.time as acnu_time, b.delete_flag1 as acnu_deleteflag
from comp21_ids as a
left join 
overlapswitchers as b
on a.tve_id=b.id
order by a.tve_id, a.switcher_flag;
quit;
data whyswitch;
set whyswitch; 
tve_time1=365.25*tve_time;
tve_time2=(tve_enddate-(tve_filldate2+180)+0.5);
acnu_time1=365.25*acnu_time;
acnu_time2=(acnu_enddate-(acnu_filldate2+180)+1);
run;
data tmptest; 
set whyswitch; where tve_deleteflag eq 1;run;
/* Find the IDs in tve_dsn2 where delete_flag1 = 1 and switcher_flag in (1,2)*/
proc sql;
CREATE TABLE tvedelete as 
select distinct id from tve_dsn2
where delete_flag1=1 and switcher_flag in (1,2);
run;
quit;
/*553 unique ids*/
proc sql; 
create table testdelete as
select a.* 
from whyswitch as a
inner join tvedelete as b
on a.tve_id = b.id;
quit;
proc freq data= testdelete   ; 
tables    switcher_flag*  tve_deleteflag  *acnu_deleteflag        / list missing; 
run; 
data test; set testdelete; where acnu_deleteflag eq 1 and tve_deleteflag eq 1;run;
proc print data=  tve_dsn2 ;  where id eq '11003~21013';run;


title "ACNU"; 
proc freq data=    whyswitch; 
tables dpp4iinitiator_ibd_ever sglt2iinitiator_ibd_ever        ibd_ever       / list missing; 
run; 


/*proc print data=whyswitch (obs=10);where tve_id eq '11002~19604'; run; */
proc means data= whyswitch STACKODS sum nmiss maxdec=2; 
class switcher_flag;
var acnu_time tve_time tve_time1 tve_time2 acnu_time1  acnu_event tve_event;run;
/* temp.excl_016_&exposure._&comparator._1yr&type. */
/* temp.Abexclusions_016_&exposure._&comparator._&type */