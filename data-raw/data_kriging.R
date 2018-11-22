library(sp)
library(gstat)  # for "variogram", "fit.variogram", "vgm"
library(automap)  # for "autofitVariogram"
library(imhen)

data(stations)
coordinates(stations) <- ~ longitude + latitude
stations@proj4string <- marc::proj0
stations <- sp::spTransform(stations, marc::projVN)  # we need to project for the kriging

ppp <- worldpopVN::getpop(2009)
grid <- raster::rasterToPoints(ppp, spatial = TRUE)  # about 1 minute.
grid <- sp::spTransform(grid, marc::projVN)  # we need to project for the kriging (about 30 secondes)
grid2 <- grid[sample(length(grid), 1000), ]  # try with a subsample of points of the grid

data(meteo)
tmp <- merge(stations, subset(meteo, year == 2015 & month == "January", -c(year, month)))

a <- autoKrige(Tx ~ elevation, tmp, grid2)

# ------------------------------------------------------------------------------

# Fitting a variogram:
Tx_vgm <- variogram(Tx ~ elevation, tmp)  # calculating sample variogram values
Tx_fit <- fit.variogram(Tx_vgm, model = vgm("Sph"))
