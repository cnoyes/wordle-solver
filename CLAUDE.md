# CLAUDE.md

This file provides **mandatory instructions** to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ MANDATORY PRACTICES

**READ FIRST**: Before starting any work, read `.claude/BEST_PRACTICES.md` for comprehensive development guidelines.

**You MUST:**
1. ✅ Create feature branches for all non-trivial work (NEVER commit directly to main)
2. ✅ Create GitHub issues before starting features
3. ✅ Use plan mode for features requiring 3+ file changes
4. ✅ Invoke code-reviewer agent before creating PRs
5. ✅ Follow conventional commit format
6. ✅ Write tests for new features
7. ✅ Update documentation for user-facing changes

**Branch naming**: `<type>/<issue-number>-<brief-description>`
**Commit format**: `<type>(<scope>): <subject>` (see BEST_PRACTICES.md)

---

## Project Overview

**wordle-solver** is an optimal Wordle solving system that uses exhaustive game tree exploration to pre-compute the mathematically best guess for every possible game state across all 6 turns.

### What Makes This Special

- **Pre-computed optimal strategy**: Unlike real-time solvers, this exhaustively analyzes all ~30 million guess/answer combinations upfront
- **Minimax-inspired scoring**: Minimizes worst-case outcomes using `sum(count²) / n` penalty function
- **Complete decision tree**: Covers every possible path through a Wordle game
- **Interactive CLI**: Play Wordle with instant optimal suggestions
- **Cheat sheets**: Visual guides showing optimal moves for any game state

### Algorithm Highlights

1. **Exhaustive search**: Evaluates all ~12,972 possible guesses against all ~2,315 possible answers
2. **Recursive tree building**: Constructs 6-turn decision tree (turns 2-6 branch from turn 1 outcomes)
3. **Smart scoring**: Penalizes guesses that leave many possibilities in worst case
4. **Tie-breaking**: Prefers words from answer list when scores are equal
5. **Boolean optimization**: Pre-computes filters for instant word lookups

---

## Key Commands

### Initial Setup (One-Time)

```bash
# 1. Download word lists and prepare data structures
Rscript scripts/01_setup_data.R
# Output: data/raw/answer_words.txt, data/processed/*.RDS

# 2. Build complete optimal strategy tree (18-30 minutes)
Rscript scripts/02_build_strategy.R
# Output: data/derived/strategy.RDS, best_guess.RDS

# 3. Generate visualizations (optional)
Rscript scripts/03_generate_visualizations.R
# Output: output/turn1_cheat_sheet.pdf, all_outcomes.pdf
```

### Interactive Play

```bash
# Play Wordle with optimal suggestions
Rscript scripts/play_wordle.R
```

### Testing

```bash
# Run all tests
Rscript -e "testthat::test_dir('tests')"

# Run specific test file
Rscript -e "testthat::test_file('tests/testthat/test_solver_core.R')"
```

### Development Setup

```bash
# Initialize renv (reproducible package management)
R -e "renv::init()"
R -e "renv::restore()"

# Install required packages manually
R -e "install.packages(c('dplyr', 'tidyr', 'httr', 'grid', 'gridExtra', 'testthat'))"
```

---

## Architecture

### Pipeline Overview

```
01_setup_data.R
  ↓
  Downloads word lists from Wordle source (httr)
  Transforms to position matrices + letter counts
  Generates boolean filters for fast lookups
  ↓
02_build_strategy.R (18-30 min)
  ↓
  Turn 1: Calculates best opening guess (all 12,972 guesses vs 2,315 answers)
  Turn 2-6: For each outcome branch, calculates optimal next guess
  Assembles complete lookup table (strategy.RDS)
  ↓
03_generate_visualizations.R
  ↓
  Creates PDF cheat sheets with color-coded outcome tables
  Generates complete game tree visualization
  ↓
play_wordle.R
  ↓
  Interactive CLI: User inputs colors, gets optimal next guess
```

### Key Components

#### 1. **Data Acquisition** (`R/data_acquisition.R`)
- `download_wordle_words()`: Scrapes official word lists from Wordle JS source
- `load_wordle_words()`: Loads previously downloaded lists

#### 2. **Data Transformation** (`R/data_transformation.R`)
- `words_to_position_matrix()`: Converts words → 5-column letter position tibble
- `calculate_letter_counts()`: Counts occurrences of each letter per word
- `transform_word_lists()`: Main pipeline that prepares data for solver

