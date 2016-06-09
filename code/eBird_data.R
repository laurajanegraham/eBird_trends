# eBird_data.R: Create dataset for occupancy modelling from eBird data ----

# 1. Load packages ----
library(RPostgreSQL)
library(dplyr)
library(readr)
library(tidyr)

# 2. Create tables in eBird_data SQL database ----
# set up connection
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname="ebird_data", host="localhost", port="5432", user="postgres", password="password123.")

# drop old versions
dbGetQuery(con, "DROP TABLE ebird_checklist_species")
dbGetQuery(con, "DROP TABLE ebird_checklist_info")

create_checklist_info <- "CREATE TABLE ebird_checklist_info (
                                  SAMPLING_EVENT_ID varchar(50) PRIMARY KEY,
                                  LATITUDE numeric,
                                  LONGITUDE numeric,
                                  YEAR int,
                                  MONTH int,
                                  DAY int,
                                  TIME numeric,
                                  COUNTRY varchar(50),
                                  STATE_PROVINCE varchar(50),
                                  COUNT_TYPE varchar(50),
                                  EFFORT_HRS numeric,
                                  EFFORT_DISTANCE_KM numeric,
                                  EFFORT_AREA_HA numeric,
                                  OBSERVER_ID varchar(50),
                                  NUMBER_OBSERVERS int,
                                  GROUP_ID varchar(50),
                                  PRIMARY_CHECKLIST_FLAG int,
                                  ASTER2011_DEM numeric,
                                  UMD2011_LANDCOVER numeric,
                                  UMD2011_FS_L_1500_LPI numeric,
                                  UMD2011_FS_L_1500_PD numeric,
                                  UMD2011_FS_L_1500_ED numeric,
                                  UMD2011_FS_C0_1500_PLAND numeric,
                                  UMD2011_FS_C0_1500_LPI numeric,
                                  UMD2011_FS_C0_1500_PD numeric,
                                  UMD2011_FS_C0_1500_ED numeric,
                                  UMD2011_FS_C1_1500_PLAND numeric,
                                  UMD2011_FS_C1_1500_LPI numeric,
                                  UMD2011_FS_C1_1500_PD numeric,
                                  UMD2011_FS_C1_1500_ED numeric,
                                  UMD2011_FS_C2_1500_PLAND numeric,
                                  UMD2011_FS_C2_1500_LPI numeric,
                                  UMD2011_FS_C2_1500_PD numeric,
                                  UMD2011_FS_C2_1500_ED numeric,
                                  UMD2011_FS_C3_1500_PLAND numeric,
                                  UMD2011_FS_C3_1500_LPI numeric,
                                  UMD2011_FS_C3_1500_PD numeric,
                                  UMD2011_FS_C3_1500_ED numeric,
                                  UMD2011_FS_C4_1500_PLAND numeric,
                                  UMD2011_FS_C4_1500_LPI numeric,
                                  UMD2011_FS_C4_1500_PD numeric,
                                  UMD2011_FS_C4_1500_ED numeric,
                                  UMD2011_FS_C5_1500_PLAND numeric,
                                  UMD2011_FS_C5_1500_LPI numeric,
                                  UMD2011_FS_C5_1500_PD numeric,
                                  UMD2011_FS_C5_1500_ED numeric,
                                  UMD2011_FS_C6_1500_PLAND numeric,
                                  UMD2011_FS_C6_1500_LPI numeric,
                                  UMD2011_FS_C6_1500_PD numeric,
                                  UMD2011_FS_C6_1500_ED numeric,
                                  UMD2011_FS_C7_1500_PLAND numeric,
                                  UMD2011_FS_C7_1500_LPI numeric,
                                  UMD2011_FS_C7_1500_PD numeric,
                                  UMD2011_FS_C7_1500_ED numeric,
                                  UMD2011_FS_C8_1500_PLAND numeric,
                                  UMD2011_FS_C8_1500_LPI numeric,
                                  UMD2011_FS_C8_1500_PD numeric,
                                  UMD2011_FS_C8_1500_ED numeric,
                                  UMD2011_FS_C9_1500_PLAND numeric,
                                  UMD2011_FS_C9_1500_LPI numeric,
                                  UMD2011_FS_C9_1500_PD numeric,
                                  UMD2011_FS_C9_1500_ED numeric,
                                  UMD2011_FS_C10_1500_PLAND numeric,
                                  UMD2011_FS_C10_1500_LPI numeric,
                                  UMD2011_FS_C10_1500_PD numeric,
                                  UMD2011_FS_C10_1500_ED numeric,
                                  UMD2011_FS_C12_1500_PLAND numeric,
                                  UMD2011_FS_C12_1500_LPI numeric,
                                  UMD2011_FS_C12_1500_PD numeric,
                                  UMD2011_FS_C12_1500_ED numeric,
                                  UMD2011_FS_C13_1500_PLAND numeric,
                                  UMD2011_FS_C13_1500_LPI numeric,
                                  UMD2011_FS_C13_1500_PD numeric,
                                  UMD2011_FS_C13_1500_ED numeric,
                                  UMD2011_FS_C16_1500_PLAND numeric,
                                  UMD2011_FS_C16_1500_LPI numeric,
                                  UMD2011_FS_C16_1500_PD numeric,
                                  UMD2011_FS_C16_1500_ED numeric
                              );"

create_checklist_species <- "CREATE TABLE ebird_checklist_species (
                                  SAMPLING_EVENT_ID varchar(50) REFERENCES eBird_checklist_info (SAMPLING_EVENT_ID),
                                  SPECIES varchar(57),
                                  PRES int
                              );"

dbGetQuery(con, create_checklist_info)
dbGetQuery(con, create_checklist_species)

# 3. Manipuate data and insert into SQL database ----
folders <- list.dirs("data/erd_western_hemisphere_data_grouped_by_year_v5.0/", full.names=TRUE)

# go though all folders and read data into SQL table
lapply(folders, function(fdr) {
  if(file.exists(paste(fdr, "checklists.csv", sep="/"))) {
    f <- paste(fdr, "checklists.csv", sep="/")
    cf <- paste(fdr, "extended-covariates.csv", sep="/")
    dat <- read_csv(f, n_max = 100, na = c("", "NA", "?"))
    covs <- read_csv(cf, n_max=100, na = c("", "NA", "-9999", "-9999.0000")) 
    sp_pres <- select(dat, 1, 18:ncol(dat)) # species presences will be separate table 
    sp_pres[-1] <- apply(sp_pres[-1], 2, function(x) ifelse(x==0, 0, 1))
    sp_pres <- as.data.frame(gather(sp_pres, species, pres, -SAMPLING_EVENT_ID))
    dat <- select(dat, 1:17) %>% merge(covs)
    
    dbWriteTable(con, "ebird_checklist_info", dat, append = TRUE, overwrite = FALSE, row.names = FALSE)
    dbWriteTable(con, "ebird_checklist_species", sp_pres, append = TRUE, overwrite = FALSE, row.names = FALSE)
    }
  }
  )


dbDisconnect(con)

