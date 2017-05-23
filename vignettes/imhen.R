## ----include=F-----------------------------------------------------------
knitr::knit_hooks$set(margin = function(before,options,envir) {
if(before) par(mgp=c(1.5,0.5,0),bty="n",plt=c(.105,.97,.13,.97)) else NULL })

knitr::opts_chunk$set(margin=T,prompt=T,comment="",collapse=T,cache=F,
dev.args=list(pointsize=11),fig.height=3.5,
fig.width=4.24725,fig.retina=2,fig.align="center")

## ----eval = FALSE--------------------------------------------------------
#  # install.packages("devtools")
#  devtools::install_github("choisy/imhen", build_vignettes = TRUE)

## ------------------------------------------------------------------------
library(imhen)

## ------------------------------------------------------------------------
head(meteo)

## ------------------------------------------------------------------------
table(with(meteo, table(year, month, station)))

## ------------------------------------------------------------------------
head(stations)

## ------------------------------------------------------------------------
library(gadmVN)
vietnam <- gadm(level = "country")
coordinates(stations) <- ~ longitude + latitude
proj4string(stations) <- vietnam@proj4string

## ------------------------------------------------------------------------
plot(vietnam, col = "grey")
points(stations, col = "blue", pch = 3)

## ------------------------------------------------------------------------
plot(sort(stations$elevation, TRUE), type = "o",
     xlab = "stations ranked by decreasing elevation", ylab = "elevation (m)")

## ----fig.height = .5 * 3.5, fig.width = 1.3 * 4.24725--------------------
val <- c("Tm", "Ta", "Tx")
T_range <- range(meteo[, val], na.rm = TRUE)
breaks <- seq(floor(T_range[1]), ceiling(T_range[2]), 2)
par(mfrow = c(1, 3))
for(i in val)
  hist(meteo[[i]], breaks, ann = FALSE, col = "lightgrey", ylim = c(0, 10500))

## ------------------------------------------------------------------------
for(i in val) print(range(meteo[[i]], na.rm = TRUE))
with(meteo, any(!((Tm <= Ta) & (Ta <= Tx)), na.rm = TRUE))

## ------------------------------------------------------------------------
val <- c("aH", "rH", "Rf", "Sh")
par(mfrow = c(2, 2))
for(i in val) hist(meteo[[i]], col = "lightgrey", ann = FALSE)

## ------------------------------------------------------------------------
for(i in val) print(range(meteo[[i]], na.rm = TRUE))

## ------------------------------------------------------------------------
y <- sort(unique(meteo$year))
m <- factor(levels(meteo$month), levels(meteo$month), ordered = TRUE)
s <- stations$station[order(coordinates(stations)[, "latitude"])]
s <- factor(s, s, ordered = TRUE)
template <- setNames(expand.grid(y, m, s), c("year", "month", "station"))
attr(template, "out.attrs") <- NULL  # removing useless attributes

## ------------------------------------------------------------------------
meteo_full <- merge(template, meteo, all.x = TRUE)

## ------------------------------------------------------------------------
x <- as.Date(with(unique(meteo_full[, c("year", "month")]),
                  paste0(year, "-", as.numeric(month), "-15")))
y <- seq_along(stations)
nb <- length(y)
col <- rev(heat.colors(12))
show_data <- function(var) {
  image(x, y, t(matrix(meteo_full[[var]], nb)), col = col,
        xlab = NA, ylab = "climatic stations")
  box(bty = "o")
}

## ------------------------------------------------------------------------
opar <- par(mfrow = c(2, 2))
for(i in c("Tx", "Ta", "Tm")) show_data(i)
par(opar)

## ------------------------------------------------------------------------
opar <- par(mfrow = c(2, 2))
for(i in c("aH", "rH", "Rf", "Sh")) show_data(i)
par(opar)

## ------------------------------------------------------------------------
library(magrittr)
library(dplyr)
meteo_full %<>% mutate(combined = is.na(Tx + Ta + Tm + aH + rH + Rf + Sh))
show_data("combined")
abline(v = as.Date("1995-01-01"))

## ------------------------------------------------------------------------
subset(meteo_full, year > 1994 & combined, station, TRUE) %>% unique

