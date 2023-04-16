#!/usr/bin/env ruby
start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

require "erb"
require "pathname"

def format_convert_markdown
  Dir["posts/*.md"].each do |file|
    `pandoc #{file} -f gfm -t gfm -o #{file}`
    `pandoc --no-highlight #{file} -f gfm -t html5 -o #{Pathname.new(file).sub_ext(".html")}`
  end
end

class Post
  attr_accessor :url, :content, :title, :time
  TITLE_REGEX = /<h1.*?>(.*?)<\/h1>/m
  TIME_REGEX = /<h6.*?>(.*?)<\/h6>/m
  def initialize file
    @url = File.basename(file)
    @content = File.read(file)
    @title = @content[TITLE_REGEX, 1].strip
    @time = @content[TIME_REGEX, 1].strip
  end
end

def build_index
  template = ERB.new(File.read("index.html.erb"), trim_mode: ">")
  posts = ""
  Dir["posts/*.html"].each do |file|
    post = Post.new(file)
    posts += "<li>#{post.time} - <a href=\"#{post.url}\">#{post.title}</a></li>\n"
  end
  File.write("../index.html", template.result(binding))
end

def build_posts
  template = ERB.new(File.read("post.html.erb"), trim_mode: ">")
  Dir["posts/*.html"].each do |file|
    post = Post.new(file)
    File.write("../#{post.url}", template.result(binding))
    File.delete(file)
  end
end

def build_what_i_read
  template = ERB.new(File.read("what-i-read.html.erb"), trim_mode: ">")
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
  File.write("../what-i-read.html", template.result(binding))
end

format_convert_markdown
build_index
build_posts
build_what_i_read
took = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
puts "success, took #{(took * 1000).round(3)}ms"
