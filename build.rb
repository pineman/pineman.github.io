#!/usr/bin/env ruby

require "rss"
require "erubi"
require "digest"

require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "nokogiri", "1.16.2"
end

CHROME_BINARY = '"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"'

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
  attr_reader :url, :title, :title_hash, :content, :date, :html_descr, :text_descr

  def initialize(date, url, html)
    @url = url
    @date = DateTime.parse(date)
    html = Nokogiri::HTML.fragment(html)
    @title = html.at("h1").text
    html.at("h1").remove
    @title_hash = Digest::MD5.hexdigest(@title)

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
    text = Nokogiri::HTML.fragment(@content).text
    words = text.split(/\s+/)
    truncated = ""
    words.each do |word|
      test_string = truncated.empty? ? word : "#{truncated} #{word}"
      break if test_string.length > 160
      truncated = test_string
    end
    suffix = truncated.end_with?('.') ? ' ...' : '...' if truncated.length < text.length
    @text_descr = "#{truncated}#{suffix}"
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
        item.description = post.content
      end
    end
  end
  rss.to_s.gsub!("<summary>", '<summary type="html">')
end

# props to https://github.com/ordepdev/ordepdev.github.io/blob/1bee021898a6c2dd06a803c5d739bd753dbe700a/scripts/generate-social-images.js#L26
def gen_img(post)
  width = 1200
  height = 630
  svg = <<-SVG
<svg width="#{width}" height="#{height}" viewBox="0 0 #{width} #{height}" xmlns="http://www.w3.org/2000/svg">
  <style>
    .container {
      background: #1d1e20;
      font-family: Menlo, monospace; /* I'll always have a mac right? */
      color: #dadadb;
      display: flex;
      flex-direction: column;
      height: 100%;
      padding: 50px;
      box-sizing: border-box;
    }
    .footer {
      margin-top: auto;
      font-size: 30px;
      align-self: flex-end;
    }
    h1 {
      margin: 0;
      font-size: 60px;
    }
    p {
      font-size: 40px;
    }
  </style>
  <foreignObject x="0" y="0" width="#{width}" height="#{height}">
    <div xmlns="http://www.w3.org/1999/xhtml" class="container">
      <h1>#{post.title}</h1>
      <p>#{post.text_descr}</p>
      <div class="footer">
        <span>pineman #{post.date.strftime("%Y-%m-%d")}</span>
      </div>
    </div>
  </foreignObject>
</svg>
  SVG
  th = post.title_hash
  File.write("#{th}.svg", svg)
  system <<~SCRIPT
    #{CHROME_BINARY} --headless --screenshot --window-size=#{width},#{height+400} "file://$(pwd)/#{th}.svg" &>/dev/null
    docker run --rm -v $(pwd):/imgs dpokidov/imagemagick:7.1.1-8-bullseye screenshot.png -quality 80 -crop x630+0+0 #{th}.webp
    rm -f #{th}.svg screenshot.png
    mkdir -p assets/link_previews
    mv #{th}.webp assets/link_previews/#{th}.webp
  SCRIPT
end

posts = Dir["posts/*.md"].map { |md|
  build_post(md)
}
posts.each { |post|
  write_html("#{post.url}", "post.html.erb", binding)
  gen_img(post)
}
write_html("index.html", "index.html.erb", binding)
File.write("atom.xml", build_rss(posts))
write_html("what-i-read.html", "what-i-read.html.erb", binding)
