/*****************************************************************************************************/
/* Program: /mnt/files/datasources/references/macros/table1.sas                                      */
/* Purpose: Produce output for a typical Table 1: Baseline Covariates                                */
/*                                                                                                   */
/* Created on: November 5, 2011                                                                      */
/* Created by: Virginia Pate                                                                         */
/*                                                                                                   */
/* Inputs: INDS = one or two level name of the input dataset to be used to create the table; data    */
/*                set should have one record per ID                                                  */
/*                                                                                                   */
/*         COLVAR  = name of the variable that identifies the analysis group for the given record;   */
/*                   the final table will have one column for each distinct value of COLVAR          */
/*                                                                                                   */
/*         ROWVARS = a list of the variables to be summarized in the table; each variable will have  */
/*                   one (or multiple) rows in the final table.  The variables should be listed in   */
/*                   the order in which they should appear in the table.  Variable names should be   */
/*                   separated with a space                                                          */
/*                                                                                                   */
/*         WGTVAR = name of variable to be used for weighting (leave missing for unweighted)         */
/*                                                                                                   */
/*         MAXLEVELS = the highest number of unique values that a numeric variable can have a be     */
/*                     classified as a categorical variable - if the variable has >&MAXLEVELS        */
/*                     unique values, it will be treated as a continuous variable                    */
/*                                                                                                   */
/*         PCTONLY = Y/N to indicate whether to include Ns(N) or only percentages(Y) for categorical */
/*                   variables (default = N, meaning N(%) will be presented)                         */
/*                                                                                                   */
/*         CONTSTAT = continuous variable statistic (default = mean)                                 */
/*                    mean: mean(SD), median: median(IQR)                                            */
/*                                                                                                   */
/*                                                                                                   */
/* Details: This macro produces a typical Table 1.  The final table will have one column for each    */
/*          distinct value of COLVAR, with the largest group in the first column, plus a total       */
/*          column as the last column.  Continuous variables are presented as mean(SD).  Two level   */
/*          categorical variables are presented as N(%) for the larger group (which is specified in  */
/*          the Characteristics column).  Categorical variables with more than two levels are        */
/*          presented as N(%) for each distinct level, listed in ascending order by value of the     */
/*          variable.                                                                                */
/*                                                                                                   */
/* Example macro call: %table1(inds=der.cohort_bl,                                                   */
/*                             colvar=trt,                                                           */
/*                             rowvars=age sex race chf hpt cancer,                                  */
/*                             maxlevels=3,                                                          */
/*                             outFile=Table 1)                                                      */
/*                                                                                                   */
/* Updates:                                                                                          */
/*    9/12/2018 - corrected SMD calculation for proportions!                                         */
/*    10/2/2019 - added options PCTONLY and CONTSTAT                                                 */
/*****************************************************************************************************/


%macro table1a(inds=, colVar=, rowVars=, wgtVar=, maxLevels=4, pctOnly=N, contStat=mean);

   ods noptitle escapechar='~'; options minoperator;

/***************************************************************************/
/**  STEP 1 - PREPARE DATASET & TABLE, USING BYGROUP VARIABLE AS COLUMNS  **/
/***************************************************************************/

/*** STEP 1A - GET DATASET AND LIBNAME ***/
/*Parse libname and dataset name from &inds.  If only one level, assign libname=WORK*/
   %IF %INDEX(&inds, .)>0 %THEN %DO;
      %LET libname = %UPCASE(%SCAN("&inds",1,"."));
      %LET ds = %UPCASE(%SCAN("&inds",2,"."));
   %END;/*end libname specified*/ %ELSE %DO;
      %LET libname = WORK;
      %LET ds = %UPCASE(&inds);
   %END;/*end libname not specified*/
   %LET colVar = %UPCASE(&colVar);

