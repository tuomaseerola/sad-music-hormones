# figure1.R
#### COMBINE PLOTS ----------------------------------------------------------------
plotflag <- FALSE
library("cowplot")
# 1: PRL
# 2: OXY
# 3: Mood

#G <- plot_grid(panel_a, panel_b, panel_c, panel_d, labels = c("a", "b", "c", "d"), ncol = 4, nrow = 1)
G <- plot_grid(panel_c, panel_a, panel_b, labels = c("a", "b", "c"), ncol = 3, nrow = 1)
print(G)

# Make pdf
if(plotflag==TRUE){
#  ggsave(filename = 'figure1.pdf',G,device = 'pdf',height = 4,width = 15)
  ggsave(filename = 'figure1.pdf',G,device = 'pdf',height = 4,width = 12)
}
