library(rgdal)
library(rgeos)
library(raster)

setwd("C:/Users/lg1u16/HUMMINGBIRDS/eBird_trends/")

files <- list.files(path = "data/range_maps/Birdlife_polygons/Birdlife_polygons/", pattern = ".dbf")
files <- gsub(".dbf", "", files)

birds <- read.csv("eastern_forest_birds.csv")
birds <- birds$Scientific.Name

for(f in files) {
  shp <- readOGR("data/range_maps/Birdlife_polygons/Birdlife_polygons", f)
  shp <- subset(shp, SCINAME %in% birds)
  shp <- subset(shp, SEASONAL %in% c(1, 2))
  writeOGR(shp, "data/range_maps/Birdlife_polygons/Birdlife_polygons", paste0(f, "_subset"), driver = "ESRI Shapefile")
}

