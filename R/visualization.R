#' Print Wordle Cheat Sheet
#'
#' Generates a PDF cheat sheet showing the optimal next guess for each
#' possible outcome pattern from the first (or any) guess.
#'
#' @param optimal_strategy Tibble containing outcome patterns and best guesses
#' @param output_file Character. Path to output PDF file
#'
#' @return NULL (side effect: creates PDF file)
#' @export
print_cheat_sheet <- function(optimal_strategy,
                               output_file = 'output/wordle_cheat_sheet.pdf') {

  if (!requireNamespace("grid", quietly = TRUE) ||
      !requireNamespace("gridExtra", quietly = TRUE) ||
      !requireNamespace("dplyr", quietly = TRUE)) {
    stop("Packages 'grid', 'gridExtra', and 'dplyr' are required.")
  }

  # Ensure output directory exists
  output_dir <- dirname(output_file)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  d <- optimal_strategy

  # Convert colors to factors for proper sorting
  color_cols <- names(d)[grepl('color', names(d))]
  for (n in color_cols) {
    d[[n]] <- factor(d[[n]], levels = c('red', 'yellow', 'green'))
  }

  # Sort by color patterns
  sort_expr <- paste0('d <- d %>% dplyr::arrange(', paste0(color_cols, collapse = ', '), ')')
  eval(parse(text = sort_expr))

  # Convert back to character
  for (n in color_cols) {
    d[[n]] <- as.character(d[[n]])
  }

  # Create tables (44 rows per table)
  table_size <- 44
  plot_list <- list()
  table_num <- 1

  while (((table_num - 1) * table_size + 1) <= nrow(d)) {

    row_indices <- ((table_num - 1) * table_size + 1):min((table_num * table_size), nrow(d))
    temp_data <- d[row_indices, c(9:13, 7, 15)]
    fill_colors <- d[row_indices, 2:6]

    # Map colors to display colors
    fill_colors[fill_colors == 'green'] <- 'green4'
    fill_colors[fill_colors == 'red'] <- 'gray55'
    fill_colors[fill_colors == 'yellow'] <- 'gold2'
    fill_colors[, 6:7] <- 'white'

    # Uppercase letters for display
    for (j in c(1:5, 7)) {
      temp_data[[j]] <- toupper(temp_data[[j]])
    }

    # Text colors
    text_colors <- fill_colors
    text_colors[, 1:5] <- 'white'
    text_colors[, 6:7] <- 'black'

    # Create table theme
    table_theme <- gridExtra::ttheme_minimal(
      core = list(
        bg_params = list(fill = unlist(fill_colors), col = NA),
        fg_params = list(fontface = 'bold', fontsize = 9, col = unlist(text_colors))
      )
    )

    plot_list[[table_num]] <- gridExtra::tableGrob(temp_data, rows = NULL, cols = NULL, theme = table_theme)
    table_num <- table_num + 1
  }

  # Save to PDF
  message("Creating cheat sheet PDF: ", output_file)
  pdf(output_file, paper = 'a4', height = 11, width = 8.5)
  do.call(gridExtra::grid.arrange, c(plot_list, ncol = table_num - 1))
  dev.off()

  message("Cheat sheet saved successfully")
  invisible(NULL)
}


