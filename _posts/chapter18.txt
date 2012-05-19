$comment(-*- coding: utf-8 -*- vim: set encoding=utf-8:)$
Translated by Vincent ISAMBART

h1. Chapter 18: Loading

h2. Outline

h3. Interface

At the Ruby level, there are two procedures that can be used for
loading: `require` and `load`.

<pre class="emlist">
require 'uri'            # load the uri library
load '/home/foo/.myrc'   # read a resource file
</pre>

They are both normal methods, compiled and evaluated exactly like any
other code. It means loading occurs after compilation gave control to
the evaluation stage.

These two function each have their own use. 'require' is to load
libraries, and `load` is to load an arbitrary file. Let's see this in
more details.

h4. `require`

`require` has four features:

* the file is searched in the load path
* it can load extension libraries
* the `.rb`/`.so` extension can be omitted
* a given file is never loaded more than once

Ruby's load path is in the global variable `$:` that contains an
array of strings. For example, displaying the content of the `$:` in
the environment I usually use would show:

<pre class="screen">
% ruby -e 'puts $:'
/usr/lib/ruby/site_ruby/1.7
/usr/lib/ruby/site_ruby/1.7/i686-linux
/usr/lib/ruby/site_ruby
/usr/lib/ruby/1.7
/usr/lib/ruby/1.7/i686-linux
.
</pre>

Calling `puts` on an array displays one element by line so it's easy
to read.

As I ran `configure` using `--prefix=/usr`, the library path is
`/usr/lib/ruby` and below, but if you compile it normally from the
source code, the libraries will be in `/usr/local/lib/ruby` and below.
In a Windows environment, there will also be a drive letter.

Then, let's try to `require` the standard library `nkf.so` from the
load path.

<pre class="emlist">
require 'nkf'
</pre>

If the `require`d name has no extension, `require` silently
compensates. First, it tries with `.rb`, then with `.so`. On some
platforms it also tries the platform's specific extension for
extension libraries, for example `.dll` in a Windows environment or
`.bundle` on Mac OS X.

Let's do a simulation on my environment. `ruby` checks the following
paths in sequential order.

<pre class="emlist">
/usr/lib/ruby/site_ruby/1.7/nkf.rb
/usr/lib/ruby/site_ruby/1.7/nkf.so
/usr/lib/ruby/site_ruby/1.7/i686-linux/nkf.rb
/usr/lib/ruby/site_ruby/1.7/i686-linux/nkf.so
/usr/lib/ruby/site_ruby/nkf.rb
/usr/lib/ruby/site_ruby/nkf.so
/usr/lib/ruby/1.7/nkf.rb
/usr/lib/ruby/1.7/nkf.so
/usr/lib/ruby/1.7/i686-linux/nkf.rb
/usr/lib/ruby/1.7/i686-linux/nkf.so    found!
</pre>

`nkf.so` has been found in `/usr/lib/ruby/1.7/i686-linux`. Once the
file has been found, `require`'s last feature (not loading the file
more than once) locks the file. The locks are strings put in the
global variable `$"`. In our case the string `"nkf.so"` has been put
there. Even if the extension has been omitted when calling `require`,
the file name in `$"` has the extension.

<pre class="emlist">
require 'nkf'   # after loading nkf...
p $"            # ["nkf.so"]  the file is locked

require 'nkf'   # nothing happens if we require it again
p $"            # ["nkf.so"]  the content of the lock array does not change
</pre>

The are two reasons for adding the missing extension. The first one is
not to load it twice if the same file is later `require`d with its
extension. The second one is to be able to load both `nkf.rb` and
`nkf.so`. In fact the extensions are disparate (`.so .dll .bundle`
etc.) depending of the platform, but at locking time they all become
`.so`. That's why when writing a Ruby program you can ignore the
differences of extensions and consider it's always `so`. So you can
say that `ruby` is quite UNIX oriented.

By the way, `$"` can be freely modified even at the Ruby level so we
cannot say it's a strong lock. You can for example load an extension
library multiple times if you clear `$"`.

h4. `load`

`load` is a lot easier than `require`. Like `require`, it searches the
file in `$:`. But it can only load Ruby programs. Furthermore, the
extension cannot be omitted: the complete file name must always be
given.

<pre class="emlist">
load 'uri.rb'   # load the URI library that is part of the standard library
</pre>

In this simple example we try to load a library, but the proper way to
use `load` is for example to load a resource file giving its full
path.

h3. Flow of the whole process

If we roughly split it, "loading a file" can be split in:

* finding the file
* reading the file and mapping it to an internal form
* evaluating it

The only difference between `require` and `load` is how to find the
file. The rest is the same in both.

We will develop the last evaluation part a little more. Loaded Ruby
programs are basically evaluated at the top-level. It means the
defined constants will be top-level constants and the defined methods
will be function-style methods.

