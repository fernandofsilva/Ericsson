# Projeto Otimização

library(data.table); library(lubridate); library(ggplot2)

setwd("C:/Users/esssfff/Desktop/Otimização_Copa/ITK/")

#Reading data
file.Iub <- list.files(path = ".", pattern="Iubdatastreams")

Iub <- data.frame()

for(i in 1:length(file.Iub)){
        
        x <- read.table(file.Iub[i], 
                        sep = ",", 
                        header = TRUE,
                        stringsAsFactors = FALSE
        )
        
        Iub <- rbind(Iub, x)
        
}

rm(x, file.Iub, i)

Iub <- data.table(Iub)

#Selecting columns by name and converting time coluns to POSIXct
Iub <- Iub[, .(time = ymd_hm(time, tz = "America/Sao_Paulo"), 
               object, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi00, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi01, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi02, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi03, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi04, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi05, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi06, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi07, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi08, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi09, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi10, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi11, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi12, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi13, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi14, 
               IubDataStreams.pmCapAllocIubHsLimitingRatioSpi15, 
               IubDataStreams.pmDchFramesReceived, 
               IubDataStreams.pmDchFramesTooLate, 
               IubDataStreams.pmEdchIubLimitingRatio, 
               IubDataStreams.pmHsDataFramesLostSpi00, 
               IubDataStreams.pmHsDataFramesLostSpi01, 
               IubDataStreams.pmHsDataFramesLostSpi02, 
               IubDataStreams.pmHsDataFramesLostSpi03, 
               IubDataStreams.pmHsDataFramesLostSpi04, 
               IubDataStreams.pmHsDataFramesLostSpi05, 
               IubDataStreams.pmHsDataFramesLostSpi06, 
               IubDataStreams.pmHsDataFramesLostSpi07, 
               IubDataStreams.pmHsDataFramesLostSpi08, 
               IubDataStreams.pmHsDataFramesLostSpi09, 
               IubDataStreams.pmHsDataFramesLostSpi10, 
               IubDataStreams.pmHsDataFramesLostSpi11, 
               IubDataStreams.pmHsDataFramesLostSpi12, 
               IubDataStreams.pmHsDataFramesLostSpi13, 
               IubDataStreams.pmHsDataFramesLostSpi14, 
               IubDataStreams.pmHsDataFramesLostSpi15, 
               IubDataStreams.pmHsDataFramesReceivedSpi00, 
               IubDataStreams.pmHsDataFramesReceivedSpi01, 
               IubDataStreams.pmHsDataFramesReceivedSpi02, 
               IubDataStreams.pmHsDataFramesReceivedSpi03, 
               IubDataStreams.pmHsDataFramesReceivedSpi04, 
               IubDataStreams.pmHsDataFramesReceivedSpi05, 
               IubDataStreams.pmHsDataFramesReceivedSpi06, 
               IubDataStreams.pmHsDataFramesReceivedSpi07, 
               IubDataStreams.pmHsDataFramesReceivedSpi08, 
               IubDataStreams.pmHsDataFramesReceivedSpi09, 
               IubDataStreams.pmHsDataFramesReceivedSpi10, 
               IubDataStreams.pmHsDataFramesReceivedSpi11, 
               IubDataStreams.pmHsDataFramesReceivedSpi12, 
               IubDataStreams.pmHsDataFramesReceivedSpi13, 
               IubDataStreams.pmHsDataFramesReceivedSpi14, 
               IubDataStreams.pmHsDataFramesReceivedSpi15
)]

#Rename Columns
setnames(Iub, gsub("IubDataStreams.pm", "", names(Iub)))

#Remove NA's
Iub <- Iub[complete.cases(Iub)]

setwd("C:/Users/esssfff/Desktop/Otimização_Copa/")

