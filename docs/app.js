// Load and display incidents
let allIncidents = [];
let activeFilters = {
    technologies: new Set(),
    difficulties: new Set(),
    skills: new Set()
};

// Load incidents data
fetch('incidents.json')
    .then(response => response.json())
    .then(incidents => {
        allIncidents = incidents;
        initializeFilters();
        renderIncidents();
    })
    .catch(error => {
        console.error('Error loading incidents:', error);
    });

// Initialize filter pills
function initializeFilters() {
    const technologies = new Set();
    const difficulties = new Set();
    const skills = new Set();

    allIncidents.forEach(incident => {
        incident.technologies.forEach(t => technologies.add(t));
        difficulties.add(incident.difficulty);
        incident.skills.forEach(s => skills.add(s));
    });

    renderFilterPills('tech-filters', Array.from(technologies).sort(), 'technologies');
    renderFilterPills('difficulty-filters', ['Beginner', 'Intermediate', 'Advanced', 'Not Rated'], 'difficulties');
    renderFilterPills('skill-filters', Array.from(skills).sort(), 'skills');
}

// Render filter pills
function renderFilterPills(containerId, items, filterType) {
    const container = document.getElementById(containerId);
    container.innerHTML = items.map(item =>
        `<button class="filter-pill" data-type="${filterType}" data-value="${item}">${item}</button>`
    ).join('');

    container.addEventListener('click', (e) => {
        if (e.target.classList.contains('filter-pill')) {
            toggleFilter(e.target, filterType, e.target.dataset.value);
        }
    });
}

// Toggle filter
function toggleFilter(element, filterType, value) {
    element.classList.toggle('active');

    if (element.classList.contains('active')) {
        activeFilters[filterType].add(value);
    } else {
        activeFilters[filterType].delete(value);
    }

    renderIncidents();
}

// Filter incidents
function filterIncidents() {
    return allIncidents.filter(incident => {
        // Technology filter (OR logic)
        if (activeFilters.technologies.size > 0) {
            const hasMatchingTech = incident.technologies.some(t =>
                activeFilters.technologies.has(t)
            );
            if (!hasMatchingTech) return false;
        }

        // Difficulty filter
        if (activeFilters.difficulties.size > 0) {
            if (!activeFilters.difficulties.has(incident.difficulty)) {
                return false;
            }
        }

        // Skills filter (OR logic)
        if (activeFilters.skills.size > 0) {
            const hasMatchingSkill = incident.skills.some(s =>
                activeFilters.skills.has(s)
            );
            if (!hasMatchingSkill) return false;
        }

        return true;
    });
}

// Render incidents
function renderIncidents() {
    const filtered = filterIncidents();
    const grid = document.getElementById('incidents-grid');
    const noResults = document.getElementById('no-results');
    const resultsCount = document.getElementById('results-count');

    // Update count
    resultsCount.textContent = `Showing ${filtered.length} of ${allIncidents.length} incidents`;

    if (filtered.length === 0) {
        grid.style.display = 'none';
        noResults.style.display = 'block';
        return;
    }

    grid.style.display = 'grid';
    noResults.style.display = 'none';

    grid.innerHTML = filtered.map(incident => `
        <a href="https://github.com/khbarkar/openRam/tree/main/${incident.path}" class="incident-card fade-in" target="_blank">
            <h2>${escapeHtml(incident.title)}</h2>
            <p class="description">${escapeHtml(incident.description)}</p>
            <div class="tags">
                <span class="tag difficulty">${escapeHtml(incident.difficulty)}</span>
                ${incident.technologies.map(t => `<span class="tag">${escapeHtml(t)}</span>`).join('')}
                ${incident.skills.map(s => `<span class="tag">${escapeHtml(s)}</span>`).join('')}
            </div>
            <span class="view-link">View Scenario →</span>
        </a>
    `).join('');
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