<pre class="emlist">
### mylib.rb
MY_OBJECT = Object.new
def my_p(obj)
  p obj
end

### first.rb
require 'mylib'
my_p MY_OBJECT   # we can use the constants and methods defined in an other file
</pre>

Only the local variable scope of the top-level changes when the file
changes. In other words, local variables cannot be shared between
different files. You can of course share them using for example `Proc`
but this has nothing to do with the load mechanism.

Some people also misunderstand the loading mechanism. Whatever the
class you are in when you call `load`, it does not change
anything. Even if, like in the following example, you load a file in
the `module` statement, it does not serve any purpose, as everything
that is at the top-level of the loaded file is put at the Ruby
top-level.

<pre class="emlist">
require 'mylib'     # whatever the place you require from, be it at the top-level
module SandBox
  require 'mylib'   # or in a module, the result is the same
end
</pre>

h3. Highlights of this chapter

Here the mechanism is a lot about details, so it's a little difficult
to enumerate it simply. That's why we will work a little differently
on it, and we are going to reduce the target to 3 points:

* loading serialisation
* the repartition of the functions in the different source files
* how extension libraries are loaded

Regarding the first point, you will understand it when you see it.

For the second point, the functions that appear in this chapter come
from 4 different files, `eval.c ruby.c file.c dln.c`.  We'll look at
the reason they are stretched in different places.

The third point is just like its name says. We will see how works the
currently popular trend of execution time loading, more commonly
referred to as plug-ins. This is the most important part of this
chapter so I'd like to use as many pages as possible to talk about it.

h2. Searching the library

h3. `rb_f_require()`

The body of `require` is `rb_f_require`. First, we will only look at
the part concerning the file search. Having many different cases is
bothersome so we will limit ourselves to the case when no file
extension is given.

▼ `rb_f_require()` (simplified version)
<pre class="longlist">
5527  VALUE
5528  rb_f_require(obj, fname)
5529      VALUE obj, fname;
5530  {
5531      VALUE feature, tmp;
5532      char *ext, *ftptr; /* OK */
5533      int state;
5534      volatile int safe = ruby_safe_level;
5535
5536      SafeStringValue(fname);
5537      ext = strrchr(RSTRING(fname)->ptr, '.');
5538      if (ext) {
              /* ...if the file extension has been given... */
5584      }
5585      tmp = fname;
5586      switch (rb_find_file_ext(&tmp, loadable_ext)) {
5587        case 0:
5588          break;
5589
5590        case 1:
5591          feature = fname = tmp;
5592          goto load_rb;
5593
5594        default:
5595          feature = tmp;
5596          fname = rb_find_file(tmp);
5597          goto load_dyna;
5598      }
5599      if (rb_feature_p(RSTRING(fname)->ptr, Qfalse))
5600          return Qfalse;
5601      rb_raise(rb_eLoadError, "No such file to load -- %s",
                   RSTRING(fname)->ptr);
5602
5603    load_dyna:
          /* ...load an extension library... */
5623      return Qtrue;
5624
5625    load_rb:
          /* ...load a Ruby program... */
5648      return Qtrue;
5649  }

5491  static const char *const loadable_ext[] = {
5492      ".rb", DLEXT,    /* DLEXT=".so", ".dll", ".bundle"... */
5493  #ifdef DLEXT2
5494      DLEXT2,          /* DLEXT2=".dll" on Cygwin, MinGW */
5495  #endif
5496      0
5497  };

(eval.c)
</pre>

In this function the `goto` labels `load_rb` and `load_dyna` are
actually like subroutines, and the two variables `feature` and `fname`
are more or less their parameters. These variables have the following
meaning.

|variable|meaning|example|
|`feature`|the library file name that will be put in `$"`|`uri.rb`、`nkf.so`|
|`fname`|the full path to the library|`/usr/lib/ruby/1.7/uri.rb`|

The name `feature` can be found in the function `rb_feature_p()`. This
function checks if a file has been locked (we will look at it just
after).

The functions actually searching for the library are `rb_find_file()`
and `rb_find_file_ext()`. `rb_find_file()` searches a file in the load
path `$'`. `rb_find_file_ext()` does the same but the difference is
that it takes as a second parameter a list of extensions
(i.e. `loadable_ext`) and tries them in sequential order.

Below we will first look entirely at the file searching code, then we
will look at the code of the `require` lock in `load_rb`.

h3. `rb_find_file()`

First the file search continues in `rb_find_file()`. This function
searches the file `path` in the global load path `$'`
(`rb_load_path`). The string contamination check is tiresome so we'll
only look at the main part.

