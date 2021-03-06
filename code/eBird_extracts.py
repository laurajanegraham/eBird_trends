# -*- coding: utf-8 -*-
"""
Created on Tue Jun 21 11:56:11 2016

@author: LauraGraham
"""

import pandas as pd
import numpy as np
import datetime
from sqlalchemy import create_engine
from rpy2.robjects import pandas2ri, r
pandas2ri.activate()

# connect to database
engine = create_engine('postgresql://postgres:password123.@localhost:5432/ebird_data')

# Extract the data for US, humminbirds, from 2004-2014
humdat = pd.read_sql_query("""SELECT info.sampling_event_id, 
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
                           WHERE state_province = 'Colorado' 
                           AND family = 'Trochilidae' 
                           AND year >=2008
                           AND month IN (5, 6, 7)"""
                           , con=engine)

# convert the observation date to full date
humdat['obs_date'] = humdat.apply(lambda x: datetime.datetime.strptime(str(x['year']) + ' ' + str(x['day']), '%Y %j').strftime('%Y-%m-%d'), axis = 1)
humdat['value'] = 1

# so here I'm reducing the data so that I only have month/location combinations with >= 3 replicates
# and then taking all locations where at least 12 months have +3 observations
# this is subject to change after discussions
# this causes the loss of 19 species
humdat_sml = humdat[['obs_date', 'year', 'loc_id']].drop_duplicates().groupby(['loc_id', 'year']).size().reset_index()
humdat_sml.columns = ['loc_id', 'year', 'obs']
humdat_month_location = humdat_sml.pivot(index = 'loc_id', columns = 'year', values = 'obs').fillna(value=0)
humdat_location_obs = humdat_month_location.apply(lambda x: (x >= 3).sum(), axis = 1)
humdat_location = humdat_location_obs[humdat_location_obs > 5].reset_index()
humdat_obs = humdat[humdat.loc_id.isin(humdat_location.loc_id)]

# output the locations before and after data pruning to plot and compare in r
locations_sml = humdat_obs[['loc_id', 'latitude', 'longitude']].drop_duplicates()
locations_full = humdat[['loc_id', 'latitude', 'longitude']].drop_duplicates()

r_locations_sml = pandas2ri.py2ri(locations_sml)
r.assign("locations_sml", r_locations_sml)
r("save(locations_sml, file='D:/eBird_trends/locations_sml.rda')")
r_locations_full = pandas2ri.py2ri(locations_full)
r.assign("locations_full", r_locations_full)
r("save(locations_full, file='D:/eBird_trends/locations_full.rda')")


# get the maximum number of unique sampling replicates 
max_rep = humdat_obs[['obs_date', 'year', 'loc_id']].drop_duplicates().sort_values(['loc_id', 'obs_date'])
max_rep = max(max_rep.groupby(['loc_id', 'year']).size())
year = humdat_obs.year.unique()
loc_id = humdat_obs.loc_id.unique()
species = pd.DataFrame(humdat_obs.species.unique(), columns = ['species'])
species_full = pd.DataFrame(humdat.species.unique(), columns = ['species'])
missing_species = species_full[~species_full.species.isin(species.species)]

# try subsetting by month and creating a dataframe per month
def data_juggle(in_dat, location, species):
    dat_sub = in_dat[in_dat.loc_id == location]
    dat_sub = dat_sub[['species', 'obs_date', 'value']].drop_duplicates()
    # get lookup for date/time and replicate
    sampling_reps = dat_sub[['obs_date']].drop_duplicates().sort_values(['obs_date'])
    sampling_reps['replicate'] = range(1, len(sampling_reps) + 1)
    
    dat_samp_reps = dat_sub.merge(sampling_reps)
    dat_wide = dat_samp_reps.pivot(index = 'species',columns = 'replicate', values = 'value').reset_index()
    dat_species = species.merge(dat_wide,how = "left").fillna(value = 0)
    #extra_cols = list(range(dat_species.columns[dat_species.shape[1]-1]+1, max_rep+1))
    #extra_cols = pd.DataFrame(index = dat_species.index, columns = extra_cols)
    out_dat = dat_species.drop(['species'], axis = 1).as_matrix()
    return out_dat;
    
wide_dat = list()

for i in range(0, len(year)):
    dat_year = humdat_obs[humdat_obs.year == year[i]]
    loc_id = dat_year.loc_id.unique()
    loc_dat = list()
    for j in range(0, len(loc_id)):
        loc_dat.append(data_juggle(humdat_obs,loc_id[j], species))
    wide_dat.append(loc_dat)
    print(str(year[i]) + ' processed')


r.assign("wide_dat", wide_dat)
r("save(wide_dat, file='D:/eBird_trends/data/test.rda')")
