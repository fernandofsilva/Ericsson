# Projeto Otimização

library(data.table); library(lubridate); library(ggplot2); library(dplyr)

setwd("C:/Users/esssfff/Desktop/Otimização_Copa/ITK/")

#Reading data
file.VplTp <- list.files(path = ".", pattern="VplTp")

VplTp <- data.frame()

for(i in 1:length(file.VplTp)){
        
        x <- read.table(file.VplTp[i], 
                        sep = ",", 
                        header = TRUE,
                        stringsAsFactors = FALSE
        )
        
        VplTp <- rbind(VplTp, x)
        
}

rm(x, file.VplTp, i)

VplTp <- data.table(VplTp)

#Selecting columns by name and converting time coluns to POSIXct
VplTp <- VplTp[, .(time = ymd_hm(time, tz = "America/Sao_Paulo"), 
                   object, 
                   VplTp.pmReceivedAtmCells, 
                   VplTp.pmTransmittedAtmCells
                   )]

#Rename Columns
setnames(VplTp, gsub("VplTp.pm", "", names(VplTp)))

#Remove NA's
VplTp <- VplTp[complete.cases(VplTp)]

# Reading input
PCR <- read.table("ATM_PCR.csv", sep = ";", header = TRUE)

# Merger datasets
VplTp <- merge(VplTp, PCR, by.x = "object", by.y = "Site")

rm(PCR)

#Bandwidth over the time
VPUtil <- VplTp[, .(time,
                  object,
                  AV_Cell_Trans = 100 * (TransmittedAtmCells/(PCR * 900)),
                  AV_Cell_Recei = 100 * (ReceivedAtmCells/(PCR * 900))
                  )]
rm(VplTp)

#Charts Congestion
setwd("C:/Users/esssfff/Desktop/Otimização_Copa/CHARTS/")

site <- unique(VPUtil$object)

for (i in seq(length(site))){
        
        x <- VPUtil[object == paste(site[i])]
        
        ggplot(x, aes(time)) +
                geom_line(aes(y = AV_Cell_Trans, colour = "Trans_Cells")) +
                geom_line(aes(y =AV_Cell_Recei, colour = "Receiv_Cells")) +
                labs(title = paste("Bandwidth Utilization Site",unique(VPUtil$object)[i])) +
                ylab("%") +
                xlab("Time") +
                ylim(0, 100) +
                scale_x_datetime(date_breaks = "4 hour",date_labels = "%b %e %H %M") +
                theme(axis.text.x = element_text(angle = 90, hjust = 1))
        
        ggsave(filename=paste("ATM_Cong",site[i],".jpeg"), device = "jpeg", width = 25.4, height = 12.7, units = "cm", dpi = 100)
        
}

rm(site, i, x, VPUtil)



