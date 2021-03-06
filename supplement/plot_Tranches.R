#!/bin/env Rscript

library(tools)

args <- commandArgs(TRUE)
verbose = TRUE

tranchesFile = args[1]
targetTITV = as.numeric(args[2])
targetSensitivity = as.numeric(args[3])
suppressLegend = ! is.na(args[4])

# -----------------------------------------------------------------------------------------------
# Useful general routines
# -----------------------------------------------------------------------------------------------

MIN_FP_RATE = 0.001 # 1 / 1000 is min error rate 

titvFPEst <- function(titvExpected, titvObserved) { 
    max(min(1 - (titvObserved - 0.5) / (titvExpected - 0.5), 1), MIN_FP_RATE) 
}

titvFPEstV <- function(titvExpected, titvs) {
    sapply(titvs, function(x) titvFPEst(titvExpected, x))
}

nTPFP <- function(nVariants, FDR) {
    return(list(TP = nVariants * (1 - FDR/100), FP = nVariants * (FDR / 100)))
}

leftShift <- function(x, leftValue = 0) {
    r = rep(leftValue, length(x))
    for ( i in 1:(length(x)-1) ) {
        #print(list(i=i))
        r[i] = x[i+1]
    }
    r
}

extra = Sys.getenv(c("XLABEL", "XTITLE"), unset="", names=TRUE)
if (extra["XLABEL"] != "") {
   extra["XLABEL"] = paste(extra["XLABEL"], "- ")
}

#print(extra["XLABEL"],quote=FALSE)

# -----------------------------------------------------------------------------------------------
# Tranches plot
# -----------------------------------------------------------------------------------------------
data2 = read.table(tranchesFile,sep=",",head=T)
data2 = data2[order(data2$novelTiTv, decreasing=F),]
#data2 = data2[order(data2$FDRtranche, decreasing=T),]
cols = c("cornflowerblue", "cornflowerblue", "darkorange", "darkorange")
density=c(20, -1, -1, 20)

outfile = paste(tranchesFile, ".variants", sep="")
png(paste(outfile, ".png", sep=""), height=500, width=800)
prevDev <- dev.cur()
pdf(paste(outfile, ".pdf", sep=""), height=5, width=8)
dev.control("enable")

par(mar = c(5, 5, 4, 2) + 0.1)
novelTiTv = c(data2$novelTITV,data2$novelTiTv)
alpha = 1 - titvFPEstV(targetTITV, novelTiTv)
#print(alpha)

numGood = round(alpha * data2$numNovel);

#numGood = round(data2$numNovel * (1-data2$targetTruthSensitivity/100))
numBad = data2$numNovel - numGood;

numPrevGood = leftShift(numGood, 0)
numNewGood = numGood - numPrevGood
numPrevBad = leftShift(numBad, 0)
numNewBad = numBad - numPrevBad

d=matrix(c(numPrevGood,numNewGood, numNewBad, numPrevBad),4,byrow=TRUE)
#print(d)
barplot(d/1000,horiz=TRUE,col=cols,space=0.2,xlab=paste(extra["XLABEL"], "Number of novel variants (1000s)"), density=density, cex.axis=1.25, cex.lab=1.25) # , xlim=c(250000,350000))
if (extra["XTITLE"] != "") {
   title(extra["XTITLE"])
}
#abline(v= d[2,dim(d)[2]], lty=2)
#abline(v= d[1,3], lty=2)
if ( ! suppressLegend ) {
    # 3, length(data2$targetTruthSensitivity)/3 +1
    legend("topright", c('Cumulative TPs','Tranche-specific TPs', 'Tranche-specific FPs', 'Cumulative FPs' ), fill=cols, density=density, bg='white', cex=1.25)
}

mtext("Ti/Tv",2,line=2.25,at=length(data2$targetTruthSensitivity)*1.2,las=1, cex=1)
mtext("truth",2,line=0,at=length(data2$targetTruthSensitivity)*1.2,las=1, cex=1)
axis(2,line=-1,at=0.7+(0:(length(data2$targetTruthSensitivity)-1))*1.2,tick=FALSE,labels=data2$targetTruthSensitivity, las=1, cex.axis=1.0)
axis(2,line=1,at=0.7+(0:(length(data2$targetTruthSensitivity)-1))*1.2,tick=FALSE,labels=round(novelTiTv,3), las=1, cex.axis=1.0)

dev.copy(which=prevDev)
dev.off()
dev.off()

if (exists('compactPDF')) {
  compactPDF(outfile)
}

##########
# plot sensitivity vs. specificity
##########

outfile = paste(tranchesFile, ".sensitivity", sep="")
png(paste(outfile, ".png", sep=""), width=600, height=600)
prevDev <- dev.cur()
pdf(paste(outfile, ".pdf", sep=""), height=5, width=8)
dev.control("enable")

sensitivity = data2$truthSensitivity
if ( ! is.null(sensitivity) ) {
    #specificity = titvFPEstV(targetTITV, novelTiTv)
    specificity = novelTiTv
    plot(sensitivity, specificity, type="b", col="cornflowerblue", xlab=paste(extra["XLABEL"], "tranche truth sensitivity"), ylab="Specificity (Novel Ti/Tv ratio)")
    if (extra["XTITLE"] != "") {
        title(extra["XTITLE"])
    }
    abline(h=targetTITV, lty=2)
    abline(v=targetSensitivity, lty=2)
    #text(max(sensitivity), targetTITV-0.05, labels="Expected novel Ti/Tv", pos=2)
}
dev.copy(which=prevDev)
dev.off()
dev.off()

if (exists('compactPDF')) {
  compactPDF(outfile)
}
