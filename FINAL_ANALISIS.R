###### Final Analisis ######

# Join the columns TG and PORT
RXAPP <- mutate(RXAPP, TG_PORT = paste(RXAPP$TG, RXAPP$PORT, sep="_"))

# Summarise the RXAPP geting the first DEV of each TG to each port
FINAL <- RXAPP[!duplicated(RXAPP$TG_PORT),]

# Count the number of DEV of each port and assign to a temp variable
temp <- as.data.frame(table(RXAPP$TG_PORT))
colnames(temp) <- c("TG_PORT", "NUMDEV")

# Merger the two datasets and remove the temp variable
FINAL <- merge(FINAL, temp, by = "TG_PORT")
rm(temp)

# Split the Columns TG and DEV in numbers and Join in the FINAL Dataset
x <- as.character(sapply(strsplit(FINAL$DEV,'-'), "[", 1))
y <- as.numeric(sapply(strsplit(FINAL$DEV,'-'), "[", 2))
z <- as.numeric(sapply(strsplit(FINAL$TG,'-'), "[", 2))
x <- as.data.frame(x)
y <- as.data.frame(y)
z <- as.data.frame(z)
FINAL <- cbind(FINAL, x, y, z)
colnames(FINAL) <- c("TG_PORT", "TG", "DEV", "DCP", "PORT", "NUMDEV", "DEV_TYPE", "DEV_NUM", "TG_NUM")
FINAL <- select(FINAL, TG_PORT, TG, TG_NUM, DEV, DEV_TYPE, DEV_NUM, DCP, PORT, NUMDEV)
rm(x, y, z)

# Find the device Range
FINAL <- mutate(FINAL, DEV_RANGE = paste(FINAL$DEV_TYPE, paste((((ceiling(FINAL$DEV_NUM/32)*32)-2)-30), ((ceiling(FINAL$DEV_NUM/32)*32)-1), sep = "&&-"), sep = "-"))
FINAL <- mutate(FINAL, DEV_INI = (((ceiling(FINAL$DEV_NUM/32)*32)-2)-30))
FINAL <- mutate(FINAL, DEV_END = ((ceiling(FINAL$DEV_NUM/32)*32)-1))
FINAL <- select(FINAL, TG_PORT, TG, TG_NUM, DEV, DEV_TYPE, DEV_NUM, DEV_INI, DEV_END, DEV_RANGE, DCP, PORT, NUMDEV)

# Add the SC and SCGR to each TG (There is a tricky to make the loop run)
FINAL <- mutate(FINAL, SCGR = TG_NUM, SC = 0)
FINAL <- arrange(FINAL, TG_NUM, DEV_TYPE, DEV_NUM)

temp <- c(rep(999,14))
FINAL <- rbind(temp, FINAL)
FINAL <- rbind(temp, FINAL)
FINAL <- rbind(temp, FINAL)

for(i in seq(along=FINAL$TG_NUM)) {
  ifelse(FINAL$TG_NUM[i] == FINAL$TG_NUM[i-1], ifelse(FINAL$TG_NUM[i-1] == FINAL$TG_NUM[i-2], FINAL$SC[i] <- 2 , FINAL$SC[i] <- 1) , FINAL$SC[i] <- 0)
}
rm(i, temp)

FINAL <- FINAL[grep("RXOTG-.", FINAL$TG),]

# Add the DEv and DCP
FINAL$PORT <- gsub("A", 1, FINAL$PORT)
FINAL$PORT <- gsub("B", 33, FINAL$PORT)
FINAL$PORT <- gsub("C", 287, FINAL$PORT)
FINAL$PORT <- gsub("D", 319, FINAL$PORT)
FINAL$PORT <- as.numeric(FINAL$PORT)

FINAL <- arrange(FINAL, DEV_TYPE, DEV_NUM)
FINAL <- mutate(FINAL, DEV1 = 0)

temp <- c(rep(999,14))
FINAL <- rbind(temp, FINAL)
FINAL <- rbind(temp, FINAL)
FINAL <- rbind(temp, FINAL)

for(i in seq(along=FINAL$DEV)) {
  ifelse(FINAL$DEV_RANGE[i] ==  FINAL$DEV_RANGE[i-1], FINAL$DEV1[i] <- (FINAL$DEV1[i-1] + FINAL$NUMDEV[i-1]), FINAL$DEV1[i] <- FINAL$DEV_NUM[i])
}
rm(i)

for(i in seq(along=FINAL$DEV)) {
  ifelse(FINAL$DEV_RANGE[i] ==  FINAL$DEV_RANGE[i-1], FINAL$DCP[i] <- (FINAL$PORT[i] + FINAL$NUMDEV[i-1]), FINAL$DEV1[i] <- FINAL$DEV_NUM[i])
}
rm(i, temp)

# Formating the FINAL Dataset
FINAL <- FINAL[grep("RXOTG-.", FINAL$TG),]
FINAL <- mutate(FINAL, COMMENT = "")
FINAL$COMMENT[FINAL$NUMDEV <= 7 ] = "Check"
FINAL <- arrange(FINAL, TG_NUM, SC)
FINAL$DEV1 <- paste(FINAL$DEV_TYPE, FINAL$DEV1, sep="-")

# Summarise the Output in one variable
RRSCI <- select(FINAL, SCGR, SC, DEV1, DCP, NUMDEV, COMMENT)

# write to a file
write.table(RRSCI, file = paste(strsplit(filelog, "[.]")[[1]][1],"_RRSCI.txt", sep = ""), sep = "," , row.names = FALSE)

