#!/usr/bin/env Rscript

source('~/detachAllPackages.R')

setwd('~/Projects/wordle/')

library('tidyverse')

answer_words <- scan('raw_data/answer_words.txt', what = 'character')
guess_words <- scan('raw_data/guess_words.txt', what = 'character')
guess_words <- sort(c(answer_words, guess_words))

saveRDS(answer_words, 'derived_data/answer_words.RDS')
saveRDS(guess_words, 'derived_data/guess_words.RDS')

word_lists <- list('answer' = answer_words, 'guess' = guess_words)

for (n in names(word_lists)) {
  w <- word_lists[[n]] 
  m <- matrix(unlist(sapply(w, function(x) strsplit(x, ''))), byrow = T, ncol = 5)
  c <- matrix(rep(0, length(w) * 26), ncol = 26)
  
  colnames(c) <- letters
  rownames(c) <- w
  
  for (i in 1:nrow(m)) {
    for (j in 1:5) c[i, m[i, j]] <- c[i, m[i, j]] + 1
  }

  m <- as_tibble(m)
  if (n == 'answer') {
    names(m) <- c('a_p1', 'a_p2', 'a_p3', 'a_p4', 'a_p5')
  } else {
    names(m) <- c('g_p1', 'g_p2', 'g_p3', 'g_p4', 'g_p5')
  }
  write_csv(m, paste0('derived_data/', n, '_mat.csv'))
  saveRDS(m, paste0('derived_data/', n, '_mat.RDS'))
  
  c <- as_tibble(c)
  write_csv(c, paste0('derived_data/', n, '_count.csv'))
  saveRDS(c, paste0('derived_data/', n, '_count.RDS'))
}