#HS Congestion 
HSCONGESTION <- Iub[,
                    .(SPI00 = 100 * sum(CapAllocIubHsLimitingRatioSpi00 >= 5) / length(CapAllocIubHsLimitingRatioSpi00),
                      SPI01 = 100 * sum(CapAllocIubHsLimitingRatioSpi01 >= 5) / length(CapAllocIubHsLimitingRatioSpi01),
                      SPI02 = 100 * sum(CapAllocIubHsLimitingRatioSpi02 >= 5) / length(CapAllocIubHsLimitingRatioSpi02),
                      SPI03 = 100 * sum(CapAllocIubHsLimitingRatioSpi03 >= 5) / length(CapAllocIubHsLimitingRatioSpi03),
                      SPI04 = 100 * sum(CapAllocIubHsLimitingRatioSpi04 >= 5) / length(CapAllocIubHsLimitingRatioSpi04),
                      SPI05 = 100 * sum(CapAllocIubHsLimitingRatioSpi05 >= 5) / length(CapAllocIubHsLimitingRatioSpi05),
                      SPI06 = 100 * sum(CapAllocIubHsLimitingRatioSpi06 >= 5) / length(CapAllocIubHsLimitingRatioSpi06),
                      SPI07 = 100 * sum(CapAllocIubHsLimitingRatioSpi07 >= 5) / length(CapAllocIubHsLimitingRatioSpi07),
                      SPI08 = 100 * sum(CapAllocIubHsLimitingRatioSpi08 >= 5) / length(CapAllocIubHsLimitingRatioSpi08),
                      SPI09 = 100 * sum(CapAllocIubHsLimitingRatioSpi09 >= 5) / length(CapAllocIubHsLimitingRatioSpi09),
                      SPI10 = 100 * sum(CapAllocIubHsLimitingRatioSpi10 >= 5) / length(CapAllocIubHsLimitingRatioSpi10),
                      SPI11 = 100 * sum(CapAllocIubHsLimitingRatioSpi11 >= 5) / length(CapAllocIubHsLimitingRatioSpi11),
                      SPI12 = 100 * sum(CapAllocIubHsLimitingRatioSpi12 >= 5) / length(CapAllocIubHsLimitingRatioSpi12),
                      SPI13 = 100 * sum(CapAllocIubHsLimitingRatioSpi13 >= 5) / length(CapAllocIubHsLimitingRatioSpi13),
                      SPI14 = 100 * sum(CapAllocIubHsLimitingRatioSpi14 >= 5) / length(CapAllocIubHsLimitingRatioSpi14),
                      SPI15 = 100 * sum(CapAllocIubHsLimitingRatioSpi15 >= 5) / length(CapAllocIubHsLimitingRatioSpi15)
                      ),
                    by = object][
                            ,
                            .(object, SPI00, SPI01, SPI02, SPI03, SPI04, SPI05, SPI06, SPI07, SPI08, SPI09, SPI10, SPI11, SPI12, SPI13, SPI14, SPI15,
                              Rank = SPI00 + SPI01 + SPI02 + SPI03 + SPI04 + SPI05 + SPI06 + SPI07 + SPI08 + SPI09 + SPI10 + SPI11 + SPI12 + SPI13 + SPI14 + SPI15
                              )][
                                      order(-Rank)
                                      ]

write.table(HSCONGESTION, file = "HSCONGESTION.csv", sep = ";", row.names = FALSE)

rm(HSCONGESTION)

#Charts Congestion
setwd("C:/Users/esssfff/Desktop/Otimização_Copa/CHARTS/")

site <- unique(Iub$object)

for (i in seq(length(site))){
        
        x <- Iub[object == paste(site[i])]
        
        ggplot(x, aes(x=time)) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi00, colour = "SPI00")) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi01, colour = "SPI01")) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi02, colour = "SPI02")) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi03, colour = "SPI03")) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi04, colour = "SPI04")) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi05, colour = "SPI05")) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi06, colour = "SPI06")) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi07, colour = "SPI07")) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi08, colour = "SPI08")) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi09, colour = "SPI09")) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi10, colour = "SPI10")) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi11, colour = "SPI11")) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi12, colour = "SPI12")) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi13, colour = "SPI13")) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi14, colour = "SPI14")) +
                geom_line(aes(y = CapAllocIubHsLimitingRatioSpi15, colour = "SPI15")) +
                labs(title = paste("SPI Congestion Site",unique(Iub$object)[i])) +
                ylab("%") +
                xlab("Time") +
                ylim(0, 100) +
                scale_x_datetime(date_breaks = "4 hour",date_labels = "%b %e %H %M") +
                theme(axis.text.x = element_text(angle = 90, hjust = 1))
        
        ggsave(filename=paste(site[i],"Cong",".jpeg"), device = "jpeg", width = 25.4, height = 12.7, units = "cm", dpi = 100)
        
}

rm(site, i, x)

setwd("C:/Users/esssfff/Desktop/Otimização_Copa/")

#Dch Frame Loss Ratio
DCHFrameLost <- Iub[, .(time, 
                        object,
                        DHCFrameLost = (100 * (DchFramesTooLate / (1000 * DchFramesReceived)))
                        )]

