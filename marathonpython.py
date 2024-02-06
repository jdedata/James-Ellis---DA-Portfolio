#import libraries
import pandas as pd,
import seaborn as sns,

df = pd.read_csv("TWO_CENTURIES_OF_UM_RACES.csv")
#View the data that's been imported
df.head(10)
df.shape
df.dtypes

#Cleaning data
#Selecting: USA Races, 50k or 50mi, year 2020
#Step 1: View 50k or 50m

df[df['Event distance/length'] == '50km']
#Users may also write '50k' instead of '50km', so check:
df[df['Event distance/length'] == '50k']
#Check for miles
df[df['Event distance/length'] == '50m']
df[df['Event distance/length'] == '50mi']
#Combine 50km and 50mi
df[df['Event distance/length'].isin (['50km','50mi'])]
#Refine to year 2020
df[(df['Event distance/length'].isin (['50km','50mi'])) & (df['Year of event'] == 2020)]
#Refine events down to 'USA' events
df[df['Event name'].str.split('(').str.get(1).str.split(')').str.get(0) == 'USA']
#Combine all filters
df[(df['Event distance/length'].isin (['50km','50mi'])) & (df['Year of event'] == 2020) & (df['Event name'].str.split('(').str.get(1).str.split(')').str.get(0) == 'USA')]
rt1 = df[(df['Event distance/length'].isin (['50km','50mi'])) & (df['Year of event'] == 2020) & (df['Event name'].str.split('(').str.get(1).str.split(')').str.get(0) == 'USA')]
rt1.head(10)

#Remove (USA) from event name
rt1['Event name'].str.split('(').str.get(0)
rt1['Event name'] = rt1['Event name'].str.split('(').str.get(0)
#Check for 'USA' removal
rt1.head(10)

#Clean up athlete data (age)
rt1['athlete_age'] = 2020 - rt1['Athlete year of birth']
#Remove 'h' from performance
rt1['Athlete performance'] = rt1['Athlete performance'].str.split(' ').str.get(0)

#Drop columns: Athlete Club, Athlete Country, Athlete year of birth, Athlete Age Category
rt1 = rt1.drop(['Athlete club', 'Athlete country', 'Athlete year of birth', 'Athlete age category'], axis = 1)

#Clean up null values
rt1.isna().sum
rt1[rt1['athlete_age'].isna()==1]
rt1 = rt1.dropna()

#Check for duplicate values
rt1[rt1.duplicated() == True]

#Reset index
rt1.reset_index(drop = True)

#Fix types
rt1['athlete_age'] = rt1['athlete_age'].astype(int)
rt1['Athlete average speed'] = rt1['Athlete average speed'].astype(float)
rt1.dtypes

#Rename columns
#Year of event                  int64
#Event dates                   object
#Event name                    object
#Event distance/length         object
#Event number of finishers      int64
#Athlete performance           object
#Athlete gender                object
#Athlete average speed         object
#Athlete ID                     int64
#athlete_age                  float64

rt1 = rt1.rename(columns={'Year of event': 'year',
                          'Event dates': 'race_day',
                          'Event name': 'race_name',
                          'Event distance/length': 'race_length',
                          'Event number of finishers': 'race_number_of_finishers',
                          'Athlete performance': 'athlete_performance',
                          'Athlete gender': 'athlete_gender',
                          'Athlete average speed': 'athlete_average_speed',
                          'Athlete ID': 'athlete_id'})
rt1.head(5)
#Reorder columns
rt2 = rt1[['race_day', 'race_name', 'race_length', 'race_number_of_finishers', 'athlete_id', 'athlete_gender',]]
rt2.head(5)

#Find 2 specific races based off name and runner ID
rt2[rt2['race_name'] == 'Everglades 50 Mile Ultra Run ']
rt2[rt2['athlete_id'] == 222509]

#Charts and Graphs
sns.histplot(rt2['race_length'])
sns.histplot(rt2, x = 'race_length', hue = 'athlete_gender')
sns.displot(rt2[rt2['race_length'] == '50mi']['athlete_average_speed'])
sns.violinplot(rt2, x = 'race_length', y = 'athlete_average_speed', hue = 'athlete_gender')
