#### 1. LIBRARIES AND FUNCTIONS --------------------------------------------------------
library(lme4)
library(lmerTest)
library(emmeans)
lmerTest.limit = 20000
library(OutlierDetection)
source('constrain_outliers.R')
source('outlierDetection.R')

#### 2. DATA --------------------------------------------------------
df <- read.csv('aggregate_data.csv')

#### 2. TRANSFORM  --------------------------------------------------------
dfl<-df
C <- 1 # Convert to log transformation
dfl$PRL     <-log(C+df$PRL)
dfl$CRT     <-log(C+df$CRT)
dfl$CRP     <-log(C+df$CRP)
dfl$ACTH    <-log(C+df$ACTH)
dfl$OXY     <-log(C+df$OXY)

##### 3 . CHECK WHETHER THERE ARE BASELINE DIFFERENCES --------------------------
dfl_baseline <- dplyr::filter(dfl,Condition=='Baseline')
m <- aov(PRL ~ EMPATHY, data=dfl_baseline); em <- emmeans(m,specs = ~EMPATHY); print(knitr::kable(pairs(em),digits=3,caption = 'PRL Baseline'))
m <- aov(OXY ~ EMPATHY, data=dfl_baseline); em <- emmeans(m,specs = ~EMPATHY); print(knitr::kable(pairs(em),digits=3,caption = 'OXY Baseline'))
m <- aov(CRT ~ EMPATHY, data=dfl_baseline); em <- emmeans(m,specs = ~EMPATHY); print(knitr::kable(pairs(em),digits=3,caption = 'CRT Baseline'))
m <- aov(ACTH ~ EMPATHY, data=dfl_baseline); em <- emmeans(m,specs = ~EMPATHY); print(knitr::kable(pairs(em),digits=3,caption = 'ACTH Baseline'))
m <- aov(CRP ~ EMPATHY, data=dfl_baseline); em <- emmeans(m,specs = ~EMPATHY); print(knitr::kable(pairs(em),digits=3,caption = 'CRP Baseline'))

##### 3. BASELINE SUBTRACTION  -------------------------------------------------
library(tidyverse)

# As percentage change
dfl %>% 
  group_by(ID) %>% 
  mutate(PRL      = PRL      / PRL     [Condition=="Baseline"] -1) %>%
  mutate(OXY      = OXY      / OXY     [Condition=="Baseline"] -1) %>%
  mutate(CRT      = CRT      / CRT     [Condition=="Baseline"] -1) %>%
  mutate(CRP      = CRP      / CRP     [Condition=="Baseline"] -1) %>%
  mutate(ACTH     = ACTH     / ACTH    [Condition=="Baseline"] -1) %>%
  ungroup ->df_rel # Baseline Substracted

df_rel$PRL<-  df_rel$PRL*100
df_rel$OXY<-  df_rel$OXY*100
df_rel$CRT<-  df_rel$CRT*100
df_rel$CRP<-  df_rel$CRP*100
df_rel$ACTH<- df_rel$ACTH*100

# remove baseline
df_rel <-dplyr::filter(df_rel,Condition!='Baseline')
df_rel$Condition<-factor(df_rel$Condition,levels = c('Silence','Music'))
df_rel$Session<-factor(df_rel$Session)

#### 4. TRIM OUTLIERS ------------------------------------------------------------------------------------

plotflag <- 0
IQR_level <- 1.5
remove_decision <- FALSE

# relative
constrain_outliers(df_rel$PRL,IQR_level,plotflag,'PRL',remove = remove_decision) # yes 4 
constrain_outliers(-df_rel$PRL,IQR_level,plotflag,'OXY',remove = remove_decision) # yes 1
constrain_outliers(df_rel$OXY,IQR_level,plotflag,'OXY',remove = remove_decision) # yes 5
constrain_outliers(-df_rel$OXY,IQR_level,plotflag,'OXY',remove = remove_decision) # yes 3
constrain_outliers(df_rel$CRT,IQR_level,plotflag,'CRT',remove = remove_decision) # yes 2
constrain_outliers(df_rel$CRP,IQR_level,plotflag,'CRP',remove = remove_decision) # yes 17
constrain_outliers(df_rel$ACTH,IQR_level,plotflag,'ACTH',remove = remove_decision) # no 0