#### 3. **Solver Core** (`R/solver_core.R`)
- `calc_best_guess()`: **THE MAIN ALGORITHM**
  - For given game state (remaining guesses & answers), finds optimal next guess
  - Generates all guess×answer combinations
  - Calculates color feedback (green/yellow/red) for each combination
  - Groups by outcome pattern
  - Scores each guess using `sum(count²) / n` (penalizes worst cases)
  - Returns best guess + detailed outcome breakdown

- `generate_boolean_filters()`: Pre-generates boolean vectors for filtering
  - Example: `g_p1_equal_a` = vector marking all guess words with 'a' in position 1
  - Enables instant filtering: `guess_words[which(g_p1_equal_a & g_e_greater_1)]`

- `calculate_guesses()`: Uses boolean filters to extract matching words for outcomes

#### 4. **Visualization** (`R/visualization.R`)
- `print_cheat_sheet()`: Generates PDF tables showing optimal guesses
- `print_single_outcome()`: Creates Wordle-style grid for one game path
- `generate_outcomes_pdf()`: Visualizes all possible game paths

---

## Data Flow

### File Structure

```
data/
├── raw/                    # Downloaded word lists
│   ├── answer_words.txt   # 2,315 possible solutions
│   └── guess_words.txt    # 12,972 valid guesses
├── processed/              # Transformed data structures
│   ├── answer_words.RDS
│   ├── guess_words.RDS
│   ├── answer_mat.RDS     # Position matrices
│   ├── guess_mat.RDS
│   ├── answer_count.RDS   # Letter count matrices
│   └── guess_count.RDS
└── derived/                # Computed strategy
    ├── results.RDS        # Raw calc_best_guess() results
    ├── best_guess.RDS     # Per-turn decision tables
    ├── optimal_strategy.RDS  # Formatted strategy by turn
    └── strategy.RDS       # Complete lookup table (MAIN OUTPUT)

output/
├── turn1_cheat_sheet.pdf  # Optimal 2nd guess for each opening outcome
└── all_outcomes.pdf       # All game paths visualized

legacy/                     # Original COVID-era code (reference only)
```

### Key Data Structures

**strategy.RDS** (main output):
- Complete lookup table with ~50,000+ rows
- Each row = unique game state path
- Columns: `guess1`, `guess1_color1-5`, `best_guess2`, `guess2`, `guess2_color1-5`, ...
- Sorted by color patterns for easy lookups

**optimal_strategy.RDS**:
- List of 6 tibbles (one per turn)
- Each tibble shows: outcome pattern → best next guess + statistics

---

## Algorithm Deep Dive

### Scoring Function

```r
avg_remaining = sum(answer_count^2) / n
```

**Why squared penalty?**
- Linear `sum(count) / n` treats all outcomes equally
- Squaring penalizes outcomes that leave many possibilities
- Example: Leaving [1, 1, 8] possibilities is worse than [3, 3, 4]
- Implements minimax-style risk minimization

### Boolean Filter Optimization

**Problem**: Filtering words by constraints is slow with string operations

**Solution**: Pre-compute boolean vectors

```r
# Instead of:
guess_words[substr(guess_words, 1, 1) == 'a' & str_count(guess_words, 'e') >= 1]

# Do this:
guess_words[which(g_p1_equal_a & g_e_greater_1)]  # Instant lookup!
```

Generates ~1,500 boolean vectors:
- Position-based: `g_p{1-5}_equal_{a-z}`, `g_p{1-5}_not_equal_{a-z}`
- Count-based: `g_{a-z}_equal_{0-5}`, `g_{a-z}_greater_{0-5}`
- Same for answer words (prefix `a_`)

### Computational Complexity

**Turn 1**:
- 12,972 guesses × 2,315 answers = 30,030,780 combinations
- Group by outcome pattern (~250 unique patterns per guess)
- Score ~12,972 guesses

**Turn 2-6**:
- For each branch, repeat with filtered word lists
- Branches decrease as game progresses (most paths solve by turn 4-5)

**Total runtime**: 18-30 minutes (one-time computation)
**Memory**: ~500MB for complete strategy tree

---

## Common Patterns

### Adding a New Scoring Function

```r
# In R/solver_core.R, modify calc_best_guess():
guess_summary <- outcomes %>%
  group_by(g) %>%
  summarize(
    # Original scoring
    avg_remaining = sum(answer_count ^ 2) / n(),

    # Add your new score here
    new_score = <your_formula>,

    min_remaining = min(answer_count),
    max_remaining = max(answer_count)
  ) %>%
  mutate(in_answer_list = g %in% answer_words)

# Change sorting to use new score
best_row <- guess_summary %>%
  arrange(new_score, desc(in_answer_list), g) %>%  # Use new_score
  slice(1)
```

