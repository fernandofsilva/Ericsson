# Classic Abis Analysis


setwd("~/Inputs")

#Load library
library(data.table)
library(RODBC)

############################## Loading databases ###############################

#Connect to SQL moView TIM db
# odbcChannel <- odbcDriverConnect('driver={SQL Server};
#                                  server=146.250.136.14;
#                                  database=moView_TIM;
#                                  Uid=mv_tim;Pwd=tim')

odbcChannel <- odbcConnect(dsn = 'MoviewTim', uid = 'mv_tim', pwd = 'tim')

#Load BSC List
BSC <- read.csv("ListaNodes.csv", colClasses = "character")
BSC <- BSC$BSC

#Load RXAPP from the BSC Lista
RXAPP <- data.frame()

#Loop over the BSC List
for(i in seq_along(BSC)) {
  
  x <- sqlQuery(odbcChannel, 
                paste("SELECT nodeLabel, TG, DEV, DCP FROM dbo.RXAPP", " WHERE nodeLabel = '", 
                      BSC[i], "' ORDER BY TG", sep = ""))
  x <- x[!duplicated(x), ]
  
  RXAPP <- rbind(RXAPP, x)
  
}

rm(i, x)

#Load RXAPP from the BSC Lista
RXMOP <- data.frame()

#Loop over the BSC List
for(i in seq_along(BSC)) {
  
  x <- sqlQuery(odbcChannel, 
                paste("SELECT nodeLabel, TG, RSITE FROM dbo.RXMOP", " WHERE nodeLabel = '", 
                      BSC[i], "' AND MOTY = 'RXOTG' ORDER BY TG", sep = ""))
  x <- x[!duplicated(x), ]
  
  RXMOP <- rbind(RXMOP, x)
  
}

rm(i, x)

rm(BSC)

#Close channel
odbcClose(odbcChannel)

rm(odbcChannel)

#Converting column types
RXAPP$nodeLabel <- as.character(RXAPP$nodeLabel)
RXAPP$DEV <- as.character(RXAPP$DEV)
RXAPP$TG <- as.integer(RXAPP$TG)
RXAPP$DCP <- as.integer(RXAPP$DCP)

RXMOP$nodeLabel <- as.character(RXMOP$nodeLabel)
RXMOP$TG <- as.integer(RXMOP$TG)
RXMOP$RSITE <- as.character(RXMOP$RSITE)

#Adding Port Column
RXAPP$PORT[RXAPP$DCP >= 1 & RXAPP$DCP <= 31] = "A"
RXAPP$PORT[RXAPP$DCP >= 33 & RXAPP$DCP <= 63] = "B"
RXAPP$PORT[RXAPP$DCP >= 287 & RXAPP$DCP <= 317] = "C"
RXAPP$PORT[RXAPP$DCP >= 319 & RXAPP$DCP <= 349] = "D"

#Function to select RBLT Range
E1 <- function(DEV = c("RBLT2-1", "RBLT2-33")){
  DEVRETURN <- vector('character')
  for(i in seq_along(DEV)){
    DEVTYPE <- as.character(sapply(strsplit(DEV[i],'-'), "[", 1))
    DEVNUMBER <- as.numeric(sapply(strsplit(DEV[i],'-'), "[", 2))
    DEVRANGE <- paste(DEVTYPE, paste((((ceiling(DEVNUMBER/32)*32)-2)-30), 
                                     ((ceiling(DEVNUMBER/32)*32)-1), sep = "&&-"), sep = "-")
    DEVRETURN <- c(DEVRETURN, DEVRANGE)
  }
  return(DEVRETURN)
}

# Adding the column E1_RANGE
RXAPP$E1_RANGE <- E1(RXAPP$DEV)

# Removing columns DEV and DCP
RXAPP <- RXAPP[,-c(3,4)]

# Removing duplicated
RXAPP <- RXAPP[!duplicated(RXAPP), ]

RXMOP$MERGE <- paste(RXMOP$nodeLabel, RXMOP$TG, sep = "_")
RXAPP$MERGE <- paste(RXAPP$nodeLabel, RXAPP$TG, sep = "_")

DB <- merge(RXMOP, RXAPP, by = "MERGE")
DB <- DB[,-c(1:3)]
colnames(DB) <- c("RSITE", "nodeLabel", "TG", "PORT", "E1_RANGE")
DB <- DB[,c(2, 1, 3, 4, 5)]

rm(RXAPP, RXMOP)

write.csv(x = DB, file = "AbisAnalysis.csv", row.names = FALSE)

rm(DB, E1)


DB <- read.csv(file = '/Users/esssfff/Documents/Inputs/AbisAnalysis.csv', 
               colClasses = c('character', 'character', 'integer', 
                              'character', 'character'))

DB1 <- data.frame()

SITES <- unique(DB$RSITE)

for(i in seq_along(SITES)){
  
  x <- DB[DB$RSITE == SITES[i],]
  y <- length(unique(x$TG))
  z <- length(unique(x$E1_RANGE))
  
  result <- ifelse(y == z, 1, 0)
  
  DB1 <- rbind(DB1, result)
  
}

