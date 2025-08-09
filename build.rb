#!/usr/bin/env ruby

require "rss"
require "erubi"

require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "nokogiri", "1.16.2"
end

def write_html(html_file, template_file, caller_binding)
  template = Erubi::Engine.new(File.read(template_file), escape: true)
  html = eval(template.src, caller_binding)
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
  attr_reader :url, :title, :content, :date, :html_descr, :text_descr
  def initialize(date, url, html)
    @url = url
    @date = DateTime.parse(date)
    html = Nokogiri::HTML.fragment(html)
    @title = html.at("h1").text
    html.at("h1").remove

    # Add IDs to headings and copy link
    html.css('h1, h2, h3, h4, h5, h6').each do |heading|
      id = heading.text.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
      heading['id'] = id
      copy_link = Nokogiri::XML::Node.new('a', html)
      copy_link['href'] = "##{id}"
      copy_link['class'] = 'heading-link'
      copy_link['title'] = 'Copy link to heading'
      copy_link['onclick'] = "copyHeadingLink(this);"
      icon = Nokogiri::XML::Node.new('span', html)
      icon['class'] = 'icon-container'
      icon.inner_html = '<i class="fa-solid fa-link"></i>'
      copy_link.add_child(icon)
      heading.add_child(copy_link)
    end

    @content = html.to_s
    # descr = h.search('./p[1] | ./p[1]/following-sibling::node()[count(preceding-sibling::p) = 1]').to_s
    descr = @content[/<p>.*?<\/p>.*?<p>.*?<\/p>/m] || ""
    @html_descr = descr + "<p>...</p>"
    @text_descr = Nokogiri::HTML.fragment(descr).text
    @text_descr = "#{@text_descr[...157]}..." if @text_descr.length > 160
  end
end

def build_post(md)
  `pandoc #{md} -f gfm -t gfm -o #{md}` unless ENV["NOFORMAT"]
  html = "posts/html/#{File.basename(md, ".*")}.html"
  `pandoc --wrap=none --no-highlight #{md} -f gfm -t html5 -o #{html}`
  date, url = File.basename(html).split("_")
  html = File.read(html)
  Post.new(date, url, html)
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
        item.published = post.date.iso8601
        item.updated = post.date.iso8601
        item.description = post.html_descr
      end
    end
  end
  rss.to_s.gsub!("<summary>", '<summary type="html">')
end

`rm -f posts/html/*; rm -f *.html`
posts = Dir["posts/*.md"].map { |md|
  build_post(md)
}
posts.each { |post|
  write_html("#{post.url}", "post.html.erb", binding)
}
write_html("index.html", "index.html.erb", binding)
File.write("atom.xml", build_rss(posts))
write_html("what-i-read.html", "what-i-read.html.erb", binding)
