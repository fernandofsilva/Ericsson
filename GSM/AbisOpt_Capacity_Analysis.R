# Loading libraries
library(ggplot2)
library(data.table)
library(lubridate)

# Loading database
sts <- data.table(read.csv(file = "/Users/esssfff/Documents/Inputs/one.csv",
                stringsAsFactors = FALSE))

sts[, c("SubNetwork", "SubNetworkB", "MeContext", "SUPERCH") 
    := tstrsplit(object, ",")]
sts[, c("MeContext1", "BSC") := tstrsplit(MeContext, "=")]
sts[, c("SUPERCH1", "SCGR_SC") := tstrsplit(SUPERCH, "=")]
sts[, c("object", "SubNetwork", "SubNetworkB", "MeContext", "SUPERCH", 
        "MeContext1", "SUPERCH1") := NULL]

BSC <- unique(sts$BSC)

file.log <- list.files(path = "/Users/esssfff/Documents/Inputs/", 
                       pattern = BSC, full.names = TRUE)

pt <- read.fwf(file = file.log, widths = c(6, 4, 15, 15, 8, 5, 7, 6), 
                     skip = 5, col.names = c("SCGR", "SC", "DEV", "DEV1", 
                                             "NUMDEV", "DCP", "STATE", 
                                             "REASON"))


rm(file.log, BSC)

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

setkey(sts, SCGR_SC)
setkey(pt, SCGR_SC)

db <- pt[ .(sts), nomatch = NA]

rm(sts, pt)

colnames(db) <- gsub(pattern = "SUPERCH.pm", replacement = "", x = colnames(db))
setcolorder(db, c("time", "BSC", "SCGR_SC", "NUMDEV", "AVDELDLSCBUF", 
                  "AVDELULSCBUF", "DLCSSCBUFTHR", "DLPSSCBUFTHR", "KBMAXREC", 
                  "KBMAXSENT", "KBREC", "KBSCAN", "KBSENT", "LOSTDLPACK", 
                  "LOSTULPACK", "THRDLPACK", "THRULPACK", "TOTDLPSSCFRBUF", 
                  "TOTFRDLSCBUF", "TOTFRULSCBUF", "TOTULPSSCFRBUF", 
                  "ULPSSCBUFTHR", "ULSCBUFTHR"))

db[, c(4:23) := lapply(.SD, as.numeric), .SDcols = c(4:23)]

db <- db[, .(time = ymd_hm(time, tz = "America/Sao_Paulo"),
             SCGR_SC,
             Avg_Util_DL = 100 * (8000 * KBSENT) / (KBSCAN * NUMDEV * 64000),
             Avg_Util_UL = 100 * (8000 * KBREC) / (KBSCAN * NUMDEV * 64000),
             Max_Util_DL = 100 * (8000 * KBMAXSENT) / (NUMDEV * 64000),
             Max_Util_UL = 100 * (8000 * KBMAXREC) / (NUMDEV * 64000)
             )
         ]

setwd("/Users/esssfff/Documents/Inputs/")

SCGR.SC <- unique(db$SCGR_SC)

for (i in seq_along(db$time)){
  
  x <- db[SCGR_SC == paste(SCGR.SC[i])]
  
  ggplot(x, aes(x = time)) +
    geom_line(aes(y = Avg_Util_DL, colour = "Avg_Util_DL")) +
    geom_line(aes(y = Avg_Util_UL, colour = "Avg_Util_UL")) +
    labs(title = paste(SCGR.SC[i])) +
    ylab("%") +
    xlab("Time") +
    ylim(0, 100) 
    scale_x_datetime(date_breaks = "4 hour",date_labels = "%b %e %H %M") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1))
  
  ggsave(filename=paste(SCGR.SC[i],"_Avg",".jpeg"), device = "jpeg", width = 25.4, height = 12.7, units = "cm", dpi = 100)
  
}