▼ `rb_find_file()` (simplified version)
<pre class="longlist">
2494  VALUE
2495  rb_find_file(path)
2496      VALUE path;
2497  {
2498      VALUE tmp;
2499      char *f = RSTRING(path)->ptr;
2500      char *lpath;

2530      if (rb_load_path) {
2531          long i;
2532
2533          Check_Type(rb_load_path, T_ARRAY);
2534          tmp = rb_ary_new();
2535          for (i=0;i<RARRAY(rb_load_path)->len;i++) {
2536              VALUE str = RARRAY(rb_load_path)->ptr[i];
2537              SafeStringValue(str);
2538              if (RSTRING(str)->len > 0) {
2539                  rb_ary_push(tmp, str);
2540              }
2541          }
2542          tmp = rb_ary_join(tmp, rb_str_new2(PATH_SEP));
2543          if (RSTRING(tmp)->len == 0) {
2544              lpath = 0;
2545          }
2546          else {
2547              lpath = RSTRING(tmp)->ptr;
2551          }
2552      }

2560      f = dln_find_file(f, lpath);
2561      if (file_load_ok(f)) {
2562          return rb_str_new2(f);
2563      }
2564      return 0;
2565  }

(file.c)
</pre>

If we write what happens in Ruby we get the following:

<pre class="emlist">
tmp = []                     # make an array
$:.each do |path|            # repeat on each element of the load path
  tmp.push path if path.length > 0 # check the path and push it
end
lpath = tmp.join(PATH_SEP)   # concatenate all elements in one string separated by PATH_SEP

dln_find_file(f, lpath)      # main processing
</pre>

`PATH_SEP` is the `path separator`: `':'` under UNIX, `';'` under
Windows. `rb_ary_join()` creates a string by putting it between the
different elements. In other words, the load path that had become an
array is back to a string with a separator.

Why? It's only because `dln_find_file()` takes the paths as a string
with `PATH_SEP` as a separator. But why is `dln_find_file()`
implemented like that? It's just because `dln.c` is not a library for
`ruby`. Even if it has been written by the same author, it's a general
purpose library. That's precisely for this reason that when I sorted
the files by category in the Introduction I put this file in the
Utility category. General purpose libraries cannot receive Ruby
objects as parameters or read `ruby` global variables.

`dln_find_file()` also expands for example `~` to the home directory,
but in fact this is already done in the omitted part of
`rb_find_file()`. So in `ruby`'s case it's not necessary.

h3. Loading wait

Here, file search is finished quickly. Then comes is the loading
code. Or more accurately, it is "up to just before the load". The code
of `rb_f_require()`'s `load_rb` has been put below.

▼ `rb_f_require():load_rb`
<pre class="longlist">
5625    load_rb:
5626      if (rb_feature_p(RSTRING(feature)->ptr, Qtrue))
5627          return Qfalse;
5628      ruby_safe_level = 0;
5629      rb_provide_feature(feature);
5630      /* the loading of Ruby programs is serialised */
5631      if (!loading_tbl) {
5632          loading_tbl = st_init_strtable();
5633      }
5634      /* partial state */
5635      ftptr = ruby_strdup(RSTRING(feature)->ptr);
5636      st_insert(loading_tbl, ftptr, curr_thread);
          /* ...load the Ruby program and evaluate it... */
5643      st_delete(loading_tbl, &ftptr, 0); /* loading done */
5644      free(ftptr);
5645      ruby_safe_level = safe;

(eval.c)
</pre>

Like mentioned above, `rb_feature_p()` checks if a lock has been put
in `$"`. And `rb_provide_feature()` pushes a string in `$"`, in other
words locks the file.

The problem comes after. Like the comment says "the loading of Ruby
programs is serialised". In other words, a file can only be loaded
from one thread, and if during the loading a thread tries to load the
same file, that thread will wait for the first loading to be finished.
If it were not the case:

<pre class="emlist">
Thread.fork {
    require 'foo'   # At the beginning of require, foo.rb is added to $"
}                   # However the thread changes during the evaluation of foo.rb
require 'foo'   # foo.rb is already in $" so the function returns immediately
# (A) the classes of foo are used...
</pre>

By doing something like this, even though the `foo` library is not
really loaded, the code at (A) ends up being executed.

The process to enter the waiting state is simple. A `st_table` is
created in `loading_tbl`, the association "`feature=>`waiting thread"
is recorded in it. `curr_thread` is in `eval.c`'s functions, its value
is the current running thread.

The mechanism to enter the waiting state is very simple. A `st_table`
is created in the `loading_tbl` global variable, and a
"`feature`=>`loading thread`" association is created. `curr_thread` is
a variable from `eval.c`, and its value is the currently running
thread.  That makes an exclusive lock. And in `rb_feature_p()`, we
wait for the loading thread to end like the following.

▼ `rb_feature_p()` (second half)
<pre class="longlist">
5477  rb_thread_t th;
5478
5479  while (st_lookup(loading_tbl, f, &th)) {
5480      if (th == curr_thread) {
5481          return Qtrue;
5482      }
5483      CHECK_INTS;
5484      rb_thread_schedule();
5485  }

(eval.c)
</pre>

