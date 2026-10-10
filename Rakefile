require "erubi"
require "nokogiri"
require "vips"

require "cgi"
require "date"
require "json"
require "rake/clean"
require "uri"

Rake::FileUtilsExt.verbose(false)

SITE_ROOT = "https://pineman.github.io"

BUILD_DIR = "docs"

INDEX_HTML = "#{BUILD_DIR}/index.html"
INDEX_MD = "#{BUILD_DIR}/index.md"
LINKS_HTML = "#{BUILD_DIR}/links.html"
NOTES_HTML = "#{BUILD_DIR}/notes.html"
NOTES_INDEX_MD = "#{BUILD_DIR}/notes.md"
NOTES_DIR = "notes"
POSTS_DIR = "posts"
TMP_DIR = ".tmp"
NOTES_HTML_DIR = "#{TMP_DIR}/notes"
POSTS_HTML_DIR = "#{TMP_DIR}/posts"
LINKS_MD = "notes/links.md"
ATOM_XML = "#{BUILD_DIR}/atom.xml"
SITEMAP_XML = "#{BUILD_DIR}/sitemap.xml"
LINK_PREVIEWS_DIR = "#{BUILD_DIR}/assets/link_previews"

BUILD_POSTS_DIR = "#{BUILD_DIR}/posts"
BUILD_NOTES_DIR = "#{BUILD_DIR}/notes"
POST_ASSETS_DIR = "#{POSTS_DIR}/assets"
BUILD_POST_ASSETS_DIR = "#{BUILD_POSTS_DIR}/assets"
BUILD_STYLE_CSS = "#{BUILD_DIR}/style.css"
BUILD_LINKS_MD = "#{BUILD_DIR}/links.md"

TEMPLATES_DIR = "templates"
TEMPLATE_INDEX = "#{TEMPLATES_DIR}/index.html.erb"
TEMPLATE_POST = "#{TEMPLATES_DIR}/post.html.erb"
TEMPLATE_LINKS = "#{TEMPLATES_DIR}/links.html.erb"
TEMPLATE_NOTES = "#{TEMPLATES_DIR}/notes.html.erb"
TEMPLATE_NOTE = "#{TEMPLATES_DIR}/note.html.erb"
TEMPLATE_HEAD = "#{TEMPLATES_DIR}/head.html.erb"
TEMPLATE_ARTICLE_HEAD = "#{TEMPLATES_DIR}/article-head.html.erb"
TEMPLATE_PINECONE = "#{TEMPLATES_DIR}/pinecone.html"
TEMPLATE_ATOM = "#{TEMPLATES_DIR}/atom.xml.erb"
TEMPLATE_SITEMAP = "#{TEMPLATES_DIR}/sitemap.xml.erb"
TEMPLATE_REDIRECT = "#{TEMPLATES_DIR}/redirect.html.erb"
ICONS = FileList["#{TEMPLATES_DIR}/icons/*.svg"]

POSTS_MD = FileList["#{POSTS_DIR}/*.md"]
POSTS_HTML = POSTS_MD.pathmap("#{BUILD_POSTS_DIR}/%n.html")
POSTS_INTERMEDIATE_HTML = POSTS_MD.pathmap("#{POSTS_HTML_DIR}/%n.html")
LINK_PREVIEWS = POSTS_MD.pathmap("#{LINK_PREVIEWS_DIR}/%n.png")
BUILD_POSTS_MD = POSTS_MD.pathmap("#{BUILD_POSTS_DIR}/%f")
BUILD_POST_ASSETS = FileList["#{POST_ASSETS_DIR}/*"].pathmap("#{BUILD_POST_ASSETS_DIR}/%f")

NOTES_MD = FileList["#{NOTES_DIR}/*.md"].exclude(LINKS_MD)
NOTE_HTML = NOTES_MD.pathmap("#{BUILD_NOTES_DIR}/%n.html")
NOTES_INTERMEDIATE_HTML = NOTES_MD.pathmap("#{NOTES_HTML_DIR}/%n.html")
BUILD_NOTES_MD = NOTES_MD.pathmap("#{BUILD_NOTES_DIR}/%f")

