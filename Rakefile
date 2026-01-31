#!/usr/bin/env ruby

require "rss"
require "erubi"

require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "nokogiri", "1.16.2"
end

require "rake/clean"

Rake::FileUtilsExt.verbose(false)

CHROME_BINARY = '"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"'
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
LINK_PREVIEWS_DIR = "#{BUILD_DIR}/assets/link_previews"

BUILD_POSTS_DIR = "#{BUILD_DIR}/posts"
BUILD_NOTES_DIR = "#{BUILD_DIR}/notes"

TEMPLATES_DIR = "templates"
TEMPLATE_INDEX = "#{TEMPLATES_DIR}/index.html.erb"
TEMPLATE_POST = "#{TEMPLATES_DIR}/post.html.erb"
TEMPLATE_LINKS = "#{TEMPLATES_DIR}/links.html.erb"
TEMPLATE_NOTES = "#{TEMPLATES_DIR}/notes.html.erb"
TEMPLATE_NOTE = "#{TEMPLATES_DIR}/note.html.erb"
TEMPLATE_HEAD = "#{TEMPLATES_DIR}/head.html.erb"
TEMPLATE_ARTICLE_HEAD = "#{TEMPLATES_DIR}/article-head.html.erb"
TEMPLATE_PINECONE = "#{TEMPLATES_DIR}/pinecone.html"
TEMPLATE_LINK_PREVIEW = "#{TEMPLATES_DIR}/link-preview.svg.erb"

POSTS_MD = FileList["#{POSTS_DIR}/2*.md"]
POSTS_HTML = POSTS_MD.pathmap("#{BUILD_POSTS_DIR}/%n.html")
POSTS_INTERMEDIATE_HTML = POSTS_MD.pathmap("#{POSTS_HTML_DIR}/%n.html")
LINK_PREVIEWS = POSTS_MD.pathmap("#{LINK_PREVIEWS_DIR}/%n.png")

NOTES_MD = FileList["#{NOTES_DIR}/*.md"].exclude(LINKS_MD)
NOTE_HTML = NOTES_MD.pathmap("#{BUILD_NOTES_DIR}/%n.html")
NOTES_INTERMEDIATE_HTML = NOTES_MD.pathmap("#{NOTES_HTML_DIR}/%n.html")

LEGACY_REDIRECTS = %w[
  2022-12-03_aoc3
  2023-05-07_ruby-bug-shell-gem
  2023-11-05_ruby-ascii-8bit
  2024-05-25_just-use-curl
  2025-02-01_k8s-dns
]
TEMPLATE_REDIRECT = "#{TEMPLATES_DIR}/redirect.html.erb"

CLEAN.include(BUILD_DIR, TMP_DIR)

multitask default: [:all]
multitask all: [INDEX_HTML, INDEX_MD, LINKS_HTML, NOTES_HTML, NOTES_INDEX_MD, *NOTE_HTML, *POSTS_HTML, *LINK_PREVIEWS, ATOM_XML, :copy_assets, :generate_redirects, :copy_markdown_sources]

directory BUILD_DIR
directory BUILD_POSTS_DIR
directory BUILD_NOTES_DIR
directory POSTS_HTML_DIR
directory NOTES_HTML_DIR

file INDEX_HTML => [BUILD_DIR, TEMPLATE_INDEX, *POSTS_HTML, TEMPLATE_HEAD, TEMPLATE_PINECONE] do |t|
  posts = POSTS_MD.map { |md| Post.new(md) }
  write_html(t.name, TEMPLATE_INDEX, binding)
end

file INDEX_MD => [BUILD_DIR, INDEX_HTML] do |t|
  index_to_md(INDEX_HTML, t.name)
end

file NOTES_INDEX_MD => [BUILD_DIR, NOTES_HTML] do |t|
  notes_to_md(NOTES_HTML, t.name)
end

file LINKS_HTML => [BUILD_DIR, TEMPLATE_LINKS, LINKS_MD, TEMPLATE_HEAD, TEMPLATE_ARTICLE_HEAD] do |t|
  lines = File.readlines(LINKS_MD)
  modified_lines = lines.map do |line|
    line.start_with?("http") && !line.start_with?("* ") ? "* #{line}" : line
  end
  File.write(LINKS_MD, modified_lines.join) if modified_lines != lines

  write_html(t.name, TEMPLATE_LINKS, binding)
