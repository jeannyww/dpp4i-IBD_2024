import pandas as pd
import numpy as np

# Read the CSV file into a DataFrame
df= pd.read_csv(filepath_or_buffer='.\\labels_task231122.csv', header=0) 

# Print the first 5 rows of the DataFrame
print(df.head())

# Refactor the code using Pandas
df['Type2']= None
df['flag']=df['Variable'].str.endswith(('_bc','_gc')).astype('int')  
df.loc[(df['Type']=='Char')| (df['flag']==1),'Type2']='$'
print(df.loc[df['Type']=='Char', 'Type'])
df.loc[(df['Type']=='Num') & (df['Format']=='MMDDYY10.'),'Type2']='$'
print(df.loc[(df['Type']=='Num') & (df['Format']=='MMDDYY10.'), 'Type'])
df.loc[df['Type']=='Num','Type2']=''
print(df.loc[df['Type']=='Num', 'Type'])
df.loc[(df['Type2']=='$'), 'Length']='$ 10'
df.loc[(df['Type2']==''), 'Length']='8' 
df.loc[(df['Type2']=='$') &(df['Variable']=='ID'),'Length']='$ 12'  
# Print the updated DataFrame
print(df.head())
print(df.tail())
# Print character string to insert into SAS program
# Create a new column that combines 'Variable' and 'Type2' with a space in between
df['combined'] = df.apply(lambda row: f"{row['Variable']} {row['Type2']}", axis=1)

# Concatenate all the values in the 'combined' column into a single string with spaces as delimiters
text_string = ' '.join(df['combined'])

print(text_string)



# Print character string to insert into SAS program
# Create a new column that combines 'Length' and 'Type2' with a space in between
df['combined2'] = df.apply(lambda row: f"{row['Variable']} {row['Length']}", axis=1)

# Concatenate all the values in the 'combined' column into a single string with spaces as delimiters
text_string = ' '.join(df['combined2'])

print(text_string)
