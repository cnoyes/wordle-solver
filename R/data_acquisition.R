#' Download Wordle Word Lists
#'
#' Fetches the official Wordle word lists by scraping the game's JavaScript source.
#' Extracts two lists: answer words (potential solutions) and guess words (all valid guesses).
#'
#' @param url Character. URL to the Wordle JavaScript file. Defaults to the official source.
#' @param output_dir Character. Directory to save the word lists. Defaults to 'data/raw/'.
#'
#' @return Named list with two elements: answer_words and guess_words
#' @export
#'
#' @examples
#' \dontrun{
#'   words <- download_wordle_words()
#'   length(words$answer_words)  # ~2,315 words
#'   length(words$guess_words)   # ~12,972 words
#' }
download_wordle_words <- function(url = 'https://www.powerlanguage.co.uk/wordle/main.e65ce0a5.js',
                                   output_dir = 'data/raw') {

  if (!requireNamespace("httr", quietly = TRUE)) {
    stop("Package 'httr' is required. Install with: install.packages('httr')")
  }

  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Fetch the JavaScript source
  message("Fetching Wordle source from: ", url)
  r <- httr::GET(url)
  d <- httr::content(r, 'text')

  # Extract word lists using regex
  # La = answer words (potential solutions)
  # Ta = guess words (all valid guesses including answers)
  la <- gsub('.+var La=\\["([^\\]]+?)"\\].+', '\\1', d, perl = TRUE)
  ta <- gsub('.+,Ta=\\["([^\\]]+?)"\\].+', '\\1', d, perl = TRUE)

  answer_words <- strsplit(la, '","')[[1]]
  guess_words <- strsplit(ta, '","')[[1]]

  # Filter to 5-letter words only (sanity check)
  answer_words <- answer_words[nchar(answer_words) == 5]
  guess_words <- guess_words[nchar(guess_words) == 5]

  message("Found ", length(answer_words), " answer words")
  message("Found ", length(guess_words), " guess words")

  # Save to files
  answer_file <- file.path(output_dir, 'answer_words.txt')
  guess_file <- file.path(output_dir, 'guess_words.txt')

  writeLines(sort(answer_words), answer_file)
  writeLines(sort(guess_words), guess_file)

  message("Saved to:")
  message("  ", answer_file)
  message("  ", guess_file)

  return(list(
    answer_words = sort(answer_words),
    guess_words = sort(guess_words)
  ))
}


#' Load Wordle Word Lists
#'
#' Loads previously downloaded word lists from text files.
#'
#' @param data_dir Character. Directory containing word list files.
#'
#' @return Named list with two elements: answer_words and guess_words
#' @export
load_wordle_words <- function(data_dir = 'data/raw') {

  answer_file <- file.path(data_dir, 'answer_words.txt')
  guess_file <- file.path(data_dir, 'guess_words.txt')

  if (!file.exists(answer_file) || !file.exists(guess_file)) {
    stop("Word list files not found. Run download_wordle_words() first.")
  }

  answer_words <- readLines(answer_file)
  guess_words <- readLines(guess_file)

  return(list(
    answer_words = answer_words,
    guess_words = guess_words
  ))
}
