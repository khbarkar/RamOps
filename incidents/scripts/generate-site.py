#!/usr/bin/env python3
"""
Generate GitHub Pages site from incident directories.
Parses YAML frontmatter from root-cause-analysis.md files.
"""

import os
import re
import json
from pathlib import Path
from typing import Dict, List, Optional

# Base directory is repo root (two levels up from incidents/scripts/)
BASE_DIR = Path(__file__).parent.parent.parent
DOCS_DIR = BASE_DIR / "docs"
OUTPUT_JSON = DOCS_DIR / "incidents.json"


def extract_frontmatter(content: str) -> Optional[Dict]:
    """Extract YAML frontmatter from markdown content using simple regex parsing."""
    match = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
    if not match:
        return None

    frontmatter_text = match.group(1)
    data = {}

    # Parse simple YAML fields
    # title: "Some title" or title: Some title
    title_match = re.search(r'title:\s*["\']?(.*?)["\']?\s*$', frontmatter_text, re.MULTILINE)
    if title_match:
        data['title'] = title_match.group(1).strip('"\'')

    # difficulty: Beginner
    diff_match = re.search(r'difficulty:\s*(\w+)', frontmatter_text)
    if diff_match:
        data['difficulty'] = diff_match.group(1)

    # description: "Some description"
    desc_match = re.search(r'description:\s*["\']?(.*?)["\']?\s*$', frontmatter_text, re.MULTILINE)
    if desc_match:
        data['description'] = desc_match.group(1).strip('"\'')

    # skills: [Debugging, Troubleshooting] or skills: Debugging, Troubleshooting
    skills_match = re.search(r'skills:\s*\[(.*?)\]', frontmatter_text)
    if skills_match:
        data['skills'] = [s.strip().strip('"\'') for s in skills_match.group(1).split(',')]
    else:
        skills_match = re.search(r'skills:\s*(.+)', frontmatter_text)
        if skills_match:
            data['skills'] = [s.strip().strip('"\'') for s in skills_match.group(1).split(',')]

    # technologies: [Kubernetes, Docker]
    tech_match = re.search(r'technologies:\s*\[(.*?)\]', frontmatter_text)
    if tech_match:
        data['technologies'] = [t.strip().strip('"\'') for t in tech_match.group(1).split(',')]
    else:
        tech_match = re.search(r'technologies:\s*(.+)', frontmatter_text)
        if tech_match:
            data['technologies'] = [t.strip().strip('"\'') for t in tech_match.group(1).split(',')]

    return data if data else None


def get_description_fallback(content: str, frontmatter: Optional[Dict]) -> str:
    """Get description from frontmatter or extract from markdown body."""
    if frontmatter and 'description' in frontmatter:
        return frontmatter['description']

    # Remove frontmatter and extract first 100 chars
    content = re.sub(r'^---\s*\n.*?\n---\s*\n', '', content, flags=re.DOTALL)
    # Remove markdown headings and extra whitespace
    content = re.sub(r'^#+\s+', '', content, flags=re.MULTILINE)
    content = ' '.join(content.split())
    return content[:100] + ('...' if len(content) > 100 else '')


