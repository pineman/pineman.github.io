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

- **Blog posts**: `posts/YYYY-MM-DD_slug.md` → compiled to `posts/slug.html` and root `slug.html`
- **Notes**: `notes/*.md` → compiled to `notes/*.html`
- **Links**: `links.md` → `links.html`
- **Index**: Generated from `templates/index.html.erb`

### Build Pipeline

The Rakefile orchestrates the build:
1. Markdown files are converted to intermediate HTML via pandoc (`posts/html/`, `notes/html/`)
2. Intermediate HTML is wrapped with ERB templates to produce final HTML
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
