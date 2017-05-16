#Set JAVA_HOME for XLConnect
options(java.home="C:\\Program Files\\Java\\jre1.8.0_91")

# Setting Home Directory
setwd("~/Inputs")

# Load library
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(reshape2))
suppressPackageStartupMessages(library(XLConnect))

# Read the printout
filelog <- list.files(path=getwd(), pattern=".log")[1]
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

# Sheet Site Information
Site_Information <- mutate(RXOTRX, ID = substr(CELL, 1, 6), NAME = paste("RJ", substr(CELL, 2, 6), sep = ""))[,3:4]
Site_Information <- arrange(Site_Information, NAME)
Site_Information <- Site_Information[!duplicated(Site_Information),]

# Sheet PSTU Parameters
PSTU_Parameters <- data.frame(RXOTRX[2],colsplit(RXOTRX$TRX, "-" , names = c("MO","TG", "TRX")))
PSTU_Parameters <- transmute(PSTU_Parameters, SITEID = substr(CELL, 1, 6), PSTU_Name = paste(substr(CELL, 1, 6), TG, sep = "_"))
PSTU_Parameters <- arrange(PSTU_Parameters, SITEID)
PSTU_Parameters <- PSTU_Parameters[!duplicated(PSTU_Parameters$PSTU_Name),]

# Sheet SCGR Parameters
SCGR_Parameters <- data.frame(RXOTRX[2],colsplit(RXOTRX$TRX, "-" , names = c("MO","TG", "TRX")))
SCGR_Parameters <- transmute(SCGR_Parameters, 
                             PSTU_Name = paste(substr(CELL, 1, 6), TG, sep = "_"),
                             SCGR = TG,
                             MODE = "IPM",
                             MBWDL = 4096,
                             MBWUL = 4096,
                             JBSUL = 20,
                             LDEL = 1,
                             IPOV = "OFF"
                               )
SCGR_Parameters <- SCGR_Parameters[!duplicated(SCGR_Parameters$PSTU_Name),]

# Sheet SC Parameters
SC_Parameters <- colsplit(RXOTRX$TRX, "-" , names = c("MO","TG", "TRX"))[,2]
SC_Parameters <- SC_Parameters[!duplicated(SC_Parameters)]
SC <- rep(c(0,1), length(SC_Parameters))
DCP <- rep(c(1,33), length(SC_Parameters))
SCGR <- sort(c(SC_Parameters, SC_Parameters))
SC_Parameters <- as.data.frame(cbind(SCGR, SC, DCP)); rm(SCGR, DCP, SC)
SC_Parameters <- mutate(SC_Parameters, DEV1 = "", NUMDEV = 31)
SC_Parameters <- select(SC_Parameters, SCGR, SC, DEV1, DCP, NUMDEV)

# Sheet TRXes Associations
SC <- as.data.frame(colsplit(RXOTRX$TRX, "-" , names = c("MO","TG", "TRX")))
TRXes_Associations <- cbind(RXOTRX, SC); rm(SC)
TRXes_Associations <- TRXes_Associations[,c(1,5)]
colnames(TRXes_Associations) <- c("MO","SC")
TRXes_Associations$SC[TRXes_Associations$SC <= 5] = 0
TRXes_Associations$SC[TRXes_Associations$SC >= 6] = 1

# Sheet TG Parameters
TG_Parameters <- data.frame(colsplit(RXOTRX$TRX, "-" , names = c("MO","TG1", "TRX")))
TG_Parameters <- TG_Parameters[!duplicated(TG_Parameters$TG1),]
TG_Parameters <- transmute(TG_Parameters, 
                        TG = paste("RXOTG", TG1, sep = "-"),
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
LAPD_Parameters <- data.frame(colsplit(RXOTRX$TRX, "-" , names = c("MO","TG1", "TRX")))
LAPD_Parameters <- LAPD_Parameters[!duplicated(LAPD_Parameters$TG1),]
LAPD_Parameters <- transmute(LAPD_Parameters, 
                        TG = paste("RXOTG", TG1, sep = "-"),
                        DCP = "350-581")


# Sheet Cell Parameters
Cell_Parameters <- mutate(RXOTRX, ATHABIS = "ON", DAMRCRABIS = "ON")[,2:4]
Cell_Parameters <- arrange(Cell_Parameters, CELL)
Cell_Parameters <- Cell_Parameters[!duplicated(Cell_Parameters$CELL),]

# Sheet Physical Connectivity
Physical_Connectivity <- data.frame(RXOTRX[2],colsplit(RXOTRX$TRX, "-" , names = c("MO","TG", "TRX")))
Physical_Connectivity <- transmute(Physical_Connectivity, SITEID = substr(CELL, 1, 6), TG = TG)
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

rm(RXOTRX)

#Write to a Excel File
filelog <- paste(substr(filelog, 1, 7),".xlsx", sep = "")
fileXls <- paste(getwd(), filelog, sep='/')
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

rm(filelog, exc, fileXls, Cell_Parameters, LAPD_Parameters, Physical_Connectivity, PSTU_Parameters,SC_Parameters, SCGR_Parameters, Site_Information, TG_Parameters, TRXes_Associations)