# -*- coding: utf-8 -*-
"""
Created on Tue Jun 21 11:56:11 2016

@author: LauraGraham
"""

import pandas as pd

from sqlalchemy import create_engine

# connect to database
engine = create_engine('postgresql://postgres:password123.@localhost:5432/ebird_data')

# Extract the data for US, humminbirds, from 2004-2014
humdat = pd.read_sql_query("""SELECT loc_id, 
       latitude, 
       longitude, 
       year, 
       month, 
       day, 
       time,
       sppres.species
FROM ebird_checklist_info info
INNER JOIN ebird_checklist_species sppres
       ON info.sampling_event_id = sppres.sampling_event_id
INNER JOIN ebird_species_info spinfo
       ON sppres.species = spinfo.species
WHERE country = 'United_States' 
AND family = 'Trochilidae' AND year >=2004 AND year <=2014""", con=engine)
