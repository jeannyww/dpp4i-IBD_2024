/*------------------------------------------------------------------*
| MACRO NAME  : consort
| SHORT DESC  : Creates a consort diagram from pre-derived data
*------------------------------------------------------------------*
| CREATED BY  : Meyers, Jeffrey                 (12/03/2020 3:00)
*------------------------------------------------------------------*
| VERSION UPDATES:
| 1.0 - 12/03/2020
|  Initial Release
*------------------------------------------------------------------*
| PURPOSE
|
| This macro creates a CONSORT diagram based on a dataset.  The alignment,
| text, arrows, and binning is all calculated within the macro.  The paths
| of the CONSORT can be split multiple times and re-merged as needed.
| Annotation can be added to label different portions of the CONSORT.
|
| 1.0: REQUIRED PARAMETERS
|    
|    DATA = Dataset with one row per patient and includes all ID, NODE, SPLIT and FREQ variables 
|    ID = Variable including unique patient IDs.  Patients cannot be repeated in the dataset.  Required for Counting
|    NODE = Space delimited Variable list of variables that contains text for each box.  Should be unique for each SPLIT path.
|           The ~ symbol will indicate a line break.
|
| 2.0: OPTIONAL PARAMETERS
|   
|    2.1: Optional Consort Parameters
|
|       SPLIT = Variables that determine splits in the consort chart paths (going top to bottom). Matches up 
|               one-to-one with each node.  Delimited by | between nodes.  Different behavior depending on REMERGE.
|               REMERGE=0: Last SPLIT variable will carry forward if left missing until the next new SPLIT variable.
|               REMERGE=1: Paths will remerge if SPLIT is left missing for a NODE variable
|       REMERGE = Indicates whether paths should remerge when SPLIT is left missing.  0 is No (default), 1 is Yes
|       OFFREASON = Variables that contain the reasons for not going to the next node to be contained in off treatment text box.
|                   Last listed variable is carried forward.  Matches one to one with node list.  Delimited by |.  
|                   Variable label is used as the header of the off treatment text box.  Patient is determined to be off treatment
|                   when they are no longer in any nodes.
|       FREQ = Variables to add frequency counts to a text box.  Matches one to one with node list.  Delimited by |
|       END_SUMMARY = One or more variables to be summarized in the bottom row of the consort.  Each variable will be summarized separately
|                     at the end of each path.
|
|    2.2: Debugging Option
|
|       DEBUG = Determines if notes and MPRINT are turned on and whether temporary datasets are left behind.
|               0 = No (default), 1 = Yes
|
|    2.3: Graph Options
|       2.3.1: Axis Options
|          XMIN = Minimum of x-axis.  Graph is created based on a 0-100 percent scale.  Default is -5.
|          XMAX = Maximum of x-axis.  Graph is created based on a 0-100 percent scale.  Default is 105.
|          YMIN = Minimum of y-axis.  Graph is created based on a 0-100 percent scale.  Default is -5.
|          YMAX = Maximum of x-axis.  Graph is created based on a 0-100 percent scale.  Default is 105.
|       2.3.2: Adjusting Graph Components Options
|          WEIGHTED_ROW_HEIGHT = Determines if row heights are weighted by number of lines of text. 1=Yes, 0=No (equal weights to all rows).  Default=0.
|          MULTILINE_ADJUST = Gives the percentage weight that each row of text should have for height of off-treatment boxes to align arrowheads better.  Default is AUTO.
|                             AUTO attempts to guess based on image Height and FONT_SIZE.  Values can be any number greater than 0.
|          ARROWHEAD_ADJUST = Adjusts the veritcal position of arrowheads to avoid being covered by text boxes.  Default is 0.2. Options are any value greater than 0. 
|          OFFREASON_XADJUST = Adjusts the horizontal position of off treatment boxes for each split phase (separated by |).  Default is 0.
|          INDENT_TEXT = Specifies the text used to indent frequency lists in the off-treatment variables, FREQ variables, and END_SUMMARY variables.
|                        Default is 'A0A0A0'x||'-'.  'A0'x is a non-breaking space character.
|          OFFREASON_LABEL = Specifies a label for the offreason variables.  The | deliminates between different nodes and the ` deliminates between different 
|                            variables in the same node.  The default is the label currently assigned to the variable.
|          NO_OFFREASON_TEXT = Specifies text to use when a patient is off-treatment but the reason variable is missing.  Default is Active Treatment.
|       2.3.3: Graph Reference Labels
|          2.3.3.1: Reference Text Options: When specifying options for multiple REF_TEXT values the last option listed will be carried forward
|              REF_TEXT = Specifies reference text to list within the consort diagram.  Multiple references can be specified with | delimiters
|              REF_X = Specifies x coordinate for REF_TEXT.  The | delimiter distinguishes between multiple reference texts
|              REF_Y = Specifies y coordinate for REF_TEXT.  The | delimiter distinguishes between multiple reference texts
|              REF_ROTATE = Specifies rotation for REF_TEXT in units of degrees moving counter-clockwise.  The | delimiter distinguishes between multiple reference texts
|          2.3.3.2: Reference Text box Options: a text box is drawn at the x/y coordinates that can be styled differently than the rest of the consort diagram.
|              REF_BACKGROUND_COLOR = Specifies background text REF_TEXT.  The | delimiter distinguishes between multiple reference texts.  Default is WHITE.
|              REF_BOX_EXPAND = Specifies text box horizontal expansion in pixels.  The | delimiter distinguishes between multiple reference texts.  Default is 0.
|              REF_BORDER_COLOR = Specifies border color for REF_TEXT.  The | delimiter distinguishes between multiple reference texts.  Default is BLACK.
|              REF_BORDER_WIDTH = Specifies border width in pixels for REF_TEXT. Only one value is allowed.  Default is 1.
|              REF_FONT_COLOR = Specifies REF_TEXT font colors.  The | delimiter distinguishes between multiple reference texts.  Default is BLACK.
|              REF_FONT_SIZE = Specifies REF_TEXT font size.  The | delimiter distinguishes between multiple reference texts. Default is 8pt.
|          2.3.3.3: Line Options: when line size>0 a reference line will run horizontally across the consort
|              REF_LINE_SIZE = 0 Specifies the thickness for the reference line.  The | delimiter distinguishes between multiple reference texts.  Default is 0.
|              REF_LINE_PATTERN = Specifies the line pattern for the reference line.  The | delimiter distinguishes between multiple reference texts.  Default is SOLID.
|              REF_LINE_COLOR = Specifies the color for the reference line.  The | delimiter distinguishes between multiple reference texts.  Default is BLACK.
|       2.3.4: Graph Space Annotation Options
|          SHOW_LIMITS = Annotates the rows and columns that line up the text boxes and displays the x/y values. Options are 1 (yes) and 0 (no). Default is 0. 
|          SHOW_ANCHORPOINTS = Displays where the text boxes are anchored to in the graph space. Options are 1 (yes) and 0 (no). Default is 0.
|          SHOW_GRID = Adds grid lines for 10% increments in each axis. Options are 1 (yes) and 0 (no). Default is 0. 
|          FREQ_SHOW_LABELS = Determines if labels are shown for FREQ variables in the text boxes. Options are 1 (yes) and 0 (no). Default is 1.
|          SHOW_SPLIT_HEADERS = Determines if header rows are shown for SPLIT variables. Can be changed for every new SPLIT or remerge phase.
|                               Last value carries forward with the | as a delimiter.  Options are 1 (yes) and 0 (no).  Default is 1.
|       2.3.5:  Arrow Line Options
|          SHOW_ARROWHEADS = Determines if connecting lines have arrowheads. Options are 1 (yes) and 0 (no).  Default is 1.
|          ARROWHEAD_SHAPE = Determines the type of arrowhead shape for the connecting lines.  Options are OPEN, FILLED, or BARBED.  Default is FILLED.
|          LINE_COLOR = Determines the color of the connecting lines.  Default is BLACK.
|          LINE_SIZE = Determines the thickness of the connecting lines.  Default is 1pt.
|       2.3.6: Text Box Options
|          TEXTBOX_OUTLINE =Determines if the outlines are drawn on the text boxes.  1=yes, 0=no.  Default=1.
|          TEXTBOX_OUTLINE_COLOR = Determines the textbox outline color.  Default is black.
|          TEXTBOX_BACKGROUND_COLOR = Determines the textbox background color.  Default is white.
|          TEXTBOX_OFFTRT_ALIGN = Determines which direction the off-treatment reason textboxes split off to.  Options are OUTSIDE, LEFT and RIGHT.  Default is OUTSIDE.
|       2.3.7: Font Options
|          FONT = Specifies which font to use.  Font must be installed by user prior to using.  Default is Arial.
|          FONT_SIZE = Specifies the size of the font for all text boxes in pt.  The default is 7.
|          FONT_COLOR = Specifies the color of the font for all text boxes.  Default is BLACK.
|
|    2.4: Image Options
|       HEIGHT = Determines the height of the final image in inches.  Default is 15.
|       WIDTH = Determines the width of the final image in inches.  Default is 12.
|       PLOTNAME = Determines the name of the image file.  Default is _consort.
|       PLOTTYPE = Determines the type of image file.  Default is STATIC.
|       GPATH = Determines where the image file is saved to.  Default is null. 
|       TIFFDEVICE = Specifies the type of tiff device to use for making Tiff files.  Default is TIFFP.
|       DPI = Determines the DPI of the final image.  Default is 150.
*------------------------------------------------------------------*
| OPERATING SYSTEM COMPATIBILITY
| UNIX SAS v9.4M6   :   YES
| PC SAS v9.4M6     :   YES
*------------------------------------------------------------------*
| MACRO CALL
|
| %consort (
|            DATA=,
|            ID=,
|            NODE=
|          );
*------------------------------------------------------------------*
| REQUIRED PARAMETERS
|
| Name      : DATA
| Default   : 
| Type      : Dataset Name
| Purpose   : REFER TO PARAMETER SECTION
|
| Name      : ID
| Default   :
| Type      : Patient ID variable Name
| Purpose   : REFER TO PARAMETER SECTION
|
| Name      : NODE
| Default   :
| Type      : Variable List
| Purpose   : REFER TO PARAMETER SECTION
|
*------------------------------------------------------------------*
| EXAMPLES:
|
| Dataset for Examples:
proc format;
    value off1f
        1='Ineligible'
        2='Insurance Denied';
    value off2f
        1='Withdrawal'
        2='Progression'
        3='Adverse Event'
        4='Death'
        5='Alternate Therapy';
run;
data example;
    call streaminit(1);
    array u {1500};
    do j = 1 to dim(u);*Variables;
        u(j)=rand("Uniform");
    end;
    length id 8. arm $25. gender smoke_stat $10. offtrt 8. reg rand treated neo rt surg adj comp $50.;
    do i = 1 to 1500;*Patients;
        id=i;
        call missing(reg,rand,treated,neo,surg,rt,adj,comp);
        arm=catx(' ','Arm',1+round(rand("Uniform"),1))||'~';
        gender=ifc(rand("Uniform")>0.50,'Male','Female');
        smoke_chance=rand("Uniform");
        if smoke_chance>0.66 then smoke_stat='Former';
        else if smoke_chance>0.33 then smoke_stat='Current';
        else smoke_stat='Never';
        reg='Registered~';
        if u(i)>=0.1 then do;
            rand='Randomized~';
            if u(i)>=0.15 then do;
                treated='Started~Treatment~';
                if u(i)>=0.3 then do;
                    neo='Completed Neoadjuvant~Chemotherapy~';
                    if u(i)>=0.35 and arm='Arm 2~' then rt='Completed~Neoadjuvant RT~';
                    if (arm='Arm 1~' or ^missing(rt)) and u(i)>=0.4 then do;
                        surg='Completed Surgery~';
                        if u(i)>=0.5 then do;
                            adj='Started~Adjuvant Therapy~';
                            if u(i)>=0.6 then do;
                                comp='Completed All Therapy~';
                            end;
                        end;
                    end;
                end;
                offtrt2=floor(rand("Uniform")*5+1);
            end;
            else offtrt2=floor(rand("Uniform")*3+1);
        end;
        else offtrt=floor(rand("Uniform")*2+1);
        output;
    end;
    drop u: i j;
    format offtrt off1f. offtrt2 off2f.;
    label arm='Treatment Arm' offtrt='Screen Failure' offtrt2='Off-Treatment' smoke_stat='Smoking Status';
run;  
| Example 1: Basic Example Call:
%consort(data=example,id=id,
    node=reg rand treated neo);
| Example 2: Add off treatment reasons:
%consort(data=example,id=id,
    node=reg rand treated neo,
    offreason=offtrt|offtrt2,
    offreason_label=Screen Failure|Untreated|Off-Treatment);
| Example 3: Split into multiple paths:
%consort(data=example,id=id,
    node=reg rand treated neo,
    split=|arm|gender,
    offreason=offtrt|offtrt2,
    offreason_label=Screen Failure|Untreated|Off-Treatment);
| Example 4: Add a FREQ variable:
%consort(data=example,id=id,
    node=reg rand treated neo,
    split=|arm|gender,
    freq=|gender,
    offreason=offtrt|offtrt2,
    offreason_label=Screen Failure|Untreated|Off-Treatment);
| Example 5: Remerge and separate paths:
%consort(data=example,id=id,
    node=reg rand treated neo,
    split=arm||gender,
    freq=|gender,
    offreason=offtrt|offtrt2,
    offreason_label=Screen Failure|Untreated|Off-Treatment,
    remerge=1);
|
*------------------------------------------------------------------*
| This program is free software; you can redistribute it and/or
| modify it under the terms of the GNU General Public License as
| published by the Free Software Foundation; either version 2 of
| the License, or (at your option) any later version.
|
| This program is distributed in the hope that it will be useful,
| but WITHOUT ANY WARRANTY; without even the implied warranty of
| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
| General Public License for more details.
*------------------------------------------------------------------*/

