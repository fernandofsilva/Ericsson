#Report VIVO

library(data.table)
library(XLConnect)
options(java.home="C:\\Program Files\\Java\\jre1.8.0_91")

data <- read.csv("Inputs/one.csv", stringsAsFactors = FALSE,
                 col.names = c("time", "BSC", "CP", "TCH", "GSL"))

data <- data.table(data)

data <- data[, .(BSC,
                 CP = gsub(",", ".", CP),
                 TCH = gsub(",", ".", TCH),
                 GSL = gsub(",", ".", GSL)
                 )]

data[, c("CP", "TCH", "GSL") := lapply(.SD, as.integer), .SDcols = c("CP", "TCH", "GSL")]

data <- data[, lapply(.SD, max), by=BSC, .SDcols = c("CP","TCH", "GSL")]

exc <- loadWorkbook("Inputs/Report_Vivo.xlsx", create = TRUE)
createSheet(exc,'Information')
writeWorksheet(exc, data, sheet = "Information", startRow = 2, startCol = 2)
saveWorkbook(exc)

rm(exc, data)