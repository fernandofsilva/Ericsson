#Read from SQL

#Load library
library(RODBC)
library(dplyr)
library(reshape2)

#Connect to SQL moView Vivo db
odbcChannel <- odbcDriverConnect('driver={SQL Server};
                                 server=146.250.136.110;
                                 database=moView_Vivo;
                                 Uid=mv_vivo;Pwd=vivo')

NTCOP <- sqlQuery(odbcChannel, paste("SELECT nodeLabel, SNT, DEV FROM dbo.NTCOP"))

#Close channel
odbcClose(odbcChannel)

rm(odbcChannel)

NTCOP <- NTCOP[!duplicated(NTCOP),]

NTCOP <- NTCOP[-grep("RBLT|RALT", NTCOP$DEV),]
NTCOP <- data.frame(NTCOP[1:3],colsplit(NTCOP$DEV, "-" , names = c("DEV_TYPE","DEV1", "DEV2")))
NTCOP <- data.frame(NTCOP[c(1, 4, 5, 6)],colsplit(NTCOP$SNT, "-" , names = c("SNT","SNT1")))
NTCOP <- NTCOP[,c(1, 5, 2, 3, 4)]
NTCOP$DEV1 <- gsub("&&", "", NTCOP$DEV1)
NTCOP$DEV1 <- as.numeric(NTCOP$DEV1)
NTCOP$DEV2 <- as.numeric(NTCOP$DEV2)
NTCOP$RANGE <- NTCOP$DEV2 - NTCOP$DEV1

NTCOP$BOARD <- "ERROR"
NTCOP$BOARD <- ifelse(NTCOP$DEV_TYPE == "RHDEV" & NTCOP$RANGE == 255, "TRHB", NTCOP$BOARD)
NTCOP$BOARD <- ifelse(NTCOP$DEV_TYPE == "RHDEV" & NTCOP$RANGE == 31, "RPG3", NTCOP$BOARD)
NTCOP$BOARD <- ifelse(NTCOP$DEV_TYPE == "RTGPHDV" & NTCOP$RANGE == 511, "GPHB", NTCOP$BOARD)
NTCOP$BOARD <- ifelse(NTCOP$DEV_TYPE == "RTGPHDV" & NTCOP$RANGE == 31, "RPP", NTCOP$BOARD)
NTCOP$BOARD <- ifelse(NTCOP$DEV_TYPE == "RTTG1D" & NTCOP$RANGE == 511, "TRA_R7", NTCOP$BOARD)
NTCOP$BOARD <- ifelse(NTCOP$DEV_TYPE == "RTTGD" & NTCOP$RANGE == 255, "TRA_R6", NTCOP$BOARD)
NTCOP$BOARD <- ifelse(NTCOP$DEV_TYPE == "C7STH" & NTCOP$RANGE == 31, "HSL_RPP", NTCOP$BOARD)
NTCOP$BOARD <- ifelse(NTCOP$DEV_TYPE == "C7GSTAH" & NTCOP$RANGE == 127, "HSL_STEB", NTCOP$BOARD)
NTCOP$BOARD <- ifelse(NTCOP$DEV_TYPE == "C7GSTH" & NTCOP$RANGE == 127, "HSL_STEB", NTCOP$BOARD)
NTCOP$BOARD <- ifelse(NTCOP$DEV_TYPE == "RTPGD" & NTCOP$RANGE == 1023, "PGW", NTCOP$BOARD)
NTCOP$BOARD <- ifelse(NTCOP$DEV_TYPE == "C7ST2C" & NTCOP$RANGE == 3, "C7_RPG3", NTCOP$BOARD)
NTCOP$BOARD <- ifelse(NTCOP$SNT == "ETM2", "ET155", NTCOP$BOARD)
NTCOP$BOARD <- ifelse(NTCOP$SNT == "ETM4", "EVOET", NTCOP$BOARD)

FINAL <- NTCOP %>% group_by(nodeLabel, BOARD) %>% summarise(QUANT = length(BOARD))

write.csv(file = "BOARDS_VIVO.csv", x = FINAL, row.names = FALSE)

rm(NTCOP, FINAL)

#Connect to SQL moView Vivo db
odbcChannel <- odbcDriverConnect('driver={SQL Server};
                                 server=146.250.136.110;
                                 database=moView_Vivo;
                                 Uid=mv_vivo;Pwd=vivo')

RXOTRX <- sqlQuery(odbcChannel, paste("SELECT nodeLabel, TRX, CELL FROM dbo.RXMOP", " WHERE MOTY = 'RXOTRX' ORDER BY TG", sep = ""))

#Close channel
odbcClose(odbcChannel)

rm(odbcChannel)

RXOTRX <- RXOTRX[!duplicated(RXOTRX),]

# SITE <- transmute(RXOTRX, nodeLabel = nodeLabel, SITE = substr(CELL, 1, 5))
# SITE <- SITE[!duplicated(SITE),]
# SITE <- SITE %>% group_by(nodeLabel) %>% summarise(SITE = length(SITE))

RXOTRX <- RXOTRX %>% group_by(nodeLabel) %>% summarise(TRX = length(nodeLabel))

write.csv(x = RXOTRX, file = "TRX.csv", row.names = F)

rm(RXOTRX)
