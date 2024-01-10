set proj=D:\Externe Projekte\UNC\wangje\prog\sas
REM This is for running all SAS programs in the project folder and will overwrite log and lst files
set name=10_readdata
"C:\Program Files\SASHome\SASFoundation\9.4\sas.exe" -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" -work "D:\SASTemp" -sysin "%proj%\%name%.sas" -log "%proj%\%name%.log" -print "%proj%\%name%.lst" -nosplash -nologo -icon 
set name=11_cleandata
"C:\Program Files\SASHome\SASFoundation\9.4\sas.exe" -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" -work "D:\SASTemp" -sysin "%proj%\%name%.sas" -log "%proj%\%name%.log" -print "%proj%\%name%.lst" -nosplash -nologo -icon 
set name=12_createcohorts
"C:\Program Files\SASHome\SASFoundation\9.4\sas.exe" -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" -work "D:\SASTemp" -sysin "%proj%\%name%.sas" -log "%proj%\%name%.log" -print "%proj%\%name%.lst" -nosplash -nologo -icon 
set name=13_merge
"C:\Program Files\SASHome\SASFoundation\9.4\sas.exe" -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" -work "D:\SASTemp" -sysin "%proj%\%name%.sas" -log "%proj%\%name%.log" -print "%proj%\%name%.lst" -nosplash -nologo -icon 
set name=14_createanalysis
"C:\Program Files\SASHome\SASFoundation\9.4\sas.exe" -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" -work "D:\SASTemp" -sysin "%proj%\%name%.sas" -log "%proj%\%name%.log" -print "%proj%\%name%.lst" -nosplash -nologo -icon 
set name=15_psweighting
"C:\Program Files\SASHome\SASFoundation\9.4\sas.exe" -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" -work "D:\SASTemp" -sysin "%proj%\%name%.sas" -log "%proj%\%name%.log" -print "%proj%\%name%.lst" -nosplash -nologo -icon 
set name=16_runanalysis
"C:\Program Files\SASHome\SASFoundation\9.4\sas.exe" -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" -work "D:\SASTemp" -sysin "%proj%\%name%.sas" -log "%proj%\%name%.log" -print "%proj%\%name%.lst" -nosplash -nologo -icon 

