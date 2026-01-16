#!/usr/bin/env ruby

require "rss"
require "erubi"

require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "nokogiri", "1.16.2"
end

require "rake/clean"

CHROME_BINARY = '"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"'
SITE_ROOT = "https://pineman.github.io"

INDEX_HTML = "index.html"
INDEX_MD = "index.md"
LINKS_HTML = "links.html"
POSTS_DIR = "posts"
POSTS_HTML_DIR = "#{POSTS_DIR}/html"
LINKS_MD = "#{POSTS_DIR}/links.md"
ATOM_XML = "atom.xml"
LINK_PREVIEWS_DIR = "assets/link_previews"

TEMPLATES_DIR = "templates"
TEMPLATE_INDEX = "#{TEMPLATES_DIR}/index.html.erb"
TEMPLATE_POST = "#{TEMPLATES_DIR}/post.html.erb"
TEMPLATE_LINKS = "#{TEMPLATES_DIR}/links.html.erb"
TEMPLATE_HEAD = "#{TEMPLATES_DIR}/head.html"
TEMPLATE_ARTICLE_HEAD = "#{TEMPLATES_DIR}/article-head.html.erb"
TEMPLATE_PINECONE = "#{TEMPLATES_DIR}/pinecone.html"
TEMPLATE_LINK_PREVIEW = "#{TEMPLATES_DIR}/link-preview.svg.erb"

POSTS_MD = FileList["#{POSTS_DIR}/2*.md"]
POSTS_HTML = POSTS_MD.pathmap("%n.html")
POSTS_INTERMEDIATE_HTML = POSTS_MD.pathmap("#{POSTS_HTML_DIR}/%n.html")
LINK_PREVIEWS = POSTS_MD.pathmap("#{LINK_PREVIEWS_DIR}/%n.png")

CLEAN.include(INDEX_HTML, INDEX_MD, LINKS_HTML, POSTS_HTML, POSTS_INTERMEDIATE_HTML, LINK_PREVIEWS, ATOM_XML)

multitask default: [:all]
multitask all: [INDEX_HTML, INDEX_MD, LINKS_HTML, *POSTS_HTML, *LINK_PREVIEWS, ATOM_XML]

file INDEX_HTML => [TEMPLATE_INDEX, *POSTS_HTML, TEMPLATE_HEAD, TEMPLATE_PINECONE] do |t|
  posts = POSTS_MD.map { |md| Post.new(md) }
  write_html(t.name, TEMPLATE_INDEX, binding)
end

file INDEX_MD => INDEX_HTML do |t|
  index_to_md(t.source, t.name)
end

file LINKS_HTML => [TEMPLATE_LINKS, LINKS_MD, TEMPLATE_HEAD, TEMPLATE_ARTICLE_HEAD] do |t|
  lines = File.readlines(LINKS_MD)
  modified_lines = lines.map do |line|
    line.start_with?("http") && !line.start_with?("* ") ? "* #{line}" : line
  end
  File.write(LINKS_MD, modified_lines.join)

  write_html(t.name, TEMPLATE_LINKS, binding)
end

rule %r{^#{POSTS_HTML_DIR}/.*\.html$} => ->(f) { f.pathmap("#{POSTS_DIR}/%n.md") } do |t|
  Post.new(t.source).build_intermediate_html!
end

POSTS_HTML.each do |post_html|
  file post_html => ["#{POSTS_HTML_DIR}/#{post_html}", TEMPLATE_POST, TEMPLATE_HEAD, TEMPLATE_ARTICLE_HEAD] do |t|
    post = Post.new("#{POSTS_DIR}/#{File.basename(t.name, ".html")}.md")
    write_html(t.name, TEMPLATE_POST, binding)
  end
end

rule %r{^#{LINK_PREVIEWS_DIR}/.*\.png$} => [->(f) { "#{POSTS_HTML_DIR}/#{File.basename(f, ".png")}.html" }, TEMPLATE_LINK_PREVIEW] do |t|
  Post.new("#{POSTS_DIR}/#{File.basename(t.source, ".html")}.md").gen_img!
end

file ATOM_XML => [*POSTS_HTML] do |t|
  posts = POSTS_MD.map { |md| Post.new(md) }
  File.write(t.name, Post.build_rss(posts))
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

def render_erb(template_file, caller_binding)
  bufvar = "@_buf_#{Random.rand(1_000_000)}"
  template = Erubi::Engine.new(File.read(template_file), escape: true, bufvar: bufvar)
  eval(template.src, caller_binding)
end

def write_html(html_file, template_file, caller_binding)
  html = render_erb(template_file, caller_binding)
  File.write(html_file, html)
end

def index_to_md(index_html_filename, index_md_filename)
  html = File.read(index_html_filename).gsub(/<div class="icon-container".*?>.*?<\/div>/m, "")
  html = html.gsub(/href="(\d{4}-\d{2}-\d{2}_.*?)\.html"/, "href=\"#{POSTS_DIR}/\\1.md\"")
  html = html.gsub("href=\"#{LINKS_HTML}\"", "href=\"#{LINKS_MD}\"")
  tmp_file = "#{index_md_filename}.tmp.html"
  File.write(tmp_file, html)
  begin
    sh("pandoc --wrap=none -f html -t gfm-raw_html -o #{index_md_filename} #{tmp_file}", verbose: false)
  ensure
    rm(tmp_file, verbose: false)
  end
end

class Post
  include FileUtils

  attr_reader :filename, :url, :title, :html, :date, :text_descr

  def initialize(md_file)
    @md_file = md_file
    @filename = File.basename(@md_file, ".md")
    @url = "#{@filename}.html"
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

  def build_intermediate_html!
    sh("pandoc #{@md_file} -f gfm -t gfm -o #{@md_file}", verbose: false) if !ENV["NOFORMAT"]
    sh("pandoc --wrap=none --syntax-highlighting=none #{@md_file} -f gfm -t html5 -o #{@html_file}", verbose: false)
  end

  # props to https://github.com/ordepdev/ordepdev.github.io/blob/1bee021898a6c2dd06a803c5d739bd753dbe700a/scripts/generate-social-images.js#L26
  def gen_img!
    width = 1200
    height = 630
    post = self
    svg = render_erb(TEMPLATE_LINK_PREVIEW, binding)
    t = @filename
    File.write("#{t}.svg", svg)
    sh(<<~SCRIPT, verbose: false)
      #{CHROME_BINARY} --headless --screenshot="screenshot-#{t}.png" --window-size=#{width},#{height + 400} "file://$(pwd)/#{t}.svg" &>/dev/null
      docker run --rm -v $(pwd):/imgs dpokidov/imagemagick:7.1.1-8-bullseye screenshot-#{t}.png -quality 80 -crop x630+0+0 -strip #{t}.png
      rm -f #{t}.svg screenshot-#{t}.png
      mkdir -p #{LINK_PREVIEWS_DIR}
      mv #{t}.png #{LINK_PREVIEWS_DIR}/
    SCRIPT
  end

  def self.build_rss(posts)
    posts = posts.sort_by(&:date)
    rss = RSS::Maker.make("atom") do |maker|
      maker.channel.links.new_link do |link|
        link.href = "#{SITE_ROOT}/#{ATOM_XML}"
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
