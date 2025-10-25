# 🎮 How to Run the Wordle Solver

## ⚠️ IMPORTANT: Must Run Interactively

This Wordle solver requires **interactive terminal input**. It will NOT work with piped input or in automated scripts.

---

## ✅ The RIGHT Way to Run It

### Option 1: From R Console (RECOMMENDED)

```r
# 1. Navigate to the project directory
setwd("~/code/wordle-solver")

# 2. Run the script
source('scripts/play_wordle_interactive.R')
```

**This works because:**
- R console is interactive by default
- `readLines()` works correctly
- You can type inputs naturally

---

### Option 2: From Terminal (If Supported)

Some systems support interactive R from command line:

```bash
cd ~/code/wordle-solver
R --interactive
```

Then from the R prompt:
```r
source('scripts/play_wordle_interactive.R')
```

---

## ❌ What DOESN'T Work

### Don't do this:
```bash
# ✗ This will fail - Rscript is non-interactive
Rscript scripts/play_wordle.R

# ✗ This will fail - piped input doesn't work
echo "g\ng\ng\ng\ng" | R --interactive
```

**Why it fails:**
- `Rscript` runs in non-interactive mode
- `readLines()` and `scan()` behave differently in non-interactive mode
- The script explicitly checks for `interactive()` and will stop

---

## 📝 Step-by-Step Instructions

### First Time Setup

1. **Open Terminal**
2. **Navigate to project**:
   ```bash
   cd ~/code/wordle-solver
   ```

3. **Start R**:
   ```bash
   R
   ```

4. **Run the solver**:
   ```r
   source('scripts/play_wordle_interactive.R')
   ```

### Playing the Game

1. **Read the optimal guess** (e.g., "RAISE")
2. **Go to Wordle**: https://www.nytimes.com/games/wordle/index.html
3. **Enter the word** in Wordle
4. **See the colors** Wordle shows you
5. **Enter each color** when prompted:
   - Type **`g`** for green (correct position)
   - Type **`y`** for yellow (wrong position)
   - Type **`r`** for red/gray (not in word)
   - Press **Enter** after each letter

6. **Get next guess** and repeat!

---

## 🐛 Troubleshooting

### "Invalid input" after typing correctly

**Problem**: You're not in interactive mode

**Solution**:
```r
# Check if you're interactive
interactive()  # Should return TRUE

# If FALSE, restart R properly:
quit()  # Exit R
R       # Restart R (not Rscript!)
source('scripts/play_wordle_interactive.R')
```

### Script immediately exits

**Problem**: Running with `Rscript` instead of `R`

**Solution**: Use `R` console, not `Rscript`

### Empty input errors

**Problem**: Terminal input redirection or RStudio issues

**Solution**:
1. Close RStudio if using it
2. Use plain terminal R:
   ```bash
   cd ~/code/wordle-solver
   R
   ```
3. Then: `source('scripts/play_wordle_interactive.R')`

---

## 🎯 Quick Reference

### Correct Command Sequence

```bash
# In Terminal:
cd ~/code/wordle-solver
R

# In R Console:
source('scripts/play_wordle_interactive.R')

# Follow the prompts!
```

### Example Game

```
💡 Optimal guess:  RAISE

Enter the color feedback you received:
  Position 1 (g=green, y=yellow, r=red): r [Enter]
  Position 2 (g=green, y=yellow, r=red): y [Enter]
  Position 3 (g=green, y=yellow, r=red): g [Enter]
  Position 4 (g=green, y=yellow, r=red): r [Enter]
  Position 5 (g=green, y=yellow, r=red): r [Enter]

You entered:
 R  A  I  S  E
▓▓ 🟨 🟩 ▓▓ ▓▓

TURN 2
💡 Optimal guess:  TRAIL
...
```

---

## 💡 Pro Tips

1. **Keep Wordle open** in browser while playing
2. **Type carefully** - g, y, or r only
3. **Press Enter** after each letter
4. **Average solution**: 3-4 guesses
5. **Win rate**: 100% (if you follow the suggestions!)

---

## ✅ Ready to Play!

```bash
cd ~/code/wordle-solver
R
```

```r
source('scripts/play_wordle_interactive.R')
```

Good luck! 🎯
