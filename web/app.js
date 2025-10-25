// Wordle Solver - Interactive Cheat Sheet JavaScript

let allOutcomes = [];
let filteredOutcomes = [];

// Load data on page load
document.addEventListener('DOMContentLoaded', async () => {
    try {
        const response = await fetch('data/turn1.json');
        const data = await response.json();

        allOutcomes = data.outcomes;
        filteredOutcomes = [...allOutcomes];

        updateStats(data);
        renderOutcomes();
        attachEventListeners();
    } catch (error) {
        console.error('Error loading data:', error);
        document.getElementById('results').innerHTML = `
            <div class="loading" style="color: #d32f2f;">
                ⚠️ Error loading cheat sheet data. Please ensure data files are present.
            </div>
        `;
    }
});

// Update statistics display
function updateStats(data) {
    const statsEl = document.getElementById('stats');
    statsEl.innerHTML = `
        <span id="showing-count">Showing ${filteredOutcomes.length} of ${allOutcomes.length} patterns</span>
    `;
}

// Render outcomes to the page
function renderOutcomes() {
    const resultsEl = document.getElementById('results');

    if (filteredOutcomes.length === 0) {
        resultsEl.innerHTML = `
            <div class="no-results">
                <h3>No matches found</h3>
                <p>Try adjusting your search or filter criteria</p>
            </div>
        `;
        return;
    }

    const grid = document.createElement('div');
    grid.className = 'outcome-grid';

    filteredOutcomes.forEach(outcome => {
        const card = createOutcomeCard(outcome);
        grid.appendChild(card);
    });

    resultsEl.innerHTML = '';
    resultsEl.appendChild(grid);

    // Update count
    document.getElementById('showing-count').textContent =
        `Showing ${filteredOutcomes.length} of ${allOutcomes.length} patterns`;
}

// Create individual outcome card
function createOutcomeCard(outcome) {
    const card = document.createElement('div');
    card.className = 'outcome-card';

    // Pattern tiles
    const pattern = document.createElement('div');
    pattern.className = 'pattern';

    for (let i = 1; i <= 5; i++) {
        const tile = document.createElement('span');
        tile.className = `tile ${outcome[`p${i}_color`]}`;
        tile.textContent = outcome[`letter${i}`];
        pattern.appendChild(tile);
    }

    // Outcome info
    const info = document.createElement('div');
    info.className = 'outcome-info';

    info.innerHTML = `
        <div class="next-guess-label">YOUR SECOND GUESS:</div>
        <div class="next-guess" title="Enter this word in Wordle">
            ${outcome.next_guess ? outcome.next_guess.toUpperCase() : 'SOLVED!'}
        </div>
        <div class="stat">
            ${outcome.remaining_words} ${outcome.remaining_words === 1 ? 'word' : 'possible words'} remaining
        </div>
        <div class="additional-stats">
            <div>Expected remaining: ${outcome.avg_remaining?.toFixed(1) || 'N/A'}</div>
        </div>
    `;

    card.appendChild(pattern);
    card.appendChild(info);

    return card;
}

// Attach event listeners for filtering and sorting
function attachEventListeners() {
    const searchInput = document.getElementById('search');
    const sortSelect = document.getElementById('sort');

    searchInput.addEventListener('input', filterAndRender);
    sortSelect.addEventListener('change', filterAndRender);
}

// Filter and re-render outcomes
function filterAndRender() {
    const searchTerm = document.getElementById('search').value.toLowerCase();
    const sortBy = document.getElementById('sort').value;

    // Filter
    filteredOutcomes = allOutcomes.filter(outcome => {
        if (!searchTerm) return true;

        // Search in letters
        const letters = [
            outcome.letter1,
            outcome.letter2,
            outcome.letter3,
            outcome.letter4,
            outcome.letter5
        ].join('').toLowerCase();

        // Search in next guess
        const nextGuess = (outcome.next_guess || '').toLowerCase();

        return letters.includes(searchTerm) || nextGuess.includes(searchTerm);
    });

    // Sort
    switch (sortBy) {
        case 'remaining':
            filteredOutcomes.sort((a, b) => a.remaining_words - b.remaining_words);
            break;
        case 'remaining-desc':
            filteredOutcomes.sort((a, b) => b.remaining_words - a.remaining_words);
            break;
        case 'pattern':
        default:
            // Keep original pattern-based order
            filteredOutcomes.sort((a, b) => a.pattern_id - b.pattern_id);
            break;
    }

    renderOutcomes();
}
