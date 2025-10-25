#!/usr/bin/env Rscript

source('~/detachAllPackages.R')

setwd('~/Projects/wordle/')

library('httr')
library('tidyverse')

url <- 'https://www.powerlanguage.co.uk/wordle/main.e65ce0a5.js'
r <- GET(url)
d <- content(r, 'text')

# d <- 'xxxxxxx;var La=["cigar","rebut","rural","shave"]],Ta=["aahed","aalii","aargh","aarti","abaca","abaci","zymic"],Ia="present",'
la <- gsub('.+var La=\\["([^\\]]+?)"\\].+', '\\1', d, perl = T)
ta <- gsub('.+,Ta=\\["([^\\]]+?)"\\].+', '\\1', d, perl = T)

answer_words <- strsplit(la, '","') %>% unlist()
guess_words <- strsplit(ta, '","') %>% unlist()

answer_words <- answer_words[nchar(answer_words) == 5]
guess_words <- guess_words[nchar(guess_words) == 5]

write(sort(answer_words), 'raw_data/answer_words.txt')
write(sort(guess_words), 'raw_data/guess_words.txt')
