#!/usr/bin/env Rscript

source('~/detachAllPackages.R')

setwd('~/Projects/wordle/')

source('generate_booleans.R')

library('tidyverse')
library('grid')
library('gridExtra')

calculate_guesses <- function(best_guess) {
  
  boolean_expression <- best_guess %>%
    mutate(e1 = ifelse(p1 == 'green', paste0('g_p1_equal_', g_p1),
                       ifelse(p1 == 'red', paste0('g_', g_p1, '_equal_0'),
                              paste0('g_', g_p1, '_greater_1'))),
           e2 = ifelse(p2 == 'green', paste0('g_p2_equal_', g_p2),
                       ifelse(p2 == 'red', paste0('g_', g_p2, '_equal_0'),
                              paste0('g_', g_p2, '_greater_1'))),
           e3 = ifelse(p3 == 'green', paste0('g_p3_equal_', g_p3),
                       ifelse(p3 == 'red', paste0('g_', g_p3, '_equal_0'),
                              paste0('g_', g_p3, '_greater_1'))),
           e4 = ifelse(p4 == 'green', paste0('g_p4_equal_', g_p4),
                       ifelse(p4 == 'red', paste0('g_', g_p4, '_equal_0'),
                              paste0('g_', g_p4, '_greater_1'))),
           e5 = ifelse(p5 == 'green', paste0('g_p5_equal_', g_p5),
                       ifelse(p5 == 'red', paste0('g_', g_p5, '_equal_0'),
                              paste0('g_', g_p5, '_greater_1')))) %>%
    mutate(e = paste0('g[which(', paste(e1, e2, e3, e4, e5, sep = ' & '), ')]')) %>% .$e
  guesses <- sapply(boolean_expression, function(e) eval(parse(text = e)), USE.NAMES = F)
  return(guesses)
}

calc_best_guess <- function(g2, a2, g2_mat, a2_mat) {
  
  c <- expand_grid(g = g2, a = a2) %>%
    bind_cols(g2_mat[rep(1:nrow(g2_mat), each = nrow(a2_mat)), ]) %>%
    bind_cols(a2_mat[rep(1:nrow(a2_mat), nrow(g2_mat)), ])
  
  for (i in 1:5) {
    e1 <- paste0('c$green_', i, ' <- c$g_p', i, ' == c$a_p', i)
    e2 <- paste0('c$red_', i, ' <- c$g_p', i, ' != c$a_p1 & c$g_p', i,
                 ' != c$a_p2 & c$g_p', i, ' != c$a_p3 & c$g_p', i,
                 ' != c$a_p4 & c$g_p', i, ' != c$a_p5')
    e3 <- paste0('c$p', i, ' <- ifelse(c$green_', i, ", 'green', ifelse(c$red_",
                 i, ", 'red', 'yellow'))")
    eval(parse(text = e1))
    eval(parse(text = e2))
    eval(parse(text = e3))
  }
  
  c$exact_match <- c$p1 == 'green' & c$p2 == 'green' & c$p3 == 'green' & c$p4 == 'green' & c$p5 == 'green'

  o <- c %>%
    group_by(g, g_p1, g_p2, g_p3, g_p4, g_p5, p1, p2, p3, p4, p5) %>%
    summarize(answer_count = sum(!exact_match)) %>%
    ungroup()
  
  guess_summary <- o %>%
    group_by(g) %>%
    summarize(avg_remaining = sum(answer_count ^ 2) / length(answer_count),
              min_remaining = min(answer_count),
              max_remaining = max(answer_count)) %>%
    ungroup() %>%
    mutate(in_answer_list = g %in% a2)
 
  guess <- guess_summary %>% arrange(avg_remaining, desc(in_answer_list), g) %>% .$g %>% .[1]
  avg_remaining <- guess_summary %>% arrange(avg_remaining, desc(in_answer_list), g) %>% .$avg_remaining %>% .[1]
  min_remaining <- guess_summary %>% arrange(avg_remaining, desc(in_answer_list), g) %>% .$min_remaining %>% .[1]
  max_remaining <- guess_summary %>% arrange(avg_remaining, desc(in_answer_list), g) %>% .$max_remaining %>% .[1]
  
  
  best_guess <- c %>%
    filter(g == guess) %>%
    group_by(g, g_p1, g_p2, g_p3, g_p4, g_p5, p1, p2, p3, p4, p5) %>%
    summarize(answer_count = sum(!exact_match),
              answers = list(a[!exact_match])) %>%
    ungroup()
  
  result <- list(o = o, guess = guess, guess_summary = guess_summary,
                 best_guess = best_guess, avg_remaining = avg_remaining,
                 min_remaining = min_remaining, max_remaining = max_remaining)
  return(result)
  
} 

