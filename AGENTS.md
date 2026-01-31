# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Build Commands

Build the site:
```bash
./make
```

Watch for changes and rebuild automatically (requires `entr` and `ts`):
```bash
./make watch
```

Local dev server:
```bash
./make serve
```

Clean generated files:
```bash
rake clean
```

### CV Build (in cv/ directory)

```bash
cd cv && npm install && ./make
```

This generates `cv/index.html` from ERB template and `cv/cv.pdf` using electron-pdf.

## Architecture

This is a static site generator for a personal homepage, built with Ruby Rake and ERB templates.

### Content Structure

- **Blog posts**: `posts/YYYY-MM-DD_slug.md` → compiled to `build/posts/slug.html`
- **Notes**: `notes/*.md` → compiled to `build/notes/*.html`
- **Links**: `links.md` → `build/links.html`
- **Index**: Generated from `templates/index.html.erb` → `build/index.html`

### Build Pipeline

The Rakefile orchestrates the build:
1. Markdown files are converted to intermediate HTML via pandoc (stored in `.tmp/`)
2. Intermediate HTML is wrapped with ERB templates to produce final HTML in `build/`
3. Posts also generate link preview images (requires Chrome and Docker/imagemagick)
4. An Atom feed (`atom.xml`) is generated from blog posts

### Key Files

- `Rakefile` - Build system with `Post` and `Note` classes
- `make` - Shell wrapper for rake commands
- `templates/` - ERB templates (index, post, note, links, notes, head)
- `templates/style.css` - Site-wide styles

### Dependencies

- Ruby with `rake`, `erubi`, `nokogiri` gems (nokogiri is inline-installed via bundler)
- `pandoc` for markdown conversion
- For link previews: Chrome binary and Docker with imagemagick

## Build Output Directory

All build output goes to `build/` in the repository root (gitignored). This enables serving from a dedicated directory for GitHub Pages via GitHub Actions.

### Output Structure

- `build/index.html`, `build/links.html`, `build/notes.html`, `build/atom.xml`
- `build/posts/*.html` and `build/posts/*.md` (compiled posts + source markdown)
- `build/notes/*.html` and `build/notes/*.md` (compiled notes + source markdown)
- `build/assets/` (static assets including link preview images)
- `build/templates/style.css`
- `build/cv/` (CV HTML and PDF, built separately via `cd cv && ./make`)

### Backwards Compatibility

Redirect HTML files in `assets/redirects/` are copied to `build/` root so old post URLs continue to work:
- `2022-12-03_aoc3.html` → redirects to `posts/2022-12-03_aoc3.html`
- `2023-05-07_ruby-bug-shell-gem.html` → redirects to `posts/2023-05-07_ruby-bug-shell-gem.html`
- `2023-11-05_ruby-ascii-8bit.html` → redirects to `posts/2023-11-05_ruby-ascii-8bit.html`
- `2024-05-25_just-use-curl.html` → redirects to `posts/2024-05-25_just-use-curl.html`
- `2025-02-01_k8s-dns.html` → redirects to `posts/2025-02-01_k8s-dns.html`

### Serving Markdown Files

Source markdown files (`posts/*.md`, `notes/*.md`, `links.md`) and generated `index.md` are copied to `build/` so they can be served directly alongside the generated HTML.
