###### RXAPP Analisis  ######

setwd("~/Inputs")

# Load library
library(dplyr)

filelog <- list.files(path=getwd(), pattern="RXAPP.log")[1]

# Read the printout
RXAPP <- read.fwf(filelog, widths = c(15,5))

# Rename Columns
colnames(RXAPP) <- c("DEV", "DCP")

#Remove all blank spaces
RXAPP$DEV <- gsub(" ", "", RXAPP$DEV)
RXAPP$DCP <- gsub(" ", "", RXAPP$DCP)

# Set Columns types
RXAPP$DEV <- as.character(RXAPP$DEV)
RXAPP$DCP <- as.numeric(RXAPP$DCP)

#Remove unnecessary rows
RXAPP <- RXAPP[grep("RXOTG-.|RBLT.", RXAPP$DEV),]

#Remove NAs
RXAPP[is.na(RXAPP)] <- 0

# Insert Port Coluns
RXAPP <- mutate(RXAPP, PORT = "P", TG = DEV)

# Replace DCP values according to the Port
RXAPP$PORT[RXAPP$DCP >= 1 & RXAPP$DCP <= 31] = "A"
RXAPP$PORT[RXAPP$DCP >= 33 & RXAPP$DCP <= 63] = "B"
RXAPP$PORT[RXAPP$DCP >= 287 & RXAPP$DCP <= 317] = "C"
RXAPP$PORT[RXAPP$DCP >= 319 & RXAPP$DCP <= 349] = "D"
RXAPP <- select(RXAPP, TG, DEV, DCP, PORT)

# Correct TG Colunm
for(i in seq(along=RXAPP$TG)) {
  ifelse(grepl("^RBLT",RXAPP$TG[i]),  RXAPP$TG[i] <- RXAPP$TG[i-1], "")
}
rm(i)

# Remove unnecessary rows
RXAPP <- RXAPP[grep("RBLT.", RXAPP$DEV),]

# write to a file
write.table(RXAPP, file = paste(strsplit(filelog, "[.]")[[1]][1],"_RXAPP.txt", sep = ""), sep = "," , row.names = FALSE)