df_rel$PRL <- constrain_outliers(df_rel$PRL,IQR_level,0,'PRL',remove = remove_decision)
df_rel$PRL <- constrain_outliers(-df_rel$PRL,IQR_level,0,'PRL',remove = remove_decision); df_rel$PRL<-df_rel$PRL*-1; 
df_rel$OXY <- constrain_outliers(df_rel$OXY,IQR_level,0,'OXY',remove = remove_decision)
df_rel$OXY <- constrain_outliers(-df_rel$OXY,IQR_level,0,'OXY',remove = remove_decision); df_rel$OXY<-df_rel$OXY*-1 
df_rel$CRP <- constrain_outliers(df_rel$CRP,IQR_level,0,'CRP',remove = remove_decision)
df_rel$ACTH <- constrain_outliers(df_rel$ACTH,IQR_level,0,'ACTH',remove = remove_decision)

#boxplot(OXY ~ Condition + EMPATHY,data=df_rel)
#boxplot(OXY15~ Condition + EMPATHY,data=df_rel)

#print(dim(df_rel))
df_rel$EMPATHY<-factor(df_rel$EMPATHY)

# Define Contrasts
Music_High =   c(0, 1, 0, 0)
Music_Low =    c(0, 0, 0, 1)
Silence_High = c(1, 0, 0, 0)
Silence_Low =  c(0, 0, 1, 0)

#### PANEL a: PRL ---------------------------------------------------------------------------------------------
m1 <- lmer(PRL ~ Condition * EMPATHY + (1|ID) + (1|Session), data=df_rel) # relative
em2 <- emmeans(m1,specs = ~ Condition * EMPATHY) #
# This is Between Group comparison                                     estimate     SE df t.ratio p.value
cat("## PRL")
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Silence - Low Empathy" = Silence_High - Silence_Low)),digits = 3,caption = 'Prolactin contrasts.'))#    -2.39 1.73 71.8 -1.381  0.1716 
print(knitr::kable(contrast(em2,method=list("Music - High Empathy vs Music - Low Empathy" = Music_High - Music_Low)),digits = 3))        #    -4.25 1.73 71.8 -2.454  0.0166  
# Within group comparison 
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Music - High Empathy" = Silence_High - Music_High)),digits = 3))  #       2.3 0.727 59 3.168   0.0024 
print(knitr::kable(contrast(em2,method=list("Silence - Low Empathy vs Music - Low Empathy" = Silence_Low - Music_Low)),digits = 3))      #     0.445 0.751 59 0.592   0.5562

# Show the means and deviations
library(dplyr)
S <- df_rel %>%
  dplyr::group_by(EMPATHY,Condition) %>%
  dplyr::summarise(n=n(),m=mean(PRL,na.rm = TRUE),sd=sd(PRL,na.rm = TRUE)) %>%
  dplyr::mutate(se=sd/sqrt(n),LCI=m+qnorm(0.025)*se,UCI=m+qnorm(0.975)*se) 

## Create plot
S$UCI<- 0

pd<-position_dodge(1)
theme_fs <- function(fs=18){
  tt <- theme(axis.text = element_text(size=fs-1, colour=NULL)) + 
    theme(legend.text = element_text(size=fs, colour=NULL)) + 
    theme(legend.title = element_text(size=fs, colour=NULL)) + 
    theme(axis.title = element_text(size=fs, colour=NULL)) + 
    theme(legend.text = element_text(size=fs, colour=NULL))
  return <- tt
}

custom_theme_size <- theme_fs(12)
library(RColorBrewer)
pal<-brewer.pal(3, name="Set1")

ymax<-11
pval_lines<-c(ymax*.25,ymax*.50,ymax*.75)
pval_lines_text<-c(ymax*.30,ymax*.55,ymax*.80)

panel_a <- ggplot(S,aes(x=Condition,y=m,fill=EMPATHY))+
  geom_errorbar(aes(ymin=LCI,ymax=UCI), width=0.50,position = pd,colour='black',size=0.5,show.legend = FALSE)+
  geom_col(position = pd,show.legend = FALSE,colour='black')+
  scale_fill_brewer(type = 'qual', palette = 'Set1')+
  xlab("") +
  ylab("Change in Prolactin from Baseline (%)") +
  geom_hline(yintercept = 0,size=1,colour='black')+
  theme(legend.key = element_rect(colour = "white")) + 
  theme_classic()+
  theme(plot.title = element_text(hjust = 0.5))+
  annotate("segment", x = 0.8, xend = 1.2, y = pval_lines[1], yend = pval_lines[1], colour = "black")+
  annotate("segment", x = 1.8, xend = 2.2, y = pval_lines[1], yend = pval_lines[1], colour = "black")+
  annotate("segment", x = 0.8, xend = 1.8, y = pval_lines[2], yend = pval_lines[2], colour = pal[1])+
  annotate("segment", x = 1.2, xend = 2.2, y = pval_lines[3], yend = pval_lines[3], colour = pal[2])+
  annotate("text", x = 1, y = pval_lines_text[1], label = "P=0.172",size=3)+
  annotate("text", x = 2, y = pval_lines_text[1], label = "P=0.017",size=3)+
  annotate("text", x = (0.8+1.8)/2, y = pval_lines_text[2], label = "P=0.002 ",size=3, colour = pal[1])+
  annotate("text", x = (1.2+2.2)/2, y = pval_lines_text[3], label = "P=0.556",size=3, colour = pal[2])+
  scale_y_continuous(breaks=seq(-10,10,by=5),limits = c(-11,11))+ 
  custom_theme_size

