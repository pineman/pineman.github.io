fs = require('fs')
hljs = require('highlight.js')
code = fs.readFileSync(0, 'utf8')
html = hljs.highlight(code, {language: process.argv[2]}).value
process.stdout.write(html)
