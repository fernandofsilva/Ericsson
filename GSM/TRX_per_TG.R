# TRX per TG

# This Code is to be used in a Packet Abis Dimensioning for operator TIM
# The input for the code is a SQL query on MoView database

#Load library
library(data.table)
library(RODBC)

############################## Loading databases ###############################

#Connect to SQL moView TIM db
odbcChannel <- odbcDriverConnect('driver={SQL Server};
                                 server=146.250.136.14;
                                 database=moView_TIM;
                                 Uid=mv_tim;Pwd=tim')

#Loading the site list
sites <- fread("/Users/esssfff/Documents/Inputs/ListaSites.csv", 
               stringsAsFactors = FALSE, header = TRUE, 
               col.names = c("BSC", "SITEID"))

#Loop over the site list selecting just the elements of the list

RXOTRX <- data.frame()

for(i in seq_along(sites$BSC)) {
  
  x <- sqlQuery(odbcChannel, 
                paste("SELECT nodeLabel, CELL , TG, TRX FROM dbo.RXMOP", 
                      " WHERE nodeLabel = '", sites[i,1], 
                      "' AND CELL LIKE '", sites[i, 2], 
                      "%' ORDER BY TG", sep = ""))
  x <- x[!duplicated(x), ]
  
  RXOTRX <- rbind(RXOTRX, x)
  
}

rm(i, x)

#Close channel
odbcClose(odbcChannel)

rm(odbcChannel)

############################## Handling Databases ##############################

RXOTRX <- data.table(RXOTRX)

CELL <- RXOTRX[, lapply(.SD, length), by= c("nodeLabel", "CELL"), .SDcols = c("TRX")]
TG <- RXOTRX[, lapply(.SD, length), by= c("nodeLabel", "CELL", "TG"), .SDcols = c("TRX")]


write.csv(x = TG,
          file = "/Users/esssfff/Documents/Inputs/TRX_per_TG.csv",
          row.names = FALSE)

write.csv(x = CELL,
          file = "/Users/esssfff/Documents/Inputs/TRX_per_CELL.csv",
          row.names = FALSE)

rm(list = ls())

