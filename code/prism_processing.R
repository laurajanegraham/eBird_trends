library(prism)
library(raster)

files_2006 <- list.files("data/NLCD/", pattern="lc_perc_2006", full.names=TRUE)
files_2011 <- list.files("data/NLCD/", pattern="lc_perc_2011", full.names=TRUE)

lc_perc_2006 <- stack(files_2006)
lc_perc_2011 <- stack(files_2011)

nlcd <- lc_perc_2006[[1]]

options(prism.path = "data/prism")

get_prism_annual(type="tmean", years=2004:2014)
get_prism_annual(type="ppt", years=2004:2014)

temp_files <- ls_prism_data(absPath=TRUE)[,2]
temp_raster <- stack(temp_files)
temp_raster_reproj <- projectRaster(temp_raster, crs=nlcd@crs)
temp_raster_extent <- crop(temp_raster_reproj, nlcd@extent)
temp_raster_res <- resample(temp_raster_extent, nlcd, method='bilinear')
covariate_dat <- stack(lc_perc_2011[[-c(1,5)]], temp_raster_res)
writeRaster(covariate_dat, filename="data/prism/covariate_dat.tif", options="INTERLEAVE=BAND", overwrite=TRUE)

test <- stack("data/prism/covariate_dat.tif")

names(test) <- c("perc_forest", "perc_agri", "perc_urban", ls_prism_data()[,1])


