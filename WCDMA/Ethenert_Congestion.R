library(data.table); library(lubridate); library(ggplot2)

setwd("C:/Users/esssfff/Desktop/Otimização_Copa/ITK/")

#Reading data
file.Eth <- list.files(path = ".", pattern="GigaBitEthernet")

Eth <- data.frame()

for(i in 1:length(file.Eth)){
        
        x <- read.table(file.Eth[i], 
                        sep = ",", 
                        header = TRUE,
                        stringsAsFactors = FALSE
        )
        
        Eth <- rbind(Eth, x)
        
}

rm(x, file.Eth, i)

Eth <- data.table(Eth)

#Selecting columns by name and converting time coluns to POSIXct
Eth <- Eth[, .(time = ymd_hm(time, tz = "America/Sao_Paulo"), 
               object,
               GigaBitEthernet.pmIfInOctetsLink1Hi,
               GigaBitEthernet.pmIfInOctetsLink1Lo,
               GigaBitEthernet.pmIfOutOctetsLink1Hi,
               GigaBitEthernet.pmIfOutOctetsLink1Lo,
               GigaBitEthernet.pmDot1qTpVlanPortInDiscardsLink1, 
               GigaBitEthernet.pmIfInErrorsLink1, 
               GigaBitEthernet.pmIfInUnknownProtosLink1, 
               GigaBitEthernet.pmIfInDiscardsLink1, 
               GigaBitEthernet.pmIfInBroadcastPktsLink1, 
               GigaBitEthernet.pmIfInMulticastPktsLink1, 
               GigaBitEthernet.pmIfInUcastPktsLink1,
               GigaBitEthernet.pmIfOutBroadcastPktsLink1,
               GigaBitEthernet.pmIfOutMulticastPktsLink1,
               GigaBitEthernet.pmIfOutUcastPktsLink1,
               GigaBitEthernet.pmIfOutErrorsLink1,
               GigaBitEthernet.pmIfOutDiscardsLink1
               )]

#Rename Columns
setnames(Eth, gsub("GigaBitEthernet.pm", "", names(Eth)))

Eth[is.na(Eth)] = 0

#Bandwidth over the time
BWUtil <- Eth[, .(time,
                  object,
                  AV_THR_ETH_IN = 8 * ((2^31 * IfInOctetsLink1Hi) + IfInOctetsLink1Lo + 20 * (Dot1qTpVlanPortInDiscardsLink1 + IfInErrorsLink1 + IfInUnknownProtosLink1 + IfInDiscardsLink1 + IfInBroadcastPktsLink1 + IfInMulticastPktsLink1 + 1000 * IfInUcastPktsLink1))/(1000*900),
                  AV_THR_ETH_OUT = 8 * ((2^31 * IfOutOctetsLink1Hi) + IfOutOctetsLink1Lo + 20 * (IfOutBroadcastPktsLink1 + IfOutMulticastPktsLink1 + 1000 * IfOutUcastPktsLink1 - (IfOutErrorsLink1 + IfOutDiscardsLink1)))/(1000 * 900),
                  AV_THR_UTIL_IN = (8 * ((2^31 * IfInOctetsLink1Hi) + IfInOctetsLink1Lo + 20 * (Dot1qTpVlanPortInDiscardsLink1 + IfInErrorsLink1 + IfInUnknownProtosLink1 + IfInDiscardsLink1 + IfInBroadcastPktsLink1 + IfInMulticastPktsLink1 + 1000 * IfInUcastPktsLink1))/(1000*900))/10000,
                  AV_THR_UTIL_OUT = (8 * ((2^31 * IfOutOctetsLink1Hi) + IfOutOctetsLink1Lo + 20 * (IfOutBroadcastPktsLink1 + IfOutMulticastPktsLink1 + 1000 * IfOutUcastPktsLink1 - (IfOutErrorsLink1 + IfOutDiscardsLink1)))/(1000 * 900))/10000
                  )]

rm(Eth)

#Congestion over the time
BWCONGESTION <- BWUtil[,
                    .(AV_UTIL_IN = 100 * sum(AV_THR_UTIL_IN >= 80) / length(AV_THR_UTIL_IN),
                      AV_UTIL_OUT = 100 * sum(AV_THR_UTIL_IN >= 80) / length(AV_THR_UTIL_IN)
                    ),
                    by = object][
                            ,
                            .(object, AV_UTIL_IN, AV_UTIL_IN,
                              Rank = AV_UTIL_IN + AV_UTIL_IN
                            )][
                                    order(-Rank)
                                    ]

#Charts Congestion
setwd("C:/Users/esssfff/Desktop/Otimização_Copa/CHARTS/")

site <- unique(BWUtil$object)

for (i in seq(length(site))){
        
        x <- BWUtil[object == paste(site[i])]
        
        ggplot(x, aes(time)) +
                geom_line(aes(y = AV_THR_UTIL_IN, colour = "Thp_Ethernet")) +
                labs(title = paste("Ethernet Congestion Site",unique(BWUtil$object)[i])) +
                ylab("%") +
                xlab("Time") +
                scale_x_datetime(date_breaks = "2 hour",date_labels = "%b %e %H %M") +
                theme(axis.text.x = element_text(angle = 90, hjust = 1))
        
        ggsave(filename=paste("Thp_Eth_",site[i],".jpeg"), device = "jpeg", width = 25.4, height = 12.7, units = "cm", dpi = 100)
        
}

rm(site, i, x, BWUtil)


