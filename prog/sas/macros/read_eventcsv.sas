
%macro read_eventcsv ( druglist , outlib );

    %do i=1 %to %sysfunc(countw(&druglist.));
        %let drug=%scan(&druglist.,&i.);

    data  tmp; 
        infile "D:\Externe Projekte\UNC\Task231122 - IBDandDPP4I (db23-1)\Tasks\01 Get Cohort\results\2023-12-16\Task231122_01_231122_&drug._Event\Task231122_01_231122_&drug._Event.csv" 
        dsd dlm="," firstobs=2 n=200 missover;
        length ID $ 12 eventtype 8 tmp_EventDate $ 10 tmp_EventDate_tx $ 10 badrx_BCode $ 10 badrx_GCode $ 10 EndOfLine $ 10;
        input ID $ eventtype ReadCode $ tmp_EventDate $ tmp_EventDate_tx $ badrx_BCode $ badrx_GCode $ EndOfLine $;
    data &outlib..&drug._event; set tmp;
    retain id eventtype eventdate eventdate_tx;
        if strip(tmp_eventdate) eq "" | strip(tmp_eventdate) eq "??/??/????" then tmp_eventdate="."; 
        if strip(tmp_eventdate_tx) eq "" | strip(tmp_eventdate_tx) eq "??/??/????" then tmp_eventdate_tx=".";
        eventdate=input(tmp_eventdate,mmddyy10.);
        eventdate_tx= input(tmp_eventdate_tx,mmddyy10.);
        drop tmp_eventdate tmp_eventdate_tx; 
        format eventdate eventdate_tx date9.;
    run;
    proc datasets nolist; delete tmp; run; quit;
    %end; 
    proc contents; run;
%mend read_eventcsv;