#' Print Single Wordle Outcome
#'
#' Creates a visualization of a single game path showing the sequence of
#' guesses and their color feedback, mimicking the Wordle UI.
#'
#' @param outcome Single-row tibble from strategy table
#'
#' @return grob object for plotting
#' @export
print_single_outcome <- function(outcome) {

  if (!requireNamespace("grid", quietly = TRUE) ||
      !requireNamespace("gridExtra", quietly = TRUE) ||
      !requireNamespace("dplyr", quietly = TRUE)) {
    stop("Packages 'grid', 'gridExtra', and 'dplyr' are required.")
  }

  # Extract letter positions for each guess
  extract_letters <- function(indices) {
    temp <- outcome[1, indices]
    names(temp) <- c('l1', 'l2', 'l3', 'l4', 'l5')
    return(temp)
  }

  # Guessed letter positions
  guess_letters <- dplyr::bind_rows(
    extract_letters(9:13),    # Guess 1
    extract_letters(28:32),   # Guess 2
    extract_letters(46:50),   # Guess 3
    extract_letters(64:68),   # Guess 4
    extract_letters(82:86)    # Guess 5
  )

  # Best guess words (split into letters)
  split_word <- function(col_index) {
    if (is.na(outcome[1, col_index])) return(NULL)
    chars <- strsplit(as.character(outcome[1, col_index]), '')[[1]]
    dplyr::tibble(l1 = chars[1], l2 = chars[2], l3 = chars[3], l4 = chars[4], l5 = chars[5])
  }

  best_guesses <- dplyr::bind_rows(
    split_word(15),  # Best guess 2
    split_word(33),  # Best guess 3
    split_word(51),  # Best guess 4
    split_word(69),  # Best guess 5
    split_word(87)   # Best guess 6
  )

  # Color feedback
  extract_colors <- function(indices) {
    temp <- outcome[1, indices]
    names(temp) <- c('l1', 'l2', 'l3', 'l4', 'l5')
    return(temp)
  }

  feedback_colors <- dplyr::bind_rows(
    extract_colors(2:6),      # Guess 1
    extract_colors(21:25),    # Guess 2
    extract_colors(39:43),    # Guess 3
    extract_colors(57:61),    # Guess 4
    extract_colors(75:79)     # Guess 5
  )

  # Map to display colors
  fill_colors <- feedback_colors
  fill_colors[fill_colors == 'green'] <- 'green4'
  fill_colors[fill_colors == 'red'] <- 'gray55'
  fill_colors[fill_colors == 'yellow'] <- 'gold2'

  # Green background for best guess row
  best_guess_colors <- fill_colors
  best_guess_colors[, 1:5] <- 'green4'

  # Uppercase all letters
  for (j in 1:5) {
    guess_letters[[j]] <- toupper(guess_letters[[j]])
    if (!is.null(best_guesses)) {
      best_guesses[[j]] <- toupper(best_guesses[[j]])
    }
  }

  # Text colors (white on colored backgrounds, black on white)
  text_colors <- fill_colors
  text_colors[, 1:5] <- 'white'

  # Combine guessed letters with best guess
  valid_guess_rows <- which(!is.na(guess_letters$l1))
  last_best_guess_row <- if (is.null(best_guesses) || is.na(best_guesses$l1[1])) {
    NULL
  } else {
    max(which(!is.na(best_guesses$l1)))
  }

  display_data <- if (!is.null(last_best_guess_row)) {
    dplyr::bind_rows(guess_letters[valid_guess_rows, ], best_guesses[last_best_guess_row, ])
  } else {
    guess_letters[valid_guess_rows, ]
  }

  display_colors <- if (!is.null(last_best_guess_row)) {
    dplyr::bind_rows(fill_colors[valid_guess_rows, ], best_guess_colors[last_best_guess_row, ])
  } else {
    fill_colors[valid_guess_rows, ]
  }

  # Remove duplicates
  unique_rows <- which(!duplicated(display_data))
  display_data <- display_data[unique_rows, ]
  display_colors <- display_colors[unique_rows, ]

  # Create table theme
  table_theme <- gridExtra::ttheme_minimal(
    core = list(
      bg_params = list(fill = unlist(display_colors), col = NA),
      fg_params = list(fontface = 'bold', fontsize = 4, col = 'white')
    )
  )

  plot_obj <- gridExtra::tableGrob(display_data, rows = NULL, cols = NULL, theme = table_theme)
  return(plot_obj)
}


#' Generate All Outcomes PDF
#'
#' Creates a comprehensive PDF showing visualizations of all possible
#' game outcome paths (can be very large - 50 outcomes per page).
#'
#' @param strategy Complete strategy tibble with all game paths
#' @param output_file Character. Path to output PDF file
#' @param outcomes_per_page Integer. Number of outcome grids per page (default 50)
#'
#' @return NULL (side effect: creates PDF file)
#' @export
generate_outcomes_pdf <- function(strategy,
                                   output_file = 'output/wordle_outcomes.pdf',
                                   outcomes_per_page = 50) {

  if (!requireNamespace("grid", quietly = TRUE) ||
      !requireNamespace("gridExtra", quietly = TRUE)) {
    stop("Packages 'grid' and 'gridExtra' are required.")
  }

  # Ensure output directory exists
  output_dir <- dirname(output_file)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  message("Generating outcomes PDF (this may take a while)...")
  message("Total outcomes to visualize: ", nrow(strategy))

  pdf(output_file, paper = 'a4', height = 11, width = 8.5)

  page_start <- 1
  while (page_start <= nrow(strategy)) {

    page_end <- min(nrow(strategy), page_start + outcomes_per_page - 1)
    page_indices <- page_start:page_end

    message("Rendering page: rows ", page_start, " to ", page_end)

    plot_list <- lapply(page_indices, function(i) {
      print_single_outcome(strategy[i, ])
    })

    gridExtra::grid.arrange(grobs = plot_list, nrow = 10, ncol = 5)

    page_start <- page_start + outcomes_per_page
  }

  dev.off()

  message("Outcomes PDF saved: ", output_file)
  invisible(NULL)
}
