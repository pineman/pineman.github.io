# Variables
POSTS_MD := $(wildcard posts/*.md)
POSTS_HTML := $(POSTS_MD:posts/%.md=%.html)
POSTS_INTERMEDIATE := $(POSTS_MD:posts/%.md=posts/html/%.html)
LINK_PREVIEWS := $(POSTS_MD:posts/%.md=assets/link_previews/%.png)
BUILD := Makefile build.rb

# Main templates and partials
TEMPLATES := index.html.erb post.html.erb what-i-read.html.erb
PARTIALS := partials/head.html partials/article-head.html partials/pinecone.html

# Default target
.PHONY: all
all: $(POSTS_HTML) index.html what-i-read.html atom.xml $(LINK_PREVIEWS)

index.html: index.html.erb $(POSTS_HTML) partials/head.html partials/pinecone.html $(BUILD)
	./build.rb $@

what-i-read.html: what-i-read.html.erb posts/what-i-read.txt partials/head.html partials/pinecone.html partials/article-head.html $(BUILD)
	./build.rb $@

atom.xml: $(POSTS_HTML) $(BUILD)
	./build.rb $@

%.html: post.html.erb posts/%.md partials/head.html partials/pinecone.html partials/article-head.html $(BUILD)
	./build.rb $@

assets/link_previews/%.png: posts/html/%.html $(BUILD)
	./build.rb $@

.PHONY: clean
clean:
	rm -f index.html what-i-read.html $(POSTS_HTML) atom.xml assets/link_previews/*.png posts/html/*.html
