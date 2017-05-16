#Loading Packages
library(data.table)

#Loading STS from the files in the Input file directory
filelog <- list.files(path="/Users/esssfff/Documents/Inputs/", pattern="^B", 
                      full.names = TRUE)

STS = do.call(rbind, lapply(filelog, fread))

rm(filelog)

#Loading the site list
sites <- fread("/Users/esssfff/Documents/Inputs/ListaSites.csv", 
                  stringsAsFactors = FALSE, header = TRUE, 
                  col.names = c("BSC", "SITEID"))

#Setting Column names
setnames(STS, c("time", "CELL_BSC", "DATA", "TCH")) 

#Replacing , by .
STS[, c(3:4) := lapply(.SD, function(x){
  gsub(pattern = ",", replacement = ".", x = x)
}), .SDcols = c(3:4)]

# Converting columns type
STS[, c(3:4) := lapply(.SD, as.numeric), .SDcols = c(3:4)]

############################## Handling Databases ##############################

# STS handling
STS[, c("CELL", "BSC") := tstrsplit(CELL_BSC, "_")]
STS[, SITEID := substr(CELL, 1, 6)]

#Subseting table according sites list
setkey(STS, BSC, SITEID)
setkey(sites, BSC, SITEID)

STS <- STS[.(sites), nomatch = NA]

rm(sites)

SITESUMMARY <- STS[, lapply(.SD, sum), by= c("time", "BSC", "SITEID"), .SDcols = c("TCH", "DATA")]

MAXTCH <- SITESUMMARY[, lapply(.SD, max), by= c("BSC", "SITEID"), .SDcols = c("TCH")]
MAXDATA <- SITESUMMARY[, lapply(.SD, max), by= c("BSC", "SITEID"), .SDcols = c("DATA")]

setkey(MAXTCH, SITEID, TCH)
setkey(MAXDATA, SITEID, DATA)
setkey(SITESUMMARY, SITEID, TCH)

tchhourmax <- SITESUMMARY[ .(MAXTCH), nomatch = NA]

setkey(SITESUMMARY, SITEID, DATA)
datahourmax <- SITESUMMARY[ .(MAXDATA), nomatch = NA]

tchhourmax[, c("TCH", "DATA", "i.BSC") := NULL]
datahourmax[, c("TCH", "DATA", "i.BSC") := NULL]

setkey(tchhourmax, time, BSC, SITEID)
setkey(datahourmax, time, BSC, SITEID)
setkey(STS, time, BSC, SITEID)

TCH <- STS[ .(tchhourmax), nomatch = NA]
TCH[, c("time", "CELL_BSC","DATA") := NULL]
DATA <- STS[ .(datahourmax), nomatch = NA]
DATA[, c("time", "CELL_BSC","TCH") := NULL]

setkey(TCH, BSC, SITEID, CELL)
setkey(DATA, BSC, SITEID, CELL)

STS <- TCH[.(DATA), nomatch = NA]

rm(tchhourmax, datahourmax, MAXDATA, MAXTCH, DATA, TCH, SITESUMMARY)

setcolorder(STS, c("BSC", "SITEID", "CELL", "TCH", "DATA"))

write.csv(x = STS, file = "/Users/esssfff/Documents/Inputs/Traffic_per_site.csv", row.names = FALSE)

rm(STS)