/*** STEP 1B - GET BY GROUP (COLUMN) DATA ***/
   /*Get BY GROUP variable information: variable type, label, format, distinct levels, etc.*/
   proc contents data=&libname..&ds noprint out=metadata(keep=name type label format length); run;

   /*The distinct levels of BYGROUP will be used to create variable names (and later table columns)*/
   /*Therefore, we need to apply a format if it has one and they must be character variables*/
   /*Also, get N for each level of BYGROUP to use in column headers*/
   data _null_; set metadata(where=(upcase(name)="&colVar"));
      if type=2 and format='$' then format=cats(format, put(length,8.),'.'); 
         else if type=2 and format='' then format=cats('$', put(length,8.),'.');
         else if type=1 and format='' then format='8.'; 
         else if format ne '' then format=cats(format,'.');
      if type=2 then call symput('colType','char'); else call symput('colType','num');
      call symput('colFMT', format); run;

   proc sql noprint;  select distinct 
           put(&colVar, &colFMT.), 
           /*case when count(*)<11 then 'NTSR' else*/ put(count(*),comma12.) /*end*/ as colN
      into :colLabel1-:colLabel10, :colN1-:colN10
      from &inds group by put(&colVar,&colFmt.);
      %LET NumCol = &SqlObs;
   quit;
   
   %DO l=1 %TO &numCol; 
        %IF &&colN&l = NTSR %THEN %DO;
           %PUT ********* All columns must include at least 11 people in order to run table *********;
          %ABORT;
        %END;     
        %IF "%SYSFUNC(COMPRESS(&&colLabel&l,,kns))" ^= "&&colLabel&l" OR 
          %SUBSTR(&&colLabel&l,1,1) IN 0 1 2 3 4 5 6 7 8 9 _ %THEN %DO;
           %PUT ********* All formatted column variable values or, if no format is applied *********;
           %PUT ********* to the column variable then unformatted column variable values, *********;
           %PUT ********* must be a valid SAS variable name *********; 
         %ABORT;
     %END;  
   %END;

   proc sql noprint; 
     select distinct  put(&colVar,&colFMT.), 
            case when count(*)<11 then 'NTSR' else  
              %IF &wgtVar ^=  %THEN put(sum(&wgtvar), comma12.0); %ELSE put(count(*), comma12.); end as colN
         into          :colLabel1-:colLabel&numCol., :colN1-:colN&numCol.
        from &inds group by put(&colVar,&colFMT.) order by colN desc;

     select case when count(*)<11 then 'NTSR' else %IF &wgtVar ^=  %THEN strip(put(sum(&wgtvar), comma12.0)); %ELSE strip(put(count(*), comma12.)); end
         into :totN from &inds;     quit;

   %DO l=1 %TO &numCol; %LET col&l = %SYSFUNC(TRANSLATE(&&colLabel&l,_,%STR( ))); %END;

/*** STEP 1C - CREATE SHELL ***/ 
   /*Create shell dataset using variable names and labels created above*/
   data final; length row $250 %DO i=1 %TO &NumCol; &&col&i.._pct &&col&i.._days &&col&i.._days1 %END; 
						sdiff_pct sdiff_days sdiff_days1 $100 order rowOrder 8;
      label row = 'Characteristic' 
            %DO i=1 %TO &NumCol; &&col&i.._pct = "&&colLabel&i ~n N=&&colN&i" 
											&&col&i.._days = "Days Since Last ~n (&&colLabel&i)" 
											&&col&i.._days1= "Days Since First ~n (&&colLabel&i)"
				%END;;              
      set _null_;     run;

/****************************************************/
/**  STEP 2 - PROCESS VARIABLES FOR ROWS OF TABLE  **/
/****************************************************/

   /*Now process each variable in the variable list - VARLIST will serve as the ROWS*/     
   /*Loop through each variable listed in &varlist*/
   %LET NumRow = %SYSFUNC(countw(&rowVars));
   %DO r=1 %TO &NumRow;  %LET rowVar = %SCAN(&rowVars,&r);

