* * * * *

layout: default\
—

Table of contents
-----------------

Some chapters are previews. It means they have not been fully reviewed,\
some diagrams may be missing and some sentences may be a little\
rough. But it also means they are in open review, so do not hesitate\
to address issues on the mailing list.

-   [Preface](preface.html)
-   [Introduction - translation in progress](intro.html)

### Part 1: Objects

-   [Chapter 1: A Minimal Introduction to Ruby](minimum.html)
-   [Chapter 2: Objects](object.html)
-   [Chapter 3: Names and name tables](name.html)
-   [Chapter 4: Classes and modules](class.html)
-   [Chapter 5: Garbage collection](gc.html)
-   [Chapter 6: Variables and constants](variable.html)
-   [Chapter 7: Security](security.html)

### Part 2: Syntax analysis

-   [Chapter 8: Ruby Language Details](spec.html)
-   [Chapter 9: yacc crash course](yacc.html)
-   [Chapter 10: Parser](parser.html)
-   [Chapter 11: Context-dependent scanner](contextual.html)
-   [Chapter 12: Syntax tree construction](syntree.html)

### Part 3: Evaluation

-   [Chapter 13: Structure of the evaluator](evaluator.html)
-   [Chapter 14: Context](module.html)
-   [Chapter 15: Methods](method.html)
-   [Chapter 16: Blocks](iterator.html)
-   [Chapter 17: Dynamic evaluation](anyeval.html)

### Part 4: Around the evaluator

-   [Chapter 18: Loading](load.html)
-   [Chapter 19: Threads](thread.html)

-   [Final chapter: Ruby’s future - translation unstarted](fin.html)

About this Guide
================

This is a new effort to gather efforts to help translate into English
the [Ruby\
Hacking Guide](http://i.loveruby.net/ja/rhg/book/). The RHG is a book\
that explains how the ruby interpreter (the official\
C implementation of the [Ruby language](http://www.ruby-lang.org/))
works\
internally.

To fully understand it, you need a good knowledge of C and Ruby.

Please note that this book was based on the source code of ruby 1.7.3\
so there are a few small differences to the current version of\
ruby. However, these differences may make the source code simpler to\
understand and the Ruby Hacking Guide is a good starting point before\
looking into the ruby source code. The version of the source code used\
can be downloaded here: http://i.loveruby.net/ja/rhg/ar/ruby-rhg.tar.gz.

Many thanks to [RubyForge](http://rubyforge.org) for hosting us and to\
Minero AOKI for letting us translate his work.

Help us!
--------

The original is available [here](http://i.loveruby.net/ja/rhg/book/)\
or hosted within this repo
[here](http://ruby-hacking-guide.github.com/original_repo/ja_html/)\
(currently with broken formatting)

This translation is done during our free time, do not expect too\
much. The book is quite big (more than 500 pages) so we need help to\
translate it.

People who are good at Ruby, C and Japanese or English are\
needed. Those good at Japanese (native Japanese speakers are of course\
welcome) can help translate and those good at English (preferably\
native speakers) can help correct mistakes, and rewrite badly written\
parts… Knowing Ruby and C well is really a requirement because it\
helps avoiding many mistranslations and misinterpretations.

People good at making diagrams would also be helpful because there is\
quite a lot to redo and translators would rather spend their time\
translating instead of making diagrams.

There have been multiple efforts to translate this book, and we want to
see if\
we can renew efforts by creating an organisation on github. Interested
parties\
can join in by starting a pull request on this repo\
https://github.com/ruby-hacking-guide/ruby-hacking-guide.github.com\
There is a mostly derelict mailing list at\
[rhg-discussion mailing
list](http://rubyforge.org/mailman/listinfo/rhg-discussion)\
feel free to introduce yourself (who you are, your skills, how much free
time you\
have), but I think the best way to propose or send
corrections/improvements\
is to send a pull request. If you start a feature branch along with a
pull\
request at the start of your work then people can comment as you work.

There is an old SVN repo, that is hosted at\
The RubyForge project page is http://rubyforge.org/projects/rhg.\
It has been imported here, and I will attempt to give credit and
re-write the\
SVN/Git history when I can.

As for now the contributors to that repo were:

-   Vincent ISAMBART
-   meinrad recheis
-   Laurent Sansonetti
-   Clifford Caoile
-   Jean-Denis Vauguet

