# analysis_EDA.R

DF<-read.csv('EDA.csv')

#### 1. LIBRARIES --------------------------------------------------------
library(lme4)
library(lmerTest)
library(emmeans)
lmerTest.limit = 20000
library(OutlierDetection)
source('constrain_outliers.R')
source('outlierDetection.R')

#### 2. TRANSFORM  --------------------------------------------------------
# Convert to log transformation
C <- 1
dfl<-DF
dfl$CDA.nSCR     <-log(C+DF$CDA.nSCR)
dfl$CDA.Latency  <-log(C+DF$CDA.Latency)
dfl$CDA.AmpSum   <-log(C+DF$CDA.AmpSum)
dfl$CDA.SCR      <-log(C+DF$CDA.SCR)
dfl$CDA.ISCR     <-log(C+DF$CDA.ISCR)
dfl$CDA.PhasicMax<-log(C+DF$CDA.PhasicMax)
dfl$CDA.Tonic    <-log(C+DF$CDA.Tonic)
dfl$TTP.nSCR     <-log(C+DF$TTP.nSCR)
dfl$TTP.Latency  <-log(C+DF$TTP.Latency)
dfl$TTP.AmpSum   <-log(C+DF$TTP.AmpSum)
dfl$Global.Mean  <-log(C+DF$Global.Mean)

##### 3. BASELINE SUBTRACTION  -------------------------------------------------
# idea, what if baseline for each condition is subtracted from the values?
#head(dfl)
library(tidyverse)

# Relative change from the baseline
dfl %>% 
  group_by(ID) %>% 
  mutate(CDA.nSCR      = CDA.nSCR      / CDA.nSCR     [Event.Name=="Baseline"]-1) %>%
  mutate(CDA.Latency   = CDA.Latency   / CDA.Latency  [Event.Name=="Baseline"]-1) %>%
  mutate(CDA.AmpSum    = CDA.AmpSum    / CDA.AmpSum   [Event.Name=="Baseline"]-1) %>%
  mutate(CDA.SCR       = CDA.SCR       / CDA.SCR      [Event.Name=="Baseline"]-1) %>%
  mutate(CDA.ISCR      = CDA.ISCR      / CDA.ISCR     [Event.Name=="Baseline"]-1) %>%
  mutate(CDA.PhasicMax = CDA.PhasicMax / CDA.PhasicMax[Event.Name=="Baseline"]-1) %>%
  mutate(CDA.Tonic     = CDA.Tonic     / CDA.Tonic    [Event.Name=="Baseline"]-1) %>%
  mutate(TTP.nSCR      = TTP.nSCR      / TTP.nSCR     [Event.Name=="Baseline"]-1) %>%
  mutate(TTP.Latency   = TTP.Latency   / TTP.Latency  [Event.Name=="Baseline"]-1) %>%
  mutate(TTP.AmpSum    = TTP.AmpSum    / TTP.AmpSum   [Event.Name=="Baseline"]-1) %>%
  mutate(Global.Mean   = Global.Mean   / Global.Mean  [Event.Name=="Baseline"]-1) %>%
  ungroup ->DF_rel # Baseline Substracted

DF_rel$TTP.nSCR[is.infinite(DF_rel$TTP.nSCR)]<-NA
DF_rel$TTP.nSCR[is.na(DF_rel$TTP.nSCR)]<-NA

DF_rel$CDA.AmpSum[is.infinite(DF_rel$CDA.AmpSum)]<-NA
DF_rel$CDA.AmpSum[is.na(DF_rel$CDA.AmpSum)]<-NA

DF_rel$CDA.nSCR<-DF_rel$CDA.nSCR*100
DF_rel$CDA.Latency<-DF_rel$CDA.Latency*100
DF_rel$CDA.AmpSum<-DF_rel$CDA.AmpSum*100
DF_rel$CDA.SCR<-DF_rel$CDA.SCR*100
DF_rel$CDA.ISCR<-DF_rel$CDA.ISCR*100
DF_rel$CDA.PhasicMax<-DF_rel$CDA.PhasicMax*100
DF_rel$CDA.Tonic<-DF_rel$CDA.Tonic*100
DF_rel$TTP.nSCR<-DF_rel$TTP.nSCR*100
DF_rel$TTP.Latency<-DF_rel$TTP.Latency*100
DF_rel$TTP.AmpSum<-DF_rel$TTP.AmpSum*100

