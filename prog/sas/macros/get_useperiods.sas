

%macro get_useperiods ( druglist , grace, washout, save= N );

    %do z=1 %to %sysfunc(countw(&druglist.));
        %let drug=%scan(&druglist.,&z.);
        
        data tmptrtmt_; set raw.&drug._trtmt; run;
    
    proc sql;
        create table tmpRx_&drug. as
        select * from 
            (select a.id, a.rxdate, a.time0, a.history, a.gemscript, a.BCSDP, a.rx_dayssupply, a.DPP4i, a.SU, a.SGLT2i, a.TZD 
            from tmptrtmt_ as a ) 
            left join 
            (select * from tmpevent_wide&drug. as b)
            on a.id=b.id;
    quit;
    
    data tmpRx_&drug._; set tmpRx_&drug.;
        startdt= time0-history ; format startdt date9.;
        enddt= min(death_dt, dbexit_dt, endstudy_dt); format enddt date9.; RUN;
    %let keeplist= dpp4i su sglt2i tzd gemscript BCSDP;
        
    %useperiods(grace=&primaryGraceP, washout=&washoutp, wpgp=Y, daysimp=0, maxDays=, multiclaim=max,
        inds= %str(tmpRx_&drug._ (where=(&drug.=1))), idvar=id, startenroll=startdt, rxdate=rxdate, endenroll=enddt, dayssup=rx_dayssupply, 
        keepvars= &keeplist, outds=&drug._useperiods);
        
    %if &save. = Y %then %do;
    
        data temp.&drug._useperiods; set &drug._useperiods; run;
        %end;
    
    %end;
    %mend get_useperiods;
    
    