---
layout: default
---

h1. Final Chapter: Ruby's future

h2. Issues to be addressed

@ruby@ isn't 'completely finished' software. It's still being developed,
there are still a lot of issues. Firstly, we want to try removing
inherent problems in the current interpreter.

The order of the topics is mostly in the same order as the chapters of 
this book.


h3. Performance of GC

The performance of the current GC might be
"not notably bad, but not notably good".
"not notably bad" means "it won't cause troubles in our daily life",
and "not notably good" means "its downside will be exposed under heavy load".
For example, if it is an application which creates plenty of objects and keeps
holding them, its speed would slow down radically.
Every time doing GC, it needs to mark all of the objects,
and furthermore it would becomes to need to invoke GC more often
because it can't collect them.
To counter this problem, Generational GC, which was mentioned in Chapter 5,
must be effective. (At least, it is said so in theory.)

Also regarding its response speed,
there are still rooms we can improve.
With the current GC, while it is running, the entire interpretor stops.
Thus, when the program is an editor or a GUI application,
sometimes it freezes and stops to react.
Even if it's just 0.1 second,
stopping when typing characters would give a very bad impression.
Currently, there are few such applications created or,
even if exists, its size might be enough small not to expose this problem.
However, if such application will actually be created in the future,
there might be the necessity to consider Incremental GC.


h3. Implementation of parser

As we saw in Part 2, the implementation of @ruby@ parser has already utilized
@yacc@'s ability to almost its limit, thus I can't think it can endure further
expansions. It's all right if there's nothing planned to expand,
but a big name "keyword argument" is planned next
and it's sad if we could not express another demanded grammar because of the
limitation of @yacc@.


h3. Reuse of parser

Ruby's parser is very complex. In particular, dealing with around @lex_state@
seriously is very hard. Due to this, embedding a Ruby program or creating a
program to deal with a Ruby program itself is quite difficult.

For example, I'm developing a tool named @racc@,
which is prefixed with R because it is a Ruby-version @yacc@.
With @racc@, the syntax of grammar files are almost the same as @yacc@
but we can write actions in Ruby.
To do so, it could not determine the end of an action without parsing Ruby code
properly, but "properly" is very difficult. Since there's no other choice,
currently I've compromised at the level that it can parse "almost all".

As another example which requires analyzing Ruby program,
I can enumerate some tools like @indent@ and @lint@,
but creating such tool also requires a lot efforts.
It would be desperate if it is something complex like a refactoring tool.

Then, what can we do? If we can't recreate the same thing,
what if @ruby@'s original parser can be used as a component?
In other words, making the parser itself a library.
This is a feature we want by all means.

However, what becomes problem here is, as long as @yacc@ is used,
we cannot make parser reentrant.
It means, say, we cannot call @yyparse()@ recursively,
and we cannot call it from multiple threads.
Therefore, it should be implemented in the way of not returning control to Ruby
while parsing.



h3. Hiding Code

With current @ruby@, it does not work without the source code of the program to
run. Thus, people who don't want others to read their source code might have
trouble.


h3. Interpretor Object

Currently each process cannot have multiple @ruby@ interpretors,
this was discussed in Chapter 13.
If having multiple interpretors is practically possible, it seems better,
but is it possible to implement such thing?


h3. The structure of evaluator

Current @eval.c@ is, above all, too complex.
Embedding Ruby's stack frames to machine stack could occasionally become the
source of trouble, using @setjmp() longjmp()@ aggressively makes it less easy to
understand and slows down its speed.
Particularly with RISC machine, which has many registers, using @setjmp()@
aggressively can easily cause slowing down because @setjmp()@ set aside all
things in registers.


h3. The performance of evaluator

@ruby@ is already enough fast for ordinary use.
But aside from it, regarding a language processor,
definitely the faster is the better.
To achieve better performance, in other words to optimize,
what can we do?
In such case, the first thing we have to do is profiling.
So I profiled.

<pre class="emlist">
  %   cumulative   self              self     total
 time   seconds   seconds    calls  ms/call  ms/call  name
 20.25      1.64     1.64  2638359     0.00     0.00  rb_eval
 12.47      2.65     1.01  1113947     0.00     0.00  ruby_re_match
  8.89      3.37     0.72  5519249     0.00     0.00  rb_call0
  6.54      3.90     0.53  2156387     0.00     0.00  st_lookup
  6.30      4.41     0.51  1599096     0.00     0.00  rb_yield_0
  5.43      4.85     0.44  5519249     0.00     0.00  rb_call
  5.19      5.27     0.42   388066     0.00     0.00  st_foreach
  3.46      5.55     0.28  8605866     0.00     0.00  rb_gc_mark
  2.22      5.73     0.18  3819588     0.00     0.00  call_cfunc
