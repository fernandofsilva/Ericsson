#SIU_Reader_VIVO

#Load Packages
options(java.home="C:\\Program Files\\Java\\jre1.8.0_91")
suppressPackageStartupMessages(library(gdata))
suppressPackageStartupMessages(library(XLConnect))
suppressPackageStartupMessages(library(plyr))

setwd("c:/Users/esssfff/Desktop/siu/")

files <- list.files(path=getwd(), pattern=".xls|.xlsm" )

data <- data.frame()

for(i in 1:length(files)){
        
        # Read BSC and Site name
        df1 <- read.xls(files[i],
                        sheet="6. IP Interfaces",
                        perl="C:/Perl64/bin/perl.exe", 
                        nrows = 20)
        get1 <- grep("*main$*", colnames(df1))
        get2 <- grep("*primaryIP_Address$*", colnames(df1))
        get3 <- grep("*primarySubNetMask$*", colnames(df1))
        get4 <- grep("*defaultGateway$", colnames(df1))
        
        df1 <- df1[grep("([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+)", df1[,get4]),][,c(get1, get2, get3, get4)]
         
        colnames(df1) <- c("SIU_NAME","primaryIP_Address", "primarySubNetMask", "defaultGateway")
        
        df2 <- read.xls(files[i],
                        sheet="11. VLANs",
                        perl="C:/Perl64/bin/perl.exe", 
                        nrows = 20)
        get5 <- grep("*tagValue$", colnames(df2))
        
        df2 <- df2[grep("[[:digit:]]", df2[,get5]),][,get5]
        df2 <- df2[-1]
        df2 <- t(as.data.frame(df2))
        row.names(df2) <- NULL
        
        df <- cbind(df1, df2)
        
        data <- rbind.fill(data, df)
        
        rm(df, df1, df2, get1, get2, get3, get4, get5)
        
        print(paste(Sys.time(), files[i], i))
        
}

rm(files, i)

fileXls <- paste(getwd(), "SIU.xlsx", sep='/')
exc <- loadWorkbook(fileXls, create = TRUE)
createSheet(exc,'SIU')
writeWorksheet(exc, data, sheet = "SIU", startRow = 2, startCol = 2)
saveWorkbook(exc)

rm(data, exc, fileXls)
