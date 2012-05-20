# This script automatically converts the HTML pages
# of the Ruby Hacking Guide to the textile-based text
# format used for the translation.
# It's far from being perfect and
# won't be useful in any other case because it's
# dependant on the way these HTML pages are written,
# it's still better than doing this by hand.
$KCODE = 'u'

if ARGV.length != 2
  puts "syntax: #{$0} input_html output_txt"
  exit
end

require 'nkf'

# read the file, convert it to UTF-8 and tranform full width characters in ASCII
data = File.open(ARGV[0], 'r') { |input_file| NKF::nkf('-w -Z', input_file.read) }

File.open(ARGV[1], 'w') do |output|
  in_code = false
  data.gsub!(%r{&(amp|gt|lt);|</?pre\b|</?code>}) do |m|
    if m[0] == ?<
      in_code = (m[1] != ?/)
      if /code/.match(m) then '`' else m end
    else
      if in_code # replaces &xxx; in code and pre blocs
        { '&amp;' => '&', '&gt;' => '>', '&lt;' => '<' }[m]
      else
        m
      end
    end
  end
  
  # different types of list
  list_type = nil
  data.gsub!(/<(ul|ol|li)>/) do |m|
    if m == '<li>'
      if list_type == '<ol>' then '# ' else '* ' end
    else
      list_type = m
      ''
    end
  end

  [
    [ /.*?<body>(.*?)<\/body>.*/m, '\1' ], # we only want the body
    [ /<\/?(table|p( class=".+?")?)>|<\/(li|h\d|ol|ul)>/, '' ], # remove useless tags
    [ /▼/, '▼ ' ], # just add a space after the arrow
    [ /<h(\d)>/, 'h\1. ' ], # headers
    [ /<a href="(.+?)">(.+?)<\/a>/m, '"\2":\1' ], # images
    [ /<tr><td>|<td><td>|<td><\/tr>/, '|' ], # tables
    [ /<img src="(.+?)" alt=".+?"><br>\n図\d+: (.*)/, '!\1(\2)!' ], # images and captions
    [ /[ \t]+$/, '' ], # trims line ends
    [ /\A\n+|\n+\Z/, '' ], # remove beginning and ending empty lines
    [ /\n\n+/, "\n\n" ], # succession of empty lines
  ].each { |re, str| data.gsub!(re, str) }
    
  output.puts(data)
end
