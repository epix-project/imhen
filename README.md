
<!-- README.md is generated from README.Rmd. Please edit that file -->

# imhen

<!-- badges: start -->

[![AppVeyor build
status](https://ci.appveyor.com/api/projects/status/github/epix-project/imhen?branch=master&svg=true)](https://ci.appveyor.com/project/epix-project/imhen)
<!-- badges: end -->

|                                                               |                                                                                                                                                                                                                                                                                                                                                                                         |
| ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <img src="vignettes/imhen.png" alt="" style="width: 100px;"/> | This package contains meteorological data for Vietnam from the Vietnamese Institute of Meteorology, Hydrology and Environment ([IMHEN](http://vnclimate.vn/en/about/imhen/)). This is monthly data in 67 climatic stations from January 1960 to December 2015. Climatic variables are min, max, average temperatures, absolute and relative humidities, rainfall and hours of sunshine. |

## Installation and loading

You can install `imhen` from [GitHub](https://github.com/choisy/imhen)

``` r
# install.packages("devtools")
devtools::install_github("choisy/imhen", build_vignettes = TRUE)
```

Once installed, you can load the package:

``` r
library(imhen)
```

## Usage examples

The package contains two dataframes. The first one is `meteo` which
contains the climatic variables `Tx`, `Ta`, `Tm`, `aH`, `rH`, `Rf` and
`Sh` plus time (`year` and `month`) and space (`station`) information:

``` r
head(meteo)
#>   year    month station   Ta   Tx   Tm    Rf   aH rH Sh
#> 1 1961  January Bac Kan 13.9 19.1 10.5   5.3 13.1 82 NA
#> 2 1961 February Bac Kan 15.1 18.3 13.2  21.5 14.7 85 NA
#> 3 1961    March Bac Kan 19.6 23.2 17.5  85.4 20.1 87 NA
#> 4 1961    April Bac Kan 23.5 28.1 20.5 185.8 24.8 87 NA
#> 5 1961      May Bac Kan 25.8 31.2 22.1  34.9 27.1 83 NA
#> 6 1961     June Bac Kan 26.9 32.6 23.1 314.7 29.3 83 NA
```

Note that the data frame is not “complete”, with some combinations of
the `year`, `month` and `station` being missing:

``` r
table(with(meteo, table(year, month, station)))
#> 
#>     0     1 
#>  7980 37848
```

The second one is `stations` which contains the coordinates (`longitude`
and `latitude`) and the `elevation`:

``` r
head(stations)
#>     station elevation  latitude             geometry
#> 1   Bac Kan       174 22.133333  105.81667, 22.13333
#> 2 Bac Giang         7 21.283333  106.20000, 21.28333
#> 3  Bac Lieu         2  9.283333 105.716667, 9.283333
#> 4  Bac Ninh         5 21.200000        106.05, 21.20
#> 5    Ba Tri        12 10.033333  106.60000, 10.03333
#> 6     Ba Vi        20 21.083333  106.40000, 21.08333
```

### Mapping the climatic stations

We can transform the climatic stations coordinates into a spatial
object:

``` r
library(gadmVN)
vietnam <- gadm(level = "country")
coordinates(stations) <- ~ longitude + latitude
proj4string(stations) <- vietnam@proj4string
```

And plot the stations on the map:

``` r
plot(vietnam, col = "grey")
points(stations, col = "blue", pch = 3)
```

### Visualizing the climatic stations elevations

We can also look at the elevations of the climatic stations:

``` r
plot(sort(stations$elevation, TRUE), type = "o",
     xlab = "stations ranked by decreasing elevation", ylab = "elevation (m)")
```

<img src="man/figures/README-unnamed-chunk-9-1.png" width="100%" />

### Exploring the climatic variables

Let’s look at the temperatures:

``` r
val <- c("Tm", "Ta", "Tx")
T_range <- range(meteo[, val], na.rm = TRUE)
breaks <- seq(floor(T_range[1]), ceiling(T_range[2]), 2)
par(mfrow = c(1, 3))
for(i in val)
  hist(meteo[[i]], breaks, ann = FALSE, col = "lightgrey", ylim = c(0, 10500))
```

<img src="man/figures/README-unnamed-chunk-10-1.png" width="100%" />

Looks good. Let’s check the consistency of the values:

``` r
for(i in val) print(range(meteo[[i]], na.rm = TRUE))
#> [1] -9.256667 29.900000
#> [1]  0.0 35.8
#> [1]  5.7 39.3
with(meteo, any(!((Tm <= Ta) & (Ta <= Tx)), na.rm = TRUE))
#> [1] FALSE
```

Let’s look at the other variables:

``` r
val <- c("aH", "rH", "Rf", "Sh")
par(mfrow = c(2, 2))
for(i in val) hist(meteo[[i]], col = "lightgrey", ann = FALSE)
```

<img src="man/figures/README-unnamed-chunk-12-1.png" width="100%" />

Looks good too.

``` r
for(i in val) print(range(meteo[[i]], na.rm = TRUE))
#> [1]  2.9 39.9
#> [1]  49 100
#> [1]    0.0 2451.7
#> [1]   0 674
```

### Visualizing the data spatio-temporally

Let’s first Make a `year`, `month`, `station` template for a full design
of the data:

``` r
y <- sort(unique(meteo$year))
m <- factor(levels(meteo$month), levels(meteo$month), ordered = TRUE)
s <- stations$station[order(coordinates(stations)[, "latitude"])]
s <- factor(s, s, ordered = TRUE)
template <- setNames(expand.grid(y, m, s), c("year", "month", "station"))
attr(template, "out.attrs") <- NULL  # removing useless attributes
```

The full version of the data:

``` r
meteo_full <- merge(template, meteo, all.x = TRUE)
```

Let’s visualize it:

``` r
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
```

Missings values for all the temperature variables:

``` r
opar <- par(mfrow = c(2, 2))
for(i in c("Tx", "Ta", "Tm")) show_data(i)
par(opar)
```

Showing very well the higher seasonality in the north than in the south.
Missing values for the absolute and relative humidities as well as for
rainfall and hours of sunshine:

``` r
opar <- par(mfrow = c(2, 2))
for(i in c("aH", "rH", "Rf", "Sh")) show_data(i)
par(opar)
```

Showing strong seasonality of absolute humidity in the north of the
country, interesting pattern of relative humidity in the center of the
country, high rainfalls in the fall in the center of the country, and
out-of-phase oscillations of the number of hours of sunshine between the
north and the south of the country. It seems though that there are
strange outliers in sunshine in the north in 2008 or so. Let’s now
combine the missing values from all the climatic variables:

``` r
library(magrittr)
library(dplyr)
meteo_full %<>% mutate(combined = is.na(Tx + Ta + Tm + aH + rH + Rf + Sh))
show_data("combined")
abline(v = as.Date("1995-01-01"))
```

The locations of the 6 stations with missing value in the recent year
are:

``` r
subset(meteo_full, year > 1994 & combined, station, TRUE) %>% unique
```

## Left to do

  - pairwise distances
  - time series (trends seasonalities)
  - time seasonal variation
  - PCA?
