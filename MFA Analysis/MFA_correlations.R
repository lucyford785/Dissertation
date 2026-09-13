#MFA:
library(tidyverse)
library(dplyr)
library(Hmisc)
library(ggplot2)
library(corrplot)

big_df_parsed<-read_csv(file.path(path.expand("~"),"Desktop","UOM CCL","Semester 2","Dissertation","big_df_mfa_parsed.csv"))

#remove Mandarin pinyin row:
big_df_parsed<-subset(big_df_parsed, Filename!='mandarin_pinyin.dict')

PHOIBLE_raw<-read_csv(file.path(path.expand("~"),"Desktop","UOM CCL","Semester 2","Dissertation","PHOIBLE","cldf-datasets-phoible-f36deac","cldf","contributions.csv"))
PHOIBLE_df<-PHOIBLE_raw%>%
  select(ID, Name, count_phonemes, count_consonants)

#make Names lowercase to align with MFA:
PHOIBLE_df$Language<-tolower(PHOIBLE_df$Name)

#clean columns:
PHOIBLE_df$Name<-NULL
big_df_parsed<-big_df_parsed%>%
  select(Language, Word_length_phon, Word_length_syll, Mean_cluster_length)


#add PHOIBLE data
#NB: multiple PH inventories for some langs - corresponds to 1 MFA file - so df expands 
df_ph<-merge(PHOIBLE_df, big_df_parsed, by='Language')

#dplyr renames for interpretability:
df_ph<-rename(df_ph, PHOIBLE_ID=ID)
df_ph<-rename(df_ph, Phon_Inv_Size=count_phonemes)
df_ph<-rename(df_ph, Cons_Inv_Size=count_consonants)


#create correlation matrix 
cor_df<-df_ph%>%
  select(Phon_Inv_Size, Cons_Inv_Size, Word_length_phon, Word_length_syll, Mean_cluster_length)

MFA_corr<-cor(cor_df, method='spearman')

corrplot(MFA_corr, method='number')

MFA_cor_mat<-as.matrix(cor_df)

#compute p values test
rcorr(MFA_cor_mat, type="spearman")

