# load_data.R: code to import eBird data ----
# 1. Load packages ----
library(rgdal)
library(maps)
library(ggplot2)
library(raster)
library(rgeos)
library(dplyr)
library(tidyr)
library(lubridate)
library(cowplot)
library(stringr)
library(R2jags)

# here we set whether we want all records or just breeding season
breeding = TRUE

# 2. Map of conterminous US ----
us_outline <- getData("GADM", country = "USA", level = 1)
us_outline <- subset(us_outline, !NAME_1 %in% c("Hawaii", "Alaska"))
ext <- extent(us_outline)
us_outline <- getData("GADM", country = "USA", level = 0)
us_outline <- crop(us_outline, ext)

# 3. Worldclim data ---- 
if(file.exists("data/ann_temp.R")) {
  load("data/ann_temp.R")
} else {
  ann_temp <- raster("../worldclim_data/bio_5m_bil/bio1.bil")
  ann_temp <- mask(ann_temp, us_outline)
  save(ann_temp, file="data/ann_temp.R")
}

ann_temp <- aggregate(ann_temp, 10)
cell_xy <- as.data.frame(ann_temp, xy = TRUE)
cell_xy$cell <- rownames(cell_xy)

# 4. eBird data ----
# data sources currently coming from the hb migration project 
files <- list.files("data/eBird_checklists_2008-2014", 
                    pattern = "eBird_checklists", full.names = TRUE)

eBird_dat <- lapply(files, function(f) {
  dat <- read.table(f, sep = "\t", header = TRUE)
})

eBird_dat <- do.call("rbind", eBird_dat)

eBird_xy <- SpatialPointsDataFrame(cbind(eBird_dat$LONGITUDE, eBird_dat$LATITUDE), eBird_dat)
eBird_dat$cell <- raster::extract(ann_temp, eBird_xy, cellnumbers = TRUE, df = TRUE)$cells

eBird_dat <- merge(eBird_dat, cell_xy)
eBird_dat <- mutate(eBird_dat, obs_date = ymd(as.Date(DAY, origin = paste0(YEAR, "-01-01"), value = 1)),
         mon_year = paste(year(obs_date), 
                          ifelse(nchar(month(obs_date))==1, paste0("0",month(obs_date)), month(obs_date)), 
                          sep="_"),
         month = month(obs_date))
         
eBird_dat <- if(breeding == TRUE) filter(eBird_dat, month %in% c(5,6,7,8)) # if only interested in breeding season records - need to come up with less arbitrary way of defining - species based?
if(breeding == TRUE) {
  eBird_dat$sample_session <- eBird_dat$YEAR
} else {
  eBird_dat$mon_year
}

# 5. Detection/non-detection history ----
sampling_replicates <- distinct(eBird_dat, obs_date, cell) %>%
  select(obs_date, sample_session, cell) %>% # here I can adjust the code to include sampling co-variates
  group_by(cell, sample_session) %>% 
  arrange(obs_date) %>%
  mutate(value = 1, replicate=cumsum(value))

sampling_replicates_tot <- group_by(sampling_replicates, cell, sample_session) %>%
  summarise(reps=max(replicate))

all_reps <- expand.grid(sample_session = unique(sampling_replicates$sample_session), replicate = 1:max(sampling_replicates$replicate))

sampling_replicates_wide <- merge(sampling_replicates, all_reps, all=TRUE) %>%
  select(cell, sample_session, replicate, value) %>%
  mutate(replicate = str_pad(replicate, 3, pad = "0")) %>%
  unite(rep, sample_session, replicate, sep="_") %>%
  spread(rep, value, fill=0) 

eBird_wide <- merge(eBird_dat, sampling_replicates, all=TRUE) %>%
  merge(all_reps, all=TRUE) %>%
  distinct(SCI_NAME, cell, sample_session, replicate) %>%
  select(SCI_NAME, cell, sample_session, replicate, value) %>%
  mutate(replicate = str_pad(replicate, 3, pad = "0")) %>%
  unite(rep, sample_session, replicate, sep="_") %>%
  spread(rep,value, fill=0) %>%
  merge(sampling_replicates_wide, by=c("cell"), all.y = TRUE)

eBird_wide <- eBird_wide[which(complete.cases(eBird_wide)),]

sampling_history <- eBird_wide[,3:(ncol(sampling_replicates_wide) + 1)] + 
  eBird_wide[,(ncol(sampling_replicates_wide) + 2):ncol(eBird_wide)] - 1

sampling_history[sampling_history==-1] <- NA

colnames(sampling_history) <- colnames(sampling_replicates_wide[2:ncol(sampling_replicates_wide)])
sampling_history <- data.frame(eBird_wide[1:2], sampling_history)

# 6. Split by species ----
sampling_history <- split(sampling_history, sampling_history$SCI_NAME)
rufus <- sampling_history[["Selasphorus rufus"]][-c(1,2)]

