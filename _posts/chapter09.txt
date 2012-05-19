$comment(-*- coding: utf-8 -*- vim: set encoding=utf-8:)$
Translated by Vincent ISAMBART

h1. Chapter 9: `yacc` crash course

h2. Outline

h3. Parser and scanner

How to write parsers for programming languages has been an active area
of research for a long time, and there is a quite firm established
tactic for doing it. If we limit ourselves to a grammar not too
strange (or ambiguous), we can solve this problem by following this
method.

The first part consists in splitting a string in a list of words (or
tokens). This is called a scanner or lexer. The term "lexical
analyzer" is also used, but is too complicated to say so we'll use the
name scanner.

When speaking about scanners, the common sense first says "there are
generally spaces at the end of a word". And in practice, it was made
like this in most programming languages, because it's the easiest way.

There can also be exceptions. For example, in the old Fortran, white
spaces did not have any meaning. This means a white space did not end
a word, and you could put spaces in the name of a variable. However
that made the parsing very complicated so the compiler vendors, one by
one, started ignoring that standard. Finally Fortran 90 followed this
trend and made the fact that white spaces have an impact the standard.

By the way, it seems the reason white spaces had not meaning in
Fortran 77 was that when writing programs on punch cards it was easy
to make errors in the number of spaces.

h3. List of symbols

I said that the scanner spits out a list of words (tokens), but, to be
exact, what the scanner creates is a list of "symbols", not words.

What are symbols? Let's take numbers as an example. In a programming
language, 1, 2, 3, 99 are all "numbers". They can all be handled the
same way by the grammar. Where we can write 1, we can also write 2 or
3. That's why the parser does not need to handle them in different
ways. For numbers, "number" is enough.

"number", "identifier" and others can be grouped together as
"symbol". But be careful not to mix this with the `Symbol` class.

The scanner first splits the string into words and determines what
these symbols are. For example, `NUMBER` or `DIGIT` for numbers,
`IDENTIFIER` for names like "`name`", `IF` for the reserved word
`if`. These symbols are then given to the next phase.

h3. Parser generator

The list of words and symbols spitted out by the scanner are going to
be used to form a tree. This tree is called a syntax tree.

The name "parser" is also sometimes used to include both the scanner
and the creation of the syntax tree. However, we will use the narrow
sense of "parser", the creation of the syntax tree. How does this
parser make a tree from the list of symbols? In other words, on what
should we focus to find the tree corresponding to a piece of code?

The first way is to focus on the meaning of the words. For example,
let's suppose we find the word `var`. If the definition of the local
variable `var` has been found before this, we'll understand it's the
reading of a local variable.

An other ways is to only focus on what we see. For example, if after
an identified comes a '`=`', we'll understand it's an assignment. If
the reserved word `if` appears, we'll understand it's the start of an
`if` statement.

The later method, focusing only on what we see, is the current
trend. In other words the language must be designed to be analyzed
just by looking at the list of symbols. The choice was because because
this way is simpler, can be more easily generalized and can therefore
be automatized using tools. These tools are called parser generators.

The most used parser generator under UNIX is `yacc`. Like many others,
`ruby`'s parser is written using `yacc`. The input file for this tool
is `parser.y`. That's why to be able to read `ruby`'s parser, we need
to understand `yacc` to some extent.  (Note: Starting from 1.9, `ruby`
requires `bison` instead of `yacc`. However, `bison` is mainly `yacc`
with additional functionality, so this does not diminish the interest
of this chapter.)

This chapter will be a simple presentation of `yacc` to be able to
understand `parse.y`, and therefore we will limit ourselves to what's
needed to read `parse.y`. If you want to know more about parsers and
parser generators, I recommend you a book I wrote called "Rubyを256倍使
うための本 無道編" (The book to use 256 times more of Ruby -
Unreasonable book).  I do not recommend it because I wrote it, but
because in this field it's the easiest book to understand. And besides
it's cheap so it won't make me rich.

