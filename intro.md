* * * * *

layout: default\
—

Preface: Introduction\
h2. Characteristics of Ruby
===========================

Some of the readers may have already been familiar with Ruby, some may
be not.\
(I wish the latter for this chapter to be most useful) First let’s go
though a\
rough summary of the characteristics of Ruby for such people.

Hereafter capital “Ruby” refers to Ruby as a language scheme, and
lowercase\
“`ruby`” refers to the implementation of `ruby` command.

#### Development pattern

Ruby is a personally created language by Yukihiro Matsumoto. That means
Ruby\
doesn’t have a standard scheme that C or Java have. The specification is
merely\
shown as an implementation as `ruby`, and its varying continuously.
Whichever\
you mention good or bad, it’s unbind.

Furthermore `ruby` itself is a free software - source code being open
and\
being in public free of charge - this is what I must add in the
introduction.\
That’s why it allows the approach of this book into publication.

Giving the `README` and `LEGAL` included in the distribution package
the\
complete reading of the license, let’s list up what you can do for the
time\
being:

You can redistribute source code of `ruby`\
You can modify source code of `ruby`\
You can redistribute a copy of source code with your modification

There is no need for special permission and payment in all these cases.

By the way, the original `ruby` is the version referred to in this book
unless\
otherwise stated, because our main purpose is to read it. However, I
modified\
the code without notice at a certain extent such as to remove or add
white\
spaces, new lines, and comments.

#### It’s conservative

Ruby is a very conservative language. It is equipped with only carefully
chosen\
features that have been tested and washed out in a variety of
languages​.\
Therefore it doesn’t have plenty of fresh and experimental features very
much.\
So it has a tendency to appeal to programmers who put importance on
practical\
functionalities. The dyed-in-the-wool hackers like Scheme and Haskell
lovers\
don’t seem to find appeal in ruby in a short glance.

The library is conservative in the same way. Clear and unabbreviated
names are\
given for new functions, while names that appears in C and Perl
libraries have\
been took over from them. For example, `printf`, `getpwent`, `sub`, and
`tr`.

It is also conservative in implementation. Assembler is not its option
for\
seeking speed. Portability is always considered a higher priority when
it\
conflicts with speed.

#### It is an object-oriented language

Ruby is an object-oriented language. It is not possible to forget about
it\
absolutely, when you talk about the features of Ruby.

I will not give a page to this book about what an object-oriented
language is.\
To tell about an object-oriented feature about Ruby, the expression of
the code\
that just going to be explained below is the exact sample.

#### It is a script language

Ruby is a script language. It is also not possible to forget about it\
absolutely, when you talk about the features of Ruby. To gain agreement
of\
everyone, an introduction of Ruby must include “object-oriented” and
“script\
language”.

However, what is a “script language” for example? I couldn’t figure out
the\
definition successfully. For example, John K. Ousterhout, the author of
Tcl/Tk,\
gives a definition as “executable language using `#!` on UNIX”. There
are other\
definitions depending on the view points, such as one that can express a
useful\
program with only one line, or that can execute the code by passing a
program\
file from the command line, etc.

However, I dare to use another definition, because I don’t find much
interest\
in “what” a script language. To call it a script language, it at least
has to\
avoid gaining disagreement of calling it so. That’s the definition I
suggest.\
To fulfill this definition, I would define the meaning of “script
language” as\
follows.

Whether the author of the language calls it “script language” or not.

I’m sure this definition will have no failure. And Ruby fulfills this
point. \
Therefore I call Ruby a “script language”.

#### It’s an interpreter

`ruby` is an interpreter. That’s the fact. But why it’s an interpreter?
For\
example, couldn’t it be made as a compiler? The answer should be “no”,
because\
I guess Ruby has at least something better than being an interpreter
than a\
compiler. Well, what is good about being an interpreter?

As a preparation step to investigating into it, let’s start by thinking
about\
the difference between an interpreter and a compiler. If the matter is
to\
attempt a comparison with the process how a program is executed
theoretically,\
there’s no difference between an interpreter language and a compile
language.\
It may be possible to say that a compiler language involves an
interpreter,\
because of the fact that CPU “interprets” a code into a machine language
using\
a compiler. What’s the difference actually? I suppose it’s in a
practical\
things - in the process of development.

I know somebody, as soon as hearing “in the process of development”,
would\
claim using a stereotypical phrase, that an interpreter reduces effort
of\
compilation that makes the development procedure easier. But I don’t
think it’s\
accurate. A language could possibly be planned so that it won’t show
the\
process of compilation. Actually, Delphi can compile a project by
hitting just\
F5. A claim about a long time for compilation is derived from the size
of the\
project or optimization of the codes. Compilation itself doesn’t owe a
negative\
side.

Well, why people perceive an interpreter and compiler so much different
like\
this? I think that it is because the developers have long distinguished
the use\
of the implementations of these languages according to the
characteristics. In\
short, a comparatively small, a daily routine fits well with developing
an\
interpreter language. On the other hand, a compiler language is a goal
for a\
large project where a number of people are involved in the development
and\
accuracy is required. That may be because of the speed, as well as the\
readiness of creating a language.

Therefore, “it’s handy because it’s an interpreter” is merely an
outsized myth.\
Being an interpreter doesn’t necessarily contribute the readiness in
usage;\
seeking readiness in usage naturally makes your path toward building an\
interprer language.

Anyway, `ruby` is an interpreter; it has an important fact about where
this\
book is facing, so I emphasize it here again. It doesn’t matter whether
it’s\
easy being an interpreter; anyway `ruby` is implemented as an
interpreter.

#### High portability

Even with a fundamental problem that the interface is built targeting
Unix, I\
would insist `ruby` possesses a high portability. It doesn’t often
require an\
unfamiliar library. It doesn’t have a part written in assembler
gorigorily.\
Therefore it’s easy to port to a new platform, comparatively. Namely, it
works\
on the following platforms currently.

Linux\
Win32 (Windows 95, 98, Me, NT, 2000, XP)\
Cygwin\
djgpp\
FreeBSD\
NetBSD\
OpenBSD\
BSD/OS\
Mac OS X\
Solaris\
Tru64 UNIX\
HP-UX\
AIX\
VMS\
UX/4800\
BeOS\
OS/2 (emx)\
Psion

The main machine of the author Matsumoto is Linux, reportedly. You can
assume\
that a Linux will not fail to build any version of ruby.

Furthermore, a typical Unix environment basically can expect a stable\
functionality. Considering the release cycle of packages, the primary
option\
for the environment to hit around `ruby` should fall on a branch of PC
UNIX,\
 currently.

On the other hand, the Win32 environment tends to cause problems
definitely.\
The large gaps in the targeting OS model tend to cause problems around
the\
machine stack and the linker. Yet, recently Windows hackers have
contributed to\
make better support. I use a native ruby on Windows 2000 and Me. Once it
gets\
successfully run, it doesn’t seem to show special concerns like
frequent\
crashing. The main problems on Windows may be the gaps in the
specifications.

Another type of OS that many people may be interested in should probably
be Mac\
OS (prior to v9) and handheld OS like Palm.