/*** STEP 2A - GET METADATA ON VARIABLE ***/
   /*Get variable LABEL to serve as the value for the Covariate column of Table 1*/
   /*Get variable FORMAT to ensure output dataset is correct*/
   data _null_; set metadata(where=(substr(upcase(name),4)="%upcase(&rowVar)"));
      if type=2 and format='$' then format=cats(format, put(length,8.),'.'); 
         else if type=2 and format='' then format=cats('$', put(length,8.),'.');
         else if type=1 and format='' then format='8.'; 
         else if format ne '' then format=cats(format,'.');
      if type=2 then call symput('rowType','char'); else call symput('rowType','num');
      if label='' then label=propcase(name);
      call symput('rowFMT', format);  call symput('rowLabel', label); run;

   /*Determine if variable is CONTINUOUS OR CATEGORICAL based on the variable type and the number of distinct values*/
   proc sql noprint; 
      select %IF &rowFMT =  %THEN  
         /*no FMT*/ count(distinct bl_&rowVar)               ;/*end no FMT*/ %ELSE  
         /*FMT   */ count(distinct put(bl_&rowVar,&rowFMT.)) ;/*end FMT*/ 
               into :rowLevel from &inds; quit;

   %IF &rowLevel = 1 %THEN %DO;           %LET type = ;    %END; %ELSE
   %IF &rowType = char %THEN %DO;         %LET type = cat; %END;/*end char*/ %ELSE 
   %IF (&rowLevel<=&maxLevels) %THEN %DO; %LET type = cat; %END;/*end <MaxLevels*/ %ELSE %DO; 
                                          %LET type = con; %END;/*end ow*/

	%IF &rowLevel=1 %THEN %DO;
		proc sql noprint; select case when bl_&rowVar=1 then 'Y' else 'N' end into :runDays from &inds; quit;
	%END; %ELSE %IF &rowLevel>1 %THEN %DO; %LET runDays=Y; %END;
	%IF &runDays=N %THEN %GOTO NEXTVAR;

   /*For BINARY variables, use yes if y/n variable, otherwise use the smaller group as the group to report*/
   /*For variables with >2 levels, report each level*/
	%IF &rowLevel=2 %THEN %DO;
		%LET rowRefVal=1; 		%LET rowRefValF=1;		%LET rowRefLabel=1;
	%END; %ELSE %IF &rowLevel>2 %THEN %DO;
		proc sql noprint; select   distinct 
      					bl_&rowVar as var,  bl_&rowVar,           bl_&rowVar
              into  :rowRefVal,  :rowRefValF,          :rowRefLabel 
              from &inds having var=min(var); quit;
   %END;

	proc sql noprint; select case when bl_days1=1 then 'Y' else 'N' end into :bldays1 
		from vars where base_name="%UPCASE(&rowVar)"; quit;

	data t&rowVar.; length row $250; order=&r-0.5; rowOrder=1; row = "%UPCASE(&rowVar)"; run;

