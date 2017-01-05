model {

  # Ecological state priors ----
  for (i in 1:nspecies){
    # initial occupancy - fixed effect
    psi1[i] ~ dunif(0, 1)
    
    # persistence - random effect
    phialpha[i] ~ dnorm(mu.phialpha, tau.phialpha) # intercept
    phibeta1[i] ~ dnorm(mu.phibeta1, tau.phibeta1) # forest %
    phibeta2[i] ~ dnorm(mu.phibeta2, tau.phibeta1) # temp
    phibeta3[i] ~ dnorm(mu.phibeta3, tau.phibeta1) # forest * temp

    
    gammaalpha[i] ~ dnorm(mu.gammaalpha, tau.gammaalpha) # intercept
    gammabeta1[i] ~ dnorm(mu.gammabeta1, tau.gammabeta1) # forest %
    gammabeta2[i] ~ dnorm(mu.gammabeta2, tau.gammabeta2) # temp %
    gammabeta3[i] ~ dnorm(mu.gammabeta3, tau.gammabeta3) # forest * temp
  }
  
  # Ecological state hyperpriors ----
  mu.phialpha ~ dnorm(0, 0.01)
  mu.phibeta1 ~ dnorm(0, 0.01)
  mu.phibeta2 ~ dnorm(0, 0.01)
  mu.phibeta3 ~ dnorm(0, 0.01)
 
  mu.gammaalpha ~ dnorm(0, 0.01)
  mu.gammabeta1 ~ dnorm(0, 0.01)
  mu.gammabeta2 ~ dnorm(0, 0.01)
  mu.gammabeta3 ~ dnorm(0, 0.01)

  tau.phialpha ~ dt(0,1,1)T(0,)
  tau.phibeta1 ~ dt(0,1,1)T(0,)
  tau.phibeta2 ~ dt(0,1,1)T(0,)
  tau.phibeta3 ~ dt(0,1,1)T(0,)

  tau.gammaalpha ~ dt(0,1,1)T(0,)
  tau.gammabeta1 ~ dt(0,1,1)T(0,)
  tau.gammabeta2 ~ dt(0,1,1)T(0,)
  tau.gammabeta3 ~ dt(0,1,1)T(0,)

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
        logit(phi[i,j,t]) <- phialpha[i] + phibeta1[i] * forest[j] + phibeta2[i] * temp[j, t-1] + phibeta3[i] * forest[j] * temp[j, t-1]
        logit(gamma[i,j,t]) <- gammaalpha[i] + gammabeta1[i] * forest[j] + gammabeta2[i] * temp[j, t] + gammabeta3[i] * forest[j] * temp[j, t]
        
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

