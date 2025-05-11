# Inspirations
http://motherfuckingwebsite.com/

http://bettermotherfuckingwebsite.com/

https://thebestmotherfucking.website/

# Instructions
Compile with `./make`

Watch with `./make watch`

# Notes
`assets/highlight.min.js` includes almost no languages on purpose. Select more from [here](https://highlightjs.org/download/). Download, unzip, and copy `highlight.min.js` only.

Could use https://github.com/pygments/pygments.rb as a compile-time alternative (highlight.js failed)

HTML files are all in the root dir so that an HTTP server is not needed. Otherwise, the head partial would need to be dynamic (or use absolute links with an HTTP server)