LEGACY_REDIRECTS = %w[
  2022-12-03_aoc3
  2023-05-07_ruby-bug-shell-gem
  2023-11-05_ruby-ascii-8bit
  2024-05-25_just-use-curl
  2025-02-01_k8s-dns
]
REDIRECTS_HTML = LEGACY_REDIRECTS.map { |filename| "#{BUILD_DIR}/#{filename}.html" }

# Only clean generated files, not static assets in docs/
CLEAN.include(
  TMP_DIR,
  "#{BUILD_DIR}/*.html",
  "#{BUILD_DIR}/*.md",
  "#{BUILD_DIR}/*.xml",
  BUILD_STYLE_CSS,
  "#{BUILD_POSTS_DIR}",
  "#{BUILD_NOTES_DIR}",
  LINK_PREVIEWS_DIR
)

multitask default: [:all]
multitask all: [INDEX_HTML, INDEX_MD, LINKS_HTML, NOTES_HTML, NOTES_INDEX_MD, *NOTE_HTML, *POSTS_HTML, *LINK_PREVIEWS, ATOM_XML, SITEMAP_XML, BUILD_STYLE_CSS, *BUILD_POST_ASSETS, *REDIRECTS_HTML, *BUILD_POSTS_MD, *BUILD_NOTES_MD, BUILD_LINKS_MD]

directory BUILD_DIR
directory BUILD_POSTS_DIR
directory BUILD_NOTES_DIR
directory POSTS_HTML_DIR
directory NOTES_HTML_DIR
directory LINK_PREVIEWS_DIR
directory BUILD_POST_ASSETS_DIR

file INDEX_HTML => [BUILD_DIR, TEMPLATE_INDEX, *POSTS_HTML, TEMPLATE_HEAD, TEMPLATE_PINECONE, *ICONS] do |t|
  posts = POSTS_MD.map { |md| Post.new(md) }
  Page.new(t.name, posts:).write(TEMPLATE_INDEX)
end

file INDEX_MD => [BUILD_DIR, INDEX_HTML] do |t|
  html = File.read(INDEX_HTML).gsub(/<span class="icon-container".*?>.*?<\/span>/m, "")
  # pandoc only converts <main> when present, which would drop the header
  html = html.gsub(/<\/?main>/, "")
  html = html.gsub(/href="#{POSTS_DIR}\/(\d{4}-\d{2}-\d{2}_.*?)\.html"/, "href=\"#{POSTS_DIR}/\\1.md\"")
  html = html.gsub("href=\"links.html\"", "href=\"#{LINKS_MD}\"")
  Pandoc.html_to_md(html, t.name)
end

file NOTES_INDEX_MD => [BUILD_DIR, NOTES_HTML] do |t|
  html = File.read(NOTES_HTML)
  html = html.gsub(/href="#{NOTES_DIR}\/(.+?)\.html"/, "href=\"#{NOTES_DIR}/\\1.md\"")
  html = html.gsub(/<a href="[^"]*">&lt; back<\/a>/, "")
  Pandoc.html_to_md(html, t.name)
end

file LINKS_HTML => [BUILD_DIR, TEMPLATE_LINKS, LINKS_MD, TEMPLATE_HEAD, TEMPLATE_ARTICLE_HEAD] do |t|
  months = Links.process!
  Page.new(t.name, months:, updated: File.mtime(LINKS_MD)).write(TEMPLATE_LINKS)
end

file NOTES_HTML => [BUILD_DIR, TEMPLATE_NOTES, *NOTE_HTML, TEMPLATE_HEAD, TEMPLATE_ARTICLE_HEAD] do |t|
  notes = NOTES_MD.map { |md| Note.new(md) }
  Page.new(t.name, notes:).write(TEMPLATE_NOTES)
end

