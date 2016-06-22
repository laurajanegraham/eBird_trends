# -*- coding: utf-8 -*-
"""
Created on Tue Jun 21 11:56:11 2016

@author: LauraGraham
"""

import pandas as pd
import datetime
from sqlalchemy import create_engine
from itertools import product


# connect to database
engine = create_engine('postgresql://postgres:password123.@localhost:5432/ebird_data')

# Extract the data for US, humminbirds, from 2004-2014
humdat = pd.read_sql_query("""SELECT sampling_event_id, 
                           loc_id, 
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
                           AND family = 'Trochilidae' 
                           AND year >=2004 
                           AND year <=2014"""
                           , con=engine)

# convert the observation date to full date
humdat['obs_date'] = humdat.apply(lambda x: datetime.datetime.strptime(str(x['year']) + ' ' + str(x['day']), '%Y %j').strftime('%Y-%m-%d'), axis = 1)
humdat['mon_year'] = humdat.obs_date.str.slice(0, 7)

# get the unique sampling replicates 
sampling_reps = humdat[['obs_date', 'mon_year', 'loc_id']].drop_duplicates().sort_values(['loc_id', 'obs_date'])
sampling_reps['replicate'] = sampling_reps.groupby(['loc_id', 'mon_year']).cumcount()

all_reps = pd.DataFrame(list(product(sampling_reps['mon_year'], list(range(max(sampling_reps['replicate']) + 1)))), columns = ['mon_year', 'replicate'])