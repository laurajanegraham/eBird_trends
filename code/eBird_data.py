# -*- coding: utf-8 -*-
"""
Created on Wed Jun  8 10:23:19 2016

@author: LauraGraham
"""

import pandas as pd
import numpy as np
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
cur.execute("""DROP TABLE ebird_checklist_species""")
cur.execute("""DROP TABLE ebird_checklist_info""")
cur.execute("""CREATE TABLE ebird_checklist_info (
                                  SAMPLING_EVENT_ID varchar(50) PRIMARY KEY,
                                  LOC_ID  varchar(50),                              
                                  LATITUDE numeric,
                                  LONGITUDE numeric,
                                  YEAR int,
                                  MONTH int,
                                  DAY int,
                                  TIME numeric,
                                  COUNTRY varchar(50),
                                  STATE_PROVINCE varchar(50),
                                  COUNTY varchar(50), 
                                  COUNT_TYPE varchar(50),
                                  EFFORT_HRS numeric,
                                  EFFORT_DISTANCE_KM numeric,
                                  EFFORT_AREA_HA numeric,
                                  OBSERVER_ID varchar(50),
                                  NUMBER_OBSERVERS numeric,
                                  GROUP_ID varchar(50),
                                  PRIMARY_CHECKLIST_FLAG numeric,
                                  ASTER2011_DEM numeric,
                                  UMD2011_LANDCOVER numeric,
                                  UMD2011_FS_L_1500_LPI numeric,
                                  UMD2011_FS_L_1500_PD numeric,
                                  UMD2011_FS_L_1500_ED numeric,
                                  UMD2011_FS_C0_1500_PLAND numeric,
                                  UMD2011_FS_C0_1500_LPI numeric,
                                  UMD2011_FS_C0_1500_PD numeric,
                                  UMD2011_FS_C0_1500_ED numeric,
                                  UMD2011_FS_C1_1500_PLAND numeric,
                                  UMD2011_FS_C1_1500_LPI numeric,
                                  UMD2011_FS_C1_1500_PD numeric,
                                  UMD2011_FS_C1_1500_ED numeric,
                                  UMD2011_FS_C2_1500_PLAND numeric,
                                  UMD2011_FS_C2_1500_LPI numeric,
                                  UMD2011_FS_C2_1500_PD numeric,
                                  UMD2011_FS_C2_1500_ED numeric,
                                  UMD2011_FS_C3_1500_PLAND numeric,
                                  UMD2011_FS_C3_1500_LPI numeric,
                                  UMD2011_FS_C3_1500_PD numeric,
                                  UMD2011_FS_C3_1500_ED numeric,
                                  UMD2011_FS_C4_1500_PLAND numeric,
                                  UMD2011_FS_C4_1500_LPI numeric,
                                  UMD2011_FS_C4_1500_PD numeric,
                                  UMD2011_FS_C4_1500_ED numeric,
                                  UMD2011_FS_C5_1500_PLAND numeric,
                                  UMD2011_FS_C5_1500_LPI numeric,
                                  UMD2011_FS_C5_1500_PD numeric,
                                  UMD2011_FS_C5_1500_ED numeric,
                                  UMD2011_FS_C6_1500_PLAND numeric,
                                  UMD2011_FS_C6_1500_LPI numeric,
                                  UMD2011_FS_C6_1500_PD numeric,
                                  UMD2011_FS_C6_1500_ED numeric,
                                  UMD2011_FS_C7_1500_PLAND numeric,
                                  UMD2011_FS_C7_1500_LPI numeric,
                                  UMD2011_FS_C7_1500_PD numeric,
                                  UMD2011_FS_C7_1500_ED numeric,
                                  UMD2011_FS_C8_1500_PLAND numeric,
                                  UMD2011_FS_C8_1500_LPI numeric,
                                  UMD2011_FS_C8_1500_PD numeric,
                                  UMD2011_FS_C8_1500_ED numeric,
                                  UMD2011_FS_C9_1500_PLAND numeric,
                                  UMD2011_FS_C9_1500_LPI numeric,
                                  UMD2011_FS_C9_1500_PD numeric,
                                  UMD2011_FS_C9_1500_ED numeric,
                                  UMD2011_FS_C10_1500_PLAND numeric,
                                  UMD2011_FS_C10_1500_LPI numeric,
                                  UMD2011_FS_C10_1500_PD numeric,
                                  UMD2011_FS_C10_1500_ED numeric,
                                  UMD2011_FS_C12_1500_PLAND numeric,
                                  UMD2011_FS_C12_1500_LPI numeric,
                                  UMD2011_FS_C12_1500_PD numeric,
                                  UMD2011_FS_C12_1500_ED numeric,
                                  UMD2011_FS_C13_1500_PLAND numeric,
                                  UMD2011_FS_C13_1500_LPI numeric,
                                  UMD2011_FS_C13_1500_PD numeric,
                                  UMD2011_FS_C13_1500_ED numeric,
                                  UMD2011_FS_C16_1500_PLAND numeric,
                                  UMD2011_FS_C16_1500_LPI numeric,
                                  UMD2011_FS_C16_1500_PD numeric,
                                  UMD2011_FS_C16_1500_ED numeric
                              );""")