When `rb_thread_schedule()` is called, the control is transferred to
an other thread, and this function only returns after the control
returned back to the thread where it was called. When the file name
disappears from `loading_tbl`, the loading is finished so the function
can end. The `curr_thread` check is not to lock itself (figure 1).

!images/ch_load_loadwait.png(Serialisation of loads)!

h2. Loading of Ruby programs

h3. `rb_load()`

We will now look at the loading process itself. Let's start by the
part inside `rb_f_require()`'s `load_rb` loading Ruby programs.

▼ `rb_f_require()-load_rb-` loading
<pre class="longlist">
5638      PUSH_TAG(PROT_NONE);
5639      if ((state = EXEC_TAG()) == 0) {
5640          rb_load(fname, 0);
5641      }
5642      POP_TAG();

(eval.c)
</pre>

Here the `rb_load()` that is called is in fact the real form of the
Ruby level load. 

さてここで呼んでいる`rb_load()`、これは実はRubyレベルの`load`の実体である。
ということは探索がもう一回必要になるわけで、同じ作業をもう一回見るなん
てやっていられない。そこでその部分は以下では省略してある。
また第二引数の`wrap`も、上記の呼び出しコードで0なので、0で畳み込んである。

▼ `rb_load()` (simplified edition)
<pre class="longlist">
void
rb_load(fname, /* wrap=0 */)
    VALUE fname;
{
    int state;
    volatile ID last_func;
    volatile VALUE wrapper = 0;
    volatile VALUE self = ruby_top_self;
    NODE *saved_cref = ruby_cref;

    PUSH_VARS();
    PUSH_CLASS();
    ruby_class = rb_cObject;
    ruby_cref = top_cref;           /* (A-1) CREFを変える */
    wrapper = ruby_wrapper;
    ruby_wrapper = 0;
    PUSH_FRAME();
    ruby_frame->last_func = 0;
    ruby_frame->last_class = 0;
    ruby_frame->self = self;        /* (A-2) ruby_frame->cbaseを変える */
    ruby_frame->cbase = (VALUE)rb_node_newnode(NODE_CREF,ruby_class,0,0);
    PUSH_SCOPE();
    /* at the top-level the visibility is private by default */
    SCOPE_SET(SCOPE_PRIVATE);
    PUSH_TAG(PROT_NONE);
    ruby_errinfo = Qnil;  /* make sure it's nil */
    state = EXEC_TAG();
    last_func = ruby_frame->last_func;
    if (state == 0) {
        NODE *node;

        /* (B)なぜかevalと同じ扱い */
        ruby_in_eval++;
        rb_load_file(RSTRING(fname)->ptr);
        ruby_in_eval--;
        node = ruby_eval_tree;
        if (ruby_nerrs == 0) {   /* no parse error occurred */
            eval_node(self, node);
        }
    }
    ruby_frame->last_func = last_func;
    POP_TAG();
    ruby_cref = saved_cref;
    POP_SCOPE();
    POP_FRAME();
    POP_CLASS();
    POP_VARS();
    ruby_wrapper = wrapper;
    if (ruby_nerrs > 0) {   /* a parse error occurred */
        ruby_nerrs = 0;
        rb_exc_raise(ruby_errinfo);
    }
    if (state) jump_tag_but_local_jump(state);
    if (!NIL_P(ruby_errinfo))   /* an exception was raised during the loading */
        rb_exc_raise(ruby_errinfo);
}
</pre>

やっとスタック操作の嵐から抜けられたと思った瞬間また突入するというのも
精神的に苦しいものがあるが、気を取りなおして読んでいこう。

長い関数の常で、コードのほとんどがイディオムで占められている。
`PUSH`/`POP`、タグプロテクトと再ジャンプ。その中でも注目したいのは
(A)の`CREF`関係だ。ロードしたプログラムは常にトップレベル上で
実行されるので、`ruby_cref`を(プッシュではなく)退避し`top_cref`に戻す。
`ruby_frame->cbase`も新しいものにしている。

それともう一ヶ所、(B)でなぜか`ruby_in_eval`をオンにしている。そもそも
この変数はいったい何に影響するのか調べてみると、`rb_compile_error()`とい
う関数だけのようだ。`ruby_in_eval`が真のときは例外オブジェクトにメッセージを
保存、そうでないときは`stderr`にメッセージを出力、となっている。つまりコ
マンドのメインプログラムのパースエラーのときはいきなり`stderr`に出力した
いのだが評価器の中ではそれはまずいので止める、という仕組みらしい。すると
`ruby_in_eval`のevalはメソッド`eval`や関数`eval()`ではなくて一般動詞の
evaluateか、はたまた`eval.c`のことを指すのかもしれない。

h3. `rb_load_file()`

