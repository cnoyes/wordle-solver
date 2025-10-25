# Interactive Wordle Solver Cheat Sheet

This directory contains the interactive web-based cheat sheet for the Wordle solver.

## Features

- 🎯 **Interactive filtering** - Search by letters or optimal guesses
- 📊 **Sortable results** - Sort by remaining words or pattern
- 🎨 **Wordle-style design** - Familiar color coding (green/yellow/gray)
- 📱 **Responsive** - Works on desktop and mobile
- ⚡ **Fast** - Client-side JavaScript, no server needed

## Files

- `index.html` - Main web page
- `styles.css` - Wordle-themed styling
- `app.js` - Interactive functionality
- `data/turn1.json` - Optimal strategy data for Turn 1
- `data/stats.json` - Overall statistics

## Usage

### Local Development

**Important:** You must use a local web server (not `file://`) to load the JSON data files.

```bash
# Start local server
cd web
python3 -m http.server 8000

# Visit http://localhost:8000 in your browser
```

**Why?** Browsers block loading JSON files from `file://` URLs for security (CORS policy).

Alternative servers:
```bash
# Python 2
python -m SimpleHTTPServer 8000

# Node.js (if you have http-server installed)
npx http-server -p 8000

# PHP
php -S localhost:8000
```

### GitHub Pages

This site is designed to be hosted on GitHub Pages. It will be available at:

```
https://cnoyes.github.io/wordle-solver/
```

## Data Generation

The JSON data files are generated from the optimal strategy RDS files:

```bash
Rscript scripts/04_export_web_data.R
```

This reads `data/derived/best_guess.RDS` and exports:
- Turn 1 outcomes with optimal next guesses
- Summary statistics

## How It Works

1. **Load** - JavaScript fetches the Turn 1 data (132 possible patterns after guessing "RAISE")
2. **Display** - Each outcome shows:
   - Color-coded pattern (🟩🟨⬜)
   - Number of remaining possible words
   - Optimal next guess
   - Additional statistics
3. **Filter** - Users can search and sort to quickly find their pattern
4. **Navigate** - Clear instructions guide users through the solving process

## Browser Compatibility

- ✅ Chrome/Edge (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Mobile browsers

Requires JavaScript enabled.

## Future Enhancements

- [ ] Add Turn 2-6 outcomes (more data needed)
- [ ] Interactive pattern selector (click tiles to set colors)
- [ ] Dark mode toggle
- [ ] Game history tracking
- [ ] Share results functionality
