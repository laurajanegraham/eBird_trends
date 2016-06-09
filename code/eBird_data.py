# -*- coding: utf-8 -*-
"""
Created on Wed Jun  8 10:23:19 2016

@author: LauraGraham
"""

import pandas as pd
import os
import psycopg2 as psql
from sqlalchemy import create_engine

# list the directories
os.chdir(r'D:\eBird_trends\data\erd_western_hemisphere_data_grouped_by_year_v5.0')
files = next(os.walk('.'))[1]

# connect to database
con = psql.connect(dbname="ebird_data", host="localhost", port="5432", user="postgres", password="password123.")
cur = con.cursor()

# if tables are in there already, remove (this will need commenting out if we want to append more data)
#cur.execute("""DROP TABLE ebird_checklist_species""")
cur.execute("""DROP TABLE ebird_checklist_info""")

con.commit()
cur.close()
con.close()
engine = create_engine('postgresql://postgres:password123.@localhost:5432/ebird_data')

for f in files:
    # only want to go into folders which actually have the checklists.csv (e.g. the doc folder should be ignored)
    if os.path.isfile(f + r'\checklists.csv'):
    # load the file
        checklist = f + r'\checklists.csv'
        covariate = f + r'\extended-covariates.csv'
        
        print("Loading data for " + f)
        checklist_dat = pd.read_csv(checklist, na_values = ['?'])
        covariate_dat = pd.read_csv(covariate, na_values = ['-9999', '-9999.0000'])
        
        print("Manipulating species presences for " + f)
        sp_pres = pd.concat([checklist_dat.ix[:,0], checklist_dat.ix[:,19:len(checklist_dat.columns)]], axis=1)
        sp_pres = pd.melt(sp_pres, id_vars = ['SAMPLING_EVENT_ID'], var_name = 'species', value_name = 'pres' )
        sp_pres.columns = map(str.lower, sp_pres.columns) 
        
        print("Manipulate sampling covariates for " + f)
        info = checklist_dat.ix[:,0:19]
        info = info.merge(covariate_dat)
        info.columns = map(str.lower, info.columns) # makes later queries easier
        
        print("Loading sampling covariates for " + f + " into SQL database")
        info.to_sql('ebird_checklist_info', engine, if_exists = 'append', index = False)
        print("Loading species presences for " + f + " into SQL database")
        sp_pres.to_sql('ebird_checklist_species', engine, if_exists = 'append', index = False)
        
con = psql.connect(dbname="ebird_data", host="localhost", port="5432", user="postgres", password="password123.")
cur = con.cursor()

print("Creating primary and foreign key constraints")
cur.execute("""ALTER TABLE ebird_checklist_info ADD PRIMARY KEY (sampling_event_id);""")
cur.execute("""ALTER TABLE ebird_checlist_species ADD CONSTRAINT spfk (sampling_event_id) REFERENCES ebird_checklist_info (sampling_event_id) MATCH FULL;""")
con.commit()
cur.close()
con.close()