# TRIM away the baseline
DF_rel <-dplyr::filter(DF_rel,Event.Name!='Baseline')
DF_rel$Condition<-factor(DF_rel$Event.Name,levels = c('Silence','Music'))

#### 3. TRIM OUTLIERS ------------------------------------------------------------------------------------
plotflag <- 0
IQR_level <- 1.5
constrain_outliers(DF_rel$CDA.nSCR,IQR_level,plotflag,'CDA.nSCR',remove = FALSE) # 3
constrain_outliers(DF_rel$CDA.ISCR,IQR_level,plotflag,'CDA.ISCR',remove = FALSE) # 3

constrain_outliers(DF_rel$CDA.Latency,IQR_level,plotflag,'CDA.Latency',remove = FALSE) # 7
constrain_outliers(DF_rel$CDA.SCR,IQR_level,plotflag,'CDA.SCR',remove = FALSE) # 5
constrain_outliers(DF_rel$CDA.PhasicMax,IQR_level,plotflag,'CDA.PhasicMax',remove = FALSE) # 5
constrain_outliers(DF_rel$CDA.Tonic,IQR_level,plotflag,'CDA.nSCR',remove = FALSE) # 0
constrain_outliers(DF_rel$TTP.Latency,IQR_level,plotflag,'CDA.nSCR',remove = FALSE) # 8
constrain_outliers(DF_rel$Global.Mean,IQR_level,plotflag,'CDA.nSCR',remove = FALSE) # 0

DF_rel$CDA.nSCR <- constrain_outliers(DF_rel$CDA.nSCR,IQR_level,0,'CDA.nSCR',remove = FALSE)
DF_rel$CDA.ISCR <- constrain_outliers(DF_rel$CDA.ISCR,IQR_level,0,'CDA.ISCR',remove = FALSE)

DF_rel$CDA.Latency <- constrain_outliers(DF_rel$CDA.Latency,IQR_level,0,'CDA.Latency',remove = FALSE)
DF_rel$CDA.SCR <- constrain_outliers(DF_rel$CDA.SCR,IQR_level,0,'CDA.Latency',remove = FALSE)
DF_rel$CDA.PhasicMax <- constrain_outliers(DF_rel$CDA.PhasicMax,IQR_level,0,'CDA.Latency',remove = FALSE)
DF_rel$CDA.Tonic <- constrain_outliers(DF_rel$CDA.Tonic,IQR_level,0,'CDA.Latency',remove = FALSE)
DF_rel$TTP.Latency <- constrain_outliers(DF_rel$TTP.Latency,IQR_level,0,'CDA.Latency')
DF_rel$Global.Mean <- constrain_outliers(DF_rel$Global.Mean,IQR_level,0,'CDA.Latency')

#### 5. GLMM BROAD -------------------------------------------------
DF_rel$Event.Name
DF_rel$Event.Name<-factor(DF_rel$Event.Name,levels = c('Silence','Music'))


m <- DF_rel %>%
  dplyr::group_by(Empathy,Event.Name) %>%
  dplyr::summarise(n=n(),CDA.ISCR_M=mean(CDA.ISCR,na.rm = TRUE),CDA.ISCR_SE=sd(CDA.ISCR,na.rm = TRUE)/sqrt(n), CDA.nSCR_M=mean(CDA.nSCR,na.rm = TRUE),CDA.nSCR_SE=sd(CDA.nSCR,na.rm = TRUE)/sqrt(n), CDA.AmpSum_M=mean(CDA.AmpSum,na.rm = TRUE),CDA.AmpSum_SE=sd(CDA.AmpSum,na.rm = TRUE)/sqrt(n), CDA.Tonic_M=mean(CDA.Tonic,na.rm = TRUE),CDA.Tonic_SE=sd(CDA.Tonic,na.rm = TRUE)/sqrt(n))

print(knitr::kable(m,digits = 3,caption = 'Table S2. Means and standard errors of all EDA measures.'))

#### CONTRASTS -----------------------------------------------------------------------------
Music_High   = c(0, 1, 0, 0)
Music_Low    = c(0, 0, 0, 1)
Silence_High = c(1, 0, 0, 0)
Silence_Low =  c(0, 0, 1, 0)

