###### RXAPP Analisis  ######

setwd("~/Inputs")

# Load library
library(dplyr)
library(reshape2)
library(lubridate)

filelog <- list.files(path=getwd(), pattern="RXAPP")[1]

# Read the printout
RXAPP <- read.fwf(filelog, widths = c(15, 5, 9, 18, 5, 3))

# Rename Columns
colnames(RXAPP) <- c("DEV", "DCP", "APUSAGE", "APSTATE", "DATA", "TEI")

RXAPP <- RXAPP[, c(-2, -3, -4, -6)]

#Remove all blank spaces
RXAPP$DEV <- gsub(" ", "", RXAPP$DEV)
RXAPP$DATA <- gsub(" ", "", RXAPP$DATA)

# Set Columns types
RXAPP$DEV <- as.character(RXAPP$DEV)
RXAPP$DATA <- as.character(RXAPP$DATA)

#Remove unnecessary rows
RXAPP <- RXAPP[grep("RXOTG-.|RBLT.", RXAPP$DEV),]

#Remove NAs
RXAPP[is.na(RXAPP)] <- 0

# Insert Port Coluns
RXAPP <- mutate(RXAPP, TG = DEV)

# Correct TG Colunm
for(i in seq(along=RXAPP$TG)) {
  ifelse(grepl("^RBLT",RXAPP$TG[i]),  RXAPP$TG[i] <- RXAPP$TG[i-1], "")
}
rm(i)

# Remove unnecessary rows
RXAPP <- RXAPP[grep("RBLT.", RXAPP$DEV),]
DEV <- RXAPP %>% group_by(TG) %>% summarize(DEV = length(DEV))
RXAPP <- RXAPP %>% group_by(TG, DATA) %>% summarize(PDCH = length(DEV))

RXAPP <- filter(RXAPP, DATA == "YES")
RXAPP <- RXAPP[, -2]

RXAPP <- merge(RXAPP, DEV, by = "TG")
rm(DEV)

RXAPP <- transmute(RXAPP, TG, E1 = ceiling(DEV/31), PDCH = PDCH)

###### RXOTRX Analisis  ######

filelog <- list.files(path=getwd(), pattern="RXOTRX")[1]

# Read the printout
RXOTRX <- read.fwf(filelog, widths = c(18, 10))

# Rename Columns
colnames(RXOTRX) <- c("TRX", "CELL")

#Remove all blank spaces
RXOTRX$TRX <- gsub(" ", "", RXOTRX$TRX)
RXOTRX$CELL <- gsub(" ", "", RXOTRX$CELL)

#Remove unnecessary rows
RXOTRX <- RXOTRX[grep("RXOTRX.", RXOTRX$TRX),]

# Set Columns types
RXOTRX$TRX <- as.character(RXOTRX$TRX)
RXOTRX$CELL <- as.character(RXOTRX$CELL)

RXMOP <- data.frame(RXOTRX[2],colsplit(RXOTRX$TRX, "-" , names = c("MO","TG", "TRX")))
RXMOP <- transmute(RXMOP, SITEID = substr(CELL, 1, 6), TG = paste("RXOTG", TG, sep = "-"))
RXMOP <- unique(RXMOP)

RXOTRX <- transmute(RXOTRX, SITEID = substr(CELL, 1, 6), TRX = TRX, CELL = CELL)

CELL <- RXOTRX[, -2]
CELL <- unique(CELL)

CELL <- CELL %>% group_by(SITEID) %>% summarise( CELL = length(CELL))

RXOTRX <- RXOTRX %>% group_by(SITEID) %>% summarize(TRX = length(TRX))

###### RLBDP Analisis  ######

filelog <- list.files(path=getwd(), pattern="RLBDP")[1]

# Read the printout
CELLID <- read.fwf(filelog, widths = c(5))
CELLID$ID <- row.names(CELLID)
CELLID <- CELLID[grep("CELL", CELLID$V1),]
CELLID <- CELLID[-1,]
CELLID <- as.numeric(CELLID$ID)
CELLID <- c(CELLID, CELLID[length(CELLID)] + 15)

RLBDP <- data.frame()

for (i in seq_along(CELLID)) {
  
  x <- read.fwf(filelog,
                widths = c(7, 11, 16, 17, 9, 7),
                col.names = c("CHGR", "NUMREQBPC", "NUMREQEGPRSBPC", "NUMREQCS3CS4BPC", "TN7BCCH", "EACPREF"),
                colClasses = c(rep("character",6)),
                nrow = 1,
                skip = CELLID[i]
                )
  RLBDP <- rbind(RLBDP, x)
  
  y <- CELLID[i] + 3
  
  while(y < CELLID[i+1]-1) {
    x <- read.fwf(filelog,
                  widths = c(7, 11, 16, 17, 9, 7),
                  col.names = c("CHGR", "NUMREQBPC", "NUMREQEGPRSBPC", "NUMREQCS3CS4BPC", "TN7BCCH", "EACPREF"),
                  colClasses = c(rep("character",6)),
                  nrow = 1,
                  skip = y
                  )
    RLBDP <- rbind(RLBDP, x)
    y <- y + 6
    }
}

