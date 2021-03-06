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
library(rgdal)

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

# get BCR
bcr <- readOGR("data/BCR", "BCR")
bcr <- spTransform(bcr, cov_data@crs)
bcr_28 <- subset(bcr, BCRNumber %in% c(28, 29)) # currently working on these two because need to shrink the data for a reasonable length run (not whole US-48) and by selecting these it gives a reasonable range of the land cover variables, not as correlated as it would be with just 28 as originally planned. 

# crop cov_data
cov_data <- mask(cov_data, bcr_28)
cov_data_df <- as.data.frame(cov_data) %>% mutate(cell = row.names(.))
cov_data_df <- cov_data_df[which(complete.cases(cov_data_df)),]


# 4. Bundle together data ----
# filter eBird_dat_out to include only cites within the selected BCRs
eBird_dat_out <- filter(eBird_dat_out, cell %in% cov_data_df$cell)

# site to visit lookup
site_lookup <- data.frame(cell = unique(eBird_dat_out$cell), site = 1:length(unique(eBird_dat_out$cell)))
eBird_dat_out <- merge(eBird_dat_out, site_lookup)

# observations data
y <- eBird_dat_out[,8:44]

# loop counters
nspecies <- dim(y)[2]
nvisit <- dim(y)[1]
nsite <- length(unique(eBird_dat_out$cell))
nyear <- length(unique(eBird_dat_out$YEAR))

# lookup visit to site / year 
site <- eBird_dat_out$site
year <- eBird_dat_out$YEAR - 2005

# state covariates
forest <- scale(cov_data_df$perc_forest)
agri <- scale(cov_data_df$perc_agri)
urban <- scale(cov_data_df$perc_urban)
temp <- cov_data_df[,grepl("tmean", names(cov_data_df))]
temp <- scale(temp[3:8])
ppt <- cov_data_df[,grepl("ppt", names(cov_data_df))]
ppt <- scale(ppt[3:8])


# observation covariates
n_list <- eBird_dat_out$n_list
effort_hrs <- eBird_dat_out$EFFORT_HRS
num_obs <- eBird_dat_out$NUMBER_OBSERVERS

# jags data
model_data <- list(y=y, nspecies=nspecies, nvisit=nvisit, nsite=nsite, nyear=nyear, site=site, year=year, forest=forest, agri=agri, urban=urban, temp=temp, ppt=ppt, n_list=n_list, effort_hrs=effort_hrs, num_obs=num_obs)

# 5. Run occupancy model ----
# set initial values
z <- group_by(eBird_dat_out[-c(1,3:7)], site, YEAR) %>% summarise_each(funs(max))
zst <- array(data=NA, dim=c(nspecies, nsite, nyear))
for(i in 1:nspecies){
  for(j in 1:nsite) {
    for(t in 1:nyear) { # NB will need to change if years change
      val <- filter(z, site==j, YEAR==t+2005)
      if(nrow(val) != 0) zst[i,j,t] <- as.numeric(val[,i+2])
    }
  }
}

model_data$zst = zst

# save and reload script because the jags part of the model run on diff computer
save(model_data, file="data/model_data_2016_11_23.rda")
load("data/model_data_2016_11_23.rda")
ef_birds <- read.csv("eastern_forest_birds.csv", stringsAsFactors = FALSE)
mig_lookup <- data.frame(mig_status=unique(ef_birds$mig_status), mig_code=1:3)
ef_birds <- merge(ef_birds, mig_lookup)
ef_birds <- merge(data.frame(ID = 1:ncol(model_data$y), scientific_name=gsub("_", " ", names(model_data$y))), ef_birds) %>%
  arrange(ID)

model_data$trait <- ef_birds$mig_code

inits <- function(){ list(z = model_data$zst)}

# set parameters to save
params <- c("mu.phibeta1", "mu.phibeta2", "mu.phibeta3", "mu.phibeta4", "mu.phibeta5", "mu.gammabeta1", "mu.gammabeta2", "mu.gammabeta3", "mu.gammabeta4", "mu.gammabeta5")

system.time(out <- jags(data = model_data, inits = inits, parameters.to.save = params, model.file="code/dynocc_covs_traits.JAGS.R", n.chains=3, n.adapt=100, n.iter=1000, n.burnin=500, n.thin=2, parallel = TRUE))

save(out, file="results/jags_out_mig.Rda")

# update the jags model and save every 1000 iterations
for(rep in 1:100) {
  out <- update(out, n.iter=1000, parallel = TRUE)
  save(out, file="results/jags_out_mig.Rda")
}
