# Diagnostics of eBird occupancy model

# set this up to run from source-

library(ggplot2)
library(reshape2)
library(R2jags)
library(dplyr)

############################################################### lookup table
#load('site_cats.rData') # -> site_cats
#site_cats$Converted1970 <- as.logical(site_cats$Converted1970)
############################################################### 

#get the species information
load('results/jags_out_mig.Rda') # -> out
############################################################### traceplot

sims.array <- as.data.frame(out$sims.list)
sims.array$chain <- melt(sapply(1:3, rep, times=out$mcmc.info$n.samples/3))$value
sims.array$it <- rep(1:(out$mcmc.info$n.samples/3), times=3)
sims.array <- melt(sims.array, id=c('it', 'chain'))

gp <- ggplot(data=sims.array, aes(x=it, y=value, col=factor(chain))) +
  facet_wrap(~variable, scales='free') + geom_line() + theme_bw()
ggsave(gp, file=paste0('plots/traceplot_',1,'kit.png'),
       he=210, wi=350, units='mm')

############################################################### 
# FITTED VALUES
source('source/fitted_values_161130.R')

############################################################### species-level parameters

#data <- melt(as.data.frame(out$sims.list[c('init.occ','alpha.phi', "beta1")]))
#data$var2 <- gsub(data$variable, patt="\\.[0-9]{1,3}$", re='')

#data$spp_index <- as.numeric(mapply(FUN=gsub, x=data$variable, pattern=paste0(data$var2, "."), repl=""))

#data <- merge(data, species)
#(gp <- ggplot(data) + geom_freqpoly(aes(x=value, y=..density.., col=SpeciesCode), bins=50) + 
#  xlab(paste0('Parameter estimate')) + ylab('Posterior density') + theme_bw() +
#  facet_wrap(~var2, scales='free', nrow=3))
#ggsave(plot=gp, width=297, height=202, units='mm',
#       file=file.path(dir, paste0('posteriors_species_',kit,'kit.png')))
############################################################### 
# pair plots of the three parameters against one another, with error bars. Col=Rhat

sp_plot <- function(x, y, names=c('spest1', 'spest2')){
  names(x) <- paste0(names(x), '.x')
  names(y) <- paste0(names(y), '.y')
  sp <- cbind(x,y)
  sp$Rhat_prod <- with(sp, Rhat.x * Rhat.y)

  gp <- ggplot(data=sp, aes(x=mean.x, y=mean.y, 
                            xmin=mean.x-sd.x, xmax=mean.x+sd.x,
                            ymin=mean.y-sd.y, ymax=mean.y+sd.y,
                            col=Rhat_prod)) 
  gp <- gp + geom_point() + geom_errorbar() + geom_errorbarh()
  gp <- gp + xlab(names[1]) + ylab(names[2])
  gp <- gp + theme_bw()
  ggsave(gp, file=file.path(dir, paste0(names[1],'_vs_',names[2],'_',kit,'kit.png')))
}

#init.occ <- with(out, data.frame(mean=mean$init.occ, sd=sd$init.occ, Rhat=Rhat$init.occ))
#alpha.phi <- with(out, data.frame(mean=mean$alpha.phi, sd=sd$alpha.phi, Rhat=Rhat$alpha.phi))
#beta1 <- with(out, data.frame(mean=mean$beta1, sd=sd$beta1, Rhat=Rhat$beta1))
#sp_plot(x=init.occ, y=alpha.phi, names=c('initial occupancy','peristence'))
#sp_plot(x=init.occ, y=beta1, names=c('initial occupancy','sensitivity to range position'))
#sp_plot(x=alpha.phi, y=beta1, names=c('persistence','sensitivity to range position'))

############################################################### site

data <- as.data.frame(out$sims.list[grepl('\\.site', names(out$sims.list))])

png(file=paste0(dir,'/site_params_',kit,'kit.png'), he=1000, wi=1000); pairs(data); dev.off()


data <- melt(data, id=NULL)

# edit the names of the variables to regroup them for plotting
levels(data$variable) <- gsub(levels(data$variable), pa='\\.site', re='')
levels(data$variable) <- gsub(levels(data$variable), pa='\\.0', re='\\.PA_Uncnv')
levels(data$variable) <- gsub(levels(data$variable), pa='\\.1', re='\\.IM_vs_PA')
levels(data$variable) <- gsub(levels(data$variable), pa='\\.2', re='\\.Converted')
levels(data$variable) <- gsub(levels(data$variable), pa='\\.eta', re='_eta')

