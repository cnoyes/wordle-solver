#!/usr/bin/env Rscript

#' Interactive Wordle Solver CLI
#'
#' Play Wordle with the optimal solver providing suggestions at each turn.
#'
#' Usage: Rscript scripts/play_wordle.R

# Load required libraries
library(dplyr)

message("=======================================================")
message("  🎮 Interactive Wordle Solver")
message("=======================================================\n")

# Check for required data
if (!file.exists('data/derived/best_guess.RDS')) {
  stop("Strategy data not found.\n",
       "Please run: Rscript scripts/02_build_strategy.R\n",
       "Or ensure legacy data is copied to data/derived/")
}

# Load data
message("Loading strategy...")
optimal_strategy <- readRDS('data/derived/best_guess.RDS')
message("✓ Strategy loaded (", length(optimal_strategy), " turns)\n")

# Helper functions
color_text <- function(text, color) {
  color_codes <- list(
    green = '\033[32m',
    yellow = '\033[33m',
    red = '\033[31m',
    reset = '\033[0m',
    bold = '\033[1m'
  )
  paste0(color_codes[[color]], text, color_codes$reset)
}

format_wordle_box <- function(letter, color) {
  bg_codes <- list(
    green = '\033[42m',   # Green background
    yellow = '\033[43m',  # Yellow background
    red = '\033[47m',     # White/gray background
    reset = '\033[0m'
  )
  # Use black text on colored backgrounds
  paste0(bg_codes[[color]], '\033[30m', ' ', toupper(letter), ' ', bg_codes$reset)
}

display_guess <- function(word, colors) {
  letters <- strsplit(word, '')[[1]]
  boxes <- sapply(1:5, function(i) format_wordle_box(letters[i], colors[i]))
  cat(paste(boxes, collapse = ' '), '\n')
}

get_color_input <- function(position) {
  valid <- FALSE
  while (!valid) {
    cat("  Position ", position, " (g=green, y=yellow, r=red): ")
    flush.console()  # Force output before reading input

    # Use scan() which is more reliable than readline()
    input <- scan(file = "stdin", what = character(), n = 1, quiet = TRUE)

    # Handle empty input
    if (length(input) == 0 || is.na(input) || input == "") {
      cat("  Invalid input. Use g/y/r or green/yellow/red\n")
      next
    }

    input <- tolower(trimws(input))

    if (input %in% c('g', 'y', 'r', 'green', 'yellow', 'red')) {
      valid <- TRUE
      return(switch(input,
                    'g' = 'green', 'green' = 'green',
                    'y' = 'yellow', 'yellow' = 'yellow',
                    'r' = 'red', 'red' = 'red'))
    } else {
      cat("  Invalid input. Use g/y/r or green/yellow/red\n")
    }
  }
}

# Main game loop
cat("\n", color_text("📖 HOW TO PLAY", "bold"), "\n")
cat("1. I'll suggest the optimal guess\n")
cat("2. Enter this word into Wordle\n")
cat("3. Tell me the color feedback you received\n")
cat("4. Repeat until solved!\n\n")

cat(color_text("Color codes:", "bold"), "\n")
cat("  ", format_wordle_box('L', 'green'), " = Letter in correct position (green)\n")
cat("  ", format_wordle_box('L', 'yellow'), " = Letter in word, wrong position (yellow)\n")
cat("  ", format_wordle_box('L', 'red'), " = Letter not in word (gray)\n\n")

# Track game state
turn <- 1
current_strategy <- optimal_strategy[[1]]
previous_row <- NA
game_history <- list()

# Game loop
while (turn <= 6) {
  cat("\n", rep("=", 55), "\n", sep = "")
  cat(color_text(paste("  TURN", turn), "bold"), "\n")
  cat(rep("=", 55), "\n", sep = "")

  # Get optimal guess for current state
  if (turn == 1) {
    # Turn 1: Use the fixed opening guess
    best_guess_word <- current_strategy$g[1]
    row_to_use <- 1
  } else {
    # Turn 2+: Use best_guess from previous turn
    if (!is.na(previous_row)) {
      best_guess_word <- current_strategy$best_guess[previous_row]
      # Handle case where best_guess is a list
      if (is.list(best_guess_word)) {
        best_guess_word <- best_guess_word[[1]][1]
      }
    } else {
      best_guess_word <- current_strategy$best_guess[1]
      if (is.list(best_guess_word)) {
        best_guess_word <- best_guess_word[[1]][1]
      }
    }
  }

  cat("\n", color_text("💡 Optimal guess:", "green"), " ",
      color_text(toupper(best_guess_word), "bold"), "\n\n")

  # Show remaining possibilities
  if (turn > 1 && !is.na(previous_row)) {
    if ('answer_count' %in% names(current_strategy)) {
      remaining <- current_strategy$answer_count[previous_row]
      if (!is.na(remaining) && remaining > 1) {
        cat("   (", remaining, " possible answers remaining)\n\n")
      }
    }
  }

  # Get user feedback
  cat("Enter the color feedback you received:\n")
  colors <- sapply(1:5, get_color_input)

  # Display the guess with colors
  cat("\nYou entered:\n")
  display_guess(best_guess_word, colors)

  # Check for win
  if (all(colors == 'green')) {
    cat("\n", rep("=", 55), "\n", sep = "")
    cat(color_text("  🎉 CONGRATULATIONS! 🎉", "bold"), "\n")
    cat(rep("=", 55), "\n", sep = "")
    cat("\nSolved in ", turn, " guess", if(turn > 1) "es" else "", "!\n\n", sep = "")

    # Show game summary
    cat(color_text("Game Summary:", "bold"), "\n")
    for (i in seq_along(game_history)) {
      cat("Turn ", i, ": ")
      display_guess(game_history[[i]]$word, game_history[[i]]$colors)
    }
    cat("Turn ", turn, ": ")
    display_guess(best_guess_word, colors)
    cat("\n")
    quit(save = "no", status = 0)
  }

  # Save turn to history
  game_history[[turn]] <- list(word = best_guess_word, colors = colors)

  # Find matching row in next turn's strategy
  if (turn < 6) {
    next_strategy <- optimal_strategy[[turn + 1]]

    # Build filter for matching outcome (using p1-p5 columns)
    color_match <- next_strategy$p1 == colors[1] &
                   next_strategy$p2 == colors[2] &
                   next_strategy$p3 == colors[3] &
                   next_strategy$p4 == colors[4] &
                   next_strategy$p5 == colors[5]

    matching_rows <- which(color_match)

    if (length(matching_rows) == 0) {
      cat("\n", color_text("⚠️  Warning:", "yellow"), " Could not find matching outcome.\n")
      cat("This shouldn't happen with valid inputs. Check your color entries.\n")
      break
    }

    previous_row <- matching_rows[1]
    current_strategy <- next_strategy
  }

  turn <- turn + 1
}

if (turn > 6) {
  cat("\n", rep("=", 55), "\n", sep = "")
  cat(color_text("  Game Over - Not solved in 6 guesses", "red"), "\n")
  cat(rep("=", 55), "\n\n", sep = "")
}