Around `ruby 1.2` and before, it supported legacy Mac OS, but the
development\
seems to be in suspension. Even a compiling can’t get through. The
biggest\
cause is that the compiler environment of legacy Mac OS and the decrease
of\
developers. Talking about Mac OS X, there’s no worries because the body
is\
UNIX.

There seem to be discussions the portability to Palm several branches,
but I\
have never heard of a successful project. I guess the difficulty lies in
the\
necessity of settling down the specification-level standards such as
`stdio` on\
the Palm platform, rather than the processes of actual implementation.
Well I\
saw a porting to Psion has been done. ([ruby-list:36028]).

How about hot stories about VM seen in Java and .NET? I need to mention
these\
together with implementation in the final chapter.

#### Automatic memory control

Functionally it’s called GC, or Garbage Collection. Saying it in
C-language,\
this feature allows you to skip `free()` after `malloc()`. Unused memory
is\
detected by the system automatically, and will be released. It’s so
convenient\
that once you get used to GC you will likely be unwilling to do it
manual\
memory control again.

The topics about GC have been common because of its popularity in
recent\
languages with GC as a standard set, and the GS is fun to talk about
because it\
has a lot to devise better algorithms.

#### Typeless variables

The variables in Ruby don’t have types. The reason is probably typeless\
variables conforms more with polymorphism, which is one of the
strongest\
features of an object-oriented language. Of course a language with
variable\
type has a way to deal with polymorphism. What I mean here is a
typeless\
variables have better conformance.

The level of “better conformance” in this case refers to synonyms like
“handy”.\
It’s sometimes corresponds to crucial importance, sometimes it doesn’t
matter\
practically. Yet, this is certainly an appealing point if a language
seeks for\
“handy and easy”, and Ruby does.

#### Most of syntactic elements are expressions

This topic is probably difficult to understand it instantly without
needs\
supplemental explanation. For example, the following C-language program\
contains a syntactic error.

result = if (cond) { process(val); } else { 0; }\

</pre>
Because the C-language syntax defines `if` as a statement. See following
rewrite.

result = cond ? process(val) : 0;\

</pre>
This rewrite is possible because the conditional operator (`a?b:c`) is
defined\
as an expression.

On the other hand, Ruby acceps a following expression because `if` is an
expression.

result = if cond then process(val) else nil end\

</pre>
大雑把に言うと、関数やメソッドの引数にできるものは式だと思っていい。

もちろん「ほとんどの文法要素が式」という言語は他にもいろいろある。例えば\
Lispはその最たるものだ。このあたりの特徴からなんとなく「RubyはLispに似\
てる」と感じる人が多いようである。

#### イテレータ

Rubyにはイテレータがある。イテレータとは何か。いやその前にイテレータと\
いう言葉は最近嫌われているので別の言葉を使うべきかもしれない。だがい\
い言葉を思いつかないので当面イテレータと呼ぶことにする。

それでイテレータとは何か。高階の関数を知っているなら、とりあえずはそれ\
と似たようなものだと思っておけばいい。Cで言えば関数ポインタを引数\
に渡すやつである。C**で言えばSTLにある@Iterator@の操作部分までをメソッド\
に封入したものである。shやPerlを知っているのなら、独自に定義できる\
`for`文みたいなもんだと思って見てみるといい。

\
もっともあくまでここに挙げたのは全て「似たようなもの」であって、どれも\
Rubyのイテレータと似てはいるが、同じでは、全くない。いずれその時が来た\
らもう少し厳密な話をしよう。
\
h4. C言語で書いてある
\
Cで書いたプログラムなどいまどき珍しくもないが、特徴であることは間違い\
ない。少なくともHaskellやPL/Iで書いてあるわけではないので一般人にも\
読める可能性が高い（本当にそうかどうかはこれから自分で確かめてほしい）。

\
それからC言語と言っても@ruby@が対象としているのは基本的にK&R Cだ。\
少し前まではK&R
onlyの環境が、たくさんとは言わないが、それなりにあったからだ。\
しかしさすがに最近はANSI Cが通らない環境はなくなってきており技術的には\
ANSI Cに移っても特に問題はない。だが作者のまつもとさん個人の趣味もあっ\
てまだK&Rスタイルを通している。

\
そんなわけで関数定義は全てK&Rスタイルだし、プロトタイプ宣言もあまり真面\
目に書かれていない。@gcc@でうっかり`-Wall`を付けると大量に警告が出て\
くるとか、\
C**コンパイラでコンパイルするとプロトタイプが合わないと怒られてコンパ\
イルできない……なんて話がポロポロとメーリングリストに流れている。

#### 拡張ライブラリ

RubyのライブラリをCで書くことができ、Rubyを再コンパイルすることなく\
実行時にロードできる。このようなライブラリを「Ruby拡張ライブラリ」\
または単に「拡張ライブラリ」と言う。

単にCで書けるだけでなくRubyレベルとCレベルでのコードの表現の差が小さい\
のも大きな特徴である。Rubyで使える命令はほとんどそのままCでも使うこと\
ができる。例えば以下のように。

\# メソッド呼び出し\
obj.method(arg) \# Ruby\
rb\_funcall(obj, rb\_intern(“method”), 1, arg); \# C\
\# ブロック呼び出し\
yield arg \# Ruby\
rb\_yield(arg); \# C\
\# 例外送出\
raise ArgumentError, ‘wrong number of arguments’ \# Ruby\
rb\_raise(rb\_eArgError, “wrong number of arguments”); \# C\
\# オブジェクトの生成\
arr = Array.new \# Ruby\
VALUE arr = rb\_ary\_new(); \# C\

</pre>
拡張ライブラリを書くうえでは非常に楽をできていいし、現実に\
このことが代えがたい@ruby@の長所にもなっている。しかしそのぶん\
`ruby`の実装にとっては非常に重い足枷となっており、随所にその\
影響を見ることができる。特にGCやスレッドへの影響は顕著である。

#### スレッド

Rubyにはスレッドがある。さすがに最近はスレッドを知らない人はほとんどい\
ないと思うのでスレッド自体に関する説明は省略する。以下はもう少し細かい\
話だ。

`ruby`のスレッドはオリジナルのユーザレベルスレッドである。この実装の\
特徴は、仕様と実装、両方の移植性が非常に高いことである。なにしろDOS上で\
さえスレッドが動き、どこでも同じ挙動で使えるのだ。この点を@ruby@の最大の\
長所として挙げる人も多い。

しかし@ruby@スレッドは凄まじい移植性を実現した反面で速度をおもいきり犠牲\
にしている。どのくらい遅いかというと、世の中に数あるユーザレベルスレッ\
ドの実装の中でも一番遅いのではないか、というくらい遅い。これほど@ruby@の\
実装の傾向を明確に表しているところもないだろう。

ソースコードを読む技術
----------------------

さて。@ruby@の紹介も終わっていよいよソースコード読みに入ろうか、というと\
ころだが、ちょっと待ってほしい。

ソースコードを読む、というのはプログラマならば誰しもやらなければいけな\
いことだが、その具体的な方法を教えてもらえることはあまりないのではない\
だろうか。どうしてだろう。プログラムが書けるなら読むのも当然できるとい\
うのだろうか。

しかし筆者には人の書いたプログラムを読むことがそんなに簡単なことだとは\
思えない。プログラムを書くのと同じくらい、読むことにも技術や定石がある\
はずだし、必要だと考える。そこで@ruby@を読んでいく前にもう少し一般的に、\
ソースコードを読むにはどういう考えかたをすればいいのか、整理することに\
しよう。

