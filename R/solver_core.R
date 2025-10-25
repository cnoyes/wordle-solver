#' Calculate Best Guess for Current Game State
#'
#' Given a set of possible guesses and remaining answers, calculates the optimal
#' next guess using a minimax-inspired scoring function that minimizes the
#' expected number of remaining possibilities.
#'
#' @param guess_words Character vector of valid guesses
#' @param answer_words Character vector of remaining possible answers
#' @param guess_mat Tibble with letter positions for guess words
#' @param answer_mat Tibble with letter positions for answer words
#'
#' @return List containing:
#'   - guess: The optimal guess word
#'   - avg_remaining: Average remaining answers after this guess
#'   - min_remaining: Minimum remaining answers (best case)
#'   - max_remaining: Maximum remaining answers (worst case)
#'   - best_guess: Detailed tibble with all outcome patterns
#'   - guess_summary: Summary statistics for all considered guesses
#' @export
calc_best_guess <- function(guess_words, answer_words, guess_mat, answer_mat) {

  if (!requireNamespace("dplyr", quietly = TRUE) ||
      !requireNamespace("tidyr", quietly = TRUE)) {
    stop("Packages 'dplyr' and 'tidyr' are required.")
  }

  # Generate all combinations of guesses x answers
  combinations <- tidyr::expand_grid(g = guess_words, a = answer_words) %>%
    dplyr::bind_cols(guess_mat[rep(1:nrow(guess_mat), each = nrow(answer_mat)), ]) %>%
    dplyr::bind_cols(answer_mat[rep(1:nrow(answer_mat), nrow(guess_mat)), ])

  # Calculate color feedback for each position
  for (i in 1:5) {
    # Green: letter in correct position
    green_expr <- paste0('combinations$green_', i, ' <- combinations$g_p', i, ' == combinations$a_p', i)

    # Red: letter not in word at all
    red_expr <- paste0(
      'combinations$red_', i, ' <- combinations$g_p', i, ' != combinations$a_p1 & ',
      'combinations$g_p', i, ' != combinations$a_p2 & ',
      'combinations$g_p', i, ' != combinations$a_p3 & ',
      'combinations$g_p', i, ' != combinations$a_p4 & ',
      'combinations$g_p', i, ' != combinations$a_p5'
    )

    # Yellow: letter in word but wrong position
    color_expr <- paste0(
      'combinations$p', i, ' <- ifelse(combinations$green_', i,
      ", 'green', ifelse(combinations$red_", i, ", 'red', 'yellow'))"
    )

    eval(parse(text = green_expr))
    eval(parse(text = red_expr))
    eval(parse(text = color_expr))
  }

  # Mark exact matches (all green)
  combinations$exact_match <-
    combinations$p1 == 'green' &
    combinations$p2 == 'green' &
    combinations$p3 == 'green' &
    combinations$p4 == 'green' &
    combinations$p5 == 'green'

  # Group by guess and outcome pattern
  outcomes <- combinations %>%
    dplyr::group_by(g, g_p1, g_p2, g_p3, g_p4, g_p5, p1, p2, p3, p4, p5) %>%
    dplyr::summarize(answer_count = sum(!exact_match), .groups = 'drop')

  # Score each guess
  # Uses sum(count^2) / n to penalize worst-case outcomes
  guess_summary <- outcomes %>%
    dplyr::group_by(g) %>%
    dplyr::summarize(
      avg_remaining = sum(answer_count ^ 2) / dplyr::n(),
      min_remaining = min(answer_count),
      max_remaining = max(answer_count),
      .groups = 'drop'
    ) %>%
    dplyr::mutate(in_answer_list = g %in% answer_words)

  # Select best guess (minimize avg_remaining, prefer words in answer list)
  best_row <- guess_summary %>%
    dplyr::arrange(avg_remaining, dplyr::desc(in_answer_list), g) %>%
    dplyr::slice(1)

  best_word <- best_row$g
  avg_rem <- best_row$avg_remaining
  min_rem <- best_row$min_remaining
  max_rem <- best_row$max_remaining

  # Get detailed outcome breakdown for best guess
  best_guess_detail <- combinations %>%
    dplyr::filter(g == best_word) %>%
    dplyr::group_by(g, g_p1, g_p2, g_p3, g_p4, g_p5, p1, p2, p3, p4, p5) %>%
    dplyr::summarize(
      answer_count = sum(!exact_match),
      answers = list(a[!exact_match]),
      .groups = 'drop'
    )

  return(list(
    outcomes = outcomes,
    guess = best_word,
    guess_summary = guess_summary,
    best_guess = best_guess_detail,
    avg_remaining = avg_rem,
    min_remaining = min_rem,
    max_remaining = max_rem
  ))
}


