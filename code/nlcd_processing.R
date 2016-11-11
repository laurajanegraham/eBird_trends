library(raster)
library(tidyr)
library(ggplot2)
library(cowplot)

# load in NLCD data
#nlcd <- raster("data/NLCD/nlcd_2011_landcover_2011_edition_2014_10_10.img")
lc <- raster("data/NLCD/lc_reclassify.img") # file post-ArcMap processing
lc_2006 <- raster("data/NLCD/lc_reclassify_2006.img")
# load lookup to coarser categories and reclassify
# categories loosly based on Gardner and Urban 2007 Landscape Ecol. 
# NB I ended up doing this in ArcMap due to not working here. 
#nlcd_lookup <- read.csv("data/NLCD/nlcd_lookup.csv")
#lc_out <- subs(nlcd, nlcd_lookup, by='nlcd', which='lc')

# Code calculates percent cover of each land cover type: 
# http://gis.stackexchange.com/questions/141546/re-sample-raster-to-acre-grid-using-arcgis-desktop-or-r
# Will need to go back in and calculate aggregate land cover indices. 
aggPctCover <- function(val, r, fact) {
  aggregate(r, fact=fact, fun=function(x, na.rm=T) {mean(x == val, na.rm=na.rm)})
}

lc_perc <- stack(sapply(0:4, FUN=aggPctCover, r=lc, fact=floor(sqrt(2500))))
names(lc_perc) <- paste0('lc_', 0:4)

lc_perc_2006 <- stack(sapply(0:4, FUN=aggPctCover, r=lc_2006, fact=floor(sqrt(2500))))
names(lc_perc_2006) <- paste0('lc_', 0:4)

writeRaster(lc_perc, "data/NLCD/lc_perc_2011.tif", bylayer=TRUE)
writeRaster(lc_perc_2006, "data/NLCD/lc_perc_2006.tif", bylayer=TRUE)

files_2006 <- list.files("data/NLCD/", pattern="lc_perc_2006", full.names=TRUE)
files_2011 <- list.files("data/NLCD/", pattern="lc_perc_2011", full.names=TRUE)

lc_perc_2006 <- stack(files_2006)
lc_perc_2011 <- stack(files_2011)

lc_perc_diff <- lc_perc_2011 - lc_perc_2006

lc_perc_diff_df <- as.data.frame(lc_perc_diff[[-c(1,3)]])
names(lc_perc_diff_df) <- c("% Forest", "% Agricultural and Grassland", "% Urban")
lc_perc_diff_long <- gather(lc_perc_diff_df)

ggplot(lc_perc_diff_long, aes(x = value)) + geom_histogram() + facet_wrap(~key)