ここでソースファイルは突然`ruby.c`へと移る。と言うよりも実際のところは
こうではないだろうか。即ち、ロード関係のファイルは本来`ruby.c`に置きたい。
しかし`rb_load()`では`PUSH_TAG()`などを使わざるを得ない。だから仕方なく
`eval.c`に置く。でなければ最初から全部`eval.c`に置くだろう。

それで、`rb_load_file()`だ。

▼ `rb_load_file()`
<pre class="longlist">
 865  void
 866  rb_load_file(fname)
 867      char *fname;
 868  {
 869      load_file(fname, 0);
 870  }

(ruby.c)
</pre>

まるごと委譲。`load_file()`の第二引数`script`は真偽値で、`ruby`コマンドの
引数のファイルをロードしているのかどうかを示す。今はそうではなく
ライブラリのロードと考えたいので`script=0`で疊み込もう。
さらに以下では意味も考え本質的でないものを削ってある。

▼ `load_file()` (simplified edition)
<pre class="longlist">
static void
load_file(fname, /* script=0 */)
    char *fname;
{
    VALUE f;
    {
        FILE *fp = fopen(fname, "r");   (A)
        if (fp == NULL) {
            rb_load_fail(fname);
        }
        fclose(fp);
    }
    f = rb_file_open(fname, "r");       (B)
    rb_compile_file(fname, f, 1);       (C)
    rb_io_close(f);
}
</pre>

(A) In practice, the try to open using `fopen()` is to check if the
file can be opened. If there is no problem, it's immediately closed.
It may seem a little useless but it's an extremely simple and yet
highly portable and reliable way to do it.

(B) The file is opened once again, this time using the Ruby level
library `File.open`. The file was not opened with `File.open` from the
beginning not to raise any Ruby exception if the file cannot be
opened.  Here if any exception occurred we would like to have a
loading error, but getting the errors related to `open`, for example
`Errno::ENOENT`, `Errno::EACCESS`..., would be problematic. We are in
`ruby.c` so we cannot stop a tag jump.

(C) Using the parser interface `rb_compile_file()`, the program is
read from an `IO` object, and compiled in a syntax tree. The syntax
tree is added to `ruby_eval_tree` so there is no need to get the
result.

That's all for the loading code. Finally, the calls were quite deep so
let's look at the callgraph of `rb_f_require()` bellow.

<pre class="emlist">
rb_f_require           ....eval.c
    rb_find_file            ....file.c
        dln_find_file           ....dln.c
            dln_find_file_1
    rb_load
        rb_load_file            ....ruby.c
            load_file
                rb_compile_file     ....parse.y
        eval_node
</pre>

We've seen a lot of callgraphs, they are now common sense.

h4. The number of `open` required for loading

Like we've seen before, there are `open` used just to check if a file
can be open, but in fact during the loading process other functions
like for example `rb_find_file_ext()` also do checks using `open`. How
many times is `open()` called in the whole process?

と思ったら実際に数えてみるのが正しいプログラマのありかただ。システムコー
ルトレーサを使えば簡単に数えられる。そのためのツールはLinuxなら
`strace`、Solarisなら`truss`、BSD系なら`ktrace`か`truss`、
というように
OSによって名前がてんでバラバラなのだが、Googleで検索すればすぐ見付かる
はずだ。WindowsならたいていIDEにトレーサが付いている。

Well, as my main environment is Linux, I looked using `strace`.
The output is done on `stderr` so it was redirected using `2>&1`.

<pre class="screen">
% strace ruby -e 'require "rational"' 2>&1 | grep '^open'
open("/etc/ld.so.preload", O_RDONLY)    = -1 ENOENT
open("/etc/ld.so.cache", O_RDONLY)      = 3
open("/usr/lib/libruby-1.7.so.1.7", O_RDONLY) = 3
open("/lib/libdl.so.2", O_RDONLY)       = 3
open("/lib/libcrypt.so.1", O_RDONLY)    = 3
open("/lib/libc.so.6", O_RDONLY)        = 3
open("/usr/lib/ruby/1.7/rational.rb", O_RDONLY|O_LARGEFILE) = 3
open("/usr/lib/ruby/1.7/rational.rb", O_RDONLY|O_LARGEFILE) = 3
open("/usr/lib/ruby/1.7/rational.rb", O_RDONLY|O_LARGEFILE) = 3
open("/usr/lib/ruby/1.7/rational.rb", O_RDONLY|O_LARGEFILE) = 3
</pre>

`libc.so.6`の`open`まではダイナミックリンクの実装で使っている`open`なので
残りの`open`は計四回。つまり三回は無駄になっているようだ。

h2. Loading of extension libraries

h3. `rb_f_require()`-`load_dyna`

This time we will see the loading of extension libraries. We will
start with `rb_f_require()`'s `load_dyna`. However, we do not need the
part about locking anymore so it was removed.

