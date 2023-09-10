#!/usr/bin/env ruby

require "rss"
require "fileutils"
require "erb"

require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "nokogiri", "1.14.3"
end

def template(template_file, caller_binding)
  template = ERB.new(File.read(template_file), trim_mode: ">")
  template.result(caller_binding)
end

class Post
  attr_reader :url, :content, :title, :date, :description
  def initialize(file)
    @date, @url = File.basename(file).split('_')
    h = Nokogiri::HTML.fragment(File.read(file))
    h1 = h.at('h1')
    @title = h1.text
    h1.after("<time datetime=\"#{@date}\">#{@date}</time>")
    @content = h.to_s
    #descr = h.search('./p[1] | ./p[1]/following-sibling::node()[count(preceding-sibling::p) = 1]').to_s
    descr = @content[/<p>.*?<\/p>.*?<p>.*?<\/p>/m]
    @description = descr + '<p>...</p>'
  end
end

def build_posts
  FileUtils.rm_rf('../posts/html')
  FileUtils.mkdir('../posts/html')
  Dir["../posts/*.md"].each do |md|
    # Using pandoc 3.1.2
    `pandoc #{md} -f gfm -t gfm -o #{md}`
    html = "../posts/html/#{File.basename(md, '.*')}.html"
    `pandoc --no-highlight #{md} -f gfm -t html5 -o #{html}`
  end
  Dir["../posts/html/*.html"].map do |html_file|
    post = Post.new(html_file)
    html = template("post.html.erb", binding)
    File.write("../#{post.url}", html)
    post
  end.sort_by!(&:date)
end

def build_index(posts)
  content = ''
  posts.reverse.each do |post|
    content += "<li><time datetime=\"#{post.date}\">#{post.date}</time> <a href=\"#{post.url}\">#{post.title}</a></li>\n"
  end
  html = template("index.html.erb", binding)
  File.write("../index.html", html)
end

def build_what_i_read
  file = File.new("../posts/what-i-read.txt")
  time = file.mtime
  content = ""
  file.readlines.each do |l|
    l.strip!
    case l
    when /^# /
      content += "</ul>\n<h4>#{l[2..]}</h4>\n<ul>\n"
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
  content.sub!("</ul>\n", "")
  html = template("what-i-read.html.erb", binding)
  File.write("../what-i-read.html", html)
end

def build_rss(posts)
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

posts = build_posts
build_index(posts)
build_rss(posts)
build_what_i_read
