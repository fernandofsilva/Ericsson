# Projeto Otimização

library(data.table); library(lubridate); library(ggplot2)

setwd("C:/Users/esssfff/Desktop/Otimização_Copa/ITK/")

#Reading data
file.Sync <- list.files(path = ".", pattern="NodeSync")

Sync <- data.frame()

for(i in 1:length(file.Sync)){
        
        x <- read.table(file.Sync[i],
                        sep = ",", 
                        header = TRUE,
                        stringsAsFactors = FALSE
                        )
        
        Sync <- rbind(Sync, x)
        
        }

rm(x, file.Sync, i)

Sync <- data.table(Sync)

#Selecting columns by name and converting time coluns to POSIXct
Sync <- Sync[, .(time = ymd_hm(time, tz = "America/Sao_Paulo"), 
                 object, 
                 NodeSynch.pmIubLinkDynamicDelayMax, 
                 NodeSynch.pmIubLinkStaticDelay
                 )]

#Rename Columns
setnames(Sync, gsub("NodeSynch.pm", "", names(Sync)))

#Remove NA's
Sync <- Sync[complete.cases(Sync)]

#Node Sync
Delay <- Sync[, .(time,
                  object,
                  MaxPropagationDelay = IubLinkDynamicDelayMax,
                  MaxDelayVariation = (IubLinkDynamicDelayMax - IubLinkStaticDelay)
                  )]

rm(Sync)

#Limits Delay
DelayRatio <- Delay[,
                    .(MaxPropagationDelay = 100 * sum(MaxPropagationDelay >= 30) / length(MaxPropagationDelay),
                      MaxDelayVariation = 100 * sum(MaxDelayVariation >= 10) / length(MaxDelayVariation)
                      ),
                    by = object][
                            order(-MaxPropagationDelay,MaxDelayVariation)
                            ]

write.table(DelayRatio, file = "DelayRatio.csv", sep = ";", row.names = FALSE)
