# mood_screening.R
library(ggplot2)
library(emmeans)
library(lme4)
library(tidyverse)


mood<-read.csv('mood_and_emotions.csv')
mood<-dplyr::select(mood,-X)
mood$Condition<-factor(mood$Condition)
mood$Empathy<-factor(mood$Empathy)

#mood$neg2 <- (mood$jarkyttynyt + mood$peloissaan + mood$surullinen + mood$vihamielinen + mood$hapeissaan + mood$hermostunut + mood$ahdistunut)/7
mood$neg <- (mood$jarkyttynyt + mood$peloissaan + mood$vihamielinen + mood$hapeissaan + mood$hermostunut + mood$ahdistunut)/6
#mood$pos2 <- (mood$valpas + mood$inspiroitunut + mood$paattavainen + mood$liikuttunut + mood$tarkkaavainen + mood$aktiivinen + mood$rentoutunut)/7

#### BASELINE DIFFERENCES? ---------------------------------------------------------------------------------------------
mood_baseline <-dplyr::filter(mood,Condition=='Baseline')
m <- aov(neg ~ Empathy, data=mood_baseline)
#print(summary(m1,correlation=FALSE))
em2 <- emmeans::emmeans(m,specs = ~ Empathy) #
print(knitr::kable(pairs(em2)))

d<-eff_size(em2,sigma = stats::sigma(m),edf = stats::df.residual(m))
print(knitr::kable(d))

m <- aov(pos ~ Empathy, data=mood_baseline)# works
#print(summary(m1,correlation=FALSE))
em2 <- emmeans::emmeans(m,specs = ~ Empathy) #
print(knitr::kable(pairs(em2)))


#### POS MOOD ---------------------------------------------------------------------------------------------

mood %>% 
  group_by(ID) %>% 
  mutate(pos      = pos      / pos     [Condition=="Baseline"] -1) %>%
  mutate(neg     = neg     / neg    [Condition=="Baseline"] -1) %>%
  ungroup ->mood_rel # Baseline Substracted

mood_rel$pos<-mood_rel$pos*100
mood_rel$neg<-mood_rel$neg*100

# remove baseline
dim(mood_rel)
mood_rel_t <-dplyr::filter(mood_rel,Condition!='Baseline')
dim(mood_rel_t)
mood_rel_t$Condition<-factor(mood_rel_t$Condition,levels = c('Silence','Music'))
names(mood_rel_t)[names(mood_rel_t)=='Sessio']<-'Session'
mood_rel_t$Session<-factor(mood_rel_t$Session-1)
names(mood_rel_t)
mood_rel_t$Empathy<-factor(mood_rel_t$Empathy,levels = c('HIGH','LOW'))

library(dplyr)
S_pos <- mood_rel_t %>%
  dplyr::group_by(Empathy,Condition) %>%
  dplyr::summarise(n=n(),m=mean(pos,na.rm = TRUE),sd=sd(pos,na.rm = TRUE)) %>%
  dplyr::mutate(se=sd/sqrt(n),LCI=m+qnorm(0.025)*se,UCI=m+qnorm(0.975)*se) 

S_neg <- mood_rel_t %>%
  dplyr::group_by(Empathy,Condition) %>%
  dplyr::summarise(n=n(),m=mean(neg,na.rm = TRUE),sd=sd(neg,na.rm = TRUE)) %>%
  dplyr::mutate(se=sd/sqrt(n),LCI=m+qnorm(0.025)*se,UCI=m+qnorm(0.975)*se) 

#### Contrasts --------------------------

Music_High =   c(0, 1, 0, 0)
Music_Low =    c(0, 0, 0, 1)
Silence_High = c(1, 0, 0, 0)
Silence_Low =  c(0, 0, 1, 0)

#### Negative Moods
cat("## Negative moods")
print(knitr::kable(S_neg,digits = 3,caption = 'Neg. moods across conditions and groups.'))

m1 <- lme4::lmer(neg ~ Condition * Empathy + (1|ID), data=mood_rel_t)# works
#print(summary(m1,correlation=FALSE))

em2 <- emmeans::emmeans(m1,specs = ~ Condition * Empathy) #
em2

