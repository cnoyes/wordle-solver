# Wordle Solver: Optimal Strategy via Exhaustive Search

**An optimal Wordle solver that pre-computes the mathematically best guess for every possible game state.**

[![R](https://img.shields.io/badge/R-4.0%2B-blue.svg)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 🎯 What Makes This Special

Unlike real-time Wordle solvers that calculate moves on-the-fly, this solver **exhaustively explores the entire game tree** to pre-compute optimal strategies. Think of it as a chess opening book, but for Wordle.

### Key Features

- ✅ **Interactive web cheat sheet** - Beautiful, searchable interface for finding optimal guesses
- ✅ **Pre-computed optimal strategy** for all 2,314 possible Wordle answers
- ✅ **Minimax-inspired scoring** that minimizes worst-case outcomes
- ✅ **Complete decision tree** covering all 6 turns
- ✅ **Interactive CLI** for playing Wordle with instant suggestions
- ✅ **Visual cheat sheets** (PDF) showing optimal moves for any game state
- ✅ **~30 million combinations analyzed** upfront (18-30 minute one-time computation)

---

## 🌐 Interactive Web Cheat Sheet

**[Try the Interactive Cheat Sheet](https://cnoyes.github.io/wordle-solver/)** (GitHub Pages)

The best way to use this solver is through the **interactive web interface**:

- 🎨 **Wordle-style design** with familiar green/yellow/gray colors
- 🔍 **Live search** - Type any letter pattern or guess to filter results
- 📊 **Sortable** - Order by fewest/most remaining words
- 💡 **Clear instructions** - Step-by-step guide for first-time users
- 📱 **Mobile-friendly** - Works on any device

**How to use:**
1. Visit the interactive cheat sheet (or open `web/index.html` locally)
2. Guess "RAISE" in Wordle
3. Find your color pattern in the cheat sheet
4. See the optimal next guess instantly!

All 132 Turn 1 outcomes are displayed in an easy-to-browse, searchable grid.

---

## 📖 Downloadable PDF Cheat Sheets

This project includes **two comprehensive PDF visualizations** that map out the entire solution space:

### 🎯 Turn 1 Cheat Sheet ([Download](output/turn1_cheat_sheet.pdf))

**What it shows:** All 132 possible color outcomes after guessing "RAISE"

For each outcome pattern, it displays:
- 🟩🟨⬜ **Color-coded letters** showing the feedback
- 🔢 **Remaining words** - How many solutions are still possible
- 💡 **Optimal next guess** - The mathematically best second guess

**How to use it:**
1. Guess "RAISE" in Wordle
2. Look up your color pattern in the cheat sheet
3. See exactly what to guess next and how many words remain!

**Example:** If you get ⬜🟨🟩⬜⬜ (gray R, yellow A, green I, gray S, gray E):
- 102 possible words remain
- Optimal next guess: "OUTED"

### 🗺️ Complete Game Paths ([Download](output/Wordle%20Outcomes.pdf))

**What it shows:** Complete game sequences from start to finish

This PDF visualizes **all possible paths through the game tree**, showing:
- Each guess and its color feedback across all turns
- The progression from opening guess to solution
- Visual representation mimicking the actual Wordle grid

**How to use it:**
- Study optimal game paths
- Understand decision trees visually
- See how the solver narrows down possibilities turn by turn

**Note:** This is a large PDF (many pages) showing the exhaustive game tree!

---

## 📊 Algorithm Overview

### The Core Idea

For every possible game state (remaining guesses + remaining answers), the solver:

1. **Generates all outcomes**: For each guess, calculates the color feedback (🟩🟨⬜) for every possible answer
2. **Scores guesses**: Uses `sum(count²) / n` to penalize guesses that leave many possibilities in the worst case
3. **Selects optimal guess**: Picks the guess that minimizes expected remaining answers
4. **Builds recursively**: Repeats for turns 2-6, creating a complete decision tree

### Scoring Function

```r
avg_remaining = sum(answer_count^2) / n
```

**Why square the counts?**
- Linear averaging treats all outcomes equally
- Squaring **penalizes worst-case scenarios**
- Example: A guess leaving [1, 1, 8] possibilities is worse than [3, 3, 4]
- This implements a **minimax-style risk minimization**

### Performance Optimization

To handle ~30 million guess×answer combinations efficiently:

- **Boolean filters**: Pre-computes 1,500+ boolean vectors for instant word filtering
  ```r
  # Instead of slow string operations:
  words[substr(words, 1, 1) == 'a' & str_count(words, 'e') >= 1]

  # Use pre-computed boolean lookup:
  words[which(g_p1_equal_a & g_e_greater_1)]  # Instant!
  ```

- **Vectorized operations**: Leverages R's `tidyverse` for fast matrix operations
- **One-time computation**: Build once, lookup instantly forever

---

## 🚀 Quick Start

### Prerequisites

```bash
# Install R (4.0+)
brew install r  # macOS
# or download from: https://www.r-project.org/

# Install required packages
R -e "install.packages(c('dplyr', 'tidyr', 'httr', 'grid', 'gridExtra', 'testthat'))"
```

### Installation

```bash
git clone https://github.com/cnoyes/wordle-solver.git
cd wordle-solver
```

### Setup (One-Time)

```bash
# Step 1: Download Wordle word lists (~30 seconds)
Rscript scripts/01_setup_data.R

# Step 2: Build optimal strategy tree (18-30 minutes)
#   This exhaustively explores all possible games
#   ⚠️  Grab a coffee - this is computationally intensive!
Rscript scripts/02_build_strategy.R

# Step 3: Generate visualizations (optional)
Rscript scripts/03_generate_visualizations.R
```

### Play Wordle with Optimal Suggestions

```bash
Rscript scripts/play_wordle.R
```

**How it works:**
1. The CLI suggests the optimal guess (opening: "RAISE")
2. Enter that word into [Wordle](https://www.nytimes.com/games/wordle/index.html)
3. Input the color feedback you received (g=green, y=yellow, r=red)
4. Get the next optimal guess
5. Repeat until solved!

---

## 📖 Example Session

```
=======================================================
  🎮 Interactive Wordle Solver
=======================================================

Loading optimal strategy...
✓ Strategy loaded

📖 HOW TO PLAY
1. I'll suggest the optimal guess
2. Enter this word into Wordle
3. Tell me the color feedback you received
4. Repeat until solved!

=======================================================
  TURN 1
=======================================================

💡 Optimal guess:  RAISE

Enter the color feedback you received:
  Position 1 (g=green, y=yellow, r=red): r
  Position 2 (g=green, y=yellow, r=red): y
  Position 3 (g=green, y=yellow, r=red): g
  Position 4 (g=green, y=yellow, r=red): r
  Position 5 (g=green, y=yellow, r=red): r

You entered:
 R  A  I  S  E
▓▓ 🟨 🟩 ▓▓ ▓▓

=======================================================
  TURN 2
=======================================================

💡 Optimal guess:  TRAIL

   (12 possible answers remaining)

...
```

---

## 🏗️ Project Structure

```
wordle-solver/
├── R/                          # Core functions
│   ├── data_acquisition.R     # Download Wordle word lists
│   ├── data_transformation.R  # Transform words to matrices
│   ├── solver_core.R          # Main algorithm (calc_best_guess)
│   └── visualization.R        # Generate PDF cheat sheets
├── scripts/                    # Runnable pipelines
│   ├── 01_setup_data.R        # Download & transform data
│   ├── 02_build_strategy.R    # Build decision tree (slow!)
│   ├── 03_generate_visualizations.R  # Create PDFs
│   └── play_wordle.R          # Interactive CLI
├── tests/                      # Unit tests
│   └── testthat/
│       ├── test_data_transformation.R
│       └── test_solver_core.R
├── data/
│   ├── raw/                   # Downloaded word lists
│   ├── processed/             # Transformed matrices
│   └── derived/               # Computed strategy (main output)
│       └── strategy.RDS       # Complete lookup table ⭐
├── output/                     # Generated visualizations
│   ├── turn1_cheat_sheet.pdf
│   └── all_outcomes.pdf
├── legacy/                     # Original COVID-era code (reference)
├── CLAUDE.md                   # Developer documentation
└── README.md                   # This file
```

---

## 🧪 Algorithm Details

### Turn 1: Opening Guess

**Problem**: Which word should you guess first?

**Approach**:
- Evaluate all **12,970 valid guesses** against all **2,314 possible answers**
- For each guess, simulate all possible color outcomes
- Score each guess by how well it splits the answer space
- Result: Opening guess that minimizes worst-case remaining possibilities

**Typical optimal openers**: CRANE, SALET, SLATE, CRATE

### Turns 2-6: Recursive Tree Building

For each outcome branch from turn 1:
1. Filter remaining possible answers
2. Recalculate optimal guess for this subset
3. Repeat recursively until turn 6 or solved

**Result**: A complete lookup table with ~50,000+ rows covering every possible game path

### Data Structures

**Position Matrix** (for fast color calculation):
```
      p1  p2  p3  p4  p5
crane  c   r   a   n   e
stale  s   t   a   l   e
```

**Letter Count Matrix** (for fast filtering):
```
      a  b  c  d  ...  z
crane 1  0  1  0  ...  0
stale 1  0  0  0  ...  0
```

**Boolean Filters** (for instant lookups):
```r
g_p1_equal_c  <- c(TRUE, FALSE, ...)  # Words with 'c' in position 1
g_e_greater_1 <- c(TRUE, TRUE, ...)   # Words with at least 1 'e'
```

---

## 📈 Performance Statistics

### Computational Complexity

| Turn | Combinations | Time |
|------|-------------|------|
| 1 | 12,970 × 2,314 = ~30M | ~5 min |
| 2-6 | Branching (~250 branches/turn) | ~15-25 min |
| **Total** | **~30 million evaluations** | **18-30 min** |

### Memory Usage

- Raw strategy tree: ~500MB
- Boolean filters: ~50MB
- Final lookup table: ~100MB

### Solving Performance

When using the optimal strategy:
- **Average guesses**: 3.4-3.6 (typical)
- **Max guesses**: 6 (worst case)
- **Win rate**: 100% (all 2,315 answers solvable)

---

## 🧑‍💻 Development

### Running Tests

```bash
# Run all tests
Rscript -e "testthat::test_dir('tests')"

# Run specific test file
Rscript -e "testthat::test_file('tests/testthat/test_solver_core.R')"
```

### Adding New Features

See `CLAUDE.md` for detailed development guidelines.

**Ideas for extensions**:
- **Hard mode support**: Must reuse green/yellow letters
- **Absurdle/Quordle**: Multiple simultaneous games
- **Shiny web app**: Interactive web interface
- **Parallel computation**: Speed up strategy building with `future` + `furrr`
- **C++ backend**: Rewrite core algorithm in Rcpp for 10-100x speedup

### Architecture

```
01_setup_data.R → 02_build_strategy.R → 03_generate_visualizations.R
       ↓                   ↓                        ↓
   data/processed/    data/derived/           output/*.pdf
                           ↓
                    play_wordle.R (interactive CLI)
```

---

## 🎓 Background

This project was created during the COVID-19 lockdown (2020-2022) as a deep dive into:
- **Combinatorial game theory**
- **Minimax optimization**
- **Large-scale data preprocessing**
- **R performance optimization**

It demonstrates:
- Advanced algorithmic thinking
- Efficient handling of large state spaces
- Clean, modular code architecture
- Comprehensive testing and documentation

---

## 📚 References

- [Wordle (NYT)](https://www.nytimes.com/games/wordle/index.html) - The game itself
- [3Blue1Brown: Solving Wordle using information theory](https://www.youtube.com/watch?v=v68zYyaEmEA) - Excellent video on optimal strategies
- [Original Wordle source code](https://www.powerlanguage.co.uk/wordle/main.e65ce0a5.js) - Where word lists are extracted from

---

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for new functionality
4. Update documentation
5. Submit a pull request

See `CLAUDE.md` for detailed development guidelines.

---

## 📝 License

MIT License - see [LICENSE](LICENSE) for details

---

## 👤 Author

**Clay Noyes**

- GitHub: [@cnoyes](https://github.com/cnoyes)

---

## ⭐ Acknowledgments

- Thanks to Josh Wardle for creating Wordle
- Inspired by 3Blue1Brown's information theory analysis
- Built with ❤️ and lots of ☕ during COVID lockdown

---

**If this helped you win your Wordle streak, consider giving it a ⭐!**
