#!/usr/bin/env Rscript

#' Build Strategy with Diagnostic Output
#'
#' This version adds detailed error handling and memory monitoring

# Set up error handling
options(error = function() {
  cat("\n\n=== ERROR OCCURRED ===\n")
  traceback(2)
  quit(status = 1)
})

# Load functions
source('R/data_transformation.R')
source('R/solver_core.R')
source('R/visualization.R')

library(dplyr)
library(tidyr)

message("=======================================================")
message("  Wordle Solver - Building Strategy (DIAGNOSTIC MODE)")
message("=======================================================\n")

# Configuration
options(dplyr.summarise.inform = FALSE)

# Load transformed data
message("Loading transformed data...")
data <- load_transformed_data('data/processed')

g <- data$guess_words
a <- data$answer_words
g_mat <- data$guess_mat
a_mat <- data$answer_mat
g_count <- data$guess_count
a_count <- data$answer_count

message("✓ Loaded ", length(g), " guess words")
message("✓ Loaded ", length(a), " answer words")

# Check memory before starting
message("\nMemory before starting:")
system("ps -o rss,vsz -p $PPID | tail -1")

# Generate boolean filters
message("\nGenerating boolean filters...")
generate_boolean_filters(g, a, g_mat, a_mat, g_count, a_count)
message("Boolean filters generated successfully")

# Build decision tree
best_guess <- list()
results <- list()

message("\n=======================================================")
message("  Building Decision Tree (DIAGNOSTIC MODE)")
message("=======================================================\n")

# Turn 1: Calculate best opening guess
message("[Turn 1/6] Calculating best opening guess...")
message("  Guess words: ", length(g))
message("  Answer words: ", length(a))
message("  Total combinations: ", format(length(g) * length(a), big.mark = ","))

message("\n  Creating expand_grid...")
flush.console()

tryCatch({
  # Monitor memory during the critical operation
  message("  Memory before expand_grid:")
  system("ps -o rss,vsz -p $PPID | tail -1")

  message("\n  Calling calc_best_guess()...")
  flush.console()

  # Run with progress monitoring
  start_time <- Sys.time()
  results[[1]] <- calc_best_guess(g, a, g_mat, a_mat)
  end_time <- Sys.time()

  message("\n  ✓ Turn 1 completed!")
  message("  Duration: ", round(difftime(end_time, start_time, units = "mins"), 2), " minutes")
  message("  Best opening guess: ", results[[1]]$guess)
  message("  Avg remaining: ", round(results[[1]]$avg_remaining, 2))

  message("\n  Memory after calc_best_guess:")
  system("ps -o rss,vsz -p $PPID | tail -1")

  best_guess[[1]] <- results[[1]]$best_guess %>% mutate(id = NA)
  best_guess[[1]]$guesses <- calculate_guesses(best_guess[[1]], g)

  message("  ✓ Outcome branches: ", nrow(best_guess[[1]]))

}, error = function(e) {
  message("\n!!! ERROR during Turn 1 calculation !!!")
  message("Error message: ", e$message)
  message("\nMemory at time of error:")
  system("ps -o rss,vsz -p $PPID | tail -1")
  quit(status = 1)
})

message("\n=======================================================")
message("  Turn 1 Complete - Stopping for now")
message("=======================================================")
message("\nIf Turn 1 succeeded, the full build can proceed.")
message("Run the regular 02_build_strategy.R to complete all 6 turns.")