DCHFrameLostRatio <- DCHFrameLost[,
                                  .(DHCFrameLost = 100 * sum(DHCFrameLost >= 1) / length(DHCFrameLost)
                                    ),
                                  by = object]

write.table(DCHFrameLostRatio, file = "DCHFrameLostRatio.csv", sep = ";", row.names = FALSE)

rm(DCHFrameLostRatio)

#Charts FrameLost
setwd("C:/Users/esssfff/Desktop/Otimização_Copa/CHARTS/")

site <- unique(DCHFrameLost$object)

for (i in seq(length(site))){
        
        x <- DCHFrameLost[object == paste(site[i])]
        
        ggplot(x, aes(time)) +
                geom_line(aes(y = DHCFrameLost, colour = "DCH")) +
                labs(title = paste("SPI DCH FrameLost Site",unique(Iub$object)[i])) +
                ylab("%") +
                xlab("Time") +
                ylim(0, 10) +
                scale_x_datetime(date_breaks = "4 hour",date_labels = "%b %e %H %M") +
                theme(axis.text.x = element_text(angle = 90, hjust = 1))
        
        ggsave(filename=paste(site[i],"FR_DCH",".jpeg"), device = "jpeg", width = 25.4, height = 12.7, units = "cm", dpi = 100)
        
}

rm(x, i, site, DCHFrameLost)

setwd("C:/Users/esssfff/Desktop/Otimização_Copa/")

#HS Frame Lost
HSFrameLost <- Iub[, .(time, 
                       object, 
                       HSFrameLostSPI00 = 100 * HsDataFramesLostSpi00 / (HsDataFramesReceivedSpi00 + HsDataFramesLostSpi00),
                       HSFrameLostSPI01 = 100 * HsDataFramesLostSpi01 / (HsDataFramesReceivedSpi01 + HsDataFramesLostSpi01),
                       HSFrameLostSPI02 = 100 * HsDataFramesLostSpi02 / (HsDataFramesReceivedSpi02 + HsDataFramesLostSpi02),
                       HSFrameLostSPI03 = 100 * HsDataFramesLostSpi03 / (HsDataFramesReceivedSpi03 + HsDataFramesLostSpi03),
                       HSFrameLostSPI04 = 100 * HsDataFramesLostSpi04 / (HsDataFramesReceivedSpi04 + HsDataFramesLostSpi04),
                       HSFrameLostSPI05 = 100 * HsDataFramesLostSpi05 / (HsDataFramesReceivedSpi05 + HsDataFramesLostSpi05),
                       HSFrameLostSPI06 = 100 * HsDataFramesLostSpi06 / (HsDataFramesReceivedSpi06 + HsDataFramesLostSpi06),
                       HSFrameLostSPI07 = 100 * HsDataFramesLostSpi07 / (HsDataFramesReceivedSpi07 + HsDataFramesLostSpi07),
                       HSFrameLostSPI08 = 100 * HsDataFramesLostSpi08 / (HsDataFramesReceivedSpi08 + HsDataFramesLostSpi08),
                       HSFrameLostSPI09 = 100 * HsDataFramesLostSpi09 / (HsDataFramesReceivedSpi09 + HsDataFramesLostSpi09),
                       HSFrameLostSPI10 = 100 * HsDataFramesLostSpi10 / (HsDataFramesReceivedSpi10 + HsDataFramesLostSpi10),
                       HSFrameLostSPI11 = 100 * HsDataFramesLostSpi11 / (HsDataFramesReceivedSpi11 + HsDataFramesLostSpi11),
                       HSFrameLostSPI12 = 100 * HsDataFramesLostSpi12 / (HsDataFramesReceivedSpi12 + HsDataFramesLostSpi12),
                       HSFrameLostSPI13 = 100 * HsDataFramesLostSpi13 / (HsDataFramesReceivedSpi13 + HsDataFramesLostSpi13),
                       HSFrameLostSPI14 = 100 * HsDataFramesLostSpi14 / (HsDataFramesReceivedSpi14 + HsDataFramesLostSpi14),
                       HSFrameLostSPI15 = 100 * HsDataFramesLostSpi15 / (HsDataFramesReceivedSpi15 + HsDataFramesLostSpi15)
)]

#Replace NaN by 0
HSFrameLost[is.na(HSFrameLost)] = 0