rm(CELLID, x, y, i)

#Remove all blank spaces
RLBDP$CHGR <- gsub(" ", "", RLBDP$CHGR)
RLBDP$NUMREQBPC <- gsub(" ", "", RLBDP$NUMREQBPC)
RLBDP$NUMREQEGPRSBPC <- gsub(" ", "", RLBDP$NUMREQEGPRSBPC)
RLBDP$NUMREQCS3CS4BPC <- gsub(" ", "", RLBDP$NUMREQCS3CS4BPC)
RLBDP$TN7BCCH <- gsub(" ", "", RLBDP$TN7BCCH)
RLBDP$EACPREF <- gsub(" ", "", RLBDP$EACPREF)

RLBDP <- mutate(RLBDP, Lenght = nchar(CHGR))

for (i in seq_along(RLBDP$CHGR)){
  ifelse(RLBDP$Lenght[i] != 7, RLBDP$CHGR[i] <- RLBDP$CHGR[i-1], RLBDP$CHGR[i] <- RLBDP$CHGR[i])
}

rm(i)

RLBDP <- RLBDP[!is.na(RLBDP$NUMREQEGPRSBPC), ]
RLBDP <- transmute(RLBDP, SITEID = substr(CHGR, 1, 6), NUMREQEGPRSBPC = as.numeric(NUMREQEGPRSBPC))

RLBDP <- RLBDP %>% group_by(SITEID) %>% summarise(NUMREQEGPRSBPC = sum(NUMREQEGPRSBPC))

###### STS Analisis  ######

filelog <- list.files(path=getwd(), pattern="STS")[1]

data <- read.csv(filelog, stringsAsFactors = FALSE, col.names = c("time", "BSC_Site", "DATA", "TCH"))

data$time <- ymd_hm(data$time, tz = "America/Sao_Paulo")

data$DATA <- gsub(",", ".", data$DATA)
data$TCH <- gsub(",", ".", data$TCH)
data$DATA <- as.numeric(data$DATA)
data$TCH <- as.numeric(data$TCH)

hourmax <- data %>% group_by(time) %>% summarise(TCH = sum(TCH), DATA = sum(DATA))

tchhourmax <- hourmax[hourmax$TCH == max(hourmax$TCH),]$time
datahourmax <- hourmax[hourmax$DATA == max(hourmax$DATA),]$time

DATA <- data[data$time == datahourmax, ][, c(2, 3)]
TCH <- data[data$time == tchhourmax, ][, c(2, 4)]

data <- merge(TCH, DATA, by = "BSC_Site")

data <- transmute(data, SITEID = substr(BSC_Site, 1, 6), TCH = TCH, DATA = DATA)

data <- data %>% group_by(SITEID) %>% summarise(TCH = sum(TCH), DATA = sum(DATA))

rm(DATA, TCH, hourmax, tchhourmax, datahourmax)

###### Merger Analisis  ######

RXAPP <- merge(RXAPP, RXMOP, by = "TG")
RXAPP <- RXAPP %>% group_by(SITEID) %>% summarise(E1 = sum(E1),
                                                  PDCH = sum(PDCH),
                                                  TG = length(TG))
rm(RXMOP)

FINAL <- merge(RXAPP, CELL, by = "SITEID")
rm(RXAPP, CELL)
FINAL <- merge(FINAL, data, by = "SITEID")
rm(data)
FINAL <- merge(FINAL, RLBDP, by = "SITEID")
rm(RLBDP)
FINAL <- merge(FINAL, RXOTRX, by = "SITEID")
rm(RXOTRX)

FINAL <- FINAL[, c("SITEID", "TG", "CELL", 'PDCH',"NUMREQEGPRSBPC", "TRX", "E1", "TCH", "DATA")]
colnames(FINAL) <- c("SITEID", "TG", "CELL", 'PDCH',"EPDCH", "TRX", "E1", "Erl", "Mpbs")

#--------------------------------------------------------------------------#
#                                                                          #
# Write File in Excel                                                      #
#                                                                          #
#--------------------------------------------------------------------------#

# Load Library
library(XLConnect)
options(java.home="C:\\Program Files\\Java\\jre1.8.0_91")

#Write to a Excel File
fileXls <- paste(getwd(), "/", strsplit(filelog, " ")[[1]][1], ".xlsx",sep="")
unlink(fileXls, recursive = FALSE, force = FALSE)
exc <- loadWorkbook(fileXls, create = TRUE)

createSheet(exc,'Site_Information')

writeWorksheet(exc, FINAL, sheet = "Site_Information", startRow = 2, startCol = 2)

saveWorkbook(exc)

rm(FINAL, exc, fileXls, filelog)

