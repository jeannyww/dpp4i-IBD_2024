 
/**createvar*/
*writing sas code that creates comorbidity variables based on number of &years pre-index (_bc for conditions, and _last for medications);
%macro createvar (type,  var_list , writ_list, yrspreindex);
/*  %LET lookback = %eval(-1**&yrspreindex);*/
/*  tmp_yrslookback&yrspreindex.= (intnx('year', entry, -&lookback, 'same'));*/

  /* assumption that >=50 years lookback arbitrarily means all available lookback */
  %if &yrspreindex lt 50 %then %do; 
    %LET nyrspreindex = &yrspreindex;
  %end; %ELSE %do; %let nyrspreindex= all available; %end;

  %DO i=1 %TO  %sysfunc(countw(&var_list));
    %let var = %scan(&var_list, &i);
    %let varwritq =%sysfunc(dequote( %scan(&writ_list, &i)));
    %let varwrit = %sysfunc(tranwrd(&varwritq, ~,   ));

    /* creating var vars from list, prefix &prefix._ means prevalent  */
    %IF &type='condition' %THEN %DO; 
      %let suffix = bl; %let prefix = bl;  
      %END;
    %ELSE %IF &type='med' %THEN %DO;
      %let suffix = last; %let prefix = bl;
      %END;
    &prefix.&yrspreindex.yr_&var = .; label  &prefix.&yrspreindex.yr_&var=Baseline &varwrit. &nyrspreindex year preindex; 
	if &var._&suffix eq 0 then  &prefix.&yrspreindex.yr_&var=0; 
    else if (entry-&var._&suffix) ge tmp_yrslookback&yrspreindex.  then do;
        &prefix.&yrspreindex.yr_&var= 1; 
    end; else if (entry-&var._&suffix) lt tmp_yrslookback&yrspreindex.  then  &prefix.&yrspreindex.yr_&var.=0;    
   
  %END;
%if &type='med' %then %do; 
&prefix.&yrspreindex.yr_nsaids= (&prefix.&yrspreindex.yr_ass|&prefix.&yrspreindex.yr_allnsa|&prefix.&yrspreindex.yr_cox2|&prefix.&yrspreindex.yr_diclo|&prefix.&yrspreindex.yr_ibu|&prefix.&yrspreindex.yr_napro|&prefix.&yrspreindex.yr_otnsa|&prefix.&yrspreindex.yr_para);
label &prefix.&yrspreindex.yr_nsaids = Baseline all NSAIDs &nyrspreindex year preindex;
%end;

%mend createvar;  