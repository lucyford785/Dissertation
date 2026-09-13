#NB: run after ASJP_stats_clean (data imports and initial analysis)

library(dplyr)
library(tidyverse)
library(mco) 
library(ggplot2) 
library(plotly)
library(purrr)

#set seed for sampling reproducability
set.seed(12)

#rename for interpretability
df$Macroarea<-df$Macroarea.y

pareto_sample<-function(df){
  #strat sampling - Family:
  sampled_df<-df%>%
    group_by(Family)%>%
    sample_n(1) #size of smallest group
  sampled_df%>%count(Family)
  
  #ss - glottocode:
  sampled_df_2<-sampled_df%>%
    group_by(Glottocode)%>%
    sample_n(1)
  
  #clean df to numerical values only
  sampled_df_2%>%
    select(Glottocode, Family, Macroarea, Phon_Inv_Size, Word_length_syll, Mean_cluster_length)

}

pareto_1k<-replicate(1000, pareto_sample(df), simplify=FALSE)
pareto_df<-as.data.frame(pareto_1k)%>%
    group_by(Glottocode, Family, Macroarea)%>%
    summarise_at(vars("Phon_Inv_Size", "Word_length_syll", "Mean_cluster_length"), mean)
  

#by default all variables minimised
best<-paretoFilter(as.matrix(pareto_df))
best<-as.data.frame(best)
best$Word_length_syll<-as.numeric(best$Word_length_syll)
best$Phon_Inv_Size<-as.numeric(best$Phon_Inv_Size)
best$Mean_cluster_length<-as.numeric(best$Mean_cluster_length)

#3D, grouped by family
plot_ly(
  data=as.data.frame(best),
  x=~Phon_Inv_Size, 
  y=~Mean_cluster_length, 
  z=~Word_length_syll,
  text=~Glottocode,
  color = ~Family,
  type='scatter3d', 
  mode='markers')%>%
  layout(title = "Pareto optimal solutions to the tradeoff between syllable complexity, word length (syllables), and phoneme inventory size (Grouped by language family)")

#3D, grouped by Macroarea
plot_ly(
  data=as.data.frame(best),
  x=~Phon_Inv_Size, 
  y=~Mean_cluster_length, 
  z=~Word_length_syll,
  text=~Glottocode,
  color = ~Macroarea,
  type='scatter3d', 
  mode='markers')%>%
  layout(title = "Pareto optimal solutions to the tradeoff between syllable complexity, word length (syllables), and phoneme inventory size (Grouped by macroarea)")

#2D slices:
plot_ly(
  data=best,
  x=~Phon_Inv_Size, 
  y=~Mean_cluster_length, 
  text=~Glottocode,
  color = ~Macroarea,
  type='scatter', 
  mode='markers')%>%
  layout(title = "Pareto optimal solutions to the tradeoff between syllable complexity and phoneme inventory size (Grouped by macroarea)")


plot_ly(
  data=as.data.frame(best),
  x=~Word_length_syll, 
  y=~Mean_cluster_length, 
  text=~Glottocode,
  color = ~Macroarea,
  type='scatter', 
  mode='markers')%>%
  layout(title = "Pareto optimal solutions to the tradeoff between syllable complexity and word length (syllables) (Grouped by macroarea)")

plot_ly(
  data=as.data.frame(best),
  x=~Word_length_syll, 
  y=~Phon_Inv_Size, 
  text=~Glottocode,
  color = ~Macroarea,
  type='scatter', 
  mode='markers'
  )%>%
  layout(title = "Pareto optimal solutions to the tradeoff between word length (syllables) and phoneme inventory size (Grouped by macroarea)")


#extra measures:
best%>%
  count(Macroarea)

best%>%
  count(Family)

df%>%count(Macroarea.y)