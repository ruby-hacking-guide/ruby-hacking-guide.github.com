$comment(-*- coding: utf-8 -*- vim:set encoding=utf-8:)$
Translated by Clifford Escobar CAOILE

h1. Chapter 7: Security

h3. Fundamentals

I say security but I don't mean passwords or encryption. The Ruby security
feature is used for handling untrusted objects in a environment like CGI
programming.

For example, when you want to convert a string representing a number into a
integer, you can use the `eval` method. However. `eval` is a method that "runs
a string as a Ruby program." If you `eval` a string from a unknown person from
the network, it is very dangerous. However for the programmer to fully
differentiate between safe and unsafe things is very tiresome and cumbersome.
Therefore, it is for certain that a mistake will be made. So, let us make it
part of the language, was reasoning for this feature.

So then, how Ruby protect us from that sort of danger? Causes of dangerous
operations, for example, opening unintended files, are roughly divided into two
groups:

* Dangerous data
* Dangerous code

For the former, the code that handles these values is created by the
programmers themselves, so therefore it is (pretty) safe. For the latter, the
program code absolutely cannot be trusted.

Because for these causes the solution is vastly different, it is important to
differentiate them by level. This are called security levels. The Ruby security
level is represented by the `$SAFE` global variable. The value ranges from
minimum value 0 to maximum value 4. When the variable is assigned, the level
increases. Once the level is raised it can never be lowered. And for each
level, the operations are limited.

I will not explain level 1 or 3.
Level 0 is the normal program environment and the security system is not
running. Level 2 handles dangerous values. Level 4 handles dangerous code.
We can skip 0 and move on to explain in detail levels 2 and 4.

h4. Level 2

This level is for dangerous data, for example, in normal CGI
applications, etc.

A per-object "dirty mark" serves as the basis for the Level 2
implementation. All objects read in externally are marked dirty, and
any attempt to `eval` or `File.open` with a dirty object will cause an
exception to be raised and the attempt will be stopped.

This dirty mark is "infectious". For example, when taking a part of a
dirty string, that part is also dirty.

h4. Level 4

This level is for dangerous programs, for example, running external
(unknown) programs, etc.

At level 2, operations and the data it uses are checked, but at level
4, operations themselves are restricted. For example, `exit`, file
I/O, thread manipulation, redefining methods, etc. Of course, the
dirty mark information is used, but basically the operations are the
criteria.

h4. Unit of Security

`$SAFE` looks like a global variable but is in actuality a thread
local variable. In other words, Ruby's security system works on units
of thread. In Java and .NET, rights can be set per component (object),
but Ruby does not implement that. The assumed main target was probably
CGI.

Therefore, if one wants to raise the security level of one part of the
program, then it should be made into a different thread and have its
security level raised. I haven't yet explained how to create a thread,
but I will show an example here:

<pre class="emlist">
# Raise the security level in a different thread
p($SAFE)   # 0 is the default
Thread.fork {    # Start a different thread
    $SAFE = 4    # Raise the level 
    eval(str)    # Run the dangerous program
}
p($SAFE)   # Outside of the block, the level is still 0
</pre>

h4. Reliability of `$SAFE`

Even with implementing the spreading of dirty marks, or restricting
operations, ultimately it is still handled manually. In other words,
internal libraries and external libraries must be completely
compatible and if they don't, then the partway the "dirty" operations
will not spread and the security will be lost. And actually this kind
of hole is often reported. For this reason, this writer does not
wholly trust it.

That is not to say, of course, that all Ruby programs are dangerous.
Even at `$SAFE=0` it is possible to write a secure program, and even
at `$SAFE=4` it is possible to write a program that fits your whim.
However, one cannot put too much confidence on `$SAFE` (yet).

In the first place, functionality and security do not go together. It
is common sense that adding new features can make holes easier to
open. Therefore it is prudent to think that `ruby` can probably be
dangerous.

h3. 実装

ここからは実装に入るが、`ruby`のセキュリティシステムを完全に捉えるに
は仕組みよりもむしろ「どこをチェックしているのか」を見なければならない。
しかし今回それをやっているページはないし、いちいちリストアップするだけ
では面白くない。そこでとりあえずこの章ではセキュリティチェックに使わ
れる仕組みだけを解説して終えることにする。チェック用のAPIは主に以下の
二つだ。

* レベル n 以上なら例外`SecurityError`を発生する`rb_secure(n)`
* レベル1以上のとき、文字列が汚染されていたら例外を発生する`SafeStringValue()`

`SafeStringValue()`はここでは読まない。

h4. 汚染マーク

汚染マークとは具体的には`basic->flags`に記憶される
フラグ`FL_TAINT`で、
それを感染させるのは`OBJ_INFECT()`というマクロである。
このように使う。

<pre class="emlist">
OBJ_TAINT(obj)            /* objにFL_TAINTを付ける */
OBJ_TAINTED(obj)          /* objにFL_TAINTが付いているか調べる */
OBJ_INFECT(dest, src)     /* srcからdestにFL_TAINTを伝染させる */
</pre>

`OBJ_TAINT()`・`OBJ_TAINTED()`はどうでもいいとして、
`OBJ_INFECT()`だけさっと見よう。

▼ `OBJ_INFECT`
<pre class="longlist">
 441  #define OBJ_INFECT(x,s) do {                             \
          if (FL_ABLE(x) && FL_ABLE(s))                        \
              RBASIC(x)->flags |= RBASIC(s)->flags & FL_TAINT; \
      } while (0)

(ruby.h)
</pre>

`FL_ABLE()`は引数の`VALUE`がポインタであるかどうか調べる。
両方のオブジェクトがポインタなら(つまり`flags`メンバがあるなら)、
フラグを伝播する。

h4. `$SAFE`

▼ `ruby_safe_level`
<pre class="longlist">
 124  int ruby_safe_level = 0;

7401  static void
7402  safe_setter(val)
7403      VALUE val;
7404  {
7405      int level = NUM2INT(val);
7406
7407      if (level < ruby_safe_level) {
7408          rb_raise(rb_eSecurityError, "tried to downgrade safe level from %d to %d",
7409                   ruby_safe_level, level);
7410      }
7411      ruby_safe_level = level;
7412      curr_thread->safe = level;
7413  }

(eval.c)
</pre>

`$SAFE`の実体は`eval.c`の`ruby_safe_level`だ。先に書いたとおり
`$SAFE`は
スレッドに固有なので、スレッドの実装がある`eval.c`に書く必要があったからだ。
つまりC言語の都合で`eval.c`にあるだけで、本来は別の場所にあってよい。

`safe_setter()`はグローバル変数`$SAFE`の`setter`である。
つまりRubyレベルからはこの関数経由でしかアクセスできないので
レベルを下げることはできなくなる。

ただし見てのとおり`ruby_safe_level`には`static`が付いていないので
Cレベルからはインターフェイスを無視してセキュリティレベルを変更できる。

h4. `rb_secure()`

▼ `rb_secure()`
<pre class="longlist">
 136  void
 137  rb_secure(level)
 138      int level;
 139  {
 140      if (level <= ruby_safe_level) {
 141          rb_raise(rb_eSecurityError, "Insecure operation `%s' at level %d",
 142                   rb_id2name(ruby_frame->last_func), ruby_safe_level);
 143      }
 144  }

(eval.c)
</pre>

現在のセーフレベルが`level`以上だったら例外`SecurityError`を発生。簡単だ。