# 7. Occupancy model ----
nsite <- nrow(rufus)
nrep <- max(sampling_replicates$replicate)
nyear <- length(unique(sampling_replicates$sample_session)) # called year, but really it's sampling periods, could be a day, could be a month etc.
y <- array(NA, dim=c(nsite, nrep, nyear))

# 2D to 3D for input to jags
for(i in 1:nyear) {
  y[, , i] <- as.matrix(rufus[,(nrep*(i-1)+1):(i*nrep)])
}

# number of detections for each time period
tmp <- apply(y, c(1,3), max, na.rm=TRUE)
tmp[tmp == "-Inf"] <- NA
obs <- data.frame(year = sort(unique(eBird_dat$YEAR)), obs = apply(tmp, 2, sum, na.rm=TRUE))

dat <- list(y = y, nsite = nsite, nrep = nrep, nyear = nyear)
inits <- function() {
  z <- apply(y, c(1, 3), max, na.rm = TRUE)
  z[z == "-Inf"] <- NA
  list(z = z)
}

params <- c("psi", "phi", "gamma", "p", "n.occ", "growthr", "turnover")
ni <- 5000
nt <- 4
nb <- 1000
nc <- 3

out <- jags(dat, inits, params, "dynocc.jags", n.chains=nc, n.thin = nt, n.burnin = nb, n.iter = ni)

# 8. Plot the output of the occupancy model ----
mod_dat <- data.frame(out$BUGSoutput$summary[,c("mean", "2.5%", "97.5%")])
occ_dat <- subset(mod_dat, str_detect(rownames(mod_dat), "n.occ"))
occ_dat$year <- sort(unique(eBird_dat$YEAR))
occ_dat <- merge(occ_dat, obs)

occ_plot <- ggplot(occ_dat, aes(x = year)) + 
  geom_point(aes(y = mean, colour="Predicted")) + 
  geom_errorbar(aes(ymin=X2.5., ymax=X97.5.), width=0.1) +
  geom_point(data = obs, aes(x = year, y = obs, colour = "Observed")) +
  xlab("Year") + ylab(expression("No. cells occupied "%+-%" 95% CI")) + 
  scale_color_manual(name = "", values = c("red", "black"))
  
save_plot("occ_plot.png", occ_plot, base_width = 8)

ggplot(obs, aes(x = year, y = obs)) + 
  geom_point()


# 9. Create plots to show biases ----
eBird_summary <- group_by(eBird_dat, x, y) %>%
  summarise(nobs=n()) 

nc_america <- map_data("world", region = c("USA", "Canada", "Mexico", "Guatemala", "Belize", "El Salvador", "Honduras", "Nicaragua", "Costa Rica", "Panama")) %>%
  mutate(x = long, y = lat)

all_plot <- ggplot(NULL, aes(x, y)) +
  geom_polygon(data = nc_america, aes(group = group), fill = "lightgrey", color = "lightgrey") +
  geom_raster(data = eBird_summary, aes(fill = nobs)) +
  coord_equal() +
  scale_fill_gradient(name="Obs", low = "blue", high = "red") +
  xlab("") + ylab("") + xlim(-180, -50) + ggtitle("Five hummingbird species") +
  theme(axis.ticks=element_blank(), axis.text=element_blank(), axis.line=element_blank())

eBird_sp_summary <- group_by(eBird_dat, SCI_NAME, x, y) %>%
  summarise(nobs=n()) 

eBird_sp_summary <- split(eBird_sp_summary, eBird_sp_summary$SCI_NAME)

shps <- list.files("data/range_maps", pattern="shp")
sp_plots <- lapply(shps, function(x) {
  x <- gsub(".shp", "", x)
  species <- paste(strsplit(x,"_")[[1]][1], strsplit(x,"_")[[1]][2])
  shp <- readOGR("data/range_maps/", x)
  shp <- gUnaryUnion(shp)
  shp <- fortify(shp) %>% mutate(x = long, y = lat)
  
  dat <- eBird_sp_summary[[species]]
  
  sp_plot <- ggplot(NULL, aes(x, y)) +
    geom_polygon(data = nc_america, aes(group = group), fill = "lightgrey", color = "lightgrey") +
    geom_raster(data = dat, aes(fill = nobs)) +
    geom_polygon(data = shp, aes(group = group), fill = NA, color = "yellow") +
    coord_equal() +
    scale_fill_gradient(name="Obs", low = "blue", high = "red") +
    xlab("") + ylab("") + xlim(-180, -50) + ggtitle(species) +
    theme(axis.ticks=element_blank(), axis.text=element_blank(), axis.line=element_blank(), plot.title = element_text(face = "bold.italic"))
  return(sp_plot)
})

main_plot <- plot_grid(all_plot, sp_plots[[5]], nrow=1)
save_plot("eBird_records.png", main_plot, base_aspect_ratio = 1:3, base_width = 12)


