# System and Package needed
library(magrittr) # for the " %>% ", " %<>% " pipe
library(dplyr) # for "select"
library(tidyr) # for "gather"
library(purrr) #for map

# Prerequisites  ---------------------------------------------------------------

# Colnames table for translation
names_col <- matrix(c(
  "N¨m"     , "year",
  "TB"      , "Ta",
  "TX"      , "Tx",
  "Tx"      , "Tx",
  "Tm"      , "Tm",
  "R"       , "Rf",
  "U"       , "rH",
  "Sh"      , "Sh",
  "etd"     , "aH",
  "year"    , "year",
  "month"   , "month",
  "station" , "station"),
  ncol=2, byrow=T)
names_col <- setNames(names_col[, 2], names_col[, 1])

# Stations translation
stations_transl <- read.table("data-raw/stations_dictionary.txt", sep = ";",
                              stringsAsFactors = FALSE)
stations_transl <- setNames(stations_transl[, 2], stations_transl[, 1])

# Functions --------------------------------------------------------------------

# Reads 1 given sheet of 1 given file:
read_meteo1 <- function(file, sheet) {

  nb_months <- length(month.name)
  nb_skip <- 4  # number of rows to skip in the excel files
  sheet_name <- readxl::excel_sheets(file)[sheet]

  # reads a sheet of a file
  data <- readxl::read_excel(file, sheet, skip = nb_skip, na =
                               c("", "x", -999, -99.9, -9.9))
  # because sometimes reads more rows and columns than necessary
  data <- janitor::remove_empty(data, c("rows", "cols"))
  # the year variables
  names(data) %<>% gsub("N.m", "year", .)
  # removing year average written with "_" and tidy the data
  data <- select(data, -contains("year_"), -contains("X__")) %>%
    gather(month, value, -contains("year")) %>%
    rename_(.dots = setNames("value", sheet_name)) %>%
    # re-shaping
    mutate(month = as.roman(month) %>%
             as.numeric() %>%
             month.name[.] %>%
             as.factor(),
           year = as.integer(year))
}

# Reads 1 given file:
read_meteo2 <- function(file) {
  # number of sheets per file
  nb_sheets <- length(readxl::excel_sheets(file))
  # reads all the sheets of the file
  out <- lapply(seq_len(nb_sheets), function(x) read_meteo1(file, x)) %>%
    # merging the sheets per year and month
    Reduce(function(x, y) left_join(x, y, by = c("month", "year")), .)
  # Standardize name of the columns
  names(out) <- names_col[names(out)]
  # adding the station variable
  out$station <- file %>%
    strsplit("/") %>% purrr::map(3) %>% unlist() %>%
    gsub(".xls", "", .) %>%
    gsub("[[:digit:]]", "", .) %>%
    gsub("[[:punct:]]", "", .) %>%
    stations_transl[.] %>%
    as.factor()
  out
}

# Reading all the meteorological data from excel files -------------------------
# the list of excel files
files <- grep(".xls", dir("data-raw/67 tram1961-2017-Long/"), value = TRUE) %>%
  paste0("data-raw/67 tram1961-2017-Long/", .)

# reading all the files and stacking them all
meteo <- lapply(files, read_meteo2)  %>%
  do.call(rbind, .) %>%
  select(year, month, station, Ta, Tx, Tm, Rf, rH, Sh, aH) %>%
  mutate(month = factor(month, month.name, ordered=TRUE)) %>%
  arrange(station, year)

meteo_r <- meteo

# Cleaning the data:
meteo[which(meteo$Tx > 50), "Tx"] <- meteo[which(meteo$Tx > 50), "Tx"] / 10
meteo[which(meteo$Ta > 50), "Ta"] <- meteo[which(meteo$Ta > 50), "Ta"] / 10
meteo[which(meteo$Tm > 50), "Tm"] <- meteo[which(meteo$Tm > 50), "Tm"] / 10
sel <- with(meteo, which(!((Tm <= Ta) & (Ta <= Tx))))
val <- c("Tm", "Ta", "Tx")
for(i in sel) meteo[i, val] <- meteo[i, val] %<>% unlist %>% sort

# Climatic stations ------------------------------------------------------------
stations <- read.table("data-raw/stations.txt", TRUE)
stations$station %<>% as.vector %>% stations_transl[.] %>% as.factor()

# Correcting Tan Son Hoa coordinates:
stations[stations$station == "Tan Son Hoa",
         c("longitude" ,"latitude")] <- c(106.662867, 10.795879)

# Transforming the stations data frame into a SpatialPointsDataFrame:
proj0 <-
  sp::CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0")

stations <- sp::SpatialPointsDataFrame(
  dplyr::select(stations, longitude, latitude), stations, proj4string = proj0)

# Converting stations to an sf object:
stations <- sf::st_as_sf(stations)
stations[, c("longitude", "latitude")] <- NULL
units(stations$elevation) <- units::as_units("m")

# Saving to disk ---------------------------------------------------------------

devtools::use_data(meteo_r, meteo, stations, overwrite = TRUE)

# Test -------------------------------------------------------------------------

library(testthat)

# Verifying the number of the stations
expect_length(stations$station %>% unique %>% na.omit, 67)
expect_length(meteo$station %>% unique %>% na.omit, 67)

# Checking the names of the stations
expect_equal(stations$station %>% unique %in% stations_transl %>% mean(), 1)
expect_equal(meteo$station %>% unique %in% stations_transl %>% mean(), 1)

# Checking the class of each columns
testthat::expect_true(is.numeric(meteo$Ta))
testthat::expect_true(is.numeric(meteo$Tx))
testthat::expect_true(is.numeric(meteo$Tm))
testthat::expect_true(is.numeric(meteo$Rf))
testthat::expect_true(is.numeric(meteo$rH))
testthat::expect_true(is.numeric(meteo$Sh))
testthat::expect_true(is.numeric(meteo$aH))

testthat::expect_true(is.integer(meteo$year))

testthat::expect_true(is.factor(meteo$month))
testthat::expect_true(is.factor(meteo$station))


# Clearing ---------------------------------------------------------------------

rm(list = ls())
