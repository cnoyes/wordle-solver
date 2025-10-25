#!/usr/bin/env Rscript

#' Build Complete Optimal Strategy Tree
#'
#' This script builds the complete 6-turn decision tree for optimal Wordle play.
#' WARNING: This is computationally intensive and takes 18-30 minutes to run.
#'
#' The result is a lookup table where you can find the optimal guess for any
#' game state across all 6 possible turns.

# Load functions
source('R/data_transformation.R')
source('R/solver_core.R')
source('R/visualization.R')

library(dplyr)
library(tidyr)

message("=======================================================")
message("  Wordle Solver - Building Optimal Strategy Tree")
message("=======================================================\n")

# Configuration
options(dplyr.summarise.inform = FALSE)

# Load transformed data
message("Loading transformed data...")
data <- load_transformed_data('data/processed')

g <- data$guess_words  # All valid guesses
a <- data$answer_words # Potential solutions
g_mat <- data$guess_mat
a_mat <- data$answer_mat
g_count <- data$guess_count
a_count <- data$answer_count

message("✓ Loaded ", length(g), " guess words")
message("✓ Loaded ", length(a), " answer words")

# Generate boolean filters
message("\nGenerating boolean filters...")
generate_boolean_filters(g, a, g_mat, a_mat, g_count, a_count)

# Build decision tree across 6 turns
best_guess <- list()
results <- list()

message("\n=======================================================")
message("  Building Decision Tree (this will take 18-30 minutes)")
message("=======================================================\n")

# Turn 1: Calculate best opening guess
message("[Turn 1/6] Calculating best opening guess...")
message("  Evaluating ", length(g), " possible guesses for ", length(a), " answers...")
results[[1]] <- calc_best_guess(g, a, g_mat, a_mat)
best_guess[[1]] <- results[[1]]$best_guess %>% mutate(id = NA)
best_guess[[1]]$guesses <- calculate_guesses(best_guess[[1]], g)

message("  ✓ Best opening guess: ", results[[1]]$guess)
message("  ✓ Avg remaining: ", round(results[[1]]$avg_remaining, 2))
message("  ✓ Outcome branches: ", nrow(best_guess[[1]]))

# Turns 2-6: Build tree recursively
for (turn in 2:6) {
  message("\n[Turn ", turn, "/6] Building turn ", turn, " branches...")

  results[[turn]] <- vector("list", nrow(best_guess[[turn - 1]]))

  # For each outcome from previous turn
  active_branches <- which(best_guess[[turn - 1]]$answer_count > 0)
  message("  Processing ", length(active_branches), " active branches...")

  pb_increment <- max(1, floor(length(active_branches) / 20))

  for (j in active_branches) {

    if (j %% pb_increment == 0) {
      message("    Branch ", j, " / ", length(active_branches))
    }

    # Get remaining answers for this branch
    a_subset <- best_guess[[turn - 1]]$answers[[j]]
    g_subset <- g
    a_subset_indices <- which(a %in% a_subset)
    g_subset_indices <- which(g %in% g_subset)
    a_subset_mat <- a_mat[a_subset_indices, ]
    g_subset_mat <- g_mat[g_subset_indices, ]

    # Calculate best guess for this branch
    results[[turn]][[j]] <- calc_best_guess(g_subset, a_subset, g_subset_mat, a_subset_mat)
  }

  # Combine results
  best_guess[[turn]] <- lapply(seq_along(results[[turn]]), function(j) {
    if (!is.null(results[[turn]][[j]])) {
      results[[turn]][[j]]$best_guess %>% mutate(id = j)
    }
  }) %>%
    bind_rows()

  best_guess[[turn]]$guesses <- calculate_guesses(best_guess[[turn]], g)

  message("  ✓ Turn ", turn, " complete: ", nrow(best_guess[[turn]]), " outcome branches")
}

# Save intermediate results
message("\nSaving intermediate results...")
dir.create('data/derived', showWarnings = FALSE, recursive = TRUE)
saveRDS(results, 'data/derived/results.RDS')
message("✓ Saved results.RDS")

# Add best_guess recommendations to each level
message("\nAssembling strategy tree...")
for (i in 2:length(best_guess)) {
  best_guess[[i - 1]]$best_guess <- sapply(results[[i]], function(x) x$guess)
  best_guess[[i - 1]]$avg_remaining <- sapply(results[[i]], function(x) x$avg_remaining)
  best_guess[[i - 1]]$min_remaining <- sapply(results[[i]], function(x) x$min_remaining)
  best_guess[[i - 1]]$max_remaining <- sapply(results[[i]], function(x) x$max_remaining)
}

# Handle final turn - extract first remaining answer for each branch
final_turn <- best_guess[[length(best_guess)]]
final_turn$best_guess <- sapply(final_turn$answers, function(x) {
  if (length(x) > 0) x[1] else NA_character_
})
final_turn$avg_remaining <- vector("list", nrow(final_turn))
final_turn$min_remaining <- vector("list", nrow(final_turn))
final_turn$max_remaining <- vector("list", nrow(final_turn))
best_guess[[length(best_guess)]] <- final_turn

