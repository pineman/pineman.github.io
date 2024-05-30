#!/usr/bin/env ruby

require "rss"
require "fileutils"
require "erb"

require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "nokogiri", "1.16.2"
end

def write_html(html_file, template_file, caller_binding)
  template = ERB.new(File.read(template_file), trim_mode: ">")
  html = template.result(caller_binding)
  File.write(html_file, html)
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

class Post
  attr_reader :url, :content, :title, :date, :html_descr, :text_descr
  def initialize(file)
    @date, @url = File.basename(file).split("_")
    @date = DateTime.parse(@date)
    h = Nokogiri::HTML.fragment(File.read(file))
    h1 = h.at("h1")
    @title = h1.text
    h1.after("<time datetime=\"#{@date.iso8601}\" pubdate=\"pubdate\">#{@date.strftime("%Y-%m-%d")}</time>")
    @content = h.to_s
    # descr = h.search('./p[1] | ./p[1]/following-sibling::node()[count(preceding-sibling::p) = 1]').to_s
    descr = @content[/<p>.*?<\/p>.*?<p>.*?<\/p>/m] || ""
    @html_descr = descr + "<p>...</p>"
    @text_descr = Nokogiri::HTML(descr).text
    @text_descr = "#{@text_descr[...157]}..." if @text_descr.length > 160
  end
end

def build_posts
  FileUtils.rm_rf("../posts/html")
  FileUtils.mkdir("../posts/html")
  # TODO: move this to inside Post initializer
  Dir["../posts/*.md"].each { |md|
    `pandoc #{md} -f gfm -t gfm -o #{md}` unless ENV["NOFORMAT"]
    `pandoc --wrap=none --no-highlight #{md} -f gfm -t html5 -o "../posts/html/#{File.basename(md, ".*")}.html"`
  }
  posts = Dir["../posts/html/*.html"].map { |html_file|
    Post.new(html_file)
  }.sort_by!(&:date)
end

def build_rss(posts)
  rss = RSS::Maker.make("atom") do |maker|
    maker.channel.links.new_link do |link|
      link.href = "https://pineman.github.io/atom.xml"
      link.rel = "self"
    end
    maker.channel.author = "João Pinheiro"
    maker.channel.title = "João Pinheiro"
    maker.channel.about = "https://pineman.github.io/"
    maker.channel.updated = posts.last.date.iso8601
    posts.each do |post|
      maker.items.new_item do |item|
        item.title = post.title
        item.link = "https://pineman.github.io/#{post.url}"
        item.updated = post.date.iso8601
        item.description = post.html_descr
      end
    end
  end
  rss.to_s.gsub!("<summary>", '<summary type="html">')
end

posts = build_posts
posts.each { |post|
  write_html("../#{post.url}", "post.html.erb", binding)
}
write_html("../index.html", "index.html.erb", binding)
rss = build_rss(posts)
File.write("../atom.xml", rss)
write_html("../what-i-read.html", "what-i-read.html.erb", binding)
