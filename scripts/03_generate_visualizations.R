#!/usr/bin/env Rscript

#' Generate Visualizations
#'
#' Creates PDF cheat sheets and outcome visualizations from the
#' pre-computed optimal strategy.

# Load functions
source('R/visualization.R')

library(dplyr)
library(grid)
library(gridExtra)

message("=======================================================")
message("  Wordle Solver - Generating Visualizations")
message("=======================================================\n")

# Load optimal strategy
message("Loading optimal strategy...")
if (!file.exists('data/derived/optimal_strategy.RDS')) {
  stop("Optimal strategy not found. Run scripts/02_build_strategy.R first.")
}

optimal_strategy <- readRDS('data/derived/optimal_strategy.RDS')
strategy <- readRDS('data/derived/strategy.RDS')

message("✓ Loaded optimal strategy")

# Create output directory
dir.create('output', showWarnings = FALSE)

# Generate Turn 1 cheat sheet
message("\n[1/2] Generating Turn 1 cheat sheet...")
message("  This shows the optimal 2nd guess for each outcome from the opening guess")
print_cheat_sheet(
  optimal_strategy[[1]],
  output_file = 'output/turn1_cheat_sheet.pdf'
)
message("  ✓ Saved: output/turn1_cheat_sheet.pdf")

# Generate all outcomes PDF (warning: large file!)
message("\n[2/2] Generating complete outcomes visualization...")
message("  WARNING: This creates a large PDF with all possible game paths")
message("  This may take several minutes...")

user_response <- readline(prompt = "Continue? (y/n): ")
if (tolower(user_response) == 'y') {
  generate_outcomes_pdf(
    strategy,
    output_file = 'output/all_outcomes.pdf',
    outcomes_per_page = 50
  )
  message("  ✓ Saved: output/all_outcomes.pdf")
} else {
  message("  Skipped all outcomes PDF")
}

# Calculate success statistics
message("\nCalculating solver statistics...")
wins_by_turn <- sapply(1:6, function(turn_num) {
  filter_expr <- paste0(
    "strategy %>% filter(guess", turn_num,
    "_color1 == 'green' & guess", turn_num,
    "_color2 == 'green' & guess", turn_num,
    "_color3 == 'green' & guess", turn_num,
    "_color4 == 'green' & guess", turn_num,
    "_color5 == 'green') %>% nrow()"
  )
  eval(parse(text = filter_expr))
})

total_wins <- sum(wins_by_turn)
total_answers <- length(readRDS('data/processed/answer_words.RDS'))

message("\n=======================================================")
message("  Solver Performance Statistics")
message("=======================================================")
message("Total possible answers: ", total_answers)
message("Total winning paths: ", total_wins)
message("\nWins by turn:")
for (i in seq_along(wins_by_turn)) {
  if (wins_by_turn[i] > 0) {
    pct <- round(100 * wins_by_turn[i] / total_answers, 1)
    message("  Turn ", i, ": ", wins_by_turn[i], " (", pct, "%)")
  }
}
message("\nAverage guesses to win: ", round(sum(wins_by_turn * seq_along(wins_by_turn)) / total_wins, 2))
message("\n=======================================================")
message("  Visualization Complete!")
message("=======================================================")
message("\nGenerated files:")
message("  - output/turn1_cheat_sheet.pdf")
if (tolower(user_response) == 'y') {
  message("  - output/all_outcomes.pdf")
}
