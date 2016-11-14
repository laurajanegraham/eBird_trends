library(raster)

ras <- raster("../NLCD/lc_perc_2006_1.tif")
pts <- read.csv("../temp_lat_long.csv")

eBird_xy <- SpatialPointsDataFrame(cbind(pts$LONGITUDE, pts$LATITUDE), pts)
proj4string(eBird_xy) <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
eBird_xy <- spTransform(eBird_xy, ras@crs)
pts$cell <- raster::extract(ras, eBird_xy, cellnumbers = TRUE, df = TRUE)$cells 
write.csv(pts, file="../temp_lat_long.csv", row.names = FALSE)