end

file NOTES_HTML => [BUILD_DIR, TEMPLATE_NOTES, *NOTE_HTML, TEMPLATE_HEAD, TEMPLATE_ARTICLE_HEAD] do |t|
  notes = NOTES_MD.map { |md| Note.new(md) }
  write_html(t.name, TEMPLATE_NOTES, binding)
end

rule %r{^#{NOTES_HTML_DIR}/.*\.html$} => [->(f) { f.pathmap("#{NOTES_DIR}/%n.md") }, NOTES_HTML_DIR] do |t|
  Note.new(t.prerequisites.first).build_intermediate_html!
end

NOTE_HTML.each do |note_html|
  file note_html => [BUILD_NOTES_DIR, note_html.pathmap("#{NOTES_HTML_DIR}/%f"), TEMPLATE_NOTE, TEMPLATE_HEAD, TEMPLATE_ARTICLE_HEAD] do |t|
    note = Note.new(t.name.pathmap("#{NOTES_DIR}/%n.md"))
    write_html(t.name, TEMPLATE_NOTE, binding)
  end
end

rule %r{^#{POSTS_HTML_DIR}/.*\.html$} => [->(f) { f.pathmap("#{POSTS_DIR}/%n.md") }, POSTS_HTML_DIR] do |t|
  Post.new(t.prerequisites.first).build_intermediate_html!
end

POSTS_HTML.each do |post_html|
  file post_html => [BUILD_POSTS_DIR, post_html.pathmap("#{POSTS_HTML_DIR}/%f"), TEMPLATE_POST, TEMPLATE_HEAD, TEMPLATE_ARTICLE_HEAD] do |t|
    post = Post.new(t.name.pathmap("#{POSTS_DIR}/%n.md"))
    write_html(t.name, TEMPLATE_POST, binding)
  end
end

rule %r{^#{LINK_PREVIEWS_DIR}/.*\.png$} => [->(f) { f.pathmap("#{POSTS_HTML_DIR}/%n.html") }, TEMPLATE_LINK_PREVIEW] do |t|
  Post.new(t.source.pathmap("#{POSTS_DIR}/%n.md")).gen_img!
end

file ATOM_XML => [BUILD_DIR, *POSTS_HTML] do |t|
  posts = POSTS_MD.map { |md| Post.new(md) }
  File.write(t.name, Post.build_rss(posts))
end

task copy_assets: [BUILD_DIR, BUILD_POSTS_DIR] do
  cp_r "assets/.", "#{BUILD_DIR}/assets/", preserve: true
  cp "templates/style.css", "#{BUILD_DIR}/style.css"
  cp "assets/favicon.ico", "#{BUILD_DIR}/favicon.ico"
  cp_r "youwashock", "#{BUILD_DIR}/youwashock"
  cp_r "posts/assets", "#{BUILD_POSTS_DIR}/assets"
end

task generate_redirects: [BUILD_DIR] do
  LEGACY_REDIRECTS.each do |filename|
    html = render_erb(TEMPLATE_REDIRECT, binding)
    File.write("#{BUILD_DIR}/#{filename}.html", html)
  end
end

task copy_markdown_sources: [BUILD_POSTS_DIR, BUILD_NOTES_DIR] do
  POSTS_MD.each { |f| cp f, "#{BUILD_POSTS_DIR}/#{File.basename(f)}" }
  NOTES_MD.each { |f| cp f, "#{BUILD_NOTES_DIR}/#{File.basename(f)}" }
  cp LINKS_MD, "#{BUILD_DIR}/links.md"
end

module Helpers
  def self.years_ago(date)
    date = Date.parse(date)
    today = Date.today
    y = today.year - date.year
    y -= 1 if today.month < date.month || today.month == date.month && today.day < date.day
    y
  end
end

def site_link(path)
  "#{@root}#{path}"
end

def render_erb(template_file, caller_binding)
  bufvar = "@_buf_#{Random.rand(1_000_000)}"
  template = Erubi::Engine.new(File.read(template_file), escape: true, bufvar: bufvar)
  eval(template.src, caller_binding)
end

def write_html(html_file, template_file, caller_binding)
  html = render_erb(template_file, caller_binding)
  File.write(html_file, html)
end

def html_to_md(html, md_filename)
  IO.popen(["pandoc", "--wrap=none", "-f", "html", "-t", "gfm-raw_html", "-o", md_filename], "w") do |io|
    io.write(html)
  end
end

def index_to_md(index_html_filename, index_md_filename)
  html = File.read(index_html_filename).gsub(/<div class="icon-container".*?>.*?<\/div>/m, "")
  html = html.gsub(/href="#{POSTS_DIR}\/(\d{4}-\d{2}-\d{2}_.*?)\.html"/, "href=\"#{POSTS_DIR}/\\1.md\"")
  html = html.gsub("href=\"links.html\"", "href=\"#{LINKS_MD}\"")
  html_to_md(html, index_md_filename)
end

def notes_to_md(html_filename, md_filename)
  html = File.read(html_filename)
  html = html.gsub(/href="#{NOTES_DIR}\/(.+?)\.html"/, "href=\"#{NOTES_DIR}/\\1.md\"")
  html = html.gsub(/<a href="[^"]*">&lt; back<\/a>/, "")
  html_to_md(html, md_filename)
end

def md_to_html(md_file, html_file)
  sh("pandoc --wrap=none --syntax-highlighting=none #{md_file} -f gfm -t html5 -o #{html_file}", verbose: false)
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
      @html = html.to_s
      @text_descr = truncate_text(@html)
    end
  end

  # props to https://github.com/ordepdev/ordepdev.github.io/blob/1bee021898a6c2dd06a803c5d739bd753dbe700a/scripts/generate-social-images.js#L26
  def gen_img!
    width = 1200
    height = 630
    post = self
    svg = render_erb(TEMPLATE_LINK_PREVIEW, binding)
    t = @filename
    mkdir_p TMP_DIR
    File.write("#{TMP_DIR}/#{t}.svg", svg)
    sh(<<~SCRIPT, verbose: false)
      #{CHROME_BINARY} --headless --screenshot="#{TMP_DIR}/screenshot-#{t}.png" --window-size=#{width},#{height + 400} "file://$(pwd)/#{TMP_DIR}/#{t}.svg" &>/dev/null
      docker run --rm -v $(pwd):/imgs dpokidov/imagemagick:7.1.1-8-bullseye #{TMP_DIR}/screenshot-#{t}.png -quality 80 -crop x630+0+0 -strip #{TMP_DIR}/#{t}.png
      rm -f #{TMP_DIR}/#{t}.svg #{TMP_DIR}/screenshot-#{t}.png
      mkdir -p #{LINK_PREVIEWS_DIR}
      mv #{TMP_DIR}/#{t}.png #{LINK_PREVIEWS_DIR}/
    SCRIPT
  end

  def self.build_rss(posts)
    posts = posts.sort_by(&:date)
    rss = RSS::Maker.make("atom") do |maker|
      maker.channel.links.new_link do |link|
        link.href = "#{SITE_ROOT}/atom.xml"
        link.rel = "self"
      end
      maker.channel.author = "pineman"
      maker.channel.title = "pineman"
      maker.channel.about = "#{SITE_ROOT}/"
      maker.channel.updated = posts.last.date.iso8601
      maker.image.url = "#{SITE_ROOT}/assets/me.webp"
      posts.each do |post|
        maker.items.new_item do |item|
          item.title = post.title
          item.link = "#{SITE_ROOT}/#{post.url}"
          item.published = post.date.iso8601
          item.updated = post.date.iso8601
          item.description = post.html
        end
      end
    end
    rss.to_s.gsub!("<summary>", '<summary type="html">')
  end

  def build_intermediate_html!
    sh("pandoc #{@md_file} -f gfm -t gfm -o #{@md_file}", verbose: false) if !ENV["NOFORMAT"]
    md_to_html(@md_file, @html_file)
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
  include FileUtils
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
    md_to_html(@md_file, @html_file)
  end
end

