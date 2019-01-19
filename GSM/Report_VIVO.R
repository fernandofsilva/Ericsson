#Report VIVO

library(data.table)

data <- read.csv("/home/esssfff/Documents/Inputs/one.csv", 
        stringsAsFactors = FALSE, 
        col.names = c("time", "BSC", "CP", "TCH", "GSL"))

data <- data.table(data)

data <- data[, .(BSC,
                 CP = gsub(",", ".", CP),
                 TCH = gsub(",", ".", TCH),
                 GSL = gsub(",", ".", GSL)
                 )]

data[, c("CP", "TCH", "GSL") := lapply(.SD, as.integer), .SDcols = c("CP", "TCH", "GSL")]

data <- data[, lapply(.SD, max), by=BSC, .SDcols = c("CP","TCH", "GSL")]

# Load Library
library(openxlsx)

#Write to a Excel File
fileXls <- "/home/esssfff/Documents/Inputs/Report_Vivo.xlsx"

wb <- createWorkbook()
addWorksheet(wb,'Information')

writeData(wb, data, sheet = "Information", startRow = 2, startCol = 2)

saveWorkbook(wb, fileXls, overwrite = TRUE)