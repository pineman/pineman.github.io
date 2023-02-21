ruby -ne '$_.strip!; puts "<li><a href=\"#{$_}\">#{$_}</a></li>"' < links