#print(knitr::kable(em2))
##### BETWEEN GROUPS----------------
# This is Between Group comparison for Music           estimate     SE df t.ratio p.value
print(knitr::kable(emmeans::contrast(em2,method=list("Silence - High Empathy vs Silence - Low Empathy" = Silence_High - Silence_Low)),digits = 3,caption = 'Pos. mood in Silence.'))
print(knitr::kable(emmeans::contrast(em2,method=list("Music - High Empathy vs Music - Low Empathy" = Music_High - Music_Low)),digits = 3,caption = 'Pos. mood in Music'))   #      12.8  5 114 2.563   0.0117 
##### WITHIN GROUPS ----------------
print(knitr::kable(emmeans::contrast(em2,method=list("Silence - High Empathy vs Music - High Empathy" = Silence_High - Music_High)),digits = 3,caption = 'Pos. mood in High Empathy')) #  -12.9 4.4 60.1 -2.924  0.0049 
print(knitr::kable(emmeans::contrast(em2,method=list("Silence - Low Empathy vs Music - Low Empathy" = Silence_Low - Music_Low)),digits = 3,caption = 'Pos. mood in Low Empathy'))   # 0.631 4.5 59.1 0.140   0.8890 


#### Positive moods -------------------------------------
cat("## Positive moods")
print(knitr::kable(S_pos,digits = 3,caption = 'Pos. moods across conditions and groups.'))

m1 <- lme4::lmer(pos ~ Condition * Empathy + (1|ID), data=mood_rel_t)# works
#print(summary(m1,correlation=FALSE))

em2 <- emmeans::emmeans(m1,specs = ~ Condition * Empathy) #
#print(knitr::kable(em2))
##### BETWEEN GROUPS----------------
# This is Between Group comparison for Music           estimate     SE df t.ratio p.value
print(knitr::kable(emmeans::contrast(em2,method=list("Silence - High Empathy vs Silence - Low Empathy" = Silence_High - Silence_Low)),digits = 3,caption = 'Pos. mood in Silence.'))#   -0.681 5.04 114 -0.135  0.8928 
print(knitr::kable(emmeans::contrast(em2,method=list("Music - High Empathy vs Music - Low Empathy" = Music_High - Music_Low)),digits = 3,caption = 'Pos. mood in Music'))   #      12.8  5 114 2.563   0.0117 
##### WITHIN GROUPS ----------------
print(knitr::kable(emmeans::contrast(em2,method=list("Silence - High Empathy vs Music - High Empathy" = Silence_High - Music_High)),digits = 3,caption = 'Pos. mood in High Empathy')) #  -12.9 4.4 60.1 -2.924  0.0049 
print(knitr::kable(emmeans::contrast(em2,method=list("Silence - Low Empathy vs Music - Low Empathy" = Silence_Low - Music_Low)),digits = 3,caption = 'Pos. mood in Low Empathy'))   # 0.631 4.5 59.1 0.140   0.8890 

S_pos
#### PLOT positive moods
S<-S_pos
S$UCI[1]<- 0.00
S$LCI[2]<- 0.00
S$UCI[3]<- 0.00
S$UCI[4]<- 0.00

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


ymax<-20
pval_lines<-c(ymax*.25,ymax*.50,ymax*.75)
pval_lines_text<-c(ymax*.30,ymax*.55,ymax*.80)

panel_c <- ggplot(S,aes(x=Condition,y=m,fill=Empathy))+
  geom_errorbar(aes(ymin=LCI,ymax=UCI), width=0.50,position = pd,colour='black',size=0.5,show.legend = FALSE)+
  geom_col(position = pd,show.legend = FALSE,colour='black')+
  scale_fill_brewer(type = 'qual', palette = 'Set1')+
  xlab("") +
  ylab("Change in Pos. mood from Baseline (%)") +
  geom_hline(yintercept = 0,size=1,colour='black')+
  theme(legend.key = element_rect(colour = "white")) + 
  theme_classic()+
  theme(plot.title = element_text(hjust = 0.5))+
  annotate("segment", x = 0.8, xend = 1.2, y = pval_lines[1], yend = pval_lines[1], colour = "black")+
  annotate("segment", x = 1.8, xend = 2.2, y = pval_lines[1], yend = pval_lines[1], colour = "black")+
  annotate("segment", x = 0.8, xend = 1.8, y = pval_lines[2], yend = pval_lines[2], colour = pal[1])+
  annotate("segment", x = 1.2, xend = 2.2, y = pval_lines[3], yend = pval_lines[3], colour = pal[2])+
  annotate("text", x = 1, y = pval_lines_text[1], label = "P=0.893 ",size=3)+
  annotate("text", x = 2, y = pval_lines_text[1], label = "P=0.012",size=3)+
  annotate("text", x = (0.8+1.8)/2, y = pval_lines_text[2], label = "P=0.005 ",size=3, colour = pal[1])+
  annotate("text", x = (1.2+2.2)/2, y = pval_lines_text[3], label = "P=0.889",size=3, colour = pal[2])+
  scale_y_continuous(breaks=seq(-20,20,by=10),limits = c(-20,20))+ # labels = scales::number_format(accuracy = 0.1)
  custom_theme_size

print(panel_c)


