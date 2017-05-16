#Read from SQL

library(RODBC)

#Connect to SQL moView Claro db
odbcChannel <- odbcDriverConnect('driver={SQL Server};server=146.250.136.12;database=moView_Claro;Uid=mv_claro;Pwd=claro')

#Connect to SQL moView Vivo db
odbcChannel <- odbcDriverConnect('driver={SQL Server};server=146.250.136.110;database=moView_Vivo;Uid=mv_vivo;Pwd=vivo')

#Connect to SQL moView Tim db
odbcChannel <- odbcDriverConnect('driver={SQL Server};server=146.250.136.14;database=moView_TIM;Uid=mv_tim;Pwd=tim')


#Fetch the RXAPP complete RXAPP Table
RXMOP <- sqlFetch(odbcChannel, "dbo.RXMOP")

#List all columns of the dbo.RXAPP Table
sqlColumns(odbcChannel, "dbo.RXAPP")

#Query for RXAPP just to the BSCRJ25
x <- sqlQuery(odbcChannel, paste("SELECT nodeLabel, TG, DEV, DCP FROM dbo.RXAPP", "WHERE nodeLabel = 'BSCRJ25'  ORDER BY TG"))
x <- x[!duplicated(x), ]
x <- x[complete.cases(x),]

BSC <- c("BAJU02", "BBHE01", "BBHE03", "BBHE04", "BBHE06", "BBHE07", "BBHE08", "BBHE09", "BBHE10", "BBHE11", "BCEM01", "BITB01", "BITB02", "BITB03", "BJFA01", "BJFA02", "BMCL01", "BMCL02", "BMCL03", "BSDR01", "BSDR02", "BSDR03", "BSDR04", "BSDR05", "BSDR06", "BSDR07", "BULA01", "BULA02", "BULA03", "BVGA01", "BVGA02", "BFSA01", "BFSA02", "BFSA03")

data <- data.frame()

for (i in seq_along(BSC)) {
        
        x <- sqlQuery(odbcChannel, paste("SELECT nodeLabel, TG, TRX, CELL FROM dbo.RXMOP", " WHERE nodeLabel = '", BSC[i], "' AND MOTY = 'RXOTRX' ORDER BY TG", sep = ""))
        x <- x[!duplicated(x), ]
        
        data <- rbind(data, x)
        
        }

write.csv(x, "Inputs/SITES.csv", row.names = FALSE)

#Close channel
odbcClose(odbcChannel)

rm(odbcChannel)

#Query for RXAPP just to the one BSC
#RXOTG <- sqlQuery(odbcChannel, paste("SELECT TG, RSITE FROM dbo.RXMOP", " WHERE nodeLabel = '", BSC, "' AND MOTY = 'RXOTG' ORDER BY TG", sep = ""))
#RXOTG <- RXOTG[!duplicated(RXOTG), ]

