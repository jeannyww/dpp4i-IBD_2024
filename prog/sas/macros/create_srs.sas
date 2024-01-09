
/**===================================*\
Data cleaning-small SRS
%macro create_srs ( nsample=5000 , fulldata=a.SENSITIVITYA_0, outdata = a0srs );
 
\*===================================*/
/* region - Data cleaning-small SRS*/

/* for faster processing of testing , first create a srs of 10k obs */

/*create_srs*/
*descrip;
%macro create_srs ( nsample , fulldata, outdata  );

data tmpfull; set &fulldata;run;

proc sql;
    CREATE TABLE uniqueids as select distinct id
    from tmpfull ;
quit; *the SensitivityA0 dataset has 50891 uniqueIDs;

proc sql outobs=&nsample;
    create table randid as select * from uniqueids order by ranuni(12345);
quit;

/* merging with observations for random ids only selected */
proc sql;
    create table &outdata as select * from randid
    inner join  tmpfull as a on randid.id=a.id;
quit;
/* endregion */

%mend create_srs;