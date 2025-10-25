library(testthat)
source('../../R/data_transformation.R')

test_that("words_to_position_matrix correctly splits words", {
  words <- c("hello", "world")

  result <- words_to_position_matrix(words)

  expect_equal(ncol(result), 5)
  expect_equal(nrow(result), 2)
  expect_equal(result$p1[1], "h")
  expect_equal(result$p5[1], "o")
  expect_equal(result$p1[2], "w")
  expect_equal(result$p5[2], "d")
})

test_that("calculate_letter_counts correctly counts letters", {
  words <- c("hello", "llama")

  result <- calculate_letter_counts(words)

  expect_equal(ncol(result), 26)
  expect_equal(nrow(result), 2)

  # "hello" has 1 h, 1 e, 2 l's, 1 o
  expect_equal(result$h[1], 1)
  expect_equal(result$l[1], 2)
  expect_equal(result$o[1], 1)

  # "llama" has 2 l's, 2 a's, 1 m
  expect_equal(result$l[2], 2)
  expect_equal(result$a[2], 2)
  expect_equal(result$m[2], 1)
})

test_that("calculate_letter_counts handles words with no repeated letters", {
  words <- c("abcde")

  result <- calculate_letter_counts(words)

  # Each letter should appear exactly once
  expect_equal(result$a[1], 1)
  expect_equal(result$b[1], 1)
  expect_equal(result$c[1], 1)
  expect_equal(result$d[1], 1)
  expect_equal(result$e[1], 1)

  # Other letters should be 0
  expect_equal(result$z[1], 0)
})

test_that("words_to_position_matrix works with single word", {
  words <- c("crane")

  result <- words_to_position_matrix(words)

  expect_equal(nrow(result), 1)
  expect_equal(as.character(unlist(result[1,])), c("c", "r", "a", "n", "e"))
})
