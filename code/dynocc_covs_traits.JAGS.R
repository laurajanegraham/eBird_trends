model {

  # Ecological state priors ----
  for (i in 1:nspecies){
    # initial occupancy - fixed effect
    psi1[i] ~ dunif(0, 1)
    
    # persistence - random effect
    phialpha[i] ~ dnorm(mu.phialpha[trait[i]], tau.phialpha[trait[i]]) # intercept
    phibeta1[i] ~ dnorm(mu.phibeta1[trait[i]], tau.phibeta1[trait[i]]) # forest %
    phibeta2[i] ~ dnorm(mu.phibeta2[trait[i]], tau.phibeta1[trait[i]]) # agri %
    phibeta3[i] ~ dnorm(mu.phibeta3[trait[i]], tau.phibeta1[trait[i]]) # urban %
    phibeta4[i] ~ dnorm(mu.phibeta4[trait[i]], tau.phibeta1[trait[i]]) # ppt
    phibeta5[i] ~ dnorm(mu.phibeta5[trait[i]], tau.phibeta1[trait[i]]) # temp
    
    gammaalpha[i] ~ dnorm(mu.gammaalpha[trait[i]], tau.gammaalpha[trait[i]]) # intercept
    gammabeta1[i] ~ dnorm(mu.gammabeta1[trait[i]], tau.gammabeta1[trait[i]]) # forest %
    gammabeta2[i] ~ dnorm(mu.gammabeta2[trait[i]], tau.gammabeta2[trait[i]]) # agri %
    gammabeta3[i] ~ dnorm(mu.gammabeta3[trait[i]], tau.gammabeta3[trait[i]]) # urban %
    gammabeta4[i] ~ dnorm(mu.gammabeta4[trait[i]], tau.gammabeta4[trait[i]]) # ppt
    gammabeta5[i] ~ dnorm(mu.gammabeta5[trait[i]], tau.gammabeta5[trait[i]]) # temp 
  }
  
  # Ecological state hyperpriors ----
  mu.phialpha ~ dnorm(0, 0.01)
  mu.gammaalpha ~ dnorm(0, 0.01)
  tau.phialpha ~ dt(0,1,1)T(0,)
  tau.gammaalpha ~ dt(0,1,1)T(0,)
  
  for(f in 1:3){ # colonisation and extinction drivers may differ depending on functional group
    phibeta1.mean[f] ~ dnorm(0, 0.01)
    phibeta2.mean[f] ~ dnorm(0, 0.01)
    phibeta3.mean[f] ~ dnorm(0, 0.01)
    phibeta4.mean[f] ~ dnorm(0, 0.01)
    phibeta5.mean[f] ~ dnorm(0, 0.01) 
    mu.phibeta1[f] <- logit(phibeta1.mean[f])
    mu.phibeta2[f] <- logit(phibeta2.mean[f])
    mu.phibeta3[f] <- logit(phibeta3.mean[f])
    mu.phibeta4[f] <- logit(phibeta4.mean[f])
    mu.phibeta5[f] <- logit(phibeta5.mean[f])
    
    gammabeta1.mean[f] ~ dnorm(0, 0.01)
    gammabeta2.mean[f] ~ dnorm(0, 0.01)
    gammabeta3.mean[f] ~ dnorm(0, 0.01)
    gammabeta4.mean[f] ~ dnorm(0, 0.01)
    gammabeta5.mean[f] ~ dnorm(0, 0.01) 
    mu.gammabeta1[f] <- logit(gammabeta1.mean[f])
    mu.gammabeta2[f] <- logit(gammabeta2.mean[f])
    mu.gammabeta3[f] <- logit(gammabeta3.mean[f])
    mu.gammabeta4[f] <- logit(gammabeta4.mean[f])
    mu.gammabeta5[f] <- logit(gammabeta5.mean[f])
    
    tau.phibeta1[f] ~ dt(0,1,1)T(0,)
    tau.phibeta2[f] ~ dt(0,1,1)T(0,)
    tau.phibeta3[f] ~ dt(0,1,1)T(0,)
    tau.phibeta4[f] ~ dt(0,1,1)T(0,)
    tau.phibeta5[f] ~ dt(0,1,1)T(0,)
    
    tau.gammabeta1[f] ~ dt(0,1,1)T(0,)
    tau.gammabeta2[f] ~ dt(0,1,1)T(0,)
    tau.gammabeta3[f] ~ dt(0,1,1)T(0,)
    tau.gammabeta4[f] ~ dt(0,1,1)T(0,)
    tau.gammabeta5[f] ~ dt(0,1,1)T(0,)
  }

  # Observation priors ----
  # Currently modelled as fixed effects
  for (i in 1:nspecies){
    pbeta1[i] ~ dnorm(mu.pbeta1, tau.pbeta1) # n_list
    pbeta2[i] ~ dnorm(mu.pbeta2, tau.pbeta2) # EFFORT_HRS
    pbeta3[i] ~ dnorm(mu.pbeta3, tau.pbeta3) # NUMBER_OBSERVERS
  }
  
  for (t in 1:nyear) {
    palpha[t] ~ dnorm(0, tau.palpha)
  }
  
  # Observation hyperpriors
  mu.pbeta1 ~ dnorm(0, 0.01)
  mu.pbeta2 ~ dnorm(0, 0.01)
  mu.pbeta3 ~ dnorm(0, 0.01)
  
  tau.palpha ~ dt(0,1,1)T(0,)
  tau.pbeta1 ~ dt(0,1,1)T(0,)
  tau.pbeta2 ~ dt(0,1,1)T(0,)
  tau.pbeta3 ~ dt(0,1,1)T(0,)

  # Ecological state submodel ----
  for (i in 1:nspecies){
    for (j in 1:nsite){
      z[i,j,1] ~ dbern(psi1[i])
      for (t in 2:nyear){
        # Persistence and colonisation for species i at site j in year t are functions of the covariates in year t-1 and t respectively (NB the landcover covariates are static in time)
        logit(phi[i,j,t]) <- phialpha[i] + phibeta1[i] * forest[j] + phibeta2[i] * agri[j] + phibeta3[i] * urban[j] + phibeta4[i] * ppt[j, t-1] + phibeta5[i] * temp[j, t-1]
        logit(gamma[i,j,t]) <- gammaalpha[i] + gammabeta1[i] * forest[j] + gammabeta2[i] * agri[j] + gammabeta3[i] * urban[j] + gammabeta4[i] * ppt[j, t] + gammabeta5[i] * temp[j, t]
        
        # Dynamic occupancy = previous occupancy modified by persistence and colonisation
        muZ[i,j,t]<- z[i,j,t-1]*phi[i,j,t] + (1-z[i,j,t-1])*gamma[i,j,t]
        
        # True occupancy z for species i in site j in year t
        z[i,j,t] ~ dbern(muZ[i,j,t])
      } #l
    } #k
  } #i
  
  # Observation submodel ----
  for (i in 1:nspecies){
    for (k in 1:nvisit){
      logit(p[i,k]) <- palpha[year[k]] + pbeta1[i]*n_list[k] + pbeta2[i]*effort_hrs[k]
      muy[i,k] <- z[i,site[k],year[k]]*p[i,k]
      y[k,i] ~ dbern(muy[i,k])
    }
  }

  # Derived parameters ---- this section needs sorting
  # Sample and population occupancy, growth rate and turnover
  # for (k in 1:nspecies){
  #   psi[1,k] <- psi1[k]
  #   n.occ[1,k]<-sum(z[1,1:nsite,k])
  #   for (j in 1:nsite){
  #      meanp[1,j,k] <- sum(p[1,j,k,1:nrep])/nrep
  #   }
  #   mean_p[1,k] <- sum(meanp[1,1:nrep,k])/nsite
  #   for (i in 2:nyear){
  #     psi[i,k] <- psi[i-1,k]*phi[i-1,k] + (1-psi[i-1,k])*gamma[i-1,k]
  #     n.occ[i,k] <- sum(z[i,1:nsite,k])
  #     growthr[i-1,k] <- psi[i,k]/psi[i-1,k]
  #     turnover[i-1,k] <- (1 - psi[i-1,k]) * gamma[i-1,k]/psi[i,k]
  #     for (j in 1:nsite){
  #        meanp[i,j,k] <- sum(p[i,j,k,1:nrep])/nrep
  #      }
  #     mean_p[i,k] <- sum(meanp[i,1:nrep,k])/nsite
  #   }
  # }
}

