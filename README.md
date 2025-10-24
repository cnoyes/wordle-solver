# wordle-solver

Optimal Wordle solver with pre-computed decision tree for all game states

## Installation

### Prerequisites

- R (>= 4.0.0)
- RStudio (recommended)

### Setup

```r
# Install renv for package management
install.packages("renv")

# Restore project dependencies
renv::restore()
```

## Usage

```r
# Source the main script
source("scripts/main.R")

# Or run specific analyses
source("scripts/analyze_data.R")
```

## Project Structure

```
wordle-solver/
├── R/                      # R functions and modules
│   └── functions.R         # Custom functions
├── scripts/                # Analysis scripts
│   ├── 01_data_prep.R      # Data preparation
│   ├── 02_analysis.R       # Main analysis
│   └── 03_visualization.R  # Visualizations
├── data/                   # Data files
│   ├── raw/                # Raw data (not committed)
│   ├── processed/          # Processed data (not committed)
│   └── public/             # Public/shareable data
├── output/                 # Output files (plots, tables)
├── reports/                # R Markdown reports
├── tests/                  # Unit tests (testthat)
├── renv/                   # renv package library
├── .Rprofile               # R startup configuration
├── DESCRIPTION             # Project metadata
└── README.md               # This file
```

## Development

### Running Tests

```r
# Run all tests
testthat::test_dir("tests")
```

### Code Style

Follow the [tidyverse style guide](https://style.tidyverse.org/):

```r
# Install styler for automatic formatting
install.packages("styler")

# Style a file
styler::style_file("R/functions.R")

# Style entire project
styler::style_dir("R")
```

### Adding Dependencies

```r
# Install a package and add to renv
install.packages("package_name")
renv::snapshot()  # Save to renv.lock
```

## Common Commands

```r
# Update all packages
renv::update()

# Check project status
renv::status()

# Clean workspace
rm(list = ls())

# Restart R session
.rs.restartR()  # In RStudio
```

## License

MIT
