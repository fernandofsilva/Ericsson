# Loading libraries
library(ggplot2)
library(data.table)

# Loading database
sts <- fread(file = "/Users/esssfff/Documents/Inputs/one.csv")

sts[, c("SubNetwork", "SubNetworkB", "MeContext", "SUPERCH") 
    := tstrsplit(object, ",")]
sts[, c("MeContext1", "BSC") := tstrsplit(MeContext, "=")]
sts[, c("SUPERCH1", "SCGR_SC") := tstrsplit(SUPERCH, "=")]
sts[, c("object", "SubNetwork", "SubNetworkB", "MeContext", "SUPERCH", 
        "MeContext1", "SUPERCH1") := NULL]

BSC <- unique(sts$BSC)

file.log <- list.files(path = "/Users/esssfff/Documents/Inputs/", 
                       pattern = BSC, full.names = TRUE)

rm(file.log, BSC)

pt <- read.fwf(file = file.log, widths = c(6, 4, 15, 15, 8, 5, 7, 6), 
                     skip = 5, col.names = c("SCGR", "SC", "DEV", "DEV1", 
                                             "NUMDEV", "DCP", "STATE", 
                                             "REASON"))
pt <- data.table(pt)

pt <- pt[-grep(pattern = "SCGR", x = pt$SCGR),]
pt <- pt[!is.na(pt$STATE),]

pt <- pt[, lapply(.SD, function(x) {gsub(pattern = " ", 
                                         replacement = "", x = x)})]

for(i in seq(pt$SCGR)) {
  ifelse(pt$SCGR[i] ==  "", 
         pt$SCGR[i] <- pt$SCGR[i-1], 
         pt$SCGR[i] <- pt$SCGR[i])
}
rm(i)

pt <- pt[, .(SCGR_SC = paste(SCGR, "-", SC, sep = ""), 
       NUMDEV)]



