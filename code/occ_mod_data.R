# occ_mod_data.R ---- 
# Code to pull together the data for the occupancy model 

# Load packages ----
library(plyr)
library(raster)
library(readr)
library(dplyr)
library(tidyr)

# 1. eBird observation and obs covariate data ----
files <- list.files("data", pattern="_eBird.csv", full.names = TRUE)

# load data and change the python True/False strings to 1/0
eBird_dat <- ldply(files, read_csv)
eBird_dat[eBird_dat=='True'] <- 1
eBird_dat[eBird_dat=='False'] <- 0

# pull out all locations which have been surveyed in 3+ years - given I'm 
# looking at what happens between two years might two be enough? 
# i.e. change to > 1
years_surveyed <- unique(eBird_dat[,c('cell', 'YEAR')]) %>% 
  group_by(cell) %>% 
  summarise(nyear = n()) %>%
  filter(nyear > 2)

eBird_dat <- filter(eBird_dat, cell %in% years_surveyed$cell)

# 2. Bird functional group data ----
ef_birds <- read_csv("eastern_forest_birds.csv")

# fix the order of the dataframe
eBird_dat_nonspecies <- select(eBird_dat, cell, YEAR, n_list, EFFORT_HRS, EFFORT_DISTANCE_KM, EFFORT_AREA_HA, NUMBER_OBSERVERS)
eBird_dat_species <- eBird_dat[,gsub(" ", "_", ef_birds$scientific_name)] %>% apply(., 2, function(x) as.numeric(x))
eBird_dat <- data.frame(eBird_dat_nonspecies, eBird_dat_species)

# remove locations where none of the study species have been observed
eBird_dat <- eBird_dat[which(rowSums(eBird_dat_species) > 0),]

# 3. Environmental covariate data ----


# 4. Bundle together data ----

# 5. Run occupancy model ----



