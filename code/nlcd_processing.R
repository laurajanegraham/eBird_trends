library(raster)

# load in NLCD data
nlcd <- raster("data/NLCD/nlcd_2011_landcover_2011_edition_2014_10_10/nlcd_2011_landcover_2011_edition_2014_10_10/nlcd_2011_landcover_2011_edition_2014_10_10.img")

# load lookup to coarser categories and reclassify
nlcd_lookup <- read.csv("data/NLCD/nlcd_lookup.csv")
lc_out <- subs(nlcd, nlcd_lookup, by='nlcd', which='lc')

# Code calculates percent cover of each land cover type: 
# http://gis.stackexchange.com/questions/141546/re-sample-raster-to-acre-grid-using-arcgis-desktop-or-r
# Will need to go back in and calculate aggregate land cover indices. 
aggPctCover <- function(val, r, fact) {
  aggregate(r, fact=fact, fun=function(x, na.rm=T) {mean(x == val, na.rm=na.rm)})
}
lc_perc <- stack(sapply(unique(lc_out), FUN=aggPctCover, r=lc_out, fact=floor(sqrt(2500))))
names(lc_perc) <- paste0('lc_', unique(lc_out))