### 原則

まずは原則について触れる。

#### 目的の決定\
bq. \
「ソースコードを読むための極意」は『目的をもって読む』ことです。

これはRuby作者のまつもとさんの言だ。なるほど、この言葉には非常にうなず\
けるものがある。「カーネルくらいは読んどかなきゃいかんかなあ」と思って\
ソースコードを展開したり解説本を買ったりしてはみたものの、いったいどう\
していいのかわからないまま放ってしまった、という経験のある人は多いので\
はないだろうか。その一方で、「このツールのどこかにバグがある、とにかく\
これを速攻で直して動かさないと納期に間に合わない」……というときには他\
人のプログラムだろうとなんだろうと瞬く間に直せてしまうこともあるのでは\
ないだろうか。

この二つのケースで違うのは、意識の持ちかたである。自分が何を知ろうと\
しているのかわからなければ「わかる」ことはありえない。だからまず自分が\
何を知りたいのか、それを明確に言葉にすることが全ての第一歩である。

だがこれだけではもちろん「技術」たりえない。「技術」とは、意識すれば誰に\
でもできるものでなければならないからだ。続いて、この第一歩から最終的に\
目的を達成するところまで敷衍する方法について延べる。

#### 目的の具体化

いま「@ruby@全部を理解する」を最終目標に決めたとしよう。これでも「目的を\
決めた」とは言えそうだが、しかし実際にソースコードを読む役に立たないこ\
とは明らかである。具体的な作業には何にもつながっていないからだ。従って\
まずはこの曖昧な目標を具体的なところまで引きずり下ろさなければならない。

どうすればいいだろうか。まず第一に、そのプログラムを書いた人間になった\
つもりで考えてみることだ。そのときにはプログラムを作るときの知識が流用\
できる。例えば伝統的な「構造化」プログラムを読むとしたら、こちらも\
構造化プログラムの手法に則って考えるようにする。即ち目的を徐々に徐々に分割\
していく。あるいはGUIプログラムのようにイベントループに入ってグルグル\
するものならば、とりあえず適当にイベントループを眺めてからイベントハン\
ドラの役割を調べてみる。あるいはMVC（Model View Controler）のMをまず調\
べてみる。

第二に解析の手法を意識することだ。誰しも自分なりの解析方法というのはそ\
れなりに持っていると思うが、それは経験と勘に頼って行われていることが多\
い。どうしたらうまくソースコードを読めるのか、そのこと自体を考え、意識\
することが非常に重要である。

ではそのような手法にはどんなものがあるだろうか。それを次に説明する。

### 解析の手法

ソースコードを読む手法は大雑把に言って静的な手法と動的な手法の二つに分\
類できる。静的な手法とはプログラムを動かさずソースコードを読んだり解析\
したりすること。動的な手法とはデバッガなどのツールを使って実際の動きを\
見ることだ。

プログラムを調査するときはまず動的な解析から始めたほうがよい。なぜなら\
それは「事実」だからだ。静的な解析では現実にプログラムを動かしていない\
のでその結果は多かれ少なかれ「予想」になってしまう。真実を知りたいのな\
らばまず事実から始めるべきなのだ。

もちろん動的な解析の結果が本当に事実であるかどうかはわからない。デバッガがバ\
グっているかもしれないし、CPUが熱暴走しているかもしれない。自分が設定\
した条件が間違っているかもしれない。しかし少なくとも静的解析よりは動的\
な解析の結果のほうが事実に近いはずである。

### 動的な解析\
h4. 対象プログラムを使う

これがなければ始まらない。そもそもそのプログラムがどういうものなのか、\
どういう動作をすべきなのか、あらかじめ知っておく。

#### デバッガで動きを追う

例えば実際にコードがどこを通ってどういうデータ構造を作るか、なんていう\
ことは頭の中で考えているよりも実際にプログラムを動かしてみてその結果を\
見たほうが早い。それにはデバッガを使うのが簡単だ。

実行時のデータ構造を絵にして見られるとさらに嬉しいのだが、そういうツー\
ルはなかなかない（特にフリーのものは少ない）。比較的単純な構造のスナッ\
プショットくらいならテキストでさらっと書き出し\
`graphviz`footnote{@graphviz`......添付CD-ROMの`doc/graphviz.html@参照}の\
ようなツールを使って絵にすることもできそうだが、汎用・リアルタイムを\
目指すとかなり難しい。

#### トレーサ