Nevertheless, if you would like a book from someone else (or can't
read Japanese), I recommend O'Reilly's "lex & yacc programming" by
John R. Levine, Tony Mason and Doug Brown. And if your are still not
satisfied, you can also read "Compilers" (also known as the "dragon
book" because of the dragon on its cover) by Alfred V. Aho, Ravi Sethi
and Jeffrey D. Ullman.

h2. Grammar

h3. Grammar file

The input file for `yacc` is called "grammar file", as it's the file
where the grammar is written. The convention is to name this grammar
file `*.y`. It will be given to `yacc` who will generate C source
code. This file can then be compiled as usual (figure 1 shows the full
process).

!images/ch_yacc_build.png(File dependencies)!

The output file name is always `y.tab.c` and can't be changed. The
recent versions of `yacc` usually allow to change it on the command
line, but for compatibility it was safer to keep `y.tab.c`. By the
way, it seems the `tab` of `y.tab.c` comes from `table`, as lots of
huge tables are defined in it. We should now have a look at the file.

The grammar file's content has the the following form:

▼ General form of the grammar file
<pre class="longlist">
%{
Header
%}
%union ....
%token ....
%type ....

%%
Rules part
%%
User defined part
</pre>

`yacc`'s input file is first divided in 3 parts by `%%`. The first
part if called the definition part, has a lot of definitions and
setups. Between `%{` and `%}` we can write anything we want in C, like
for example necessary macros. After that, the instructions starting
with `%` are special `yacc` instructions. Every time we use one, we'll
explain it.

The middle part of the file is called the rules part, and is the most
essential part for `yacc`. It's where is written the grammar we want
to parse. We'll explain it in details in the next section.

The last part of the file, the user defined part, can be used freely
by the user. `yacc` just copies this part verbatim in the output
file. It's used for example to put auxiliary routines needed by the
parser.

h3. What does `yacc` do.

What `yacc` takes care of is mainly this rules part in the
middle. `yacc` takes the grammar written there and use it to make a
function called `yyparse()`. It's the parser, in the narrow sense of
the word.

In the narrow sense, so it means a scanner is needed. However, `yacc`
won't take care of it, it must be done by the user. The function for
the scanner is named `yylex()`.

Even if `yacc` creates `yyparse()`, it only takes care of its core
part. The "actions" we'll mention later is out of its scope. You can
think the part done by `yacc` is too small, but that's not the
case. That's because this "core part" is overly important that `yacc`
survived to this day even though we keep complaining about it.

But what on earth is this core part? That's what we're going to see.

h3. BNF

When we want to write a parser in C, its code will be "cut the string
this way, make this an `if` statement..." When using parser
generators, we say the opposite, that is "I would like to parse this
grammar." Doing this creates for us a parser to handle the
grammar. This means telling the specification gives us the
implementation. That's the convenient point of `yacc`.

But how can we tell the specification? With `yacc`, the method of
description used is the BNF (Backus-Naur Form). Let's look at a very
simple example.

<pre class="emlist">
if_stmt: IF expr THEN stmt END
</pre>

Let's see separately what's at the left and at the right of the
"`:`". The part on the left side, `if_stmt`, is equal to the right
part... is what I mean here. In other words, I'm saying that:

`if_stmt` and `IF expr THEN stmt END` are equivalent.

Here, `if_stmt`, `IF`, `expr`... are all "symbols". `expr` is the
abbreviation of `expression`, `stmt` of `statement`. It must be for
sure the declaration of the `if` statement.

One definition is called a rule. The part at the left of "`:`" is
called the left side and the right part called the right side. This is
quite easy to remember.

But something is missing. We do not want an `if` statement without
being able to use `else`. And `even` if we could write `else`, having
to always write the `else` even when it's useless would be
cumbersome. In this case we could do the following:

<pre class="emlist">
if_stmt: IF expr THEN stmt END
       | IF expr THEN stmt ELSE stmt END
</pre>

"`|`" means "or".

`if_stmt` is either "`IF expr THEN stmt END`" or "`IF expr THEN stmt
ELSE stmt END`".

That's it.

Here I would like you to pay attention to the split done with
`|`. With just this, one more rule is added. In fact, punctuating with
`|` is just a shorter way to repeat the left side. The previous
example has exactly the same meaning as the following:

<pre class="emlist">
if_stmt: IF expr THEN stmt END
if_stmt: IF expr THEN stmt ELSE stmt END
</pre>

This means two rules are defined in the example.

This is not enough to complete the definition of the `if`
statement. That's because the symbols `expr` and `stmt` are not sent
by the scanner, rules must be defined. To be closer to Ruby, let's
boldly add some rules.

<pre class="emlist">
stmt   : if_stmt
       | IDENTIFIER '=' expr   /* assignment */
       | expr

if_stmt: IF expr THEN stmt END
       | IF expr THEN stmt ELSE stmt END

expr   : IDENTIFIER       /* reading a variable */
       | NUMBER           /* integer constant */
       | funcall          /* FUNction CALL */

funcall: IDENTIFIER '(' args ')'

args   : expr             /* only one parameter */
</pre>

I used two new elements. First, comments of the same form as in C, and
character expressed using `'='`. This `'='` is also of course a
symbol. Symbols like "=" are different from numbers as there is only
one variety for them. That's why for symbols where can also use `'='`.
It would be great to be able to use for strings for, for example,
reserved words, but due to limitations of the C language this cannot
be done.

We add rules like this, to the point we complete writing all the
grammar. With `yacc`, the left side of the first written rule is "the
whole grammar we want to express". So in this example, `stmt`
expresses the whole program.

It was a little too abstract. Let's explain this a little more
concretely. By "`stmt` expresses the whole program", I mean `stmt` and
the rows of symbols expressed as equivalent by the rules, are all
recognized as grammar. For example, `stmt` and `stmt` are
equivalent. Of course. Then `expr` is equivalent to `stmt`. That's
expressed like this in the rule. Then, `NUMBER` and `stmt` are
equivalent. That's because `NUMBER` is `expr` and `expr` is `stmt`.

We can also say that more complicated things are equivalent.

<pre class="emlist">
              stmt
               ↓
             if_stmt
               ↓
      IF expr THEN stmt END
          ↓        ↓
IF IDENTIFIER THEN expr END
                    ↓
IF IDENTIFIER THEN NUMBER END
</pre>

In the statement developed here, at the end all symbols are ones sent
by the scanner. That means this expression is a correct program. Or
putting it the other way around, if this sequence of symbols is sent
by the scanner, the parser will understand it in the opposite way it
was developed.

<pre class="emlist">
IF IDENTIFIER THEN NUMBER END
                    ↓
IF IDENTIFIER THEN expr END
          ↓        ↓
      IF expr THEN stmt END
               ↓
             if_stmt
               ↓
              stmt
</pre>

And `stmt` is a symbol expressing the whole program. That's why this
sequence of symbols is a correct program for the parser. When it's the
case, the parsing routine `yyparse()` ends returning 0.

By the way, the technical term expressing that the parser succeeded is
that it "accepted" the input. The parser is like a government office:
if you do not fill the documents in the boxes exactly like he asked
you to, he'll refuse them. The accepted sequences of symbols are the
ones for which the boxes where filled correctly. Parser and government
office are strangely similar for instance in the fact that they care
about details in specification and that they use complicated terms.

h3. Terminal symbols and nonterminal symbols

Well, in the confusion of the moment I used without explaining it the
expression "symbols coming from the scanner". So let's explain this. I
use one word "symbol" but there are two types.

The first type of the symbols are the ones sent by the scanner. They
are for example, `IF`, `THEN`, `END`, `'='`, ... They are called
terminal symbols. That's because like before when we did the quick
expansion we find them aligned at the end. In this chapter terminal
symbols are always written in capital letters. However, symbols like
`'='` between quotes are special. Symbols like this are all terminal
symbols, without exception.

The other type of symbols are the ones that never come from the
scanner, for example `if_stmt`, `expr` or `stmt`. They are called
nonterminal symbols. As they don't come from the scanner, they only
exist in the parser. Nonterminal symbols also always appear at one
moment or the other as the left side of a rule. In this chapter,
nonterminal symbols are always written in lower case letters.

h3. How to test

I'm now going to tell you the way to process the grammar file with
`yacc`.

<pre class="emlist">
%token A B C D E
%%
list: A B C
    | de

de  : D E
</pre>

First, put all terminal symbols used after `%token`. However, you do
not have to type the symbols with quotes (like `'='`). Then, put `%%`
to mark a change of section and write the grammar. That's all.

Let's now process this.

<pre class="screen">
% yacc first.y
% ls
first.y  y.tab.c
%
</pre>

Like most Unix tools, "silence means success".

There's also implementations of `yacc` that need semicolons at the end
of (groups of) rules. When it's the case we need to do the following:

<pre class="emlist">
%token A B C D E
%%
list: A B C
    | de
    ;

de  : D E
    ;
</pre>

I hate these semicolons so in this book I'll never use them.

h3. Void rules

Let's now look a little more at some of the established ways of
grammar description. I'll first introduce void rules.

<pre class="emlist">
void:
</pre>

There's nothing on the right side, this rule is "void". For example,
the two following `target`s means exactly the same thing.

<pre class="emlist">
target: A B C

target: A void B void C
void  :
</pre>

What is the use of such a thing? It's very useful. For example in the
following case.

<pre class="emlist">
if_stmt : IF expr THEN stmts opt_else END

opt_else:
        | ELSE stmts
</pre>

Using void rules, we can express cleverly the fact that "the `else`
section may be omitted". Compared to the rules made previously using
two definitions, this way is shorter and we do not have to disperse
the burden.

h3. Recursive definitions

The following example is still a little hard to understand.

<pre class="emlist">
list: ITEM         /* rule 1 */
    | list ITEM    /* rule 2 */
</pre>

This expresses a list of one or more items, in other words any of the
following lists of symbols:

<pre class="emlist">
ITEM
ITEM ITEM
ITEM ITEM ITEM
ITEM ITEM ITEM ITEM
      :
</pre>

Do you understand why? First, according to rule 1 `list` can be read
`ITEM`. If you merge this with rule 2, `list` can be `ITEM ITEM`.

<pre class="emlist">
list: list ITEM
    = ITEM ITEM
</pre>

We now understand that the list of symbols `ITEM ITEM` is similar to
`list`. By applying again rule 2 to `list`, we can say that 3 `ITEM`
are also similar to `list`. By quickly continuing this process, the
list can grow to any size.

I'll now show you the next example. The following example expresses
the lists with 0 or more `ITEM`.

<pre class="emlist">
list:
    | list ITEM
</pre>

First the first line means "`list` is equivalent to (void)". By void I
mean the list with 0 `ITEM`. Then, by looking at rule 2 we can say
that "`list ITEM`" is equivalent to 1 `ITEM`. That's because `list` is
equivalent to void.

<pre class="emlist">
list: list   ITEM
    = (void) ITEM
    =        ITEM
</pre>

By applying the same operations of replacement multiple times, we can
understand that `list` is the expression a list of 0 or more items.

With this knowledge, "lists of 2 or more `ITEM`" or "lists of 3 or
more `ITEM`" are easy, and we can even create "lists or an even number
of elements".

<pre class="emlist">
list:
    | list ITEM ITEM
</pre>

h2. Construction of values

This abstract talk lasted long enough so in this section I'd really
like to go on with a more concrete talk.

h3. Shift and reduce

For the moment we have only seen how to write grammars, but what we
want is being able to build the full syntax tree. However, I'm afraid
to say that has can be expected there's no way to build the syntax
tree with just expressing the rules. That's why this time we'll go a
little farther and I'll explain how to build the syntax tree.

We'll first see what the parser does during the execution. We'll use
the following simple grammar as an example.

<pre class="emlist">
%token A B C
%%
program: A B C
</pre>

In the parser there is a stack called the semantic stack. The parser
pushes on it all the symbols coming from the scanner. This move is
called "shifting the symbols".

<pre class="emlist">
[ A B ] ← C   shift
</pre>

And when any of the right side of a rule is equal to the end of the
end, this is called ???understanding???. When this happens, the right
side of the rule is replaced by the left side on the stack.

<pre class="emlist">
[ A B C ]
    ↓         reduction
[ program ]
</pre>

This move is called "a reduction of `A B C`" to `program`". This term
is a little presomptious

この動作を「`A B C`を`program`に還元(reduce)する」と言う。
言葉は偉そうだがようするに白發中が揃うと大三元になるようなものだ。
……それは違うか。

そして`program`はプログラム全体を表すから、スタックに`program`だけがあると
いうことはプログラム全体を見付けたのかもしれない。だからここでちょうど
入力が終われば受理される。

もう少しだけ複雑な文法で試してみよう。

<pre class="emlist">
%token IF E S THEN END
%%
program : if

if      : IF expr THEN stmts END

expr    : E

stmts   : S
        | stmts S
</pre>

スキャナからの入力はこうだ。

<pre class="emlist">
IF  E  THEN  S  S  S  END
</pre>

このときのセマンティックスタックの遷移を以下に示す。

|スタック|動作|
||最初は空|
|`IF`|`IF`をシフト|
|`IF E`|`E`をシフト|
|`IF expr`|`E`→`expr`で還元|
|`IF expr THEN`|`THEN`をシフト|
|`IF expr THEN S`|`S`をシフト|
|`IF expr THEN stmts`|`S`→`stmts`で還元|
|`IF expr THEN stmts S`|`S`をシフト|
|`IF expr THEN stmts`|`stmts S`→`stmts`で還元|
|`IF expr THEN stmts S`|`S`をシフト|
|`IF expr THEN stmts`|`stmts S`→`stmts`で還元|
|`IF expr THEN stmts END`|`END`をシフト|
|`if`|`IF expr THEN stmts END`→`if`で還元|
|`program`|`if`→`program`で還元|
||accept.|

最後に一つだけ注意。還元では記号が減るとは限らない。
空規則があると「無」から記号が生成される場合もある。

h3. アクション

さて、ここからが重要なところだ。シフトだろうが還元だろうが、セマンティッ
クスタックの中でウダウダやっているだけでは何の意味もない。我々の最終目
標は構文木を生成することだったから、それにつながってくれないと困るのだ。
`yacc`はどう落としまえを付けるつもりなのか。「パーサが還元する瞬間をフッ
クできるようにしましょう」というのが`yacc`の出した答えだ。そのフックを
パーサのアクション(action)と言う。アクションは次のように規則の
最後に書く。

<pre class="emlist">
program: A B C { /* ここがアクション */ }
</pre>

`{`と`}`で囲んだ部分がアクションだ。こう書いておくと`A B C`を`program`に
還元する瞬間にこのアクションを実行してくれる。アクションでは何をしようと
自由だ。Cのコードならだいたいなんでも書ける。

h3. Value of symbols

そしてここからがさらに重要なのだが、全ての記号には「その値」というもの
がある。終端記号も非終端記号もだ。終端記号はスキャナから来るからその値
もスキャナからもらう。それは例えば記号`NUMBER`に対しては1とか9とか
108かもしれない。記号`IDENTIFIER`に対しては`"attr"`とか`"name"`とか
`"sym"`かもしれない。なんでもいいのだ。その値は記号といっしょにセマン
ティックスタックに積まれる。次の図は今ちょうど`S`を値と一緒にシフトし
たところだ。

<pre class="emlist">
IF    expr   THEN   stmts   S
値    値     値     値     値
</pre>

先程の規則によれば`stmts S`は`stmts`に還元できる。もしその規則にアクション
が書いてあればそれが実行されるわけだが、その時、右辺に対応する分の記号
の値をアクションに渡すのだ。

<pre class="emlist">
IF    expr   THEN   stmts  S      /* スタック */
値1   値2    値3    値4    値5
                    ↓     ↓
            stmts:  stmts  S      /* 規則 */
                    ↓     ↓
                  { $1  +  $2; }  /* アクション */
</pre>

と、このようにアクションでは`$1`、`$2`、`$3`……
で規則右辺に相当する記号の値を取ることができる。
`$1`とか`$2`はスタックを指す表現に`yacc`が書き換えてくれるわけだ。
もっともC言語なら本当は型のこととかいろいろあるのだけれど、
面倒なので当面`int`と仮定しておこう。

そして次は代わりに左辺の記号を積むのだが、記号はどれも値があるのだか
らその左辺の記号にもやはり値がなくてはいけない。それはアクション中では
`$$`と表現され、アクションを抜けたときの`$$`の値が左辺の記号の値となる。

<pre class="emlist">
IF    expr   THEN   stmts  S      /* 還元直前のスタック */
値1   値2    値3    値4    値5
                    ↓     ↓
            stmts:  stmts  S      /* 右辺が末尾にマッチした規則 */
              ↑    ↓     ↓
            { $$  = $1  +  $2; }  /* そのアクション */

IF    expr   THEN   stmts         /* 還元後のスタック */
値1   値2    値3    (値4+値5)
</pre>

最後に蛇足。記号の値は意味値、semantic valueと呼ばれることもある。
だからそれを入れるスタックはsemantic value stackで、
略してsemantic stackと呼ぶわけだ。

h3. `yacc`と型

さて実に面倒だが、型の話をしなければ話が収まらない。記号の値の型はいっ
たいなんだろう。結論から言うと`YYSTYPE`という型になる。きっとこれは
`YY Stack TYPE`か、はたまた`Semantic value TYPE`か、どちらかの略に違いない。
そして`YYSTYPE`は当然何か別の型の`typedef`である。その型とは、定義部で
`%union`という命令で指定した共用体だ。

だが今までは`%union`なんて書いていなかった。それなのにエラーにならなかっ
たのはどういうわけだろう。それは`yacc`が気をきかせて勝手にデフォルトでもっ
て処理してくれたからだ。Cでデフォルトと言えば当然`int`だ。ということ
で`YYSTYPE`のデフォルトは`int`である。

`yacc`の本に出す例や電卓プログラムくらいなら`int`のままでも構わないのだが、
構文木を作るには構造体やポインタやその他いろいろを使いたい。そこで例え
ば次のように`%union`を使う。

<pre class="emlist">
%union {
    struct node {
        int type;
        struct node *left;
        struct node *right;
    } *node;
    int num;
    char *str;
}
</pre>

今は実際に使うわけではないので型やメンバ名は適当だ。普通のCと違って
`%union`のブロックの最後にはセミコロンが必要ないので注意。

それで、こう書くと`y.tab.c`では次のようになるわけだ。

<pre class="emlist">
typedef union {
    struct node {
        int type;
        struct node *left;
        struct node *right;
    } *node;
    int num;
    char *str;
} YYSTYPE;
</pre>

そうするとセマンティックスタックは

<pre class="emlist">
YYSTYPE yyvs[256];       /* スタックの実体(yyvs = YY Value Stack) */
YYSTYPE *yyvsp = yyvs;   /* スタックの先端を指すポインタ */
</pre>

という感じだろうな、と予想が付く。
それならアクションに出てくる記号の値も……

<pre class="emlist">
/* yacc処理前のアクション */
target: A B C { func($1, $2, $3); }

/* 変換後、y.tab.cでの様子 */
{ func(yyvsp[-2], yyvsp[-1], yyvsp[0]); ;
</pre>

当然こうなる。

この場合はデフォルトの`int`を使ったのでスタックを参照するだけでよいが、
`YYSTYPE`が共用体の場合は同時にそのメンバも指定しなければアクセスでき
ないはずである。それには記号単位で結び付ける方法とその都度指定する
方法の二通りがある。

まずは一般的な、記号単位で指定する方法から。終端記号の場合は
`%token`を、非終端記号の場合は`%type`を使って次のように書く。

<pre class="emlist">
%token<num> A B C    /* 全てのA B Cの値はint型 */
%type<str> target    /* 全てのtargetの値はchar*型 */
</pre>

一方、毎回指定する場合は次のように`$`の次にメンバ名を割り込ませる。

<pre class="emlist">
%union { char *str; }
%%
target: { $<str>$ = "ようするにキャストみたいなものさ"; }
</pre>

こちらの方法はできるだけ使わないほうがいい。
記号単位でメンバを決めるのが基本だ。

h3. パーサとスキャナの連結

これでパーサの中の値のアレコレについては全て話した。あとはスキャナ
との連結プロトコルを話せば核となる事項は全ておしまいだ。

まず確認すると、スキャナは関数`yylex()`であった。
(終端)記号そのものは関数の返り値として(`int`で)返す。`yacc`が記
号と同じ名前で定数を`#define`してくれているので、記号`NUMBER`なら`NUMBER`と
書くだけでいい。そしてその値は`yylval`というグローバル変数に入れて渡す。
この`yylval`もまた`YYSTYPE`型で、パーサのときと全く同じことが言える。つま
り`%union`で定義すると共用体になる。しかし今回はメンバを勝手に選んだりは
してくれないので自分でメンバ名を書かないとだめだ。つまり非常に簡単な
例だと次のようになる。

<pre class="emlist">
static int
yylex()
{
    yylval.str = next_token();
    return STRING;
}
</pre>

ここまでの関係を図2にまとめたので一つ一つ確認してみてほしい。
`yylval`、`$$`、`$1`、`$2`……など、インターフェイスとなる変数は全て
`YYSTYPE`型である。

!images/ch_yacc_yaccvars.png(`yacc`関連の変数・関数の関係)!

h3. 埋め込みアクション

アクションは規則の最後に書くもの、と説明したが、実は規則の途中で
書いてしまうこともできる。

<pre class="emlist">
target: A B { puts("embedded action"); } C D
</pre>

これを埋め込みアクションと言う。
埋め込みアクションは次のような記述の
単なるシンタックスシュガーだ。

<pre class="emlist">
target: A B dummy C D

dummy :     /* 空規則 */
        {
            puts("embedded action");
        }
</pre>

実行されるタイミングなどはこれで全てわかるだろう。記号の値も普通に取れ
る。つまりこの例なら埋め込みアクションの値は`$3`として出てくる。

h2. 現実的な話題

h3. 衝突

もうこれで`yacc`なんて恐くない。

と思ったとしたらそれはかなり甘い。なぜ`yacc`がこれほどまでに
恐れられるのか、その理由はこの後にあるのだ。

これまでは「規則の右辺がスタック先端にマッチしたら」と何気なく書いて
きたが、次のような規則があったらどうなるのだろうか。

<pre class="emlist">
target  : A B C
        | A B C
</pre>

実際に`A B C`という記号列が出てきたとき、どちらの規則がマッチするのか
わからなくなるはずである。こんなものは人間にだって理解できない。
従って`yacc`もわからない。こういう変な文法を発見すると`yacc`は
reduce/reduce conflict(還元・還元衝突)が起きた、と文句を
言ってくる。複数の規則が同時に還元可能であるという意味だ。

<pre class="screen">
% yacc rrconf.y
conflicts:  1 reduce/reduce
</pre>

とはいえ普通ならば事故以外にこんなことはしないと思うが、
次の例はどうだろうか。記述している記号列は全く同じである。

<pre class="emlist">
target  : abc
        | A bc

abc     : A B C

bc      :   B C
</pre>

これならば比較的ありうる。特に規則を考えながらグチャグチャ移
動していると知らず知らずのうちにこんな規則ができてしまうものだ。

似たパターンで次のようなものもある。

<pre class="emlist">
target  : abc
        | ab C

abc     : A B C

ab      : A B
</pre>

`A B C`という記号列が現れた場合、`abc`一つを選ぶべきか`ab`と`C`の組み
合わせにすべきかわからない。こういうとき`yacc`は
shift/reduce conflict(シフト・還元衝突)が起きたぞ、と文句を垂れる。
こちらは、同時にシフトできる規則と還元できる規則があるという意味だ。

<pre class="screen">
% yacc srconf.y
conflicts:  1 shift/reduce
</pre>

shift/reduce conflictの有名な例が「ぶらさがり`else`問題」である。
例えばC言語の`if`文でこの問題が起こる。話を単純化して書いてみよう。

<pre class="emlist">
stmt     : expr ';'
         | if

expr     : IDENTIFIER

if       : IF '(' expr ')' stmt
         | IF '(' expr ')' stmt  ELSE stmt
</pre>

式は`IDENTIFIER`(変数)だけ、`if`の本体は文一つだけとして規則を作ってみた。
さて、この文法で次のプログラムをパースするとどういうことになるだろう。

<pre class="emlist">
if (cond)
    if (cond)
        true_stmt;
    else
        false_stmt;
</pre>

こう書いてしまうとなんとなく一目瞭然に見えるのだが、
実は次のようにも解釈できる。

<pre class="emlist">
if (cond) {
    if (cond)
        true_stmt;
}
else {
    false_stmt;
}
</pre>

つまり外側と内側どちらの`if`に`else`を付けるかという問題だ。

ただしshift/reduce conflictはreduce/reduce conflictに比べれば比較的無
害な衝突である。なぜかというと、たいていの場合はシフトを選べばうまくい
くからだ。シフトを選ぶというのは「できるだけ近い要素同士を連結する」と
だいたい同義語であり、人間の直感にマッチしやすい。実際、ぶらさがり
`else`もシフトしておけばうまくいく。そういうわけで`yacc`もその流れに従い
shift/reduce conflictが起きたときにはデフォルトでシフトを選ぶようになっ
ている。

h3. 先読み

試しに次の文法を`yacc`にかけてみてほしい。

<pre class="emlist">
%token A B C
%%
target  : A B C   /* 規則1 */
        | A B     /* 規則2 */
</pre>

どう考えても衝突しそうではないだろうか。`A B`まで読んだ時点で
規則1はシフトしたがるし、規則2は還元したがる。
つまりこれはshift/reduce conflictになるはずだ。ところが……

<pre class="screen">
% yacc conf.y
%
</pre>

おかしい、衝突しない。どうしてだろう。

実を言うと`yacc`で作ったパーサは記号を一つだけ
「先読み(look ahead)」できる。
本当にシフトや還元をする前に次の記号を盗み見て、どうするか判断
できるのだ。

だからパーサ生成時にもそれを考慮してくれて、一つの先読みで区別
できるなら衝突させない。例えば先程の規則なら`A B`の次に`C`が来れば
規則1しか可能性はないので規則1を選ぶ(シフトする)。入力が終わっ
たら規則2を選ぶ(還元する)。

注意してほしいのは「先読み」という単語には二通りの意味があることだ。
一つは`yacc`で`*.y`を処理するときの先読み。もう一つは生成したパーサを
実際に動かすときの先読み。実行時の先読みはたいして難しくないが`yacc`自身
の先読みは非常にややこしい。なぜなら文法規則だけから実行時のあらゆる
入力パターンを予測して挙動を決めないといけないからだ。

もっとも、実際には「あらゆる」は無理なので「かなりの」パターンに対処す
ることになる。そして全パターンのうちどのくらいの範囲に対処できるかどう
かが先読みアルゴリズムの強さになるわけだ。`yacc`が文法ファイル処理時に
使っている先読みアルゴリズムはLALR(1)と言い、現存する衝突解決アルゴリ
ズムの中ではわりと強力なものである。

いろいろ言ったが、本書でやるのは規則を読むだけで書くことではないので、
あまり心配することはない。ここで説明したかったのは文法を使った先読みで
はなく実行時の先読みのほうだ。

h3. Operators precedence order

しばらく抽象的な話が続いたのでここらでもう少し具体的な話をする。`+`や
`*`などの二項演算子(インフィックス型演算子)の規則を定義してみること
にしよう。これにも定石があるので、おとなしくそれに従っておけばいい。以
下に四則演算が使える電卓のようなものを定義した。

<pre class="emlist">
expr    : expr '+' expr
        | expr '-' expr
        | expr '*' expr
        | expr '/' expr
        | primary

primary : NUMBER
        | '(' expr ')'
</pre>

`primary`は「項」とか訳される。一番小さな文法単位のことである。
`expr`を括弧でくくると`primary`になるというところがポイントだ。

さて、この文法を適当にファイルに書いてコンパイルすると、こうなる。

<pre class="screen">
% yacc infix.y
16 shift/reduce conflicts
</pre>

激しく衝突してしまった。五分ばかり考えていればわかると思うが、
この規則では次のような場合に困るのである。

<pre class="emlist">
1 - 1 - 1
</pre>

これは次の二通りのどちらにも解釈できてしまう。

<pre class="emlist">
(1 - 1) - 1
1 - (1 - 1)
</pre>

数式として自然なのはもちろん前者だ。しかし`yacc`がやるのはあくまで見ため
の処理であって、そこに意味は全く入らない。`-`という記号の持つ意味なんてこれっ
ぽちも考慮してはくれないのだ。人間の意図を正しく反映させるには、やりた
いことを地道に指示してやらないといけない。

ではどうしたらいいかと言うと、定義部にこう書けばよい。

<pre class="emlist">
%left '+' '-'
%left '*' '/'
</pre>

この命令は演算子の優先順位と結合性の二つを同時に指定する。
順番に説明していこう。

優先順位という言葉はプログラム言語の文法の話をするときにはよく出てくる
と思う。理論的に話すとややこしいので直感的に言うと、次のような場合にど
ちらの演算子に括弧が付くかという話だ。

<pre class="emlist">
1 + 2 * 3
</pre>

`*`のほうが優先順位が高ければ、こうなる。

<pre class="emlist">
1 + (2 * 3)
</pre>

`+`のほうが優先順位が高ければ、こうなる。

<pre class="emlist">
(1 + 2) * 3
</pre>

このように、演算子に強いものと弱いものを設定して
shift/reduce conflictを解決するのが演算子優先順位だ。

だがしかし、同じ状況に陥っても優先順位が同じだったらどうすればいい
だろうか。例えばこのように。

<pre class="emlist">
1 - 2 - 3
</pre>

今度はどちらも`-`なので優先順位は全く同じだ。こういうときには結合性
を使って解決する。結合性にはleft right nonassocの三種類があり、
それぞれ次のように解釈される。

|結合性|解釈|
|left(左結合)|`(1 - 2) - 3`|
|right(右結合)|`1 - (2 - 3)`|
|nonassoc(非結合)|パースエラー|

数式用演算子だとほとんど左結合である。右結合は主に代入の`=`や
否定の`not`で使う。

<pre class="emlist">
a = b = 1    # (a = (b = 1))
not not a    # (not (not a))
</pre>

nonassocの代表格は比較演算子だろう。

<pre class="emlist">
a == b == c   # パースエラー
a <= b <= c   # パースエラー
</pre>

もっともPythonなどでは三項の比較が可能なのでこの限りではない。

それで先程の`%left`・`%right`・`%nonassoc`という命令は、
名前通りの結合性を示すために使われる。そして優先順位は並べる順で示す。
下にある演算子ほど優先順位が高い。同じ列にあれば同じ順位である。

<pre class="emlist">
%left  '+' '-'    /* 左結合で優先順位3 */
%left  '*' '/'    /* 左結合で優先順位2 */
%right '!'        /* 右結合で優先順位1 */
</pre>
