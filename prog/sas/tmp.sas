PROC SGPLOT DATA = plot NOAUTOLEGEND DESCRIPTION=""; 
    YAXIS LABEL = 'Risk of Inflammatory Bowel Disease' LABELATTRS=(size=13pt weight=bold)  VALUES = (0 TO 0.0045 BY 0.0005) valueattrs=(size=12pt); 
    XAXIS LABEL = 'Follow-up Time (years)' 		       LABELATTRS=(size=13pt weight=bold)  VALUES = (0 TO 4 BY 0.5)         valueattrs=(size=12pt); 

    title height=12pt bold " ";
    step x=&timevar y=&exposure._risk /lineattrs=(color=blue pattern=1  thickness=2) name="&exposure._risk";
    step x=&timevar y=&exposure._lower/lineattrs=(color=blue pattern=20 thickness=1) name="&exposure._lower";
    step x=&timevar y=&exposure._upper/lineattrs=(color=blue pattern=20 thickness=1) name="&exposure._upper";

    step x=&timevar y=&comparator._risk /lineattrs=(color=red  pattern=1  thickness=2) name="&comparator._risk";
    step x=&timevar y=&comparator._lower/lineattrs=(color=red  pattern=20 thickness=1) name="&comparator._lower";
    step x=&timevar y=&comparator._upper/lineattrs=(color=red  pattern=20 thickness=1) name="&comparator._upper";
    keylegend "exposure._risk" "&comparator._risk" /location=inside position=topleft valueattrs=(size=12pt weight=bold) NOBORDER;
    FOOTNOTE;
    RUN; 
PROC SGPLOT DATA = plot NOAUTOLEGEND DESCRIPTION=""; 
    YAXIS LABEL = 'Risk of Inflammatory Bowel Disease' LABELATTRS=(size=13pt weight=bold)  VALUES = (0 TO 0.0045 BY 0.0005) valueattrs=(size=12pt); 
    XAXIS LABEL = 'Follow-up Time (years)' 		    LABELATTRS=(size=13pt weight=bold)  VALUES = (0 TO 4 BY 0.5) valueattrs=(size=12pt); 

    title height=12pt bold " ";
    step x=&timevar y=&exposure._risk/lineattrs=(color=blue pattern=1 thickness=2) name="&exposure.";
    step x=&timevar y=&exposure._lower/lineattrs=(color=blue pattern=20 thickness=1) name="&exposure._lower";
    step x=&timevar y=&exposure._upper/lineattrs=(color=blue pattern=20 thickness=1) name="&exposure._upper";

    step x=&timevar y=&comparator._risk/lineattrs=(color=red  pattern=1 thickness=2) name="&comparator.";
    step x=&timevar y=&comparator._lower/lineattrs=(color=red  pattern=20 thickness=1) name="&comparator._lower";
    step x=&timevar y=&comparator._upper/lineattrs=(color=red  pattern=20 thickness=1) name="&comparator._upper";
    keylegend "&exposure." "&comparator." /location=inside position=topleft valueattrs=(size=12pt weight=bold) NOBORDER;
    FOOTNOTE;
    RUN; 