/************************************************************************/
/**  STEP 3 - GET PROPORTIONS & STANDARDIZED DIFFERENCES FOR % WITH RX **/
/************************************************************************/
      proc freq data=&inds;  Title "&rowVar by &colVar";
         %IF &wgtvar ^=  %THEN %DO; weight &wgtvar; %END;
         tables &colVar * bl_&rowVar / missing;  %IF &rowFMT ^=  %THEN %DO; format bl_&rowVar &rowFMT.; %END;/*end no FMT*/   
         ods output crosstabfreqs=&rowVar.(
               keep   = &colVar bl_&rowVar rowPercent Percent Frequency _type_ 
               rename = (bl_&rowVar=&rowVar.2)                                
               %IF &rowLevel = 2 %THEN where = ( strip(put(&rowVar.2,&rowFMT.)) = "&rowRefValF");
               ) ; run;
      data &rowVar.2 (keep=group &rowVar &colVar %IF &numCol>1 %THEN rowpct; %IF &rowLevel>2 %THEN row rowOrder &rowVar.2;); set &rowVar; 
         length %IF &rowLevel>2 %THEN row $250; group &rowVar $100; %IF &rowLevel>2 %THEN %DO; rowOrder=_N_; %END;/*end rowLevel>2*/;
         if _type_ = '11' then do; %IF &numCol>1 %THEN %DO; rowpct=rowpercent/100; %END;
            group =                                            %IF &colTYPE = num %THEN %DO; %IF &colFMT =  %THEN 
               /*num, no FMT*/ "grp_" || strip(put(&colVar,8.));  %ELSE 
               /*num,    FMT*/ put(&colVar, &colFMT.);            %END;/*end num*/   %ELSE %DO; %IF &colFMT =  %THEN 
               /*char,no FMT*/ &colVar;                           %ELSE 
               /*char,   FMT*/ put(&colVar, &colFMT.);            %END;/*end char*/ ; 
            if Frequency>11 then &rowVar = %IF &pctOnly=N %THEN strip(put(Frequency,comma12.)) || ' (' ||; strip(put(rowpercent,8.1)) %IF &pctOnly=N %THEN || '%)' ;;
            else &rowVar = 'NTSR';
         end; else if _type_ = '01' then do;
         group = 'Total';
         if Frequency>11 then &rowVar = %IF &pctOnly=N %THEN strip(put(Frequency,comma12.)) || ' (' ||; strip(put(percent,8.1)) %IF &pctOnly=N %THEN || '%)';; else &rowVar = 'NTSR';
         end;  else delete;
                    
         /*For multi-level variables, create one row per value of ROWVAR */
         %IF &rowLevel > 2 %THEN %DO;                                           %IF &rowType=char %THEN %DO; %IF &rowFMT =  %THEN %DO;
            /*char, no FMT*/row = '~R/RTF"\tab" ' || strip(&rowVar.2);                                      %END; %ELSE %DO; 
            /*char, FMT   */row = '~R/RTF"\tab" ' || strip(put(&rowVar.2,&rowFMT.));                %END; %END;/*end char*/ %ELSE %DO; %IF &rowFMT = %THEN %DO; 
            /*num, no FMT */row = '~R/RTF"\tab"Group ' || strip(put(&rowVar.2,8.));       %END; /*end num, no FMT*/ %ELSE %DO; 
            /*num, FMT    */row = '~R/RTF"\tab" ' || strip(put(&rowVar.2, &rowFMT.)); %END; /*end num, FMT*/ %END; /*end num*/ %END;/*end rowLevel>2*/
      run;

      proc datasets lib=work nolist nodetails; modify &rowVar.2; format &colVar; run;quit;

      %IF &rowLevel>2 %THEN %DO; proc sort data=&rowVar.2; by row; run; %END;/*end rowLevel>2*/
      proc transpose data=&rowVar.2 out=&rowVar.T;  %IF &rowLevel>2 %THEN %DO; by row; %END; var &rowVar; id group; run;
      %IF &NumCol>1 %THEN %DO; %IF &rowLevel>1 %THEN %DO;
         proc transpose data=&rowVar.2 out=meanT prefix=mean; where group ne 'Total'; %IF &rowLevel>2 %THEN %DO; by row; %END;/*end rowLevel>2*/
               var rowpct; id group; run;*9/12/18 - corrected to use proportion rather than percentage in sdiff calculation!;
         data &rowVar.3; set meanT; length %DO c=2 %TO &numCol; sdiff&c %END; $12; 
            %DO c=2 %TO &numCol; 
            	d&c=round(abs((mean&col1-mean&&col&c)/sqrt(abs((mean&col1*(1-mean&col1)+mean&&col&c*(1-mean&&col&c)))/2)),0.001);
               sdiff&c = put(d&c, 8.3); %END;*end c=2 to numCol loop; 
				if comp='' then comp=''; if dpp4='' then dpp4='';
            keep %DO c=2 %TO &numCol; sdiff&c %END; %IF &rowLevel>2 %THEN row; ; 
            label %DO c=2 %TO &numCol; sdiff&c="Stzd Diff ~n Col 1 vs Col &c" %END;; run; 
		%END;*end NumCol>1; %END;*end rowLevel>1;

      data &rowVar._pctRx; length row $250 comp dpp4 sdiff2 $100; merge %IF &NumCol>1 %THEN %DO; %IF &rowLevel>1 %THEN &rowVar.3; %END; &rowVar.T(drop=_name_); rowOrder=_N_; order=&r+0.1;
           %IF &rowLevel<3 %THEN %DO; row=%IF &bldays1=Y %THEN "% with BL Rx"; %ELSE "% with BL Dx";; %END;
			  if comp='' then comp=''; if dpp4='' then dpp4=''; if sdiff2='' then sdiff2='';
		run;

