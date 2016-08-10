# -*- coding: utf-8 -*-
"""
Created on Wed Jun  8 10:23:19 2016

@author: LauraGraham
"""

import pandas as pd
import numpy as np
import os
import psycopg2 as psql

# list the directories
os.chdir(r'D:\eBird_trends\data\ebird_us48_data_grouped_by_year_v2014')
files = next(os.walk('.'))[1]

# connect to database
con = psql.connect(dbname="ebird_us_data", host="localhost", port="5432", user="postgres", password="password123.")
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
                                  POP00_SQMI numeric, 
                                  HOUSING_DENSITY numeric,
                                  HOUSING_PERCENT_VACANT numeric, 
                                  ELEV_GT numeric, 
                                  ELEV_NED numeric, 
                                  BCR numeric,
                                  BAILEY_ECOREGION varchar(5), 
                                  OMERNIK_L3_ECOREGION numeric, 
                                  CAUS_TEMP_AVG numeric,
                                  CAUS_TEMP_MIN numeric, 
                                  CAUS_TEMP_MAX numeric, 
                                  CAUS_PREC numeric, 
                                  CAUS_SNOW numeric,
                                  NLCD2001_FS_C11_7500_PLAND numeric, 
                                  NLCD2001_FS_C12_7500_PLAND numeric,
                                  NLCD2001_FS_C21_7500_PLAND numeric, 
                                  NLCD2001_FS_C22_7500_PLAND numeric,
                                  NLCD2001_FS_C23_7500_PLAND numeric, 
                                  NLCD2001_FS_C24_7500_PLAND numeric,
                                  NLCD2001_FS_C31_7500_PLAND numeric, 
                                  NLCD2001_FS_C41_7500_PLAND numeric,
                                  NLCD2001_FS_C42_7500_PLAND numeric, 
                                  NLCD2001_FS_C43_7500_PLAND numeric,
                                  NLCD2001_FS_C52_7500_PLAND numeric, 
                                  NLCD2001_FS_C71_7500_PLAND numeric,
                                  NLCD2001_FS_C81_7500_PLAND numeric, 
                                  NLCD2001_FS_C82_7500_PLAND numeric,
                                  NLCD2001_FS_C90_7500_PLAND numeric, 
                                  NLCD2001_FS_C95_7500_PLAND numeric,
                                  NLCD2006_FS_C11_7500_PLAND numeric, 
                                  NLCD2006_FS_C12_7500_PLAND numeric,
                                  NLCD2006_FS_C21_7500_PLAND numeric, 
                                  NLCD2006_FS_C22_7500_PLAND numeric,
                                  NLCD2006_FS_C23_7500_PLAND numeric, 
                                  NLCD2006_FS_C24_7500_PLAND numeric,
                                  NLCD2006_FS_C31_7500_PLAND numeric, 
                                  NLCD2006_FS_C41_7500_PLAND numeric,
                                  NLCD2006_FS_C42_7500_PLAND numeric, 
                                  NLCD2006_FS_C43_7500_PLAND numeric,
                                  NLCD2006_FS_C52_7500_PLAND numeric, 
                                  NLCD2006_FS_C71_7500_PLAND numeric,
                                  NLCD2006_FS_C81_7500_PLAND numeric, 
                                  NLCD2006_FS_C82_7500_PLAND numeric,
                                  NLCD2006_FS_C90_7500_PLAND numeric, 
                                  NLCD2006_FS_C95_7500_PLAND numeric,
                                  NLCD2011_FS_C11_7500_PLAND numeric, 
                                  NLCD2011_FS_C12_7500_PLAND numeric,
                                  NLCD2011_FS_C21_7500_PLAND numeric, 
                                  NLCD2011_FS_C22_7500_PLAND numeric,
                                  NLCD2011_FS_C23_7500_PLAND numeric, 
                                  NLCD2011_FS_C24_7500_PLAND numeric,
                                  NLCD2011_FS_C31_7500_PLAND numeric, 
                                  NLCD2011_FS_C41_7500_PLAND numeric,
                                  NLCD2011_FS_C42_7500_PLAND numeric, 
                                  NLCD2011_FS_C43_7500_PLAND numeric,
                                  NLCD2011_FS_C52_7500_PLAND numeric, 
                                  NLCD2011_FS_C71_7500_PLAND numeric,
                                  NLCD2011_FS_C81_7500_PLAND numeric, 
                                  NLCD2011_FS_C82_7500_PLAND numeric,
                                  NLCD2011_FS_C90_7500_PLAND numeric, 
                                  NLCD2011_FS_C95_7500_PLAND numeric
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
        covariate = f + r'\core-covariates.csv'

        print("Loading data for " + f)
        # covariate file is narrow enough to read in all at once        
        covariate_dat = pd.read_csv(covariate, na_values = ['?', '-9999', '-9999.0000'])
        # read in the checklist file 1000 rows at a time
        for checklist_dat in pd.read_csv(checklist, na_values = ['?'], chunksize = 10000):
        
            print("Manipulating sampling covariates for " + f)
            info = checklist_dat.ix[:,0:19]
            info = info.merge(covariate_dat)
            info.to_csv(r'temp_info.csv', header = None, index = None, na_rep='NULL')
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
            sp_sql = """COPY ebird_checklist_species FROM 'D:\\eBird_trends\\data\\ebird_us48_data_grouped_by_year_v2014\\temp_sp.csv' WITH DELIMITER AS ',';"""
            cur.execute(sp_sql)
            print("Loading sampling covariates for " + f + " into SQL database")
            info_sql = """COPY ebird_checklist_info FROM 'D:\\eBird_trends\\data\\ebird_us48_data_grouped_by_year_v2014\\temp_info.csv' WITH DELIMITER AS ',' NULL AS 'NULL';"""
            cur.execute(info_sql)

        del covariate_dat
        con.commit()
cur.close()
con.close()