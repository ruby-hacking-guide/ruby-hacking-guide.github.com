#!/usr/bin/env ruby
# -*- coding: utf-8 -*- vim:set encoding=utf-8:
RHGAddress = 'rubyforge.org:/var/www/gforge-projects/rhg/'
address = RHGAddress
upload_images = false 

def show_help_and_die
    puts <<EOS
Usage: #{__FILE__} [--help|--upload-images]

--help:            Show this help
--upload-images:   Also upload images (which we do not by default)
--login=<login>:    rubyforge.org login
EOS
    exit 0
end

ARGV.each do |arg|
  case arg
    when '--help'
      show_help_and_die

    when '--upload-images'
      upload_images = true

    when /--login=(\w+)/
      address = "#{$1}@#{RHGAddress}"

    else
      show_help_and_die
  end
end

unless system("scp rhg.css #{Dir.glob('*.html').join(' ')} #{address}")
  STDERR.puts "Error when trying to upload html/css files"
  exit 1
end

if upload_images
  unless system("scp images/*.png #{address}/images")
    STDERR.puts "Error when trying to upload images files"
    exit 1
  end
end
