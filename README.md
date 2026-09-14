# Dissertation
Repository containing data, processing and analysis code, and selected results (html files containing interactive plots) for a statistical analysis of syllable complexity, average word length, and phoneme inventory size in the set of languages found in both the Automated Similarity Judgement Programme (ASJP) and PHOIBLE, using the Montreal Forced Aligner (MFA) as a validation set. 

The IPA parser is attributed to Dmitry Nikolaev, with the original code contained in the following repository: https://github.com/macleginn/eurphon-parse-search. The raw parser (IPAParser_3_0.py) and its requirements are stored twice (in both 'MFA preprocessing' and 'ASJP preprocessing') to ensure that all files to run full preprocessing for both the test and validation set are stored in the same folder for ease of reproduction. The IPA parser requires the python 'lark' package to be installed. 

PHOIBLE data is integrated into the MFA and ASJP analysis scripts. 


