import re
import pandas as pd

# Open the file and read its content
with open('tmp.txt', 'r') as file:
    content = file.read()
# Use a regular expression to remove all standalone whole numbers
content = re.sub(r'\b\d+\b', '', content)
# Remove spaces, tabs, indents and new line entries
content = content.replace(' ', '').replace('\t', '').replace('\n', '')
# Open the file in write mode and write the modified content back to the file
with open('tmp.txt', 'w') as file:
    file.write(content)

# read the contents of the new file
with open('tmp.txt', 'r') as file:
    content = file.read()

# split the content by commas 
data=content.split(',')

df= pd.DataFrame(data, columns=['data'])

# export all variables to a csv-- these are the 400+ variable names that will be put into the import module for sas 
df.to_csv('tmp.csv', index=False)
