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
  # TODO: be explicit about the binding, don't use eval
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
  attr_reader :filename, :url, :title, :content, :date, :html_descr, :text_descr

  def initialize(path)
    @md_file = path
    @filename = File.basename(@md_file, ".md")
    date, url = @filename.split("_")
    @url = "#{url}.html"
    @date = DateTime.parse(date)
    @html_file = "posts/html/#{@filename}.html"
  end

  def set_html_attrs!
    html = Nokogiri::HTML.fragment(File.read(@html_file))
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

  def build!
    `pandoc #{@md_file} -f gfm -t gfm -o #{@md_file}` if !ENV["NOFORMAT"]
    `pandoc --wrap=none --no-highlight #{@md_file} -f gfm -t html5 -o #{@html_file}`
    set_html_attrs!
  end
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
  t = post.filename
  File.write("#{t}.svg", svg)
  system <<~SCRIPT
    #{CHROME_BINARY} --headless --screenshot --window-size=#{width},#{height+400} "file://$(pwd)/#{t}.svg" &>/dev/null
    docker run --rm -v $(pwd):/imgs dpokidov/imagemagick:7.1.1-8-bullseye screenshot.png -quality 80 -crop x630+0+0 #{t}.png
    rm -f #{t}.svg screenshot.png
    mkdir -p assets/link_previews
    mv #{t}.png assets/link_previews/
  SCRIPT
end

exit 1 if ARGV.empty?

ARGV.each do |arg|
  case arg
  when /^posts\/.*\.md$/
    post = Post.new(arg)
    post.build!
    write_html("#{post.url}", "post.html.erb", binding)
  when /^assets\/link_previews\/.*\.png$/
    post = Post.new("posts/#{File.basename(arg, ".png")}.md")
    post.set_html_attrs!
    gen_img(post)
  when "index.html"
    write_html("index.html", "index.html.erb", binding)
  when "what-i-read.html"
    write_html("what-i-read.html", "what-i-read.html.erb", binding)
  when "atom.xml"
    File.write("atom.xml", build_rss(posts))
  end
end
