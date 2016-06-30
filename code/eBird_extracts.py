# -*- coding: utf-8 -*-
"""
Created on Tue Jun 21 11:56:11 2016

@author: LauraGraham
"""

import pandas as pd
import numpy as np
import datetime
from sqlalchemy import create_engine


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
humdat['value'] = 1

# get the unique sampling replicates 
sampling_reps = humdat[['obs_date', 'mon_year', 'loc_id']].drop_duplicates().sort_values(['loc_id', 'obs_date'])
max_rep = max(sampling_reps.groupby(['loc_id', 'mon_year']).cumcount())

species = pd.DataFrame(humdat.species.unique(), columns = ['species'])
# try subsetting by month and creating a dataframe per month
humdat_month = humdat.query("mon_year == '2013-09' & loc_id == 'L2237076'")
humdat_month['replicate'] = humdat_month.sort_values(['species', 'loc_id', 'obs_date']).groupby(['species', 'loc_id']).cumcount()
humdat_month_wide = humdat_month.pivot(index = 'species',columns = 'replicate', values = 'value').reset_index()
humdat_month_wide = species.merge(humdat_month_wide,how = "left").fillna(value = 0)
extra_cols = list(range(humdat_month_wide.columns[humdat_month_wide.shape[1]-1]+1, max_rep+1))
extra_cols = pd.DataFrame(index = humdat_month_wide.index, columns = extra_cols)
humdat_month_wide = pd.concat([humdat_month_wide, extra_cols], axis = 1)

