#!/usr/bin/env Rscript

#' Setup Script: Download and Transform Wordle Data
#'
#' This script performs initial setup:
#' 1. Downloads word lists from Wordle source
#' 2. Transforms words into optimized data structures
#' 3. Generates boolean filters for fast computation
#'
#' Run this once before running the solver.

# Load functions
source('R/data_acquisition.R')
source('R/data_transformation.R')
source('R/solver_core.R')

library(dplyr)
library(tidyr)

message("=======================================================")
message("  Wordle Solver - Data Setup")
message("=======================================================\n")

# Step 1: Load word lists (use existing or download)
message("\n[Step 1/3] Loading Wordle word lists...")
tryCatch({
  # Check if word files already exist
  if (file.exists('data/raw/answer_words.txt') && file.exists('data/raw/guess_words.txt')) {
    message("Using existing word lists from data/raw/")
    words <- load_wordle_words(data_dir = 'data/raw')
    message("✓ Loaded ", length(words$answer_words), " answer words")
    message("✓ Loaded ", length(words$guess_words), " guess words")
  } else {
    message("Downloading word lists from Wordle source...")
    words <- download_wordle_words(output_dir = 'data/raw')
    message("✓ Downloaded ", length(words$answer_words), " answer words")
    message("✓ Downloaded ", length(words$guess_words), " guess words")
  }
}, error = function(e) {
  stop("Failed to load/download words: ", e$message)
})

# Step 2: Transform word lists
message("\n[Step 2/3] Transforming word lists...")
tryCatch({
  # Combine answer and guess words for guess list
  all_guess_words <- sort(unique(c(words$answer_words, words$guess_words)))

  transformed <- transform_word_lists(
    answer_words = words$answer_words,
    guess_words = all_guess_words,
    output_dir = 'data/processed'
  )
  message("✓ Transformed data saved")
}, error = function(e) {
  stop("Failed to transform data: ", e$message)
})

# Step 3: Note about boolean filters
message("\n[Step 3/3] Boolean filter generation...")
message("✓ Boolean filters will be generated during strategy building")
message("  (They require global environment variables)")
message("")

message("\n=======================================================")
message("  Setup Complete!")
message("=======================================================")
message("\nNext steps:")
message("  1. Run scripts/02_build_strategy.R to compute optimal strategy")
message("  2. Or run scripts/play_wordle.R for interactive play")
message("\nNote: Building the full strategy tree takes 18-30 minutes")
