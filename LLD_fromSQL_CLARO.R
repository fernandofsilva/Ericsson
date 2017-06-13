#Read from SQL

#Lista de BSCs
BSC <- c("BSCSI47")

#--------------------------------------------------------------------------#
#                                                                          #
# Read the data from SQL                                                   #
#                                                                          #
#--------------------------------------------------------------------------#

#Load library
library(RODBC)
#source("R_Codes/Auxiliary_Functions.R")

#Connect to SQL moView Claro db
odbcChannel <- odbcDriverConnect('driver={SQL Server};
                                 server=146.250.136.12;
                                 database=moView_Claro;
                                 Uid=mv_claro;Pwd=claro')

RXOTRX <- sqlQuery(odbcChannel, paste("SELECT TG, TRX, CELL FROM dbo.RXMOP", " WHERE nodeLabel = '", BSC, "' AND MOTY = 'RXOTRX' ORDER BY TG", sep = ""))
RXOTRX <- RXOTRX[!duplicated(RXOTRX), ]
RXOTRX <- RXOTRX[!RXOTRX$CELL == "ALL", ]
RXOTRX <- RXOTRX[order(RXOTRX$TG, RXOTRX$TRX),]

#Query for RXAPP just to the BSC
RXAPP <- sqlQuery(odbcChannel, paste("SELECT TG, DEV, DCP FROM dbo.RXAPP", " WHERE nodeLabel = '", BSC, "' ORDER BY TG", sep = ""))
RXAPP <- RXAPP[!duplicated(RXAPP), ]
RXAPP <- RXAPP[complete.cases(RXAPP),]
RXAPP$DEV <- as.character(RXAPP$DEV)
RXAPP <- RXAPP[order(RXAPP$TG, RXAPP$DCP),]

#Close channel
odbcClose(odbcChannel)

rm(odbcChannel)

#--------------------------------------------------------------------------#
#                                                                          #
# RXAPP Printout                                                           #
#                                                                          #
#--------------------------------------------------------------------------#

#Load Library
library(dplyr)

# Create column Port according to DCP values
RXAPP$PORT[RXAPP$DCP >= 1 & RXAPP$DCP <= 31] = "A"
RXAPP$PORT[RXAPP$DCP >= 33 & RXAPP$DCP <= 63] = "B"
RXAPP$PORT[RXAPP$DCP >= 287 & RXAPP$DCP <= 317] = "C"
RXAPP$PORT[RXAPP$DCP >= 319 & RXAPP$DCP <= 349] = "D"

# Join the columns TG and PORT
RXAPP <- mutate(RXAPP, TG_PORT = paste(TG, PORT, sep="_"))

# Summarise the RXAPP geting the first DEV of each TG to each port
FINAL <- RXAPP[!duplicated(RXAPP$TG_PORT),]

# Count the number of DEV of each port and assign to a temp variable
temp <- as.data.frame(table(RXAPP$TG_PORT))
colnames(temp) <- c("TG_PORT", "NUMDEV")

rm(RXAPP)

# Merger the two datasets and remove the temp variable
FINAL <- merge(FINAL, temp, by = "TG_PORT")
rm(temp)

# Split the Columns TG and DEV in numbers and Join in the FINAL Dataset
x <- as.character(sapply(strsplit(FINAL$DEV,'-'), "[", 1))
y <- as.numeric(sapply(strsplit(FINAL$DEV,'-'), "[", 2))
x <- as.data.frame(x)
y <- as.data.frame(y)
FINAL <- cbind(FINAL, x, y)
colnames(FINAL) <- c("TG_PORT", "TG_NUM", "DEV", "DCP", "PORT", "NUMDEV", "DEV_TYPE", "DEV_NUM")
FINAL <- select(FINAL, TG_PORT, TG_NUM, DEV, DEV_TYPE, DEV_NUM, DCP, PORT, NUMDEV)
rm(x, y)

# Find the device Range
FINAL <- mutate(FINAL, DEV_RANGE = paste(FINAL$DEV_TYPE, paste((((ceiling(FINAL$DEV_NUM/32)*32)-2)-30), ((ceiling(FINAL$DEV_NUM/32)*32)-1), sep = "&&-"), sep = "-"))
FINAL <- mutate(FINAL, DEV_INI = (((ceiling(FINAL$DEV_NUM/32)*32)-2)-30))
FINAL <- mutate(FINAL, DEV_END = ((ceiling(FINAL$DEV_NUM/32)*32)-1))
FINAL <- select(FINAL, TG_PORT, TG_NUM, DEV, DEV_TYPE, DEV_NUM, DEV_INI, DEV_END, DEV_RANGE, DCP, PORT, NUMDEV)

# Add the SC and SCGR to each TG (There is a tricky to make the loop run)
FINAL <- mutate(FINAL, SCGR = TG_NUM, SC = 0)
FINAL <- arrange(FINAL, TG_NUM, DEV_TYPE, DEV_NUM)

temp <- c(rep(999,14))
FINAL <- rbind(temp, FINAL)
FINAL <- rbind(temp, FINAL)
FINAL <- rbind(temp, FINAL)

for(i in seq(along=FINAL$TG_NUM)) {
        ifelse(FINAL$TG_NUM[i] == FINAL$TG_NUM[i-1], 
               ifelse(FINAL$TG_NUM[i-1] == FINAL$TG_NUM[i-2], 
                      FINAL$SC[i] <- 2 , 
                      FINAL$SC[i] <- 1) , 
               FINAL$SC[i] <- 0)
}
rm(i, temp)

FINAL <- FINAL[grep("RBLT.", FINAL$DEV_TYPE),]

# Add the DEv and DCP
FINAL$PORT <- gsub("A", 1, FINAL$PORT)
FINAL$PORT <- gsub("B", 33, FINAL$PORT)
FINAL$PORT <- gsub("C", 287, FINAL$PORT)
FINAL$PORT <- gsub("D", 319, FINAL$PORT)
FINAL$PORT <- as.numeric(FINAL$PORT)

FINAL <- arrange(FINAL, DEV_TYPE, DEV_NUM)
FINAL <- mutate(FINAL, DEV1 = 0)

############################################################################################################

# Two db with the DEV_RANG with TGs with NUM_DEV minor and greater than 8 and 
# E1s with more than 4 TGs
numdev.minor.8 <- FINAL[FINAL$NUMDEV < 8, ]$DEV_RANGE

tg <- as.data.frame(FINAL %>% group_by(DEV_RANGE) %>% summarise( TS = length(DEV_RANGE)))
tg4 <- tg[tg$TS > 3, ]$DEV_RANGE

numdev.minor.8 <- numdev.minor.8[!numdev.minor.8 %in% tg4]

db <- FINAL[!FINAL$DEV_RANGE %in% numdev.minor.8,]
db.1 <- FINAL[FINAL$DEV_RANGE %in% numdev.minor.8,]
rm(numdev.minor.8, tg, tg4)

# E1 has not been using 31 devices
e1 <- as.data.frame(FINAL %>% group_by(DEV_RANGE) %>% summarise( TS = sum(NUMDEV)))
e1$TS <- 31 - e1$TS
e1 <- e1[e1$TS != 0,]


for(i in seq(along=db.1$DEV)) {
        if (db.1$DEV_RANGE[i] %in% e1$DEV_RANGE & db.1$NUMDEV[i] < 8){
                temp <- 8 - db.1$NUMDEV[i]
                db.1$NUMDEV[i] <- db.1$NUMDEV[i] + temp
                e1[e1$DEV_RANGE == db.1$DEV_RANGE[i], ]$TS <- e1[e1$DEV_RANGE == db.1$DEV_RANGE[i], ]$TS - temp
                temp <- 0
        }
}
rm(temp, i, e1)

FINAL <- rbind(db, db.1)
rm(db.1, db)

# Two db with the DEV_RANG with TGs with NUM_DEV minor and greater than 8 and 
# E1s with more than 4 TGs
numdev.minor.8 <- FINAL[FINAL$NUMDEV < 8, ]$DEV_RANGE

tg <- as.data.frame(FINAL %>% group_by(DEV_RANGE) %>% summarise( TS = length(DEV_RANGE)))
tg4 <- tg[tg$TS > 3, ]$DEV_RANGE
tg3 <- tg[tg$TS == 3, ]$DEV_RANGE
tg2 <- tg[tg$TS == 2, ]$DEV_RANGE

numdev.minor.8 <- numdev.minor.8[!numdev.minor.8 %in% tg4]

db <- FINAL[!FINAL$DEV_RANGE %in% numdev.minor.8,]
db.1 <- FINAL[FINAL$DEV_RANGE %in% numdev.minor.8,]
rm(numdev.minor.8, tg, tg4)

db.tg2 <- db.1[db.1$DEV_RANGE %in% tg2, ]
db.tg3 <- db.1[db.1$DEV_RANGE %in% tg3, ]

rm(db.1, tg2, tg3)

db.tg2 <- arrange(db.tg2, DEV_INI, desc(NUMDEV))

db.tg2$NUMDEV <- rep(c(23,8), nrow(db.tg2)/2)

temp <- db.tg3[db.tg3$NUMDEV < 8, ]
temp <- as.data.frame(temp %>% group_by(DEV_RANGE) %>% summarise( NUMDEV = length((NUMDEV < 8))))
NUMDEV1 <- temp[temp$NUMDEV == 1, ]$DEV_RANGE
NUMDEV2 <- temp[temp$NUMDEV == 2, ]$DEV_RANGE
rm(temp)

db.tg3.1 <- db.tg3[db.tg3$DEV_RANGE %in% NUMDEV1, ]
db.tg3.2 <- db.tg3[db.tg3$DEV_RANGE %in% NUMDEV2, ]
rm(db.tg3, NUMDEV1, NUMDEV2)

db.tg3.1 <- arrange(db.tg3.1, DEV_INI, desc(NUMDEV))
db.tg3.1$NUMDEV <- rep(c(12,11,8), nrow(db.tg3.1)/3)

db.tg3.2 <- arrange(db.tg3.2, DEV_INI, desc(NUMDEV))
db.tg3.2$NUMDEV <- rep(c(15,8,8), nrow(db.tg3.2)/3)

FINAL <- rbind(db, db.tg2, db.tg3.1, db.tg3.2)
rm(db, db.tg2, db.tg3.1, db.tg3.2)

FINAL <- arrange(FINAL, DEV_TYPE, DEV_NUM)

############################################################################################################

temp <- c(rep(999,14))
FINAL <- rbind(temp, FINAL)
FINAL <- rbind(temp, FINAL)
FINAL <- rbind(temp, FINAL)

for(i in seq(along=FINAL$DEV)) {
        ifelse(FINAL$DEV_RANGE[i] ==  FINAL$DEV_RANGE[i-1], 
               FINAL$DEV1[i] <- (FINAL$DEV1[i-1] + FINAL$NUMDEV[i-1]), 
               FINAL$DEV1[i] <- FINAL$DEV_NUM[i])
}
rm(i)

for(i in seq(along=FINAL$DEV)) {
        ifelse(FINAL$DEV_RANGE[i] ==  FINAL$DEV_RANGE[i-1], 
               ifelse(FINAL$DEV_RANGE[i-1] == FINAL$DEV_RANGE[i-2], 
                      FINAL$DCP[i] <- (FINAL$PORT[i] + FINAL$NUMDEV[i-1] + FINAL$NUMDEV[i-2]), 
                      FINAL$DCP[i] <- (FINAL$PORT[i] + FINAL$NUMDEV[i-1])), 
               FINAL$DEV1[i] <- FINAL$DEV_NUM[i])
}
rm(i, temp)


# Formating the FINAL Dataset
FINAL <- FINAL[grep("RBLT.", FINAL$DEV_TYPE),]
FINAL <- mutate(FINAL, COMMENT = "")
FINAL$COMMENT[FINAL$NUMDEV < 8 ] = "Check"
FINAL <- arrange(FINAL, TG_NUM, SC)
FINAL$DEV1 <- paste(FINAL$DEV_TYPE, FINAL$DEV1, sep="-")

# Summarise the Output in one variable
RRSCI <- select(FINAL, SCGR, SC, DEV1, DCP, NUMDEV, COMMENT, DEV_RANGE)

rm(FINAL)

TG_TDM <- RRSCI$SCGR
TG_TDM <- TG_TDM[!duplicated(TG_TDM)]

#--------------------------------------------------------------------------#
#                                                                          #
# RXOTRX Printout                                                          #
#                                                                          #
#--------------------------------------------------------------------------#

#Load Library
library(dplyr); library(reshape2)

# Set Columns types
RXOTRX$TRX <- as.character(RXOTRX$TRX)
RXOTRX$CELL <- as.character(RXOTRX$CELL)

# Sheet Site Information Claro
Site_Information <- transmute(RXOTRX, ID = substr(CELL, 1, 6), ID_STATE = substr(CELL, 1, 1))
x <- data.frame(ID_STATE = c("1","7","2","8","3","9","P","Q","4","0","5","6"), STATE = c("SM","SM","SI","SI","MRJ","NRJ","ORJ","PRJ","MG","MG","PRSC","RS"))
Site_Information <- merge(Site_Information, x, by = "ID_STATE")
Site_Information <- transmute(Site_Information, ID = ID, NAME = paste(STATE, substr(ID, 2, 6), sep = ""))
Site_Information <- arrange(Site_Information, NAME)
Site_Information <- Site_Information[!duplicated(Site_Information),]
rm(x)


# Sheet PSTU Parameters Claro
PSTU_Parameters <- transmute(RXOTRX, SITEID = substr(CELL, 1, 6), PSTU_Name = paste(substr(CELL, 1, 6), TG, sep = "_"), TG = TG)
PSTU_Parameters <- arrange(PSTU_Parameters, SITEID)
PSTU_Parameters <- PSTU_Parameters[!duplicated(PSTU_Parameters$PSTU_Name),]
for(i in seq(along=PSTU_Parameters$PSTU_Name)) {
        ifelse(PSTU_Parameters$TG[i] %in% TG_TDM, PSTU_Parameters$PSTU_Name[i] <- "-", "")
}
rm(i)

# Sheet SCGR Parameters
SCGR_Parameters <- transmute(RXOTRX, 
                             PSTU_Name = paste(substr(CELL, 1, 6), TG, sep = "_"),
                             SCGR = TG,
                             MODE = "IPM",
                             MBWDL = 4096,
                             MBWUL = 4096,
                             JBSUL = 20,
                             LDEL = 1,
                             IPOV = "OFF")
SCGR_Parameters <- SCGR_Parameters[!duplicated(SCGR_Parameters$PSTU_Name),]
for(i in seq(along=SCGR_Parameters$PSTU_Name)) {
        if(SCGR_Parameters$SCGR[i] %in% TG_TDM){
                SCGR_Parameters$PSTU_Name[i] <- "-"
                SCGR_Parameters$MODE[i] <- "SCM"
                SCGR_Parameters$MBWDL[i] <- "-"
                SCGR_Parameters$MBWUL[i] <- "-"
                SCGR_Parameters$JBSUL[i] <- "-"
                SCGR_Parameters$LDEL[i] <- "-"
                SCGR_Parameters$IPOV[i] <- "-"
        }
}
rm(i)


# Sheet SC Parameters
# SC_Parameters <- RXOTRX$TG
# SC_Parameters <- SC_Parameters[!duplicated(SC_Parameters)]
# SC <- rep(c(0,1), length(SC_Parameters))
# DCP <- rep(c(1,33), length(SC_Parameters))
# SCGR <- sort(c(SC_Parameters, SC_Parameters))
# SC_Parameters <- as.data.frame(cbind(SCGR, SC, DCP)); rm(SCGR, DCP, SC)
# SC_Parameters <- mutate(SC_Parameters, DEV1 = "", NUMDEV = 31)
# SC_Parameters <- select(SC_Parameters, SCGR, SC, DEV1, DCP, NUMDEV)
# SC_Parameters <- SC_Parameters[!SC_Parameters$SCGR %in% TG_TDM, ]
# SC_Parameters$COMMENT <- ""
# SC_Parameters$DEV_RANGE <- ""
# SC_Parameters <- rbind(SC_Parameters, RRSCI)
# SC_Parameters <- arrange(SC_Parameters, SCGR, SC)
SC_Parameters <- RRSCI
rm(RRSCI)




# Sheet TRXes Associations
TRXes_Associations <- transmute(RXOTRX, MO = paste("RXOTRX", TG, TRX, sep = "-"), SC = TRX, TG = TG)
TRXes_Associations$SC[TRXes_Associations$SC <= 5] = 0
TRXes_Associations$SC[TRXes_Associations$SC >= 6] = 1
for(i in seq(along=TRXes_Associations$MO)) {
        ifelse(TRXes_Associations$TG[i] %in% TG_TDM, TRXes_Associations$SC[i] <- "", "")
}
rm(i)

# Sheet TG Parameters
TG_Parameters <- data.frame(TG = RXOTRX$TG)
TG_Parameters <- TG_Parameters[!duplicated(TG_Parameters),]
TG_Parameters <- data.frame(TG = TG_Parameters)
TG_Parameters <- transmute(TG_Parameters, 
                           TG = paste("RXOTG", TG, sep = "-"),
                           TMODE = "SCM",
                           JBSUL = 20,
                           JBPTA = 20,
                           PAL = 1,
                           PTA = 7,
                           PACKALG = 1,
                           SIGDEL = "NORMAL", 
                           SDAMRREDABISTHR = 70,
                           SDFRMAABISTHR = 85,
                           SDHRAABISTHR = 80,
                           SDHRMAABISTHR = 60)

# Sheet LAPD Parameters
LAPD_Parameters <- data.frame(TG = RXOTRX$TG)
LAPD_Parameters <- LAPD_Parameters[!duplicated(LAPD_Parameters),]
LAPD_Parameters <- data.frame(TG = LAPD_Parameters)
LAPD_Parameters <- transmute(LAPD_Parameters, 
                             TG = paste("RXOTG", TG, sep = "-"),
                             DCP = "350-581")


# Sheet Cell Parameters
Cell_Parameters <- transmute(RXOTRX, CELL = CELL, ATHABIS = "ON", DAMRCRABIS = "ON")
Cell_Parameters <- arrange(Cell_Parameters, CELL)
Cell_Parameters <- Cell_Parameters[!duplicated(Cell_Parameters$CELL),]

# Sheet Physical Connectivity
Physical_Connectivity <- transmute(RXOTRX, SITEID = substr(CELL, 1, 6), TG = TG)
Physical_Connectivity <- arrange(Physical_Connectivity, SITEID)
Physical_Connectivity <- Physical_Connectivity[!duplicated(Physical_Connectivity$TG),]
Physical_Connectivity <- mutate(Physical_Connectivity, TGPORT = "A,B")
Physical_Connectivity$SIU_E1T1 <- unlist(with(Physical_Connectivity, tapply(TG, SITEID, function(x) rank(x,ties.method = "first"))))
Physical_Connectivity$SIU_E1T1[Physical_Connectivity$SIU_E1T1 == 1] = "0-1"
Physical_Connectivity$SIU_E1T1[Physical_Connectivity$SIU_E1T1 == 2] = "2-3"
Physical_Connectivity$SIU_E1T1[Physical_Connectivity$SIU_E1T1 == 3] = "4-5"
Physical_Connectivity$SIU_E1T1[Physical_Connectivity$SIU_E1T1 == 4] = "6-7"
Physical_Connectivity$SIU_E1T1[Physical_Connectivity$SIU_E1T1 == 5] = "8-9"
Physical_Connectivity$SIU_E1T1[Physical_Connectivity$SIU_E1T1 == 6] = "10-11"
Physical_Connectivity$SIU_E1T1[Physical_Connectivity$SIU_E1T1 == 7] = "12-13"
Physical_Connectivity$SIU_E1T1[Physical_Connectivity$SIU_E1T1 == 8] = "14-15"
Physical_Connectivity <- Physical_Connectivity[!Physical_Connectivity$TG %in% TG_TDM, ]

rm(RXOTRX, TG_TDM)


#--------------------------------------------------------------------------#
#                                                                          #
# Write File in Excel                                                      #
#                                                                          #
#--------------------------------------------------------------------------#

# Load Library
setwd("~/Inputs")
library(XLConnect)
options(java.home="C:\\Program Files\\Java\\jre1.8.0_91")

#Write to a Excel File
fileXls <- paste(getwd(), "/", BSC, ".xlsx",sep="")
unlink(fileXls, recursive = FALSE, force = FALSE)
exc <- loadWorkbook(fileXls, create = TRUE)

createSheet(exc,'Site_Information')
createSheet(exc,'PSTU_Parameters')
createSheet(exc,'SCGR_Parameters')
createSheet(exc,'SC_Parameters')
createSheet(exc,'TRXes_Associations')
createSheet(exc,'TG_Parameters')
createSheet(exc,'LAPD_Parameters')
createSheet(exc,'Cell_Parameters')
createSheet(exc,'Physical_Connectivity')

writeWorksheet(exc, Site_Information, sheet = "Site_Information", startRow = 2, startCol = 2)
writeWorksheet(exc, PSTU_Parameters, sheet = "PSTU_Parameters", startRow = 2, startCol = 2)
writeWorksheet(exc, SCGR_Parameters, sheet = "SCGR_Parameters", startRow = 2, startCol = 2)
writeWorksheet(exc, SC_Parameters, sheet = "SC_Parameters", startRow = 2, startCol = 2)
writeWorksheet(exc, TRXes_Associations, sheet = "TRXes_Associations", startRow = 2, startCol = 2)
writeWorksheet(exc, TG_Parameters, sheet = "TG_Parameters", startRow = 2, startCol = 2)
writeWorksheet(exc, LAPD_Parameters, sheet = "LAPD_Parameters", startRow = 2, startCol = 2)
writeWorksheet(exc, Cell_Parameters, sheet = "Cell_Parameters", startRow = 2, startCol = 2)
writeWorksheet(exc, Physical_Connectivity, sheet = "Physical_Connectivity", startRow = 2, startCol = 2)

saveWorkbook(exc)

rm(BSC, exc, fileXls, Cell_Parameters, LAPD_Parameters, Physical_Connectivity, PSTU_Parameters,SC_Parameters, SCGR_Parameters, Site_Information, TG_Parameters, TRXes_Associations)