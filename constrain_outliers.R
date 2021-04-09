constrain_outliers <- function(data,IQR_level,plotflag,label,remove=FALSE){
# TE 1.8.2017
# Blood experiment
# T. Eerola 25.4.2017
#
  
# plotflag<-0

#IQR_level <- 1.5 # 1.5 or 3
#print(paste('Constrain outliers - IQR + ',IQR_level,sep=""))

if(plotflag==1){
  par(mfrow=c(2,1))
  hist(data,main=paste(label,' - Orig.'),col='grey')
  thr <- outlierDetection(data,IQR_level);
  n<-sum(data > thr,na.rm = TRUE)
  if(remove==TRUE){
    data[data > thr] <- NA
  }
  if(remove==FALSE){
    data[data > thr] <- thr
  }
  hist(data,main=paste(label,' - Trimmed.'),col='grey20')
  print(n)
}
if(plotflag==0){
    thr <- outlierDetection(data,IQR_level);
    n<-sum(data > thr,na.rm = TRUE)
    if(remove==TRUE){
      data[data > thr] <- NA
    }
    if(remove==FALSE){
      data[data > thr] <- thr
    }
#    print(n)
}

return <- data
}
