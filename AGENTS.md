# AGENTS.md

Static site generator for a personal homepage: Ruby Rake + ERB + pandoc. `Rakefile` is the source of truth for the build.

## Commands

- `bundle install`: install the Ruby gems
- `./make`: build the site into `docs/`
- `./make serve`: serve `docs/` locally
- `./make watch`: rebuild on change (needs `entr` and `ts`)
- `cd cv && npm install && ./make`: build the CV into `docs/cv/`

## Gotchas

- The build reformats `posts/*.md` in place with pandoc. Set `NOFORMAT` (any value, also empty) to skip this.
- The build rewrites `notes/links.md`: it fetches titles from Hacker News, YouTube and antirez.com, so it needs network access. `docs/links.md` from the previous build is the cache of processed lines. `rake clean` deletes it, and the next build fetches all links again.
- `docs/` is the GitHub Pages root. Generated files in it are committed, so commit them with the source change. `rake clean` only deletes generated files, not the static ones in `docs/`.
- Pages are written at different depths. In templates, use `site_link(path)` for internal links.
- Each new post needs a link preview image, made with Chrome at its macOS path and Docker (imagemagick).
- `posts/ideas/` is not built.