rule %r{^#{NOTES_HTML_DIR}/.*\.html$} => [->(f) { f.pathmap("#{NOTES_DIR}/%n.md") }, NOTES_HTML_DIR] do |t|
  Note.new(t.prerequisites.first).build_intermediate_html!
end

rule %r{^#{BUILD_NOTES_DIR}/.*\.html$} => [->(f) { f.pathmap("#{NOTES_HTML_DIR}/%f") }, BUILD_NOTES_DIR, TEMPLATE_NOTE, TEMPLATE_HEAD, TEMPLATE_ARTICLE_HEAD] do |t|
  note = Note.new(t.name.pathmap("#{NOTES_DIR}/%n.md"))
  Page.new(t.name, note:).write(TEMPLATE_NOTE)
end

rule %r{^#{POSTS_HTML_DIR}/.*\.html$} => [->(f) { f.pathmap("#{POSTS_DIR}/%n.md") }, POSTS_HTML_DIR] do |t|
  Post.new(t.prerequisites.first).build_intermediate_html!
end

rule %r{^#{BUILD_POSTS_DIR}/.*\.html$} => [->(f) { f.pathmap("#{POSTS_HTML_DIR}/%f") }, BUILD_POSTS_DIR, TEMPLATE_POST, TEMPLATE_HEAD, TEMPLATE_ARTICLE_HEAD, *ICONS] do |t|
  post = Post.new(t.name.pathmap("#{POSTS_DIR}/%n.md"))
  Page.new(t.name, post:).write(TEMPLATE_POST)
end

rule %r{^#{LINK_PREVIEWS_DIR}/.*\.png$} => [->(f) { f.pathmap("#{POSTS_HTML_DIR}/%n.html") }, LINK_PREVIEWS_DIR] do |t|
  Post.new(t.source.pathmap("#{POSTS_DIR}/%n.md")).gen_img!
end

file ATOM_XML => [BUILD_DIR, TEMPLATE_ATOM, *POSTS_HTML] do |t|
  posts = POSTS_MD.map { |md| Post.new(md) }.sort_by(&:date)
  Page.new(t.name, posts:).write(TEMPLATE_ATOM)
end

file SITEMAP_XML => [BUILD_DIR, TEMPLATE_SITEMAP, *POSTS_HTML, *NOTE_HTML] do |t|
  posts = POSTS_MD.map { |md| Post.new(md) }.sort_by(&:date).reverse
  notes = NOTES_MD.map { |md| Note.new(md) }
  Page.new(t.name, posts:, notes:).write(TEMPLATE_SITEMAP)
end

file BUILD_STYLE_CSS => ["#{TEMPLATES_DIR}/style.css", BUILD_DIR] do |t|
  cp t.source, t.name
end

rule %r{^#{BUILD_POST_ASSETS_DIR}/} => [->(f) { f.pathmap("#{POST_ASSETS_DIR}/%f") }, BUILD_POST_ASSETS_DIR] do |t|
  cp t.source, t.name
end

LEGACY_REDIRECTS.zip(REDIRECTS_HTML).each do |filename, redirect_html|
  file redirect_html => [TEMPLATE_REDIRECT, BUILD_DIR] do |t|
    Page.new(t.name, filename:).write(TEMPLATE_REDIRECT)
  end
end

rule %r{^#{BUILD_POSTS_DIR}/.*\.md$} => [->(f) { f.pathmap("#{POSTS_DIR}/%f") }, ->(f) { f.pathmap("#{POSTS_HTML_DIR}/%n.html") }, BUILD_POSTS_DIR] do |t|
  cp t.source, t.name
end

rule %r{^#{BUILD_NOTES_DIR}/.*\.md$} => [->(f) { f.pathmap("#{NOTES_DIR}/%f") }, BUILD_NOTES_DIR] do |t|
  cp t.source, t.name
end

file BUILD_LINKS_MD => [LINKS_MD, LINKS_HTML] do |t|
  cp t.source, t.name
end

# The context a page template is evaluated in: its data (post, notes, ...) as
# methods, and links relative to wherever the page is written.
class Page
  def initialize(file, **data)
    @file = file
    # e.g. "../" for docs/posts/*.html
    @root = "../" * file.delete_prefix("#{BUILD_DIR}/").count("/")
    data.each { |name, value| define_singleton_method(name) { value } }
  end

  def site_link(path)
    "#{@root}#{path}"
  end

  def years_ago(date)
    date = Date.parse(date)
    today = Date.today
    y = today.year - date.year
    y -= 1 if today.month < date.month || today.month == date.month && today.day < date.day
    y
  end

  # Inline Font Awesome Free icon. Its embedded license comment is dropped:
  # pages using icons carry a single CC BY 4.0 attribution comment instead.
  def icon(name)
    File.read("#{TEMPLATES_DIR}/icons/#{name}.svg")
      .sub(/<!--.*?-->/m, "")
      .sub("<svg ", '<svg aria-hidden="true" fill="currentColor" ')
      .strip
  end

  def json_ld(data)
    # Escape "<" so the JSON can never close the script tag
    %(<script type="application/ld+json">#{JSON.pretty_generate(data).gsub("<", "\\u003c")}</script>)
  end

  def render(template_file)
    instance_eval(Erubi::Engine.new(File.read(template_file), escape: true).src, template_file)
  end

  def write(template_file)
    File.write(@file, render(template_file))
  end
end

class Post
  include FileUtils
  attr_reader :url, :html, :filename, :title, :date, :text_descr

  def initialize(md_file)
    @md_file = md_file
    @filename = File.basename(@md_file, ".md")
    @url = "#{POSTS_DIR}/#{@filename}.html"
    @date = DateTime.parse(@filename.split("_")[0])
    @html_file = "#{POSTS_HTML_DIR}/#{@filename}.html"

    if File.exist?(@html_file)
      html = Nokogiri::HTML.fragment(File.read(@html_file))
      @title = html.at("h1").text
      html.at("h1").remove
      html.css("img").each do |img|
        img["loading"] = "lazy"
        img["decoding"] = "async"
      end
      @html = html.to_s
      @text_descr = truncate_text(@html)
    end
  end

  # props to https://github.com/ordepdev/ordepdev.github.io/blob/1bee021898a6c2dd06a803c5d739bd753dbe700a/scripts/generate-social-images.js#L26
  def gen_img!
    title_mask = Vips::Image.text("<b>#{CGI.escapeHTML(title)}</b>", font: "Menlo 60", width: 1100, dpi: 72)
    descr_mask = Vips::Image.text(CGI.escapeHTML(text_descr), font: "Menlo 40", width: 1100, dpi: 72)
    footer_mask = Vips::Image.text("pineman #{date.strftime("%Y-%m-%d")}", font: "Menlo 30", dpi: 72)
    Vips::Image.black(1200, 630)
      .insert(title_mask, 50, 50)
      .insert(descr_mask, 50, 50 + title_mask.height + 40)
      .insert(footer_mask, 1200 - 50 - footer_mask.width, 630 - 50 - footer_mask.height)
      .ifthenelse([0xda, 0xda, 0xdb], [0x1d, 0x1e, 0x20], blend: true)
      .write_to_file("#{LINK_PREVIEWS_DIR}/#{@filename}.png", palette: true, Q: 80, strip: true)
  end

  # Feed readers resolve relative URLs against the feed, not the post, so make
  # them absolute. In-page #fragment links are left as they are.
  def feed_html
    doc = Nokogiri::HTML.fragment(html)
    doc.css("[src], [href]").each do |el|
      attr = el.key?("src") ? "src" : "href"
      next if el[attr].start_with?("#") || el[attr].match?(/\A[a-z][a-z0-9+.-]*:/i)
      el[attr] = URI.join("#{SITE_ROOT}/#{url}", el[attr]).to_s
    end
    doc.to_s
  end

  def build_intermediate_html!
    sh("pandoc #{@md_file} -f gfm -t gfm -o #{@md_file}") if !ENV["NOFORMAT"]
    Pandoc.md_to_html(@md_file, @html_file)
  end

  private

  def truncate_text(html)
    text = Nokogiri::HTML.fragment(html).text
    words = text.split(/\s+/)
    truncated = ""
    words.each do |word|
      test_string = truncated.empty? ? word : "#{truncated} #{word}"
      break if test_string.length > 160
      truncated = test_string
    end
    suffix = truncated.end_with?(".") ? " ..." : "..." if truncated.length < text.length
    "#{truncated}#{suffix}"
  end
end

class Note
  attr_reader :url, :html, :name, :filename, :title, :date, :text_descr

  def initialize(md_file)
    @md_file = md_file
    @name = File.basename(md_file, ".md")
    @url = "#{NOTES_DIR}/#{@name}.html"
    @html_file = "#{NOTES_HTML_DIR}/#{@name}.html"

    if File.exist?(@html_file)
      @html = File.read(@html_file)
    end
  end

  def build_intermediate_html!
    Pandoc.md_to_html(@md_file, @html_file)
  end
end

module Links
  extend self

  def process!
    lines = File.readlines(LINKS_MD)
    cache = BUILD_LINKS_MD
    processed_lines = File.exist?(cache) ? File.readlines(cache).to_set : Set.new

    modified_lines = lines.map do |line|
      original_line = line
      line = line.gsub("?utm_source=substack&utm_medium=email", "")
      line = "* #{line}" if line.start_with?("http") && !line.start_with?("* ")

      # docs/links.md is the source from the previous successful build. An
      # unchanged line was already processed, including HN self-posts whose
      # enriched form cannot be distinguished from a line with a personal note.
      unless processed_lines.include?(original_line) || processed_lines.include?(line)
        line = enrich_hacker_news(line)

        if line =~ %r{^\* (https?://(?:youtu\.be/\S+|(?:www\.|m\.)?youtube\.com/watch\?\S*\bv=\S+))\s*$}
          youtube_url = $1
          if title = fetch_title(youtube_url, /\s+-\s+YouTube\z/)
            line = "* #{youtube_url} - #{title}\n"
          end
        end

        if line =~ %r{^\* (https?://antirez\.com/news/\d+)\s*$}
          antirez_url = $1
          if title = fetch_title(antirez_url, /\s+-\s+<antirez>\z/)
            line = "* #{antirez_url} - #{title}\n"
          end
        end
      end

      line
    end

    links_md = modified_lines.join

    File.write(LINKS_MD, links_md) if modified_lines != lines

    links_md.split(/^(?=# )/).map do |section|
      heading, *items = section.lines.map(&:strip).reject(&:empty?)
      [heading.delete_prefix("# "), items.map { |item| item.delete_prefix("* ") }]
    end
  end

  private

  def enrich_hacker_news(line)
    match = line.match(/^\* (https:\/\/news\.ycombinator\.com\/item\?id=(\d+))(?:\s+-\s+(.+?))?\s*$/)
    return line unless match

    hn_url, hn_id, notes = match.captures
    data = JSON.parse(http_get("https://hacker-news.firebaseio.com/v0/item/#{hn_id}.json"))
    return line unless data && data["title"]

    title = data["title"]
    # A Hacker News item without a backing URL (for example, Ask HN) must not
    # get its title added again on each build.
    return line if notes == title || notes&.start_with?("#{title} - ")

    backing_link = data["url"] ? " (#{data["url"]})" : ""
    notes_suffix = notes ? " - #{notes}" : ""
    "* #{hn_url}#{backing_link} - #{title}#{notes_suffix}\n"
  end

  def fetch_title(url, suffix)
    html = http_get(url, headers: { "User-Agent" => "Mozilla/5.0" })
    title = html[/<title[^>]*>(.*?)<\/title>/im, 1]
    title = CGI.unescapeHTML(title.to_s).gsub(/\s+/, " ").strip.sub(suffix, "")
    title unless title.empty?
  end

  def http_get(url, headers: {})
    header_args = headers.flat_map { |name, value| ["-H", "#{name}: #{value}"] }
    body = IO.popen(["curl", "-sSL", "--max-redirs", "5", "--max-time", "15", "--retry", "3", *header_args, url], &:read)
    raise "curl failed for #{url}" unless $?.success?
    body
  end
end

module Pandoc
  extend self
  include FileUtils

  def md_to_html(md_file, html_file)
    sh("pandoc --wrap=none --syntax-highlighting=none #{md_file} -f gfm -t html5 -o #{html_file}")
  end

  def html_to_md(html, md_file)
    IO.popen(["pandoc", "--wrap=none", "-f", "html", "-t", "gfm-raw_html", "-o", md_file], "w") do |io|
      io.write(html)
    end
    raise "pandoc failed for #{md_file}" unless $?.success?
  end
end
