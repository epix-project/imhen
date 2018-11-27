# Parameters -------------------------------------------------------------------
proj <- "+init=epsg:3405"
nbcells <- 10000
kriging_model <- value ~ latitude + elevation
weighted <- TRUE


# The packages -----------------------------------------------------------------
installed <- row.names(installed.packages())
cran <- c("automap", "devtools", "parallel", "purrr", "sf", "sp", "raster", "tidyr", "dplyr")
gh <- paste0("choisy/", c("imhen", "srtmVN", "mcutils", "sptools", "worldpopVN"))
cran2 <- setdiff(cran, installed)
gh2 <- setdiff(gh, installed)
if (length(cran2) > 0) install.packages(cran2)
if (length(gh2) > 0) devtools::install_github(gh2)
lapply(c("sf", "sp", "raster", "sptools", "mcutils", "tidyr", "dplyr"), library, character.only = TRUE)


# The data ---------------------------------------------------------------------
obj <- ls()
if (! "meteo" %in% obj) meteo <- imhen::meteo
if (! "stations" %in% obj) {
  stations <- as(imhen::stations, "Spatial")
  stations$latitude <- coordinates(stations)[, 2]
}
if (! "country" %in% obj) country <- gadm("vietnam", "sp", 0)
if (! "provinces" %in% obj) provinces <- gadm("vietnam", "sp", 1)
if (! "elevation" %in% obj) elevation <- srtmVN::getsrtm()
if (! "popdensity" %in% obj) popdensity <- worldpopVN::getpop()


# Utilitary functions ----------------------------------------------------------
make_grid <- function(plgn, rstr, var, n, ...) {
  require(magrittr) # %>%
  plgn %>%
    sptools::make_grid(n, ...) %>%
    sptools::add_from_raster(rstr, var) %>%
    sptools::add_variable_spdf(., data.frame(latitude = coordinates(.)[, 2]))
}

make_weights <- function(rstr, grid, plgns) {
  require(magrittr) # %>%
  rstr %>%
    sptools::resample_from_grid(grid) %>%
    sptools::split_on_poly(plgns) %>%
    parallel::mclapply(sptools::rescale_raster)
}

make_2arg_fct <- function(f, ...) {
  function(x, y) {
    f(x, y, ...)
  }
}

kriging <- function(points, grid, formula, proj) {
  require(magrittr) # %>%
  points %>%
    sptools::na_exclude() %>%
    sp::spTransform(proj) %>%
    automap::autoKrige(formula, ., sp::spTransform(grid, proj)) %>%
    `$`("krige_output") %>%
    slot("data") %>%
    dplyr::transmute(interpolated = var1.pred) %>%
    sptools::change_data(grid, .)
}

simple_aggregation <- function(grid, polygons, var) {
  sptools::apply_pts_by_poly(grid, polygons, var, mean, na.rm = TRUE)
}

weighted_aggregation <- function(grid, polygons, weights) {
  require(magrittr)  # %>%
  grid %>%
    sptools::grid2raster() %>%
    sptools::split_on_poly(polygons) %>%
    purrr::map2(weights, raster::overlay, fun = function(x, y) x * y) %>%
    sapply(. %>%     # this could potentially be parallelized.
             raster::values() %>%
             sum(na.rm = TRUE))
}


# Preparing --------------------------------------------------------------------
grid <- make_grid(country, elevation, "elevation", nbcells)
weights <- make_weights(popdensity, grid, provinces)
interpolation <- make_2arg_fct(kriging, kriging_model, proj)
if (weighted) {
  aggregation <- make_2arg_fct(weighted_aggregation, weights)
} else aggregation <- make_2arg_fct(simple_aggregation, "interpolated")


# Calculations -----------------------------------------------------------------
out <- meteo %>%
  filter(year > 2003) %>%
  mutate_if(is.factor, as.character) %>%
  # I. Prepare the data --------------------------------------------------------
gather(variable, value, -year, -month, -station) %>% # defining "variable" and "value"
  split(list(.$variable, .$year, .$month)) %>%
  # II. For each month and variable --------------------------------------------
parallel::mclapply(. %>%
                     merge(stations, .) %>%       # (1) spatialize data
                     interpolation(grid) %>%      # (2) spatial interpolation
                     aggregation(provinces)) %>%  # (3) spatial aggregation
  # III. Put results into shape ------------------------------------------------
data.frame() %>%
  cbind(province = provinces$VARNAME_1, .) %>%
  gather("key", "value", -province) %>%
  separate(key, c("variable", "year", "month")) %>%
  spread(variable, value) %>%
  mutate(year  = as.integer(year),
         month = factor(month, month.name, ordered = TRUE)) %>%
  arrange(year, province, month) %>%
  # IV. Post-calculation checks ------------------------------------------------
  mutate(rH = ifelse(rH > 100, 100, rH)) %>%
  mutate_at(vars(aH, rH, Rf, Sh), funs(ifelse(. < 0, 0, .)))

meteo_intagg_2008_2017 <- out %>%
  dplyr::filter(year > 2007) %>%
  dplyr::select(year, month, province, Ta, Tx, Tm, Rf, aH, rH, Sh)