def parse_readme_metadata(readme_path: Path) -> Dict:
    """Parse metadata from README.md file."""
    try:
        with open(readme_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        metadata = {}
        
        # Extract title from first heading
        title_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
        if title_match:
            metadata['title'] = title_match.group(1).strip()
        
        # Extract description from ## Scenario section
        scenario_match = re.search(r'##\s+Scenario\s*\n\n(.+?)(?:\n\n##|\Z)', content, re.DOTALL)
        if scenario_match:
            desc = scenario_match.group(1).strip()
            desc = ' '.join(desc.split())  # Normalize whitespace
            metadata['description'] = desc[:200] + ('...' if len(desc) > 200 else '')
        
        # Extract difficulty
        diff_match = re.search(r'\*\*Difficulty:\*\*\s*(.+?)(?:\n|$)', content)
        if diff_match:
            metadata['difficulty'] = diff_match.group(1).strip()
        
        return metadata
    except Exception as e:
        print(f"Warning: Could not parse README {readme_path}: {e}")
        return {}


def parse_incident(rca_path: Path) -> Optional[Dict]:
    """Parse a single incident from its RCA file."""
    try:
        with open(rca_path, 'r', encoding='utf-8') as f:
            content = f.read()

        frontmatter = extract_frontmatter(content)
        incident_dir = rca_path.parent
        readme_path = incident_dir / 'README.md'

        # Get relative path from repo root (e.g., incidents/kubernetes/incident-001)
        rel_path = incident_dir.relative_to(BASE_DIR)

        # Try to get metadata from README.md first
        readme_metadata = parse_readme_metadata(readme_path) if readme_path.exists() else {}

        # Extract title (priority: frontmatter > README > directory name)
        if frontmatter and 'title' in frontmatter:
            title = frontmatter['title']
        elif 'title' in readme_metadata:
            title = readme_metadata['title']
        else:
            title = incident_dir.name.replace('-', ' ').replace('_', ' ').title()

        # Extract difficulty (priority: frontmatter > README > Not Rated)
        if frontmatter and 'difficulty' in frontmatter:
            difficulty = frontmatter['difficulty']
        elif 'difficulty' in readme_metadata:
            difficulty = readme_metadata['difficulty']
        else:
            difficulty = 'Not Rated'

        # Extract skills
        skills = frontmatter.get('skills', []) if frontmatter else []
        if isinstance(skills, str):
            skills = [s.strip() for s in skills.split(',')]

        # Extract technologies
        technologies = frontmatter.get('technologies', []) if frontmatter else []
        if isinstance(technologies, str):
            technologies = [t.strip() for t in technologies.split(',')]

        # If no technologies, infer from path
        if not technologies:
            path_parts = str(rel_path).split('/')
            if len(path_parts) > 1:
                tech = path_parts[1].replace('-', ' ').title()
                technologies = [tech]

        # Get description (priority: frontmatter > README > RCA fallback)
        if frontmatter and 'description' in frontmatter:
            description = frontmatter['description']
        elif 'description' in readme_metadata:
            description = readme_metadata['description']
        else:
            description = get_description_fallback(content, frontmatter)

        return {
            'id': str(rel_path).replace('\\', '/'),
            'title': title,
            'description': description,
            'difficulty': difficulty,
            'skills': skills,
            'technologies': technologies,
            'path': str(rel_path).replace('\\', '/')
        }

    except Exception as e:
        print(f"Error parsing {rca_path}: {e}")
        return None


def find_incidents() -> List[Dict]:
    """Find and parse all incident directories."""
    incidents = []

    # Find all directories matching incidents/*/incident-*/
    incidents_dir = BASE_DIR / "incidents"
    for category_dir in incidents_dir.iterdir():
        if not category_dir.is_dir() or category_dir.name in ['scripts', '__pycache__']:
            continue

        for incident_dir in category_dir.iterdir():
            if not incident_dir.is_dir() or not incident_dir.name.startswith('incident-'):
                continue

            rca_path = incident_dir / 'root-cause-analysis.md'
            if not rca_path.exists():
                print(f"Warning: No RCA file in {incident_dir}")
                continue

            incident = parse_incident(rca_path)
            if incident:
                incidents.append(incident)
                print(f"Parsed: {incident['id']}")

    return incidents


def generate_incidents_json(incidents: List[Dict]):
    """Write incidents.json to docs directory."""
    DOCS_DIR.mkdir(exist_ok=True)

    with open(OUTPUT_JSON, 'w', encoding='utf-8') as f:
        json.dump(incidents, f, indent=2, ensure_ascii=False)

    print(f"\nGenerated {OUTPUT_JSON} with {len(incidents)} incidents")


def generate_html():
    """Generate index.html."""
    html = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ram Ops - Incident Training Scenarios</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <header>
        <div class="container">
            <div class="header-content">
                <img src="img/logo.png" alt="Ram Ops" class="logo">
                <a href="https://github.com/khbarkar/openRam" class="github-link" target="_blank">
                    <svg width="24" height="24" viewBox="0 0 16 16" fill="currentColor">
                        <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"/>
                    </svg>
                </a>
            </div>
        </div>
    </header>

    <main class="container">
        <div class="filters">
            <div class="filter-section">
                <h3>Technology</h3>
                <div id="tech-filters" class="filter-pills"></div>
            </div>
            <div class="filter-section">
                <h3>Difficulty</h3>
                <div id="difficulty-filters" class="filter-pills"></div>
            </div>
            <div class="filter-section">
                <h3>Skills</h3>
                <div id="skill-filters" class="filter-pills"></div>
            </div>
        </div>

        <div class="results-count" id="results-count"></div>

        <div class="incidents-grid" id="incidents-grid">
            <!-- Generated by app.js -->
        </div>

        <div class="no-results" id="no-results" style="display: none;">
            No incidents match your filters
        </div>
    </main>

    <script src="app.js"></script>
</body>
</html>
"""

    with open(DOCS_DIR / "index.html", 'w', encoding='utf-8') as f:
        f.write(html)

    print(f"Generated {DOCS_DIR / 'index.html'}")


def generate_css():
    """Generate styles.css."""
    css = """* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    background: #000000;
    color: #FFFFFF;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    line-height: 1.6;
}

