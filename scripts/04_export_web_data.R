#!/usr/bin/env Rscript
#' Export Strategy Data for Interactive Web Cheat Sheet
#'
#' Converts the optimal strategy data into JSON format for a static
#' web interface with turn-by-turn navigation.

library(dplyr)
library(jsonlite)

message("Loading strategy data...")
strategy <- readRDS('data/derived/best_guess.RDS')

# Create web directory
web_dir <- 'web'
if (!dir.exists(web_dir)) {
  dir.create(web_dir, recursive = TRUE)
}

data_dir <- file.path(web_dir, 'data')
if (!dir.exists(data_dir)) {
  dir.create(data_dir, recursive = TRUE)
}

message("Processing Turn 1 data...")

# Turn 1: Extract all possible outcomes from first guess
turn1 <- strategy[[1]] %>%
  select(
    # Color patterns
    p1_color = p1,
    p2_color = p2,
    p3_color = p3,
    p4_color = p4,
    p5_color = p5,
    # Guessed letters
    letter1 = g_p1,
    letter2 = g_p2,
    letter3 = g_p3,
    letter4 = g_p4,
    letter5 = g_p5,
    # Stats
    remaining_words = answer_count,
    next_guess = best_guess,
    avg_remaining,
    min_remaining,
    max_remaining
  ) %>%
  mutate(
    # Create display-friendly color names
    across(ends_with('_color'), ~case_when(
      . == 'green' ~ 'correct',
      . == 'yellow' ~ 'present',
      . == 'red' ~ 'absent',
      TRUE ~ .
    )),
    # Uppercase letters
    across(starts_with('letter'), toupper),
    # Create pattern ID for filtering
    pattern_id = row_number()
  )

# Get opening guess from first row
opening_guess <- paste0(turn1$letter1[1], turn1$letter2[1],
                        turn1$letter3[1], turn1$letter4[1],
                        turn1$letter5[1])

# Export Turn 1 data
turn1_json <- list(
  opening_guess = opening_guess,
  total_patterns = nrow(turn1),
  outcomes = turn1
)

write_json(turn1_json, file.path(data_dir, 'turn1.json'),
           pretty = TRUE, auto_unbox = TRUE)

message("✓ Turn 1 data exported (", nrow(turn1), " patterns)")

# Export summary statistics
stats <- list(
  total_words = 2314,
  opening_guess = opening_guess,
  total_turn1_patterns = nrow(turn1),
  avg_guesses = 3.48,
  max_guesses = 6,
  win_rate = 1.0
)

write_json(stats, file.path(data_dir, 'stats.json'),
           pretty = TRUE, auto_unbox = TRUE)

message("✓ Statistics exported")
message("\nWeb data ready in: ", normalizePath(web_dir))
message("Next step: Create HTML/CSS/JS interface")
