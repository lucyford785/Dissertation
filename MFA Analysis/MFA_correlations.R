#MFA:
library(tidyverse)
library(dplyr)
library(Hmisc)
library(ggplot2)
library(corrplot)

big_df_parsed<-read_csv('/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/big_df_mfa_parsed.csv')

#remove Mandarin pinyin row:
big_df_parsed<-subset(big_df_parsed, Filename!='mandarin_pinyin.dict')

PHOIBLE_raw<-read_csv('/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/PHOIBLE/cldf-datasets-phoible-f36deac/cldf/contributions.csv')
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


###################
#create correlation matrix 
#clean df - use phoible df as WALS is categorical
mfa_cor_sample<-function(df){
  #strat sampling - Family:
  sampled_df<-df%>%
    group_by(Language)%>%
    sample_n(1) #size of smallest group
  sampled_df%>%count(Language)
  
  #clean df to numerical values only
  #count_consonants
  cor_df<-sampled_df%>%
    select(Phon_Inv_Size, Cons_Inv_Size, Word_length_phon, Word_length_syll, Mean_cluster_length)
  
  cor_df$Language<-NULL
  #cor(cor_df, method='spearman')
  cor_mat<-as.matrix(cor_df)
  result<-rcorr(cor_mat, type="spearman")
  list(cor=result$r, p=result$P)
}

mfa_1k<-replicate(1000, mfa_cor_sample(df_ph), simplify=FALSE) 
mfa_p_vals<-lapply(mfa_1k, `[[`, "p")
mfa_cors_1k<-lapply(mfa_1k, `[[`, "cor")
mfa_p_vals<-lapply(mfa_p_vals, p.adjust, method='BH')

#only keep significant correlations:
threshold <- 0.05
x<-mfa_cors_1k
y<-mfa_p_vals
mfa_filtered_cors <- Map(
  function(xi, yi) {
    xi[yi > threshold] <- 0
    xi
  },
  x, y
)

#compute average
mfa_mean_cors_1k<-reduce(mfa_filtered_cors, `+`) /length(mfa_filtered_cors) #purrr reduce

#p values - proportion of significant correlations:
#NB:don't keep this
mfa_sig_prop <- Reduce( #base Reduce
  "+",
  lapply(mfa_p_vals, function(x) x < 0.05)
) / length(mfa_p_vals)

mfa_sig_prop

#new correlation averaging - only average over significant correlations:


#compute standard deviation and confidence intervals:
#NB: use tapply with built in sd func - don't keep this
mfa_sd_1k<- Reduce("+",
                   lapply(mfa_cors_1k, function(m)
                     (m - mfa_mean_cors_1k)^2)
) / length(mfa_cors_1k)

mfa_sd_1k<- sqrt(mfa_sd_1k)

#correlation plot:

corrplot(mfa_mean_cors_1k, method='number')