▼ `rb_f_require()`-`load_dyna`
<pre class="longlist">
5607  {
5608      int volatile old_vmode = scope_vmode;
5609
5610      PUSH_TAG(PROT_NONE);
5611      if ((state = EXEC_TAG()) == 0) {
5612          void *handle;
5613
5614          SCOPE_SET(SCOPE_PUBLIC);
5615          handle = dln_load(RSTRING(fname)->ptr);
5616          rb_ary_push(ruby_dln_librefs, LONG2NUM((long)handle));
5617      }
5618      POP_TAG();
5619      SCOPE_SET(old_vmode);
5620  }
5621  if (state) JUMP_TAG(state);

(eval.c)
</pre>

もはやほとんど目新しいものはない。タグはイディオム通りの使いかた
しかしていないし、可視性スコープの退避・復帰も見慣れた手法だ。
残るのは`dln_load()`だけである。これはいったい何をしているのだろう。
というところで次に続く。

h3. リンクについて復習

`dln_load()`は拡張ライブラリをロードしているわけだが、拡張ライブラリを
ロードするとはどういうことなのだろうか。それを話すにはまず話を思い切り
物理世界方向に巻き戻し、リンクのことから始めなければならない。

Cのプログラムをコンパイルしたことはもちろんあると思う。筆者は
Linuxで`gcc`を使っているので、次のようにすれば動くプログラムが
作成できる。

<pre class="screen">
% gcc hello.c
</pre>

ファイル名からするときっとこれはHello, World!プログラムなんだろう。
`gcc`はUNIXではデフォルトで`a.out`というファイルにプログラムを
出力するので続いて次のように実行できる。

<pre class="screen">
% ./a.out
Hello, World!
</pre>

ちゃんとできている。

ところで、いま`gcc`は実際には何をしたのだろうか。普段はコンパイル、
コンパイルと言うことが多いが、実際には

# プリプロセス(`cpp`)
# C言語をアセンブラにコンパイル(`cc`)
# アセンブラを機械語にアセンブル(`as`)
# リンク(`ld`)

という四つの段階を通っている。このうちプリプロセス・コンパイル・アセン
ブルまではいろいろなところで説明を見掛けるのだが、なぜかリンクの段階だ
けは明文化されずに終わることが多いようだ。学校の歴史の授業では絶対に
「現代」まで行き着かない、というのと同じようなものだろうか。そこで本書
ではその断絶を埋めるべく、まずリンクとは何なのか簡単にまとめておくこと
にする。

アセンブルまでの段階が完了したプログラムはなんらかの形式の
「オブジェクトファイル」
になっている。そのような形式でメジャーなものには以下のよう
なものがある。

* ELF, Executable and Linking Format(新しめのUNIX)
* `a.out`, assembler output(比較的古いUNIX)
* COFF, Common Object File Format(Win32)

念のため言っておくが、オブジェクトファイル形式の`a.out`と`cc`の
デフォルト出力ファイル名の`a.out`は全然別物である。例えば今時のLinuxで
普通に作ればELF形式のファイル`a.out`ができる。

それで、このオブジェクトファイル形式がどう違うのか、という話はこのさい
どうでもいい。今認識しなければならないのは、これらのオブジェクトファイ
ルはどれも「名前の集合」と考えられるということだ。例えばこのファイルに
存在する関数名や変数名など。

またオブジェクトファイルに含まれる名前の集合には二種類がある。即ち

* 必要な名前の集合(例えば内部から呼んでいる外部関数。例:`printf`)
* 提供する名前の集合(例えば内部で定義している関数。例:`hello`)

である。そしてリンクとは、複数のオブジェクトファイルを集めてきたときに
全てのオブジェクトファイルの「必要な名前の集合」が「提供する名前の集合」
の中に含まれることを確認し、かつ互いに結び付けることだ。つまり全ての
「必要な名前」から線をひっぱって、どこかのオブジェクトファイルが「提供
する名前」につなげられるようにしなければいけない(図2)。
このことを用語を使って
言えば、未定義シンボルを解決する(resolving undefined symbol)、となる。

!images/ch_load_link.png(オブジェクトファイルとリンク)!

論理的にはそういうことだが、現実にはそれだけではプログラムは走らないわ
けだ。少なくともCのプログラムは走らない。名前をアドレス(数)に変換し
てもらわなければ動けないからだ。

そこで論理的な結合の次には物理的な結合が必要になる。オブジェクトファイ
ルを現実のメモリ空間にマップし、全ての名前を数で置き換えないといけない。
具体的に言えば関数呼び出し時のジャンプ先アドレスを調節したりする。

そしてこの二つの結合をいつやるかによってリンクは二種類に分かれる。即ち
スタティックリンクとダイナミックリンクである。スタティックリンクはコン
パイル時に全段階を終了してしまう。一方ダイナミックリンクは結合のうちい
くらかをプログラムの実行時まで遅らせる。そしてプログラムの実行時になっ
て初めてリンクが完了する。

