#' Example Function
#'
#' This is an example function that demonstrates documentation.
#'
#' @param x A numeric vector
#' @return The mean of x
#' @examples
#' example_mean(c(1, 2, 3, 4, 5))
#' @export
example_mean <- function(x) {
  if (!is.numeric(x)) {
    stop("x must be numeric")
  }
  mean(x, na.rm = TRUE)
}
