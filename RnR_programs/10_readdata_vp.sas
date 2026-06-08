options nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes ;
options macrogen symbolgen mlogic mprint mcompile mcompilenote=all; 
option MAUTOSOURCE;option SASAUTOS=(SASAUTOS "D:\Externe Projekte\UNC\wangje\prog\sas\macros");

%setup(programName=011_readdata_vp.sas, savelog=Y, dataset=dataname);

%macro split_trt(drugList);
	%LET N= %SYSFUNC(countw(&drugList));
	%DO i=1 %TO &N; 
		%LET drug = %SCAN(&drugList,&i);
		proc sql;
			create table raw.&drug._bl as select distinct * 
				from raw.&drug._trtmt(drop=rxdate_tmp gemscript BCSDP  rx_dayssupply DPP4i SU SGLT2i TZD rxdate);

			create table raw.&drug._trt as select distinct id, rxdate, gemscript ,BCSDP, rx_dayssupply DPP4i, SU, SGLT2i, TZD 
				from raw.&drug._trtmt order by id, rxdate;
		quit;
	%END;
%mend;
%split_trt(dpp4i su tzd sglt2i)
