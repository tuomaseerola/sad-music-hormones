# manova_emotion_scales.R
library(tidyverse)

emotions<-read.csv('emotions.csv',header = TRUE)
emotions<-dplyr::select(emotions,-X)
head(emotions)

# collapse
library(reshape2)
m <- melt(emotions,id.vars = c('Participant','Empathy'))
m$Empathy<-factor(m$Empathy)
m$Participant<-factor(m$Participant)

library(lme4)
library(lmerTest)
m0 <- lmer(value ~ as.numeric(variable)*as.numeric(Empathy) + (1|Participant),data=m)
s<-summary(m0,corr=FALSE)
print(knitr::kable(s$coefficients,digits = 3,caption = 'MANOVA across emotions (variable) and Emapthy.'))
# Fixed effects:
#Estimate Std. Error      df t value Pr(>|t|)    
#  (Intercept)                                33.149     11.113 304.586   2.983 0.003086 ** 
#  as.numeric(variable)                       12.741      3.265 246.000   3.902 0.000123 ***
#  as.numeric(Empathy)                        -6.115      7.097 304.586  -0.862 0.389621    
#   as.numeric(variable):as.numeric(Empathy)   -1.410      2.085 246.000  -0.676 0.499511   

m1 <- lmer(value ~ variable * Empathy + (1|Participant), data=m)
summary(m1,corr=FALSE)

library(emmeans)
m1 <- lmer(value ~ variable + Empathy + (1|Participant), data=m)
m1
em1<-emmeans(m1,specs = 'variable')
em1
pairs(em1)
#### xxxxxx ---------------------------------------
m1 <- lmer(value ~ variable * Empathy + (1|Participant), data=m)
summary(m1,corr=FALSE)
head(m)
table(m$variable)

em1<-emmeans(m1,specs = ~ Empathy | variable)
em1
print(knitr::kable(pairs(em1),digits = 3, caption = 'Comparison of Empathy groups across emotions scales.'))


library(dplyr)
S1 <- m %>%
  dplyr::group_by(variable,Empathy) %>%
  dplyr::summarise(n=n(),m=mean(value,na.rm = TRUE),sd=sd(value,na.rm = TRUE)) %>%
  dplyr::mutate(se=sd/sqrt(n),LCI=m+qnorm(0.025)*se,UCI=m+qnorm(0.975)*se) 

print(knitr::kable(S1,digits = 3,caption='Self-report means across empathy groups.'))


rm(m0,m1,em1,m)
