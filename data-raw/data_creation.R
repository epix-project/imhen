# Reads 1 given sheet of 1 given file:
read_meteo1 <- function(file,sheet) {
  nb_months <- 12 # number of months
  nb_skip <- 4 # number of rows to skip in the excel files
  data <- readxl::read_excel(file,sheet,skip=nb_skip) # reads a sheet of a file
  data <- data[!is.na(data[,1]),] # because sometimes reads more rows than necessary
  year <- rep(data[,1],nb_months) # the year variable
  data <- data[,-c(1,nb_months+2)] # removing year and year average (first and last columns)
  month <- rep(names(data),each=nrow(data)) # the month variable
  setNames(data.frame(year,month,unlist(data),stringsAsFactors=F),
           c("year","month",paste(sheet))) # adding the sheet number as the name of the data column
}

# Reads 1 given file:
read_meteo2 <- function(file) {
  nb_sheets <- 7 # number of sheets per file
  out <- lapply(1:nb_sheets,function(x)read_meteo1(file,x)) # reads all the sheets of the file
  out <- Reduce(function(x,y)merge(x,y,all=T),out) # merging the sheets per year and month
  out$station <- sub(".xls","",file) # adding the station variable
  out
}

# Reading all the meteorological data from excel files:
files <- grep(".xls",dir(),value=T) # the list of excel files
meteo <- lapply(files,read_meteo2) # reading all the files
meteo <- do.call(rbind,meteo) # stacking all the files

# Putting in shape:
hash <- setNames(month.name,c("I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII"))
meteo$month <- hash[meteo$month] # rename months
names(meteo)[3:9] <- c("Ta","Tx","Tm","Rf","rH","Sh","aH") # rename variables
meteo$year <- as.integer(meteo$year) # year as integer
meteo$month <- factor(meteo$month,month.name) # month as factor
meteo$station <- factor(meteo$station) # station as factor
meteo <- meteo[with(meteo,order(station,year,month)),] # order rows
# reorder columns:
meteo <- meteo[,c("year","month","station","Tx","Ta","Tm","aH","rH","Rf","Sh")]
# ordering the months:
meteo$month <- as.ordered(meteo$month)

# Cleaning the data:
meteo[which(meteo$Tx>50),"Tx"] <- meteo[which(meteo$Tx>50),"Tx"]/10
meteo[which(meteo$Ta>50),"Ta"] <- meteo[which(meteo$Ta>50),"Ta"]/10
meteo[which(meteo$Tm>50),"Tm"] <- meteo[which(meteo$Tm>50),"Tm"]/10
sel <- with(meteo,which(!((Tm <= Ta) & (Ta <= Tx))))
val <- c("Tm","Ta","Tx")
for(i in sel) meteo[i,val] <- sort(meteo[i,val])

# Climatic stations:
stations <- read.table("stations.txt",T)

# Saving to disk:
devtools::use_data(meteo,stations,overwrite=T)
