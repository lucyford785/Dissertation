library(dplyr)
library(tidyverse)
library(mco) #still needed?
#library(emoa) #for finding pareto optimal solutions with more control than mco
library(ggplot2)
#library(ggcube) #for 3d visualisation in ggplot2
library(plotly)
library(purrr)

set.seed(12)
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
  #count_consonants
  sampled_df_2%>%
    select(Glottocode, Family, Macroarea, Phon_Inv_Size, Word_length_syll, Mean_cluster_length)

}

pareto_1k<-replicate(1000, pareto_sample(df), simplify=FALSE) #simplify false means each iteration gets stored?
pareto_df<-as.data.frame(pareto_1k)%>%
    group_by(Glottocode, Family, Macroarea)%>%
    summarise_at(vars("Phon_Inv_Size", "Word_length_syll", "Mean_cluster_length"), mean)
  

#pareto_df<-pareto_sample(df)

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

#mcl wls
fit <- loess(
  Mean_cluster_length ~ Word_length_syll,
  data = best
)

newdat <- data.frame(
  Word_length_syll = seq(
    min(best$Word_length_syll),
    max(best$Word_length_syll),
    length.out = 200
  )
)

newdat$pred <- predict(fit, newdat)

plot_ly(
  data = best,
  x = ~Word_length_syll,
  y = ~Mean_cluster_length,
  text=~Glottocode,
  mode = "markers",
  type = "scatter"
) |>
  add_lines(
    data = newdat,
    x = ~Word_length_syll,
    y = ~pred,
    line = list(color = "red", width = 3)
  )

######### mcl wls again (pareto boundary) ########

best2 <- best[order(best$Word_length_syll), ]
plot_ly(
  data = best2,
  x = ~Word_length_syll,
  y = ~Mean_cluster_length,
  text=~Glottocode,
  mode = "markers",
  type = "scatter"
) |>
  add_lines(
    data = best2,
    x = ~Word_length_syll,
    y = ~Mean_cluster_length,
    name = "Pareto frontier",
    line = list(color = "red", width = 3)
  )

###### mcl pis ########
fit <- loess(
  Mean_cluster_length ~ Phon_Inv_Size,
  data = best
)

newdat <- data.frame(
  Phon_Inv_Size = seq(
    min(best$Phon_Inv_Size),
    max(best$Phon_Inv_Size),
    length.out = 200
  )
)

newdat$pred <- predict(fit, newdat)

plot_ly(
  data = best,
  x = ~Phon_Inv_Size,
  y = ~Mean_cluster_length,
  mode = "markers",
  type = "scatter"
) |>
  add_lines(
    data = newdat,
    x = ~Phon_Inv_Size,
    y = ~pred,
    line = list(color = "red", width = 3)
  )

###### pis wls ########
fit <- loess(
  Phon_Inv_Size ~ Word_length_syll,
  data = best
)

newdat <- data.frame(
  Word_length_syll = seq(
    min(best$Word_length_syll),
    max(best$Word_length_syll),
    length.out = 200
  )
)

newdat$pred <- predict(fit, newdat)

plot_ly(
  data = best,
  x = ~Word_length_syll,
  y = ~Phon_Inv_Size,
  mode = "markers",
  type = "scatter"
) |>
  add_lines(
    data = newdat,
    x = ~Word_length_syll,
    y = ~pred,
    line = list(color = "red", width = 3)
  )

#extra measures:
best%>%
  count(Macroarea)

best%>%
  count(Family)

df%>%count(Macroarea.y)
