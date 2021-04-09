# analysis_HRV.R

DF<-read.csv('HRV.csv')

#### 1. LIBRARIES --------------------------------------------------------
library(lme4)
library(lmerTest)
library(emmeans)
lmerTest.limit = 20000
library(OutlierDetection)
source('constrain_outliers.R')
source('outlierDetection.R')

#### 2. TRANSFORM HRV --------------------------------------------------------

# create two normalised indices
#calculate HFnu and LFnu!
# LFnu = LF power in normalized units LF/(total power-VLF)×100
# HFnu = HF power in normalized units LF/(total power-VLF)×100
DF$LFnu <- DF$LF / (DF$VLF+DF$LF+DF$HF-DF$VLF)*100
DF$HFnu <- DF$HF / (DF$VLF+DF$LF+DF$HF-DF$VLF)*100

DF$LFnu2 <- DF$LF / (DF$VLF+DF$LF+DF$HF)
DF$HFnu2 <- DF$HF / (DF$VLF+DF$LF+DF$HF)

# Convert to log transformation
C <- 1
dfl<-DF
#dfl$ULF     <-log(C+DF$ULF)   # Not reliable from short-term recordings
dfl$LFnu2  <-log(C+DF$LFnu2)
dfl$HFnu2  <-log(C+DF$HFnu2)
dfl$LFnu  <-log(C+DF$LFnu)
dfl$HFnu  <-log(C+DF$HFnu)
dfl$VLF  <-log(C+DF$VLF)
dfl$LF   <-log(C+DF$LF)
dfl$HF      <-log(C+DF$HF)
dfl$LF.HF     <-log(C+DF$LF.HF)
dfl$SDNN<-log(C+DF$SDNN)
dfl$SDANN    <-log(C+DF$SDANN)
dfl$pNN50     <-log(C+DF$pNN50)
dfl$SDSD  <-log(C+DF$SDSD)
dfl$IRRR   <-log(C+DF$IRRR)
dfl$MADRR  <-log(C+DF$MADRR)

##### 3. BASELINE SUBTRACTION  -------------------------------------------------
# idea, what if baseline for each condition is substracted from the values?
head(dfl)
library(tidyverse)

# Relative change from baseline

dfl %>% 
  group_by(ID) %>% 
  mutate(VLF     = VLF    /     VLF[Event.Name=="Baseline"]-1) %>% 
  mutate(LF      = LF     /      LF[Event.Name=="Baseline"]-1) %>% 
  mutate(LFnu    = LFnu   /    LFnu[Event.Name=="Baseline"]-1) %>% 
  mutate(LFnu2   = LFnu2  /   LFnu2[Event.Name=="Baseline"]-1) %>% 
  mutate(HF      = HF     /      HF[Event.Name=="Baseline"]-1) %>% 
  mutate(HFnu    = HFnu   /    HFnu[Event.Name=="Baseline"]-1) %>% 
  mutate(HFnu2   = HFnu2  /   HFnu2[Event.Name=="Baseline"]-1) %>% 
  mutate(LF.HF   = LF.HF  /   LF.HF[Event.Name=="Baseline"]-1) %>%
  mutate(SDNN    = SDNN   /    SDNN[Event.Name=="Baseline"]-1) %>% 
  mutate(SDANN   = SDANN  /   SDANN[Event.Name=="Baseline"]-1) %>% 
  mutate(pNN50   = pNN50  /   pNN50[Event.Name=="Baseline"]-1) %>% 
  mutate(MADRR   = MADRR  /   MADRR[Event.Name=="Baseline"]-1) %>% 
  mutate(IRRR    = IRRR   /    IRRR[Event.Name=="Baseline"]-1) %>% 
  mutate(SDSD    = SDSD   /    SDSD[Event.Name=="Baseline"]-1) %>% 
  ungroup ->DF_rel # Baseline Substracted

DF_rel$VLF<-DF_rel$VLF*100
DF_rel$LF<-DF_rel$LF*100
DF_rel$LFnu2<-DF_rel$LFnu2*100
DF_rel$HF<-DF_rel$HF*100
DF_rel$HFnu<-DF_rel$HFnu*100
DF_rel$HFnu2<-DF_rel$HFnu2*100
DF_rel$LF.HF<-DF_rel$LF.HF*100
DF_rel$SDNN<-DF_rel$SDNN*100
DF_rel$SDANN<-DF_rel$SDANN*100
DF_rel$SDSD<-DF_rel$SDSD*100
DF_rel$IRRR<-DF_rel$IRRR*100
DF_rel$pNN50<-DF_rel$pNN50*100

#### 4. TRIM OUTLIERS ------------------------------------------------------------------------------------
plotflag <- 0
IQR_level <- 1.5
dfl$SDNN <- constrain_outliers(-dfl$SDNN,IQR_level,plotflag,'SDNN'); dfl$SDNN<-dfl$SDNN*-1
constrain_outliers(-dfl$LFnu,IQR_level,plotflag,'XX')
dfl$LFnu <- constrain_outliers(-dfl$LFnu,IQR_level,plotflag,'LFnu'); dfl$LFnu<-dfl$LFnu*-1
constrain_outliers(-dfl$SDSD,IQR_level,plotflag,'XX')
dfl$SDSD <- constrain_outliers(-dfl$SDSD,IQR_level,plotflag,'SDSD'); dfl$SDSD<-dfl$SDSD*-1
constrain_outliers(-dfl$IRRR,IQR_level,plotflag,'XX')
dfl$IRRR <- constrain_outliers(-dfl$IRRR,IQR_level,plotflag,'IRRR'); dfl$IRRR<-dfl$IRRR*-1
constrain_outliers(-dfl$pNN50,IQR_level,plotflag,'XX')
dfl$pNN50 <- constrain_outliers(-dfl$pNN50,IQR_level,plotflag,'pNN50'); dfl$pNN50<-dfl$pNN50*-1

