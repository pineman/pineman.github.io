#!/usr/bin/env ruby
require "erb"
require "pathname"
require "nokogiri"
require "shellwords"

class Post
  attr_reader :url, :content, :title, :time
  TITLE_REGEX = /<h1.*?>(.*?)<\/h1>/m
  TIME_REGEX = /<h6.*?>(.*?)<\/h6>/m
  def initialize(file)
    @url = File.basename(file)
    @content = highlight(File.read(file))
    @title = @content[TITLE_REGEX, 1].strip
    @time = @content[TIME_REGEX, 1].strip
  end
  private
  def highlight(html)
    h = Nokogiri::HTML(html)
    h.css('pre code').each { |code|
      code['class'] = 'hljs'
      lang = code.parent['class']
      # Text streams are a universal interface
      # Curiously those are not even the original words in the Holy Scripture
      # https://en.wikipedia.org/wiki/Unix_philosophy#Origin
      code.inner_html = `echo #{code.text.shellescape} | node highlight.js #{lang}`
    }
    h.to_s
  end
end

def template(template_file, caller_binding)
  template = ERB.new(File.read(template_file), trim_mode: ">")
  template.result(caller_binding)
end

def build_index(posts)
  html = template("index.html.erb", binding)
  File.write("../index.html", html)
end

def build_posts
  Dir["posts/*.md"].each do |md|
    `pandoc #{md} -f gfm -t gfm -o #{md}`
    `pandoc --no-highlight #{md} -f gfm -t html5 -o #{Pathname.new(md).sub_ext(".html")}`
  end
  Dir["posts/*.html"].map do |html|
    post = Post.new(html)
    html = template("post.html.erb", binding)
    File.write("../#{post.url}", html)
    File.delete(html)
    post
  end
end

def build_what_i_read
  file = File.new("posts/what-i-read.txt")
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
  build_index(posts)
  build_what_i_read
  took = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
  puts "success, took #{(took * 1000).round(3)}ms"
end
