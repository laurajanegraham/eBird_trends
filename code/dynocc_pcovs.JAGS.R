model {

  # Ecological state priors ----
  for (i in 1:nspecies){
    # initial occupancy - fixed effect
    psi1[i] ~ dunif(0, 1)

    # RANDOM EFFECTS
    logitphi[i] ~ dnorm(mu.phi, tau.phi) # Persistence probabilities
    logit(phi[i]) <- logitphi[i]
    logitgamma[i] ~ dnorm(mu.gamma, tau.gamma) # Colonisation probabilities
    logit(gamma[i]) <- logitgamma[i]
  }
  
  # Ecological state hyperpriors ----
  mu.phi ~ dnorm(0, 0.01) 
  mu.gamma ~ dnorm(0, 0.01)
  
  tau.phi ~ dt(0,1,1)T(0,)
  tau.gamma ~ dt(0,1,1)T(0,)

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
        # Dynamic occupancy = previous occupancy modified by persistence and colonisation
        muZ[i,j,t]<- z[i,j,t-1]*phi[i] + (1-z[i,j,t-1])*gamma[i]
        
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
   for (i in 1:nspecies){
     psi[i,1] <- psi1[i]
     
     n.occ[i,1]<-sum(z[i,1:nsite,1])

     for (t in 2:nyear){
       psi[i,t] <- psi[i, t-1]*phi[i] + (1-psi[i, t-1])*gamma[i]  
       n.occ[i, t] <- sum(z[i,1:nsite,t])
       growthr[i, t-1] <- psi[i,t]/psi[i, t-1]
       turnover[i, t-1] <- (1 - psi[i,t-1]) * gamma[i]/psi[i,t]
     }
   }
}

