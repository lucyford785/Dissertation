#####PER LANGUAGE PREPROCESSING#####

#import libraries
import numpy as np
import pandas as pd
import re
import os
from statistics import mean, StatisticsError #for error handling in cluster calcs
from pathlib import Path #for anonymous file handling

filename=Path.home()/"Desktop/UOM CCL/Semester 2/Dissertation/ASJP_full/lexibank-asjp-0127953/cldf/forms.csv"

print(f'Processing {filename}') 

#initialise lists for full (uncollapsed) dataset:
token_ids=[] #for identifying which word is which by concept 
language_ids=[]
values=[] #NB: this uses ASJP orthography
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
#NB: this will include all languages
per_lang_df=pd.DataFrame({
    'Token_ID': token_ids,
    'Language_ID': language_ids,
    'Gloss': glosses,
    'Word': values, 
    'Transcription': transcriptions})

per_lang_df.to_csv(Path.home()/'Desktop/UOM CCL/Semester 2/Dissertation/ASJP_dfs/ASJP_pre_parsing_df.csv')


#open up parsed phonemes file from parser:
parsed_phonemes=[]
VC_labels=[]
with open(Path.home()/'Desktop/UOM CCL/Semester 2/Dissertation/Dmitry MFA parser/ASJP_parsed_phonemes.txt') as f:
    for line in (f.readlines()):
            fields = line.split(':')
            parsed_phonemes.append(fields[0])
            VC_labels.append(fields[1].strip())

VC_dict=dict(zip(parsed_phonemes, VC_labels))

#only keep valid phonemes using parsed_phonemes:
#NB: TRANSCRIPTIONS COLUMN USES FULL TRANSCRIPTION, ONLY VALID IPA SYMBOLS PROCESSED BY PARSER (UNICODE NORMALISE) INCLUDED IN OTHER COLUMN CALCS
for i, word in enumerate(transcriptions):
    for symbol in word:
        if symbol not in parsed_phonemes:
            word=word.replace(symbol, '')
    transcriptions[i]=word

#removing spaces in transcriptions:
transcriptions=[re.sub(r' ', '', item) for item in transcriptions]

#count the number of phonemes in each transcription:
phon_counts=[]
vowels=[]
for item in transcriptions:
    result=len(re.findall(r'[^\s]', item, flags=re.IGNORECASE))
    for symbol in item:
        if symbol in VC_dict.keys():
            if VC_dict[symbol]=='vowel':
                vowels.append(symbol)
        elif symbol == '~': #merge 2 symbols
            result=result-1
        elif symbol=='$': #merge 3 symbols
            result=result-2
        else:
            continue
    phon_counts.append(result)

per_lang_df.insert(loc=5, column='No.Phonemes', value=phon_counts)

#label vowels
pattern=f'[{''.join(vowels)}]'

transcriptions=[re.sub(pattern, 'VOWEL', item) for item in transcriptions]

#remove ASJP modifier characters:
ASJP_MODIFIERS=[r'[\""]', '<', '>', '*', '+']
transcriptions=[re.sub(r'[<>\*\+\""]+', '', item) for item in transcriptions] #ejective marker ' excluded as acts as a standalone consonant

#create consonant cluster sets:
clusters=[re.sub(r'(VOWEL)+', '/', item) for item in transcriptions]

#add clusters column to dataframe:
per_lang_df.insert(loc=6, column='Clusters', value=clusters)

#count number of syllables by number of /:
num_syllables=[item.count('/') for item in clusters]

#add to df
per_lang_df.insert(loc=7, column='No. Syllables(Vowels)', value=num_syllables)
    
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
per_lang_df.insert(loc=8, column='Mean cluster length', value=avg_cluster_lengths)
per_lang_df.to_csv(f'{Path.home()}/Desktop/UOM CCL/Semester 2/Dissertation/ASJP_dfs/ASJP_perlang_df.csv')

############## AVERAGES DF #################

#Use pandas df.groupby() to group numbers into language ID categories and store 1 result per language ID

big_df = per_lang_df.drop(columns=['Gloss', 'Word', 'Transcription', 'Clusters', 'Token_ID'])
big_df[['No.Phonemes', 'No. Syllables(Vowels)','Mean cluster length']]=big_df[['No.Phonemes', 'No. Syllables(Vowels)','Mean cluster length']].apply(pd.to_numeric)
grouped_df=big_df.groupby("Language_ID").mean()

print(grouped_df)

grouped_df.to_csv(f'{Path.home()}/Desktop/UOM CCL/Semester 2/Dissertation/big_df_ASJP.csv')