print_cheat_sheet <- function(optimal_strategy, fn = 'output_data/Wordle Cheat Sheet.pdf') {
  
  d <- optimal_strategy

  color_cols <- names(d)[grepl('color', names(d))] 
  for (n in color_cols) d[[n]] <- factor(d[[n]], levels = c('red', 'yellow', 'green'))
  
  e <- paste0('d <- d %>% arrange(', paste0(color_cols, collapse = ', '), ')')
  eval(expr = parse(text = e))
  
  for (n in color_cols)  d[[n]] <- as.character(d[[n]])
  
  d_size <- 44
  p <- list()
  i <- 1
  while(((i-1)*d_size + 1) <= nrow(d)) {
   
    ind <- ((i-1)*d_size + 1):min((i*d_size), nrow(d))
    temp_d <- d[ind, c(9:13, 7, 15)]
    f <- d[ind, 2:6] 
    f[f == 'green'] <- 'green4'
    f[f == 'red'] <- 'gray55'
    f[f == 'yellow'] <- 'gold2'
    f[, 6:7] <- 'white'
    
    for (j in c(1:5, 7)) temp_d[[j]] <- toupper(temp_d[[j]])
    
    c <- f
    c[, 1:5] <- 'white'
    c[, 6:7] <- 'black'
    
    t3 <- ttheme_minimal(
      core = list(bg_params = list(fill = unlist(f), col = NA),
                  fg_params = list(fontface = 'bold', fontsize = 9,
                                   col = unlist(c))))
    
    p[[i]] <- tableGrob(temp_d, rows = NULL, cols = NULL, theme = t3)
    i <- i + 1
    
  }
  
  pdf(fn, paper = 'a4', height = 11, width = 8.5)
  # grid.arrange(p[[1]], p[[2]], p[[3]], ncol = 3)
  do.call("grid.arrange", c(p, ncol= i-1))
  dev.off()
  
}

printSingleOutcome <- function(outcome) {
  
  d <- outcome[1, 9:13]
  names(d) <- c('l1', 'l2', 'l3', 'l4', 'l5')
  temp_d <- outcome[1, 28:32]
  names(temp_d) <- c('l1', 'l2', 'l3', 'l4', 'l5')
  d <- bind_rows(d, temp_d)
  temp_d <- outcome[1, 46:50]
  names(temp_d) <- c('l1', 'l2', 'l3', 'l4', 'l5')
  d <- bind_rows(d, temp_d)
  temp_d <- outcome[1, 64:68]
  names(temp_d) <- c('l1', 'l2', 'l3', 'l4', 'l5')
  d <- bind_rows(d, temp_d)
  temp_d <- outcome[1, 82:86]
  names(temp_d) <- c('l1', 'l2', 'l3', 'l4', 'l5')
  d <- bind_rows(d, temp_d)
  
  chars <- strsplit(as.character(outcome[1, 15]), '')[[1]]
  g <- tibble(l1 = chars[1], l2 = chars[2], l3 = chars[3], l4 = chars[4], l5 = chars[5])
  chars <- strsplit(as.character(outcome[1, 33]), '')[[1]]
  temp_g <- tibble(l1 = chars[1], l2 = chars[2], l3 = chars[3], l4 = chars[4], l5 = chars[5])
  g <- bind_rows(g, temp_g)
  chars <- strsplit(as.character(outcome[1, 51]), '')[[1]]
  temp_g <- tibble(l1 = chars[1], l2 = chars[2], l3 = chars[3], l4 = chars[4], l5 = chars[5])
  g <- bind_rows(g, temp_g)
  chars <- strsplit(as.character(outcome[1, 69]), '')[[1]]
  temp_g <- tibble(l1 = chars[1], l2 = chars[2], l3 = chars[3], l4 = chars[4], l5 = chars[5])
  g <- bind_rows(g, temp_g)
  chars <- strsplit(as.character(outcome[1, 87]), '')[[1]]
  temp_g <- tibble(l1 = chars[1], l2 = chars[2], l3 = chars[3], l4 = chars[4], l5 = chars[5])
  g <- bind_rows(g, temp_g)
  
  
  
  f1 <- outcome[1, 2:6]
  names(f1) <- c('l1', 'l2', 'l3', 'l4', 'l5')
  temp_f1 <- outcome[1, 21:25]
  names(temp_f1) <- c('l1', 'l2', 'l3', 'l4', 'l5')
  f1 <- bind_rows(f1, temp_f1)
  temp_f1 <- outcome[1, 39:43]
  names(temp_f1) <- c('l1', 'l2', 'l3', 'l4', 'l5')
  f1 <- bind_rows(f1, temp_f1)
  temp_f1 <- outcome[1, 57:61]
  names(temp_f1) <- c('l1', 'l2', 'l3', 'l4', 'l5')
  f1 <- bind_rows(f1, temp_f1)
  temp_f1 <- outcome[1, 75:79]
  names(temp_f1) <- c('l1', 'l2', 'l3', 'l4', 'l5')
  f1 <- bind_rows(f1, temp_f1)
  f2 <- f1
  f2[, 1:5] <- 'green'
  
  f1[f1 == 'green'] <- 'green4'
  f1[f1 == 'red'] <- 'gray55'
  f1[f1 == 'yellow'] <- 'gold2'

  f2[f2 == 'green'] <- 'green4'
  f2[f2 == 'red'] <- 'gray55'
  f2[f2 == 'yellow'] <- 'gold2'
  
  for (j in c(1:5)) d[[j]] <- toupper(d[[j]])
  for (j in c(1:5)) g[[j]] <- toupper(g[[j]])
  
  c <- f1
  c[, 1:5] <- 'white'
  
  ind1 <- which(!is.na(d$l1))
  ind2 <- if (is.na(g$l1[1])) c() else max(which(!is.na(g$l1)))
  
  d <- bind_rows(d[ind1, ], g[ind2, ])
  f <- bind_rows(f1[ind1, ], f2[ind2, ])
  
  ind <- which(!duplicated(d))
  
  d <- d[ind, ]
  f <- f[ind, ]
  
  t3 <- ttheme_minimal(
    core = list(bg_params = list(fill = unlist(f), col = NA),
                fg_params = list(fontface = 'bold', fontsize = 4,
                                 col = unlist(c))))
  
  p <- tableGrob(d, rows = NULL, cols = NULL, theme = t3)
  return(p)
}
