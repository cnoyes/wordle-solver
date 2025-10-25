#!/usr/bin/env Rscript

setwd('~/Projects/wordle/')

library('tidyverse')

g <- readRDS('derived_data/guess_words.RDS')
a <- readRDS('derived_data/answer_words.RDS')
g_mat <- readRDS('derived_data/guess_mat.RDS')
a_mat <- readRDS('derived_data/answer_mat.RDS')
g_count <- readRDS('derived_data/guess_count.RDS')
a_count <- readRDS('derived_data/answer_count.RDS')

s <- readRDS('derived_data/strategy.RDS')
b <- readRDS('derived_data/best_guess.RDS')
