install.packages("R2jags")
library(R2jags)
load("locations_sml.rda")
load("locations_full.rda")

load("data/hummingbirds_colorado.rda")

# size of array
dim(wide_dat)

# Code modified from Kery and Schaub 2012
# Bundle data
dat <- list(y = wide_dat, nyear = dim(wide_dat)[1], nsite = dim(wide_dat)[2], nspecies = dim(wide_dat)[3], nrep = dim(wide_dat)[4])

# Initial values
zst <- apply(wide_dat, c(1, 2, 3), max)	# Observed occurrence as inits for z
inits <- function(){ list(z = zst)}
# Parameters monitored
params <- c("psi", "phi", "gamma", "p", "n.occ", "growthr", "turnover")

# MCMC settings
ni <- 2500
nt <- 4
nb <- 500
nc <- 3

# Call JAGS from R
strt <- Sys.time()
out <- jags.parallel(dat, inits, params, "code/dynocc.JAGS.R", n.chains = nc, n.thin = nt, n.iter = ni, n.burnin = nb)

save(out, file="basic_model.Rda")

print(Sys.time() - strt)
print(out, digits=3)