#HS Frame Lost Ratio
HSFrameLostRatio <- HSFrameLost[, 
                                .(SPI00 = 100 * sum(HSFrameLostSPI00 >= 1) / length(HSFrameLostSPI00),
                                  SPI01 = 100 * sum(HSFrameLostSPI01 >= 1) / length(HSFrameLostSPI01),
                                  SPI02 = 100 * sum(HSFrameLostSPI02 >= 1) / length(HSFrameLostSPI02),
                                  SPI03 = 100 * sum(HSFrameLostSPI03 >= 1) / length(HSFrameLostSPI03),
                                  SPI04 = 100 * sum(HSFrameLostSPI04 >= 1) / length(HSFrameLostSPI04),
                                  SPI05 = 100 * sum(HSFrameLostSPI05 >= 1) / length(HSFrameLostSPI05),
                                  SPI06 = 100 * sum(HSFrameLostSPI06 >= 1) / length(HSFrameLostSPI06),
                                  SPI07 = 100 * sum(HSFrameLostSPI07 >= 1) / length(HSFrameLostSPI07),
                                  SPI08 = 100 * sum(HSFrameLostSPI08 >= 1) / length(HSFrameLostSPI08),
                                  SPI09 = 100 * sum(HSFrameLostSPI09 >= 1) / length(HSFrameLostSPI09),
                                  SPI10 = 100 * sum(HSFrameLostSPI10 >= 1) / length(HSFrameLostSPI10),
                                  SPI11 = 100 * sum(HSFrameLostSPI11 >= 1) / length(HSFrameLostSPI11),
                                  SPI12 = 100 * sum(HSFrameLostSPI12 >= 1) / length(HSFrameLostSPI12),
                                  SPI13 = 100 * sum(HSFrameLostSPI13 >= 1) / length(HSFrameLostSPI13),
                                  SPI14 = 100 * sum(HSFrameLostSPI14 >= 1) / length(HSFrameLostSPI14),
                                  SPI15 = 100 * sum(HSFrameLostSPI15 >= 1) / length(HSFrameLostSPI15)
                                ),
                                by = object]

write.table(HSFrameLostRatio, file = "HSFrameLostRatio.csv", sep = ";", row.names = FALSE)

rm(HSFrameLostRatio)

#Charts FrameLost
setwd("C:/Users/esssfff/Desktop/Otimização_Copa/CHARTS/")

site <- unique(HSFrameLost$object)

for (i in seq(length(site))){
        
        x <- HSFrameLost[object == paste(site[i])]
        
        ggplot(x, aes(time)) +
                geom_line(aes(y = HSFrameLostSPI00, colour = "SPI00")) +
                geom_line(aes(y = HSFrameLostSPI01, colour = "SPI01")) +
                geom_line(aes(y = HSFrameLostSPI02, colour = "SPI02")) +
                geom_line(aes(y = HSFrameLostSPI03, colour = "SPI03")) +
                geom_line(aes(y = HSFrameLostSPI04, colour = "SPI04")) +
                geom_line(aes(y = HSFrameLostSPI05, colour = "SPI05")) +
                geom_line(aes(y = HSFrameLostSPI06, colour = "SPI06")) +
                geom_line(aes(y = HSFrameLostSPI07, colour = "SPI07")) +
                geom_line(aes(y = HSFrameLostSPI08, colour = "SPI08")) +
                geom_line(aes(y = HSFrameLostSPI09, colour = "SPI09")) +
                geom_line(aes(y = HSFrameLostSPI10, colour = "SPI10")) +
                geom_line(aes(y = HSFrameLostSPI11, colour = "SPI11")) +
                geom_line(aes(y = HSFrameLostSPI12, colour = "SPI12")) +
                geom_line(aes(y = HSFrameLostSPI13, colour = "SPI13")) +
                geom_line(aes(y = HSFrameLostSPI14, colour = "SPI14")) +
                geom_line(aes(y = HSFrameLostSPI15, colour = "SPI15")) +
                labs(title = paste("SPI HS FrameLost Site",unique(Iub$object)[i])) +
                ylab("%") +
                xlab("Time") +
                ylim(0, 10) +
                scale_x_datetime(date_breaks = "4 hour",date_labels = "%b %e %H %M") +
                theme(axis.text.x = element_text(angle = 90, hjust = 1))
        
        ggsave(filename=paste(site[i],"FL_HS",".jpeg"), device = "jpeg", width = 25.4, height = 12.7, units = "cm", dpi = 100)
        
}

rm(x, i, site, HSFrameLost, Iub)





