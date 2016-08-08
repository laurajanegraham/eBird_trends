model {
  
  # Specify priors
  
  for (k in 1:nspecies){
    psi1[k] ~ dunif(0, 1)
    for(i in 1:(nyear-1)){
      phi[i,k] ~ dunif(0, 1)
      gamma[i,k] ~ dunif(0, 1)
      p[i,k] ~ dunif(0, 1) 
    }
    p[nyear,k] ~ dunif(0, 1)
  }
  
  for (k in 1:nspecies){
    alphap[k] ~ dnorm(0, 0.01)
    for (np in 1:nparam){
      beta[np, k] ~ dnorm(0, 0.01)
      w[np, k] ~ dbern(0.5)
    }
  }
  
  # Ecological submodel: Define state conditional on parameters
  for (j in 1:nsite){
    for (k in 1:nspecies){
      z[1,j,k] ~ dbern(psi1[k])
      for (i in 2:nyear){
        muZ[i,j,k]<- z[i-1,j,k]*phi[i-1,k] + (1-z[i-1,j,k])*gamma[i-1,k]
        z[i,j,k] ~ dbern(muZ[i,j,k])
      } #l
    } #k
  } #i
  
  # Observation model
  for (i in 1:nyear){
    for (j in 1:nsite){
      for (k in 1:nspecies){
        for (l in 1:nrep){
          logit(p[i,j,k,l]) <- alphap[k] + w[1,k]*beta[1,k]*effort_hrs[i,j,l] + w[2,k]*beta[2,k]*day[i,j,l]
          muy[i,j,k,l] <- z[i,j,k]*p[i,j,k,l]
          y[i,j,k,l] ~ dbern(muy[i,j,k,l])
        }#l
      } #k
    } #j
  } #i
  
  # Derived parameters: Sample and population occupancy, growth rate and turnover
  # for (k in 1:nspecies){
  #   psi[1,k] <- psi1
  #   n.occ[1,k]<-sum(z[1,1:nsite,k])
  #   for (i in 2:nyear){
  #     psi[i,k] <- psi[i-1,k]*phi[i-1,k] + (1-psi[i-1,k])*gamma[i-1,k]
  #     n.occ[i,k] <- sum(z[i,1:nsite,k])
  #     growthr[i-1,k] <- psi[i,k]/psi[i-1,k]                         # originally we had growthr[k]. JAGS seem to dislike vectoring going from 2..K.
  #     turnover[i-1,k] <- (1 - psi[i-1,k]) * gamma[i-1,k]/psi[i,k]
  #   }
  # }
}

