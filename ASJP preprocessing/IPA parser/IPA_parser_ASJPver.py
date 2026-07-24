from glob import glob
import unicodedata
import numpy as np
import pandas as pd
from IPAParser_3_0 import IPAParser

#remove ASJP symbols in processings script rather than here

# def strip_modifiers(phoneme):
#     #NB: still need both IPA and ASJP modifier strip as using IPA-like segments column 
#     RED_FLAGS = ["MODIFIER", "COMBINING", "SUPERSCRIPT", "DIGIT"]
#     ASJP_MODIFIERS=[r'[\""\']', '<', '>', '~', '*', '+']
#     buffer = []
#     for symbol in phoneme:
#         if symbol in ASJP_MODIFIERS:
#             break
#         for rf in RED_FLAGS:
#             if rf in unicodedata.name(symbol):
#                 break
#         else:
#             # We didn't break; all good
#             buffer.append(symbol)
#     return "".join(buffer)

def strip_modifiers(phoneme):
    RED_FLAGS = ["MODIFIER", "COMBINING", "SUPERSCRIPT", "DIGIT"]
    buffer = []
    for symbol in phoneme:
        for rf in RED_FLAGS:
            if rf in unicodedata.name(symbol):
                break
        else:
            # We didn't break; all good
            buffer.append(symbol)
    return "".join(buffer)

def main():
    parser = IPAParser()
    all_symbols = set()
    all_phonemes = set()
    all_phonemes_w_names = []
    failures = []
    csv_paths = glob(
        '/Users/lucyford/Desktop/UOM CCL/Semester 2/Dissertation/ASJP_dfs/ASJP_pre_parsing_df.csv'
    )
    for path in csv_paths: #TODO: this is redundant since only 1 file for ASJP
        path_phonemes = set()
        df = pd.read_csv(path)
        # df = df.loc[
        #     np.logical_not(df.Word.isin(["<unk>", "[bracketed]", "[laughter]"]))
        # ]

        #use transcriptions instead as 'sil' and 'spn' are recurring
        # df=df.loc[
        #     np.logical_not(df.Transcription.isin(["sil", "spn"]))
        # ]
        
        #no empty transcriptions in this file 

        for t in df.Transcription:
            word = unicodedata.normalize("NFD", t.strip())
            word_phonemes = word.split(" ") #also whitespace tokenised - good
            path_phonemes.update(word_phonemes)
            for p in word_phonemes:
                all_symbols.update(list(p))

        # Check the new phonemes using the parser right away to not keep the path
        for phoneme in sorted(path_phonemes):
            # all_phonemes now only contains phonemes that we can actually parsed
            simplified_phoneme = strip_modifiers(phoneme)
            if simplified_phoneme not in all_phonemes:
                try:
                    parse = parser.parse(simplified_phoneme)
                    all_phonemes.add(simplified_phoneme)
                    all_phonemes_w_names.append(
                        f'{simplified_phoneme}: {parse.as_dict()["type"]}\n'
                    )
                except:
                    # Tracking paths correctly
                    failures.append(f"{repr(simplified_phoneme)} ({repr(phoneme)}): {path}\n")

    with open("ASJP_all_symbols.txt", "w") as out:
        for symbol in sorted(all_symbols):
            print(f"{symbol}: {unicodedata.name(symbol)}", file=out)
    with open("ASJP_parsed_phonemes.txt", "w") as out:
        out.writelines(sorted(all_phonemes_w_names))
    with open("ASJP_parsing_failures.txt", "w") as out:
        out.writelines(failures)


if __name__ == "__main__":
    main()
