# AGENTS.md

Static site generator for a personal homepage: Ruby Rake + ERB + pandoc. `Rakefile` is the source of truth for the build.

## Commands

- `bundle install`: install the Ruby gems
- `./make`: build the site into `docs/`
- `./make serve`: serve `docs/` locally
- `./make watch`: rebuild on change (needs `entr` and `ts`)
- `./make format`: reformat `posts/*.md` in place with pandoc
- `cd cv && npm install && ./make`: build the CV into `docs/cv/`

## Gotchas

- The build rewrites `notes/links.md`: it fetches titles from Hacker News, YouTube and antirez.com, so it needs network access. It only enriches a line that is a bare link, so it does not fetch a link again after it adds a title.
- `docs/` is the GitHub Pages root. Generated files in it are committed, so commit them with the source change. `rake clean` only deletes generated files, not the static ones in `docs/`.
- Pages are written at different depths. In templates, use `site_link(path)` for internal links.
- Each new post needs a link preview image. The build makes it with libvips in a Docker image (`link_preview/`), so Docker must be running.
- `posts/ideas/` is not built.