</pre>

This is a profile when running some application but
this is approximately the profile of a general Ruby program.
@rb_eval()@ appeared in the overwhelming percentage being at the top,
after that, in addition to functions of GC, evaluator core,
functions that are specific to the program are mixed.
For example, in the case of this application,
it takes a lot of time for regular expression match (@ruby_re_match@).

However, even if we understood this, the question is how to improve it.
To think simply, it can be archived by making @rb_eval()@ faster.
That said, but as for @ruby@ core, there are almost not any room which can be
easily optimized. For instance, apparently "tail recursive -> @goto@ conversion"
used in the place of @NODE_IF@ and others has already applied almost all
possible places it can be applied.
In other words, without changing the way of thinking fundamentally,
there's no room to improve.


h3. The implementation of thread

This was also discussed in Chapter 19. There are really a lot of issues about
the implementation of the current ruby's thread. Particularly, it cannot mix
with native threads so badly. The two great advantages of @ruby@'s thread,
(1) high portability (2) the same behavior everywhere,
are definitely incomparable, but probably that implementation is something we
cannot continue to use eternally, isn't it?




h2. `ruby` 2

Subsequently, on the other hand, I'll introduce the trend of the original `ruby`,
how it is trying to counter these issues.


h3. Rite

At the present time, ruby's edge is 1.6.7 as the stable version and 1.7.3 as the
development version, but perhaps the next stable version 1.8 will come out in
the near future. Then at that point, the next development version 1.9.0 will
start at the same time. And after that, this is a little irregular but 1.9.1
will be the next stable version.

|_. stable |_. development |_. when to start |
| 1.6.x | 1.7.x | 1.6.0 was released on 2000-09-19 |
| 1.8.x | 1.9.x | probably it will come out within 6 months |
| 1.9.1~ | 2.0.0 | maybe about 2 years later |


And the next-to-next generational development version is `ruby` 2, whose code
name is Rite. Apparently this name indicates a respect for the inadequacy that
Japanese cannot distinguish the sounds of L and R.

What will be changed in 2.0 is, in short, almost all the entire core.
Thread, evaluator, parser, all of them will be changed.
However, nothing has been written as a code yet, so things written here is
entirely just a "plan". If you expect so much, it's possible it will turn out
disappointments. Therefore, for now, let's just expect slightly.


h3. The language to write

Firstly, the language to use. Definitely it will be C. Mr. Matsumoto said to
`ruby-talk`, which is the English mailing list for Ruby,

<blockquote>
I hate C++.
</blockquote>

So, C++ is most unlikely. Even if all the parts will be recreated,
it is reasonable that the object system will remain almost the same,
so not to increase extra efforts around this is necessary.
However, chances are good that it will be ANSI C next time.


h3. GC

Regarding the implementation of GC,
the good start point would be
`Boehm GC`\footnote{Boehm GC `http://www.hpl.hp.com/personal/Hans_Boehm/gc`}.
Bohem GC is a conservative and incremental and generational GC,
furthermore, it can mark all stack spaces of all threads even while native
threads are running. It's really an impressive GC.
Even if it is introduced once, it's hard to tell whether it will be used
perpetually, but anyway it will proceed for the direction to which we can expect
somewhat improvement on speed.


h3. Parser

Regarding the specification, it's very likely that the nested method calls
without parentheses will be forbidden. As we've seen, `command_call` has a great
influence on all over the grammar. If this is simplified, both the parser and
the scanner will also be simplified a lot.
However, the ability to omit parentheses itself will never be disabled.

And regarding its implementation, whether we continue to use `yacc` is still
under discussion. If we won't use, it would mean hand-writing, but is it
possible to implement such complex thing by hand? Such anxiety might left.
Whichever way we choose, the path must be thorny.


h3. Evaluator

The evaluator will be completely recreated.
Its aims are mainly to improve speed and to simplify the implementation.
There are two main viewpoints:


* remove recursive calls like `rb_eval()`
* switch to a bytecode interpretor

First, removing recursive calls of `rb_eval()`. The way to remove is,
maybe the most intuitive explanation is that it's like the "tail recursive ->
`goto` conversion". Inside a single `rb_eval()`, circling around by using
`goto`. That decreases the number of function calls and removes the necessity of
`setjmp()` that is used for `return` or `break`.
However, when a function defined in C is called, calling a function is
inevitable, and at that point `setjmp()` will still be required.


