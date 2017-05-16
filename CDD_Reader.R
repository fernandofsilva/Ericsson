#CDD Reader

#Load Packages
options(java.home="C:\\Program Files\\Java\\jre1.8.0_91")
library(readxl)
library(XLConnect)

setwd("Inputs/")

files <- list.files(path=getwd(), pattern=".xls|.xlsx" )

data <- data.frame()

for(i in 1:length(files)){
        
        # Read BSC and Site name
        df <- read_excel(files[i], "SITE_DATA")
        colnames(df) <- 1:ncol(df)
        df <- df[df$`1` == "RSITE" | df$`1` == "BSC" |df$`1` == "TRXC" |df$`1` == "SITENAME" ,][,1:13]
        
        df1 <- df[complete.cases(df),][,-1]
        colnames(df1) <- c("TRX0", "TRX1", "TRX2", "TRX3", "TRX4", "TRX5", "TRX6", "TRX7", "TRX8", "TRX9", "TRX10", "TRX11")
        
        df2 <- as.character(df[3,2])
        
        df3 <- as.character(df[5,2])
        
        df4 <- df[df$`7` == "CARRIERS" | df$`8` == "CELL 1" ,][,7:13]
        df4 <- df4[!is.na(df4$`8`),][,-1]
        colnames(df4) <- df4[1,]
        df4 <- df4[-1,]
        
        for(j in 1:6){
                ifelse (df4[,j] != 0, df4[,j] <- paste(df2, j, sep = ""), df4[,j] <- "-")
        }
        
        df <- df1
        df$BSC <- df3
        df$SITE <- df2
        df <- cbind(df, df4)
        df$TG <- c(1, 2, 3, 4)
        df <- df[,c("BSC", "SITE", "TG", "TRX0", "TRX1", "TRX2", "TRX3", "TRX4", "TRX5", "TRX6", "TRX7", "TRX8", "TRX9", "TRX10", "TRX11", "CELL 1", "CELL 2", "CELL 3", "CELL 4", "CELL 5", "CELL 6")]
        
        data <- rbind(data, df)
        
        rm(df, df1, df2, df3, df4)
        
}

rm(files, i, j)

data$FILTER <- ""

for (i in 1:length(data$BSC)) {
        data$FILTER[i] <- sum(data[i, ][,4:15] == "-")
        
}

data <- data[data$FILTER != 12, ][ ,-22]

rm(i)

fileXls <- paste(getwd(), "CDDs.xlsx", sep='/')
exc <- loadWorkbook(fileXls, create = TRUE)
createSheet(exc,'CDD')
writeWorksheet(exc, data, sheet = "CDD", startRow = 2, startCol = 2)
saveWorkbook(exc)

rm(data, exc, fileXls)