コードがどの手続きを通っているか調査したければトレーサを使えばいい。\
C言語なら\
`ctrace`footnote{@ctrace`......`http://www.vicente.org/ctrace@}と\
いうツールがある。\
またシステムコールのトレースには\
`strace`footnote{@strace`......`http://www.wi.leidenuniv.nl/\~wichert/strace/@}、\
`truss`、@ktrace@と言ったツールがある。

#### printしまくる

`printf`デバッグという言葉があるが、この手法はデバッグでなくても役に立つ。\
特定の変数の移り変わりなどはデバッガでチマチマ辿ってみるよりもprint文を\
埋め込んで結果だけまとめて見るほうがわかりやすい。

#### 書き換えて動かす

例えば動作のわかりにくいところでパラメータやコードを少しだけ変えて動\
かしてみる。そうすると当然動きが変わるから、コードがどういう意味なのか\
類推できる。

言うまでもないが、オリジナルのバイナリは残しておいて\
同じことを両方にやってみるべきである。

### 静的な解析\
h4. 名前の大切さ

静的解析とはつまりソースコードの解析だ。そしてソースコードの解析とは名\
前の調査である。ファイル名・関数名・変数名・型名・メンバ名など、プログ\
ラムは名前のかたまりだ。名前はプログラムを抽象化する最大の武器なのであ\
たりまえと言えばあたりまえだが、この点を意識して読むとかなり効率が違う。

またコーディングルールについてもあたりをつけておきたい。例えばCの関数\
名なら@extern@関数にはプリフィクスを使っていることが多く、関数の種類を見\
分けるのに使える。またオブジェクト指向様式のプログラムだと関数の所属情\
報がプリフィクスに入っていることがあり、貴重な情報になる。\
（例：@rb\_str\_length@）

#### ドキュメントを読む

内部構造を解説したドキュメントが入っていることもある。\
特に「@HACKING@」といった名前のファイルには注意だ。

#### ディレクトリ構造を読む

どういう方針でディレクトリが分割されているのか見る。\
そのプログラムがどういう作りになっているのか、\
どういうパートがあるのか、概要を把握する。

#### ファイル構成を読む

ファイルの中に入っている関数（名）も合わせて見ながら、\
どういう方針でファイルが分割されているのか見る。ファイル名は\
有効期間が非常に長いコメントのようなものであり、注目すべきである。

さらに、ファイルの中にまたモジュールがある場合、モジュールを構成する関\
数は近くにまとまっているはずだ。つまり関数の並び順からモジュール構成\
を見付けることができる。

#### 略語の調査

わかりにくい略語があればリストアップしておいて早めに調べる。\
例えば「GC」と書いてあった場合、それがGarbage Collectionなのか\
それともGraphic Contextなのかで随分と話が違ってしまう。

プログラム関係の略語はたいてい単語の頭文字を取るとか、単語から母音を落とす、\
という方法で作られる。特に対象プログラムの分野で有名な略語は問答無用で\
使われるのであらかじめチェックしておこう。

#### データ構造を知る

データとコードが並んでいたら、まずデータ構造から調べるべきである。つま\
りCならヘッダファイルから眺めるほうが、たぶんいい。そのときはファイル\
名から想像力を最大限に働かせよう。例えば言語処理系で@frame.h@というファ\
イルがあったら恐らくスタックフレームの定義だ。

また構造体の型とメンバ名だけでも随分といろいろなことがわかる。例え\
ば構造体の定義中に自分の型へのポインタで@next@というメンバがあればリンク\
リストだろうと想像できる。同様に、@parent@・@children@・@sibling@と言った要\
素があれば十中八九ツリーだ。@prev@ならスタックだろう。

#### 関数同士の呼び出し関係を把握する

関数同士の関係は名前の次に重要な情報だ。呼び出し関係を表現したものを\
特に「コールグラフ」と言うが、これは非常に便利である。このへんは\
ツールを活用したい。

ツールはテキストベースで十分だが、図にしてくれれば文句無しだ。\
ただそういう便利なものはなかなかない（特にフリーのものは少ない）。\
筆者が本書のために@ruby@を解析したときは、小さなコマンド言語と\
パーサを適当にRubyで書き、@graphviz@というツールに渡して半自動生成した。

#### 関数を読む

動作を読んで、関数のやることを一言で説明できるようにする。関数関連図を\
見ながらパートごとに読んでいくのがいい。

関数を読むときに重要なのは「何を読むか」ではなく「何を読まないか」であ\
る。どれだけコードを削るかで読みやすさが決まると言ってよい。具体的に何\
を削ればいいか、というのは実際に見せてみないとわかりづらいので本文で解\
説する。

それとコーディングスタイルが気にいらないときは@indent@のようなツールを\
使って変換してしまえばいい。

#### 好みに書き換えてみる

人間の身体というのは不思議なもので、できるだけ身体のいろんな場所を使い\
ながらやったことは記憶に残りやすい。パソコンのキーボードより原稿用紙の\
ほうがいい、という人が少なからずいるのは、単なる懐古趣味ではなくそうい\
うことも関係しているのではないかと思う。

そういうわけで単にモニタで読むというのは非常に身体に残りにくいので、\
書き換えながら読む。そうするとわりと早く身体がコードに馴染んでくること\
が多い。気にくわない名前やコードがあったら書き換える。わかりづらい略語\
は置換して省略しないようにしてしまえばよい。

ただし当然のことだが書き換えるときはオリジナルのソースは別に残しておき、\
途中で辻褄が合わないと思ったら元のソースを見て確認すること。でないと自\
分の単純ミスで何時間も悩む羽目になる。それに書き換えるのはあくまで馴染\
むためであって書き換えること自体が目的ではないので熱中しすぎないように\
注意してほしい。

### 歴史を読む

プログラムにはたいてい変更個所の履歴を書いた文書が付いている。例えば\
GNUのソフトウェアだと必ず@ChangeLog@というファイルがある。これは\
「プログラムがそうなっている理由」を知るのには最高に役に立つ。

またCVSやSCCSのようなバージョン管理システムを使っていてしかもそれにア\
クセスできる場合は、@ChangeLog@以上に利用価値が高い。CVSを例に取ると、特\
定の行を最後に変更した場所を表示する@cvs
annotate@、指定した版からの差分\
を取る@cvs diff@などが便利だ。

さらに、開発用のメーリングリストやニュースグループがある場合はその過去\
ログを入手してすぐに検索できるようにしておく。変更の理由がズバリ載って\
いることが多いからだ。もちろんWeb上で検索できるならそれでもいい。

### 静的解析用ツール

いろいろな目的のためにいろいろなツールがあるので一口には言えないが、筆\
者が一つだけ選ぶとしたら@global@をお勧めする。なんと言っても他の用途に応\
用しやすい作りになっているところがポイントだ。例えば同梱されている\
`gctags`は本当はタグファイルを作るためのツールなのだが、\
これを使ってファイルに含まれる関数名のリストを取ることもできる。

~/src/ruby\\ \\ gctags\\ class.c\\ |\\ awk\\ '{print\\ \$1}'
SPECIAL\_SINGLETON
SPECIAL\_SINGLETON
clone\_method
include\_class\_new
ins\_methods\_i
ins\_methods\_priv\_i
ins\_methods\_prot\_i
method\_list
\\ \\ \\ \\ \\ \\ \\ \\ ：
\\ \\ \\ \\ \\ \\ \\ \\ ：
\</pre\>

とは言えこれはあくまでも筆者のお勧めなので読者は自分の好きなツールを使っ
てもらえばいい。ただその時は最低でも次の機能を備えているものを選ぶように
すべきだ。


ファイルに含まれる関数名をリストアップする
関数名や変数名から位置を探す（さらにそこに飛べるとなおよい）
関数クロスリファレンス

h2.\\ ビルド
h3.\\ 対象バージョン

本書で解説している@ruby@のバージョンは1.7の2002-09-12版である。@ruby@はマ
イナーバージョンが偶数だと安定版で奇数だと開発版だから、1.7は開発版と
いうことになる。しかも9月12日は特に何かの区切りというわけではないの
で、該当バージョンの公式パッケージは配布されていない。従ってこの版を入
手するには本書添付のCD-ROMまたはサポートサイト
footnote{本書のサポートサイト......@http://i.loveruby.net/ja/rhg/@}
から入手するか、後述のCVSを使うしかない。


安定版の1.6でなく1.7にした理由は、1.7のほうが仕様・実装ともに整理され
ていて扱いやすいことが一つ。次に、開発版先端のほうがCVSが使いやすい。
さらに、わりと近いうちに次の安定版の1.8が出そうな雰囲気になってきたこと。
そして最後に、最先端を見ていくほうが気分的に楽しい。

h3.\\ ソースコードを入手する

添付CD-ROMに解説対象の版のアーカイブを収録した。
CD-ROMのトップディレクトリに

p(=emlist).\\ 
ruby-rhg.tar.gz
ruby-rhg.zip
ruby-rhg.lzh
\</pre\>

の三種類が置いてあるので、便利なものを選んで使ってほしい。
もちろん中身はどれも同じだ。例えば@tar.gz@のアーカイブなら
次のように展開すればいいだろう。

p(=screen).\\ 
\~/src\\ \\ mount\\ /mnt/cdrom\
~/src  gzip -dc /mnt/cdrom/ruby-rhg.tar.gz | tar xf -
\~/src  umount /mnt/cdrom\

</pre>
### コンパイルする

ソースコードを見るだけでも「読む」ことはできる。しかしプログラムを知る\
ためには実際にそれを使い、改造し、実験してみることが必要だ。実験をする\
なら見ているソースコードと同じものを使わなければ意味がないので、当然自\
分でコンパイルすることになる。

そこでここからはコンパイルの方法を説明する。まずはUNIX系OSの場合から話\
を始めよう。Windows上ではいろいろあるので次の項でまとめて話す。ただし\
CygwinはWindows上ではあるがほとんどUNIXなので、こちらの話を読んでほし\
い。

#### UNIX系OSでのビルド

さて、UNIX系OSなら普通Cコンパイラは標準装備なので、次の手順でやれば\
たいがい通ってしまう。\
`~/src/ruby`にソースコードが展開されているとする。

~/src/ruby\\ \\ ./configure
\~/src/ruby\\ \\ make\
~/src/ruby  su
\~/src/ruby \# make install
\</pre\>

以下、いくつか注意すべき点を述べる。


Cygwin、UX/4800など一部のプラットフォームでは@configure@の段階で
@--enable-shared@オプションを付けないとリンクに失敗する。
@--enable-shared@というのは@ruby@のほとんどを共有ライブラリ
（@libruby.so@）としてコマンドの外に出すオプションである。

p(=screen). 
\~/src/ruby  ./configure —enable-shared\

</pre>
ビルドに関するより詳しいチュートリアルを添付CD-ROMの\
`doc/build.html`に入れたので、それを読みながらやってみてほしい。

#### Windowsでのビルド

Windowsでのビルドとなるとどうも話がややこしくなる。\
問題の根源はビルド環境が複数あることだ。

Visual C*+\
MinGW\
Cygwin\
Borland C*+ Compiler

まずCygwin環境はWindowsよりもUNIXに条件が近いのでUNIX系のビルド手順に\
従えばいい。

Visual C**でコンパイルする場合はVisual C** 5.0以上が\
必要である。バージョン6か.NETならまず問題ないだろう。

MinGW、Minimalist GNU for
WindowsというのはGNUのコンパイル環境（ようするに\
`gcc`と@binutils@）をWindowsに移植したものだ。CygwinがUNIX環境全体を移植し\
たのに対し、MinGWはあくまでコンパイルのためのツールだけを移植してある。\
またMinGWでコンパイルしたプログラムは実行時に特別なDLLを必要としない。\
つまりMinGWでコンパイルした@ruby@はVisual C**版と全く同じに扱える。

\
また個人利用ならばBorland C** Compilerのバージョン5.5がBorlandのサイト\
footnote{Borlandのサイト：@http://www.borland.co.jp@}\
から無料でダウンロードできる。@ruby@がサポートしたのがかなり最近なのが\
多少不安だが、本書出版前に行ったビルドテストでは特に問題は出ていない。

さて以上四つの環境のうちどれを選べばいいだろうか。まず基本的には\
Visual C**版が最も問題が出にくいのでそれをお勧めする。UNIXの経験がある\
ならCygwin一式入れてCygwinを使うのもよい。UNIXの経験がなくVisual C**も\
持っていない場合はMinGWを使うのがいいだろう。

以下ではVisual C**とMinGWでのビルド方法について説明するが、\
あくまで概要だけに留めた。より細かい解説とBorland C** Compilerでの\
ビルド方法は添付CD-ROMの@doc/build.html@に収録したので適宜そちらも\
参照してほしい。

#### Visual C*+
\
Visual C**と言っても普通はIDEは使わず、DOSプロンプトからビルドする。そ\
のときはまずVisual C**自体を動かせるようにするために環境変数の初期化を\
しなければいけない。Visual C**にそのためのバッチファイルが付いてくるの\
で、まずはそれを実行しよう。
\
p. \
C:\> cd “Program FilesMicrosoft Visual Studio .NETVc7bin”\
C:Program FilesMicrosoft Visual Studio .NETVc7bin\> vcvars32\
\</pre\>
\
これはVisual C**.NETの場合だ。バージョン6なら以下の場所にある。
\
p. \
C:Program FilesMicrosoft Visual StudioVC98bin\
\</pre\>
\
`vcvars32`を実行したらその後は@ruby@のソースツリーの中のフォルダ\
`win32`に移動してビルドすればいい。以下、ソースツリーは@C:src@に\
あるとしよう。
\
p. \
C:\> cd srcruby\
C:srcruby\> cd win32\
C:srcrubywin32\> configure\
C:srcrubywin32\> nmake\
C:srcrubywin32\> nmake DESTDIR=“C:Program Filesruby” install\
\</pre\>
\
これで@C:Program Filesrubybin@に@ruby@コマンドが、\
`C:Program Filesrubylib`以下にRubyのライブラリが、\
それぞれインストールされる。@ruby@はレジストリなどは一切使わない\
ので、アンインストールするときは@C:ruby@以下を消せばよい。
\
h4. MinGW
\
前述のようにMinGWはコンパイル環境のみなので、一般的なUNIXのツール、\
例えば@sed@や@sh@が存在しない。しかし@ruby@のビルドにはそれが必要なので\
それをどこかから調達しなければならない。それにはまた二つの方法が\
存在する。CygwinとMSYS（Minimal SYStem）である。

\
だがMSYSのほうは本書の出版前に行ったビルド大会でトラブルが続出してしまっ\
たのでお勧めできない。対照的にCygwinを使う方法だと非常に素直に通った。\
従って本書ではCygwinを使う方法を説明する。

\
まずCygwinの@setup.exe@でMinGWと開発ツール一式を入れておく。\
CygwinとMinGWは添付CD-ROMにも収録した\
footnote{CygwinとMinGW……添付CD-ROMの@doc/win.html@を参照}。\
あとはCygwinの@bash@プロンプトから以下のように打てばよい。
\
p. \
~/src/ruby\\ \\ ./configure\\ --with-gcc='gcc\\ -mno-cygwin'\\ 
\\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ \\ --enable-shared\\ i386-mingw32
\~/src/ruby\\ \\ make\
~/src/ruby  make install
\</pre\>

これだけだ。ここでは@configure@の行を折り返しているが実際には一行に
入れる。またバックスラッシュを入れる必要はない。インストール先は
コンパイルしたドライブの@usrlocal@以下になる。このあたりはかなり
ややこしいことが起こっていて説明が長くなるので、
添付CD-ROMの@doc/build.html@で徹底的に説明しよう。

h2. ビルド詳細

ここまでが@README@的な解説である。今度はこれまでやったことが具体的に
何をしているのか、つっこんで見ていこう。ただしここの話は部分的に
かなり高度な知識が必要になる。わからない場合はいきなり次の節に
飛んでほしい。本書全体を読んでから戻ってきてもらえばわかるように
なっているはずだ。


さて、どのプラットフォームでも@ruby@のビルドは三段階に分かれている。
即ち@configure@、@make@、@make install@だ。@make install@はいいとして、
@configure@と@make@の段階について解説しよう。

h3. @configure@

まず@configure@である。この中身はシェルスクリプトになっており、これ
でシステムのパラメータを検出する。例えば「ヘッダファイル@setjmp.h@が存
在するか」とか、「@alloca()@は使えるか」ということを調べてくれる。調べ
る方法は意外と単純である。


チェック対象方法
コマンド実際に実行してみて@\$?@を見る
ヘッダファイル@if [ -f \$includedir/stdio.h ]@
関数小さいプログラムをコンパイルしてみてリンクが成功するかどうか試す


違いを検出したら、それをどうにかしてこちらに伝えてもらわないと
いけない。その方法は、まず@Makefile@が一つ。パラメータを@@PARAM@@の
ように埋め込んだ@Makefile.in@を置いておくと、それを実際の値に変換
した@Makefile@を生成してくれる。例えば次のように。

p(=emlist). 
Makefile.in:  CFLAGS = @CFLAGS@
                     ↓
Makefile   :  CFLAGS = -g -O2
\</pre\>

もう一つ、関数やヘッダファイルがあるかどうかといった情報を
ヘッダファイルにして出力してくれる。出力ファイルの名前は変更
できるのでプログラムによって違うが、@ruby@では@config.h@である。
@configure@を実行した後にこのファイルができていることを確かめてほしい。
中身はこんな感じだ。

p(=caption). ▼@config.h@
p(=longlist). 
         ：
         ：
\#define HAVE\_SYS\_STAT\_H 1
\#define HAVE\_STDLIB\_H 1
\#define HAVE\_STRING\_H 1
\#define HAVE\_MEMORY\_H 1
\#define HAVE\_STRINGS\_H 1
\#define HAVE\_INTTYPES\_H 1
\#define HAVE\_STDINT\_H 1
\#define HAVE\_UNISTD\_H 1
\#define \_FILE\_OFFSET\_BITS 64
\#define HAVE\_LONG\_LONG 1
\#define HAVE\_OFF\_T 1
\#define SIZEOF\_INT 4
\#define SIZEOF\_SHORT 2
         ：
         ：
\</pre\>

どれも意味はわかりやすい。@HAVE\_xxxx\_H@ならヘッダファイルが存在するか
どうかのチェックだろうし、@SIZEOF\_SHORT@ならCの@short@型が何バイトかを
示しているに違いない。同じく@SIZEOF\_INT@なら@int@のバイト長だし、
@HAVE\_OFF\_T@は@offset\_t@型が定義されているかを示している。これに限らず
@configure@では「ある／ない」の情報は@HAVE\_xxxx@というマクロで定義される
（する）。


以上のことからわかるように、@configure@は違いを検出してはくれるが、
その違いを自動的に吸収してくれるわけではない。ここで定義された値を
使って差を埋めるのはあくまで各プログラマの仕事である。例えば次の
ように。

p(=caption). ▼@HAVE\_@マクロの典型的な使いかた
p(=longlist). 
  24  \#ifdef HAVE\_STDLIB\_H
  25  \# include 
  26  \#endif
(ruby.h)
\</pre\>
h3. @autoconf@

@configure@は@ruby@の専用ツールではない。関数があるか、ヘッダファイルが
あるか......といったテストには明らかに規則性があるのだから、プログラムを
書く人がみんなでそれぞれに別のものを書くのは無駄だ。


そこで登場するのが@autoconf@というツールである。@configure.in@とか
@configure.ac@というファイルに「こういうチェックがしたいんだ」と
書いておき、それを@autoconf@で処理すると適切な@configure@を作ってくれる。
@configure.in@の@.in@は@input@の略だろう。@Makefile@と@Makefile.in@の関係と
同じである。@.ac@のほうはもちろん@AutoConf@の略だ。


ここまでを絵にすると図1のようになる。

p(=image). 
!images/ch\_abstract\_build.jpg([build])!
図1: @Makefile@ができるまで


もっと詳しいことが知りたい読者には『GNU Autoconf/Automake/Libtool』
footnote{『GNU Autoconf/Automake/Libtool』Gary V.Vaughan, Ben Elliston, Tom Tromey, Ian Lance Taylor共著、でびあんぐる監訳、オーム社}
をお勧めする。


ところで@ruby@の@configure@は言ったとおり@autoconf@を使って生成してい
るのだが、世の中にある@configure@が必ずしも@autoconf@で生成されている
とは限らない。手書きだったり、別の自動生成ツールを使っていたりすること
もある。なんにせよ、最終的に@Makefile@や@config.h@やその他いろいろがで
きればそれでいいのだ。

h3. @make@

第二段階、@make@では何をするのだろうか。もちろん@ruby@のソースコードを
コンパイルするわけだが、@make@の出力を見ているとどうもその他にいろいろ
やっているように見える。その過程を簡単に説明しておこう。


@ruby@自体を構成するソースコードをコンパイルする。
@ruby@の主要部分を集めたスタティックライブラリ@libruby.a@を作る。
常にスタティックリンクされる@ruby@「@miniruby@」を作る。
@--enable-shared@のときは共有ライブラリ@libruby.so@を作る。
@miniruby@を使って拡張ライブラリ（@ext/@以下）をコンパイルする。
最後に、本物の@ruby@を生成する。


@miniruby@と@ruby@の生成が分かれているのには二つ理由がある。一つめは拡張ラ
イブラリのコンパイルに@ruby@が必要になることだ。@--enable-shared@の場合は
@ruby@自身がダイナミックリンクされるので、ライブラリのロードパスの関係で
すぐに動かせないかもしれない。そこでスタティックリンクした@miniruby@を作り、
ビルドの過程ではそちらを使うようにする。


二つめの理由は、共有ライブラリが使えないプラットフォームでは拡張ライブ
ラリを@ruby@自体にスタティックリンクしてしまう場合があるということだ。そ
の場合、@ruby@は拡張ライブラリを全てコンパイルしてからでないと作れないが、
拡張ライブラリは@ruby@がないとコンパイルできない。そのジレンマを解消する
ために@miniruby@を使うのである。

h2. CVS

本書の添付CD-ROMに入っている@ruby@のアーカイブにしても公式のリリースパッ
ケージにしても、それは@ruby@という、変化しつづているプログラムのほんの一
瞬の姿をとらえたスナップショットにすぎない。@ruby@がどう変わってきたか、
どうしてそうだったのか、ということはここには記述されていない。では過去
も含めた全体を見るにはどうしたらいいだろうか。CVSを使えばそれができる。

h3. CVSとは

CVSを一言で言うとエディタのundoリストである。
ソースコードをCVSの管理下に入れておけばいつでも昔の姿に戻せるし、誰が、
どこを、いつ、どう変えたのかすぐにわかる。一般にそういうことをしてくれ
るプログラムのことをソースコード管理システムと言うが、オープンソースの
世界で一番有名なソースコード管理システムがCVSである。


@ruby@もやはりCVSで管理されているのでCVSの仕組みと使いかたについて少し説
明しよう。まずCVSの最重要概念はレポジトリとワーキングコピーである。
CVSはエディタのundoリストのようなものと言ったが、そのためには歴代の変更の
記録を
どこかに残しておかないといけない。それを全部まとめて保存しておく場所が
「CVSレポジトリ」である。


ぶっちゃけて言うと、過去のソースコードを全部集めてあるのがレポジトリで
ある。もちろんそれはあくまで概念であって、実際には容量を節約するために、
最新の姿一つと、そこに至るまでの変更差分（ようするにパッチ）の形で集積
されている。なんにしてもファイルの過去の姿をどの時点だろうと取り出せる
ようになっていればそれでいいのだ。


一方、レポジトリからある一点を選んでファイルを取り出したものが
「ワーキングコピー」だ。レポジトリは一つだけだがワーキングコピーは
いくつあってもいい（図2）。

p(=image). 
!images/ch\_abstract\_repo.jpg([repo])!
図2: レポジトリとワーキングコピー


自分がソースコードを変更したいときはまずワーキングコピーを取り出して、
それをエディタなどで編集してからレポジトリに「戻す」。するとレポジトリ
に変更が記録される。レポジトリからワーキングコピーを取り出すことを
「チェックアウト（checkout）」、戻すことを「チェックイン
（checkin）」
または「コミット（commit）」と言う（図3）。チェックインするとレ
ポジトリに変更が記録されて、いつでもそれを取り出せるようになる。

p(=image). 
!images/ch\_abstract\_ci.jpg([ci])!
図3: チェックインとチェックアウト


そしてCVS最大の特徴はCVSレポジトリにネットワーク越しにアクセスできると
いうところだ。つまりレポジトリを保持するサーバが一つあればインターネッ
ト越しに誰でもどこからでもチェックアウト・チェックインすることができる。
ただし普通はチェックインにはアクセス制限がかかっているので無制限
にできるというわけではない。

h4. リビジョン

レポジトリから特定の版を取り出すにはどうしたらいいだろうか。一つには時
刻で指定する方法がある。「この当時の最新版をくれ」と要求するとそれを選
んでくれるわけだ。しかし実際には時刻で指定することはあまりない。普通は
「リビジョン（revision）」というものを使う。


「リビジョン」は「バージョン」とほとんど同じ意味である。ただ普通はプロ
ジェクト自体に「バージョン」が付いているので、バージョンという言葉を使
うと紛らわしい。そこでもうちょっと細かい単位を意図してリビジョンという
言葉を使う。


CVSでは、レポジトリに入れたばかりのファイルはリビジョン1.1である。
チェックアウトして、変更して、チェックインするとリビジョン1.2になる。
その次は1.3になる。その次は1.4になる。

h4. CVSの簡単な使用例

以上をふまえてごくごく簡単にCVSの使いかたを話す。まず@cvs@コマンドがな
いとどうにもならないのでインストールしておいてほしい。添付CD-ROMにも
@cvs@のソースコードを収録した
footnote{@cvs@：@archives/cvs-1.11.2.tar.gz@}。
@cvs@のインストールの方法はあまりにも本筋から外れるのでここでは書かな
い。


インストールしたら試しに@ruby@のソースコードをチェックアウトしてみよう。
インターネットに接続中に次のように打つ。

p(=screen). 
 cvs ~~d :pserver:anonymous@cvs.ruby-lang.org:/src login\
CVS Password: anonymous\
 cvs -d :pserver:anonymous@cvs.ruby-lang.org:/src checkout ruby
\</pre\>

何もオプションを付けないと自動的に最新版がチェックアウトされるので、
@ruby/@以下に@ruby@の真の最新版が現れているはずだ。


また、とある日の版を取り出すには@cvs checkout@に@-D@オプションをつけれ
ばいい。次のように打てば本書が解説しているバージョンのワーキングコピー
が取り出せる。

p(=screen). 
 cvs~~d :pserver:anonymous@cvs.ruby-lang.org:/src checkout -D2002-09-12 ruby\
\</pre\>
\
このとき、オプションは必ず@checkout@の直後に書かないといけないことに注\
意。先に「@ruby@」を書いてしまうと「モジュールがない」という変なエラー\
になる。

\
ちなみにこの例のようなanonymousアクセスだとチェックインはできないようになっている。\
チェックインの練習をするには適当に（ローカルの）レポジトリを作って\
Hello, World!プログラムでも入れてみるのがいいだろう。具体的な入れかた\
はここには書かない。@cvs@に付いてくるマニュアルが結構親切だ。日本語の書\
籍ならオーム社の『CVSによるオープンソース開発』\
footnote{『CVSによるオープンソース開発』Karl Fogel, Moshe Bar共著、竹内利佳訳、オーム社}\
をお勧めする。
\
h2. `ruby`の構成\
h3. 物理構造
\
さてそろそろソースコードを見ていこうと思うのだが、まず最初にしなければ\
ならないことはなんだろうか。それはディレクトリ構造を眺めることである。\
たいていの場合ディレクトリ構造すなわちソースツリーはそのままプログラム\
のモジュール構造を示している。いきなり@grep@で@main`を探して頭から処理順
に読んでいく、なんていうのは賢くない。もちろん`main`を探すのも大切だが、
まずはのんびりと`ls@したり@head@したりして全体の様子をつかもう。

\
以下はCVSレポジトリからチェックアウトした直後の\
トップディレクトリの様子だ。\
スラッシュで終わっているのはサブディレクトリである。
\
p. \
COPYING compar.c gc.c numeric.c sample/\
COPYING.ja config.guess hash.c object.c signal.c\
CVS/ config.sub inits.c pack.c sprintf.c\
ChangeLog configure.in install-sh parse.y st.c\
GPL cygwin/ instruby.rb prec.c st.h\
LEGAL defines.h intern.h process.c string.c\
LGPL dir.c io.c random.c struct.c\
MANIFEST djgpp/ keywords range.c time.c\
Makefile.in dln.c lex.c re.c util.c\
README dln.h lib/ re.h util.h\
README.EXT dmyext.c main.c regex.c variable.c\
README.EXT.ja doc/ marshal.c regex.h version.c\
README.ja enum.c math.c ruby.1 version.h\
ToDo env.h misc/ ruby.c vms/\
array.c error.c missing/ ruby.h win32/\
bcc32/ eval.c missing.h rubyio.h x68/\
bignum.c ext/ mkconfig.rb rubysig.h\
class.c file.c node.h rubytest.rb\
\</pre\>
\
最近はプログラム自体が大きくなってきてサブディレクトリが細かく分割され\
ているソフトウェアも多いが、@ruby@はかなり長いことトップディレクトリ\
一筋である。あまりにファイル数が多いと困るが、この程度なら慣れればな\
んでもない。

\
トップレベルのファイルは六つに分類できる。即ち

\
ドキュメント\
`ruby`自身のソースコード\
`ruby`ビルド用のツール\
標準添付拡張ライブラリ\
標準添付Rubyライブラリ\
その他

\
である。ソースコードとビルドツールが重要なのは当然として、その他に\
我々の役に立ちそうなものを挙げておこう。

\
`ChangeLog`

\
`ruby`への変更の記録。変更の理由を調べるうえでは非常に重要。

\
`README.EXT README.EXT.ja`

\
拡張ライブラリの作成方法が書いてあるのだが、その一環として\
`ruby`自身の実装に関することも書いてある。
\
h3. ソースコードの腑分け
\
ここからは@ruby@自身のソースコードについてさらに細かく分割していく。\
主要なファイルについては@README.EXT@に分類が書いてあったので\
それに従う。記載がないものは筆者が分類した。
\
h4. Ruby言語のコア
\
`class.c`クラス関連API\
`error.c`例外関連API\
`eval.c`評価器\
`gc.c`ガーベージコレクタ\
`lex.c`予約語テーブル\
`object.c`オブジェクトシステム\
`parse.y`パーサ\
`variable.c`定数、グローバル変数、クラス変数\
`ruby.h``ruby`の主要マクロとプロトタイプ\
`intern.h``ruby`のC APIのプロトタイプ。@intern@はinternalの略だと思われるが、ここに載っている関数を拡張ライブラリで使うのは別に構わない。\
`rubysig.h`シグナル関係のマクロを収めたヘッダファイル\
`node.h`構文木ノード関連の定義\
`env.h`評価器のコンテキストを表現する構造体の定義

\
`ruby`インタプリタのコアを構成する部分。本書が解説するのは\
ここのファイルがほとんどである。@ruby@全体のファイル数と比べれば\
非常に少ないが、バイトベースでは全体の50%近くを占める。\
特に@eval.c@は200Kバイト、@parse.y@が100Kバイトと大きい。
\
h4. ユーティリティ
\
`dln.c`動的ローダ\
`regex.c`正規表現エンジン\
`st.c`ハッシュテーブル\
`util.c`基数変換やソートなどのライブラリ

\
`ruby`にとってのユーティリティという意味。ただしユーティリティという\
言葉からは想像できないほど大きいものもある。例えば@regex.c@は120Kバイトだ。
\
h4. `ruby`コマンドの実装
\
`dmyext.c`拡張ライブラリ初期化ルーチンのダミー（DumMY EXTention）\
`inits.c`コアとライブラリの初期化ルーチンのエントリポイント\
`main.c`コマンドのエントリポイント（@libruby@には不要）\
`ruby.c``ruby`コマンドの主要部分（@libruby@にも必要）\
`version.c``ruby`のバージョン

\
コマンドラインで@ruby@と打って実行するときの@ruby@コマンドの実装。コマンドライン\
オプションの解釈などを行っている部分だ。@ruby@コマンド以外に@ruby@コアを利\
用するコマンドとしては@mod\_ruby@や@vim@が挙げられる。これらのコマンドは\
ライブラリ@libruby@（`.a`/`.so`/`.dll`など）とリンクして動作する。
\
h4. クラスライブラリ
\
`array.c``class Array`\
`bignum.c``class Bignum`\
`compar.c``module Comparable`\
`dir.c``class Dir`\
`enum.c``module Enumerable`\
`file.c``class File`\
`hash.c``class Hash`（実体は@st.c@）\
`io.c``class IO`\
`marshal.c``module Marshal`\
`math.c``module Math`\
`numeric.c``class Numeric`、@Integer@、@Fixnum@、@Float@\
`pack.c``Array#pack`、@String\#unpack@\
`prec.c``module Precision`\
`process.c``module Process`\
`random.c``Kernel#srand()`、@rand@\
`range.c``class Range`\
`re.c``class Regexp`（実体は@regex.c@）\
`signal.c``module Signal`\
`sprintf.c``ruby`専用の@sprintf@\
`string.c``class String`\
`struct.c``class Struct`\
`time.c``class Time`

\
Rubyのクラスライブラリの実装。ここにあるものは基本的に通常の\
Ruby拡張ライブラリと全く同じ方法で実装されている。つまりこの\
ライブラリが拡張ライブラリの書きかたの例にもなっているということだ。
\
h4. プラットフォーム依存ファイル
\
`bcc32/`Borland C**（Win32）\
`beos/`BeOS\
`cygwin/`Cygwin（Win32でのUNIXエミュレーションレイヤー）\
`djgpp/`djgpp（DOS用のフリーな開発環境）\
`vms/`VMS（かつてDECがリリースしていたOS）\
`win32/`Visual C*+（Win32）\
`x68/`Sharp X680x0系（OSはHuman68k）

各プラットフォーム特有のコードが入っている。

#### フォールバック関数\
p(=emlist). \
missing/\

</pre>
各種プラットフォームにない関数を補うためのファイル。\
主に@libc@の関数が多い。

### 論理構造

さて、以上四つのグループのうちコアはさらに大きく三つに分けられる。\
一つめはRubyのオブジェクト世界を作りだす「オブジェクト空間（object
space）」。\
二つめはRubyプログラム（テキスト）を内部形式に変換する「パーサ（parser）」。\
三つめはRubyプログラムを駆動する「評価器（evaluator）」。\
パーサも評価器もオブジェクト空間の上に成立し、\
パーサがプログラムを内部形式に変換し、\
評価器がプログラムを駆動する。\
順番に解説していこう。

#### オブジェクト空間

一つめのオブジェクト空間。これは非常に、理解しやすい。なぜならこれが扱\
うものは基本的にメモリ上のモノが全てであり、関数を使って直接表示したり\
操作したりすることができるからだ。従って本書ではまずここから解説を\
始める。第2章から\
第7章までが第一部である。

#### パーサ

二つめのパーサ。これは説明が必要だろう。

`ruby`コマンドはRuby言語のインタプリタである。つまり起動時にテキストの入\
力を解析し、それに従って実行する。だから@ruby@はテキストとして書かれたプ\
ログラムの意味を解釈できなければいけないのだが、不幸にしてテキストとい\
うのはコンピュータにとっては非常に理解しづらいものである。コンピュータ\
にとってはテキストファイルはあくまでバイト列であって、それ以上ではない。\
そこからテキストの意味を読みとるには何か特別な仕掛けが必要になる。そ\
の仕掛けがパーサだ。このパーサを通すことでRubyプログラム（であるテキス\
ト）は@ruby@専用の、プログラムから扱いやすい内部表現に変換される。

その内部表現とは具体的には「構文木」というものだ。構文木はプログラムを\
ツリー構造で表現したもので、例えば@if@文ならば図4のように\
表現される。

![[syntree]](images/ch_abstract_syntree.jpg "[syntree]")\
図4: `if`文と、それに対応する構文木

パーサの解説は第二部『構文解析』で行う。\
第二部は第10章から第12章までだ。\
対象となるファイルは@parse.y@だけである。

#### 評価器

オブジェクトは実際に触ることができるのでわかりやすい。パーサにしてもやっ\
ていること自体はようするにデータ形式の変換なんだから、まあわかる。しか\
し三つめの評価器、こいつはつかみどころが全くない。

評価器がやるのは構文木に従ってプログラムを「実行」していくことだ。と言\
うと簡単そうに見えるのだが、では「実行する」とはどういうことか、ちゃん\
と考えるとこれが結構難しい。@if@文を実行するとはどういうことだろうか。\
`while`文を実行するとはどういうことだろうか。ローカル変数に代入するとは\
どういうことだろうか。メソッドを呼ぶとはどういうことだろうか。その\
全てにキチンキチンと答えを出していかなければ評価器はわからないのだ。

本書では第三部『評価』で評価器を扱う。対象ファイルは@eval.c@だ。\
「評価器」は英語でevaluatorと言うので、それを省略して@eval@である。

さて、@ruby@の作りについて簡単に説明してきたが、プログラムの動作なんてい\
くら概念を説明してもわかりにくいものだ。次の章ではまず実際に@ruby@を使う\
ことから始めるとしよう。

御意見・御感想・誤殖の指摘などは\
[青木峰郎 ](mailto:aamine@loveruby.net)\
までお願いします。

[『Rubyソースコード完全解説』\
](http://direct.ips.co.jp/directsys/go_x_TempChoice.cfm?sh_id=EE0040&spm_id=1&GM_ID=1721"はインプレスダイレクトで御予約・御購入いただけます)
(書籍紹介ページへ飛びます)。":http://direct.ips.co.jp/directsys/go\_x\_TempChoice.cfm?sh\_id=EE0040&spm\_id=1&GM\_ID=1721

Copyright © 2002-2004 Minero Aoki, All rights reserved.