/****************************************************************************/
/**  STEP 4 - GET AVERAGE (OR MEDIAN) DAYS SINCE LAST RX FOR ALL WITH A RX **/
/****************************************************************************/
	%IF &runDays=Y %THEN %DO;
      proc means data=&inds mean std vardef=wdf %IF &contStat=median %THEN median q1 q3;;
			WHERE BL_&ROWVAR>0; /*8/31/20 - RESTIRCT TO THOSE WITH VALUE*/
         class &colVar;  var d&rowVar; %IF &wgtvar ^=  %THEN %DO; weight &wgtvar; %END;
         %IF &colFMT ne  %THEN %DO; format &colVar &colFMT.; %END; /*end cont, no FMT*/
         ods output summary=&rowVar;          run;
		
      proc means data=&inds mean std vardef=wdf %IF &contStat=median %THEN median q1 q3;; Title "&rowVar Overall";
 			WHERE BL_&ROWVAR>0; /*8/31/20 - RESTIRCT TO THOSE WITH VALUE*/
         %IF &wgtvar ^=  %THEN %DO; weight &wgtvar; %END;
         var d&rowVar;  ods output summary=&rowVar.overall;   run;

      proc datasets lib=work nolist nodetails; modify &rowVar; format &colVar; run;quit;

      data &rowVar.2 (keep=group &rowVar &colVar d&rowVar._mean d&rowVar._stddev); set &rowVar. (in=bygroup ) &rowVar.overall (in=all ); length group &rowVar $100 ;
         if bygroup then group =                                  %IF &colTYPE = num %THEN %DO; %IF &colFMT =  %THEN 
            /*num, no FMT*/ "grp_" || strip(put(&colVar,8.));    %ELSE 
            /*num,    FMT*/ strip(put(&colVar, &colFMT.));       %END; /*end num*/  %ELSE %DO; %IF &colFMT =  %THEN 
            /*char,no FMT*/ strip(&colVar);                      %ELSE 
            /*char,   FMT*/ strip(put(&colVar, &colFMT.));       %END;/*end char*/ ; 
         else if all then group = 'Total';
         &rowVar = %IF &contStat=mean %THEN strip(put(d&rowVar._mean,8.1)) || '(' || strip(put(d&rowVar._stddev,8.2)) || ')';
             %ELSE %IF &contStat=median %THEN strip(put(d&rowVar._median,8.1)) || '(' || strip(put(d&rowVar._q1,8.1)) || '-' || strip(put(d&rowVar._q3,8.1)) || ')';;
      run;

      proc transpose data=&rowVar.2 out=&rowVar.T(drop=_name_ _label_);                                  var &rowVar;         id group;   run;
      proc transpose data=&rowVar.2 out=meanT(drop=_name_ _label_) prefix=mean; where group ne 'Total';  var d&rowVar._mean;   id group; run;
      proc transpose data=&rowVar.2 out=stdT(drop=_name_ _label_)  prefix=std;  where group ne 'Total';  var d&rowVar._stddev; id group; run;

     %IF &NumCol>1 %THEN %DO; %IF &rowLevel>1 %THEN %DO;
         data &rowVar.3; merge meanT stdT; length %DO c=2 %TO &numCol; sdiff&c %END; $12; 
            %DO c=2 %TO &numCol;
               d&c=round(abs((mean&col1-mean&&col&c)/sqrt((std&col1*std&col1+std&&col&c*std&&col&c)/2)),0.001);
               sdiff&c = put(d&c, 8.3); %END;
            keep %DO c=2 %TO &numCol; sdiff&c %END;; 
            label %DO c=2 %TO &numCol; sdiff&c ="Stdz Diff ~n Col 1 vs Col &c" %END;; run; %END; %END;

      data &rowVar._days; length row $250 dpp4i comp sdiff2 $100; 
			merge %IF &numCol>1 %THEN %DO; %IF &rowLevel>1 %THEN &rowVar.3; %END; &rowVar.T ; 

         /*For multi-level variables, create one row per value of ROWVAR */
         %IF &rowLevel > 2 %THEN %DO;                                           %IF &rowType=char %THEN %DO; %IF &rowFMT =  %THEN %DO;
            /*char, no FMT*/row = '~R/RTF"\tab" ' || strip(&rowVar.2);                                      %END; %ELSE %DO; 
            /*char, FMT   */row = '~R/RTF"\tab" ' || strip(put(&rowVar.2,&rowFMT.));                %END; %END;/*end char*/ %ELSE %DO; %IF &rowFMT = %THEN %DO; 
            /*num, no FMT */row = '~R/RTF"\tab"Group ' || strip(put(&rowVar.2,8.));       %END; /*end num, no FMT*/ %ELSE %DO; 
            /*num, FMT    */row = '~R/RTF"\tab" ' || strip(put(&rowVar.2, &rowFMT.)); %END; /*end num, FMT*/ %END; /*end num*/ %END;/*end rowLevel>2*/
