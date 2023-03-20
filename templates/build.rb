start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

require "ERB"
require "pathname"

def convert_markdown
  Dir["posts/*.md"].each do |file|
    `\pandoc --no-highlight #{file} -f markdown-smart -o #{Pathname.new(file).sub_ext(".html")}`
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
  templ = ERB.new(File.read("index.html.erb"), trim_mode: ">")
  posts = ""
  Dir["posts/*.html"].each do |file|
    post = Post.new(file)
    posts += "<li>#{post.time} - <a href=\"#{post.url}\">#{post.title}</a></li>\n"
  end
  File.write("../index.html", templ.result(binding))
end

def build_posts
  templ = ERB.new(File.read("post.html.erb"), trim_mode: ">")
  Dir["posts/*.html"].each do |file|
    post = Post.new(file)
    File.write("../#{post.url}", templ.result(binding))
  end
end

def build_what_i_read
  templ = ERB.new(File.read("what-i-read.html.erb"), trim_mode: ">")
  content = ""
  file = File.new("posts/what-i-read.txt")
  time = file.mtime
  file.readlines.each do |l|
    is_section = !l.start_with?("\t")
    l.strip!
    if is_section
      content += "</ul>\n<h4>#{l}</h4>\n<ul>\n"
    elsif l.match?(/^https?:\/\//)
      url, descr = l.split(" ", 2)
      content += "  <li><a href=\"#{url}\">#{url}</a> #{descr}</li>"
    else
      content += "  <li>#{l}</li>\n"
    end
  end
  File.write("../what-i-read.html", templ.result(binding))
end

convert_markdown
build_index
build_posts
build_what_i_read
took = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
puts "success, took #{(took * 1000).round(3)}ms"