# Clean up best_guess columns
for (i in seq_along(best_guess)) {
  best_guess[[i]]$best_guess <- ifelse(
    best_guess[[i]]$answer_count == 0, NA,
    ifelse(sapply(best_guess[[i]]$best_guess, is.null),
           sapply(best_guess[[i]]$answers, function(x) x[1]),
           sapply(best_guess[[i]]$best_guess, function(x) x[1]))
  ) %>% unlist()

  best_guess[[i]]$avg_remaining <- ifelse(
    best_guess[[i]]$answer_count == 0, NA,
    ifelse(sapply(best_guess[[i]]$avg_remaining, is.null), 1,
           sapply(best_guess[[i]]$avg_remaining, function(x) x[1]))
  ) %>% unlist()

  best_guess[[i]]$min_remaining <- ifelse(
    best_guess[[i]]$answer_count == 0, NA,
    ifelse(sapply(best_guess[[i]]$min_remaining, is.null), 1,
           sapply(best_guess[[i]]$min_remaining, function(x) x[1]))
  ) %>% unlist()

  best_guess[[i]]$max_remaining <- ifelse(
    best_guess[[i]]$answer_count == 0, NA,
    ifelse(sapply(best_guess[[i]]$max_remaining, is.null), 1,
           sapply(best_guess[[i]]$max_remaining, function(x) x[1]))
  ) %>% unlist()
}

saveRDS(best_guess, 'data/derived/best_guess.RDS')
message("✓ Saved best_guess.RDS")

# Create optimal strategy format
message("\nFormatting optimal strategy...")
optimal_strategy <- list()
for (i in seq_along(best_guess)) {
  o <- best_guess[[i]] %>%
    transmute(
      guess = g, color1 = p1, color2 = p2, color3 = p3, color4 = p4, color5 = p5,
      remaining = answer_count, remaining_list = answers,
      letter1 = g_p1, letter2 = g_p2, letter3 = g_p3, letter4 = g_p4, letter5 = g_p5,
      previous_outcome_row_number = id, best_guess,
      avg_remaining, min_remaining, max_remaining, row_number = row_number()
    )
  names(o)[1:13] <- paste0('guess', i, '_', names(o)[1:13])
  names(o)[14:19] <- paste0('guess', i + 1, '_', names(o)[14:19])
  names(o)[1] <- paste0('guess', i)
  names(o)[14] <- paste0('guess', i, '_row_number')
  names(o)[15] <- paste0('best_guess', i + 1)
  optimal_strategy[[i]] <- o
}

saveRDS(optimal_strategy, 'data/derived/optimal_strategy.RDS')
message("✓ Saved optimal_strategy.RDS")

# Build complete strategy table
message("\nBuilding complete strategy lookup table...")
strategy <- optimal_strategy[[1]] %>%
  left_join(optimal_strategy[[2]], by = c('guess2_row_number' = 'guess2_row_number')) %>%
  left_join(optimal_strategy[[3]], by = c('guess3_row_number' = 'guess3_row_number')) %>%
  left_join(optimal_strategy[[4]], by = c('guess4_row_number' = 'guess4_row_number')) %>%
  left_join(optimal_strategy[[5]], by = c('guess5_row_number' = 'guess5_row_number')) %>%
  left_join(optimal_strategy[[6]], by = c('guess6_row_number' = 'guess6_row_number'))

# Sort by all color columns
color_cols <- names(strategy)[grepl('color', names(strategy))]
for (n in color_cols) {
  strategy[[n]] <- factor(strategy[[n]], levels = c('red', 'yellow', 'green'))
}

sort_expr <- paste0(
  'strategy <- strategy %>% arrange(',
  expand_grid(x = paste0('guess', 1:5), y = c('', paste0('_color', 1:5))) %>%
    mutate(e = paste(x, y, sep = '')) %>%
    pull(e) %>%
    paste0(collapse = ', '),
  ')'
)
eval(parse(text = sort_expr))

# Convert back to character
for (n in color_cols) {
  strategy[[n]] <- as.character(strategy[[n]])
}

saveRDS(strategy, 'data/derived/strategy.RDS')
message("✓ Saved strategy.RDS")

message("\n=======================================================")
message("  Strategy Tree Complete!")
message("=======================================================")
message("\nGenerated files:")
message("  - data/derived/results.RDS (raw results)")
message("  - data/derived/best_guess.RDS (per-turn decisions)")
message("  - data/derived/optimal_strategy.RDS (formatted strategy)")
message("  - data/derived/strategy.RDS (complete lookup table)")
message("\nNext steps:")
message("  1. Run scripts/03_generate_visualizations.R to create cheat sheets")
message("  2. Run scripts/play_wordle.R for interactive play")