#' Generate Boolean Filters for Fast Word Filtering
#'
#' Pre-generates boolean vectors for filtering words based on letter positions
#' and counts. This dramatically speeds up filtering during game tree exploration.
#'
#' @param guess_words Character vector of guess words
#' @param answer_words Character vector of answer words
#' @param guess_mat Position matrix for guess words
#' @param answer_mat Position matrix for answer words
#' @param guess_count Letter count matrix for guess words
#' @param answer_count Letter count matrix for answer words
#' @param envir Environment to store boolean vectors (defaults to global)
#'
#' @return NULL (side effect: creates boolean vectors in specified environment)
#' @export
generate_boolean_filters <- function(guess_words, answer_words,
                                      guess_mat, answer_mat,
                                      guess_count, answer_count,
                                      envir = .GlobalEnv) {

  if (!requireNamespace("tidyr", quietly = TRUE)) {
    stop("Package 'tidyr' is required.")
  }

  message("Generating boolean filters...")

  # Position-based filters (e.g., g_p1_equal_a, a_p2_not_equal_s)
  position_filters <- tidyr::expand_grid(
    p = c('p1', 'p2', 'p3', 'p4', 'p5'),
    l = letters,
    m = c('a', 'g')
  ) %>%
    dplyr::mutate(p = paste0(m, '_', p)) %>%
    dplyr::mutate(
      equal_expr = paste0(p, "_equal_", l, " <- ", m, "_mat$", p, " == '", l, "'"),
      not_equal_expr = paste0(p, "_not_equal_", l, " <- ", m, "_mat$", p, " != '", l, "'")
    )

  for (expr in position_filters$equal_expr) {
    eval(parse(text = expr), envir = envir)
  }
  for (expr in position_filters$not_equal_expr) {
    eval(parse(text = expr), envir = envir)
  }

  # Count-based filters (e.g., g_s_equal_2, a_e_greater_1)
  count_filters <- tidyr::expand_grid(
    l = letters,
    c = 0:5,
    m = c('a', 'g')
  ) %>%
    dplyr::mutate(
      equal_expr = paste0(m, "_", l, "_equal_", c, " <- ", m, "_count$", l, " == ", c),
      greater_expr = paste0(m, "_", l, "_greater_", c, " <- ", m, "_count$", l, " >= ", c)
    )

  for (expr in count_filters$equal_expr) {
    eval(parse(text = expr), envir = envir)
  }
  for (expr in count_filters$greater_expr) {
    eval(parse(text = expr), envir = envir)
  }

  message("Boolean filters generated successfully")
  invisible(NULL)
}


#' Calculate Guesses from Best Guess Tibble
#'
#' Uses pre-generated boolean filters to extract the actual guess words
#' for each outcome pattern.
#'
#' @param best_guess Tibble from calc_best_guess() containing outcome patterns
#' @param guess_words Character vector of all valid guesses (needed for filtering)
#'
#' @return List of character vectors, one per row in best_guess
#' @export
calculate_guesses <- function(best_guess, guess_words) {

  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("Package 'dplyr' is required.")
  }

  # Build boolean expression for each outcome
  boolean_expressions <- best_guess %>%
    dplyr::mutate(
      e1 = ifelse(p1 == 'green', paste0('g_p1_equal_', g_p1),
                  ifelse(p1 == 'red', paste0('g_', g_p1, '_equal_0'),
                         paste0('g_', g_p1, '_greater_1'))),
      e2 = ifelse(p2 == 'green', paste0('g_p2_equal_', g_p2),
                  ifelse(p2 == 'red', paste0('g_', g_p2, '_equal_0'),
                         paste0('g_', g_p2, '_greater_1'))),
      e3 = ifelse(p3 == 'green', paste0('g_p3_equal_', g_p3),
                  ifelse(p3 == 'red', paste0('g_', g_p3, '_equal_0'),
                         paste0('g_', g_p3, '_greater_1'))),
      e4 = ifelse(p4 == 'green', paste0('g_p4_equal_', g_p4),
                  ifelse(p4 == 'red', paste0('g_', g_p4, '_equal_0'),
                         paste0('g_', g_p4, '_greater_1'))),
      e5 = ifelse(p5 == 'green', paste0('g_p5_equal_', g_p5),
                  ifelse(p5 == 'red', paste0('g_', g_p5, '_equal_0'),
                         paste0('g_', g_p5, '_greater_1')))
    ) %>%
    dplyr::mutate(
      expr = paste0('guess_words[which(', paste(e1, e2, e3, e4, e5, sep = ' & '), ')]')
    ) %>%
    dplyr::pull(expr)

  # Evaluate each expression to get matching words
  guesses <- lapply(boolean_expressions, function(expr) {
    eval(parse(text = expr))
  })

  return(guesses)
}