もっともここで説明したのは非常に単純な理想的モデルであって現実をかなり
歪曲している面がある。論理結合と物理結合はそんなにキッパリ分かれるもの
ではないし、「オブジェクトファイルは名前の集合」というのもナイーブに過
ぎる。しかしなにしろこのあたりはプラットフォームによってあまりに動作が
違いすぎるので、真面目に話していたら本がもう一冊書けてしまう。
現実レベルの知識を得るためにはさらに
『エキスパートCプログラミング』\footnote{『エキスパートCプログラミング』Peter van der Linden著、梅原系訳、アスキー出版局、1996}
『Linkers&amp;Loaders』@footnote{『Linkers&amp;Loaders』John R.Levine著、榊原一矢監訳 ポジティブエッジ訳、オーム社、2001}
あたりも読んでおくとよい。

h3. 真にダイナミックなリンク

さてそろそろ本題に入ろう。ダイナミックリンクの「ダイナミック」は当然
「実行時にやる」という意味だが、普通に言うところのダイナミックリンクだ
と実はコンパイル時にかなりの部分が決まっている。例えば必要な関数の名前
は決まっているだろうし、それがどこのライブラリにあるかということももう
わかっている。例えば`cos()`なら`libm`にあるから`gcc -lm`という
感じでリ
ンクするわけだ。コンパイル時にそれを指定しなかったらリンクエラーになる。

しかし拡張ライブラリの場合は違う。必要な関数の名前も、リンクするライブ
ラリの名前すらもコンパイル時には決まっていない。文字列をプログラムの実
行中に組み立ててロード・リンクしなければいけないのである。つまり先程の
言葉で言う「論理結合」すらも全て実行時に行わなければならない。そのため
には普通に言うところのダイナミックリンクとはまた少し違う仕組みが必要に
なる。

この操作、つまり実行時に全てを決めるリンク、のことを普通は
「動的ロード(dynamic load)」と呼ぶ。本書の用語遣いからいくと
「ダイナミックロード」と片仮名にひらくべきなのだろうが、
ダイナミックリンクと
ダイナミックロードだと紛らわしいのであえて漢字で「動的ロード」とする。

h3. 動的ロードAPI

概念の説明は以上だ。あとはその動的ロードをどうやればいいかである。とは
言っても難しいことはなくて、普通はシステムに専用APIが用意されているの
でこちらは単にそれを呼べばいい。

例えばUNIXならわりと広範囲にあるのが`dlopen`というAPIである。ただし
「UNIXならある」とまでは言えない。例えばちょっと前のHP-UXには全く違う
インターフェイスがあるしMac OS XだとNeXT風のAPIを使う。また同じ
`dlopen`でもBSD系だと`libc`にあるのにLinuxだと`libdl`として外付けになっ
ている、などなど、壮絶なまでに移植性がない。いちおうUNIX系と並び称され
ていてもこれだけ違うわけだから、他のOSになれば全然違うのもあたりまえで
ある。同じAPIが使われていることはまずありえない。

そこで`ruby`はどうしているかというと、その全然違うインターフェイスを吸収
するために`dln.c`というファイルを用意している。`dln`はdynamic linkの略だろ
う。`dln_load()`はその`dln.c`の関数の一つなのである。

そんなふうに全くバラバラの動的ロードAPIだが、せめてもの救
いはAPIの使用パターンが全く同じだということだ。どのプラットフォームだ
ろうと

# ライブラリをプロセスのアドレス空間にマップする
# ライブラリに含まれる関数へのポインタを取る
# ライブラリをアンマップ

という三段階で構成されている。例えば`dlopen`系APIならば

# `dlopen`
# `dlsym`
# `dlclose`

が対応する。Win32 APIならば

# `LoadLibrary`(または`LoadLibraryEx`)
# `GetProcAddress`
# `FreeLibrary`

が対応する。

最後に、このAPI群を使って`dln_load()`が何をするかを話そう。これが実は、
`Init_xxxx()`の呼び出しなのだ。ここに至ってついに`ruby`起動から終了までの全
過程が欠落なく描けるようになる。即ち、`ruby`は起動すると評価器を初期化し
なんらかの方法で受け取ったメインプログラムの評価を開始する。その途中で
`require`か`load`が起こるとライブラリをロードし制御を移す。制御を移す、と
は、Rubyライブラリならばパースして評価することであり、拡張ライブラリな
らばロード・リンクして`Init_xxxx()`を呼ぶことである。

h3. `dln_load()`

ようやく`dln_load()`の中身にたどりつけた。`dln_load()`も長い関数だが、これ
また理由があって構造は単純である。まず概形を見てほしい。