### Debugging Strategy Lookups

```r
# Load strategy
strategy <- readRDS('data/derived/strategy.RDS')

# Find rows for specific outcome
strategy %>%
  filter(
    guess1 == 'crane',
    guess1_color1 == 'red',
    guess1_color2 == 'green',
    guess1_color3 == 'yellow',
    guess1_color4 == 'red',
    guess1_color5 == 'red'
  ) %>%
  select(guess1, starts_with('guess1_color'), best_guess2, guess2_remaining)
```

---

## Troubleshooting

### Issue: `calc_best_guess()` runs forever

**Cause**: Large word lists (turn 1 takes ~5 minutes even when working correctly)

**Solution**:
- Check you're not running in a loop without progress messages
- Add `message()` statements to track progress
- For testing, use subset: `guess_words[1:100]`, `answer_words[1:50]`

### Issue: Boolean filters not found

**Cause**: `generate_boolean_filters()` not called before `calc_best_guess()`

**Solution**:
```r
# Must run this first:
generate_boolean_filters(g, a, g_mat, a_mat, g_count, a_count)

# Then this will work:
calc_best_guess(g, a, g_mat, a_mat)
```

### Issue: Strategy file not found

**Cause**: Haven't run `02_build_strategy.R` yet

**Solution**:
```bash
# This takes 18-30 minutes:
Rscript scripts/02_build_strategy.R
```

### Issue: Out of memory during strategy building

**Cause**: Large intermediate objects

**Solution**:
- Close other applications
- Increase R memory limit: `R_MAX_VSIZE` environment variable
- Run on machine with 8GB+ RAM
- Consider building turn-by-turn and saving intermediate results

---

## Performance Optimization

### Current Performance
- **Setup**: ~30 seconds
- **Strategy build**: 18-30 minutes (one-time)
- **Interactive lookup**: Instant (<100ms)

### Future Optimizations
1. **Parallelization**: Use `future` + `furrr` for turn 2-6 branches (easily parallelizable)
2. **Caching**: Store partial trees to enable incremental updates
3. **C++ backend**: Rewrite `calc_best_guess()` in Rcpp for 10-100x speedup
4. **Sparse matrices**: Some boolean filters are very sparse (use `Matrix` package)

---

## Testing Strategy

**Test Coverage**:
- ✅ Data transformation (word splitting, letter counting)
- ✅ Solver core (best guess structure, scoring, color matching)
- ⚠️ Visualization (manual inspection of PDFs)
- ⚠️ Full pipeline (integration test)

**To add tests**:
```r
# tests/testthat/test_<module>.R
test_that("descriptive test name", {
  # Setup
  input <- ...

  # Execute
  result <- function_to_test(input)

  # Assert
  expect_equal(result$field, expected_value)
})
```

---

## Important Files

- **`R/solver_core.R`**: Main algorithm implementation
- **`R/data_transformation.R`**: Data prep pipeline
- **`scripts/02_build_strategy.R`**: Strategy tree builder (slow!)
- **`scripts/play_wordle.R`**: Interactive CLI for end users
- **`data/derived/strategy.RDS`**: The complete solution (main artifact)
- **`legacy/`**: Original code (reference only, don't modify)

---

## Development Workflow

### Making Algorithm Changes

1. **Create feature branch**: `git checkout -b feature/improve-scoring`
2. **Modify core functions** in `R/solver_core.R`
3. **Add tests**: `tests/testthat/test_solver_core.R`
4. **Run tests**: `Rscript -e "testthat::test_dir('tests')"`
5. **Test on small subset**:
```r
g <- data$guess_words[1:100]
a <- data$answer_words[1:50]
result <- calc_best_guess(g, a, ...)
```
6. **Full rebuild**: `Rscript scripts/02_build_strategy.R` (if core algorithm changed)
7. **Commit + PR**

### Adding New Features

Examples:
- Add hard mode support (must reuse green/yellow letters)
- Add letter frequency visualization
- Add Absurdle/Quordle support (multiple simultaneous games)
- Add web interface (Shiny app)

---

## References

- [Wordle](https://www.nytimes.com/games/wordle/index.html) - The game
- [3Blue1Brown Wordle video](https://www.youtube.com/watch?v=v68zYyaEmEA) - Information theory analysis
- [Original Wordle word lists](https://www.powerlanguage.co.uk/wordle/main.e65ce0a5.js) - Data source

---

**Created during COVID-19 lockdown (2020-2022) | Refactored for public release (2025)**
