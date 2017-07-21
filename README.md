# moses
Moses Decoder trained on europarl to get perplexity

You will need to download: 
1. the Moses Decoder https://github.com/moses-smt/mosesdecoder and download 
2. the trained model https://github.com/monnetproject/translation/blob/master/phrasal/src/test/resources/sample-models/lm/europarl.srilm.gz
3. The script will go through a file with the following structure on each line: <label> \t <sentence1> \t <sentence2> \n
4. For each sentence1, there are many sentence2 option and we are looking for the sentence2 with the lowest perplexity. The lowest perplexity sentence should be sentence pairs where label = 2.
