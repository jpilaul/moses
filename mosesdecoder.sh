#!/bin/bash

declare -a sentence1_array
declare -a sentence2_list_array 
declare -a label_list_array
new_sentences=""
sentences_labels=""
# Parse the file and keep sentence 2
let i=0
let j=0

getPerplexity () {
  # get query for each sentences and reformat output to only hold perplexity including and excluding OOV
  echo "$1" | /idiap/temp/pehonnet/NLP/code/mosesdecoder/bin/query /idiap/temp/pehonnet/tmp/europarl.srilm | sed -n 3,3p
}

while IFS=$'\t' && read -r label sentence_1 sentence_2; do
  sentence1_array[i]="${sentence_1}"
  if ((i==0)); then
    new_sentences="${sentence_2}"
    sentences_labels="${label}"
  else
    if [ "${sentence1_array[i-1]}" = "${sentence1_array[i]}" ]; then
      new_sentences="$new_sentences"$'\t'"${sentence_2}"
      sentences_labels="$sentences_labels"$'\t'"${label}"
    else
      sentence2_list_array[j]="$new_sentences"
      label_list_array[j++]="$sentences_labels"
      new_sentences="${sentence_2}"
      sentences_labels="${label}"
    fi
  fi
  ((++i))
done < data/test_n.txt #<(sed -n 1,1000p data/output.txt)

let count_label2=0
let count_correct=0
for ((i=0;i<=j;i++)); do  
  # STEP 1: check sentence perplexity and find out the minimum for each group of sentences
  sentence_2=$(echo "${sentence2_list_array[i]}" | tr $'\t' "\n")
  let min=-1  
  let min_index=0
  let k=0
  let p=0
  while read -r line; do
    query="$(getPerplexity "$line")"
    while IFS=$'\t' && read -r part_1 perplexity; do
      p="$perplexity"
      if (( $(echo "$min < 0" | bc -l) )); then
        min="$perplexity" # initialize
      elif (( $(echo "$min > $perplexity" | bc -l) )); then
        min="$perplexity" # replace with new min
        min_index="$k"
      fi
      ((++k))
    done <<< "$query"
    echo "$p"$'\t'"$line"
  done <<< "$sentence_2"
  
  # STEP 2: compare position of label "2" sentence with the position of lowest perplexity
  labels=$(echo "${label_list_array[i]}" | tr $'\t' "\n")
  let antecedent_label_position=0
  while read -r label; do
    if (( $(echo "$label == 2 && $antecedent_label_position == $min_index" | bc -l) )); then
      ((++count_correct))
      break
    fi
    ((++antecedent_label_position))
  done <<< "$labels"
  if (( $i % 5 == 0 )); then
    echo "Accuracy at $i"
    echo "scale=2; $count_correct*100/$count_label2" | bc
  fi
done > language_model_results.out #old_data_results.out

echo $'\n'"-----------------------------------------------------"
echo "Outputting accuracy:"
echo "scale=2; $count_correct*100/$i" | bc

