#!/usr/bin/env ruby

require "rss"
require "erubi"

require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "nokogiri", "1.16.2"
end

CHROME_BINARY = '"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"'

module Helpers
  def self.years_ago(date)
    date = Date.parse(date)
    today = Date.today
    y = today.year - date.year
    y -= 1 if today.month < date.month || today.month == date.month && today.day < date.day
    y
  end
end

def write_html(html_file, template_file, caller_binding)
  template = Erubi::Engine.new(File.read(template_file), escape: true)
  html = eval(template.src, caller_binding)
  File.write(html_file, html)
end

class Post
  attr_reader :filename, :url, :title, :html, :date, :text_descr

  def initialize(md_file)
    @md_file = md_file
    @filename = File.basename(@md_file, ".md")
    @url = "#{@filename}.html"
    @date = DateTime.parse(@filename.split("_")[0])
    @html_file = "posts/html/#{@filename}.html"

    if File.exist?(@html_file)
      html = Nokogiri::HTML.fragment(File.read(@html_file))
      @title = html.at("h1").text
      html.at("h1").remove
      @html = html.to_s
      @text_descr = truncate_text
    end
  end

  def build_intermediate_html!
    `pandoc #{@md_file} -f gfm -t gfm -o #{@md_file}` if !ENV["NOFORMAT"]
    `pandoc --wrap=none --syntax-highlighting=none #{@md_file} -f gfm -t html5 -o #{@html_file}`
  end

  private

  def truncate_text
    text = Nokogiri::HTML.fragment(@html).text
    words = text.split(/\s+/)
    truncated = ""
    words.each do |word|
      test_string = truncated.empty? ? word : "#{truncated} #{word}"
      break if test_string.length > 160
      truncated = test_string
    end
    suffix = truncated.end_with?('.') ? ' ...' : '...' if truncated.length < text.length
    "#{truncated}#{suffix}"
  end
end

def build_rss(posts)
  posts = posts.sort_by(&:date)
  rss = RSS::Maker.make("atom") do |maker|
    maker.channel.links.new_link do |link|
      link.href = "https://pineman.github.io/atom.xml"
      link.rel = "self"
    end
    maker.channel.author = "pineman"
    maker.channel.title = "pineman"
    maker.channel.about = "https://pineman.github.io/"
    maker.channel.updated = posts.last.date.iso8601
    maker.image.url = "https://pineman.github.io/assets/me.webp"
    posts.each do |post|
      maker.items.new_item do |item|
        item.title = post.title
        item.link = "https://pineman.github.io/#{post.url}"
        item.published = post.date.iso8601
        item.updated = post.date.iso8601
        item.description = post.html
      end
    end
  end
  rss.to_s.gsub!("<summary>", '<summary type="html">')
end

# props to https://github.com/ordepdev/ordepdev.github.io/blob/1bee021898a6c2dd06a803c5d739bd753dbe700a/scripts/generate-social-images.js#L26
def gen_img(post)
  width = 1200
  height = 630
  template = Erubi::Engine.new(File.read('partials/link-preview.svg.erb'), escape: true)
  svg = eval(template.src, binding)
  t = post.filename
  File.write("#{t}.svg", svg)
  <<~`SCRIPT`
    #{CHROME_BINARY} --headless --screenshot="screenshot-#{t}.png" --window-size=#{width},#{height+400} "file://$(pwd)/#{t}.svg" &>/dev/null
    docker run --rm -v $(pwd):/imgs dpokidov/imagemagick:7.1.1-8-bullseye screenshot-#{t}.png -quality 80 -crop x630+0+0 #{t}.png
    rm -f #{t}.svg screenshot-#{t}.png
    mkdir -p assets/link_previews
    mv #{t}.png assets/link_previews/
  SCRIPT
end

require "rake/clean"

# Monkey patches to add "Building ..." log lines
module Rake
  module DSL
    alias_method :original_file, :file
    alias_method :original_rule, :rule

    def file(*args, &block)
      if block_given?
        original_file(*args) do |t|
          puts "Building #{t.name}"
          block.call(t)
        end
      else
        original_file(*args)
      end
    end

    def rule(*args, &block)
      if block_given?
        original_rule(*args) do |t|
          puts "Building #{t.name}"
          block.call(t)
        end
      else
        original_rule(*args)
      end
    end
  end
end

POSTS_MD = FileList['posts/2*.md']
POSTS_HTML = POSTS_MD.pathmap('%n.html')
LINK_PREVIEWS = POSTS_MD.pathmap('assets/link_previews/%n.png')
INTERMEDIATE_HTML = POSTS_MD.pathmap('posts/html/%n.html')

TEMPLATES = FileList['index.html.erb', 'post.html.erb', 'what-i-read.html.erb']
PARTIALS = FileList['partials/head.html', 'partials/article-head.html', 'partials/pinecone.html', 'partials/link-preview.svg.erb']

CLEAN.include(POSTS_HTML, LINK_PREVIEWS, INTERMEDIATE_HTML, 'index.html', 'what-i-read.html', 'atom.xml', '*.svg', 'screenshot-*.png')

multitask :default => [:all]
multitask :all => [*POSTS_HTML, 'index.html', 'what-i-read.html', 'atom.xml', *LINK_PREVIEWS]

file 'index.html' => ['index.html.erb', *POSTS_HTML, *PARTIALS] do |t|
  posts = POSTS_MD.map { |md| Post.new(md) }
  write_html(t.name, 'index.html.erb', binding)
end

file 'what-i-read.html' => ['what-i-read.html.erb', 'posts/what-i-read.md', *PARTIALS] do |t|
  write_html(t.name, 'what-i-read.html.erb', binding)
end

file 'atom.xml' => [*POSTS_HTML] do |t|
  posts = POSTS_MD.map { |md| Post.new(md) }
  File.write(t.name, build_rss(posts))
end

rule %r{^posts/html/.*\.html$} => ->(f){ f.pathmap('posts/%n.md') } do |t|
  Post.new(t.source).build_intermediate_html!
end

POSTS_HTML.each do |post_html|
  file post_html => ["posts/html/#{post_html}", "post.html.erb", *PARTIALS] do |t|
    md_file = "posts/#{File.basename(t.name, '.html')}.md"
    post = Post.new(md_file)
    write_html(t.name, "post.html.erb", binding)
  end
end

rule %r{^assets/link_previews/.*\.png$} => [->(f) { "posts/html/#{File.basename(f, '.png')}.html" }, 'partials/link-preview.svg.erb'] do |t|
  md_file = "posts/#{File.basename(t.source, '.html')}.md"
  post = Post.new(md_file)
  gen_img(post)
end