/*			%ELSE %DO; %IF &bldays1=Y %THEN %DO;*/
/*            row= %IF &contStat=mean %THEN "Days Since Last Rx, mean(SD)"; %ELSE %IF &contStat=median %THEN "Days Since Last Rx, median(IQR)";;*/
/*			%END; %ELSE %DO;*/
/*            row= %IF &contStat=mean %THEN "Days Since Last Dx, mean(SD)"; %ELSE %IF &contStat=median %THEN "Days Since Last Dx, median(IQR)";;*/
/*			%END; %END;         */
			order=&r+0.2; rowOrder=_N_; 	
			if dpp4i='' then dpp4i=''; if comp='' then comp=''; if sdiff2='' then sdiff2='';
		run;



/****************************************************************************/
/**  STEP 5 - GET AVERAGE (OR MEDIAN) DAYS SINCE LAST RX FOR ALL WITH A RX **/
/****************************************************************************/
	%IF &bldays1=Y %THEN %DO;
      proc means data=&inds mean std vardef=wdf %IF &contStat=median %THEN median q1 q3;;
			WHERE BL_&ROWVAR>0; /*8/31/20 - RESTIRCT TO THOSE WITH VALUE*/
         class &colVar;  var s&rowVar; %IF &wgtvar ^=  %THEN %DO; weight &wgtvar; %END;
         %IF &colFMT ne  %THEN %DO; format &colVar &colFMT.; %END; /*end cont, no FMT*/
         ods output summary=&rowVar;          run;

      proc means data=&inds mean std vardef=wdf %IF &contStat=median %THEN median q1 q3;; Title "&rowVar Overall";
			WHERE BL_&ROWVAR>0; /*8/31/20 - RESTIRCT TO THOSE WITH VALUE*/
         %IF &wgtvar ^=  %THEN %DO; weight &wgtvar; %END;
         var s&rowVar;  ods output summary=&rowVar.overall;   run;

      proc datasets lib=work nolist nodetails; modify &rowVar; format &colVar; run;quit;

      data &rowVar.2 (keep=group &rowVar &colVar s&rowVar._mean s&rowVar._stddev); set &rowVar. (in=bygroup ) &rowVar.overall (in=all ); length group &rowVar $100 ;
         if bygroup then group =                                  %IF &colTYPE = num %THEN %DO; %IF &colFMT =  %THEN 
            /*num, no FMT*/ "grp_" || strip(put(&colVar,8.));    %ELSE 
            /*num,    FMT*/ strip(put(&colVar, &colFMT.));       %END; /*end num*/  %ELSE %DO; %IF &colFMT =  %THEN 
            /*char,no FMT*/ strip(&colVar);                      %ELSE 
            /*char,   FMT*/ strip(put(&colVar, &colFMT.));       %END;/*end char*/ ; 
         else if all then group = 'Total';
         &rowVar = %IF &contStat=mean %THEN strip(put(s&rowVar._mean,8.1)) || '(' || strip(put(s&rowVar._stddev,8.2)) || ')';
             %ELSE %IF &contStat=median %THEN strip(put(s&rowVar._median,8.1)) || '(' || strip(put(s&rowVar._q1,8.1)) || '-' || strip(put(&rowVar._q3,8.1)) || ')';;
      run;

      proc transpose data=&rowVar.2 out=&rowVar.T(drop=_name_ _label_);                                  var &rowVar;         id group;   run;
      proc transpose data=&rowVar.2 out=meanT(drop=_name_ _label_) prefix=mean; where group ne 'Total';  var s&rowVar._mean;   id group; run;
      proc transpose data=&rowVar.2 out=stdT(drop=_name_ _label_)  prefix=std;  where group ne 'Total';  var s&rowVar._stddev; id group; run;

     %IF &NumCol>1 %THEN %DO; %IF &rowLevel>1 %THEN %DO;
         data &rowVar.3; merge meanT stdT; length %DO c=2 %TO &numCol; sdiff&c %END; $12; 
            %DO c=2 %TO &numCol;
               d&c=round(abs((mean&col1-mean&&col&c)/sqrt((std&col1*std&col1+std&&col&c*std&&col&c)/2)),0.001);
               sdiff&c = put(d&c, 8.3); %END;
            keep %DO c=2 %TO &numCol; sdiff&c %END;; 
            label %DO c=2 %TO &numCol; sdiff&c ="Stdz Diff ~n Col 1 vs Col &c" %END;; run; %END; %END;

	      data &rowVar._days1; length row $250 dpp4 comp sdiff2 $100; 
				merge %IF &numCol>1 %THEN %DO; %IF &rowLevel>1 %THEN &rowVar.3; %END; &rowVar.T ; 
	         %IF &rowLevel > 2 %THEN %DO;                                           %IF &rowType=char %THEN %DO; %IF &rowFMT =  %THEN %DO;
	            /*char, no FMT*/row = '~R/RTF"\tab" ' || strip(&rowVar.2);                                      %END; %ELSE %DO; 
	            /*char, FMT   */row = '~R/RTF"\tab" ' || strip(put(&rowVar.2,&rowFMT.));                %END; %END;/*end char*/ %ELSE %DO; %IF &rowFMT = %THEN %DO; 
	            /*num, no FMT */row = '~R/RTF"\tab"Group ' || strip(put(&rowVar.2,8.));       %END; /*end num, no FMT*/ %ELSE %DO; 
	            /*num, FMT    */row = '~R/RTF"\tab" ' || strip(put(&rowVar.2, &rowFMT.)); %END; /*end num, FMT*/ %END; /*end num*/ %END;/*end rowLevel>2*/
				%ELSE %DO; row= %IF &contStat=mean %THEN "Days Since First Rx, mean(SD)"; %ELSE %IF &contStat=median %THEN "Days Since Last Rx, median(IQR)";; %END;
	         order=&r+0.3; rowOrder=_N_; 
				if dpp4i='' then dpp4i=''; if comp='' then comp=''; if sdiff2='' then sdiff2='';
			run;
	%END; /*end bldays1=Y*/
	%END; /*end runDays=Y*/

	%IF &rowLevel<3 %THEN %DO;
		data &rowVar;
			merge t&rowVar.(keep=row order) 
					&rowVar._pctrx(rename=(comp=comp_pct dpp4i=dpp4i_pct sdiff2=sdiff_pct) keep=comp dpp4i sdiff2)
				%IF &runDays=Y %THEN %DO;
					&rowVar._days(rename=(comp=comp_days dpp4i=dpp4i_days sdiff2=sdiff_days) keep=comp dpp4i sdiff2)
					%IF &bldays1=Y %THEN &rowVar._days1(rename=(comp=comp_days1 dpp4i=dpp4i_days1 sdiff2=sdiff_days1) keep=comp dpp4i sdiff2);
				%END;;
			label sdiff_pct='Stdz Diff (%)' sdiff_days1='Stdz Diff (Days Since First)' sdiff_days='Stdz Diff (Days Since Last)';
		run;
	%END;
	%ELSE %DO;
		data &rowVar.TopRow; merge t&rowVar. 
				%IF &runDays=Y %THEN %DO;
					&rowVar._days(rename=(comp=comp_days dpp4i=dpp4i_days sdiff2=sdiff_days) keep=comp dpp4i sdiff2)
					%IF &bldays1=Y %THEN &rowVar._days1(rename=(comp=comp_days1 dpp4i=dpp4i_days1 sdiff2=sdiff_days1) keep=comp dpp4i sdiff2);
				%END;;
		run;
		data &rowVar.; set &rowVar.TopRow &rowVar._pctrx(rename=(comp=comp_pct dpp4i=dpp4i_pct sdiff2=sdiff_pct) keep=row comp dpp4i sdiff2); run;
	%END;

	data final; set final &rowvar; run;

	%NEXTVAR:
	%END;

%mend table1a;

