#' Transform Words to Position Matrix
#'
#' Converts a vector of 5-letter words into a matrix where each column
#' represents a letter position (1-5).
#'
#' @param words Character vector of 5-letter words
#'
#' @return Tibble with columns p1, p2, p3, p4, p5 containing letters
#' @export
words_to_position_matrix <- function(words) {

  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("Package 'dplyr' is required.")
  }

  # Split each word into individual letters
  m <- matrix(
    unlist(lapply(words, function(x) strsplit(x, '')[[1]])),
    byrow = TRUE,
    ncol = 5
  )

  # Convert to tibble with named columns
  m <- dplyr::as_tibble(m)
  names(m) <- c('p1', 'p2', 'p3', 'p4', 'p5')

  return(m)
}


#' Calculate Letter Counts for Words
#'
#' For each word, counts how many times each letter of the alphabet appears.
#' This is used for fast filtering during game state evaluation.
#'
#' @param words Character vector of 5-letter words
#'
#' @return Tibble with 26 columns (one per letter) containing letter counts
#' @export
calculate_letter_counts <- function(words) {

  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("Package 'dplyr' is required.")
  }

  # Initialize count matrix: rows = words, columns = letters
  count_matrix <- matrix(0, nrow = length(words), ncol = 26)
  colnames(count_matrix) <- letters
  rownames(count_matrix) <- words

  # Count letter occurrences for each word
  for (i in seq_along(words)) {
    word_letters <- strsplit(words[i], '')[[1]]
    for (letter in word_letters) {
      count_matrix[i, letter] <- count_matrix[i, letter] + 1
    }
  }

  # Convert to tibble
  count_tibble <- dplyr::as_tibble(count_matrix)

  return(count_tibble)
}


#' Transform Word Lists to Analysis-Ready Format
#'
#' Main pipeline function that converts raw word lists into optimized
#' data structures for the Wordle solver algorithm.
#'
#' @param answer_words Character vector of answer words
#' @param guess_words Character vector of guess words
#' @param output_dir Character. Directory to save transformed data
#'
#' @return Named list containing:
#'   - answer_mat: Position matrix for answer words
#'   - guess_mat: Position matrix for guess words
#'   - answer_count: Letter count matrix for answer words
#'   - guess_count: Letter count matrix for guess words
#' @export
transform_word_lists <- function(answer_words, guess_words, output_dir = 'data/processed') {

  message("Transforming word lists...")

  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Transform answer words
  message("Processing ", length(answer_words), " answer words...")
  answer_mat <- words_to_position_matrix(answer_words)
  answer_count <- calculate_letter_counts(answer_words)

  # Prefix column names
  names(answer_mat) <- paste0('a_', names(answer_mat))

  # Transform guess words
  message("Processing ", length(guess_words), " guess words...")
  guess_mat <- words_to_position_matrix(guess_words)
  guess_count <- calculate_letter_counts(guess_words)

  # Prefix column names
  names(guess_mat) <- paste0('g_', names(guess_mat))

  # Save as RDS files
  saveRDS(answer_words, file.path(output_dir, 'answer_words.RDS'))
  saveRDS(guess_words, file.path(output_dir, 'guess_words.RDS'))
  saveRDS(answer_mat, file.path(output_dir, 'answer_mat.RDS'))
  saveRDS(guess_mat, file.path(output_dir, 'guess_mat.RDS'))
  saveRDS(answer_count, file.path(output_dir, 'answer_count.RDS'))
  saveRDS(guess_count, file.path(output_dir, 'guess_count.RDS'))

  message("Saved transformed data to: ", output_dir)

  return(list(
    answer_words = answer_words,
    guess_words = guess_words,
    answer_mat = answer_mat,
    guess_mat = guess_mat,
    answer_count = answer_count,
    guess_count = guess_count
  ))
}


#' Load Transformed Word Data
#'
#' Loads previously transformed word data from RDS files.
#'
#' @param data_dir Character. Directory containing transformed data files
#'
#' @return Named list with all transformed data structures
#' @export
load_transformed_data <- function(data_dir = 'data/processed') {

  files <- c('answer_words.RDS', 'guess_words.RDS', 'answer_mat.RDS',
             'guess_mat.RDS', 'answer_count.RDS', 'guess_count.RDS')

  for (f in files) {
    if (!file.exists(file.path(data_dir, f))) {
      stop("File not found: ", f, ". Run transform_word_lists() first.")
    }
  }

  return(list(
    answer_words = readRDS(file.path(data_dir, 'answer_words.RDS')),
    guess_words = readRDS(file.path(data_dir, 'guess_words.RDS')),
    answer_mat = readRDS(file.path(data_dir, 'answer_mat.RDS')),
    guess_mat = readRDS(file.path(data_dir, 'guess_mat.RDS')),
    answer_count = readRDS(file.path(data_dir, 'answer_count.RDS')),
    guess_count = readRDS(file.path(data_dir, 'guess_count.RDS'))
  ))
}