Bytecode is, in short, something like a program written in machine language.
It became famous because of the virtual machine of Smalltalk90,
it is called bytecode because each instruction is one-byte.
For those who are usually working at more abstract level, byte would seem
so natural basis in size to deal with,
but in many cases each instruction consists of bits in machine languages.
For example, in Alpha, among a 32-bit instruction code, the beginning 6-bit
represents the instruction type.


The advantage of bytecode interpretors is mainly for speed. There are two
reasons: Firstly, unlike syntax trees, there's no need to traverse pointers.
Secondly, it's easy to do peephole optimization.


And in the case when bytecode is saved and read in later,
because there's no need to parse, we can naturally expect better performance.
However, parsing is a procedure which is done only once at the beginning of a
program and even currently it does not take so much time. Therefore, its
influence will not be so much.


If you'd like to know about how the bytecode evaluator could be,
`regex.c` is worth to look at.
For another example, Python is a bytecode interpretor.




h3. Thread

Regarding thread, the thing is native thread support.
The environment around thread has been significantly improved,
comparing with the situation in 1994, the year of Ruby's birth.
So it might be judged that
we can get along with native thread now.


Using native thread means being preemptive also at C level,
thus the interpretor itself must be multi-thread safe,
but it seems this point is going to be solved by using a global lock
for the time being.


Additionally, that somewhat arcane "continuation", it seems likely to be removed.
`ruby`'s continuation highly depends on the implementation of thread,
so naturally it will disappear if thread is switched to native thread.
The existence of that feature is because "it can be implemented"
and it is rarely actually used. Therefore there might be no problem.



h3. M17N

In addition, I'd like to mention a few things about class libraries.
This is about multi-lingualization (M17N for short).
What it means exactly in the context of programming is
being able to deal with multiple character encodings.


`ruby` with Multi-lingualization support has already implemented and you can
obtain it from the `ruby_m17m` branch of the CVS repository.
It is not absorbed yet because it is judged that its specification is immature.
If good interfaces is designed,
it will be absorbed at some point in the middle of 1.9.




h3. IO


The `IO` class in current Ruby is a simple wrapper of `stdio`,
but in this approach,

* there are too many but slight differences between various platforms.
* we'd like to have finer control on buffers.

these two points cause complaints.
Therefore, it seems Rite will have its own `stdio`.






h2. Ruby Hacking Guide


So far, we've always acted as observers who look at `ruby` from outside.
But, of course, `ruby` is not a product which displayed in in a showcase.
It means we can influence it if we take an action for it.
In the last section of this book,
I'll introduce the suggestions and activities for `ruby` from community,
as a farewell gift for Ruby Hackers both at present and in the future.


h3. Generational GC

First, as also mentioned in Chapter 5,
the generational GC made by Mr. Kiyama Masato.
As described before, with the current patch,

* it is less fast than expected.
* it needs to be updated to fit the edge `ruby`

these points are problems, but here I'd like to highly value it because,
more than anything else, it was the first large non-official patch.




h3. Oniguruma

The regular expression engine used by current Ruby is a remodeled version of GNU
regex. That GNU regex was in the first place written for Emacs. And then it was
remodeled so that it can support multi-byte characters. And then Mr. Matsumoto
remodeled so that it is compatible with Perl.
As we can easily imagine from this history,
its construction is really intricate and spooky.
Furthermore, due to the LPGL license of this GNU regex,
the license of `ruby` is very complicated,
so replacing this engine has been an issue from a long time ago.

What suddenly emerged here is the regular expression engine "Oniguruma" by
Mr. K. Kosako. I heard this is written really well, it is likely being
absorbed as soon as possible.

You can obtain Oniguruma from the `ruby`'s CVS repository in the following way.

<pre class="screen">
% cvs -d :pserver:anonymous@cvs.ruby-lang.org:/src co oniguruma
</pre>



h3. ripper

Next, ripper is my product. It is an extension library made by remodeling
`parse.y`. It is not a change applied to the `ruby`'s main body, but I
introduced it here as one possible direction to make the parser a component.

It is implemented with kind of streaming interface and
it can pick up things such as token scan or parser's reduction as events.
It is put in the attached CD-ROM
\footnote{ripper：`archives/ripper-0.0.5.tar.gz` of the attached CD-ROM},
so I'd like you to give it a try.
Note that the supported grammar is a little different from the current one
because this version is based on `ruby` 1.7 almost half-year ago.

