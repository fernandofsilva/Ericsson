#Load library
library(data.table)
library(RODBC)

#Connect to SQL moView Vivo db
odbcChannel <- odbcDriverConnect('driver={SQL Server};
                                 server=146.250.136.110;
                                 database=moView_Vivo;
                                 Uid=mv_vivo;Pwd=vivo')


odbcChannel <- odbcDriverConnect('driver={SQL Server};
                                 server=146.250.136.14;
                                 database=moView_TIM;
                                 Uid=mv_tim;Pwd=tim')

RNCID <- "AGNA03"

IPInt <- sqlQuery(odbcChannel, paste("SELECT nodeLabel, rdn, IpInterfaceId, vid, defaultRouter0 FROM dbo.IpInterface WHERE [subNetworkB] = '", RNCID, "'  ORDER BY nodeLabel", sep = ""))
IPInt <- IPInt[, c(-2, -3)]
IPInt <- IPInt[!duplicated(IPInt),]
IPInt <- IPInt[-grep(substr(RNCID, 1, 4), IPInt$nodeLabel),]

HostEt <- sqlQuery(odbcChannel, paste("SELECT nodeLabel, rdn, IpAccessHostEtId, ipAddress FROM dbo.IpAccessHostEt WHERE [subNetworkB] = '", RNCID, "'  ORDER BY nodeLabel", sep = ""))
HostEt <- HostEt[, c(-2, -3)]
HostEt <- HostEt[!duplicated(HostEt),]
HostEt <- HostEt[-grep(substr(RNCID, 1, 4), HostEt$nodeLabel),]

IP <- sqlQuery(odbcChannel, paste("SELECT nodeLabel, rdn, nodeIpAddress FROM dbo.Ip WHERE [subNetworkB] = '", RNCID, "'  ORDER BY nodeLabel", sep = ""))
IP <- IP[, -2]
IP <- IP[!duplicated(IP),]
IP <- IP[-grep(substr(RNCID, 1, 4), IP$nodeLabel),]

IPInt <- data.table(IPInt)
HostEt <- data.table(HostEt)
IP <- data.table(IP)

setkey(IPInt, nodeLabel)
setkey(HostEt, nodeLabel)
setkey(IP, nodeLabel)

RNC <- IPInt[ .(HostEt), nomatch = NA]
setkey(RNC, nodeLabel)
RNC <- RNC[ .(IP), nomatch = NA]

write.csv(RNC, paste("c://Users/esssfff/Documents/Inputs/", RNCID, ".csv", sep = ""), row.names = FALSE)

#Close channel
odbcClose(odbcChannel)

rm(odbcChannel)

rm(list = ls())