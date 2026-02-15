# GitHub Pages Interactive Catalog Design

**Date:** 2026-02-15
**Status:** Approved

## Overview

An interactive incident catalog for Ram Ops, deployed as a GitHub Pages site. Users can browse and filter incident scenarios by technology, difficulty, and skill type. The site auto-generates from incident directories on every push to main.

## Requirements

- Single-page interactive catalog with tag-based filtering
- Pure black (#000000) background with white/light text
- Logo left-aligned in header
- Filter by: Technology, Difficulty, Skill type
- Each incident card shows: title, description, tags, difficulty, link
- Fully mobile-responsive
- Auto-generated from incident directories via GitHub Actions
- No emojis

## Architecture

### Repository Structure

```
docs/
  img/logo.png          (existing)
  index.html            (generated)
  styles.css            (generated)
  app.js                (generated)
  incidents.json        (generated from parsing)
.github/
  workflows/
    deploy-pages.yml    (GitHub Actions workflow)
scripts/
  generate-site.py      (parsing and generation script)
```

### Generation Flow

1. Python script scans all `*/incident-*/` directories
2. Reads `root-cause-analysis.md` files and extracts YAML frontmatter
3. Generates `docs/incidents.json` with all incident data
4. Generates static HTML/CSS/JS files in `docs/`
5. GitHub Actions triggers on push to main, runs script, deploys to GitHub Pages

### Frontmatter Format

Add to each `root-cause-analysis.md`:

```yaml
---
title: "Production pod crash-looping"
difficulty: Beginner
skills: [Debugging, Troubleshooting]
technologies: [Kubernetes, Docker]
description: "Users reporting site is down due to crash-looping pods"
---
```

## Visual Design

### Color Scheme

- Background: Pure black `#000000`
- Text: White `#FFFFFF` for primary, light gray `#CCCCCC` for secondary
- Accents: Bright red `#FF0000` or white for interactive elements
- Cards: Dark gray `#1A1A1A` with subtle border

### Header Layout

```
[Logo: Ram Ops]                    [GitHub Icon Link]
```

- Logo left-aligned, 120px wide
- Minimal height (60-80px)
- GitHub icon/link on the right to repo

### Main Layout

```
+------------------------------------------+
|  Filter Bar: [All] [Kubernetes] [Kafka] |
|  [Beginner] [Intermediate] [Advanced]   |
|  [Debugging] [Troubleshooting] ...      |
+------------------------------------------+
|  [Incident Card] [Incident Card]        |
|  [Incident Card] [Incident Card]        |
+------------------------------------------+
```

### Incident Card Design

- Dark gray background card with white text
- Title (large, bold)
- Description (2 lines, truncated if needed)
- Tags as small pills (technology, difficulty, skills)
- "View Scenario" link/button at bottom
- Hover effect: subtle border or brightness increase

### Responsive Breakpoints

- Desktop: 3-column grid
- Tablet: 2-column grid
- Mobile: 1-column stack

## Interactive Behavior

### Filter Behavior

- All filters start in "show all" state
- Clicking a filter tag toggles it on/off (active state = white text on red background)
- Multiple filters can be active simultaneously
- Logic: Incidents must match ALL active filters (AND logic within category, OR across categories)
  - Example: "Kubernetes" + "Beginner" = show only beginner Kubernetes incidents
  - Example: "Debugging" + "Troubleshooting" = show incidents tagged with either skill

### Filter Categories

1. **Technology**: Auto-discovered from frontmatter (Kubernetes, Kafka, Terraform, etc.)
2. **Difficulty**: Beginner, Intermediate, Advanced
3. **Skills**: Debugging, Troubleshooting, Investigation, Recovery, Prevention

### Dynamic Updates

- Instant filtering with JavaScript (no page reload)
- Show count: "Showing X of Y incidents"
- If no matches: "No incidents match your filters" message
- Smooth fade in/out animation for cards (200ms)

### Card Click Behavior

- Entire card is clickable
- Links to the incident directory on GitHub (e.g., `incidents/kubernetes/incident-001/`)
- Opens in same tab (user can cmd/ctrl-click for new tab)

## Technical Implementation

### Python Generation Script

**Location:** `scripts/generate-site.py`

**Functionality:**
1. Scans for all directories matching pattern `*/incident-*/`
2. Reads each `root-cause-analysis.md` file
3. Extracts YAML frontmatter (title, difficulty, skills, technologies, description)
4. Falls back gracefully if frontmatter missing (use directory name, mark as "Unknown" difficulty)
5. Generates `docs/incidents.json` with all incident data
6. Copies template HTML/CSS/JS files to `docs/` (or generates them if fully dynamic)

### GitHub Actions Workflow

**Location:** `.github/workflows/deploy-pages.yml`

```yaml
on:
  push:
    branches: [main]

jobs:
  build-deploy:
    runs-on: ubuntu-latest
    steps:
      - Checkout code
      - Setup Python
      - Run generate-site.py
      - Deploy to GitHub Pages (actions/deploy-pages)
```

### Dependencies

- Python 3.8+ with PyYAML
- No other dependencies needed
- Fast execution (completes in seconds)

### Manual Testing

- Can run `scripts/generate-site.py` locally
- Opens `docs/index.html` in browser to preview
- Commit generated files or gitignore them (implementation decision)

## Error Handling

### Missing Frontmatter

- If RCA file has no frontmatter: extract title from filename, mark difficulty as "Not Rated", add "Uncategorized" tag
- Still display the incident, just with limited metadata

### Incomplete Frontmatter

- Missing description: Use first 100 characters from RCA markdown body
- Missing tags: Show "No tags" but still allow filtering by other attributes
- Missing difficulty: Default to "Not Rated" category

### Generation Failures

- Script logs errors but continues processing other incidents
- Outputs warning summary at end
- Does not fail the GitHub Actions build unless zero incidents found

### Browser Compatibility

- Vanilla JavaScript (ES6), works in all modern browsers
- No framework dependencies (React, Vue, etc.)
- Fallback for browsers without JavaScript: static list of incidents

### Performance

- All filtering happens client-side (fast, no server needed)
- incidents.json cached by browser
- Lazy load card images if we add screenshots later

## Maintenance

- Add new incident: just create directory + RCA with frontmatter, auto-appears on next push
- Update incident: edit frontmatter, auto-updates
- No manual catalog maintenance needed

## Success Criteria

1. Site deploys automatically on push to main
2. All incidents with frontmatter appear in catalog
3. Filtering works smoothly across all three categories
4. Site is fully responsive on mobile, tablet, desktop
5. Pure black theme with logo displayed correctly
6. No manual catalog maintenance required when adding new incidents
