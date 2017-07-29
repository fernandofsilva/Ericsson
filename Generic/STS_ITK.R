library(data.table)
library(XLConnect)
options(java.home="C:\\Program Files\\Java\\jre1.8.0_91")

BSC <- list.files(path = "Inputs/", full.names = TRUE)

data <- data.frame()

for(i in seq_along(BSC)){
  x <- read.csv(BSC[i], stringsAsFactors = FALSE,
           col.names = c("time", "BSC_Site", "DATA", "TCH"))
  
  data <- rbind(data, x)
}

rm(x, i, BSC)

data <- data.table(data)

data <- data[, .(BSC_Site,
                 DATA = gsub(",", ".", DATA),
                 TCH = gsub(",", ".", TCH)
)]

data[, c("CELL", "BSC") := tstrsplit(BSC_Site, "_")]

data[, c("DATA", "TCH") := lapply(.SD, as.numeric), .SDcols = c("DATA", "TCH")]
data <- data[, lapply(.SD, max), by=c("BSC", "CELL"), .SDcols = c("DATA","TCH")]

exc <- loadWorkbook("Inputs/STS_ITK.xlsx", create = TRUE)
createSheet(exc,'Information')
writeWorksheet(exc, data, sheet = "Information", startRow = 2, startCol = 2)
saveWorkbook(exc)

rm(exc, data)