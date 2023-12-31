set proj=D:\Externe Projekte\UNC\wangje\sas\prog
set name=10_readdata
"C:\Program Files\SASHome\SASFoundation\9.4\sas.exe" -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" -work "D:\SASTemp" -sysin "%proj%\%name%.sas" -log "%proj%\%name%.log" -print "%proj%\%name%.lst" -nosplash -nologo -icon 
set name=11_cleandata
"C:\Program Files\SASHome\SASFoundation\9.4\sas.exe" -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" -work "D:\SASTemp" -sysin "%proj%\%name%.sas" -log "%proj%\%name%.log" -print "%proj%\%name%.lst" -nosplash -nologo -icon 
set name=12_createcohorts
"C:\Program Files\SASHome\SASFoundation\9.4\sas.exe" -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" -work "D:\SASTemp" -sysin "%proj%\%name%.sas" -log "%proj%\%name%.log" -print "%proj%\%name%.lst" -nosplash -nologo -icon 
set name=013_merge
"C:\Program Files\SASHome\SASFoundation\9.4\sas.exe" -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" -work "D:\SASTemp" -sysin "%proj%\%name%.sas" -log "%proj%\%name%.log" -print "%proj%\%name%.lst" -nosplash -nologo -icon 




set name=
"C:\Program Files\SASHome\SASFoundation\9.4\sas.exe" -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" -work "D:\SASTemp" -sysin "%proj%\%name%.sas" -log "%proj%\%name%.log" -print "%proj%\%name%.lst" -nosplash -nologo -icon 
set name=
"C:\Program Files\SASHome\SASFoundation\9.4\sas.exe" -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" -work "D:\SASTemp" -sysin "%proj%\%name%.sas" -log "%proj%\%name%.log" -print "%proj%\%name%.lst" -nosplash -nologo -icon 
set name=
"C:\Program Files\SASHome\SASFoundation\9.4\sas.exe" -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" -work "D:\SASTemp" -sysin "%proj%\%name%.sas" -log "%proj%\%name%.log" -print "%proj%\%name%.lst" -nosplash -nologo -icon 

