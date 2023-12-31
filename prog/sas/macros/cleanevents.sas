
/*cleanevents*/
*descrip;
%macro cleanevents ( Druglist , save= N );

    %do i=1 %to %sysfunc(countw(&druglist.));
    %let drug=%scan(&druglist.,&i.);
    
    data tmpevent_ ; set raw.&drug._event ; run;
    
    proc sort data= tmpevent_; by id eventtype eventdate ; run;
    data _tmpevent_wide&drug.;
            set tmpevent_ ;
            by id eventtype ; 
            length ibd1_code ibd2_code ibd3_code ibd4_code ibd5_code badrx_Bcode badRx_Gcode $ 10; 
            retain ibd1_dt ibd1_code ibd1
                ibd2_dt ibd2_code ibd2
                ibd3_dt ibd3_code ibd3
                ibd4_dt ibd4tx_dt ibd4_code ibd4
                ibd5_dt ibd5_code ibd5
                badrx_dt badrx_Bcode badrx_Gcode badrx
                death_dt dbexit_dt LastColl_Dt endstudy_dt;
            format ibd1_dt ibd2_dt ibd3_dt ibd4_dt ibd4tx_dt ibd5_dt badrx_dt death_dt dbexit_dt LastColl_Dt endstudy_dt date9.;
        
            if first.id then do;
                ibd1_dt = .; ibd1_code = ""; ibd1 = .;
                ibd2_dt = .; ibd2_code = ""; ibd2 = .;
                ibd3_dt = .; ibd3_code = ""; ibd3 = .;
                ibd4_dt = .; ibd4tx_dt = .; ibd4_code = ""; ibd4 = .;
                ibd5_dt = .; ibd5_code = ""; ibd5 = .;
                badrx_dt = .; badrx_Bcode = ""; badrx_Gcode = ""; badrx=.;
                death_dt = .; dbexit_dt = .; LastColl_Dt = .; endstudy_dt = '31DEC2022'd;
            end;
        
            if eventtype = 1 then do;
                ibd1_dt = eventdate;
                ibd1_code = readcode;
                ibd1 = 1;
            end; 
        
            if eventtype = 2 then do;
                ibd2_dt = eventdate;
                ibd2_code = readcode;
                ibd2 = 1;
            end; 
        
            if eventtype = 3 then do;
                ibd3_dt = eventdate;
                ibd3_code = readcode;
                ibd3 = 1;
            end; 
        
            if eventtype = 4 then do;
                ibd4_dt = eventdate;
                ibd4tx_dt = eventdate_tx;
                ibd4_code = readcode;
                ibd4 = 1;
            end; 
        
            if eventtype = 5 then do;
                ibd5_dt = eventdate;
                ibd5_code = readcode;
                ibd5 = 1;
            end; 
        
            if eventtype = 6 then do;
                if first.eventtype then do; 
                badrx_dt = eventdate;
                badrx_Bcode = badrx_Bcode;
                badrx_Gcode = badrx_Gcode;
                badrx=1; 
                END;
            end; 
            if eventtype = 7 then death_dt = eventdate;
            if eventtype = 8 then dbexit_dt = eventdate;
            if eventtype = 9 then LastColl_Dt = eventdate;
            if last.id then output;
            drop eventtype eventdate readcode eventdate_tx endofline ;
        run;
        
        PROC SQL; 
            create table tmpevent_wide&drug. as select distinct a.*, b.time0 from _tmpevent_wide&drug. as a 
            inner join raw.&drug._trtmt as b on a.id = b.id;
        QUIT;
        
    
    %if &save. = Y %then %do;
        data temp.&drug._eventwide; set tmpevent_wide&drug.; run;
        %end;
    %else %do; %end; %end;
    %mend cleanevents;
    
    