print(panel_a)

#### PANEL b: OXY ---------------------------------------------------------------------------------------------

m1 <- lmer(OXY ~ Condition * EMPATHY + (1|ID) + (1|Session), data=df_rel) # Relative
em2 <- emmeans(m1,specs = ~ Condition * EMPATHY) #
# This is Between Groups                           estimate     SE df t.ratio p.value
cat("## OXY")
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Silence - Low Empathy" = Silence_High - Silence_Low)),digits = 3,caption = 'Oxytocin contrasts.')) #   3.16 4.4 104 0.717   0.4750 
print(knitr::kable(contrast(em2,method=list("Music - High Empathy vs Music - Low Empathy" = Music_High - Music_Low)),digits = 3))         #  -9.7 4.4 104 -2.205  0.0297
# WITHIN GROUPS
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Music - High Empathy" = Silence_High - Music_High)),digits = 3))   #  8.03 3.39 59.1 2.370   0.0211 
print(knitr::kable(contrast(em2,method=list("Silence - Low Empathy vs Music - Low Empathy" = Silence_Low - Music_Low)),digits = 3))       # -4.83 3.5 59.1 -1.381  0.1724

library(dplyr)
S <- df_rel %>%
  dplyr::group_by(EMPATHY,Condition) %>%
  dplyr::summarise(n=n(),m=mean(OXY,na.rm = TRUE),sd=sd(OXY,na.rm = TRUE)) %>%
  dplyr::mutate(se=sd/sqrt(n),LCI=m+qnorm(0.025)*se,UCI=m+qnorm(0.975)*se) 

S$UCI[1]<- 0.00
S$UCI[2]<- 0.00
S$UCI[3]<- 0.00
S$LCI[4]<- 0.00

ymax<-15.5
pval_lines<-c(ymax*.25,ymax*.50,ymax*.75)
pval_lines_text<-c(ymax*.30,ymax*.55,ymax*.80)

panel_b <- ggplot(S,aes(x=Condition,y=m,fill=EMPATHY))+
  geom_errorbar(aes(ymin=LCI,ymax=UCI), width=0.50,position = pd,colour='black',size=0.5,show.legend = FALSE)+
  geom_col(position = pd,show.legend = FALSE,colour='black')+
  scale_fill_brewer(type = 'qual', palette = 'Set1')+
  xlab("") +
  ylab("Change in Oxytocin from Baseline (%)") +
  geom_hline(yintercept = 0,size=1,colour='black')+
  #  ggtitle("PRL") + 
  theme(legend.key = element_rect(colour = "white")) + 
  theme_classic()+
  theme(plot.title = element_text(hjust = 0.5))+
  annotate("segment", x = 0.8, xend = 1.2, y = pval_lines[1], yend = pval_lines[1], colour = "black")+
  annotate("segment", x = 1.8, xend = 2.2, y = pval_lines[1], yend = pval_lines[1], colour = "black")+
  annotate("segment", x = 0.8, xend = 1.8, y = pval_lines[2], yend = pval_lines[2], colour = pal[1])+
  annotate("segment", x = 1.2, xend = 2.2, y = pval_lines[3], yend = pval_lines[3], colour = pal[2])+
  annotate("text", x = 1, y = pval_lines_text[1], label = "P=0.475",size=3)+
  annotate("text", x = 2, y = pval_lines_text[1], label = "P=0.030",size=3)+
  annotate("text", x = (0.8+1.8)/2, y = pval_lines_text[2], label = "P=0.021",size=3, colour = pal[1])+
  annotate("text", x = (1.2+2.2)/2, y = pval_lines_text[3], label = "P=0.172",size=3, colour = pal[2])+
  scale_y_continuous(breaks=seq(-15,15,by=5),limits = c(-15.5,15.5))+ # labels = scales::number_format(accuracy = 0.1)
  custom_theme_size

print(panel_b)