# TRIM away the baseline
DF_rel <-dplyr::filter(DF_rel,Event.Name!='Baseline')
DF_rel$Condition<-factor(DF_rel$Event.Name,levels = c('Silence','Music'))
DF_rel$Event.Name<-factor(DF_rel$Event.Name,levels = c('Silence','Music'))


#### DESCRIBE -----------------------------------------------------------------------------

m <- DF_rel %>%
  dplyr::group_by(Empathy,Event.Name) %>%
  dplyr::summarise(n=n(),VLF_M=mean(VLF,na.rm = TRUE),VLF_SE=sd(VLF,na.rm = TRUE)/sqrt(n), HF_M=mean(HF,na.rm = TRUE),HF_SE=sd(HF,na.rm = TRUE)/sqrt(n), LF_M=mean(LF,na.rm = TRUE),LF_SE=sd(LF,na.rm = TRUE)/sqrt(n), LF.HF_M=mean(LF.HF,na.rm = TRUE),LF.HF_SE=sd(LF.HF,na.rm = TRUE)/sqrt(n),SDNN_M=mean(SDNN,na.rm = TRUE),SDNN_SE=sd(SDNN,na.rm = TRUE)/sqrt(n))

print(knitr::kable(m,digits = 3,caption = 'Table S2. Means and standard errors of all HRV measures.'))


#### CONTRASTS -----------------------------------------------------------------------------
Music_High   = c(0, 1, 0, 0)
Music_Low    = c(0, 0, 0, 1)
Silence_High = c(1, 0, 0, 0)
Silence_Low =  c(0, 0, 1, 0)

# SDNN, LF, HF, LF.HF
#names(DF_rel)

#### SDNN -------------------------------------------------------------------------------
m1 <- lmer(SDNN ~ Event.Name * Empathy + (1|ID) + (1|Session), data=DF_rel) 
#print(summary(m1,correlation=FALSE))
em2 <- emmeans(m1,specs = ~ Event.Name * Empathy) #     t.ratio p.value

cat("### SDNN")
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Silence - Low Empathy" = Silence_High - Silence_Low)),digits = 3,caption = 'SDNN contrasts.'))  #  0.379   0.7059 
print(knitr::kable(contrast(em2,method=list("Music - High Empathy vs Music - Low Empathy" = Music_High - Music_Low)),digits = 3))    # 2.159   0.0353
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Music - High Empathy" = Silence_High - Music_High)),digits = 3)) # 0.134   0.8936
print(knitr::kable(contrast(em2,method=list("Silence - Low Empathy vs Music - Low Empathy" = Silence_Low - Music_Low)),digits = 3))     # -0.695  0.4896  

#### LF -------------------------------------------------------------------------------
m1 <- lmer(LFnu ~ Event.Name * Empathy + (1|ID) + (1|Session), data=DF_rel) 
#print(summary(m1,correlation=FALSE))
em2 <- emmeans(m1,specs = ~ Event.Name * Empathy) #   t.ratio p.value

cat("### LF")
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Silence - Low Empathy" = Silence_High - Silence_Low)),digits = 3,caption = 'LF contrasts.'))  #  0.379   0.7059 
print(knitr::kable(contrast(em2,method=list("Music - High Empathy vs Music - Low Empathy" = Music_High - Music_Low)),digits = 3))    # 2.159   0.0353
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Music - High Empathy" = Silence_High - Music_High)),digits = 3)) # 0.134   0.8936
print(knitr::kable(contrast(em2,method=list("Silence - Low Empathy vs Music - Low Empathy" = Silence_Low - Music_Low)),digits = 3))     # -0.695  0.4896  

#### HF -------------------------------------------------------------------------------
m1 <- lmer(HFnu ~ Event.Name * Empathy + (1|ID) + (1|Session), data=DF_rel) 
#print(summary(m1,correlation=FALSE))
em2 <- emmeans(m1,specs = ~ Event.Name * Empathy) #   t.ratio p.value

cat("### HF")
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Silence - Low Empathy" = Silence_High - Silence_Low)),digits = 3,caption = 'HF contrasts.'))  #  0.379   0.7059 
print(knitr::kable(contrast(em2,method=list("Music - High Empathy vs Music - Low Empathy" = Music_High - Music_Low)),digits = 3))    # 2.159   0.0353
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Music - High Empathy" = Silence_High - Music_High)),digits = 3)) # 0.134   0.8936
print(knitr::kable(contrast(em2,method=list("Silence - Low Empathy vs Music - Low Empathy" = Silence_Low - Music_Low)),digits = 3))     # -0.695  0.4896  

#### LF.HF -------------------------------------------------------------------------------
m1 <- lmer(LF.HF ~ Event.Name * Empathy + (1|ID) + (1|Session), data=DF_rel) 
#print(summary(m1,correlation=FALSE))
em2 <- emmeans(m1,specs = ~ Event.Name * Empathy) #     t.ratio p.value

cat("### LF/HF")
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Silence - Low Empathy" = Silence_High - Silence_Low)),digits = 3,caption = 'LF/HF contrasts.'))  #  0.379   0.7059 
print(knitr::kable(contrast(em2,method=list("Music - High Empathy vs Music - Low Empathy" = Music_High - Music_Low)),digits = 3))    # 2.159   0.0353
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Music - High Empathy" = Silence_High - Music_High)),digits = 3)) # 0.134   0.8936
print(knitr::kable(contrast(em2,method=list("Silence - Low Empathy vs Music - Low Empathy" = Silence_Low - Music_Low)),digits = 3))     # -0.695  0.4896  