l2 <- strsplit(levels(data$variable), "\\.")
l2<- data.frame(l=levels(data$variable), 
                p=sapply(l2, function(x) x[[1]]), 
                q=sapply(l2, function(x) x[[2]]))
# get the 
#l2 <- merge(l2, site_cats)
data <- merge(data, l2, by.x='variable', by.y='l')

(gp <- ggplot(data) + geom_freqpoly(aes(x=value, y=..density..,
                      col = q), bins=50) + 
  xlab(paste0('Parameter estimate')) + ylab('Posterior density') + theme_bw() +
  facet_wrap(~p, scales='free', nrow=1))

ggsave(plot=gp, width=297, height=202, units='mm',
       file.path(dir, paste0('posteriors_site_',kit,'kit.png')))


############################################################### Species

data <- as.data.frame(out$sims.list[grepl('phi.sp', names(out$sims.list))])

png(file=paste0(dir,'/species_params_',kit,'kit.png'), he=1000, wi=1000); pairs(data); dev.off()
dev.off()

data <- melt(data, id=NULL)
l2 <- strsplit(levels(data$variable), "\\.")
l2<- data.frame(l=levels(data$variable), 
                p=sapply(l2, function(x) x[[1]]), 
                q=sapply(l2, function(x) x[[2]]))
data <- merge(data, l2, by.x='variable', by.y='l')

(gp <- ggplot(data) + geom_freqpoly(aes(x=value, y=..density.., col=q), bins=50) + 
  xlab(paste0('Parameter estimate')) + ylab('Posterior density') + theme_bw() +
  facet_wrap(~p, scales='free', nrow=2))

ggsave(plot=gp, width=297, height=202, units='mm',
       file.path(dir, paste0('posteriors_speces_',kit,'kit.png')))

############################################################### Unidimensional

# now all the other parameters
j <- sapply(out$sims.list, function(x) is.null(dim(x)))
data <- melt(as.data.frame(out$sims.list[j]), id=NULL)

# detection submodel
detmodpars <- rbind(subset(data, grepl('mu.d', variable)),
                    subset(data, grepl('tau.lp', variable)),
                    subset(data, 'alpha.t.p'== variable))
(gp <- ggplot(detmodpars) + geom_freqpoly(aes(x=value, y=..density..), bins=50) + 
  xlab(paste0('Parameter estimate')) + ylab('Posterior density') + theme_bw() +
  facet_wrap(~variable, scales='free'))
ggsave(plot=gp, width=297, height=202, units='mm',
       file.path(dir, paste0('posteriors_detmod_',kit,'kit.png')))

#rump (the ones not done elsewhere)
rump <- subset(data, 
          !variable %in% unique(detmodpars$variable) & 
          !grepl("phi.sp",data$variable) &
          !grepl("\\.site",data$variable))
(gp <- ggplot(rump) + geom_freqpoly(aes(x=value, y=..density..), bins=50) + 
  xlab(paste0('Parameter estimate')) + ylab('Posterior density') + theme_bw() +
  facet_wrap(~variable, scales='free'))
ggsave(plot=gp, width=297, height=202, units='mm',
       file.path(dir, paste0('posteriors_other_',kit,'kit.png')))


# species traits part
#sppars <- rbind(subset(data, grepl('delta', variable)),
#               subset(data, variable == 'tau.eta.sp'))
#(gp <- ggplot(sppars) + geom_freqpoly(aes(x=value, y=..density..), bins=50) + 
#  xlab(paste0('Parameter estimate')) + ylab('Posterior density') + theme_bw() +
#  facet_wrap(~variable, scales='free'))
#ggsave(plot=gp, width=297, height=202, units='mm',
#       file.path(dir, paste0('posteriors_spmod_',kit,'kit.png')))

###############################################################

#plot(as.data.frame(out$sims.list[c('mu.alpha.phi.sp', 'alpha.site.0')]))
#pairs(as.data.frame(out$sims.list[c('mu.alpha.phi.sp', 'alpha.site.0')]))




