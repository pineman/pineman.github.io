require "cgi"
require "vips"

png, title, descr, date = ARGV

# props to https://github.com/ordepdev/ordepdev.github.io/blob/1bee021898a6c2dd06a803c5d739bd753dbe700a/scripts/generate-social-images.js#L26
title_mask = Vips::Image.text("<b>#{CGI.escapeHTML(title)}</b>", font: "JetBrains Mono 60", width: 1100, dpi: 72)
descr_mask = Vips::Image.text(CGI.escapeHTML(descr), font: "JetBrains Mono 40", width: 1100, dpi: 72)
footer_mask = Vips::Image.text("pineman #{date}", font: "JetBrains Mono 30", dpi: 72)
Vips::Image.black(1200, 630)
  .insert(title_mask, 50, 50)
  .insert(descr_mask, 50, 50 + title_mask.height + 40)
  .insert(footer_mask, 1200 - 50 - footer_mask.width, 630 - 50 - footer_mask.height)
  .ifthenelse([0xda, 0xda, 0xdb], [0x1d, 0x1e, 0x20], blend: true)
  .write_to_file(png, palette: true, Q: 80, strip: true)
