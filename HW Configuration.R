
library(data.table)

file.RPSRPBSPOS <- list.files(path="/Users/esssfff/Documents/Inputs/", 
                              pattern="RPSRPBSPOS", full.names = TRUE)[1]

file.RPS501BOARDS <- list.files(path="/Users/esssfff/Documents/Inputs/",
                                pattern="RPS501BOARDS", full.names = TRUE)[1]

file.EXEMP <- list.files(path="/Users/esssfff/Documents/Inputs/", 
                         pattern="EXEMP", full.names = TRUE)[1]

bsc.id <- substr(file.RPSRPBSPOS, 33, 38)

################################## read exemp ##################################

exemp <- data.table(read.fwf(file = file.EXEMP,
                  widths = c(6, 7, 4, 26, 6, 7, 7, 6),
                  col.names = c("RP", "TYPE", "EM", "EQM",
                                "TWIN", "CNTRL", "PP", "STATE"),
                  colClasses = c(rep("character", 4), rep("NULL", 4)),
                  skip = 4,
                  row.names = NULL))

exemp <- exemp[, lapply(.SD, function(x)
  {gsub(pattern = " ", replacement = "", x)})
  ]
exemp <- exemp[complete.cases(exemp)]
exemp <- exemp[ EM == "0"]

exemp <- exemp[, lapply(.SD, function(x)
{gsub(pattern = "RGSERV", replacement = "GPH", x)})
]

exemp <- exemp[, lapply(.SD, function(x)
{gsub(pattern = "RHLAPD", replacement = "TRH", x)})
]

exemp <- exemp[, lapply(.SD, function(x)
{gsub(pattern = "RTTG1S", replacement = "TRA", x)})
]

exemp[, c("TYPE", "EM") := NULL]

exemp[, c(1) := lapply(.SD, as.numeric), .SDcols = c(1)]

setnames(exemp, c("RP", "EQM"), c("RPADDR", "FUNCTION"))

rm(file.EXEMP)

############################### read RPSRPBSPOS ################################

pos <- data.table(read.fwf(file = file.RPSRPBSPOS,
                             widths = c(11, 5, 6, 7, 6, 8, 3),
                             col.names = c("RPADDR", "BRNO", "MAGNO", "SLOTNO",
                                           "INDNO", "BUSCONN", "UPD"),
                             colClasses = c(rep("character", 4), rep("NULL", 3)),
                             skip = 7,
                             row.names = NULL))

pos <- pos[, lapply(.SD, function(x){gsub(pattern = " ", replacement = "", x)})]
pos <- pos[complete.cases(pos)]

setkey(pos, BRNO, MAGNO, SLOTNO)

rm(file.RPSRPBSPOS)

############################## read RPS501BOARDS ###############################

total.lines <- length(readLines(file.RPS501BOARDS))-2

line.1 <- data.frame()

for (i in  seq(from = 7, to = total.lines, by = 7)){
  
  x <- read.fwf(file = file.RPS501BOARDS,
                widths = c(5, 6, 7, 32, 7),
                col.names = c("BRNO", "MAGNO", "SLOTNO", "PRODNO", "PRODREV"),
                colClasses = c(rep("character",5)),
                nrow = 1,
                skip = i)
  
  line.1 <- rbind(line.1, x)
  
}

line.2 <- data.frame()

for (i in  seq(from = 9, to = total.lines, by = 7)){
  
  x <- read.fwf(file = file.RPS501BOARDS,
                widths = c(34, 16, 16, 6),
                col.names = c("PRODNAM", "MANDATE", "SERNO", "MASTRP"),
                colClasses = c("character", rep("NULL", 3)),
                nrow = 1,
                skip = i)
  
  line.2 <- rbind(line.2, x)
  
}

rm(file.RPS501BOARDS)

boards <- data.table(cbind(line.1, line.2))

rm(line.1, line.2, total.lines, x, i)

boards <- boards[, lapply(.SD, function(x)
{gsub(pattern = " ", replacement = "", x)})
]

################################### cabinet ####################################

# Remove boards doesn't belong to GEM/EGEM subrack
boards <- boards[-grep(
  pattern = "FAN|DLHB|EPS|RP4|RPG3|RPG2|RPP|ETC|ET5C|TS4B|SPIB|DESCR|DLNB|\\?",
  x = PRODNAM)]

cab.mag <- boards[, .(uni = paste(BRNO, MAGNO, sep = "_"))]
cab.mag <- unique(cab.mag)

cabinet <- vector()

for (i in 1:nrow(cab.mag)) {

  x <- rep(cab.mag$uni[i], 26)
  cabinet <- c(cabinet, x)
  
}

rm(x, i, cab.mag)

cabinet <- data.table(uni = cabinet, SLOTNO = as.character(0:25))
cabinet[, c("BRNO", "MAGNO") := tstrsplit(uni, "_", fixed=TRUE)]
cabinet <- cabinet[, c(3, 4, 2)]

setkey(boards, BRNO, MAGNO, SLOTNO)
setkey(cabinet, BRNO, MAGNO, SLOTNO)

bsc <- boards[ .(cabinet), nomatch = NA]
bsc <- pos[ .(bsc), nomatch = NA]
bsc[, c(1:4) := lapply(.SD, as.numeric), .SDcols = c(1:4)]

setkey(bsc, RPADDR)
setkey(exemp, RPADDR)

bsc <- exemp[.(bsc), nomatch = NA]

setcolorder(x = bsc, neworder = c("RPADDR", "BRNO", "MAGNO", "PRODNAM",
                                  "FUNCTION", "SLOTNO", "PRODNO", "PRODREV"))

bsc <- bsc[order(BRNO, MAGNO, SLOTNO)]

rm(boards, cabinet, pos, exemp)

#--------------------------------------------------------------------------#
#                                                                          #
# Write File in Excel                                                      #
#                                                                          #
#--------------------------------------------------------------------------#

# Load Library
options(java.home="C:\\Program Files\\Java\\jre1.8.0_91")
library(XLConnect)

#Write to a Excel File
fileXls <- paste("/Users/esssfff/Documents/Inputs/", "/", bsc.id, ".xlsx",sep="")
unlink(fileXls, recursive = FALSE, force = FALSE)
exc <- loadWorkbook(fileXls, create = TRUE)

createSheet(exc,'Bayface')

writeWorksheet(exc, bsc, sheet = "Bayface", startRow = 2, startCol = 2)
setColumnWidth(exc, sheet = "Bayface", column = c(5, 7), width = 4000)

saveWorkbook(exc)

rm(bsc, bsc.id, exc, fileXls)
