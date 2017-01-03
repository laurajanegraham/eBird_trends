library(jagsUI)

# Run occupancy model ----
load("data/model_data_2016_11_23.rda")

inits <- function(){ list(z = model_data$zst)}

# set parameters to save
params <- c("mu.gamma", "mu.phi", "n.occ", "growthr", "turnover")

system.time(out <- jags(data = model_data, inits = inits, parameters.to.save = params, model.file="code/dynocc_pcovs.JAGS.R", n.chains=3, n.adapt=100, n.iter=1000, n.burnin=500, n.thin=2, parallel = TRUE))

save(out, file="results/jags_out_p_1.Rda")

# update the jags model and save every 1000 iterations
for(rep in 1:100) {
  system.time(out <- update(out, n.iter=1000, parallel = TRUE))
  save(out, file=paste0("results/jags_out_p_", rep, ".Rda"))
}
