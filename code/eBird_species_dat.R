# eBird_species_dat.R: Get the unique species and append family names then load into the SQL database ----

# 1. Load packages ----
library(taxize)
library(RPostgreSQL)

# 2. Get species list and append family ---- 

# set up connection
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname="ebird_us_data", host="localhost", port="5432", user="postgres", password="password123.")

species <- dbGetQuery(con, "SELECT DISTINCT species FROM ebird_checklist_species;")
species <- gsub("_", " ", species$species)
fam <- lapply(species, function(x) try(tax_name(query = x, get = "family", verbose = FALSE)))
fam_class <- sapply(fam, class)
fam_complete <- fam[which(fam_class == "data.frame")]
fam_complete <- lapply(fam_complete, function(x) {
  colnames(x) = c("db", "query", "family")
  return(x)
})
fam_complete <- do.call("rbind", fam_complete)
fam_complete <- merge(data.frame(species = species), fam_complete, by.x="species", by.y = "query", all.x = TRUE)
fam_complete <- apply(fam_complete, 2, as.character)
write.csv(fam_complete, file = "data/species_family_lookup.csv")
# NB taxize did not find all families - have manually updated the field for 319 species

species <- read.csv("data/species_family_lookup.csv", stringsAsFactors = FALSE) # read in the edited file
species <- subset(species, select = c(species, family))
species$species <- gsub(" ", "_", species$species)
# input species info table into the database
dbGetQuery(con, "CREATE TABLE ebird_species_info (
           species varchar(50) PRIMARY KEY,
           family varchar(50)
) ") 

dbWriteTable(con, "ebird_species_info", value = species, append = TRUE, row.names = FALSE) 

dbDisconnect(con)
