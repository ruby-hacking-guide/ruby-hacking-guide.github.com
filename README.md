Ruby Hacking Guide Translation
==============================
[Read the translated guide here](http://ruby-hacking-guide.github.io/)

Creating a github repo to hopefully inspire efforts to get this translated

The current activity is discussed
[here](https://github.com/ruby-hacking-guide/ruby-hacking-guide.github.com/pull/2)


Contributors
============

* Vincent Isambart
* Meinrad Recheis
* Laurent Sansonetti
* Clifford Escobar Caoile
* Jean-Denis Vauguet
* Robert Gravina

Running the site locally
==========

```sh
$ git clone https://github.com/ruby-hacking-guide/ruby-hacking-guide.github.com
$ gem install jekyll
$ gem install RedCloth
$ jekyll serve # this compiles files and starts a server on localhost:4000.
```


For Bundler users
```sh
$ git clone https://github.com/ruby-hacking-guide/ruby-hacking-guide.github.com
$ bundle install
$ jekyll serve # this compiles files and starts a server on localhost:4000.
```


[Jekyll usage](https://github.com/mojombo/jekyll/wiki/usage)


Reading in EPUB
=========

Thanks to @avsej, we can read this book in EPUB.

To genearte an EPUB file, you need to install eeepub additionally.

```sh
$ gem install eeepub
$ ruby script/publish
```


About the version of ruby explained
==========

The version of ruby used is ruby (1.7.3 2002-09-12).

It's almost a year before the release of Ruby 1.8.0,
so things explained in this book are basically the same in Ruby 1.8.

The details about this version are written in the
[Introduction](http://ruby-hacking-guide.github.io/intro.html)

You can download it from the official support site of the book.
* http://i.loveruby.net/ja/rhg/ar/ruby-rhg.tar.gz
* http://i.loveruby.net/ja/rhg/ar/ruby-rhg.zip

It's also available from this Organization's repo at
* https://github.com/ruby-hacking-guide/ruby-1.7.3


License
=======

Copyright (c) 2002-2004 Minero Aoki, All rights reserved.

This translation work is licensed under a
[Creative Commons Attribution-NonCommercial-ShareAlike2.5 License](http://creativecommons.org/licenses/by-nc-sa/2.5/)

If you'd like to translate this work to another language,
please contact the author Minero Aoki.
