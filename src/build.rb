#!/usr/bin/env ruby
require "erb"
require "nokogiri"
require "shellwords"

def template(template_file, caller_binding)
  template = ERB.new(File.read(template_file), trim_mode: ">")
  template.result(caller_binding)
end

class Post
  attr_reader :url, :content, :title, :date, :description
  TITLE_REGEX = /<h1.*?>(.*?)<\/h1>/m
  TIME_REGEX = /<h6.*?>(.*?)<\/h6>/m
  def initialize(file)
    @url = File.basename(file)
    @content = highlight(File.read(file))
    @title = @content[TITLE_REGEX, 1].strip
    @date = @content[TIME_REGEX, 1].strip
    @description = first_two_paragraphs(@content)
  end
  private
  def highlight(html)
    h = Nokogiri::HTML(html)
    h.css('pre code').each { |code|
      code['class'] = 'hljs'
      lang = code.parent['class'] || 'plaintext'
      # Text streams are a universal interface
      # Curiously those are not even the original words in the Holy Scripture
      # https://en.wikipedia.org/wiki/Unix_philosophy#Origin
      code.inner_html = `echo #{code.text.shellescape} | node highlight.js #{lang}`
    }
    h.to_s
  end
  def first_two_paragraphs(html)
    h = Nokogiri::HTML(html)
    descr = h.search('//body/p[1] | //body/p[1]/following-sibling::node()[count(preceding-sibling::p) = 1]').to_s
    descr + '<p>...</p>'
  end
end

def build_posts
  Dir["../posts/*.md"].each do |md|
    # Using pandoc 3.1.2
    `pandoc #{md} -f gfm -t gfm -o #{md}`
    `pandoc --no-highlight #{md} -f gfm -t html5 -o #{File.dirname(md)}/html/#{File.basename(md, '.*')}.html`
  end
  Dir["../posts/html/*.html"].map do |html_file|
    post = Post.new(html_file)
    html = template("post.html.erb", binding)
    File.write("../#{post.url}", html)
    post
  end
end

def build_rss(posts)
  require "rss"
  rss = RSS::Maker.make("atom") do |maker|
    maker.channel.author = "João Pinheiro"
    maker.channel.title = "João Pinheiro"
    maker.channel.about = "https://pineman.github.io"
    maker.channel.updated = posts.last.date
    posts.each do |post|
      maker.items.new_item do |item|
        item.title = post.title
        item.link = "https://pineman.github.io/#{post.url}"
        item.updated = post.date
        item.description = post.description
      end
    end
  end
  File.write("../atom.xml", rss)
end

def build_index(posts)
  posts = posts.sort_by(&:date).reverse
  content = ''
  posts.each do |post|
    content += "<li>#{post.date} - <a href=\"#{post.url}\">#{post.title}</a></li>\n"
  end
  html = template("index.html.erb", binding)
  File.write("../index.html", html)
end

def build_what_i_read
  file = File.new("../posts/what-i-read.txt")
  time = file.mtime
  content = ""
  file.readlines.each_with_index do |l, i|
    l.strip!
    case l
    when /^# /
      content += "</ul>\n" if i != 0
      content += "<h4>#{l[2..]}</h4>\n<ul>\n"
    when /^https?:\/\//
      url, descr = l.split(" ", 2)
      content += "  <li><a href=\"#{url}\">#{url}</a> #{descr}</li>\n"
    when /\/\//
      next
    else
      content += "  <li>#{l}</li>\n"
    end
  end
  content += "</ul>\n"
  html = template("what-i-read.html.erb", binding)
  File.write("../what-i-read.html", html)
end

# This allows me to `load` this file to play with its functions in irb
if $PROGRAM_NAME == __FILE__
  start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  posts = build_posts
  build_rss(posts)
  build_index(posts)
  build_what_i_read
  took = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
  puts "success, took #{(took * 1000).round(3)}ms"
end
