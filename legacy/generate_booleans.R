#!/usr/bin/env Rscript

setwd('~/Projects/wordle/')

library('tidyverse')

g <- readRDS('derived_data/guess_words.RDS')
a <- readRDS('derived_data/answer_words.RDS')
g_mat <- readRDS('derived_data/guess_mat.RDS')
a_mat <- readRDS('derived_data/answer_mat.RDS')
g_count <- readRDS('derived_data/guess_count.RDS')
a_count <- readRDS('derived_data/answer_count.RDS')

var_list <- expand_grid(p = c('p1', 'p2', 'p3', 'p4', 'p5'),
                        l = letters,
                        m = c('a', 'g')) %>%
  mutate(p = paste0(m, '_', p)) %>%
  mutate(expression1 = paste0(p, "_equal_", l, " <- ", m, "_mat$", p, " == '", l, "'"),
         expression2 = paste0(p, "_not_equal_", l, " <- ", m, "_mat$", p, " != '", l, "'"))

for (e in var_list$expression1) eval(parse(text = e))
for (e in var_list$expression2) eval(parse(text = e))

var_list <- expand_grid(l = letters,
                        c = 0:5,
                        m = c('a', 'g')) %>%
  mutate(expression1 = paste0(m, "_", l, "_equal_", c, " <- ", m, "_count$", l, " == ", c),
         expression2 = paste0(m, "_", l, "_greater_", c, " <- ", m, "_count$", l, " >= ", c))

for (e in var_list$expression1) eval(parse(text = e))
for (e in var_list$expression2) eval(parse(text = e))
