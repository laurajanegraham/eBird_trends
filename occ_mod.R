library(R2jags)
library(snowfall)
library(abind)
library(R2WinBUGS)
library(dplyr)
library(tidyr)
library(ggplot2)
library(cowplot)

load("data/hummingbirds_colorado.rda")

# Code modified from Kery and Schaub 2012
# Bundle data
all_dat$sp_obs[is.nan(all_dat$sp_obs)] <- NA # data comes out of SQL/Python with missing values coded as NaN - causes issues in JAGS
nyear <- dim(all_dat$sp_obs)[1]
nsite <- dim(all_dat$sp_obs)[2]
#nsite <- 40 # make it run quicker for initial testing
nspecies <- dim(all_dat$sp_obs)[3]
#nrep <-  dim(all_dat$sp_obs)[4]
nrep <- apply(all_dat$sp_obs, c(1,2), function(x) max(which(!is.na(x[1,]))))
nrep[is.infinite(nrep)] <- 0
#nrep <- 10 # again, quicker for testing 

# create the scaled parameters
# need a function to scale an n-dimensional array
scale_array <- function(in_dat) {
  m <- mean(in_dat, na.rm=TRUE)
  s <- sd(in_dat, na.rm=TRUE)
  if(is.null(dim(in_dat))) {
    out_dat <- (in_dat-m)/s
  } else {
    out_dat <- apply(in_dat, 1:length(dim(in_dat)), function(x) (x-m)/s)
  }
  return(out_dat)
}

param_dat <- all_dat[-c(1,2)]
param_dat$year <- 1:nyear
param_dat <- lapply(param_dat, scale_array)
nparam <- length(param_dat)
dat <- list(y = all_dat$sp_obs, nyear = nyear, nsite = nsite, nspecies = nspecies, nrep = nrep, effort_hrs = param_dat$effort_hrs, day = param_dat$day, time = param_dat$time, number_observers = param_dat$number_observers, pop00_sqmi = param_dat$pop00_sqmi, housing_density = param_dat$housing_density, year = param_dat$year, nparam = nparam)

# Initial values
zst <- apply(all_dat$sp_obs, c(1, 2, 3), max, na.rm=TRUE)	# Observed occurrence as inits for z
zst[is.infinite(zst)] <- NA
#zst <- zst[,1:40,]
inits <- function(){ list(z = zst)}
# Parameters monitored
params <- c("psi", "phi", "gamma", "p", "alphap", "betap", "wp")

# MCMC settings
ni <- 5000
nt <- 4
nb <- 4000
nc <- 3

# Call JAGS from R
strt <- Sys.time()

source("code/JAGSParallel.R")
out <- JAGSParallel(n.cores = 3, data = dat, inits = inits, params = params, model.file = "code/dynocc_covs.JAGS.R", n.chains = nc, n.thin = nt, n.iter = ni, n.burnin = nb)

save(out, file="../eBird_trends_output/covs_model.rda")

print(Sys.time() - strt)

# PLOT 1: Heat map of important detection parameters
# Easier for initial viewing
# create data frame of summary statistics for analysis
jags_sum <- as.data.frame(out$JAGSoutput$summary) %>%
  mutate(param = rownames(.))

param_names <- data.frame(param_name=c("effort_hrs", "day", "time", "year", "pop00_sqmi", "housing_density", "number_observers"), parameter=1:7)
species_names <- data.frame(species_name=all_dat$species$species, species=1:nrow(all_dat$species))
# get estimates for the indicator variables
wp <- filter(jags_sum, grepl('wp', param)) %>%
  mutate(param = substr(param, 4, nchar(param) - 1)) %>%
  separate(param, c("parameter", "species"), sep="\\,") %>%
  mutate(var_use = ifelse(mean > 0.5, 1, NA)) %>% select(parameter, species, var_use)

# get the parameter estimates for the 'important' variables
beta <- filter(jags_sum, grepl('betap', param)) %>%
  mutate(param = substr(param, 7, nchar(param) - 1)) %>%
  separate(param, c("parameter", "species"), sep="\\,") %>%
  #select(mean, parameter, species) %>%
  merge(wp) %>%
  mutate(mean = mean*var_use) %>%
  merge(param_names) %>% merge(species_names)

# will also need to merge on species name once I have the .rda with them in

# plot coefficient estimates in a covariate x species heatmap
param_plot <- ggplot(data = beta, aes(x=param_name, y=species_name, fill=mean)) + 
  geom_tile() + scale_fill_gradient2(low = "blue", high = "red") +
  xlab("Covariate") + ylab("Species")

save_plot("param_plot.png", param_plot, base_width=12, base_height=12)

# PLOT 2: Density plot of important parameter estimates
# Carries more information
# get the coefficient values from JAGS output
jags_beta <- out$JAGSoutput$sims.list$betap %>%
  mutate(param = rownames(.))

# these need to be in a dataframe with values, parameter number and species number (based on indices of array)
vals <- c(jags_beta)
idx <- expand.grid(1:dim(jags_beta)[3],1:dim(jags_beta)[2])
idx <- idx[rep(seq_len(nrow(idx)), each=750),]
beta_df <- data.frame(val = vals, parameter = idx$Var2, species = idx$Var1) %>%
  merge(wp) %>%
  mutate(val = val*var_use) %>%
  merge(param_names) %>% merge(species_names)

beta_df <- beta_df[complete.cases(beta_df),]

param_density <- ggplot(data = beta_df, aes(x = val, fill=species_name, colour = species_name)) + 
  geom_density(alpha=0.1) + 
  facet_wrap(~param_name, scales="free")

save_plot("param_density.png", param_density, base_width = 12, base_height = 12)