%macro consort(
    /* Required Parameters*/
    data=/*Dataset with one row per patient and includes all ID, NODE, SPLIT and FREQ variables*/, 
    id=/*Required for Counting*/,
    node=/*Space delimited Variable list of variables that contains text for each box.  Should be unique for each SPLIT path*/,
    
    /*Optional Consort Parameters*/
    split=/*Variables that determine splits in the consort chart paths (going top to bottom). Matches up 
            one-to-one with each node.  Delimited by |*/,
    remerge=0,
    offreason=/*Variables that contain the reasons for not going to the next node to be contained in off treatment text box.
                Last listed variable is carried forward.  Matches one to one with node list.  Delimited by |.  Variable
                label is used as the header of the off treatment text box*/,
    freq=/*Variables to add frequency counts to a text box.  Matches one to one with node list.  Delimited by |*/,
    end_summary=/*One or more variables to be summarized in the bottom row of the consort*/,
    
    /*Debugging Option*/
    debug=0 /*Set to 1 to turn on notes, mprint, and save the temporary datasets*/,
    /*Graph Options*/
        /*Axis Options*/
        xmin=-5 /*Minimum of x-axis.  Graph is created based on a 0-100 percent scale*/,
        xmax=105 /*Maximum of x-axis.  Graph is created based on a 0-100 percent scale*/,
        ymin=-5 /*Minimum of y-axis.  Graph is created based on a 0-100 percent scale*/,
        ymax=105 /*Maximum of y-axis.  Graph is created based on a 0-100 percent scale*/,
        
        /*Adjusting Graph Components Options*/
        weighted_row_height=0 /*Determines if row heights are weighted by number of lines of text. 1=Yes, 0=No (equal weights to all rows)*/,
        multiline_adjust=AUTO /*Gives the percentage weight that each row of text should have for height of off-treatment boxes to align arrowheads better*/,
        arrowhead_adjust=0.2 /*Adjusts the veritcal position of arrowheads to avoid being covered by text boxes*/, 
        offreason_xadjust=0 /*Adjusts the horizontal position of off treatment boxes for each split phase (separated by |)*/,
        indent_text='A0A0A0'x||'-' /*Specifies the text used to indent frequency lists in the off-treatment variables, FREQ variables, and END_SUMMARY variables*/, 
        offreason_label= /*Specifies a label for the offreason variables.  The | deliminates between different nodes and the ` deliminates between different 
                           variables in the same node*/,
        no_offreason_text=Active Treatment /*Specifies text to use when a patient is off-treatment but the reason variable is missing*/,
        
        /*Graph Reference Labels*/
            /*Reference Text Options: When specifying options for multiple REF_TEXT values the last option listed will be carried forward*/
            ref_text= /*Specifies reference text to list within the consort diagram.  Multiple references can be specified with | delimiters*/,
            ref_x= /*Specifies x coordinate for REF_TEXT.  The | delimiter distinguishes between multiple reference texts*/,
            ref_y= /*Specifies y coordinate for REF_TEXT.  The | delimiter distinguishes between multiple reference texts*/,
            ref_rotate=0 /*Specifies rotation for REF_TEXT in units of degrees moving counter-clockwise.  The | delimiter distinguishes between multiple reference texts*/,
            /*Reference Text box Options: a text box is drawn at the x/y coordinates that can be styled differently than the rest of the consort diagram.*/
            ref_background_color=white /*Specifies background text REF_TEXT.  The | delimiter distinguishes between multiple reference texts*/,
            ref_box_expand=0 /*Specifies text box horizontal expansion in pixels.  The | delimiter distinguishes between multiple reference texts*/,
            ref_border_color=black /*Specifies border color for REF_TEXT.  The | delimiter distinguishes between multiple reference texts*/,
            ref_border_width=1 /*Specifies border width in pixels for REF_TEXT. Only one value is allowed*/,
            ref_font_color=black /*Specifies REF_TEXT font colors.  The | delimiter distinguishes between multiple reference texts*/,
            ref_font_size=8pt /*Specifies REF_TEXT font size.  The | delimiter distinguishes between multiple reference texts*/,
            /*Line Options: when line size>0 a reference line will run horizontally across the consort*/
            ref_line_size=0 /*Specifies the thickness for the reference line.  The | delimiter distinguishes between multiple reference texts*/,
            ref_line_pattern=solid /*Specifies the line pattern for the reference line.  The | delimiter distinguishes between multiple reference texts*/,
            ref_line_color=black /*Specifies the color for the reference line.  The | delimiter distinguishes between multiple reference texts*/,
            
        /*Graph Space Annotation Options*/
        show_limits=0 /*Annotates the rows and columns that line up the text boxes and displays the x/y values*/, 
        show_anchorpoints=0 /*Displays where the text boxes are anchored to in the graph space*/, 
        show_grid=0 /*Adds grid lines for 10% increments in each axis*/, 
        freq_show_labels=1 /*Determines if labels are shown for FREQ variables in the text boxes*/,
        show_split_headers=1 /*Determines if header rows are shown for SPLIT variables*/,
        
        /*Arrow Line Options*/
        show_arrowheads=1 /*Determines if connecting lines have arrowheads.  Set to 0 to disable*/, 
        arrowhead_shape=filled /*Determines the type of arrowhead shape for the connecting lines.  Options are OPEN, FILLED, or BARBED*/,
        line_color=black /*Determines the color of the connecting lines*/,
        line_size=1pt /*Determines the size of the connecting lines*/,
        
        /*Text Box Options*/
        textbox_outline=1 /*Determines if the outlines are drawn on the text boxes.  1=yes, 0=no.  Default=1*/,
        textbox_outline_color=black /*Determines the outline color.  Default is black*/,
        textbox_background_color=white /*Determines the background color.  Default is white*/,
        textbox_offtrt_align=OUTSIDE /*Determines which direction the off-treatment reason textboxes split off to.  Options are OUTSIDE, LEFT and RIGHT.  Default is OUTSIDE*/,
        
        /*Font Options*/
        font=Arial /*Specifies which font to use.  Font must be installed by user prior to using*/,
        font_size=7 /*Specifies the size of the font for all text boxes in pt*/, 
        font_color=black /*Specifies the color of the font for all text boxes*/,
        
        /*Image Options*/
        height=15 /*Determines the height of the final image in inches*/, 
        width=12 /*Determines the width of the final image in inches*/, 
        plotname=_consort /*Determines the name of the image file*/, 
        plottype=static /*Determines the type of image file*/, 
        gpath= /*Determines where the image file is saved to*/, 
        tiffdevice=TIFFP /*Specifies the type of tiff device to use for making Tiff files*/, 
        dpi=150 /*Determines the DPI of the final image*/);
        
    /**Features to add:
        Change order of split variables
        Change order of off treatment reasons
        Change order of freq variables**/
       
    /**Save current options to reset after macro runs**/
    %local _mergenoby _notes _qlm _odspath _starttime _listing  _msglevel _mprint;
    %let _starttime=%sysfunc(time());
    %let _notes=%sysfunc(getoption(notes));
    %let _mergenoby=%sysfunc(getoption(mergenoby));
    %let _qlm=%sysfunc(getoption(quotelenmax)); 
    %let _mprint=%sysfunc(getoption(mprint));
    %let _msglevel=%sysfunc(getoption(msglevel));
    /**Turn off warnings for merging without a by and long quote lengths**/
    /**Turn off notes**/
    options mergenoby=NOWARN nonotes noquotelenmax msglevel=N;
    
    /*Don't send anything to output window, results window, and set escape character*/
    ods noresults escapechar='^';
    %let _odspath=&sysodspath;
    /**See if the listing output is turned on**/
    proc sql noprint;
        select 1 into :_listing separated by '' from sashelp.vdest where upcase(destination)='LISTING';
    quit;
    
    /**Process Error Handling**/
    %if %sysfunc(exist(&data))=0 %then %do;
        %put ERROR: Dataset &data does not exist;
        %put ERROR: Please enter a valid dataset;
        %goto errhandl;
    %end;
    %else %if %sysevalf(%superq(data)=,boolean)=1 %then %do;
        %put ERROR: DATA parameter is required;
        %put ERROR: Please enter a valid dataset;
        %goto errhandl;
    %end;                       
    %local z nerror;
    %let nerror=0;  
    
    /**Error Handling on Global Parameters**/
    %macro _varcheck(parm,require,numeric,maxvar=1000,dataset=&data,nummsg=,dlm=%str( ));
        %local _z _numcheck;
        /**Check if variable parameter is missing**/
        %if %sysevalf(%superq(&parm.)=,boolean)=0 %then %do;
            %if %sysfunc(countw(%superq(&parm),&dlm))>&maxvar %then %do;
                /**Give error message if too many variables are listed**/
                %put ERROR: (Global: %qupcase(&parm)) only &maxvar variable(s) are allowed for this parameter (listed: %superq(&parm.));
                %let nerror=%eval(&nerror+1);            
            %end;
            %else %if %sysfunc(notdigit(%superq(&parm.))) > 0 %then
                %do _z = 1 %to %sysfunc(countw(%superq(&parm.),&dlm));
                /**Check to make sure variable names are not just numbers**/    
                %local datid;
                /**Open up dataset to check for variables**/
                %let datid = %sysfunc(open(&dataset));
                /**Check if variable exists in dataset**/
                %if %sysfunc(varnum(&datid,%scan(%superq(&parm.),&_z,&dlm))) = 0 %then %do;
                    %put ERROR: (Global: %qupcase(&parm)) Variable %qupcase(%scan(%superq(&parm.),&_z,&dlm)) does not exist in dataset &dataset;
                    %local closedatid;
                    /**Close dataset**/
                    %let closedatid=%sysfunc(close(&datid));
                    %let nerror=%eval(&nerror+1);
                %end;
                %else %do;
                    %local closedatid;
                    %let closedatid=%sysfunc(close(&datid));
                    %if &numeric=1 %then %do;
                        data _null_;
                            set &dataset (obs=1);
                            call symput('_numcheck',strip(vtype(%qupcase(%scan(%superq(&parm.),&_z,&dlm)))));
                        run;
                        %if %sysevalf(%superq(_numcheck)^=N,boolean) %then %do;
                            %put ERROR: (Global: %qupcase(%scan(%superq(&parm.),&_z,&dlm))) variable must be numeric &nummsg;
                            %let nerror=%eval(&nerror+1);
                        %end;   
                    %end;                         
                %end;
            %end;
            %else %do;
                /**Give error message if variable name is number**/
                %put ERROR: (Global: %qupcase(&parm)) variable is not a valid SAS variable name (%superq(&parm.));
                %let nerror=%eval(&nerror+1);
            %end;
        %end;
        %else %if &require=1 %then %do;
            /**Give error if required variable is missing**/
            %put ERROR: (Global: %qupcase(&parm)) variable is a required variable but has no value;
            %let nerror=%eval(&nerror+1);
        %end;
    %mend;
    %macro _gparmcheck(parm, parmlist);          
        %local _test _z;
        /**Check if values are in approved list**/
        %do _z=1 %to %sysfunc(countw(&parmlist,|,m));
            %if %qupcase(%superq(&parm))=%qupcase(%scan(&parmlist,&_z,|,m)) %then %let _test=1;
        %end;
        %if &_test ^= 1 %then %do;
            /**If not then throw error**/
            %put ERROR: (Global: %qupcase(&parm)): %superq(&parm) is not a valid value;
            %put ERROR: (Global: %qupcase(&parm)): Possible values are &parmlist;
            %let nerror=%eval(&nerror+1);
        %end;
    %mend;
    /**Error Handling on Individual Model Numeric Variables**/
    %macro _gnumcheck(parm,min,contain,default);
        /**Check if missing**/
        %local z;
        %if %sysevalf(%superq(&parm.)=,boolean)=0 %then %do;
            %do z = 1 %to %sysfunc(countw(%superq(&parm),|,m));
                %if %sysevalf(%qscan(%superq(&parm.),&z,|,m)=,boolean) %then %do;
                    /**Check if value is not missing**/
                    %put ERROR: (Global: %qupcase(&parm) value &z) Cannot be missing and must be greater than &min.;
                    %let nerror=%eval(&nerror+1);                
                %end;
                %else %if %sysfunc(notdigit(%sysfunc(compress(%qscan(%superq(&parm.),&z,|,m),.)))) > 0 %then %do;
                    /**Check if character values are present**/
                    %put ERROR: (Global: %qupcase(&parm) value &z) Must be numeric.  %qupcase(%qscan(%superq(&parm.),&z,|,m)) is not valid.;
                    %let nerror=%eval(&nerror+1);
                %end;  
                %else %if %sysevalf(%superq(min)^=,boolean) %then %do;
                    %if %qscan(%superq(&parm.),&z,|,m) le &min and &contain=0 %then %do;
                        /**Check if value is below minimum threshold**/
                        %put ERROR: (Global: %qupcase(&parm) value &z) Must be greater than &min.  %qupcase(%qscan(%superq(&parm.),&z,|,m)) is not valid.;
                        %let nerror=%eval(&nerror+1);
                    %end;  
                    %else %if %qscan(%superq(&parm.),&z,|,m) lt &min and &contain=1 %then %do;
                        /**Check if value is below minimum threshold**/
                        %put ERROR: (Global: %qupcase(&parm) value &z) Must be greater than or equal to &min.  %qupcase(%qscan(%superq(&parm.),&z,|,m)) is not valid.;
                        %let nerror=%eval(&nerror+1);
                    %end; 
                %end;
            %end;
        %end;   
        %else %let &parm.=&default;      
    %mend;  
    /**Error Handling on Global Parameters Involving units**/
    %macro _gunitcheck(parm,allowmissing);
        %if %sysevalf(%superq(&parm)=,boolean)=1 %then %do;
                %if %sysevalf(&allowmissing^=1,boolean) %then %do;
                    /**Check if missing**/
                    %put ERROR: (Global: %qupcase(&parm)) Cannot be set to missing;
                    %let nerror=%eval(&nerror+1);
                %end;
        %end;
        %else %if %sysfunc(compress(%superq(&parm),ABCDEFGHIJKLMNOPQRSTUVWXYZ,i)) lt 0 %then %do;
            /**Throw error**/
            %put ERROR: (Global: %qupcase(&parm)) Cannot be less than zero (%qupcase(%superq(&parm)));
            %let nerror=%eval(&nerror+1);
        %end;
    %mend;
    /**Line Pattern Variables**/
    %macro _listcheck(var=,_patternlist=,lbl=,msg=,maxvalue=);
        %local _z _z2 _test;
        %if %sysevalf(%superq(lbl)=,boolean) %then %let lbl=%qupcase(&var.);
        /**Check for missing values**/
        %if %sysevalf(%superq(&var.)=,boolean)=0 %then %do _z2=1 %to %sysfunc(countw(%superq(&var.),|));
            %let _test=;
            /**Check if values are either in the approved list**/
            %do _z = 1 %to %sysfunc(countw(&_patternlist,|));
                %if %qupcase(%scan(%superq(&var.),&_z2,|))=%scan(%qupcase(%sysfunc(compress(&_patternlist))),&_z,|,m) %then %let _test=1;
            %end;
            %if &_test ^= 1 %then %do;
                /**Throw error**/
                %put ERROR: (Global: &lbl): %qupcase(%scan(%superq(&var.),&_z2,|)) is not in the list of valid values &msg;
                %put ERROR: (Global: &lbl): Possible values are %qupcase(&_patternlist);
                %let nerror=%eval(&nerror+1);
            %end;
        %end;
        %else %do;
            /**Throw error**/
            %put ERROR: (Global: &lbl): %qupcase(%superq(&var.)) is not in the list of valid values &msg;         
            %put ERROR: (Global: &lbl): Possible values are %qupcase(&_patternlist);
            %let nerror=%eval(&nerror+1);       
        %end;
    %mend;
    /*Check Parameters with limited choices*/
    %_gparmcheck(debug,0|1)
    %_gparmcheck(show_limits,0|1)
    %_gparmcheck(show_anchorpoints,0|1)
    %_gparmcheck(show_grid,0|1)
    %_gparmcheck(show_arrowheads,0|1)
    %_gparmcheck(arrowhead_shape,OPEN|FILLED|BARBED)
    %_gparmcheck(freq_show_labels,0|1)
    %_gparmcheck(weighted_row_height,0|1)
    %_gparmcheck(remerge,0|1)
    %_listcheck(var=show_split_headers,_patternlist=0|1)
    /*Check Parameters with numeric values*/
    %_gnumcheck(arrowhead_adjust,0,1)
    %_gnumcheck(font_size,0);
    %_gnumcheck(height,0);
    %_gnumcheck(width,0);
    %if &nerror=0 %then %do;
        %if %sysevalf(%qupcase(%superq(multiline_adjust))=AUTO,boolean) %then %let multiline_adjust=%sysevalf(1.13383+0.24003*&font_size-0.11964*&height);
        %_gnumcheck(multiline_adjust,0,1)
    %end;    
    %if &nerror>0 %then %goto errhandl;
    
    %if &debug=1 %then %do;
        options notes mprint;
    %end;
    
    /*Check that variables for ID and NODE exist*/
    %_varcheck(id,1,0,maxvar=1)
    %_varcheck(node,1,0)
    %if %sysevalf(%superq(offreason)^=,boolean) %then %do;
        %local _offrsn offreason i;
        %let _offrsn=&offreason;
        %do i=1 %to %sysfunc(countw(%superq(offreason),|,m));
            %let offreason=%scan(%superq(_offrsn),&i,|,m);
            %_varcheck(offreason,0,0,dlm=%str( ))
        %end;
        %let offreason=&_offrsn;
    %end;
    %_varcheck(split,0,0,dlm=|)
    %_varcheck(freq,0,0,dlm=|)
    %_varcheck(end_summary,0,0)

    /*Set up Reference Boxes*/
    %local i j k l nrefbox ref_options cur_opt;
    %if %sysevalf(%superq(ref_text)^=,boolean) %then %do;
        %let ref_options=ref_text|ref_y|ref_x|ref_rotate|ref_background_color|ref_box_expand|ref_border_color|ref_font_color|ref_font_size|ref_line_size|ref_line_color|ref_line_pattern;
        %let nrefbox=%sysfunc(countw(%superq(ref_text),|));
        %do i = 1 %to &nrefbox;
            %do j = 1 %to %sysfunc(countw(&ref_options,|));
                %let cur_opt=%scan(&ref_options,&j,|);
                %let k=%eval(&i-1);
                %local &cur_opt.&i;
                %if %sysevalf(%qscan(&&&cur_opt,&i,|,m)=,boolean) %then %let &cur_opt.&i=&&&&&cur_opt.&k;
                %else %let &cur_opt.&i=%scan(&&&cur_opt,&i,|,m);
            %end;
        %end;
    %end;
    %else %let nrefbox=0;
    
    %local ngrps unique_splits unique_splits_node;
    %let ngrps=%sysfunc(countw(&node,%str( )));
    %let unique_splits=;
    %let unique_splits_node=;
    %do i = 1 %to &ngrps;
        %local node&i node_t&i label&i split&i split_t&i split_f&i split_l&i
            offrsn&i offrsn&i offrsn_t&i offrsn_f&i offrsn_l&i 
            freq&i freq_f&i freq_l&i
            last_split last_offrsn last_offrsn_l any_off;
        
        %let node&i=%scan(&node,&i,%str( ));
        %let freq&i=%scan(&freq,&i,|,m);
        %let offrsn&i=%scan(&offreason,&i,|,m);
        %let offrsn_l&i=%qscan(%superq(offreason_label),&i,|,m);
        
        %if %sysevalf(%superq(offrsn&i)^=,boolean) %then %let any_off=1;
        %if &i>1 and %sysevalf(%superq(offrsn&i)=,boolean) %then %let offrsn&i=&last_offrsn;
        %if &i>1 and %sysevalf(%superq(offrsn_l&i)=,boolean) %then %let offrsn_l&i=&last_offrsn_l;
        %if %sysevalf(%superq(offrsn&i)^=,boolean) %then %do j =1 %to %sysfunc(countw(%superq(offrsn&i),%str( )));
            %local offrsn_l&i._&j;
            %let offrsn_l&i._&j=%scan(%superq(offrsn_l&i),&j,`,m);
        %end;

        %if %sysevalf(%superq(offrsn&i)^=,boolean) %then %do l=1 %to %sysfunc(countw(%superq(offrsn&i),%str( )));
            %local offrsn_l&i._&l;
        %end;
        %let last_offrsn=&&offrsn&i;
        %let last_offrsn_l=&&offrsn_l&i;
    %end;
    %if &remerge=0 %then %do i = 1 %to &ngrps;
        %let split&i=%scan(&split,&i,|,m);
        %if &i>1 and %sysevalf(%superq(split&i)=,boolean) %then %let split&i=&last_split;
        
        %if %sysevalf(%qscan(&split,&i,|,m)^=,boolean) %then %do;
            %if %sysevalf(%superq(unique_splits)=,boolean) %then %do;
                %let unique_splits=&&split&i;
                %let unique_splits_node=&&node&i;
            %end;
            %else %do j = 1 %to %sysevalf(1+%sysfunc(countw(%superq(unique_splits),|)));
                %if %sysevalf(%qscan(&unique_splits,&j,|)=%superq(split&i),boolean) %then %let j=%sysevalf(%sysfunc(countw(%superq(unique_splits),|))+1);
                %else %if %sysevalf(%qscan(&unique_splits,&j,|)=,boolean) %then %do;
                    %let unique_splits=%sysfunc(strip(&unique_splits))|&&split&i;
                    %let unique_splits_node=%sysfunc(strip(&unique_splits_node))|&&node&i;
                    %let j=%sysevalf(%sysfunc(countw(%superq(unique_splits),|))+1);
                %end;
            %end;
        %end;
        %let last_split=&&split&i;
    %end;
    /**Allow paths to remerge back together**/
    %else %if &remerge=1 %then %do i = 1 %to &ngrps;
        %let split&i=%scan(&split,&i,|,m);
        
        %if %sysevalf(%qscan(&split,&i,|,m)^=,boolean) %then %do;
            %if %sysevalf(%superq(unique_splits)=,boolean) %then %do;
                %let unique_splits=&&split&i;
                %let unique_splits_node=&&node&i;
            %end;
            %else %if %qscan(%superq(unique_splits),%sysfunc(countw(%superq(unique_splits),|,m)),|,m)=%str(*) %then %let unique_splits=%sysfunc(strip(&unique_splits))|&&split&i;
            %else %do j = 1 %to %sysevalf(1+%sysfunc(countw(%superq(unique_splits),|)));
                %if %sysevalf(%qscan(&unique_splits,&j,|)=%superq(split&i),boolean) %then %let j=%sysevalf(%sysfunc(countw(%superq(unique_splits),|))+1);
                %else %if %sysevalf(%qscan(&unique_splits,&j,|)=,boolean) %then %do;
                    %let unique_splits=%sysfunc(strip(&unique_splits))|&&split&i;
                    %let unique_splits_node=%sysfunc(strip(&unique_splits_node))|&&node&i;
                    %let j=%sysevalf(%sysfunc(countw(%superq(unique_splits),|))+1);
                %end;
            %end;
        %end;
        %else %if %sysevalf(%superq(unique_splits)^=,boolean) and
            %sysevalf(%qscan(%superq(unique_splits),%sysfunc(countw(%superq(unique_splits),|,m)),|,m)^=%str(*),boolean) %then %do;
            %let unique_splits=%sysfunc(strip(&unique_splits))|*;
        %end;
    %end;
    /*Things to check:
       1) Repeated nodes (no duplicates)
       2) Node values should be distinct for each path
       */
    %if &nerror>0 %then %goto errhandl;
          
    %local j k l new_split split_adjust nsplit split_indx;
    %let nsplit=%sysfunc(countw(%superq(unique_splits),|));
    %local last_sheader;
    %do i=1 %to %eval(&nsplit+1);
        %local show_sheader&i;
        %if %sysevalf(%qscan(&show_split_headers,&i,|,m)^=,boolean) %then %let show_sheader&i=%scan(&show_split_headers,&i,|,m);
        %else %let show_sheader&i=&last_sheader;
        %let last_sheader=&&show_sheader&i;
    %end;
    data _null_;
        set &data (obs=1);
        %do i = 1 %to &ngrps;
            %if %sysevalf(%superq(offrsn&i)^=,boolean) %then %do j=1 %to %sysfunc(countw(%superq(offrsn&i),%str( )));
                %if %sysevalf(%superq(offrsn_l&i._&j)=,boolean) %then %do;
                    call symputx("offrsn_l&i._&j",strip(vlabel(%scan(&&offrsn&i,&j,%str( )))));
                %end;
                call symputx("offrsn_f&i._&j",strip(vformat(%scan(&&offrsn&i,&j,%str( )))));
            %end;
            %if %sysevalf(%superq(freq&i)^=,boolean) %then %do;
                call symputx("freq_l&i",strip(vlabel(&&freq&i)));
                call symputx("freq_f&i",strip(vformat(&&freq&i)));
            %end;
        %end;
        %do i=1 %to &nsplit;
            %if %qscan(&unique_splits,&i,|)^=%str(*) %then %do;
                call symputx("split_t&i",strip(vtype(%scan(&unique_splits,&i,|))));
                call symputx("split_f&i",strip(vformat(%scan(&unique_splits,&i,|))));
            %end;
        %end;
        %do i = 1 %to %sysfunc(countw(%superq(end_summary),%str( )));
            %local end_summary&i esum_l&i;
            %let end_summary&i=%scan(%superq(end_summary),&i,%str( ));
            call symputx("esum_l&i",strip(vlabel(&&end_summary&i)));
        %end;
    run;
    proc sql noprint;
    
        /**Check for duplicate IDS**/
        %local idcheck;
        select distinct &id into :idcheck separated by ', ' from &data group by &id having count(*)>1;
        %if %sysevalf(%superq(idcheck)^=,boolean) %then %do;
            %put ERROR: Duplicate ID values found;
            %put ERROR: ID values are: &idcheck;
            %put ERROR: Macro CONSORT will cease;
            %goto errhandl;
        %end;

        %local current_split j rmrg remerge_phase s;
        create table _temp1 as
            %do s = 1 %to %sysfunc(max(1,%sysfunc(countw(%superq(end_summary),%str( )))));
                %let current_split=0;
                %let rmrg=0;
                %let remerge_phase=1;
                %let j=1;
                %let split_adjust=0;
                %let split_indx=0;
                %if &s>1 %then %do; OUTER UNION CORR %end;
                %do i = 1 %to &ngrps;
                    %if &i>1 %then %do; OUTER UNION CORR %end;
                    /*Off Treatment Sections*/
                    %if &i>1 %then %do;
                        %let j=%sysevalf(&i-1);
                        %if %sysevalf(%superq(offrsn&j)^=,boolean) %then %do l=1 %to %sysfunc(countw(%superq(offrsn&j),%str( )));
                            select &i +&split_adjust as node, &s as summary_var, 
                                "%superq(offrsn_l&j._&l)" as label%sysevalf(&i +&split_adjust), &id as id,
                                &current_split+1 as phase,&l as off_trt,%sysfunc(countw(%superq(offrsn&j),%str( ))) as  n_off,0 as summary,
                                %scan(&&offrsn&j,&l,%str( )) as offrsn%sysevalf(&i +&split_adjust) format=&&offrsn_f&j._&l
                                %if &current_split>0 %then %do k=1 %to &current_split;
                                    %if &k <= &rmrg %then %do; ,'' as split&k %end;
                                    %else %do; ,%scan(&unique_splits,&k,|) as split&k format=&&split_f&k %end;  
                                %end;
                                %else %if &nsplit=0 %then %do;
                                    ,'' as split1
                                %end;
                                , &remerge_phase as remerge_phase
                                from &data where missing(&&node&i) and ^missing(&&node&j) 
                                    %if %sysfunc(countw(%superq(offrsn&j),%str( )))>1 %then %do m=1 %to %sysfunc(countw(%superq(offrsn&j),%str( )));
                                        %if &l^=&m %then %do;
                                            and missing(%scan(&&offrsn&j,&m,%str( )))
                                        %end;
                                    %end;
                            OUTER UNION CORR
                            %let split_adjust=%sysevalf(&split_adjust+1);
                        %end;
                    %end;
                    
                    /*Split Header Section: Happens before paths split*/   
                    %if %superq(show_sheader%eval(&current_split+1))=1 and (&i=1 or %sysevalf(%superq(split&i)^=%superq(split&j),boolean)) and %sysevalf(%superq(split&i)^=,boolean) %then %do;
                        select &i +&split_adjust as node,  &s as summary_var,
                            &&node&i as label%sysevalf(&i +&split_adjust), &id as id,&current_split+1 as phase,0 as off_trt,0 as summary,'' as freq%sysevalf(&i +&split_adjust)
                            %if &current_split>0 %then %do k=1 %to &current_split;
                                    %if &k <= &rmrg %then %do; ,'' as split&k %end;
                                    %else %do; ,%scan(&unique_splits,&k,|) as split&k format=&&split_f&k %end;  
                            %end;
                            , &remerge_phase as remerge_phase,'' as offrsn%sysevalf(&i +&split_adjust),. as n_off  
                            from &data where ^missing(&&node&i) 
                        OUTER UNION CORR
                        %let split_adjust=%sysevalf(&split_adjust+1);
                    %end;    
                    
                    /*Check for new split*/
                    %if ((&i=1 or %sysevalf(%superq(split&i)^=%superq(split&j),boolean)) and %sysevalf(%superq(split&i)^=,boolean)) or
                        ((&i>1 and %sysevalf(%superq(split&i)^=%superq(split&j),boolean)) and %sysevalf(%superq(split&i)=,boolean)) %then %do;
                            %let current_split=%sysevalf(&current_split+1);
                            %if ((&i>1 and %sysevalf(%superq(split&i)^=%superq(split&j),boolean)) and %sysevalf(%superq(split&i)=,boolean)) %then %do;
                                %let rmrg=&current_split;
                                %let remerge_phase=%eval(&remerge_phase+1);
                            %end;
                    %end;
                    /*Text Boxes*/     
                    select &i+&split_adjust as node,  &s as summary_var, &current_split+1 as phase,
                        %if (&i=1 or %sysevalf(%superq(split&i)^=%superq(split&j),boolean)) and %sysevalf(%superq(split&i)^=,boolean) %then %do;  
                            %scan(&unique_splits,&current_split,|) 
                        %end;
                        %else %do; &&node&i %end; as label%sysevalf(&i +&split_adjust), &id as id, 0 as off_trt,0 as summary,
                        
                        %if %sysevalf(%superq(freq&i)^=,boolean) %then %do; "%superq(freq_l&i)" as freq_label, &&freq&i as freq%sysevalf(&i +&split_adjust), %end;
                        %else %do; '' as freq_label,'' as freq%sysevalf(&i +&split_adjust), %end;
                                                
                        %if &current_split>0 %then %do k=1 %to &current_split;
                            %if &k <= &rmrg %then %do; '' as split&k, %end;
                            %else %do; %scan(&unique_splits,&k,|) as split&k, %end; 
                        %end;     
                        %else %if &nsplit=0 %then %do;
                            '' as split1,
                        %end;   
                         &remerge_phase as remerge_phase,'' as offrsn%sysevalf(&i +&split_adjust),. as n_off             
                        from &data where ^missing(&&node&i) 
                %end;

                %if %sysevalf(%superq(end_summary)^=,boolean) %then %do; 
                    OUTER UNION CORR
                    select &i+&split_adjust as node,&s as summary_var, &current_split+2 as phase,
                        "%superq(esum_l&s)" as label%sysevalf(&i +&split_adjust), &id as id, 0 as off_trt, 1 as summary,
                        
                        %if &current_split>0 %then %do;
                            %do k=1 %to &current_split;
                                %if &k <= &rmrg %then %do; '' as split&k, %end;
                                %else %do; %scan(&unique_splits,&k,|) as split&k, %end;
                            %end;
                            "Summary &s" as split&k,
                        %end;     
                        %else %if &nsplit=0 %then %do;
                            '' as split1,'Summary' as split2,
                        %end;      
                        &&end_summary&s as summary&s, &remerge_phase as remerge_phase,'' as offrsn%sysevalf(&i +&split_adjust),. as n_off           
                        from &data where ^missing(&&node&ngrps) 
                %end;
            %end;
            order by summary_var,node;     
            %if %sysevalf(%superq(end_summary)^=,boolean) %then %do;  
                %let nsplit=%sysevalf(&nsplit+1);
                %let ngrps=%sysevalf(&ngrps+&split_adjust+1);
            %end; 
            %else %let ngrps=%sysevalf(&ngrps+&split_adjust);
    quit;
    data _temp1;
        set _temp1;
        by summary_var node;
        if first.summary_var then _count=0;
        if first.node then _count+1;
        node=_count;
        drop _count;
    run;
    %if &nsplit>0 %then %do i = 1 %to &nsplit;
        %local split&i._lvl;
        proc sort data=_temp1 out=_split&i._order nodupkey;
            by split&i;
            where ^missing(split&i);
        proc sql noprint;
            select split&i into :split&i._lvl separated by '|'
                from _split&i._order;
            drop table _split&i._order;
        quit;
    %end;
    proc sort data=_temp1;
        by summary_var id node;
    data _temp1;
        set _temp1;
        by summary_var id node;
        if off_trt>=1 and ^last.id then delete;
        %if &nsplit>0 %then %do i = 1 %to &nsplit;
            %if %sysevalf(%superq(split&i._lvl)^=,boolean) %then %do;
                if strip(vvalue(split&i))="%qscan(%superq(split&i._lvl),1,|)" then order&i=1;
                %do j = 2 %to %sysfunc(countw(%superq(split&i._lvl),|));
                    else if strip(vvalue(split&i))="%qscan(%superq(split&i._lvl),&j,|)" then order&i=&j;
                %end;
            %end;
            %else %do;
                order&i=.;
            %end;
        %end;
        %else %do;
            order1=1;
        %end;
    run;
    proc sort data=_temp1;
        by  order: node summary_var;
    run;
    data _temp2;
        set _temp1;
        by order: node summary_var;
        if first.order&nsplit then order+1;
        node=node+order/100;
        label=strip(coalescec(%do i = 1 %to &ngrps; %if &i>1 %then %do; , %end; vvalue(label&i) %end;));
        %if %sysevalf(%superq(end_summary)^=,boolean) %then %do;
            length sum_label $300.;
            sum_label=strip(coalescec(%do i = 1 %to %sysfunc(countw(%superq(end_summary),%str( ))); %if &i>1 %then %do; , %end; vvalue(summary&i) %end;));
        %end;
        drop label1-label&ngrps %do i = 1 %to %sysfunc(countw(%superq(end_summary),%str( ))); summary&i %end;;
    run;
    proc sort data=_temp2;
        by summary_var node offrsn:;
    run;
    data _temp3;
        set _temp2;
        by summary_var node offrsn:;
        if first.node then off_order=0;
        if first.offrsn&ngrps then off_order+1;
        offrsn=strip(coalescec(%do i = 1 %to &ngrps; %if &i>1 %then %do; , %end; vvalue(offrsn&i) %end;));
        drop offrsn1-offrsn&ngrps;
    run;
    proc sort data=_temp3;
        by summary_var node freq:;
    run;
    data _temp4;
        set _temp3;
        by summary_var node freq:;
        if first.node then freq_order=0;
        if first.freq&ngrps then freq_order+1;
        freq=strip(coalescec(%do i = 1 %to &ngrps; %if &i>1 %then %do; , %end; vvalue(freq&i) %end;));
        drop freq1-freq&ngrps;
    run;
    
    /*Check if any nodes have multiple unique labels*/
    proc sql noprint;
        %local ml_nodes;
        select distinct node into :ml_nodes separated by '|' from _temp4 group by node having count(distinct label)>1;
        %if %sysevalf(%superq(ml_nodes)^=,boolean) %then %do;
            %put ERROR: Consort nodes found with multiple unique text values;
            %do i = 1 %to %sysfunc(countw(&ml_nodes,|));
                %local ml_node_text&i;
                select distinct label into :ml_node_text&i separated by '|' from _temp4 where node=%scan(&ml_nodes,&i,|);
                %put ERROR: Consort node in row %sysfunc(int(%scan(&ml_nodes,&i,|))) has values of %superq(ml_node_text&i);
            %end;
            %put ERROR: Adjust SPLIT variables to allow one distinct value per consort node;
            %put ERROR: Macro CONSORT will cease;
            %goto errhandl;
        %end;

        create table _offpts as
            select * from _temp3
            where summary_var=1
            group by id having max(off_trt)>=1
            order by id,node;
    quit;
    data _unique_paths_off (keep=node connect_backward step:);
        set _offpts end=last;
        by id node ;
        array step {&ngrps};
        array phases {&ngrps};
        array paths {50,&ngrps};
        array _phases {50,&ngrps};
        if first.id then call missing(count,of step(*),of phases(*));
        count+1;
        step(count)=node;
        phases(count)=phase;
        if last.id then do;
            j=1;checkout=0;
            do until (j>50 or checkout=1);
                skip=0;i=1;
                do until (i > count or skip=1);
                    if paths(j,i)=. and ^missing(step(i)) then do;
                        paths(j,i)=step(i);
                        _phases(j,i)=phases(i);
                    end;
                    else if paths(j,i)^=step(i) then skip=1;
                    else if paths(j,i)=step(i) then i=i+1;
                end;
                if skip=0 then checkout=1;
                else j=j+1;
            end;     
            path=j;
        end;
        if last then do;
            do j = 1 to 50;
                do i = 1 to dim(step);
                    step(i)=paths(j,i);
                    phases(i)=_phases(j,i);
                end;
                if nmiss(of step(*))<dim(step) then do;
                    node=step(dim(step)-nmiss(of step(*)));
                    connect_backward=step(dim(step)-nmiss(of step(*))-1);
                    output _unique_paths_off;
                end;
                else j=51;
            end;
        end;
        retain step paths phases _phases;
    run;
    proc sort data=_temp4;
        by summary_var id node;
    run;
    data _unique_paths (keep=summary_var step: rphases: phases: summ1-summ&ngrps last_step);
        set _temp4 end=last;
        by summary_var id node ;
        where off_trt<1;
        array step {&ngrps};
        array phases {&ngrps};
        array rphases {&ngrps};
        array summ {&ngrps};
        array paths {50,&ngrps};
        array _phases {50,&ngrps};
        array _rphases {50,&ngrps};
        array _summary {50,&ngrps};
        if first.id then call missing(count,of step(*),of phases(*),of rphases(*), of summ(*));
        count+1;
        step(count)=node;
        phases(count)=phase;
        rphases(count)=remerge_phase;
        summ(count)=summary;
        if last.id then do;
            j=1;checkout=0;
            do until (j>50 or checkout=1);
                skip=0;i=1;
                do until (i > count or skip=1);
                    if paths(j,i)=. and ^missing(step(i)) then do;
                        paths(j,i)=step(i);
                        _phases(j,i)=phases(i);
                        _rphases(j,i)=rphases(i);
                        _summary(j,i)=summ(i);
                    end;
                    else if paths(j,i)^=step(i) then skip=1;
                    else if paths(j,i)=step(i) then i=i+1;
                end;
                if skip=0 then checkout=1;
                else j=j+1;
            end;     
            path=j;
        end;
        if last.summary_var then do;
            do j = 1 to 50;
                do i = 1 to dim(step);
                    step(i)=paths(j,i);
                    phases(i)=_phases(j,i);
                    rphases(i)=_rphases(j,i);
                    summ(i)=_summary(j,i);
                end;
                if nmiss(of step(*))<dim(step) then do;
                    path=j;
                    last_step=max(of step(*));
                    output _unique_paths;
                end;
                else j=51;
            end;
            
        end;
        retain step paths phases _phases rphases _rphases summ _summary;
    run;
    proc sort data=_unique_paths nodupkey;
        by step:;
    data _unique_paths;
        set _unique_paths;
        path+1;
    run;
    proc sort data=_temp4;
        by remerge_phase summary_var id node;
    run;
    data _unique_paths_r (keep=summary_var step: remerge_phase phases: summ1-summ&ngrps last_step);
        set _temp4 end=last;
        by remerge_phase summary_var id node ;
        where off_trt<1;
        array step {&ngrps};
        array phases {&ngrps};
        array summ {&ngrps};
        array paths {50,&ngrps};
        array _phases {50,&ngrps};
        array _summary {50,&ngrps};
        if first.remerge_phase then call missing(of _phases(*),of paths(*));
        if first.id then call missing(count,of step(*),of phases(*), of summ(*));
        count+1;
        step(count)=node;
        phases(count)=phase;
        summ(count)=summary;
        if last.id then do;
            j=1;checkout=0;
            do until (j>50 or checkout=1);
                skip=0;i=1;
                do until (i > count or skip=1);
                    if paths(j,i)=. and ^missing(step(i)) then do;
                        paths(j,i)=step(i);
                        _phases(j,i)=phases(i);
                        _summary(j,i)=summ(i);
                    end;
                    else if paths(j,i)^=step(i) then skip=1;
                    else if paths(j,i)=step(i) then i=i+1;
                end;
                if skip=0 then checkout=1;
                else j=j+1;
            end;     
            path=j;
        end;
        if last.remerge_phase then do;
            do j = 1 to 50;
                do i = 1 to dim(step);
                    step(i)=paths(j,i);
                    phases(i)=_phases(j,i);
                    summ(i)=_summary(j,i);
                end;
                if nmiss(of step(*))<dim(step) then do;
                    path=j;
                    last_step=max(of step(*));
                    output _unique_paths_r;
                end;
                else j=51;
            end;
            
        end;
        retain step paths phases _phases summ _summary;
    run;
    proc sort data=_unique_paths_r nodupkey;
        by remerge_phase step:;
    data _unique_paths_r;
        set _unique_paths_r;
        by remerge_phase;
        if first.remerge_phase then path=0;
        path+1;
    run;
    data _unique_paths_r;
        set _unique_paths_r end=last;
        array step {%sysevalf(&ngrps+1)};
        array phases {%sysevalf(&ngrps+1)};
        array summ {%sysevalf(&ngrps+1)};
        retain nsteps;
        nsteps=max(nsteps,dim(step)-nmiss(of step(*)));
        do i = 1 to dim(step);
            if ^missing(step(i)) then do;
                phase=phases(i);
                node=step(i);
                summary=summ(i);
                row=int(step(i));
                output;
            end;
        end;
        keep phase remerge_phase summary path node row ;
    run;
    /** Check if there are enough splits to cover all paths **/
    proc sql noprint;        
        %local max_paths obs_paths n_rmrg rmrg_flag;
        %if &nsplit>0 %then %do;
            select max(phase) into :n_rmrg separated by '' from _temp4;
            %do i=1 %to &n_rmrg;
                %local max_paths&i obs_paths&i ;
                select count(distinct order) into :max_paths&i separated by ''
                    from _temp4 where phase=&i;
                select count(distinct catx('-', %do j = 1 %to &ngrps;
                                                    %if &j>1 %then %do; , %end;
                                                    step&j
                                                %end;)) into :obs_paths&i separated by '' from 
                    (select distinct %do j = 1 %to &ngrps;
                                %if &j>1 %then %do; , %end;
                                ifn(phases&j=&i,step&j,.) as step&j
                            %end; from _unique_paths
                            having nmiss(%do j = 1 %to &ngrps;
                                            %if &j>1 %then %do; , %end;
                                            step&j
                                         %end;)>0);
                %if %sysevalf(&&max_paths&i < &&obs_paths&i,boolean) %then %do;
                    %put ERROR: (phase &i): Not enough split levels created (&&max_paths&i) to contain all unique patient paths (&&obs_paths&i);
                    %put ERROR: Macro CONSORT will cease;
                    %goto errhandl;
                %end;
            %end;
        %end;
        %else %do;
            %let max_paths=1;
            select count(distinct path) into :obs_paths separated by '' from _unique_paths;
            %if %sysevalf(&max_paths < &obs_paths,boolean) %then %do;
                %put ERROR: Not enough split levels created (&max_paths) to contain all unique patient paths (&obs_paths);
                %put ERROR: Macro CONSORT will cease;
                %goto errhandl;
            %end;
        %end;
        create table _temp5 as
            select remerge_phase,phase,node,label,'BOTTOM' as position,count(distinct id) as n,
                case(missing(label))
                    when 0 then tranwrd(strip(label)||' (N='||strip(put(calculated n,12.0))||')','~ ','~')
                else '' end as text length=1000
                from _temp4 where off_trt<1 and summary_var=1 and summary=0 group by remerge_phase,phase,node,label,position
                outer union corr
                select remerge_phase,phase,node,off_trt,n_off,label,
                    %if %qupcase(&textbox_offtrt_align)=OUTSIDE or %qupcase(&textbox_offtrt_align)=RIGHT %then %do; 'RIGHT' %end;
                    %else %do; 'LEFT' %end; as position,count(distinct id) as n,
                    tranwrd(strip(label)||' (N='||strip(put(calculated n,12.0))||')','~ ','~') as text
                    from _temp4 where off_trt>=1 and summary_var=1 and summary=0 and ^missing(offrsn) and node ^in(select node from _unique_paths_off
                                                                                    where connect_backward in(select last_step from _unique_paths))
                    group by remerge_phase,phase,node,off_trt,n_off,label,position
                outer union corr
                select remerge_phase,phase,node,off_trt,n_off,
                off_order,offrsn,
                    %if %qupcase(&textbox_offtrt_align)=OUTSIDE or %qupcase(&textbox_offtrt_align)=RIGHT %then %do; 'RIGHT' %end;
                    %else %do; 'LEFT' %end; as position,count(distinct id) as n,
                    &indent_text||strip(offrsn)||' (N='||strip(put(calculated n,12.0))||')' as text 
                    from _temp4 where off_trt>=1 and summary_var=1 and summary=0 and ^missing(offrsn) and node ^in(select node from _unique_paths_off
                                                                                    where connect_backward in(select last_step from _unique_paths))
                    group by remerge_phase,phase,node,off_trt,n_off,off_order,offrsn,position
                outer union corr
                select remerge_phase,phase,node,
                1000 as off_order,offrsn,
                    %if %qupcase(&textbox_offtrt_align)=OUTSIDE or %qupcase(&textbox_offtrt_align)=RIGHT %then %do; 'RIGHT' %end;
                    %else %do; 'LEFT' %end; as position, count(distinct id) as n,
                    "&no_offreason_text (N="||strip(put(calculated n,12.0))||')' as text 
                    from _temp4 where off_trt>=1 and summary_var=1 and summary=0 and missing(offrsn)  and node ^in(select node from _unique_paths_off
                                                                                    where connect_backward in(select last_step from _unique_paths))
                    group by remerge_phase,phase,node,off_order,offrsn,position
                    
            %if &freq_show_labels=1 %then %do;
                outer union corr
                select remerge_phase,phase,node,
                0.1 as freq_order,freq_label,'BOTTOM' as position,count(distinct id) as n,
                    'A0A0'x||strip(freq_label) as text 
                    from _temp4 where ^missing(freq_label) and summary_var=1 and summary=0 group by remerge_phase,phase,node,calculated freq_order,freq_label,position
            %end;
            outer union corr
            select remerge_phase,phase,node,
            freq_order,freq, 'BOTTOM' as position,count(distinct id) as n,
                &indent_text||strip(freq)||' (N='||strip(put(calculated n,12.0))||')' as text 
                from _temp4 where ^missing(freq) and summary_var=1 and summary=0 group by remerge_phase,phase,node,freq_order,freq,position
                
            %if %sysevalf(%superq(end_summary)^=,boolean) %then %do; 
                outer union corr
                select remerge_phase,phase,node,summary,label,'BOTTOM' as position,count(distinct id) as n,
                    case(missing(label))
                        when 0 then tranwrd(strip(label)||' (N='||strip(put(calculated n,12.0))||')','~ ','~')
                    else '' end as text length=1000
                    from _temp4 where ^missing(sum_label) and summary=1 group by remerge_phase,phase,node,summary,label,position
                outer union corr
                select remerge_phase,phase,node,summary,
                sum_label, 'BOTTOM' as position,count(distinct id) as n,
                    &indent_text||strip(sum_label)||' (N='||strip(put(calculated n,12.0))||')' as text 
                    from _temp4 where ^missing(sum_label) and summary=1 group by remerge_phase,phase,node,summary,sum_label,position
            %end;
            order by remerge_phase,phase,node,off_order,freq_order;
        %local npaths;
        select count(distinct path) into :npaths separated by '' from _unique_paths;
        %local nphase;
        select count(distinct phase) into :nphase separated by '' from _temp5;
    quit;
    
    %if %qupcase(&textbox_offtrt_align)=OUTSIDE and &nsplit>0 %then %do;
        proc sql;
            create table _split_parent as
            select *,count(distinct node) as nsplit 
                from (select distinct node from _temp4 where phase=2 having min(int(node))=int(node));
        quit;

        data _split_parent2;
            set _split_parent;
            by node;
            
            if (mod(nsplit,2)=0 and _n_/nsplit<=0.5) or (mod(nsplit,2)=1 and _n_/nsplit<0.5) then output;
        run;
        
        proc sql noprint;
            %local parent_list;
            select distinct node into :parent_list separated by ', ' from _split_parent2;
        quit;
        
        data _switch;
            set _unique_paths_off;
            
            array step {*} step:;
            
            do i = 1 to dim(step)-nmiss(of step(*));
                if step(i) in(&parent_list) then do;
                    output;
                    i=dim(step)+1;
                end;
            end;
            keep node;
        run;
        
        proc sql;
            update _temp5
                set position='LEFT'
                    where node in(select node from _switch);
        quit;
    %end;
    %local nsteps;
    data _temp6;
        set _unique_paths end=last;
        array step {%sysevalf(&ngrps+1)};
        array phases {%sysevalf(&ngrps+1)};
        array rphases {%sysevalf(&ngrps+1)};
        array summ {%sysevalf(&ngrps+1)};
        retain nsteps;
        nsteps=max(nsteps,dim(step)-nmiss(of step(*)));
        do i = 1 to dim(step);
            if ^missing(step(i)) then do;
                phase=phases(i);
                remerge_phase=rphases(i);
                node=step(i);
                summary=summ(i);
                row=int(step(i));
                if i=1 then do;
                    row_link=int(step(i));
                    connect_forward=step(i+1);
                    connect_backward=step(i);
                    output;
                end;
                else do;
                    row_link=int(step(i-1));
                    connect_forward=step(i+1);
                    connect_backward=step(i-1);
                    output;
                end;
            end;
        end;
        if last then call symputx('nsteps',nsteps);
        keep phase remerge_phase summary path node row row_link connect_forward connect_backward;
    run;
    proc sql noprint;
        select distinct row into :dsteps separated by '|' from _temp6;
        create table _temp7 as
         select distinct a.remerge_phase,a.phase,a.summary,a.node,a.connect_backward,a.connect_forward,a.min_path,a.max_path,b.npaths,a.total_npath,a.x_min,a.x_max,a.x,a.y
            from (select *, count(distinct path) as npath,min(path) as min_path,max(path) as max_path,
                    100*(calculated min_path-1)/max(total_npath) as x_min,
                    calculated x_min+100*count(distinct path)/max(total_npath) as x_max,
                    (calculated x_max+calculated x_min)/2 as x,int(node) as y
            from  
                (select a.*,b.path,b.total_npath/*,b.branch_npath*/
                from _temp6 (drop=path) a left join (select *,count(distinct path) as total_npath from _unique_paths_r group by remerge_phase) b
                   on a.remerge_phase=b.remerge_phase and a.phase=b.phase and a.node=b.node)
            group by node) a left join 
                (select phase,count(distinct node) as npaths from (select phase,node,path from _temp6 group by path,phase having node=min(node)) group by phase) b
                on a.phase=b.phase;
        %if %sysevalf(%superq(end_summary)^=,boolean) %then %do;
            %local max_rmrg sum_npth sum_nnode;
            select max(remerge_phase) into :max_rmrg separated by '' from _temp7;
            select max(npaths) into :sum_npth separated by '' from _temp7 where remerge_phase=&max_rmrg and summary=0;
            %if &max_rmrg>1 and &sum_npth=1 %then %do;
                select count(distinct node) into :sum_nnode separated by '' from _temp7 where summary=1;
                update _temp7
                    set x=100*(min_path/(&sum_nnode+1))
                    where summary=1;
            %end;
        %end;
        %do i=&nsteps %to 1 %by -1;
            create table _step&i as
                %if &i=&nsteps %then %do;
                    select * from _temp7 (drop=connect_forward x_min x_max) where y=%scan(&dsteps,&i,|);
                %end;
                %else %do;
                    select a.remerge_phase,a.phase, a.node, a.connect_backward, a.y,
                        coalesce(min(b.x),max(a.x_min)) as x_min,
                        coalesce(max(b.x),max(a.x_max)) as x_max,
                        coalesce((min(b.x)+max(b.x))/2,max(a.x)) as x 
                        from (select * from _temp7 where y=%scan(&dsteps,&i,|)) a left join _step%eval(&i+1) b on a.connect_forward=b.node and a.remerge_phase=b.remerge_phase
                        group by a.remerge_phase,a.phase, a.node,a.connect_backward,a.y;
                %end;
        %end;
        create table _temp8 as
            select a.*,coalesce(b.connect_backward,c.connect_backward) as connect_backward,f.connect_forward,d.npaths,
                case
                    when ^missing(b.x) then b.x
                    when a.position='LEFT' then c.x-15/d.npaths - case (a.phase)
                            %do i = 1 %to &nphase; 
                               when &i then %if %sysevalf(%qscan(&offreason_xadjust,&i,|,m)^=,boolean) %then %do; %scan(&offreason_xadjust,&i,|,m) %end;
                                            %else %do; 0 %end;                                           
                           %end;
                           else 0 end
                    when a.position='RIGHT' then c.x+15/d.npaths + case (a.phase)
                            %do i = 1 %to &nphase; 
                               when &i then %if %sysevalf(%qscan(&offreason_xadjust,&i,|,m)^=,boolean) %then %do; %scan(&offreason_xadjust,&i,|,m) %end;
                                            %else %do; 0 %end;                                           
                           %end;
                           else 0 end
                else . end as x,int(a.node) as y
            from _temp5 a left join 
                (%do i=1 %to &nsteps;
                    %if &i>1 %then %do; outer union corr %end;
                    select * from _step&i
                %end;) b on a.node=b.node
                left join (select a.node,a.connect_backward,b.x,b.x_min,b.x_max,b.npaths
                            from (select distinct node,connect_backward from _unique_paths_off) a left join 
                            (%do i=1 %to &nsteps;
                                %if &i>1 %then %do; outer union corr %end;
                                select * from _step&i
                            %end;) b on a.connect_backward=b.node) c 
                        on a.node=c.node
                left join 
                (select phase,count(distinct node) as npaths from (select phase,node,path from _temp6 group by path,phase having node=min(node)) group by phase) d
                on a.phase=d.phase 
                left join _unique_paths_off e on a.node=e.node
                left join _temp6 f on e.connect_backward=f.node or a.node=f.node
            order by remerge_phase,phase,node,text,connect_backward;
        %if &debug ^=1 %then %do;    
            drop table 
                %do i=1 %to &nsteps;
                    %if &i>1 %then %do; , %end;
                    _step&i
                %end;;
        %end;
    quit;
    

    proc sql noprint;
        %local max_backwards;
        select max(nback) into :max_backwards separated by ''
            from (select remerge_phase,phase,node,text,count(distinct connect_backward) as nback from _temp8 group by remerge_phase,phase,node,text);
    quit;
    data _temp8;
        set _temp8;
        by remerge_phase phase node text;
        array _connect_backward {&max_backwards} connect_backward1-connect_backward&max_backwards;
        retain _connect_backward;
        if first.text then do;
            call missing(of _connect_backward(*));_count_=1;
        end;
        else _count_+1;
        if connect_backward ^in _connect_backward then _connect_backward(_count_)=connect_backward;
        else _count_=_count_-1;
        if last.text;
        drop _count_;
    run;
    
    proc sort data=_temp8;
        by y x off_order freq_order;
    run;

    data _temp9;
        set _temp8;
        by y x;
        where ^missing(x) and ^missing(y);
        
        length _temp_text $10000.;
        if first.x then call missing(_temp_text);
        if ^(first.x and last.x) then do;
            _temp_text=catx('~',_temp_text,text);
            if last.x then do;
                text=_temp_text;
                output;
            end;
        end;
        else output;
        retain _temp_text;
        drop _temp_text;
    run;
    %local max_col max_row;
    proc sort data=_temp9;
        by x;
    data _temp9;
        set _temp9 end=last;
        by x;
        if first.x then column+1;
        retain maxrow;
        if y>maxrow then maxrow=y;
        if last then do;
            call symputx('max_col',column);
            call symputx('max_row',maxrow);
        end;        
    run;

    proc sql noprint;
        create table _temp10 as
            select a.*,(select sum(nlines_row)+2*&nphase as nlines_total from 
                        (select row,max(countw(text,'~','m')) as nlines_row from _temp9 (rename=(y=row)) group by row)) as nlines_total
                from (select *,max(nlines) as nlines_row
                    from (select a.*,countw(a.text,'~','m') as nlines,
                            %do i=1 %to &max_backwards;
                                b&i..column as column_link&i,b&i..x as x_link&i,b&i..y as row_link&i,b&i..position as position_link&i,countw(b&i..text,'~','m') as nlines_link&i,
                            %end;
                            f.column as column_flink,f.y as row_flink
                            from _temp9 (rename=(y=row)) a 
                                %do i=1 %to &max_backwards;
                                    left join _temp9 b&i on a.connect_backward&i=b&i..node
                                %end;
                                left join _temp9 f on a.connect_forward=f.node)
                    group by row) a       
            order by a.remerge_phase,a.phase,a.row;*,x_link,a.x;            
    quit;
    data _limits (keep=row_y: col_x: _nlines_: _positions_:);
        set _temp10 end=last;
        by remerge_phase phase row;
        array _nlines_ {&max_row /*rows*/,&max_col /*columns*/};
        array _nlines_row {&max_row /*rows*/} _temporary_;
        array _positions_ {&max_row /*rows*/,&max_col /*columns*/} $20.;
        array row_y {&max_row};
        array col_x {&max_col};
        retain _nlines_ _positions_ row_y col_x total_lines;
        if _n_=1 then total_lines=0;
        _nlines_(row,column)=countw(text,'~','m');
        _nlines_row(row)=nlines_row;
        _positions_(row,column)=upcase(position);
        
        %if &weighted_row_height=0 %then %do;
            row_y(row)=100*(row/&ngrps+(row-1)/&ngrps)/2;
        %end;
        %else %do;
            row_y(row)=100*(nlines_row/(2*nlines_total)+total_lines/nlines_total);
        %end;

        col_x(column)=x;
        if last then output _limits;
        if last.row then total_lines+nlines_row+2*(last.phase);
    run;
    data _consort;
        if _n_=1 then set _limits;
        set _temp10 (drop=label connect_backward);
        array _nlines_ {&max_row /*rows*/,&max_col /*columns*/};
        array _positions_ {&max_row /*rows*/,&max_col /*columns*/} $20.;
        array row_y {&max_row};
        array col_x {&max_col};
        array _x_ {&max_row /*rows*/,&max_col /*columns*/} _temporary_;
        array _y_ {&max_row /*rows*/,&max_col /*columns*/} _temporary_;
        array row_link {&max_backwards};
        array column_link {&max_backwards};
        array x_link {&max_backwards};
        array position_link {&max_backwards} $25.;
        array nlines_link {&max_backwards};
        array connect_backward {&max_backwards};
        
        if _n_=1 then call missing(of row_link(*),of x_link(*),of position_link(*),of nlines_link(*));
        
        if position='BOTTOM' then do;
            if summary=1 then x_b2=x;
            else if missing(freq) then x_b=x;
            else x_b2=x;
            y=row_y(row);
            guessed_bottom=y+&multiline_adjust*_nlines_(row,column);
        end;
        else if position in('LEFT' 'RIGHT') then do;
            if position='RIGHT' then x_r=x;
            else if position='LEFT' then x_l=x;
            if position_link1='BOTTOM' then do;
                if missing(row_flink) then y=row_y(row);
                else y=(row_y(row_link1)+&multiline_adjust*_nlines_(row_link1,column_link1))+
                    ifn(column_flink^=column_link1,0.5,1)*off_trt*(row_y(row_flink)-
                        (row_y(row_link1)+&multiline_adjust*_nlines_(row_link1,column_link1)))/(n_off+1);                 
            end;
            guessed_bottom=y+&multiline_adjust*_nlines_(row,column)/2;
        end;
        fmtname='textboxes';
        start=_n_;
        rename text=label;
        _x_(row,column)=coalesce(x_b,x_r,x_l,x_b2);
        _y_(row,column)=y;
        if _n_>1 then do;
            output;            
            _text=text;
            do i = 1 to dim(connect_backward)-nmiss(of connect_backward(*));
                if i>1 then call missing(x_line,y_line,id,x_line2,y_line2);
                if position='BOTTOM' then do;
                    if column_link(i)=column then do;
                        link_x=_x_(row_link(i),column_link(i));link_y=_y_(row_link(i),column_link(i));
                    end;
                    else do;
                        link_x=_x_(row,column);link_y=(_y_(row_link(i),column_link(i))+&multiline_adjust*_nlines_(row_link(i),column_link(i))+_y_(row,column))/2;
                    end;
                end;
                else if position in('LEFT' 'RIGHT') then do;
                    link_x=_x_(row_link(i),column_link(i));link_y=_y_(row,column);
                end;
                
                if position='BOTTOM' and missing(_text) then do;   
                    call missing(start,fmtname,text,x_b,x_r,x_l,y);   
                    id=i*2000+_n_;x_line2=link_x;y_line2=link_y;output;
                           x_line2=_x_(row,column);y_line2=_y_(row,column);output;
                    call missing(x_line2,y_line2);
                end;
                else do;
                    call missing(start,fmtname,text,x_b,x_r,x_l,y);
                    id=i*1000+_n_;x_line=link_x;y_line=link_y;output;
                           x_line=_x_(row,column);y_line=_y_(row,column)-ifn(position='BOTTOM',&arrowhead_adjust.*&show_arrowheads.,0);output;
                end;
                if position='BOTTOM' and column_link(i)^=column then do;
                    id=i*1000+_n_+0.1;x_line2=_x_(row_link(i),column_link(i));y_line2=(_y_(row_link(i),column_link(i))+&multiline_adjust*_nlines_(row_link(i),column_link(i))+_y_(row,column))/2;
                               call missing(x_line,y_line);output;
                               x_line2=_x_(row,column);output;
                    id=i*1000+_n_+0.2;x_line2=_x_(row_link(i),column_link(i));output;
                          y_line2=_y_(row_link(i),column_link(i));output;
                end;
            end;
        end;
        else output;
        drop row_y: col_x: _nlines_: _positions_:;
    run;
    proc format cntlin=_consort (keep=start label fmtname where=(^missing(start)));
    run;
        
    data _plot;
        set _consort;
        x=coalesce(x_b,x_b2,x_l,x_r);
        %if %sysevalf(%superq(ref_text)^=,boolean) %then %do;
            %local nrefbox;
            %let nrefbox=%sysfunc(countw(%superq(ref_text),|));
            %do i = 1 %to &nrefbox;
                %if &i>1 %then %do; else %end;
                if _n_=&i then do;
                    length ref_text&i $200. ref_x&i ref_y&i ref_low&i ref_high&i ref_rotate&i 8.;
                    ref_text&i="%superq(ref_text&i)";
                    ref_y&i=&&ref_y&i;
                    ref_low&i=&xmin+5;ref_high&i=&xmax-5;
                    ref_x&i=&&ref_x&i;
                    ref_rotate&i=&&ref_rotate&i;
                end;
            %end;
        %end;
    run;
    %if &_listing^=1 and %sysevalf(%superq(gpath)=,boolean) %then %do;
        ods listing close image_dpi=&dpi;
    %end;
    %else %if %sysevalf(%superq(gpath)^=,boolean) %then %do;
        /**Save image to specified location**/
        ods listing image_dpi=&dpi gpath="&gpath";
    %end;
    %else %do;
        ods listing image_dpi=&dpi;
    %end;
    ods graphics / reset=index;
    /**Names and formats the image**/
    %if %sysevalf(%superq(plottype)^=,boolean) %then %do; 
        %if %qupcase(&plottype)=EMF %then %do;
            options printerpath='emf';
            ods graphics / imagefmt=&plottype;  
            /**Modifies temporary registry keys to create better EMF image in 9.4**/
            /**Taken from SAS Technical Support Martin Mincey**/
            %local workdir;
            %let workdir=%trim(%sysfunc(pathname(work))); 
            /**Creates the new keys**/
            data _null_;
                %if %qupcase(&sysscp)=WIN %then %do; 
                    file "&workdir.\_consort_emf94.sasxreg";
                %end;
                %else %do;
                    file "&workdir./_consort_emf94.sasxreg";
                %end;
                put '[CORE\PRINTING\PRINTERS\EMF\ADVANCED]';
                put '"Description"="Enhanced Metafile Format"';
                put '"Metafile Type"="EMF"';
                put '"Vector Alpha"=int:0';
                put '"Image 32"=int:1';
            run;    
            %if %qupcase(&sysscp)=WIN %then %do; 
                proc registry export="&workdir.\_consort_preexisting.sasxreg";/* Exports current SASUSER Keys */
                proc registry import="&workdir.\_consort_emf94.sasxreg"; /* Import the new keys */
                run;
            %end;
            %else %do;
                proc registry export="&workdir./_consort_preexisting.sasxreg";/* Exports current SASUSER Keys */
                proc registry import="&workdir./_consort_emf94.sasxreg"; /* Import the new keys */
                run;
            %end;
        %end;
        %else %if %qupcase(&plottype)=TIFF or %qupcase(&plottype)=TIF %then %do;
            ods graphics / imagefmt=png;    
        %end;
        %else %do;
            ods graphics / imagefmt=&plottype;  
        %end;          
    %end;
    ods results;
    ods select all;
    ods graphics / IMAGEMAP=OFF border=off width=&width.in height=&height.in imagename="&plotname";
    options notes;
    proc sgplot data=_plot nowall noborder noautolegend;* noopaque;
        %if &nsplit>0 %then %do;
            series x=x_line2 y=y_line2 / group=id lineattrs=(thickness=&line_size color=&line_color pattern=solid);
        %end;
        series x=x_line y=y_line / group=id lineattrs=(thickness=&line_size color=&line_color pattern=solid) 
            %if &show_arrowheads=1 %then %do; arrowheadpos=end arrowheadscale=0.4 arrowheadshape=&arrowhead_shape %end;;
    
        %if %sysevalf(%superq(ref_text)^=,boolean) %then %do i = 1 %to &nrefbox;
            highlow y=ref_y&i low=ref_low&i high=ref_high&i / lineattrs=(thickness=&&ref_line_size&i color=&&ref_line_color&i pattern=&&ref_line_pattern&i);
            text x=ref_x&i y=ref_y&i text=ref_text&i / splitchar='~' splitpolicy=splitalways splitjustify=center position=center backfill 
                fillattrs=(color=&&ref_border_color&i) 
                pad=(top=%eval(2+&ref_border_width) bottom=%eval(2+&ref_border_width)
                     left=%eval(2+&ref_border_width+&&ref_box_expand&i/2) right=%eval(2+&ref_border_width+&&ref_box_expand&i/2))
                textattrs=(color=&&ref_font_color&i size=&&ref_font_size&i family="&font") strip rotate=ref_rotate&i;
            text x=ref_x&i y=ref_y&i text=ref_text&i / splitchar='~' splitpolicy=splitalways splitjustify=center position=center backfill 
                fillattrs=(color=&&ref_background_color&i) 
                pad=(top=2 bottom=2 left=%eval(2+&&ref_box_expand&i/2) right=%eval(2+&&ref_box_expand&i/2))
                textattrs=(color=&&ref_font_color&i size=&&ref_font_size&i family="&font") strip rotate=ref_rotate&i;
        %end;
        
        text x=x_b y=y text=start / %if &textbox_outline=1 %then %do; outline %end; pad=2px position=bottom transparency=0 
            splitchar='~' splitpolicy=splitalways backfill nomissinggroup group=label 
            fillattrs=(color=&textbox_background_color) textattrs=(color=&font_color size=&font_size. pt family="&font") strip
            outlineattrs=(thickness=2pt color=&textbox_outline_color) SPLITJUSTIFY=center ;

        text x=x_b2 y=y text=start / %if &textbox_outline=1 %then %do; outline %end; pad=2px position=bottom transparency=0 splitchar='~' 
            splitpolicy=splitalways backfill 
            fillattrs=(color=&textbox_background_color) textattrs=(color=&font_color size=&font_size. pt family="&font") strip
            outlineattrs=(thickness=2pt color=&textbox_outline_color) SPLITJUSTIFY=left ;
            
        text x=x_r y=y text=start / %if &textbox_outline=1 %then %do; outline %end; pad=2px position=right transparency=0 
            splitchar='~' splitpolicy=splitalways backfill 
            fillattrs=(color=&textbox_background_color) textattrs=(color=&font_color size=&font_size. pt family="&font") strip
            outlineattrs=(thickness=2pt  color=&textbox_outline_color) SPLITJUSTIFY=left;
       

        %if &nsplit>0 %then %do;
            text x=x_l y=y text=start / %if &textbox_outline=1 %then %do; outline %end; pad=2px position=left transparency=0 
                splitchar='~' splitpolicy=splitalways backfill 
                fillattrs=(color=&textbox_background_color) textattrs=(color=&font_color size=&font_size. pt family="&font") strip
                outlineattrs=(thickness=2pt color=&textbox_outline_color) SPLITJUSTIFY=left;
        %end;
        format start textboxes.;
        %if &show_anchorpoints=1 %then %do;
            scatter x=x y=y / markerattrs=(color=red symbol=circlefilled size=8pt);
            scatter x=x y=guessed_bottom / markerattrs=(color=blue symbol=circlefilled size=8pt);
        %end;
        
        xaxis type=linear 
            %if &show_limits=0 %then %do;
                display=none 
            %end;
            %else %do;
                display=(nolabel)
            %end; %if &show_grid=1 %then %do; grid %end; offsetmin=0 offsetmax=0 min=&xmin max=&xmax values=(&xmin to &xmax by 5) valueshint;
        yaxis type=linear 
            %if &show_limits=0 %then %do;
                display=none 
            %end;
            %else %do;
                display=(nolabel)
            %end; %if &show_grid=1 %then %do; grid %end; reverse offsetmin=0 offsetmax=0 min=&ymin max=&ymax values=(&ymin to &ymax by 5) valueshint;
        %if &nsplit=0 %then %do;
            where position ^='LEFT';
        %end;
    run;

    /**Changes Potential Registry Changes back**/
    %if %qupcase(&plottype)=EMF %then %do;
        proc registry clearsasuser; /* Deletes the SASUSER directory */
        proc registry import="&workdir./_consort_preexisting.sasxreg";/* Imports starting SASUSER Keys */
        run;
    %end;
    /**Creates the TIFF file from the PNG file created earlier**/
    %else %if %qupcase(&plottype)=TIFF or %qupcase(&plottype)=TIF %then %do;
        %local _fncheck _fncheck2;
        options nonotes;
        %if %sysevalf(%superq(gpath)=,boolean) %then %do;
            filename conspng "./&plotname..png"; 
            filename constif "./&plotname..tiff";
            data _null_;
                x=fexist('conspng');
                x2=fdelete('constif');
                call symput('_fncheck',strip(put(x,12.)));
                call symput('_fncheck2',strip(put(x2,12.)));
            run;
            %if %sysevalf(%superq(_fncheck)^=1,boolean) %then %do;
                filename conspng "./&plotname.1.png"; 
            %end;
        %end;
        %else %do;
            filename conspng "%sysfunc(tranwrd(&gpath./&plotname..png,//,/))"; 
            filename constif "%sysfunc(tranwrd(&gpath./&plotname..tiff,//,/))"; 
            data _null_;
                x=fexist('conspng');
                x2=fdelete('constif');
                call symput('_fncheck',strip(put(x,12.)));
                call symput('_fncheck2',strip(put(x2,12.)));
            run;
            %if %sysevalf(%superq(_fncheck)^=1,boolean) %then %do;
                filename conspng "%sysfunc(tranwrd(&gpath./&plotname.1.png,//,/))"; 
            %end;
        %end;
        options notes;
        goptions device=&tiffdevice gsfname=constif 
            xmax=&width ymax=&height 
            xpixels=%sysevalf(%sysfunc(compress(&width,abcdefghijklmnopqrstuvwxyz,i))*&dpi) 
            ypixels=%sysevalf(%sysfunc(compress(&height,abcdefghijklmnopqrstuvwxyz,i))*&dpi)
            imagestyle=fit iback=conspng noborder;
        proc gslide;
        run;
        quit; 
        data _null_;
            x=fdelete('conspng');
        run;
        filename conspng clear;
        filename constif clear;
    %end;
    options nonotes; 
    
    %errhandl:    
    %if &debug=0 %then %do;
        proc datasets nolist nodetails;
            delete _temp _temp2 _consort _x_limits _y_limits _limits
                _temp1 _temp3 _temp4 _temp5 _temp6 _temp6b _temp7 _temp8 _temp9 _temp9b _temp10 _temp11
                _plot _offpts _unique_splits _unique_paths _unique_paths _unique_paths_off _unique_paths_r _parent_child
                _split_parent _split_parent2 _switch;
        quit;
    %end;
    
    /**Reload previous Options**/ 
    %if &_listing=1 %then %do;
        ods Listing;
    %end;
    %else %do;
        ods listing close;
    %end;
    ods path &_odspath;
    options mergenoby=&_mergenoby &_notes &_qlm msglevel=&_msglevel &_mprint;
    %put CONSORT has finished processing, runtime: %sysfunc(putn(%sysevalf(%sysfunc(TIME())-&_starttime.),mmss8.4)); 
%mend;
