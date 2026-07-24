#####PER LANGUAGE PREPROCESSING#####

#import libraries
import numpy as np
import pandas as pd
import re
import os
from statistics import mean, StatisticsError #for error handling in cluster calcs

filename='/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/ASJP_full/lexibank-asjp-0127953/cldf/forms.csv'

print(f'Processing {filename}')

#initialise lists for full (uncollapsed) dataset:
token_ids=[] #for identifying which word is which by concept 
language_ids=[]
values=[] #NB: this uses ASJP orthography outlined in cldf formatted github
transcriptions=[] #IPA-like version, whitespace tokenised
glosses=[]

with open(filename) as f:
    for line in (f.readlines()[1:]):
        fields = line.rstrip().split(',')
        token_ids.append(fields[0])
        language_ids.append(fields[2])
        values.append(fields[4])
        transcriptions.append(fields[6])
        glosses.append(fields[-1])


#create pd dataframe from lists:
#NB: this will include all languages, may be separated using R filtering 
per_lang_df=pd.DataFrame({
    'Token_ID': token_ids,
    'Language_ID': language_ids,
    'Gloss': glosses,
    'Word': values, 
    'Transcription': transcriptions})

per_lang_df.to_csv('/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/ASJP_dfs/ASJP_pre_parsing_df.csv')

########## NOW STOP AND RUN PARSING SCRIPT (INSERT SCRIPT HERE EVENTUALLY) ############


#open up parsed phonemes file from parser (Dmitry):
parsed_phonemes=[]
VC_labels=[]
with open('/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/Dmitry MFA parser/ASJP_parsed_phonemes.txt') as f:
    for line in (f.readlines()):
            fields = line.split(':')
            parsed_phonemes.append(fields[0])
            VC_labels.append(fields[1].strip())

#only keep valid phonemes using parsed_phonemes:
# #NB: TRANSCRIPTIONS COLUMN USES FULL TRANSCRIPTION, ONLY VALID IPA SYMBOLS PROCESSED BY PARSER (UNICODE NORMALISE) INCLUDED IN OTHER COLUMN CALCS
#TODO: tidy this up - clunky
for word in transcriptions:
    for symbol in word:
        if symbol not in parsed_phonemes:
            # re.sub(symbol, '', word)
            word.replace(symbol, '')

#count the number of phonemes in each transcription:
phon_counts=[len(re.findall(r'[a-z0-9]', item, flags=re.IGNORECASE)) for item in transcriptions]
#add to df
per_lang_df.insert(loc=2, column='No.Phonemes', value=phon_counts)

#removing spaces in transcriptions:
transcriptions=[re.sub(r' ', '', item) for item in transcriptions]

#remove ASJP modifier characters:
ASJP_MODIFIERS=[r'[\""\']', '<', '>', '~', '*', '+']
transcriptions=[re.sub(r'[<>~\*\+\""\'\’]+', '', item) for item in transcriptions]

# #label vowels in transcriptions:
# ASJP vowels:
# transcriptions=[re.sub(r'[ieE3auo]+', 'VOWEL', item, flags=re.IGNORECASE) for item in transcriptions]
# IPA vowels:
transcriptions=[re.sub(r'[iyɨʉɯuɪʏʊeøɘɵɤoəɛœɜɞʌɔæɐaɶɑɒ]+', 'VOWEL', item, flags=re.IGNORECASE) for item in transcriptions]

#NB: no tone in ASJP notation

#create consonant cluster sets:
clusters=[re.sub(r'(VOWEL)+', '/', item) for item in transcriptions]

#add clusters column to dataframe:
per_lang_df.insert(loc=3, column='Clusters', value=clusters)

#count number of syllables by number of /:
num_syllables=[item.count('/') for item in clusters]

#add to df
per_lang_df.insert(loc=4, column='No. Syllables(Vowels)', value=num_syllables)
    
#average length of intervocalic clusters per word:

split_clusters=[re.split('/', item) for item in clusters]

avg_cluster_lengths=[]
for item in split_clusters:
    item_cl_lens=[len(subitem) if subitem !='' else 'empty' for subitem in item]
    clean_lens=[]
    for i in item_cl_lens:
        if i=='empty':
            continue
        else:
            clean_lens.append(i)
    try:
        avg_cluster_lengths.append(mean(clean_lens))
    except StatisticsError:
        avg_cluster_lengths.append('0')          

#add to df and save per language df:
per_lang_df.insert(loc=5, column='Mean cluster length', value=avg_cluster_lengths)
per_lang_df.to_csv(f'/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/ASJP_dfs/ASJP_perlang_df.csv')

############## BIG DF #################

#Use pandas df.groupby() to group numbers into language ID categories and store 1 result per language ID

big_df = per_lang_df.drop(columns=['Gloss', 'Word', 'Transcription', 'Clusters', 'Token_ID'])
big_df[['No.Phonemes', 'No. Syllables(Vowels)','Mean cluster length']]=big_df[['No.Phonemes', 'No. Syllables(Vowels)','Mean cluster length']].apply(pd.to_numeric)
grouped_df=big_df.groupby("Language_ID").mean()

print(grouped_df)

grouped_df.to_csv(f'/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/big_df_ASJP.csv')

# #number of intervocalic clusters: #leave for now - not included in calculations at this stage

# cluster_list=[]
# for item in split_clusters:
#     if item=='N/A':
#         continue
#     else:
#         cluster_list.extend(item)
# #remove empty values:
# cluster_list=[item for item in cluster_list if item.strip()]    
# unique_clusters=set(cluster_list)
# itv_clusters.append(len(unique_clusters))