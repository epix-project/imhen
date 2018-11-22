#' Meteorological Vietnamese Data
#'
#' A dataset containing the meteorological data of Vietnam collected per month
#' from 69 climatic stations, from January 1960 to December 2017. Two versions
#' exist in this package, \code{meteo_r} is the tidy version of the raw data and
#' \code{meteo} is the tidy, clean version of the raw data, with the temperatures
#' were checked and adjusted if necessary. Additionnally, aggregates of these
#' climatic variables by the province definition of the most recent period
#' (starting in 2008) are avaiable from 2008 to 2017 in \code{meteo_intagg_2008_2017}.
#'
#' The variable \code{station} is a key shared with dataset \code{\link{stations}}.
#' The variable \code{province} is a key shared with the most recent polygon
#' definitions of the provinces of Vietnam \code{gadmVN::gadm()$province}.
#'
#' @format A data frame with 37,848 rows and 10 variables:
#' \itemize{
#'   \item \code{year}: year of collection
#'   \item \code{month}: month of collection (ordered factor)
#'   \item \code{station} or \code{province}: name of the climatic station (for
#'   \code{meteo} and \code{meteo_r}) or the province (for /code {meteo_intagg_2008_2017})
#'   \item \code{Tx}: monthly average of the daily maximal temperatures
#'   (in centigrad)
#'   \item \code{Ta}: monthly average of the daily average temperatures
#'   (in centigrad)
#'   \item \code{Tm}: monthly average of the daily minimal temperatures
#'   (in centigrad)
#'   \item \code{aH}: monthly average of absolute humidity (in g/m3)
#'   \item \code{rH}: monthly average of relative humidity (in \%)
#'   \item \code{Rf}: monthly cumulative rainfall (in mm)
#'   \item \code{Sh}: monthly cumulative number of hours of sunshine
#' }
#' @source Thai P.Q. et al. (2015) Seasonality of absolute humidity explains
#' seasonality of influenza-like illness in Vietnam. \emph{Epidemics}
#' \strong{13}: 65-73.
#' \href{http://marcchoisy.free.fr/pdf/Epidemics2015.pdf}{[PDF]}
#' @seealso The \code{\link{stations}} dataset that shares the variable
#' \code{station} with \code{meteo}.
#' @examples
#' ## Extracting the meteorological data for the stations above an elevation of
#' ## 500 meters:
#' sel <- subset(stations, elevation > 500, station)
#' subset(meteo, stations$station %in% sel$statiom)
"meteo"

#' @rdname meteo
"meteo_r"

#' @rdname meteo
"meteo_intagg_2008_2017"

################################################################################

#' Location and elevation of climatic stations
#'
#' A dataset containing the coordinates and elevation of the climatic stations
#' of Vietnam.
#'
#' @format A data frame with 67 rows and 4 variables:
#' \itemize{
#'   \item \code{station}: name of the climatic station
#'   \item \code{longitude}: longitude of the climatic station (in decimal
#'   coordinates)
#'   \item \code{latitude}: latitude of the climatic station (in decimal
#'   coordinates)
#'   \item \code{elevation}: elevation of the climatic station (in m)
#' }
#' @details The variable \code{station} is a key shared with dataset
#' \code{\link{meteo}}.
#' @source Thai P.Q. et al. (2015) Seasonality of absolute humidity explains
#' seasonality of influenza-like illness in Vietnam. \emph{Epidemics}
#' \strong{13}: 65-73.
#' \href{http://marcchoisy.free.fr/pdf/Epidemics2015.pdf}{[PDF]}
#' @seealso The \code{\link{meteo}} dataset that shares the variable
#' \code{station} with \code{stations}.
#' @examples
#' ## Extracting the meteorological data for the stations above an elevation of
#' ## 500 meters:
#' sel <- subset(stations, elevation > 500, station)
#' subset(meteo, stations$station %in% sel$station)
"stations"
