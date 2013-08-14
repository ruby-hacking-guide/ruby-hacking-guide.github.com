#!/usr/bin/env ruby
# Simple script to generate EPUB book (which could be also converted
# to MOBI then) from site sources
#
# It depends on on 'eeepub' ruby gem
#
# Usage is simple:
#
#   gem install eeepub
#   ruby ./epub.rb

require 'eeepub'
require 'date'
require 'fileutils'

today = Date.today
system("jekyll build")
FileUtils.mkdir_p("epub_tmp/images")
FileUtils.cp(Dir["_site/images/*"], "epub_tmp/images")
FileUtils.mkdir_p("epub_tmp/css")
FileUtils.cp("_site/css/styles.css", "epub_tmp/css")
f = File.open("epub_tmp/css/styles.css", "a+")
f.puts(<<EOS)
/* epub patch */
body {width:100%;}
p {width:100%;}
EOS
f.close
Dir["_site/*.html"].each do |f|
  old = File.read(f)
  new = old.gsub(%r("/css/styles.css"), %q("css/styles.css"))
  File.write("epub_tmp/#{File.basename(f)}", new)
end
navigation = [
  {:label => "Preface", :content => "preface.html"},
  {:label => "Introduction - translation in progress", :content => "intro.html"},
  {:label => "Part 1: Objects", :content => "minimum.html", :nav => [
    {:label => "Chapter 1: A Minimal Introduction to Ruby", :content => "minimum.html"},
    {:label => "Chapter 2: Objects", :content => "object.html"},
    {:label => "Chapter 3: Names and name tables", :content => "name.html"},
    {:label => "Chapter 4: Classes and modules", :content => "class.html"},
    {:label => "Chapter 5: Garbage collection", :content => "gc.html"},
    {:label => "Chapter 5: Garbage collection - unfinished alternative translation", :content => "chapter05.html"},
    {:label => "Chapter 6: Variables and constants", :content => "variable.html"},
    {:label => "Chapter 7: Security", :content => "security.html"}
  ]},
  {:label => "Part 2: Syntax analysis", :content => "spec.html", :nav => [
    {:label => "Chapter 8: Ruby Language Details", :content => "spec.html"},
    {:label => "Chapter 9: yacc crash course", :content => "yacc.html"},
    {:label => "Chapter 10: Parser", :content => "parser.html"},
    {:label => "Chapter 11: Context-dependent scanner", :content => "contextual.html"},
    {:label => "Chapter 12: Syntax tree construction", :content => "syntree.html"}
  ]},
  {:label => "Part 3: Evaluation", :content => "evaluator.html", :nav => [
    {:label => "Chapter 13: Structure of the evaluator", :content => "evaluator.html"},
    {:label => "Chapter 14: Context", :content => "module.html"},
    {:label => "Chapter 15: Methods", :content => "method.html"},
    {:label => "Chapter 16: Blocks", :content => "iterator.html"},
    {:label => "Chapter 17: Dynamic evaluation", :content => "anyeval.html"}
  ]},
  {:label => "Part 4: Around the evaluator", :content => "load.html", :nav => [
    {:label => "Chapter 18: Loading", :content => "load.html"},
    {:label => "Chapter 19: Threads", :content => "thread.html"}
  ]},
  {:label => "Final chapter: Ruby's future - translation unstarted", :content => "fin.html"}
]
file_list = Dir["epub_tmp/images/*"].map{|f| {f => "images"}}
file_list.push("epub_tmp/css/styles.css" => "css")
def scan_navigation(nav, acc)
  nav.each do |n|
    if n[:content]
      acc.push("epub_tmp/#{n[:content]}")
    end
    if n[:nav]
      scan_navigation(n[:nav], acc)
    end
  end
end
scan_navigation(navigation, file_list)
epub = EeePub.make do
  title       'Ruby Hacking Guide'
  creator     'Minero AOKI, Vincent ISAMBART, Clifford Escobar CAOILE'
  rights      'The original work is Copyright © 2002 - 2004 Minero AOKI. Translated by Vincent ISAMBART and Clifford Escobar CAOILE This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike2.5 License'
  date        today
  identifier  'http://ruby-hacking-guide.github.io/', :scheme => 'URL'
  uid         'http://ruby-hacking-guide.github.io/'
  cover       "images/book_cover.jpg"

  files file_list
  nav navigation
end
epub.save("rgh-#{today}.epub")
FileUtils.rm_rf("epub_tmp")
