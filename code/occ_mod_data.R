# occ_mod_data.R ---- 
# Code to pull together the data for the occupancy model 

# Load packages ----
library(plyr)
library(raster)
library(readr)
library(dplyr)
library(tidyr)
library(prism)
library(jagsUI)
library(abind)

options(prism.path = "data/prism")

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
eBird_dat_species <- data.frame(cell=eBird_dat_nonspecies$cell, eBird_dat_species)

# remove locations where none of the study species have been observed
eBird_dat_no_obs <- group_by(eBird_dat_species, cell) %>%
  summarise_each(funs(max))

no_obs <- rowSums(eBird_dat_no_obs[-1])
eBird_dat_obs <- eBird_dat_no_obs[which(no_obs > 0),]

eBird_dat_species <- eBird_dat_species[,names(which(colSums(eBird_dat_no_obs[-1]) != 0))]

eBird_dat_out <- data.frame(eBird_dat_nonspecies, eBird_dat_species) %>% filter(cell %in% eBird_dat_no_obs$cell)

eBird_dat_out <- filter(eBird_dat_out, cell %in% eBird_dat_obs$cell)

# this line may get changed, currently limiting data for years 2006-2011 (range of NCLD tested)
eBird_dat_out <- filter(eBird_dat_out, YEAR %in% 2006:2011)

# 3. Environmental covariate data ----
cov_data <- stack("data/prism/covariate_dat.tif")
names(cov_data) <- c("perc_forest", "perc_agri", "perc_urban", ls_prism_data()[,1])
cov_data_df <- as.data.frame(cov_data) %>% mutate(cell = row.names(.))

# 4. Bundle together data ----
# observations data
y <- eBird_dat_out[,8:44]

# loop counters
nspecies <- dim(y)[2]
nvisit <- dim(y)[1]
nsite <- length(unique(eBird_dat_out$cell))
nyear <- length(unique(eBird_dat_out$YEAR))

# site to visit/year lookup
site <- eBird_dat_out$cell
year <- eBird_dat_out$YEAR

# state covariates
forest <- scale(cov_data_df$perc_forest)
agri <- scale(cov_data_df$perc_agri)
urban <- scale(cov_data_df$perc_urban)
temp <- cov_data_df[,grepl("tmean", names(cov_data_df))]
temp <- temp[3:8]
ppt <- cov_data_df[,grepl("ppt", names(cov_data_df))]
ppt <- ppt[3:8]

# observation covariates
n_list <- eBird_dat_out$n_list
effort_hrs <- eBird_dat_out$EFFORT_HRS
num_obs <- eBird_dat_out$NUMBER_OBSERVERS

# jags data
model_data <- list(y=y, nspecies=nspecies, nvisit=nvisit, nsite=nsite, nyear=nyear, site=site, year=year, forest=forest, agri=agri, urban=urban, temp=temp, ppt=ppt, n_list=n_list, effort_hrs=effort_hrs, num_obs=num_obs)
save(model_data, file="model_data_2016_11_16")

# 5. Run occupancy model ----
# set initial values
z <- group_by(eBird_dat_out[-(3:7)], cell, YEAR) %>% summarise_each(funs(max))
zst <- array(data=NA, dim=c(nspecies, nsite, nyear))
for(i in 1:nspecies){
  for(j in 1:nsite) {
    for(t in nyear) { # NB will need to change if years change
      val <- filter(z, cell==j, YEAR==year[t])
      zst[i,j,t] <- ifelse(nrow(val)==0, NA, val[i+2])
    }
  }
}

inits <- function(){ list(z = zst)}

# set parameters to save
params <- c("mu.phibeta1", "mu.phibeta2", "mu.phibeta3", "mu.phibeta4", "mu.phibeta5", "mu.gammabeta1", "mu.gammabeta2", "mu.gammabeta3", "mu.gammabeta4", "mu.gammabeta5",
            "tau.phibeta1", "tau.phibeta2", "tau.phibeta3", "tau.phibeta4", "tau.phibeta5", "tau.gammabeta1", "tau.gammabeta2", "tau.gammabeta3", "tau.gammabeta4", "tau.gammabeta5",
            "mu.pbeta1", "mu.pbeta2", "mu.pbeta3", "tau.pbeta1", "tau.pbeta2", "tau.pbeta3", "phi", "gamma", "p")

out <- jags(data = model_data, inits = inits, parameters.to.save = params, model.file="code/dynocc_covs.JAGS.R", n.chains=3, n.adapt=100, n.iter=1000, n.burnin=500, n.thin=2, parallel = TRUE)
