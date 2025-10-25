#!/usr/bin/env Rscript

setwd('~/Projects/wordle/')

# source('download_words.R')
# source('transform_data.R')

source('~/detachAllPackages.R')

source('utilities.R')

options(dplyr.summarise.inform = FALSE)

best_guess <- list()
r <- list()
r[[1]] <- calc_best_guess(g, a, g_mat, a_mat)
best_guess[[1]] <- r[[1]]$best_guess %>% mutate(id = NA)
best_guess[[1]]$guesses <- calculate_guesses(best_guess[[1]])

for (i in 2:6) {
  r[[i]] <- vector("list", nrow(best_guess[[i-1]]))
  for (j in which(best_guess[[i-1]]$answer_count > 0)) {
    
    print(paste(i, j))
    a2 <- best_guess[[i-1]]$answers[j][[1]]
    g2 <- g
    a2_ind <- which(a %in% a2)
    g2_ind <- which(g %in% g2)
    a2_mat <- a_mat[a2_ind, ]
    g2_mat <- g_mat[g2_ind, ] 
    r[[i]][[j]] <- calc_best_guess(g2, a2, g2_mat, a2_mat)
  }
  best_guess[[i]] <- lapply(1:length(r[[i]]), function(j)
    if (!is.null(r[[i]][[j]])) r[[i]][[j]]$best_guess %>% mutate(id = j)) %>% bind_rows()
  best_guess[[i]]$guesses <- calculate_guesses(best_guess[[i]])
}

saveRDS(r, 'derived_data/results.RDS')

for (i in 2:length(best_guess)) {
  best_guess[[i-1]]$best_guess <- sapply(r[[i]], function(x) x$guess)
  best_guess[[i-1]]$avg_remaining <- sapply(r[[i]], function(x) x$avg_remaining)
  best_guess[[i-1]]$min_remaining <- sapply(r[[i]], function(x) x$min_remaining)
  best_guess[[i-1]]$max_remaining <- sapply(r[[i]], function(x) x$max_remaining)
}


best_guess[[length(best_guess)]]$best_guess <- unlist(best_guess[[length(best_guess)]]$answers)
best_guess[[length(best_guess)]]$avg_remaining <- vector("list", nrow(best_guess[[length(best_guess)]]))
best_guess[[length(best_guess)]]$min_remaining <- vector("list", nrow(best_guess[[length(best_guess)]]))
best_guess[[length(best_guess)]]$max_remaining <- vector("list", nrow(best_guess[[length(best_guess)]]))

for (i in 1:length(best_guess)) {
  best_guess[[i]]$best_guess <- ifelse(best_guess[[i]]$answer_count == 0, NA,
                                       ifelse(sapply(best_guess[[i]]$best_guess, is.null),
                                              sapply(best_guess[[i]]$answers, function(x) x[1]),
                                              sapply(best_guess[[i]]$best_guess, function(x) x[1]))) %>%
    unlist()
   best_guess[[i]]$avg_remaining <- ifelse(best_guess[[i]]$answer_count == 0, NA,
                                           ifelse(sapply(best_guess[[i]]$avg_remaining, is.null), 1,
                                                  sapply(best_guess[[i]]$avg_remaining, function(x) x[1]))) %>%
     unlist()
   best_guess[[i]]$min_remaining <- ifelse(best_guess[[i]]$answer_count == 0, NA,
                                           ifelse(sapply(best_guess[[i]]$min_remaining, is.null), 1,
                                                  sapply(best_guess[[i]]$min_remaining, function(x) x[1]))) %>%
     unlist()
   best_guess[[i]]$max_remaining <- ifelse(best_guess[[i]]$answer_count == 0, NA,
                                           ifelse(sapply(best_guess[[i]]$max_remaining, is.null), 1,
                                                  sapply(best_guess[[i]]$max_remaining, function(x) x[1]))) %>%
     unlist()
} 

saveRDS(best_guess, 'derived_data/best_guess.RDS')
best_guess <- readRDS('derived_data/best_guess.RDS')
                                       
optimal_strategy <- list()
for (i in 1:length(best_guess)) {
  o <- best_guess[[i]] %>%
    transmute(guess = g, color1 = p1, color2 = p2, color3 = p3, color4 = p4,
              color5 = p5, remaining = answer_count, remaining_list = answers,
              letter1 = g_p1, letter2 = g_p2, letter3 = g_p3, letter4 = g_p4,
              letter5 = g_p5, previous_outcome_row_number = id, best_guess,
              avg_remaining = avg_remaining, min_remaining = min_remaining,
              max_remaining = max_remaining, row_number = row_number())
  names(o)[1:13] <- paste0('guess', i, '_', names(o)[1:13])
  names(o)[14:19] <- paste0('guess', i + 1, '_', names(o)[14:19])
  names(o)[1] <- paste0('guess', i)
  names(o)[14] <- paste0('guess', i, '_row_number')
  names(o)[15] <- paste0('best_guess', i + 1)
  optimal_strategy[[i]] <- o
}

saveRDS(optimal_strategy, 'derived_data/optimal_strategy.RDS')

strategy <- optimal_strategy[[1]] %>%
  left_join(optimal_strategy[[2]],
            by = c('guess2_row_number' = 'guess2_row_number')) %>%
  left_join(optimal_strategy[[3]],
            by = c('guess3_row_number' = 'guess3_row_number')) %>%
  left_join(optimal_strategy[[4]],
            by = c('guess4_row_number' = 'guess4_row_number')) %>%
  left_join(optimal_strategy[[5]],
            by = c('guess5_row_number' = 'guess5_row_number')) %>%
  left_join(optimal_strategy[[6]],
            by = c('guess6_row_number' = 'guess6_row_number'))

color_cols <- names(strategy)[grepl('color', names(strategy))] 
for (n in color_cols) strategy[[n]] <- factor(strategy[[n]], levels = c('red', 'yellow', 'green'))
e <- paste0('strategy <- strategy %>% arrange(',
            expand_grid(x = paste0('guess', 1:5),
                        y = c('', paste0('_color', as.character(1:5)))) %>%
              mutate(e = paste(x, y, sep = '')) %>% .$e %>% paste0(collapse = ', '),
            ')')
eval(expr = parse(text = e))

for (n in color_cols)  strategy[[n]] <- as.character(strategy[[n]])

saveRDS(strategy, 'derived_data/strategy.RDS')
strategy <- readRDS('derived_data/strategy.RDS')
            

print_cheat_sheet(optimal_strategy[[1]])

pdf('output_data/Wordle Outcomes.pdf', paper = 'a4', height = 11, width = 8.5)
ind <- 1:50
while (min(ind) < nrow(strategy)) {
  print(ind)
  ind <- seq(min(ind), min(nrow(strategy), max(ind)))
  p <- lapply(ind, function(i) printSingleOutcome(strategy[i, ]))
  do.call("grid.arrange", c(p, nrow = 10, ncol= 5))
  ind <- ind + 50
}
dev.off()

sapply(1:5, function(i) {
  e <- paste0("strategy %>% filter(guess",
              i, "_color1 == 'green' & guess",
              i, "_color2 == 'green' & guess",
              i, "_color3 == 'green' & guess",
              i, "_color4 == 'green' & guess",
              i, "_color5 == 'green') %>% nrow()")
  print(eval(parse(text = e)))
}) %>% sum
