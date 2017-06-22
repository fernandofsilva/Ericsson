setwd("~/Inputs")

#Load library
library(data.table)
library(RODBC)

############################## Loading databases ###############################

#Connect to SQL moView TIM db
odbcChannel <- odbcDriverConnect('driver={SQL Server};
                                 server=146.250.136.12;
                                 database=moView_Claro;
                                 Uid=mv_claro;Pwd=claro')

#Load BSC List
BSC <- read.csv("ListaNodes.csv", colClasses = "character")
BSC <- BSC$BSC


#Load RXAPP from the BSC Lista

RXOTRX <- data.frame()

#Loop over the BSC List
for(i in seq_along(BSC)) {
  
  x <- sqlQuery(odbcChannel, 
                paste("SELECT nodeLabel, TG, TRX, CELL, CHGR, SWVERACT FROM dbo.RXMOP",
                      " WHERE nodeLabel = '", BSC[i], 
                      "' AND MOTY = 'RXOTRX' ORDER BY TG", sep = ""))
  x <- x[!duplicated(x), ]
  
  RXOTRX <- rbind(RXOTRX, x)
  
}

rm(i, x)

#Close channel
odbcClose(odbcChannel)

rm(odbcChannel)

#--------------------------------------------------------------------------#
#                                                                          #
# Write File in Excel                                                      #
#                                                                          #
#--------------------------------------------------------------------------#

# Load Library
library(XLConnect)
options(java.home="C:\\Program Files\\Java\\jre1.8.0_91")

#Write to a Excel File
fileXls <- paste(getwd(), "/", "BSC_Printout", ".xlsx",sep="")
unlink(fileXls, recursive = FALSE, force = FALSE)
exc <- loadWorkbook(fileXls, create = TRUE)

createSheet(exc,'Site_Information')

writeWorksheet(exc, RXOTRX, sheet = "Site_Information", startRow = 2, startCol = 2)

saveWorkbook(exc)

rm(BSC, RXOTRX, exc, fileXls)
