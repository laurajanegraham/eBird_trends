model {
  
  # Specify priors
  
  # ecological priors
  for (k in 1:nspecies){
    psi1[k] ~ dunif(0, 1)
    for(i in 1:(nyear-1)){
      phi[i,k] ~ dunif(0, 1)
      gamma[i,k] ~ dunif(0, 1)
    }
  }
  
  # observation coefficient priors
  for (k in 1:nspecies){
    alphap[k] ~ dnorm(0, 0.01)
    for (np in 1:nparam){
      betap[np, k] ~ dnorm(0, 0.01)
      wp[np, k] ~ dbern(0.5)
    }
  }
  
  # ecological submodel: Define state conditional on parameters
  for (j in 1:nsite){
    for (k in 1:nspecies){
      z[1,j,k] ~ dbern(psi1[k])
      for (i in 2:nyear){
        muZ[i,j,k]<- z[i-1,j,k]*phi[i-1,k] + (1-z[i-1,j,k])*gamma[i-1,k]
        z[i,j,k] ~ dbern(muZ[i,j,k])
      } #l
    } #k
  } #i
  
  # observation model
  for (i in 1:nyear){
    for (j in 1:nsite){
      for (k in 1:nspecies){
        for (l in 1:nrep){
          logit(p[i,j,k,l]) <- alphap[k] + 
            wp[1,k]*betap[1,k]*effort_hrs[i,j,l] + 
            wp[2,k]*betap[2,k]*day[l] +
            wp[3,k]*betap[3,k]*time[i,j,l] +
            wp[4,k]*betap[4,k]*j + # given year is the index have not brought it in as a variable separately
            wp[5,k]*betap[5,k]*pop00_sqmi[i] +
            wp[6,k]*betap[6,k]*housing_density[i] +
            wp[7,k]*betap[7,k]*number_observers[i,j,l]
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

