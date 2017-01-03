# Diagnostics of eBird occupancy model

# set this up to run from source-

library(ggplot2)
library(reshape2)
library(R2jags)
library(dplyr)
library(tidyr)
library(cowplot)

# Load the latest occupancy model output
load('results/jags_out_covs_3.Rda') # -> out

# Create the traceplot ----
sims.array <- as.data.frame(out$sims.list) %>%
  mutate(chain=rep(1:3, each=out$mcmc.info$n.samples/out$mcmc.info$n.chains),
         it=rep(1:(out$mcmc.info$n.samples/out$mcmc.info$n.chains), times=out$mcmc.info$n.chains)) %>%
  gather(parameter, value, -it, -chain)

gp <- ggplot(data=sims.array, aes(x=it, y=value, col=factor(chain))) +
  facet_wrap(~parameter, scales='free') + geom_line()

ggsave(gp, file=paste0('plots/traceplot_',1,'kit.png'),
       he=210, wi=350, units='mm')

# Plot the parameters (colonisation vs extinction) ----
sims.array <- filter(sims.array, parameter!="deviance")
param_lookup <- read.csv("parameter_lookup.csv")
sims.array <- merge(sims.array, param_lookup)
sims.array$covariate <- factor(sims.array$covariate, 
                                  levels=c("Forest (% cover)", "Agriculture (% cover)", "Urban (% cover)", "Temperature", "Precipitation"))
ggplot(data=sims.array, aes(x=value, y=..density.., colour=process, fill=process)) +
  geom_area(stat="bin", binwidth=0.01) +
  facet_wrap(~covariate)
