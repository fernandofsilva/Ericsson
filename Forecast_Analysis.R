library(lubridate)
library(xts)
library(astsa)

data <- read.csv("Inputs/STS_forecast.csv", 
                 colClasses = rep("character", 4), 
                 col.names = c("Time", "Node", "Mpbs", "Erl"))

data$Mpbs <- gsub(",", ".", data$Mpbs)
data$Mpbs <- as.numeric(data$Mpbs)
data$Erl <- gsub(",", ".", data$Erl)
data$Erl <- as.numeric(data$Erl)

data$Time <- ymd(data$Time)

data[is.na(data),]

BSCAFLA <- data[data$Node == "BSCAFLA",]
BSCAFLA <- as.xts(BSCAFLA[ , -1], order.by = BSCAFLA$Time)

plot.zoo(BSCAFLA, plot.type = "multiple", ylab = labels)

plot.zoo(flights_xts, plot.type = "single", lty = lty)
legend("right", lty = lty, legend = labels)


