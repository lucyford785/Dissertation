#####PER LANGUAGE PREPROCESSING#####


#specify language - move this later:
# language="spanish_latin_america"
# source="MFA"

#import libraries
import numpy as np
import pandas as pd
import re
import os
from statistics import mean, StatisticsError #for error handling in cluster calcs

#initialise lists to construct final dataset:
filenames=[]
mwl_syll=[]
mwl_phon=[]
itv_clusters=[]
mcl=[]


#define IPA vowels:
ipa_vowels=["i", "y", "ɨ", "ʉ", "ɯ", "u", "ɪ", "ʏ", "ʊ", "e", "ø", "ɘ", "ɵ", "ɤ", "o", "ə", "ɛ", "œ", "ɜ", "ɞ", "ʌ", "ɔ", "æ", "ɐ", "a", "ɶ", "ɑ","ɒ"]

#define IPA diacritics: 
#TODO: are tones included here or somewhere else?
#ipa_diacritics=[""]
#tones=["˩"]

directory=f'/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/MFA Dicts'

for filename in os.listdir(directory):

    #os bug handling:
    if filename=='.DS_Store':
        continue

    print(f'Processing {filename}')

    #initialise lists - don't need all of these but keep in case useful:
    words=[]    
    transcriptions=[]

    with open(f'/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/MFA Dicts/{filename}') as f:
        for line in (f.readlines()[1:]):
            fields = line.rstrip().split('\t')
            words.append(fields[0])
            transcriptions.append(fields[1])

    #create pd dataframe from lists:
    per_lang_df=pd.DataFrame({
        'Word':words, 
        'Transcription': transcriptions})

    #removing spaces in transcriptions:
    transcriptions=[re.sub(r' ', '', item) for item in transcriptions]

    #label vowels in transcriptions using regex:
    transcriptions=[re.sub(r'[iyɨʉɯuɪʏʊeøɘɵɤoəɛœɜɞʌɔæɐaɶɑɒ]+', 'VOWEL', item, flags=re.IGNORECASE) if item!='sil' else item for item in transcriptions]

    #label tone numbers in transcriptions:
    transcriptions=[re.sub(r'[1-9]', 'TONE', item) for item in transcriptions]

    #create consonant cluster sets:
    clusters=[re.sub(r'(VOWEL)+', '/', item) if item!='spn' and item!='sil' else 'N/A' for item in transcriptions]
    #remove tone markers as these are part of the vowel
    clusters=[re.sub(r'(TONE)', '', item) if item!='N/A' else item for item in clusters]

    #add clusters column to dataframe:
    per_lang_df.insert(loc=2, column='Clusters', value=clusters)

    #count number of syllables by number of /:
    num_syllables=[item.count('/') if item!='N/A' else 'N/A' for item in clusters]

    #add to df
    per_lang_df.insert(loc=3, column='No. Syllables(Vowels)', value=num_syllables)

    #TODO: simplify this, so only initialise transcriptions once at beginning - could just do phon_counts first?
    
    #reinitialise transcriptions:
    transcriptions=[]
    with open(f'/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/MFA Dicts/{filename}') as f:
        for line in (f.readlines()[1:]):
            fields = line.rstrip().split('\t')
            transcriptions.append(fields[1])

    #count the number of phonemes in each transcription using list.count():
    #NB: exclude all numbers too as used for tones
    phon_counts=[len(re.findall(r'[^ 1-9]', item)) if item !="spn" and item!="sil" else "N/A" for item in transcriptions]
    #add to df
    per_lang_df.insert(loc=4, column='No.Phonemes', value=phon_counts)

    #average length of intervocalic clusters per word:

    split_clusters=[re.split('/', item) if item !="N/A" else "N/A" for item in clusters]

    avg_cluster_lengths=[]
    for item in split_clusters:
        if item=='N/A':
            avg_cluster_lengths.append('N/A')
        else:
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
                avg_cluster_lengths.append('N/A')

    #add to df and save per language df:
    per_lang_df.insert(loc=5, column='Mean cluster length', value=avg_cluster_lengths)
    per_lang_df.to_csv(f'/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/Language dfs/{filename}_df.csv')

    #calculate big df variables:
    #NB: collapse language and source columns into a single filename column
    filenames.append(filename)

    #mean word length in syllables:
    #filter out sil and spn tokens:

    filtered_num_syllables=[value for value in num_syllables if value!='N/A']
    mwl_syll.append(mean(filtered_num_syllables))

    #mean word length in phonemes:

    filtered_phon_counts=[value for value in phon_counts if value!='N/A']
    mwl_phon.append(mean(filtered_phon_counts))

    #number of intervocalic clusters:
    cluster_list=[]
    for item in split_clusters:
        if item=='N/A':
            continue
        else:
            cluster_list.extend(item)
    #remove empty values:
    cluster_list=[item for item in cluster_list if item.strip()]    
    unique_clusters=set(cluster_list)
    itv_clusters.append(len(unique_clusters))

    #mean cluster length in phonemes:
    filtered_cluster_lengths=[value for value in avg_cluster_lengths if value!='N/A']
    mcl.append(mean(filtered_cluster_lengths))

    print(f'{filename} processed')


#####FULL DATASET#####

#initialise big df - once at end:

#TODO: add PHOIBLE and WALS columns - see if can be automated by downloading full datasets 
#fill in manually for now 

big_df=pd.DataFrame({
    'Filename': filenames, 
    'Mean_word_length_(syllables)': mwl_syll,
    'Mean_word_length_(phonemes)': mwl_phon,
    'No._Intervocalic_clusters': itv_clusters, 
    'Mean cluster length (phonemes)': mcl

})

big_df.to_csv(f'/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/big_df_mfa.csv')