# Run occupancy model ----
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
