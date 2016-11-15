# -*- coding: utf-8 -*-
"""
Created on Thu Oct 20 14:29:56 2016

@author: lg1u16
"""

import pandas as pd
import numpy as np
import os
from rpy2.robjects import r

os.chdir(r'HUMMINGBIRDS\eBird_trends\data\ebird_us48_data_grouped_by_year_v2014')
files = next(os.walk('.'))[1]

# get the species of interest
ef_birds = pd.read_csv('..\..\eastern_forest_birds.csv')
ef_birds.scientific_name = ef_birds.scientific_name.str.replace(' ', '_')
ef_species = ef_birds.scientific_name.tolist()

for f in files:
    # only want to go into folders which actually have the checklists.csv (e.g. the doc folder should be ignored)
    if os.path.isfile(f + r'\checklists.csv'):
    # load the file
        checklist = f + r'\checklists.csv'
        covariate = f + r'\core-covariates.csv'
        
        covariate_dat = pd.read_csv(covariate, na_values = ['?', '-9999', '-9999.0000'])
        checklist_dat = pd.read_csv(checklist, na_values = ['?'])
        
        # need to work out how to change all the species stuff to pres/abs. 
        birds = pd.DataFrame(checklist_dat, columns=ef_species).fillna(value='0')
        birds = birds.astype(str)
        birds_bool = birds != '0' 
        
        checklist_dat = pd.concat([checklist_dat.ix[:,0:19], birds_bool], axis=1) # this selects riows up to 19, need to do columns
        
        dat = checklist_dat.query("MONTH in (5, 6, 7) & COUNT_TYPE in ('P21', 'P22', 'P23') & PRIMARY_CHECKLIST_FLAG == 1.0")
        
        # create fortnight column and merge to data
        days = pd.DataFrame({'DAY': dat.DAY.unique(), 'REP': np.repeat(list(range(7)), [14, 13, 13, 13, 13, 13, 13], axis=0)})
        dat = dat.merge(days)
        
        # get the unique lat long so that it can be exported and the unique cell id for the covariate raster collected
        lat_long = dat.ix[:,2:4].drop_duplicates()
        lat_long.to_csv(r'../temp_lat_long.csv', index = None)
        
        # doing this bit in R because not a clue how in python 
        r("source('../../code/get_cell.R')")
        
        # load the lat_long file back in with cellID attached
        lat_long = pd.read_csv(r'../temp_lat_long.csv')        
        
        dat = dat.merge(lat_long)
        
        dat_gp = dat.groupby(['cell', 'REP'])
        dat_agg = dat_gp.agg({"YEAR": "count",
                              "EFFORT_HRS": "sum",
                              "EFFORT_DISTANCE_KM": "sum",
                              "EFFORT_AREA_HA": "sum",
                              "NUMBER_OBSERVERS": "sum",
                              "Empidonax_virescens": "max",
                              "Setophaga_ruticilla": "max",
                              "Mniotilta_varia": "max",
                              "Cyanocitta_cristata": "max",
                              "Sitta_pusilla": "max",
                              "Toxostoma_rufum": "max",
                              "Dendroica_pensylvanica": "max",
                              "Quiscalus_quiscula": "max",
                              "Geothlypis_trichas": "max",
                              "Picoides_pubescens": "max",
                              "Sialia_sialis": "max",
                              "Sayornis_phoebe": "max",
                              "Pipilo_erythrophthalmus": "max",
                              "Contopus_virens": "max",
                              "Spizella_pusilla": "max",
                              "Picoides_villosus": "max",
                              "Wilsonia_citrina": "max",
                              "Passerina_cyanea": "max",
                              "Cardinalis_cardinalis": "max",
                              "Colaptes_auratus": "max",
                              "Parula_americana": "max",
                              "Icterus_spurius": "max",
                              "Seiurus_aurocapilla": "max",
                              "Dryocopus_pileatus": "max",
                              "Dendroica_pinus": "max",
                              "Dendroica_discolor": "max",
                              "Protonotaria_citrea": "max",
                              "Melanerpes_carolinus": "max",
                              "Sitta_canadensis": "max",
                              "Vireo_olivaceus": "max",
                              "Melanerpes_erythrocephalus": "max",
                              "Pheucticus_ludovicianus": "max",
                              "Piranga_olivacea": "max",
                              "Baeolophus_bicolor": "max",
                              "Catharus_fuscescens": "max",
                              "Sitta_carolinensis": "max",
                              "Vireo_griseus": "max",
                              "Meleagris_gallopavo": "max",
                              "Aix_sponsa": "max",
                              "Hylocichla_mustelina": "max",
                              "Coccyzus_americanus": "max",
                              "Vireo_flavifrons": "max",
                              "Dendroica_dominica": "max"}).reset_index()
        
        dat_agg.rename(columns={'YEAR': 'n_list'}, inplace=True)
        dat_agg['YEAR'] = np.repeat(f, dat_agg.shape[0])
        
        # get rid of sites with < 3 replicates
        dat_agg_sml = dat_agg[['REP', 'cell']].groupby(['cell']).size().reset_index()
        dat_agg_sml.columns = ['cell', 'REP']
        dat_locations = dat_agg_sml.query('REP > 2').cell
        dat_out = dat_agg[dat_agg.cell.isin(dat_locations)]
        
        dat_out.to_csv(r'../' + f + '_eBird.csv', index = None)
        