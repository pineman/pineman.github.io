#!/usr/bin/env ruby

require "rss"
require "erubi"

require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "nokogiri", "1.16.2"
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
  html = File.read(index_html_filename).gsub(/<div class="icon-container".*?>.*?<\/div>/m, '')
  html = html.gsub(/href="(\d{4}-\d{2}-\d{2}_.*?)\.html"/, 'href="posts/\1.md"')
  html = html.gsub('href="what-i-read.html"', 'href="posts/what-i-read.md"')
  IO.popen(["pandoc", "--wrap=none", "-f", "html", "-t", "gfm-raw_html", "-o", index_md_filename], "w") { |p| p.write(html) }
end

CHROME_BINARY = '"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"'
SITE_ROOT = "https://pineman.github.io"

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
      @text_descr = truncate_text(@html)
    end
  end

  def self.build_intermediate_html(md_file)
    `pandoc #{md_file} -f gfm -t gfm -o #{md_file}` if !ENV["NOFORMAT"]
    `pandoc --wrap=none --syntax-highlighting=none #{md_file} -f gfm -t html5 -o #{html_file}`
  end

  # props to https://github.com/ordepdev/ordepdev.github.io/blob/1bee021898a6c2dd06a803c5d739bd753dbe700a/scripts/generate-social-images.js#L26
  def self.gen_img!(md_file)
    width = 1200
    height = 630
    template = Erubi::Engine.new(File.read(TEMPLATE_LINK_PREVIEW), escape: true)
    post = Post.new(md_file)
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
    suffix = truncated.end_with?('.') ? ' ...' : '...' if truncated.length < text.length
    "#{truncated}#{suffix}"
  end
end

require "rake/clean"

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

TEMPLATE_INDEX = 'templates/index.html.erb'
TEMPLATE_POST = 'templates/post.html.erb'
TEMPLATE_WHAT_I_READ = 'templates/what-i-read.html.erb'
TEMPLATE_HEAD = 'templates/head.html'
TEMPLATE_ARTICLE_HEAD = 'templates/article-head.html.erb'
TEMPLATE_PINECONE = 'templates/pinecone.html'
TEMPLATE_LINK_PREVIEW = 'templates/link-preview.svg.erb'

POSTS_MD = FileList['posts/2*.md']
POSTS_HTML = POSTS_MD.pathmap('%n.html')
LINK_PREVIEWS = POSTS_MD.pathmap('assets/link_previews/%n.png')

TEMPLATES = FileList['templates/*.erb']

CLEAN.include('index.html', 'index.md', 'what-i-read.html', POSTS_HTML, LINK_PREVIEWS, 'atom.xml')

multitask :default => [:all]
multitask :all => ['index.html', 'index.md', 'what-i-read.html', *POSTS_HTML, *LINK_PREVIEWS, 'atom.xml']

file 'index.html' => [TEMPLATE_INDEX, *POSTS_HTML, TEMPLATE_HEAD, TEMPLATE_PINECONE] do |t|
  posts = POSTS_MD.map { |md| Post.new(md) }
  write_html(t.name, TEMPLATE_INDEX, binding)
end

file 'index.md' => 'index.html' do |t|
  index_to_md(t.source, t.name)
end

file 'what-i-read.html' => [TEMPLATE_WHAT_I_READ, 'posts/what-i-read.md', TEMPLATE_HEAD, TEMPLATE_ARTICLE_HEAD] do |t|
  write_html(t.name, TEMPLATE_WHAT_I_READ, binding)
end

POSTS_HTML.each do |post_html|
  file post_html => ["posts/html/#{post_html}", TEMPLATE_POST, TEMPLATE_HEAD, TEMPLATE_ARTICLE_HEAD] do |t|
    post = Post.new("posts/#{File.basename(t.name, '.html')}.md")
    write_html(t.name, TEMPLATE_POST, binding)
  end
end

rule %r{^posts/html/.*\.html$} => ->(f){ f.pathmap('posts/%n.md') } do |t|
  Post.build_intermediate_html!(t.source)
end

rule %r{^assets/link_previews/.*\.png$} => [->(f) { "posts/html/#{File.basename(f, '.png')}.html" }, TEMPLATE_LINK_PREVIEW] do |t|
  Post.gen_img!("posts/#{File.basename(t.source, '.html')}.md")
end

file 'atom.xml' => [*POSTS_HTML] do |t|
  posts = POSTS_MD.map { |md| Post.new(md) }
  File.write(t.name, Post.build_rss(posts))
end
