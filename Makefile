# Variables
POSTS_MD := $(wildcard posts/*.md)
POSTS_HTML := $(POSTS_MD:posts/%.md=%.html)
POSTS_INTERMEDIATE := $(POSTS_MD:posts/%.md=posts/html/%.html)
LINK_PREVIEWS := $(POSTS_MD:posts/%.md=assets/link_previews/%.png)

# Main templates and partials
TEMPLATES := index.html.erb post.html.erb what-i-read.html.erb
PARTIALS := partials/head.html partials/article-head.html partials/pinecone.html

# Default target
.PHONY: all clean

all: $(POSTS_HTML) index.html what-i-read.html atom.xml $(LINK_PREVIEWS)

index.html: index.html.erb partials/head.html partials/pinecone.html
	./build.rb $@

what-i-read.html: what-i-read.html.erb posts/what-i-read.txt partials/head.html partials/pinecone.html partials/article-head.html
	./build.rb $@

atom.xml: $(POSTS_HTML)
	./build.rb $@

%.html: post.html.erb posts/%.md partials/head.html partials/pinecone.html partials/article-head.html
	./build.rb $@

assets/link_previews/%.png: posts/html/%.html
	./build.rb $@

clean:
	rm -f index.html what-i-read.html $(POSTS_HTML) atom.xml assets/link_previews/*.png posts/html/*.html

# Force rebuild (ignore timestamps)
.PHONY: force
force: clean all
