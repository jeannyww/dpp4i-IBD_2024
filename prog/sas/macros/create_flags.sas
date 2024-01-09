%macro create_flags(data=);
	proc sql noprint;	
		select distinct name into :var1-:var500 
			from dictionary.columns where upcase(libname)='RAW' and upcase(memname)='MAIN'
				and substr(upcase(name),1,3)='BL_';
		%LET N=&sqlObs;
	quit;

	data main;
		set raw.main;

		%DO i=1 %TO &N;
			if bl_&&var&i <meets criteria> then bl_&&var&i.._flag=1; else bl_&&var&i.._flag=0; 
		%END;
	run;
%mend;