#### CRT ---------------------------------------------------------------------------------------------
m1 <- lmer(CRT ~ Condition * EMPATHY + (1|ID) + (1|Session), data=df_rel) # Relative
em2 <- emmeans(m1,specs = ~ Condition * EMPATHY) #
# This is Between Groups                               estimate     SE df t.ratio p.value
cat("## CRT")
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Silence - Low Empathy" = Silence_High - Silence_Low)),digits = 3,caption = 'Cortisol contrasts.'))#   -0.196 0.713 82.3 -0.275  0.7836 
print(knitr::kable(contrast(em2,method=list("Music - High Empathy vs Music - Low Empathy" = Music_High - Music_Low)),digits = 3))    #  -1.1 0.713 82.3 -1.539  0.1276
# WITHIN GROUPS
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Music - High Empathy" = Silence_High - Music_High)),digits = 3)) #  0.57 0.4 59 1.425   0.1593 
print(knitr::kable(contrast(em2,method=list("Silence - Low Empathy vs Music - Low Empathy" = Silence_Low - Music_Low)),digits = 3))   # -0.332 0.413 59 -0.803  0.4252

library(dplyr)
S <- df_rel %>%
  dplyr::group_by(EMPATHY,Condition) %>%
  dplyr::summarise(n=n(),m=mean(CRT,na.rm = TRUE),sd=sd(CRT,na.rm = TRUE)) %>%
  dplyr::mutate(se=sd/sqrt(n),LCI=m+qnorm(0.025)*se,UCI=m+qnorm(0.975)*se) 

knitr::kable(S,digits = 3)

#### ACTH ---------------------------------------------------------------------------------------------
m1 <- lmer(ACTH ~ Condition * EMPATHY + (1|ID) + (1|Session), data=df_rel) # Relative
em2 <- emmeans(m1,specs = ~ Condition * EMPATHY) #
# This is Between Groups                              estimate     SE df t.ratio p.value
cat("## ACTH")
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Silence - Low Empathy" = Silence_High - Silence_Low)),digits = 3,caption = 'ACTH contrasts.'))#   -1.13 2.53 78.4 -0.448  0.6555 
print(knitr::kable(contrast(em2,method=list("Music - High Empathy vs Music - Low Empathy" = Music_High - Music_Low)),digits = 3))    #  -0.983 2.53 78.4 -0.389  0.6983 
# WITHIN GROUPS
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Music - High Empathy" = Silence_High - Music_High)),digits = 3)) #  0.226 1.3 59 0.174   0.8622
print(knitr::kable(contrast(em2,method=list("Silence - Low Empathy vs Music - Low Empathy" = Silence_Low - Music_Low)),digits = 3))   # 0.375 1.34 59 0.280   0.7808 

library(dplyr)
S <- df_rel %>%
  dplyr::group_by(EMPATHY,Condition) %>%
  dplyr::summarise(n=n(),m=mean(ACTH,na.rm = TRUE),sd=sd(ACTH,na.rm = TRUE)) %>%
  dplyr::mutate(se=sd/sqrt(n),LCI=m+qnorm(0.025)*se,UCI=m+qnorm(0.975)*se) 

knitr::kable(S,digits = 3)

#### CRP ---------------------------------------------------------------------------------------------
m1 <- lmer(CRP ~ Condition * EMPATHY + (1|ID) + (1|Session), data=df_rel) # Relative
em2 <- emmeans(m1,specs = ~ Condition * EMPATHY) #
# This is Between Groups                                estimate     SE df t.ratio p.value
cat("## CRP")
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Silence - Low Empathy" = Silence_High - Silence_Low)),digits = 3, caption = 'CRP contrasts.'))#   0.676 1.34 73 0.506   0.6144 
print(knitr::kable(contrast(em2,method=list("Music - High Empathy vs Music - Low Empathy" = Music_High - Music_Low)),digits = 3))    #  2.27 1.34 73 1.700   0.0934 
# WITHIN GROUPS
print(knitr::kable(contrast(em2,method=list("Silence - High Empathy vs Music - High Empathy" = Silence_High - Music_High)),digits = 3)) #  -1.14 0.588 59.2 -1.939  0.0573 
print(knitr::kable(contrast(em2,method=list("Silence - Low Empathy vs Music - Low Empathy" = Silence_Low - Music_Low)),digits = 3))   # 0.456 0.607 59.2 0.751   0.4556 

library(dplyr)
S <- df_rel %>%
  dplyr::group_by(EMPATHY,Condition) %>%
  dplyr::summarise(n=n(),m=mean(CRP,na.rm = TRUE),sd=sd(CRP,na.rm = TRUE)) %>%
  dplyr::mutate(se=sd/sqrt(n),LCI=m+qnorm(0.025)*se,UCI=m+qnorm(0.975)*se) 

knitr::kable(S,digits = 3)
