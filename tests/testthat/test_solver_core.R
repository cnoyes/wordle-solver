library(testthat)
source('../../R/data_transformation.R')
source('../../R/solver_core.R')
library(dplyr)
library(tidyr)

test_that("calc_best_guess returns valid structure", {
  # Simple test case
  guess_words <- c("crane", "stale", "irate")
  answer_words <- c("crane", "stale")

  guess_mat <- words_to_position_matrix(guess_words)
  answer_mat <- words_to_position_matrix(answer_words)
  names(guess_mat) <- paste0('g_', names(guess_mat))
  names(answer_mat) <- paste0('a_', names(answer_mat))

  result <- calc_best_guess(guess_words, answer_words, guess_mat, answer_mat)

  # Check structure
  expect_type(result, "list")
  expect_true("guess" %in% names(result))
  expect_true("avg_remaining" %in% names(result))
  expect_true("min_remaining" %in% names(result))
  expect_true("max_remaining" %in% names(result))
  expect_true("best_guess" %in% names(result))
  expect_true("guess_summary" %in% names(result))

  # Check that guess is one of the valid words
  expect_true(result$guess %in% guess_words)

  # Check that best_guess tibble has correct columns
  expect_true("answer_count" %in% names(result$best_guess))
  expect_true("answers" %in% names(result$best_guess))
})

test_that("calc_best_guess handles single answer correctly", {
  guess_words <- c("crane")
  answer_words <- c("crane")

  guess_mat <- words_to_position_matrix(guess_words)
  answer_mat <- words_to_position_matrix(answer_words)
  names(guess_mat) <- paste0('g_', names(guess_mat))
  names(answer_mat) <- paste0('a_', names(answer_mat))

  result <- calc_best_guess(guess_words, answer_words, guess_mat, answer_mat)

  # When there's only one possible answer, should guess it
  expect_equal(result$guess, "crane")

  # Should have 0 remaining after guessing correctly
  expect_equal(result$min_remaining, 0)
})

test_that("calc_best_guess correctly identifies green matches", {
  # If we guess "crane" and answer is "crane", should see all greens
  guess_words <- c("crane")
  answer_words <- c("crane", "brake")

  guess_mat <- words_to_position_matrix(guess_words)
  answer_mat <- words_to_position_matrix(answer_words)
  names(guess_mat) <- paste0('g_', names(guess_mat))
  names(answer_mat) <- paste0('a_', names(answer_mat))

  result <- calc_best_guess(guess_words, answer_words, guess_mat, answer_mat)

  # Should have an outcome where all 5 are green (matching "crane")
  all_green_outcome <- result$best_guess %>%
    filter(p1 == 'green', p2 == 'green', p3 == 'green', p4 == 'green', p5 == 'green')

  expect_equal(nrow(all_green_outcome), 1)
  expect_equal(all_green_outcome$answer_count, 0)  # No answers remain after perfect match
})

test_that("calc_best_guess score prefers guesses that reduce uncertainty", {
  # With more diverse outcomes, average remaining should be lower
  guess_words <- c("salet", "zzzzz")  # salet is known to be a good opener
  answer_words <- c("crane", "stale", "brake", "drake")

  guess_mat <- words_to_position_matrix(guess_words)
  answer_mat <- words_to_position_matrix(answer_words)
  names(guess_mat) <- paste0('g_', names(guess_mat))
  names(answer_mat) <- paste0('a_', names(answer_mat))

  result <- calc_best_guess(guess_words, answer_words, guess_mat, answer_mat)

  # Should prefer a real word over nonsense
  expect_equal(result$guess, "salet")
})
