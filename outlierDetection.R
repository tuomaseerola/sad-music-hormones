outlierDetection = function(data,outlierdistance=1.5) {
# return the 1.5 * IQR value, 1.5 is the mild version, 3 extreme
# Note. Now only takes the upper threshold of outliers, Tuomas Eerola, 22/4/2017 
  iqr<-IQR(data,na.rm = TRUE)
  upperq <- quantile(data,0.75,na.rm = TRUE)
  mild.threshold.upper = (iqr * outlierdistance) + upperq
#  print(mild.threshold.upper)
 return<- as.numeric(mild.threshold.upper)
}