cur.execute("""CREATE TABLE ebird_checklist_species (
                                  SAMPLING_EVENT_ID varchar(50), 
                                  SPECIES varchar(57)
                              );""")
                              
for f in files:
    # only want to go into folders which actually have the checklists.csv (e.g. the doc folder should be ignored)
    if os.path.isfile(f + r'\checklists.csv'):
    # load the file
        checklist = f + r'\checklists.csv'
        covariate = f + r'\extended-covariates.csv'

        print("Loading data for " + f)
        # covariate file is narrow enough to read in all at once        
        covariate_dat = pd.read_csv(covariate, na_values = ['?', '-9999', '-9999.0000'])
        
        # read in the checklist file 1000 rows at a time
        for checklist_dat in pd.read_csv(checklist, na_values = ['?'], chunksize = 1000):
        
            print("Manipulate sampling covariates for " + f)
            info = checklist_dat.ix[:,0:19]
            info = info.merge(covariate_dat)
            info.to_csv(r'temp_info.csv', header = None, index = None, na_rep='NaN')
            del covariate_dat
            del info
            
            print("Manipulating species presences for " + f)
            sp_pres = checklist_dat[np.r_[0, 19:len(checklist_dat.columns)]] 
            del checklist_dat
            sp_pres = pd.melt(sp_pres, id_vars = ['SAMPLING_EVENT_ID'], var_name = 'species', value_name = 'pres' )
            sp_pres = sp_pres[sp_pres['pres'] != 0]
            sp_pres = sp_pres[['SAMPLING_EVENT_ID', 'species']]
            sp_pres.to_csv(r'temp_sp.csv', header = None, index = None)
            del sp_pres
            
            print("Loading species presences for " + f + " into SQL database")
            sp_sql = """COPY ebird_checklist_species FROM 'D:\\eBird_trends\\data\\erd_western_hemisphere_data_grouped_by_year_v5.0\\temp_sp.csv' WITH DELIMITER AS ',';"""
            cur.execute(sp_sql)
            print("Loading sampling covariates for " + f + " into SQL database")
            info_sql = """COPY ebird_checklist_info FROM 'D:\\eBird_trends\\data\\erd_western_hemisphere_data_grouped_by_year_v5.0\\temp_info.csv' WITH DELIMITER AS ',';"""
            cur.execute(info_sql)
                    
print("Creating foreign key constraint")
cur.execute("""ALTER TABLE ebird_checlist_species ADD CONSTRAINT spfk (sampling_event_id) REFERENCES ebird_checklist_info (sampling_event_id) MATCH FULL;""")
con.commit()
cur.close()
con.close()