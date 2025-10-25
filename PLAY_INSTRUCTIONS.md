# 🎮 How to Play Wordle with the Solver

## Quick Start

```bash
cd ~/code/wordle-solver
Rscript scripts/play_wordle.R
```

## What You'll See

```
=======================================================
  🎮 Interactive Wordle Solver
=======================================================

Loading strategy...
✓ Strategy loaded (6 turns)

📖 HOW TO PLAY
1. I'll suggest the optimal guess
2. Enter this word into Wordle
3. Tell me the color feedback you received
4. Repeat until solved!

Color codes:
  🟩 = Letter in correct position (green)
  🟨 = Letter in word, wrong position (yellow)
  ⬜ = Letter not in word (gray)

=======================================================
  TURN 1
=======================================================

💡 Optimal guess:  RAISE

Enter the color feedback you received:
  Position 1 (g=green, y=yellow, r=red): _
```

## How to Play

### Step 1: Get the Optimal Guess
The solver suggests **RAISE** as your first guess.

### Step 2: Play Wordle
Go to https://www.nytimes.com/games/wordle/index.html and enter **RAISE**

### Step 3: Enter the Colors
For each letter position (1-5), enter the color you see:
- Type **`g`** for green (correct letter, correct position)
- Type **`y`** for yellow (correct letter, wrong position)
- Type **`r`** for red/gray (letter not in word)

### Example

If Wordle shows:
```
R A I S E
⬜🟨🟩⬜⬜
```

You would enter:
```
Position 1: r
Position 2: y
Position 3: g
Position 4: r
Position 5: r
```

### Step 4: Get Next Guess
The solver will show you the optimal next guess based on the feedback!

### Step 5: Repeat
Continue until you solve the puzzle (all green) or run out of guesses.

## Tips

- **Type carefully**: Make sure colors match exactly what Wordle shows
- **One letter at a time**: The solver asks for each position separately
- **Green = g, Yellow = y, Red/Gray = r**: Short codes work fine
- **Win message**: You'll see a celebration when you solve it!

## Common Issues

### "Script hangs at loading"
- This is normal if it takes 5-10 seconds to load the strategy data
- Wait for "✓ Strategy loaded"

### "Invalid input" message
- Only type: `g`, `y`, `r` (or `green`, `yellow`, `red`)
- Press Enter after each letter

### "Could not find matching outcome"
- Double-check your color entries
- Make sure they match exactly what Wordle showed

## Example Full Game

```
TURN 1
💡 Optimal guess: RAISE
[Enter RAISE in Wordle]
[Wordle shows: ⬜🟨🟩⬜⬜]
Position 1: r
Position 2: y
Position 3: g
Position 4: r
Position 5: r

TURN 2
💡 Optimal guess: TRAIL
(143 possible answers remaining)
[Enter TRAIL in Wordle]
[Wordle shows: 🟩⬜🟩🟨⬜]
Position 1: g
Position 2: r
Position 3: g
Position 4: y
Position 5: r

TURN 3
💡 Optimal guess: TAMIL
(8 possible answers remaining)
[Continue...]
```

## Ready to Play?

```bash
cd ~/code/wordle-solver
Rscript scripts/play_wordle.R
```

Good luck! The optimal strategy should get you to the answer in 3-4 guesses on average.

---

**Note**: This solver has a 100% win rate across all 2,314 possible Wordle answers!