I created this just because "I happened to come up with this idea",
if this is accounted, I think it is constructed well.
It took only three days or so to implement, really just a piece of cake.


h3. A parser alternative

This product has not yet appeared in a clear form,
there's a person who write a Ruby parser in C++ which can be used totally
independent of `ruby`. (`[ruby-talk:50497]`).


h3. JRuby

More aggressively, there's an attempt to rewrite entire the interpretor.
For example, a Ruby written in Java,
Ruby\footnote{JRuby `http://jruby.sourceforge.net`},
has appeared.
It seems it is being implemented by a large group of people,
Mr. Jan Arne Petersen and many others.


I tried it a little and as my reviews,

* the parser is written really well. It does precisely handle even finer
  behaviors such as spaces or here document.
* `instance_eval` seems not in effect (probably it couldn't be helped).
* it has just a few built-in libraries yet (couldn't be helped as well).
* we can't use extension libraries with it (naturally).
* because Ruby's UNIX centric is all cut out,
  there's little possibility that we can run already-existing scripts without
  any change.
* slow

perhaps I could say at least these things.
Regarding the last one "slow", its degree is,
the execution time it takes is 20 times longer than the one of the original
`ruby`. Going this far is too slow.
It is not expected running fast because that Ruby VM runs on Java VM.
Waiting for the machine to become 20 times faster seems only way.


However, the overall impression I got was, it's way better than I imagined.



h3. NETRuby

If it can run with Java, it should also with C#.
Therefore, a Ruby written in C# appeared,
"NETRuby\footnote{NETRuby `http://sourceforge.jp/projects/netruby/`}".
The author is Mr. arton.

Because I don't have any .NET environment at hand,
I checked only the source code,
but according to the author,

* more than anything, it's slow
* it has a few class libraries
* the compatibility of exception handling is not good

such things are the problems.
But `instance_eval` is in effect (astounding!).


h3. How to join `ruby` development

`ruby`'s developer is really Mr. Matsumoto as an individual,
regarding the final decision about the direction `ruby` will take,
he has the definitive authority.
But at the same time, `ruby` is an open source software,
anyone can join the development.
Joining means, you can suggest your opinions or send patches.
The below is to concretely tell you how to join.

In `ruby`'s case, the mailing list is at the center of the development,
so it's good to join the mailing list.
The mailing lists currently at the center of the community are three:
`ruby-list`, `ruby-dev`, `ruby-talk`.
`ruby-list` is a mailing list for "anything relating to Ruby" in Japanese.
`ruby-dev` is for the development version `ruby`, this is also in Japanese.
`ruby-talk` is an English mailing list.
The way to join is shown on the page "mailing lists" at Ruby's official site
\footnote{Ruby's official site: `http://www.ruby-lang.org/ja/`}.
For these mailing lists, read-only people are also welcome,
so I recommend just joining first and watching discussions
to grasp how it is.

Though Ruby's activity started in Japan,
recently sometimes it is said "the main authority now belongs to `ruby-talk`".
But the center of the development is still `ruby-dev`.
Because people who has the commit right to `ruby` (e.g. core members) are mostly
Japanese, the difficulty and reluctance of using English
naturally lead them to `ruby-dev`.
If there will be more core members who prefer to use English,
the situation could be changed,
but meanwhile the core of `ruby`'s development might remain `ruby-dev`.

However, it's bad if people who cannot speak Japanese cannot join the
development, so currently the summary of `ruby-dev` is translated once a week
and posted to `ruby-talk`.
I also help that summarising, but only three people do it in turn now,
so the situation is really harsh.
The members to help summarize is always in demand.
If you think you're the person who can help,
I'd like you to state it at `ruby-list`.

And as the last note,
only its source code is not enough for a software.
It's necessary to prepare various documents and maintain web sites.
And people who take care of these kind of things are always in short.
There's also a mailing list for the document-related activities,
but as the first step you just have to propose "I'd like to do something" to `ruby-list`.
I'll answer it as much as possible,
and other people would respond to it, too.


h3. Finale

The long journey of this book is going to end now.
As there was the limitation of the number of pages,
explaining all of the parts comprehensively was impossible,
however I told everything I could tell about the `ruby`'s core.
I won't add extra things any more here.
If you still have things you didn't understand,
I'd like you to investigate it by reading the source code by yourself as much as
you want.
