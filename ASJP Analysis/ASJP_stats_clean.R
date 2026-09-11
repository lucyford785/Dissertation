#no contributor cleaning or Macroarea cleaning in this:
#REPLACE MANUAL CALCULATIONS WITH R FUNCTIONS

library(tidyverse)
library(dplyr)
library(Hmisc)
library(ggplot2)
library(corrplot)

set.seed(12)

big_ASJP<-read.csv('/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/big_df_ASJP.csv')

PHOIBLE_raw<-read_csv('/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/PHOIBLE/cldf-datasets-phoible-f36deac/cldf/contributions.csv')

PHOIBLE_langs<-read_csv('/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/PHOIBLE/cldf-datasets-phoible-f36deac/cldf/languages.csv')

PHOIBLE_values<-read_csv('/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/PHOIBLE/cldf-datasets-phoible-f36deac/cldf/values.csv')

PHOIBLE_IDs<-PHOIBLE_values%>%
  select(Language_ID, Contribution_ID)%>%
  distinct()
PHOIBLE_IDs$ID<-PHOIBLE_IDs$Contribution_ID
PHOIBLE_IDs$Contribution_ID<-NULL
PHOIBLE_IDs$Glottocode<-PHOIBLE_IDs$Language_ID
PHOIBLE_IDs$Language_ID<-NULL

PHOIBLE_df_temp<-merge(PHOIBLE_IDs, PHOIBLE_raw, by='ID')
PHOIBLE_df_merged<-merge(PHOIBLE_df_temp, PHOIBLE_langs, by='Glottocode', all=TRUE)

PHOIBLE_df_merged$Name_ph_contributions<-PHOIBLE_df_merged$Name.x
PHOIBLE_df_merged$Name.x<-NULL
PHOIBLE_df_merged$Name_ph_langs<-PHOIBLE_df_merged$Name.y
PHOIBLE_df_merged$Name.y<-NULL

ASJP_langs<-read.csv('/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/ASJP_full/lexibank-asjp-0127953/cldf/languages.csv')

ASJP_langs$Language_ID<-ASJP_langs$ID

ASJP_df<-merge(big_ASJP, ASJP_langs, by='Language_ID', all=TRUE)

#now merge with ASJP also using glottocode (no WALS for now)
df<-merge(PHOIBLE_df_merged, ASJP_df, by='Glottocode') #all has to be false for intersection of two

df$Name_ASJP<-df$Name
df$Name<-NULL

#remove some unused columns:
#NB: used ASJP macroarea and Family as appears more geographically focussed, greater nuance
df<-df%>%
  select(Glottocode, Name_ph_contributions, Name_ph_langs, Name_ASJP, Family, Macroarea.y,
         Contributor_ID, count_phonemes, count_consonants, count_vowels,
         count_tones, No.Phonemes, No..Syllables.Vowels., Mean.cluster.length)

#rename columns for interpretability:
df$Phon_Inv_Size<-df$count_phonemes
df$count_phonemes<-NULL

df$Cons_Inv_Size<-df$count_consonants
df$count_consonants<-NULL

df$Word_length_phon<-df$No.Phonemes
df$No.Phonemes<-NULL

df$Word_length_syll<-df$No..Syllables.Vowels.
df$No..Syllables.Vowels.<-NULL

df$Mean_cluster_length<-df$Mean.cluster.length
df$Mean.cluster.length<-NULL

#make language isolate family:
#NB: use PHOIBLE names and family tags
isolates<-df%>%
  filter(Family==Name_ph_langs)
df<-df%>%
  mutate(Family=replace(Family, Name_ph_langs==Family, "Isolate"))

df%>%count(Family)
#extract number of unique varieties in test set
glottocodes<-unique(df$Glottocode)

#correlation sample function:
cor_sample<-function(df){
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
  cor_df<-sampled_df_2%>%
    select(Phon_Inv_Size, Cons_Inv_Size, Word_length_phon, Word_length_syll, Mean_cluster_length)
  
  cor_df$Glottocode<-NULL
  #cor(cor_df, method='spearman')
  cor_mat<-as.matrix(cor_df)
  result<-rcorr(cor_mat, type="spearman")
  list(cor=result$r, p=result$P)

}

#result$P #p values
#result$r #correlation values
mats_1k<-replicate(1000, cor_sample(df), simplify=FALSE) #simplify false means each iteration gets stored?

#separate results to take means
p_vals<-lapply(mats_1k, `[[`, "p")
cors_1k<-lapply(mats_1k, `[[`, "cor")

#mean_cors_1k<-reduce(cors_1k, `+`) /length(cors_1k) #purrr reduce
#p_values<-reduce(mats_1k$P, `+`)/length

#adjust p values for multiple correlations - FDR
p_vals<-lapply(p_vals, p.adjust, method='BH')

#only keep significant correlations:
threshold <- 0.05
x<-cors_1k
y<-p_vals
filtered_cors <- Map(
  function(xi, yi) {
    xi[yi > threshold] <- 0
    xi
  },
  x, y
)

#compute average
mean_cors_1k<-reduce(filtered_cors, `+`) /length(filtered_cors) #purrr reduce

#p values - proportion of significant correlations:
#NB:don't keep this
sig_prop <- Reduce( #base Reduce
  "+",
  lapply(p_vals, function(x) x < 0.05)
) / length(p_vals)

sig_prop
######## HOW TO INTERPRET PROPORTIONS AS SIG OR NOT? #####

#new correlation averaging - only average over significant correlations:


#compute standard deviation and confidence intervals:
#NB: use tapply with built in sd func - don't keep this
sd_1k<- Reduce("+",
                 lapply(cors_1k, function(m)
                   (m - mean_cors_1k)^2)
) / length(cors_1k)

sd_1k<- sqrt(sd_1k)

#correlation plot:

corrplot(mean_cors_1k, method='number')

#add a title in writing later

#further visualisations? - copy dmitry plots for pairwise relationships
df%>%
  count(Family=="Isolate")

df%>%count(Family)

df%>%
  count(Glottocode)
sig_prop<-as.matrix(sig_prop)
mean_cors_1k
corrplot(sd_1k, method='number')
rej_rate<-1-sig_prop
