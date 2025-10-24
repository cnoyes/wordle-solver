# .Rprofile for PROJECT_NAME

# Activate renv for reproducible package management
if (file.exists("renv/activate.R")) {
  source("renv/activate.R")
}

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Useful options
options(
  scipen = 999,              # Disable scientific notation
  stringsAsFactors = FALSE,  # Don't convert strings to factors by default
  max.print = 100            # Limit console output
)

# Custom helper function for project
.First <- function() {
  if (interactive()) {
    cat("\nWelcome to PROJECT_NAME!\n")
    cat("Project directory:", getwd(), "\n\n")
  }
}

# Source custom functions if they exist
if (file.exists("R/functions.R")) {
  source("R/functions.R")
}
