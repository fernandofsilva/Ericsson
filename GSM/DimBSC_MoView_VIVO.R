setwd("~/Inputs")

#Load library
library(data.table)
library(RODBC)

############################## Loading databases ###############################

#Connect to SQL moView TIM db
odbcChannel <- odbcDriverConnect('driver={SQL Server};
                                 server=146.250.136.110;
                                 database=moView_Vivo;
                                 Uid=mv_vivo;Pwd=vivo')

#Load BSC List
BSC <- read.csv("ListaNodes.csv", colClasses = "character")
BSC <- BSC$BSC


#Load RXAPP from the BSC Lista
RXAPP <- data.frame()

#Loop over the BSC List
for(i in seq_along(BSC)) {
  
  x <- sqlQuery(odbcChannel, 
                paste("SELECT * FROM dbo.RXAPP", " WHERE nodeLabel = '", 
                      BSC[i], "' ORDER BY TG", sep = ""))
  x <- x[,c(2, 12, 13, 17)]
  x[grep(pattern = "NO", x = x$`64K`),]$`64K` <- "NO"
  x <- x[!duplicated(x), ]
  
  RXAPP <- rbind(RXAPP, x)
  
}

rm(i, x)

#Setting Column names
colnames(RXAPP) <- c("BSC", "TG", "DEV", "K64")

#Converting column types
RXAPP <- data.table(RXAPP)
RXAPP[, c("BSC", "DEV", "K64") := lapply(.SD, as.character), 
      .SDcols = c("BSC", "DEV", "K64")]

#Loading RXMOP:RXOTRX from the BSC Lista
RXOTRX <- data.frame()

#Loop over the BSC List
for(i in seq_along(BSC)) {
  
  x <- sqlQuery(odbcChannel, 
                paste("SELECT nodeLabel, TG, TRX, CELL FROM dbo.RXMOP",
                      " WHERE nodeLabel = '", BSC[i], 
                      "' AND MOTY = 'RXOTRX' ORDER BY TG", sep = ""))
  x <- x[!duplicated(x), ]
  
  RXOTRX <- rbind(RXOTRX, x)
  
}

rm(i, x)

#Setting Column names
colnames(RXOTRX) <- c("BSC", "TG", "TRX", "CELL")

#Converting column types
RXOTRX <- data.table(RXOTRX)
RXOTRX[, c("BSC", "CELL") := lapply(.SD, as.character), 
      .SDcols = c("BSC", "CELL")]

#Loading RLBDP from the BSC List
RLBDP <- data.frame()

#Loop over the BSC List
for(i in seq_along(BSC)) {
  
  x <- sqlQuery(odbcChannel, 
                paste("SELECT nodeLabel, CELL, CHGR, NUMREQEGPRSBPC FROM dbo.RLBDP", 
                      " WHERE nodeLabel = '", BSC[i], "' ORDER BY CELL", sep = ""))
  x <- x[!duplicated(x), ]
  
  RLBDP <- rbind(RLBDP, x)
  
}

rm(i, x)

#Setting Column names
colnames(RLBDP) <- c("BSC", "CELL", "CHGR", "NUMREQEGPRSBPC")

#Converting column types
RLBDP <- data.table(RLBDP)
RLBDP[, c("BSC", "CELL") := lapply(.SD, as.character), 
       .SDcols = c("BSC", "CELL")]

rm(BSC)

#Close channel
odbcClose(odbcChannel)

rm(odbcChannel)

#Loading STS from the files in the WD
filelog <- list.files(path=getwd(), pattern="STS")

STS = do.call(rbind, lapply(filelog, fread))

rm(filelog)

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
STS[, SITEID := substr(CELL, 1, 5)]

STS <- STS[, lapply(.SD, sum), by= c("time", "BSC", "SITEID"), .SDcols = c("TCH", "DATA")]

BSCSUMMARY <- STS[, lapply(.SD, sum), by= c("time", "BSC"), .SDcols = c("TCH", "DATA")]
MAXTCH <- BSCSUMMARY[, lapply(.SD, max), by= c("BSC"), .SDcols = c("TCH")]
MAXDATA <- BSCSUMMARY[, lapply(.SD, max), by= c("BSC"), .SDcols = c("DATA")]

setkey(MAXTCH, TCH)
setkey(MAXDATA, DATA)
setkey(BSCSUMMARY, TCH)

tchhourmax <- BSCSUMMARY[ .(MAXTCH), nomatch = NA]

setkey(BSCSUMMARY, DATA)
datahourmax <- BSCSUMMARY[ .(MAXDATA), nomatch = NA]

tchhourmax[, c("TCH", "DATA", "i.BSC") := NULL]
datahourmax[, c("TCH", "DATA", "i.BSC") := NULL]

setkey(tchhourmax, time, BSC)
setkey(datahourmax, time, BSC)
setkey(STS, time, BSC)

TCH <- STS[ .(tchhourmax), nomatch = NA]
TCH[, c("time", "DATA") := NULL]
DATA <- STS[ .(datahourmax), nomatch = NA]
DATA[, c("time", "TCH") := NULL]

setkey(TCH, BSC, SITEID)
setkey(DATA, BSC, SITEID)

STS <- TCH[.(DATA), nomatch = NA]

rm(tchhourmax, datahourmax, MAXDATA, MAXTCH, DATA, TCH, BSCSUMMARY)

# RLBDP handling

RLBDP[, SITEID := substr(CELL, 1, 5)]
RLBDP <- RLBDP[, list(CELL = length(unique(CELL)), EPDCH = sum(NUMREQEGPRSBPC)), by = c("BSC", "SITEID")]

# RXAPP handling

RXAPP[, DATA := ifelse(K64 == "YES", 1, 0)]
RXAPP <- RXAPP[, list(DEV = length(DEV), PDCH = sum(DATA)), by = c("BSC", "TG")]

# RXOTRX handling

RXOTRX[, SITEID := substr(CELL, 1, 5)]
RXOTRX <- RXOTRX[, lapply(.SD, length), by= c("BSC", "SITEID", "TG"), .SDcols = c("TRX")]

setkey(RXAPP, BSC, TG)
setkey(RXOTRX, BSC, TG)

FINAL <- RXOTRX[.(RXAPP), nomatch = NA]
FINAL[, E1 := ceiling(DEV/31)]
FINAL <- FINAL[, list(TG = length((TG)), TRX = sum(TRX), PDCH = sum(PDCH), E1 = sum(E1)), by = c("BSC", "SITEID")]

setkey(RLBDP, BSC, SITEID)
setkey(STS, BSC, SITEID)

FINAL <- RLBDP[.(FINAL), nomatch = NA][]
FINAL <- STS[.(FINAL), nomatch = NA]

FINAL <- FINAL[complete.cases(FINAL)]

FINAL <- FINAL[order(BSC, SITEID)]

rm(RLBDP, RXAPP, RXOTRX, STS)

setcolorder(FINAL, c("BSC", "SITEID", "TG", "CELL", "PDCH", "EPDCH", "TRX", "E1", "TCH", "DATA"))

#--------------------------------------------------------------------------#
#                                                                          #
# Write File in Excel                                                      #
#                                                                          #
#--------------------------------------------------------------------------#

# Load Library
library(XLConnect)
options(java.home="C:\\Program Files\\Java\\jre1.8.0_91")

#Write to a Excel File
fileXls <- paste(getwd(), "/", "Dim_BSC_MoView", ".xlsx",sep="")
unlink(fileXls, recursive = FALSE, force = FALSE)
exc <- loadWorkbook(fileXls, create = TRUE)

createSheet(exc,'Site_Information')

writeWorksheet(exc, FINAL, sheet = "Site_Information", startRow = 2, startCol = 2)

saveWorkbook(exc)

rm(FINAL, exc, fileXls)
