#Set JAVA_HOME for XLConnect
Sys.setenv(JAVA_HOME='C:\\Program Files (x86)\\Java\\jre7')

# Load library
suppressPackageStartupMessages(library(dplyr))

# Read the printout
RXOTRX <- read.fwf("RXOTRX.LOG", widths = c(18, 10))

# Rename Columns
colnames(RXOTRX) <- c("TRX", "CELL")

#Remove all blank spaces
RXOTRX$TRX <- gsub(" ", "", RXOTRX$TRX)
RXOTRX$CELL <- gsub(" ", "", RXOTRX$CELL)

#Remove unnecessary rows
RXOTRX <- RXOTRX[grep("RXOTRX.", RXOTRX$TRX),]

# Set Columns types
RXOTRX$TRX <- as.character(RXOTRX$TRX)
RXOTRX$CELL <- as.character(RXOTRX$CELL)

# write to a file
write.table(RXOTRX, file = "RXOTRX.txt", sep = "," , row.names = FALSE)