#### CDA.ISCR -------------------------------------------------------------------------------
m1 <- lmer(CDA.ISCR ~ Event.Name * Empathy + (1|ID) + (1|Session), data=DF_rel) 
#print(summary(m1,correlation=FALSE))
em2 <- emmeans(m1,specs = ~ Event.Name * Empathy) #   t.ratio p.value
#print(knitr::kable(em2))
cat("### CDA.ISCR")
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Silence - Low Empathy" = Silence_High - Silence_Low)),digits = 3,caption = 'CDA.ISCR contrasts.'))  #  0.379   0.7059 
print(knitr::kable(contrast(em2,method=list("Music - High Empathy vs Music - Low Empathy" = Music_High - Music_Low)),digits = 3))    # 2.159   0.0353
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Music - High Empathy" = Silence_High - Music_High)),digits = 3)) # 0.134   0.8936
print(knitr::kable(contrast(em2,method=list("Silence - Low Empathy vs Music - Low Empathy" = Silence_Low - Music_Low)),digits = 3))     # -0.695  0.4896  

#### CDA.AmpSum -------------------------------------------------------------------------------
m1 <- lmer(CDA.AmpSum ~ Event.Name * Empathy + (1|ID) + (1|Session), data=DF_rel)
#print(summary(m1,correlation=FALSE))
em2 <- emmeans(m1,specs = ~ Event.Name * Empathy) #     t.ratio p.value

cat("### CDA.AmpSum")
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Silence - Low Empathy" = Silence_High - Silence_Low)),digits = 3,caption = 'CDA.AmpSum contrasts.'))  #  0.379   0.7059 
print(knitr::kable(contrast(em2,method=list("Music - High Empathy vs Music - Low Empathy" = Music_High - Music_Low)),digits = 3))    # 2.159   0.0353
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Music - High Empathy" = Silence_High - Music_High)),digits = 3)) # 0.134   0.8936
print(knitr::kable(contrast(em2,method=list("Silence - Low Empathy vs Music - Low Empathy" = Silence_Low - Music_Low)),digits = 3))     # -0.695  0.4896  

#### CDA.nSCR -------------------------------------------------------------------------------
m1 <- lmer(CDA.nSCR ~ Event.Name * Empathy + (1|ID) + (1|Session), data=DF_rel) 
#print(summary(m1,correlation=FALSE))
em2 <- emmeans(m1,specs = ~ Event.Name * Empathy) #     t.ratio p.value

cat('### CDA.nSCR')
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Silence - Low Empathy" = Silence_High - Silence_Low)),digits = 3,caption = 'CDA.nSCR contrasts.'))  #  0.379   0.7059 
print(knitr::kable(contrast(em2,method=list("Music - High Empathy vs Music - Low Empathy" = Music_High - Music_Low)),digits = 3))    # 2.159   0.0353
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Music - High Empathy" = Silence_High - Music_High)),digits = 3)) # 0.134   0.8936
print(knitr::kable(contrast(em2,method=list("Silence - Low Empathy vs Music - Low Empathy" = Silence_Low - Music_Low)),digits = 3))     # -0.695  0.4896  

#### CDA.Tonic -------------------------------------------------------------------------------
m1 <- lmer(CDA.Tonic ~ Event.Name * Empathy + (1|ID) + (1|Session), data=DF_rel) 
#print(summary(m1,correlation=FALSE))
em2 <- emmeans(m1,specs = ~ Event.Name * Empathy) #     t.ratio p.value

cat('### CDA.Tonic')
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Silence - Low Empathy" = Silence_High - Silence_Low)),digits = 3,caption = 'CDA.Tonic contrasts.'))  #  0.379   0.7059 
print(knitr::kable(contrast(em2,method=list("Music - High Empathy vs Music - Low Empathy" = Music_High - Music_Low)),digits = 3))    # 2.159   0.0353
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Music - High Empathy" = Silence_High - Music_High)),digits = 3)) # 0.134   0.8936
print(knitr::kable(contrast(em2,method=list("Silence - Low Empathy vs Music - Low Empathy" = Silence_Low - Music_Low)),digits = 3))     # -0.695  0.4896  