.container {
    max-width: 1400px;
    margin: 0 auto;
    padding: 0 20px;
}

/* Header */
header {
    background: #000000;
    border-bottom: 1px solid #333;
    padding: 15px 0;
}

.header-content {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.logo {
    height: 50px;
    width: auto;
}

.github-link {
    color: #FFFFFF;
    text-decoration: none;
    transition: opacity 0.2s;
}

.github-link:hover {
    opacity: 0.7;
}

/* Filters */
.filters {
    margin: 30px 0;
}

.filter-section {
    margin-bottom: 20px;
}

.filter-section h3 {
    font-size: 14px;
    text-transform: uppercase;
    letter-spacing: 1px;
    color: #CCCCCC;
    margin-bottom: 10px;
}

.filter-pills {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
}

.filter-pill {
    background: #1A1A1A;
    color: #FFFFFF;
    padding: 8px 16px;
    border-radius: 20px;
    border: 1px solid #333;
    cursor: pointer;
    font-size: 14px;
    transition: all 0.2s;
}

.filter-pill:hover {
    border-color: #666;
}

.filter-pill.active {
    background: #FF0000;
    color: #FFFFFF;
    border-color: #FF0000;
}

/* Results Count */
.results-count {
    color: #CCCCCC;
    margin-bottom: 20px;
    font-size: 14px;
}

/* Incidents Grid */
.incidents-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
    gap: 20px;
    margin-bottom: 40px;
}

.incident-card {
    background: #1A1A1A;
    border: 1px solid #333;
    border-radius: 8px;
    padding: 20px;
    transition: all 0.2s;
    cursor: pointer;
    text-decoration: none;
    color: inherit;
    display: block;
}

.incident-card:hover {
    border-color: #666;
    transform: translateY(-2px);
}

.incident-card h2 {
    font-size: 18px;
    margin-bottom: 10px;
    color: #FFFFFF;
}

.incident-card .description {
    color: #CCCCCC;
    font-size: 14px;
    margin-bottom: 15px;
    line-height: 1.5;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
}

.incident-card .tags {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    margin-bottom: 15px;
}

.tag {
    background: #000000;
    color: #FFFFFF;
    padding: 4px 10px;
    border-radius: 12px;
    font-size: 12px;
    border: 1px solid #333;
}

.tag.difficulty {
    background: #333;
}

.incident-card .view-link {
    color: #FF0000;
    font-size: 14px;
    font-weight: 500;
}

/* No Results */
.no-results {
    text-align: center;
    color: #CCCCCC;
    padding: 60px 20px;
    font-size: 18px;
}

/* Responsive */
@media (max-width: 1024px) {
    .incidents-grid {
        grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    }
}

@media (max-width: 768px) {
    .incidents-grid {
        grid-template-columns: 1fr;
    }

    .logo {
        height: 40px;
    }
}

/* Fade animations */
@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}

@keyframes fadeOut {
    from { opacity: 1; }
    to { opacity: 0; }
}

.fade-in {
    animation: fadeIn 0.2s;
}

.fade-out {
    animation: fadeOut 0.2s;
}
"""

    with open(DOCS_DIR / "styles.css", 'w', encoding='utf-8') as f:
        f.write(css)

    print(f"Generated {DOCS_DIR / 'styles.css'}")


def generate_js():
    """Generate app.js."""
    js = """// Load and display incidents
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
"""

    with open(DOCS_DIR / "app.js", 'w', encoding='utf-8') as f:
        f.write(js)

    print(f"Generated {DOCS_DIR / 'app.js'}")


def main():
    """Main entry point."""
    print("Generating Ram Ops GitHub Pages site...")
    print("=" * 50)

    # Parse incidents
    incidents = find_incidents()

    if not incidents:
        print("\nError: No incidents found!")
        return 1

    # Generate output files
    generate_incidents_json(incidents)
    generate_html()
    generate_css()
    generate_js()

    print("=" * 50)
    print("Generation complete!")
    print(f"\nOpen {DOCS_DIR / 'index.html'} in your browser to preview.")

    return 0


if __name__ == "__main__":
    exit(main())