▼ `dln_load()`(概形)
<pre class="longlist">
void*
dln_load(file)
    const char *file;
{
#if defined _WIN32 && !defined __CYGWIN__
    Win32 APIでロード
#else
    プラットフォーム独立の初期化
#ifdef 各プラットフォーム
    ……プラットフォームごとのルーチン……
#endif
#endif
#if !defined(_AIX) && !defined(NeXT)
  failed:
    rb_loaderror("%s - %s", error, file);
#endif
    return 0;                   /* dummy return */
}
</pre>

このようにメインとなる部分がプラットフォームごとに完璧に分離しているため、
考えるときは一つ一つのプラットフォームのことだけを考えていればいい。
サポートされているAPIは以下の通りだ。

* `dlopen`(多くのUNIX)
* `LoadLibrary`(Win32)
* `shl_load`(少し古いHP-UX)
* `a.out`(かなり古いUNIX)
* `rld_load`(`NeXT4`未満)
* `dyld`(`NeXT`またはMac OS X)
* `get_image_symbol`(BeOS)
* `GetDiskFragment`(Mac OS 9以前)
* `load`(少し古いAIX)

h3. `dln_load()`-`dlopen()`

まず`dlopen`系のAPIのコードから行こう。

▼ `dln_load()`-`dlopen()`
<pre class="longlist">
1254  void*
1255  dln_load(file)
1256      const char *file;
1257  {
1259      const char *error = 0;
1260  #define DLN_ERROR() (error = dln_strerror(),\
                           strcpy(ALLOCA_N(char, strlen(error) + 1), error))
1298      char *buf;
1299      /* Init_xxxxという文字列をbufに書き込む(領域はalloca割り当て) */
1300      init_funcname(&buf, file);

1304      {
1305          void *handle;
1306          void (*init_fct)();
1307
1308  #ifndef RTLD_LAZY
1309  # define RTLD_LAZY 1
1310  #endif
1311  #ifndef RTLD_GLOBAL
1312  # define RTLD_GLOBAL 0
1313  #endif
1314
1315          /* (A)ライブラリをロード */
1316          if ((handle = (void*)dlopen(file, RTLD_LAZY | RTLD_GLOBAL))
                                                                 == NULL) {
1317              error = dln_strerror();
1318              goto failed;
1319          }
1320
              /* (B)Init_xxxx()へのポインタを取る */
1321          init_fct = (void(*)())dlsym(handle, buf);
1322          if (init_fct == NULL) {
1323              error = DLN_ERROR();
1324              dlclose(handle);
1325              goto failed;
1326          }
1327          /* (C)Init_xxxx()を呼ぶ */
1328          (*init_fct)();
1329
1330          return handle;
1331      }

1576    failed:
1577      rb_loaderror("%s - %s", error, file);
1580  }

(dln.c)
</pre>

(A)`dlopen()`の引数の`RTLD_LAZY`は「実際に関数を要求したときに
未解決シンボルを解決する」ことを示す。返り値はライブラリを識別する
ための印(ハンドル)で、`dl*()`には常にこれを渡さないといけない。

(B)`dlsym()`はハンドルの示すライブラリから関数ポインタを取る。返り値が
`NULL`なら失敗だ。ここで`Init_xxxx()`へのポインタを取り、呼ぶ。

`dlclose()`の呼び出しはない。`Init_xxxx()`の中でロードした
ライブラリの関数ポインタを
返したりしているはずだが、`dlclose()`するとライブラリ全体が使えなくなって
しまうのでまずいのだ。つまりプロセスが終了するまで`dlclose()`は呼べない。

h3. `dln_load()`-Win32

Win32では`LoadLibrary()`と`GetProcAddress()`を使う。
MSDNにも載っているごく一般的なWin32 APIである。

▼ `dln_load()`-Win32
<pre class="longlist">
1254  void*
1255  dln_load(file)
1256      const char *file;
1257  {

1264      HINSTANCE handle;
1265      char winfile[MAXPATHLEN];
1266      void (*init_fct)();
1267      char *buf;
1268
1269      if (strlen(file) >= MAXPATHLEN) rb_loaderror("filename too long");
1270
1271      /* "Init_xxxx"という文字列をbufに書き込む(領域はalloca割り当て) */
1272      init_funcname(&buf, file);
1273
1274      strcpy(winfile, file);
1275
1276      /* ライブラリをロード */
1277      if ((handle = LoadLibrary(winfile)) == NULL) {
1278          error = dln_strerror();
1279          goto failed;
1280      }
1281
1282      if ((init_fct = (void(*)())GetProcAddress(handle, buf)) == NULL) {
1283          rb_loaderror("%s - %s\n%s", dln_strerror(), buf, file);
1284      }
1285
1286      /* Init_xxxx()を呼ぶ */
1287      (*init_fct)();
1288      return handle;

1576    failed:
1577      rb_loaderror("%s - %s", error, file);
1580  }

(dln.c)
</pre>

`LoadLibrary()`して`GetProcAddress()`。ここまでパターンが同じだと
言うこともないので、終わってしまうことにしよう。

