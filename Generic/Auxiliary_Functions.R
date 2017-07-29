# This file contains Several auxiliary functions

DUGPort <- function(x) {
        # Return de DUG Port according to DCP Range.
        #
        # Args:
        #   x: A number or a vector of numbers with DCP value.
        #
        # Returns:
        #   DUG Port (A, B, C or D).
        dcp.range <- c(1:31, 33:63, 287:317, 319:349)
        # Error handling
        ifelse (!x %in% dcp.range, 
                stop("The DCP value: ", 
                     x, 
                     "is outside of the allowed DCP range."),
                x
                )
        names(x) <- x
        names(x) <- ifelse(x >= 1 & x <= 31, "A", names(x))
        names(x) <- ifelse(x >= 33 & x <= 63, "B", names(x))
        names(x) <- ifelse(x >= 287 & x <= 317, "C", names(x))
        names(x) <- ifelse(x >= 319 & x <= 349, "D", names(x))
        return(names(x))
}

DevInitial <- function(x) {
        # Return the initial DEV of the Range
        #
        # Args:
        #   x: DEV value.
        #
        # Returns:
        #   Initial DEV Range.
        # Error handling
        if (!x %% 32) {
                stop("The DEV value: ", x, 
                     "belongs to sync frame.")
        }
        dev.ini <- (((ceiling(x/32)*32)-2)-30)
        return(dev.ini)
}

DevEnd <- function(x) {
        # Return the last DEV of the Range
        #
        # Args:
        #   x: DEV value.
        #
        # Returns:
        #   Last DEV Range.
        # Error handling
        if (!x %% 32) {
                stop("The DEV value: ", x, 
                     "belongs to sync frame.")
        }
        dev.end <- ((ceiling(x/32)*32)-1)
        return(dev.end)
}

DevRange <- function(x) {
        # Return the DEV Range, ie. 64&&-95.
        #
        # Args:
        #   x: DEV value.
        #
        # Returns:
        #   DEV Range.
        # Error handling
        if (!x %% 32) {
                stop("The DEV value: ", x, 
                     "belongs to sync frame.")
        }
        dev.ini <- (((ceiling(x/32)*32)-2)-30)
        dev.end <- ((ceiling(x/32)*32)-1)
        dev.range <- paste(dev.ini, ((ceiling(x/32)*32)-1), sep = "&&-")
        return(dev.range)
}

SplitDevType <- function(x) {
        # Split de Abis device in device type.
        #
        # Args:
        #   x: String with RBLT device. i.e. RBLT2-14.
        #
        # Returns:
        #   DEV type
        dev.type <- as.character(strsplit(x,'-')[[1]][1])
        # Devices of Abis Interface allowed.
        dev.type.allowed <- c("RBLT24", "RBLT", "RBLT2", "RBLT3")
        # Error handling
        if (!dev.type %in% dev.type.allowed) {
                stop("The Dev Type : ", x, 
                     "it not allowed.")
        }
        return(dev.type)
}

SplitDevNum <- function(x) {
        # Split de Abis device in device type.
        #
        # Args:
        #   x: String with RBLT device. i.e. RBLT2-14.
        #
        # Returns:
        #   DEV type
        dev.num <- as.numeric(strsplit(x,'-')[[1]][2])
        # Error handling
        if (!dev.num %% 32) {
                stop("The DEV value: ", x, 
                     "belongs to sync frame.")
        }
        return(dev.num)
}
