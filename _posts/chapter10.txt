$comment(-*- coding: utf-8 -*- vim:set encoding=utf-8:)$ 
Translated by Robert GRAVINA

h1. Chapter 10: Parser

h2. Outline of this chapter

h3. Parser construction

The parser is defined in the `yacc` source file `parse.y`, which `yacc` uses to
produce a working parser, `parse.c`.

Although one would expect `lex.c` to contain the scanner this is not the case.
This file is created by `gperf`, taking the file `keywords` as input, and
defines the reserved word hashtable. This tool-generated `lex.c` is `#include`d
in (the also tool-generated) `parse.c`. The details of this process is somewhat
difficult to explain at this time, so we shall return to this later.

Figure 1 shows the parser construction process. For the benifit of those readers
using Windows who may not be aware, the `mv` (move) command creates a new copy
of a file and removes the original. `cc` is, of course, the C compiler and `cpp`
the C pre-processor.

!images/ch_parser_build.png(Parser construction process)!

h3. Disecting `parse.y`

Let's now look at `parse.y` in a bit more detail. The following figure presents
a rough outline of the contents of `parse.y`.

▼ parse.y 
<pre class="longlist">
%{
header
%}
%union ....
%token ....
%type ....

%%

rules

%%
user code section
    parser interface
    scanner (character stream processing)
    syntax tree construction
    semantic analysis
    local variable management
    ID implementation
</pre>

Previously we briefly mentioned the rules and user code sections. With this
chapter we begin to study the parser in some detail and so turn our attention to
these sections.

There is a considerable number of support functions defined in the user code
section, however roughly speaking they can be divided into the six parts
previously mentioned. The following table shows where each of parts are
explained in this book.

|Category|Chapter|Section|
|Parser interface|This chapter|Section 3 "Scanning"|
|Scanner|This chapter|Section 3 "Scanning"|
|Syntax tree construction|Chapter 12 "Syntax tree construction"|Section 2 "Syntax tree construction"|
|Semantic analysos|Chapter 12 "Syntax tree construction"|Section 3 "Semantic analysis"|
|Local variable management|Chapter 12 "Syntax tree construction"|Section 4 "Local variables"|
|`ID` implementation|Chapter 3 "Names and name tables"|Section 2 "`ID` and symbols"|

h2. General remarks about grammar rules

h3. Coding rules

The grammar of `ruby` conforms to a coding standard and is thus easy to read
once you are familiar with it.

Firstly, regarding symbol names, all non-terminal symbols are written in lower
case characters. Terminal symbols are prefixed by some lower case character and
then followed by upper case. Reserved words (keywords) are prefixed with the
character `k`. Other terminal symbols are prefixed with the character `t`.

▼ Symbol name examples

|Token|Symbol name|
|(non-terminal symbol)|`bodystmt`|
|`if`|`kIF`|
|`def`|`kDEF`|
|`rescue`|`kRESCUE`|
|`varname`|`tIDENTIFIER`|
|`ConstName`|`tCONST`|
|1|`tINTEGER`|

The only exceptions to these rules are `klBEGIN` and `klEND`. These symbol names
refer to the reserved words for "BEGIN" and "END", respectively, and the `l`
here stands for `large`. Since the reserved words `begin` and `end` already
exist (naturally, with symbol names `kBEGIN` and `kEND`), these non-standard
symbol names were required.

h3. Important symbols

`parse.y` contains both grammar rules and actions, however for now I would like
to concentrate on the grammar rules alone. The script sample/exyacc.rb can be
used to extract the grammar rules from this file. Aside from this, running `yacc
-v` will create a logfile `y.output` which also contains the grammar rules,
however it is rather difficult to read. In this chapter I have used a slighty
modified version of `exyacc.rb`\footnote{modified `exyacc.rb`:`tools/exyacc2.rb`
located on the attached CD-ROM} to extract the grammar rules.

▼ `parse.y`(rules)
<pre class="longlist">
program         : compstmt

bodystmt        : compstmt
                  opt_rescue
                  opt_else
                  opt_ensure

compstmt        : stmts opt_terms
                       :
                       :
</pre>

The output is quite long - over 450 lines of grammar rules - and as such I have
only included the most important parts in this chapter.

Which symbols, then, are the most important? Symbols such as `program`, `expr`, 
`stmt`,`primary`, `arg` etc. represent the more general grammatical elements of 
a programming language and it is to these which we shall focus our attention. 
The following table outlines these general elements and the symbol names used 
to represent them.

|Syntax element|Relevant symbol names|
|Program|`program prog file input stmts whole`|
|Sentence|`statement stmt`|
|Expression|`expression expr exp`|
|Smallest element|`primary prim`|
|Left hand side of an expression|`lhs`(left hand side)|
|Right hand side of an expression|`rhs`(right hand side)|
|Function call|`funcall function_call call function`|
|Method call|`method method_call call`|
|Argument|`argument arg`|
|Function definition|`defun definition function fndef`|
|Declarations|`declaration decl`|

In general, programming lanaguages tend to have the following symbol heiarchy.

|Program element|Properties|
|Statement|Can not be combined with other symbols. A syntax tree trunk.|
|Expression|Can be combined with itself or be part of other 
expressions. A syntax tree interal node.|
|Primary|An element which can not be further decomposed. A syntax tree leaf node.| 

C function definitions and Java class definitions are examples of statements in 
other languages. An expression can be a procedure call, an arithmetic expression 
etc. while a primary usually refers to a string literal or number. Some languages 
do not contain all of these symbol types, however they generally contain some 
kind of hierarchy of symbols such as `program`→`stmt`→`expr`→`primary`.

It is often the case that symbol types lower in this heirarchy can be promoted 
to higher levels and vice versa. For example, in C function calls are expressions 
yet can be may also be statements.

Conversely, when surrounded in parenthesis expressions become primaries.

Scoping rules differ considerably between programming languages. Consider 
substitution. In C, the value of expressions can be used in substitutions 
whereas in Pascal substitution occurs only at the statement level. Also,
function and class definitions are typically statements however in languages 
such as Lisp and Scheme, since everything is an expression, they too are 
expressions. Ruby follows Lisp's design in this regard.

h3. Program structure

Now let's turn our attention to the grammer rules of `ruby`. Firstly, 
`yacc` will begin by examining the first rule defined in `parse.y`, and as 
we can see from the following table, this is `program`. From here we can see 
the ruby grammar unfold and the existance of the `program stmt expr primary` 
heierarchy mentioned earlier. However there is an extra rule here for `arg`. 
Let's now take a look at this.

▼ `ruby` grammar (outline)
<pre class="longlist">
program         : compstmt

compstmt        : stmts opt_terms

stmts           : none
                | stmt
                | stmts terms stmt

stmt            : kALIAS fitem  fitem
                | kALIAS tGVAR tGVAR
                    :
                    :
                | expr

expr            : kRETURN call_args
                | kBREAK call_args
                    :
                    :
                | '!' command_call
                | arg

arg             : lhs '=' arg
                | var_lhs tOP_ASGN arg
                | primary_value '[' aref_args ']' tOP_ASGN arg
                    :
                    :
                | arg '?' arg ':' arg
                | primary

primary         : literal
                | strings
                    :
                    :
                | tLPAREN_ARG expr  ')'
                | tLPAREN compstmt ')'
                    :
                    :
                | kREDO
                | kRETRY
</pre>

If you look at each of the final alternatives for each of the rules you should 
be able to clearly make out a hierarchy of `program`→`stmt`→`expr`→`arg`→
`primary`. 

I'd like to focus on the rule for `primary`.

<pre class="emlist">
primary         : literal
                    :
                    :
                | tLPAREN_ARG expr  ')'      /* here */
</pre>

The name `tLPAREN_ARG` comes from `t` for terminal symbol, `L` for left and 
`PAREN` for parentheses - it is the open parenthesis. Why this isn't `'('` 
is covered in the next section "Context-dependent scanner". The purpose of this 
rule is demote an `expr` to a `primary`, and is shown in Figure 2. This creates 
a cycle which can the seen in Figure 2, and the arrow shows how this rule is 
reduced during parsing.

!images/ch_parser_exprloop.png(`expr` demotion)!

The next rule is also particularly interesting.

<pre class="emlist">
primary         : literal
                    :
                    :
                | tLPAREN compstmt ')'   /* here */
</pre>

A `compstmt`, which represents code for an entire program, can be demoted to 
a `primary` with this rule. The next figure illustrates this rule in action.

!images/ch_parser_progloop.png(`program`の縮退)!

This means that for any syntax element in Ruby, if we surround it with 
parenthesis it will become a `primary` and can be passed as an argument to a 
function, be used as the right hand side of an expression etc. It helps to 
see an example of this to grasp what this truly means.

<pre class="emlist">
p((class C; end))
p((def a() end))
p((alias ali gets))
p((if true then nil else nil end))
p((1 + 1 * 1 ** 1 - 1 / 1 ^ 1))
</pre>

If we invoke `ruby` with the `-c` option (syntax check), we get the following 
output.

<pre class="screen">
% ruby -c primprog.rb
Syntax OK
</pre>

Although it might look surprising at first, yes you really can do this in Ruby!

The details of this are covered when we look at semantic analysis (in Chaper 12 
"Syntax tree construction") however it is important to note there are exceptions 
to this rule. For example passing a `return` statement as an argument to a 
function will result in an error. For the most part, however, the "surrounding 
anything in parenthesis means it can be passed as an argument to a function" 
rule does hold.

In the next section I will cover the most important grammar rules in some detail.

h3. `program`

▼ `program`
<pre class="longlist">
program         : compstmt

compstmt        : stmts opt_terms

stmts           : none
                | stmt
                | stmts terms stmt
</pre>

As mentioned earlier, `program` represents an entire program in the grammar. 
For all intents and purposes `compstmts` is equivilent to `program`. 

前述の通り`program`は文法全体、即ちプログラム全体を表している。その
`program`は`compstmts`と同じであり、`compstmts`は`stmts`とほぼ同じである。
その`stmts`は`terms`区切りの`stmt`のリストである。つまりプログラム全体は
`terms`区切りの`stmt`のリストである。

`terms`はもちろんterminatorsの略で、文を終端する記号、セミコロンだとか
改行のことだ。`opt_terms`はOPTional `terms`(省略可能な`terms`)だろう。
定義は次のようになっている。

▼ `opt_terms`
<pre class="longlist">
opt_terms       :
                | terms

terms           : term
                | terms ';'

term            : ';'
                | '\n'
</pre>

`terms`は`';'`か`'\n'`の後に任意の数だけ`';'`が続く並びなので、
この規則だけから考えると二個以上の改行があるとまずいように
思える。実際に試してみよう。

<pre class="emlist">
1 + 1   # 改行一つめ
        # 改行二つめ
        # 改行三つめ
1 + 1
</pre>

再び`ruby -c`を使う。

<pre class="screen">
% ruby -c optterms.rb
Syntax OK
</pre>

おかしい。通ってしまった。実を言うと、連続した改行はスキャナのレベルで
捨てられてしまってパーサには最初の一つしか渡らないようになっているのだ。

ところで、`program`と`compstmt`は同じものだと言ったが、それならこの規則は
何のために存在するのだろう。実はこれはアクションを実行するためだけにあ
るのだ。例えば`program`ならプログラム全体について一度だけ必要な処理を実
行するために用意されている。純粋に文法のことだけ考えるなら`program`は省
略しても全く問題ない。

これを一般化すると、規則には見ための解析のために必要なものと、アクショ
ンを実行するために必要なものの二種類があるということになる。`stmts`のと
ころにある`none`もアクションのために必要な規則の一つで、空リストに対して
(`NODE*`型の)`NULL`ポインタを返すために用意されている。

h3. `stmt`

次に文、`stmt`だ。`stmt`の規則はわりと量があるので、少しずつ見ていく
ことにする。

▼ `stmt`(1)
<pre class="longlist">
stmt            : kALIAS fitem  fitem
                | kALIAS tGVAR tGVAR
                | kALIAS tGVAR tBACK_REF
                | kALIAS tGVAR tNTH_REF
                | kUNDEF undef_list
                | stmt kIF_MOD expr_value
                | stmt kUNLESS_MOD expr_value
                | stmt kWHILE_MOD expr_value
                | stmt kUNTIL_MOD expr_value
                | stmt kRESCUE_MOD stmt
                | klBEGIN '{' compstmt '}'
                | klEND '{' compstmt '}'
</pre>

なんとなくわかる。最初にいくつかあるのは`alias`だし、
次が`undef`、その後にいくつか並ぶ「なんたら`_MOD`」は
modifier(修飾子)のことだろうから、後置系構文だと想像が付く。

`expr_value`や`primary_value`はアクションのために用意されている規則である。
例えば`expr_value`なら値(value)を持つ`expr`であることを示す。値
を持たない`expr`とは`return`や`break`、あるいはそういうものを含む`if`文
などのことだ。「値を持つ」の詳しい定義は
第12章『構文木の構築』で見る。
`primary_value`も同じく「値を持つ」`primary`である。

`klBEGIN`と`klEND`は説明した通り`BEGIN`と`END`のこと。

▼ `stmt`(2)
<pre class="longlist">
                | lhs '=' command_call
                | mlhs '=' command_call
                | var_lhs tOP_ASGN command_call
                | primary_value '[' aref_args ']' tOP_ASGN command_call
                | primary_value '.' tIDENTIFIER tOP_ASGN command_call
                | primary_value '.' tCONSTANT tOP_ASGN command_call
                | primary_value tCOLON2 tIDENTIFIER tOP_ASGN command_call
                | backref tOP_ASGN command_call
</pre>

この規則は全部くくって見るのが正しい。
共通点は右辺に`command_call`が来る代入であることだ。
`command_call`は引数括弧を省略したメソッド呼び出しである。
新しく出てきた記号は以下に表を置いておくので対照しながら確かめてほしい。

|`lhs`|代入の左辺(Left Hand Side)|
|`mlhs`|多重代入の左辺(Multiple Left Hand Side)|
|`var_lhs`|代入の左辺、ただし変数系のみ(VARiable Left Hand Side)|
|`tOP_ASGN`|`+=`や`*=`など組み合わせ代入記号(OPerator ASsiGN)|
|`aref_args`|`[]`メソッド呼び出しの引数に使える表現(Array REFerence)|
|`tIDENTIFIER`|ローカル変数に使える識別子|
|`tCONSTANT`|定数に使える識別子(一文字目が大文字)|
|`tCOLON2`|`::`|
|`backref`|`$1 $2 $3...`|

ちなみにarefはLisp用語だ。対になるasetというのもあって、そちらは
array setの略。この略語は`ruby`のソースコードのいろいろなところで
使われている。

▼ `stmt`(3)
<pre class="longlist">
                | lhs '=' mrhs_basic
                | mlhs '=' mrhs
</pre>

この二つは多重代入である。`mrhs`は`mlhs`と同じ作りで、multipleな
`rhs`(右辺)。
こう見てくると、名前の意味を知るだけでもかなりわかりやすいということが
わかる。

▼ `stmt`(4)
<pre class="longlist">
                | expr
</pre>

最後に、`expr`へ連結する。

h3. `expr`

▼ `expr`
<pre class="longlist">
expr            : kRETURN call_args
                | kBREAK call_args
                | kNEXT call_args
                | command_call
                | expr kAND expr
                | expr kOR expr
                | kNOT expr
                | '!' command_call
                | arg
</pre>

式。`ruby`の式は文法上はかなり小さい。なぜなら普通は`expr`に入るものがほと
んど`arg`に行ってしまっているからだ。逆に言うと、ここには`arg`に行けなかっ
たものが残っているということになる。では行けなかったものはなにかと言う
と、これまたメソッド呼び出し括弧の省略組である。`call_args`は剥き出しの
引数リストで、`command_call`は先程言ったとおり括弧省略メソッドのこと。こ
ういうものを「小さい」単位に入れると衝突しまくることになる。

ただし以下の二つだけは種類が違う。

<pre class="emlist">
expr kAND expr
expr kOR expr
</pre>

`kAND`は「`and`」で`kOR`は「`or`」。この二つは制御構造としての役割があ
るので、`command_call`以上に「大きい」構文単位に入れなければならない。
そして`command_call`は`expr`にある。だから最低でも`expr`にしてやらない
とうまくいかない。例えば次のような使いかたが存在するのだが……

<pre class="emlist">
  valid_items.include? arg  or raise ArgumentError, 'invalid arg'
# valid_items.include?(arg) or raise(ArgumentError, 'invalid arg')
</pre>

もし`kAND`の規則が`expr`でなくて`arg`にあったとすると、次のように
連結されてしまうことになる。

<pre class="emlist">
valid_items.include?((arg or raise)) ArgumentError, 'invalid arg'
</pre>

当然パースエラーだ。

h3. `arg`

▼ `arg`
<pre class="longlist">
arg             : lhs '=' arg
                | var_lhs tOP_ASGN arg
                | primary_value '[' aref_args ']' tOP_ASGN arg
                | primary_value '.' tIDENTIFIER tOP_ASGN arg
                | primary_value '.' tCONSTANT tOP_ASGN arg
                | primary_value tCOLON2 tIDENTIFIER tOP_ASGN arg
                | backref tOP_ASGN arg
                | arg tDOT2 arg
                | arg tDOT3 arg
                | arg '+' arg
                | arg '-' arg
                | arg '*' arg
                | arg '/' arg
                | arg '%' arg
                | arg tPOW arg
                | tUPLUS arg
                | tUMINUS arg
                | arg '|' arg
                | arg '^' arg
                | arg '&' arg
                | arg tCMP arg
                | arg '>' arg
                | arg tGEQ arg
                | arg '<' arg
                | arg tLEQ arg
                | arg tEQ arg
                | arg tEQQ arg
                | arg tNEQ arg
                | arg tMATCH arg
                | arg tNMATCH arg
                | '!' arg
                | '~' arg
                | arg tLSHFT arg
                | arg tRSHFT arg
                | arg tANDOP arg
                | arg tOROP arg
                | kDEFINED opt_nl  arg
                | arg '?' arg ':' arg
                | primary
</pre>

規則の数は多いが、文法の複雑さは規則の数には比例しない。単に場合分けが
多いだけの文法は`yacc`にとっては非常に扱いやすく、むしろ規則の深さである
とか再帰のほうが複雑さに影響する。

そうすると演算子のところで`arg OP arg`という形で再帰しているのが気になる
のだが、これらの演算子には全て演算子優先順位が設定されているため
実質上ただの列挙にすぎない。
そこで`arg`の規則からそういう「ただの列挙」を併合して削ってしまおう。

<pre class="emlist">
arg: lhs '=' arg              /* 1 */
   | primary T_opeq arg       /* 2 */
   | arg T_infix arg          /* 3 */
   | T_pre arg                /* 4 */
   | arg '?' arg ':' arg      /* 5 */
   | primary                  /* 6 */
</pre>

終端記号および終端記号のリストは区別する意味がないので全部まとめて`T_`の
付く記号で表現した。`opeq`は`operator + equal`、`T_pre`は`'!'`や`'~'`の
ような前置型演算子、`T_infix`は`'*'`や`'%'`と言った二項演算子を表す。

この構造で衝突しないためには以下のようなことが重要になる
(ただしこれが全てではない)。

* `T_infix`が`'='`を含まないこと

`arg`は`lhs`と部分的に重なるので`'='`があると規則1と3が区別できない。

* `T_opeq`と`T_infix`が共通項を持たないこと

`arg`は`primary`を含むから共通項を持つと規則2と3が区別できない。

* `T_infix`の中に`'?'`がないこと

もし含むと規則3と5がshift/reduce conflictを起こす。

* `T_pre`が`'?'`や`':'`を含まない

もし含むと規則4と5がかなり複雑に衝突する。

結論としては全ての条件が成立しているので、この文法は衝突しない。
当然と言えば当然だ。

h3. `primary`

`primary`は規則が多いので最初から分割して示す。

▼ `primary`(1)
<pre class="longlist">
primary         : literal
                | strings
                | xstring
                | regexp
                | words
                | qwords
</pre>

リテラル類。`literal`は`Symbol`リテラル(`:sym`)と数値。

▼ `primary`(2)
<pre class="longlist">
                | var_ref
                | backref
                | tFID
</pre>

変数類。`var_ref`はローカル変数やインスタンス変数など。
`backref`は`$1 $2 $3`……。
`tFID`は`!`や`?`が付いた識別子、例えば`include? reject!`など。
`tFID`はローカル変数ではありえないので、
それ単独で出てきたとしてもパーサレベルでメソッド呼び出しになる。

▼ `primary`(3)
<pre class="longlist">
                | kBEGIN
                  bodystmt
                  kEND
</pre>

`bodystmt`が`rescue`や`ensure`も含んでいる。
つまりこれは例外制御の`begin`である。

▼ `primary`(4)
<pre class="longlist">
                | tLPAREN_ARG expr  ')'
                | tLPAREN compstmt ')'
</pre>

既に説明した。構文縮退。

▼ `primary`(5)
<pre class="longlist">
                | primary_value tCOLON2 tCONSTANT
                | tCOLON3 cname
</pre>

定数の参照。`tCONSTANT`は定数名(大文字で始まる識別子)。

`tCOLON2`は`::`と`tCOLON3`は両方とも`::`なのだが、`tCOLON3`はトップレベルを
意味する`::`だけを表している。つまり`::Const`という場合の`::`である。
`Net::SMTP`のような`::`は`tCOLON2`だ。

同じトークンに違う記号が使われているのは括弧省略メソッドに対応する
ためである。例えば次の二つを見分けるためだ。

<pre class="emlist">
p Net::HTTP    # p(Net::HTTP)
p Net  ::HTTP  # p(Net(::HTTP))
</pre>

直前にスペースがあるか、あるいは開き括弧などの境界文字がある場合は
`tCOLON3`でそれ以外では`tCOLON2`になる。

▼ `primary`(6)
<pre class="longlist">
                | primary_value '[' aref_args ']'
</pre>

インデックス形式の呼び出し、例えば`arr[i]`。

▼ `primary`(7)
<pre class="longlist">
                | tLBRACK aref_args ']'
                | tLBRACE assoc_list '}'
</pre>

配列リテラルとハッシュリテラル。こちらの`tLBRACK`も`'['`を表して
いるのだが、`'['`は`'['`でも前に空白のない`'['`のこと。この区別が必要
なのもメソッド呼び出し括弧の省略の余波だ。

それにしてもこの規則の終端記号は一文字しか違わないので非常にわかりずらい。
以下の表に括弧の読みかたを書いておいたので対照しながら読んでほしい。

▼ 各種括弧の英語名

|記号|英語名|日本語名(の一例)|
|`( )`|parentheses|丸括弧、括弧|
|`{ }`|braces|ヒゲ括弧、中括弧|
|`[ ]`|brackets|角括弧、大括弧|

▼ `primary`(8)
<pre class="longlist">
                | kRETURN
                | kYIELD '(' call_args ')'
                | kYIELD '(' ')'
                | kYIELD
                | kDEFINED opt_nl '('  expr ')'
</pre>

メソッド呼び出しと形式が似ている構文。
順番に、`return`、`yield`、`defined?`。

`yield`には引数が付いているのに`return`に引数がないのはどうしてだろう。
根本的な原因は、`yield`はそれ自体に返り値があるのに対し`return`には返り値が
ないことである。ただし、ここで引数がないからといって値を渡せないわけでは、
もちろんない。`expr`に次のような規則があった。

<pre class="emlist">
kRETURN call_args
</pre>

`call_args`は剥き出しの引数リストなので`return 1`や`return nil`には対
処できる。`return(1)`のようなものは`return (1)`として扱われる。という
ことは、次のように引数が二個以上ある`return`には括弧が付けられないはず
だ。

<pre class="emlist">
return(1, 2, 3)   # return  (1,2,3)と解釈されてパースエラー
</pre>

このあたりは次章『状態付きスキャナ』を読んでから
もう一度見てもらうとよくわかるだろう。

▼ `primary`(9)
<pre class="longlist">
                | operation brace_block
                | method_call
                | method_call brace_block
</pre>

メソッド呼び出し。`method_call`は引数あり(括弧もある)、`operation`は
括弧も引数もなし。`brace_block`は`{`〜`}`か`do`〜`end`で、それがついて
いるメソッドとはつまりイテレータだ。`brace`なのになぜ`do`〜`end`が入る
のか……ということにはマリアナ海溝よりも深淵な理由があるのだが、これも
やはり次章『状態付きスキャナ』を読んでもらうしかない。

▼ `primary`(10)
<pre class="longlist">
  | kIF expr_value then compstmt if_tail kEND         # if
  | kUNLESS expr_value then compstmt opt_else kEND    # unless
  | kWHILE expr_value do compstmt kEND                # while
  | kUNTIL expr_value do compstmt kEND                # until
  | kCASE expr_value opt_terms case_body kEND         # case
  | kCASE opt_terms case_body kEND                    # case(形式2)
  | kFOR block_var kIN expr_value do compstmt kEND    # for
</pre>

基本制御構造。ちょっと意外なのは、こんなデカそうなものが`primary`という
「小さい」ものの中にあることだ。`primary`は`arg`でもあるのでこんなこと
もできるということになる。

<pre class="emlist">
p(if true then 'ok' end)   # "ok"と表示される
</pre>

Rubyの特徴の一つに「ほとんどの構文要素が式」というのがあった。
`if`や`while`が`primary`にあることでそれが具体的に表現されている。

それにしてもどうしてこんな「大きい」要素が`primary`にあって大丈夫なのだ
ろう。それはRubyの構文が「終端記号Aで始まり終端記号Bで終わる」
という特徴があるからに他ならない。この点については次の項で改めて
考えてみる。

▼ `primary`(11)
<pre class="longlist">
  | kCLASS cname superclass bodystmt kEND        # クラス定義
  | kCLASS tLSHFT expr term bodystmt kEND        # 特異クラス定義
  | kMODULE cname bodystmt kEND                  # モジュール定義
  | kDEF fname f_arglist bodystmt kEND           # メソッド定義
  | kDEF singleton dot_or_colon fname f_arglist bodystmt kEND
                                                 # 特異メソッド定義
</pre>

定義文。クラス文クラス文と呼んできたが、本当はクラス項と呼ぶべきで
あったか。これらも全て「終端記号Aで始まりBで終わる」パターンなので、
いくら増えたところで一向に問題はない。

▼ `primary`(12)
<pre class="longlist">
                | kBREAK
                | kNEXT
                | kREDO
                | kRETRY
</pre>

各種ジャンプ。このへんはまあ、文法的にはどうでもいい。

h3. 衝突するリスト

先の項では`if`が`primary`なんかにあって大丈夫なのだろうか、という疑問を
提示した。厳密に証明するにはなかなか難しいのだが、感覚的にならわりと
簡単に説明できる。ここでは次のような小さい規則でシミュレーション
してみよう。

<pre class="emlist">
%token A B o
%%
element   : A item_list B

item_list :
          | item_list item

item      : element
          | o
</pre>

`element`がこれから問題にしようとしている要素だ。例えば`if`について考える
なら`if`だ。`element`は終端記号`A`で始まり`B`で終わるリストである。
`if`で言うなら`if`で始まり`end`で終わる。内容物の`o`はメソッドや
変数参照やリテラルである。リストの要素には、その`o`か、または`element`が
ネストする。

この文法に基くパーサで次のような入力をパースしてみよう。

<pre class="emlist">
A  A  o  o  o  B  o  A  o  A  o  o  o  B  o  B  B
</pre>

ここまでネストしまくっていると人間にはインデントなどの助けがないとちょっ
とわかりにくい。だが次のように考えればわりと簡単である。いつか必ず
`A`と`B`が`o`だけを狭んで現れるので、それを消して`o`に変える。それを繰り
返すだけでいい。結論は図4のようになる。

!images/ch_parser_ablist.png(Aで始まりBで終わるリストのリストをパース)!

しかしもし終端の`B`がなかったりすると……

<pre class="emlist">
%token A o
%%
element   : A item_list    /* Bを消してみた */

item_list :
          | item_list item

item      : element
          | o
</pre>

これを`yacc`で処理すると2 shift/reduce conflictsと出た。つまりこの文法は
曖昧である。入力は、先程のものから単純に`B`を抜くと次のようになってしまう。

<pre class="emlist">
A  A  o  o  o  o  A  o  A  o  o  o  o
</pre>

どうにもよくわからない。しかしshift/reduce conflictはシフトしろ、とい
うルールがあったので、試しにそれに従ってシフト優先(即ち内側優先)でパー
スしてみよう(図5)。

!images/ch_parser_alist.png(Aで始まるリストのリストをパース)!

とりあえずパースできた。しかしこれでは入力と意図が全く違うし、どうやっ
ても途中でリストを切ることができなくなってしまった。

実はRubyの括弧省略メソッドはこれと似たような状態にある。わかりにくいが、
メソッド名と第一引数が合わせて`A`だ。なぜならその二つの間にだけカンマが
ないので、新しいリストの始まりだと認識できるからである。

他に「現実的な」HTMLもこのパターンを含む。例えば``や``が省略され
たときはこうなる。そういうわけで`yacc`は普通のHTMLにはまるで通用しない。

h2. スキャナ

h3. パーサ概形

スキャナに移る前にパーサの概形について説明しておこう。
図6を見てほしい。

!images/ch_parser_interf.png(パーサインターフェイス(コールグラフ))!

パーサの公式インターフェイスは`rb_compile_cstr()`、
`rb_compile_string()`、
`rb_compile_file()`の三つである。それぞれCの文字列、Rubyの文字列オブジェク
ト、Rubyの`IO`オブジェクトからプログラムを読み込んでコンパイルする。

これらの関数は直接間接に`yycompile()`を呼び出し、最終的に`yacc`が生成した
`yyparse()`に完全に制御を移す。パーサの中心とはこの`yyparse()`に他ならない
のだから、`yyparse()`を中心に把握してやるとよい。即ち`yyparse()`に移る前の
関数は全て前準備であり、`yyparse()`より後の関数は`yyparse()`にこき使われ
る雑用関数にすぎない。

`parse.y`にある残りの関数は`yylex()`から呼び出される補助関数群だが、こちらも
また明確に分類することができる。

まずスキャナの最も低レベルな部分には入力バッファがある。`ruby`はソースプ
ログラムをRubyの`IO`オブジェクトか文字列のどちらからでも入力できるように
なっており、入力バッファはそれを隠蔽して単一のバイトストリームに見せか
ける。

次のレベルはトークンバッファである。入力バッファから1バイト
ずつ読んだらトークンが一つ完成するまでここにまとめてとっておく。

従って`yylex`全体の構造は図7のように図示できる。

!images/ch_parser_scanner.png(スキャナの全体像)!

h3. 入力バッファ

まず入力バッファから見ていこう。インターフェイスは
`nextc()`、`pushback()`、`peek()`の三つだけだ。

しつこいようだがまずデータ構造を調べるのだった。
入力バッファの使う変数はこうだ。

▼ 入力バッファ
<pre class="longlist">
2279  static char *lex_pbeg;
2280  static char *lex_p;
2281  static char *lex_pend;

(parse.y)
</pre>

バッファの先頭と現在位置、終端。どうやらこのバッファは単純な一列の
文字列バッファらしい(図8)。

!images/ch_parser_ibuffer.png(入力バッファ)!

h4. `nextc()`

ではこれを使っているところを見てみる。まずは一番オーソドックスと
思われる`nextc()`から。

▼ `nextc()`
<pre class="longlist">
2468  static inline int
2469  nextc()
2470  {
2471      int c;
2472
2473      if (lex_p == lex_pend) {
2474          if (lex_input) {
2475              VALUE v = lex_getline();
2476
2477              if (NIL_P(v)) return -1;
2478              if (heredoc_end > 0) {
2479                  ruby_sourceline = heredoc_end;
2480                  heredoc_end = 0;
2481              }
2482              ruby_sourceline++;
2483              lex_pbeg = lex_p = RSTRING(v)->ptr;
2484              lex_pend = lex_p + RSTRING(v)->len;
2485              lex_lastline = v;
2486          }
2487          else {
2488              lex_lastline = 0;
2489              return -1;
2490          }
2491      }
2492      c = (unsigned char)*lex_p++;
2493      if (c == '\r' && lex_p <= lex_pend && *lex_p == '\n') {
2494          lex_p++;
2495          c = '\n';
2496      }
2497
2498      return c;
2499  }

(parse.y)
</pre>

最初の`if`で入力バッファの最後まで行ったかどうかテストしているようだ。そ
してその内側の`if`は、`else`で`-1`(`EOF`)を返していることから入力全体の
終わりをテストしているのだと想像できる。逆に言えば、入力が終わったときには
`lex_input`が0になる。

ということは入力バッファには少しずつ文字列が入ってきているのだというこ
とがわかる。その単位はと言うと、バッファを更新する関数の名前が
`lex_getline()`なので行に間違いない。

まとめるとこういうことだ。

<pre class="emlist">
if (バッファ終端に到達した)
    if (まだ入力がある)
        次の行を読み込む
    else
        return EOF
ポインタを進める
CRを読み飛ばす
return c
</pre>

行を補給する関数`lex_getline()`も見てみよう。
この関数で使う変数も一緒に並べておく。

▼ `lex_getline()`
<pre class="longlist">
2276  static VALUE (*lex_gets)();     /* gets function */
2277  static VALUE lex_input;         /* non-nil if File */

2420  static VALUE
2421  lex_getline()
2422  {
2423      VALUE line = (*lex_gets)(lex_input);
2424      if (ruby_debug_lines && !NIL_P(line)) {
2425          rb_ary_push(ruby_debug_lines, line);
2426      }
2427      return line;
2428  }

(parse.y)
</pre>

最初の行以外はどうでもよい。
`lex_gets`が一行読み込み関数へのポインタ、`lex_input`が本当の入力だろう。
`lex_gets`をセットしているところを検索してみると、こう出た。

▼ `lex_gets`をセット
<pre class="longlist">
2430  NODE*
2431  rb_compile_string(f, s, line)
2432      const char *f;
2433      VALUE s;
2434      int line;
2435  {
2436      lex_gets = lex_get_str;
2437      lex_gets_ptr = 0;
2438      lex_input = s;

2454  NODE*
2455  rb_compile_file(f, file, start)
2456      const char *f;
2457      VALUE file;
2458      int start;
2459  {
2460      lex_gets = rb_io_gets;
2461      lex_input = file;

(parse.y)
</pre>

`rb_io_gets()`はパーサ専用というわけではなく、`ruby`の汎用ライブラリだ。
`IO`オブジェクトから一行読み込む関数である。

一方の`lex_get_str()`は次のように定義されている。

▼ `lex_get_str()`
<pre class="longlist">
2398  static int lex_gets_ptr;

2400  static VALUE
2401  lex_get_str(s)
2402      VALUE s;
2403  {
2404      char *beg, *end, *pend;
2405
2406      beg = RSTRING(s)->ptr;
2407      if (lex_gets_ptr) {
2408          if (RSTRING(s)->len == lex_gets_ptr) return Qnil;
2409          beg += lex_gets_ptr;
2410      }
2411      pend = RSTRING(s)->ptr + RSTRING(s)->len;
2412      end = beg;
2413      while (end < pend) {
2414          if (*end++ == '\n') break;
2415      }
2416      lex_gets_ptr = end - RSTRING(s)->ptr;
2417      return rb_str_new(beg, end - beg);
2418  }

(parse.y)
</pre>

この関数はいいだろう。`lex_gets_ptr`が既に読み込んだところを記憶している。
それを次の`\n`まで移動し、同時にそこを切り取って返す。

ここで`nextc`に戻ろう。このように同じインターフェイスの関数を二つ用意
して、パーサの初期化のときに関数ポインタを切り替えてしまうことで他の部
分を共通化しているわけだ。コードの差分をデータに変換して吸収していると
も言える。`st_table`にも似たような手法があった。

h4. `pushback()`

バッファの物理構造と`nextc()`がわかればあとは簡単だ。
一文字書き戻す`pushback()`。Cで言えば`ungetc()`である。

▼ `pushback()`
<pre class="longlist">
2501  static void
2502  pushback(c)
2503      int c;
2504  {
2505      if (c == -1) return;
2506      lex_p--;
2507  }

(parse.y)
</pre>

h4. `peek()`

そしてポインタを進めずに次の文字をチェックする`peek()`(語意は
「覗き見る」)。

▼ `peek()`
<pre class="longlist">
2509  #define peek(c) (lex_p != lex_pend && (c) == *lex_p)

(parse.y)
</pre>

h3. トークンバッファ

トークンバッファは次のレベルのバッファである。
トークンが一つ切り出せるまで文字列を保管しておく。
インターフェイスは以下の五つである。

|`newtok`|新しいトークンを開始する|
|`tokadd`|バッファに文字を足す|
|`tokfix`|バッファを終端する|
|`tok`|バッファリングしている文字列の先頭へのポインタ|
|`toklen`|バッファリングしている文字列長さ|
|`toklast`|バッファリングしている文字列の最後のバイト|

ではまずデータ構造から見ていく。

▼ トークンバッファ
<pre class="longlist">
2271  static char *tokenbuf = NULL;
2272  static int   tokidx, toksiz = 0;

(parse.y)
</pre>

`tokenbuf`がバッファで、`tokidx`がトークンの末尾(`int`なのでインデッ
クスらしい)、`toksiz`がバッファ長だろう。こちらも入力バッファと同じく
単純な構造だ。絵にすると図9のようになる。

!images/ch_parser_tbuffer.png(トークンバッファ)!

引き続きインターフェイスに行って、新しいトークンを開始する`newtok()`を
読もう。

▼ `newtok()`
<pre class="longlist">
2516  static char*
2517  newtok()
2518  {
2519      tokidx = 0;
2520      if (!tokenbuf) {
2521          toksiz = 60;
2522          tokenbuf = ALLOC_N(char, 60);
2523      }
2524      if (toksiz > 4096) {
2525          toksiz = 60;
2526          REALLOC_N(tokenbuf, char, 60);
2527      }
2528      return tokenbuf;
2529  }

(parse.y)
</pre>

バッファ全体の初期化インターフェイスというのはないので、バッファが初期
化されていない可能性がある。だから最初の`if`でそれをチェックし初期化す
る。`ALLOC_N()`は`ruby`が定義しているマクロで、`calloc()`とだいたい
同じだ。

割り当てる長さは初期値で60だが、大きくなりすぎていたら(`> 4096`)小さく
戻している。一つのトークンがそんなに長くなることはまずないので、このサ
イズで現実的だ。

次はトークンバッファに文字を追加する`tokadd()`を見る。

▼ `tokadd()`
<pre class="longlist">
2531  static void
2532  tokadd(c)
2533      char c;
2534  {
2535      tokenbuf[tokidx++] = c;
2536      if (tokidx >= toksiz) {
2537          toksiz *= 2;
2538          REALLOC_N(tokenbuf, char, toksiz);
2539      }
2540  }

(parse.y)
</pre>

一行目で文字を追加。そのあとトークン長をチェックし、バッファ末尾を
越えそうだったら`REALLOC_N()`する。`REALLOC_N()`は引数指定方式が
`calloc()`と同じ`realloc()`だ。

残りのインターフェイスはまとめてしまう。

▼ `tokfix() tok() toklen() toklast()`
<pre class="longlist">
2511  #define tokfix() (tokenbuf[tokidx]='\0')
2512  #define tok() tokenbuf
2513  #define toklen() tokidx
2514  #define toklast() (tokidx>0?tokenbuf[tokidx-1]:0)

(parse.y)
</pre>

問題ないだろう。

h3. `yylex()`

`yylex()`はとても長い。現在1000行以上ある。そのほとんどが巨大な
`switch`文一つで占められており、文字ごとに分岐するようになっている。
まず一部省略して全体構造を示す。

▼ `yylex`概形
<pre class="longlist">
3106  static int
3107  yylex()
3108  {
3109      static ID last_id = 0;
3110      register int c;
3111      int space_seen = 0;
3112      int cmd_state;
3113
3114      if (lex_strterm) {
              /* ……文字列のスキャン…… */
3131          return token;
3132      }
3133      cmd_state = command_start;
3134      command_start = Qfalse;
3135    retry:
3136      switch (c = nextc()) {
3137        case '\0':                /* NUL */
3138        case '\004':              /* ^D */
3139        case '\032':              /* ^Z */
3140        case -1:                  /* end of script. */
3141          return 0;
3142
3143          /* white spaces */
3144        case ' ': case '\t': case '\f': case '\r':
3145        case '\13': /* '\v' */
3146          space_seen++;
3147          goto retry;
3148
3149        case '#':         /* it's a comment */
3150          while ((c = nextc()) != '\n') {
3151              if (c == -1)
3152                  return 0;
3153          }
3154          /* fall through */
3155        case '\n':
              /* ……省略…… */

            case xxxx:
                :
              break;
                :
            /* 文字ごとにたくさん分岐 */
                :
                :
4103        default:
4104          if (!is_identchar(c) || ISDIGIT(c)) {
4105              rb_compile_error("Invalid char `\\%03o' in expression", c);
4106              goto retry;
4107          }
4108
4109          newtok();
4110          break;
4111      }

          /* ……通常の識別子を扱う…… */
      }

(parse.y)
</pre>

`yylex()`の返り値はゼロが「入力終わり」、非ゼロなら記号である。

「`c`」などという非常に簡潔な変数が全体に渡って使われているので注意。
スペースを読んだときの`space_seen++`は後で役に立つ。

あとは文字ごとに分岐してひたすら処理すればよいのだが、単調な処理が続く
ので読むほうはとても退屈だ。そこでいくつかポイントを絞って見てみること
にする。本書では全ての文字は解説しないが、同じパターンを敷衍していけば
簡単である。

h4. `'!'`

まずは簡単なものから見てみよう。

▼ `yylex`-`'!'`
<pre class="longlist">
3205        case '!':
3206          lex_state = EXPR_BEG;
3207          if ((c = nextc()) == '=') {
3208              return tNEQ;
3209          }
3210          if (c == '~') {
3211              return tNMATCH;
3212          }
3213          pushback(c);
3214          return '!';

(parse.y)
</pre>

日本語でコードの意味を書き出したので対照して読んでみてほしい。

<pre class="emlist">
case '!':
  EXPR_BEGに移行
  if (次の文字が'='なら) {
      トークンは「!=(tNEQ)」である
  }
  if (次の文字が'~'なら) {
      トークンは「!~(tNMATCH)」である
  }
  どちらでもないなら読んだ文字は戻しておく
  トークンは「'!'」である。
</pre>

この`case`節は短かいが、スキャナの重要な法則が示されている。それは
「最長一致の原則」である。`"!="`という二文字は「`!`と`=`」「`!=`」の
二通りに解釈できるが、この場合は「`!=`」を選ばなければならない。
プログラム言語のスキャナでは最長一致が基本である。

また`lex_state`はスキャナの状態を表す変数である。
次章『状態付きスキャナ』で嫌になるほど
やるので、とりあえず無視しておいていい。いちおう意味だけ言っておくと、
`EXPR_BEG`は「明らかに式の先頭にいる」ことを示している。`not`の`!`だろ
うと`!=`だろうと`!~`だろうと、次は式の先頭だからだ。

h4. `'>'`

次は`yylval`(記号の値)を使う例として`'>'`を見てみる。

▼ `yylex`-`'>'`
<pre class="longlist">
3296        case '>':
3297          switch (lex_state) {
3298            case EXPR_FNAME: case EXPR_DOT:
3299              lex_state = EXPR_ARG; break;
3300            default:
3301              lex_state = EXPR_BEG; break;
3302          }
3303          if ((c = nextc()) == '=') {
3304              return tGEQ;
3305          }
3306          if (c == '>') {
3307              if ((c = nextc()) == '=') {
3308                  yylval.id = tRSHFT;
3309                  lex_state = EXPR_BEG;
3310                  return tOP_ASGN;
3311              }
3312              pushback(c);
3313              return tRSHFT;
3314          }
3315          pushback(c);
3316          return '>';

(parse.y)
</pre>

`yylval`のところ以外は無視してよい。プログラムを読むときは一つのことに
だけ集中するのが肝心だ。

ここでは`>=`に対応する記号`tOP_ASGN`に対してその値`tRSHFT`をセットして
いる。使っている共用体メンバが`id`だから型は`ID`である。`tOP_ASGN`は自
己代入の記号で、`+=`とか`-=`とか`*=`といったものを全部まとめて表してい
るから、それを後で区別するために何の自己代入かを値として渡すわけだ。

なぜ自己代入をまとめるかというと、そのほうが規則が短くなるからだ。
スキャナでまとめられるものはできるだけたくさんまとめてしまったほうが規
則がすっきりする。ではなぜ二項演算子は全部まとめないのかと言うと、優先
順位が違うからである。

h4. `':'`

スキャンがパースから完全に独立していれば話は簡単なのだが、現実はそう
簡単ではない。Rubyの文法は特に複雑で空白が前にあるとなんか違うとか、
まわりの状況でトークンの切り方が変わったりする。以下に示す`':'`の
コードは空白で挙動が変わる一例だ。

▼ `yylex`-`':'`
<pre class="longlist">
3761        case ':':
3762          c = nextc();
3763          if (c == ':') {
3764              if (lex_state == EXPR_BEG ||  lex_state == EXPR_MID ||
3765                  (IS_ARG() && space_seen)) {
3766                  lex_state = EXPR_BEG;
3767                  return tCOLON3;
3768              }
3769              lex_state = EXPR_DOT;
3770              return tCOLON2;
3771          }
3772          pushback(c);
3773          if (lex_state == EXPR_END ||
                  lex_state == EXPR_ENDARG ||
                  ISSPACE(c)) {
3774              lex_state = EXPR_BEG;
3775              return ':';
3776          }
3777          lex_state = EXPR_FNAME;
3778          return tSYMBEG;

(parse.y)
</pre>

今度も`lex_state`関係は無視して`space_seen`まわりだけに注目してほしい。

`space_seen`はトークンの前に空白があると真になる変数だ。それが成立
すると、つまり`'::'`の前に空白があるとそれは`tCOLON3`になり、空白がな
ければ`tCOLON2`になるらしい。これは前節で`primary`のところで説明した通
りだ。

h4. 識別子

ここまでは記号ばかりなのでせいぜい一文字二文字だったが、今度は
もう少し長いものも見てみることにする。識別子のスキャンパターンだ。

まず`yylex`の全体像はこうなっていた。

<pre class="emlist">
yylex(...)
{
    switch (c = nextc()) {
      case xxxx:
        ....
      case xxxx:
        ....
      default:
    }

    識別子のスキャンコード
}
</pre>

次のコードは巨大`switch`の末尾のところからの引用である。
やや長いのでコメントを入れつつ示そう。

▼ `yylex`-識別子
<pre class="longlist">
4081        case '@':                 /* インスタンス変数かクラス変数 */
4082          c = nextc();
4083          newtok();
4084          tokadd('@');
4085          if (c == '@') {         /* @@、つまりクラス変数 */
4086              tokadd('@');
4087              c = nextc();
4088          }
4089          if (ISDIGIT(c)) {       /* @1など */
4090              if (tokidx == 1) {
4091    rb_compile_error("`@%c' is not a valid instance variable name", c);
4092              }
4093              else {
4094    rb_compile_error("`@@%c' is not a valid class variable name", c);
4095              }
4096          }
4097          if (!is_identchar(c)) { /* @の次に変な文字がある */
4098              pushback(c);
4099              return '@';
4100          }
4101          break;
4102
4103        default:
4104          if (!is_identchar(c) || ISDIGIT(c)) {
4105              rb_compile_error("Invalid char `\\%03o' in expression", c);
4106              goto retry;
4107          }
4108
4109          newtok();
4110          break;
4111      }
4112
4113      while (is_identchar(c)) {   /* 識別子に使える文字のあいだ…… */
4114          tokadd(c);
4115          if (ismbchar(c)) {      /* マルチバイト文字の先頭バイトならば */
4116              int i, len = mbclen(c)-1;
4117
4118              for (i = 0; i < len; i++) {
4119                  c = nextc();
4120                  tokadd(c);
4121              }
4122          }
4123          c = nextc();
4124      }
4125      if ((c == '!' || c == '?') &&
              is_identchar(tok()[0]) &&
              !peek('=')) {      /* name!またはname?の末尾一文字 */
4126          tokadd(c);
4127      }
4128      else {
4129          pushback(c);
4130      }
4131      tokfix();

(parse.y)
</pre>

最後に`!`/`?`を追加しているところの条件に注目してほしい。
この部分は次のような解釈をするためである。

<pre class="emlist">
obj.m=1       # obj.m  =   1       (obj.m= ... ではない)
obj.m!=1      # obj.m  !=  1       (obj.m! ... ではない)
</pre>

つまり最長一致「ではない」。
最長一致はあくまで原則であって規則ではないので、
ときには破っても構わないのだ。

h4. 予約語

識別子をスキャンした後には実はもう100行くらいコードがあって、そこでは
実際の記号を割り出している。先程のコードではインスタンス変数やクラス変
数、ローカル変数などをまとめてスキャンしてしまっていたから、それを改め
て分類するわけだ。

それはまあいいのだが、その中にちょっと変わった項目がある。それは予約語
を漉し取ることだ。予約語は文字種的にはローカル変数と変わらないので、ま
とめてスキャンしておいて後から分類するほうが効率的なのである。

では`char*`文字列`str`があったとして、予約語かどうか見分けるにはどうしたら
いいだろうか。まずもちろん`if`文と`strcmp()`で比較しまくる方法がある。しか
しそれでは全くもって賢くない。柔軟性がない。スピードも線型増加する。
普通はリストとかハッシュにデータだけ分離して、コードを短く済ますだろう。

<pre class="emlist">
/* コードをデータに変換する */
struct entry {char *name; int symbol;};
struct entry *table[] = {
    {"if",     kIF},
    {"unless", kUNLESS},
    {"while",  kWHILE},
    /* ……略…… */
};

{
    ....
    return lookup_symbol(table, tok());
}
</pre>

それで`ruby`はどうしているかと言うと、ハッシュテーブルを使っている。そ
れも完全ハッシュだ。`st_table`の話をしたときにも言った
が、キーになりうる集合が前もってわかっていれば絶対に衝突しないハッシュ
関数を作れることがある。予約語というのは「キーになりうる集合が前もって
わかってい」るわけだから、完全ハッシュ関数が作れそうだ。

しかし「作れる」のと実際に作るのとは別の話だ。
手動で作るなんてことはやっていられない。予約語は増えたり減ったり
するのだから、そういう作業は自動化しなければいけない。

そこで`gperf`である。`gperf`はGNUプロダクトの一つで、値の集合から完全
ハッシュ関数を作ってくれる。`gperf`自体の詳しい使いかたは`man gperf`し
てもらうとして、ここでは生成した結果の使いかただけ述べよう。

`ruby`での`gperf`の入力ファイルは`keywords`で出力は`lex.c`である。
`parse.y`はこれを直接`#include`している。基本的にはCの
ファイルを`#include`す
るのはよろしくないが、関数一つのために本質的でないファイル分割をやるの
はさらによろしくない。特に`ruby`では`extern`関数はいつのまにか拡張ライブラリ
に使われてしまう恐れがあるので、互換性を保ちたくない関数はできるだけ
`static`にすべきなのだ。

そしてその`lex.c`には`rb_reserved_word()`という関数が定義されている。
予約語の`char*`をキーにしてこれを呼ぶと索ける。返り値は、見付から
なければ`NULL`、見付かれば(つまり引数が予約語なら)`struct kwtable*`が返る。
`struct kwtable`の定義は以下のとおり。

▼ `kwtable`
<pre class="longlist">
   1  struct kwtable {char *name; int id[2]; enum lex_state state;};

(keywords)
</pre>

`name`が予約語の字面、`id[0]`がその記号、`id[1]`が修飾版の記号
(`kIF_MOD`など)。
`lex_state`は「その予約語を読んだ後に移行すべき`lex_state`」である。
`lex_state`については次章で説明する。

実際に索いているのはこのあたりだ。

▼ `yylex()`-識別子-`rb_reserved_word()`を呼ぶ
<pre class="longlist">
4173                  struct kwtable *kw;
4174
4175                  /* See if it is a reserved word.  */
4176                  kw = rb_reserved_word(tok(), toklen());
4177                  if (kw) {

(parse.y)
</pre>

h3. 文字列類

`yylex()`のダブルクォート(`"`)のところを見ると、こうなっている。

▼ `yylex`-`'"'`
<pre class="longlist">
3318        case '"':
3319          lex_strterm = NEW_STRTERM(str_dquote, '"', 0);
3320          return tSTRING_BEG;

(parse.y)
</pre>

なんと一文字目だけをスキャンして終了してしまう。そこで今度は
規則を見てみると、次の部分に`tSTRING_BEG`が見付かった。

▼ 文字列関連の規則
<pre class="longlist">
string1         : tSTRING_BEG string_contents tSTRING_END

string_contents :
                | string_contents string_content

string_content  : tSTRING_CONTENT
                | tSTRING_DVAR string_dvar
                | tSTRING_DBEG term_push compstmt '}'

string_dvar     : tGVAR
                | tIVAR
                | tCVAR
                | backref

term_push       :
</pre>

この規則は文字列中の式埋め込みに対応するために導入された部分である。
`tSTRING_CONTENT`がリテラル部分、`tSTRING_DBEG`が`"#{"`である。
`tSTRING_DVAR`は「後に変数が続く`#`」を表す。例えば

<pre class="emlist">
".....#$gvar...."
</pre>

のような構文である。説明していなかったが埋め込む式が変数一個の
場合には`{`と`}`は省略できるのだ。ただしあまり推奨はされない。
ちなみに`DVAR`、`DBEG`の`D`は`dynamic`の略だと思われる。

また`backref`は`$1 $2`……とか`$& $'`といった正規表現関連の
特殊変数を表す。

`term_push`は「アクションのための規則」である。

さてここで`yylex()`に戻る。
単純にパーサに戻っても、コンテキストが文字列の「中」になる
わけだから、次の`yylex()`でいきなり変数だの`if`だのスキャンされたら困る。
そこで重要な役割を果たすのが……

<pre class="emlist">
      case '"':
        lex_strterm = NEW_STRTERM(str_dquote, '"', 0);
        return tSTRING_BEG;
</pre>

……`lex_strterm`だ、ということになる。`yylex()`の先頭に戻ってみよう。

▼ `yylex()`先頭
<pre class="longlist">
3106  static int
3107  yylex()
3108  {
3109      static ID last_id = 0;
3110      register int c;
3111      int space_seen = 0;
3112      int cmd_state;
3113
3114      if (lex_strterm) {
              /* ……文字列のスキャン…… */
3131          return token;
3132      }
3133      cmd_state = command_start;
3134      command_start = Qfalse;
3135    retry:
3136      switch (c = nextc()) {

(parse.y)
</pre>

`lex_strterm`が存在するときは問答無用で文字列モードに突入するようになっ
ている。ということは逆に言うと`lex_strterm`があると文字列をスキャン中と
いうことであり、文字列中の埋め込み式をパースするときには`lex_strterm`を
0にしておかなければならない。そして埋め込み式が終わったらまた戻さな
ければならない。それをやっているのが次の部分だ。

▼ `string_content`
<pre class="longlist">
1916  string_content  : ....
1917                  | tSTRING_DBEG term_push
1918                      {
1919                          $<num>1 = lex_strnest;
1920                          $<node>$ = lex_strterm;
1921                          lex_strterm = 0;
1922                          lex_state = EXPR_BEG;
1923                      }
1924                    compstmt '}'
1925                      {
1926                          lex_strnest = $<num>1;
1927                          quoted_term = $2;
1928                          lex_strterm = $<node>3;
1929                          if (($$ = $4) && nd_type($$) == NODE_NEWLINE) {
1930                              $$ = $$->nd_next;
1931                              rb_gc_force_recycle((VALUE)$4);
1932                          }
1933                          $$ = NEW_EVSTR($$);
1934                      }

(parse.y)
</pre>

埋め込みアクションで`lex_strterm`を`tSTRING_DBEG`の値として保存し
(事実上のスタックプッシュ)、通常のアクションで復帰している(ポップ)。
なかなかうまい方法だ。

しかしなんでこのような七面倒くさいことをするのだろう。普通にスキャンし
ておいて、「`#{`」を見付けた時点で`yyparse()`を再帰呼び出しすればいい
のではないだろうか。そこに実は問題がある。`yyparse()`は再帰呼び出しで
きないのだ。これはよく知られた`yacc`の制限である。値の受け渡しに利用す
る`yylval`がグローバル変数なので、うかつに再帰すると値が壊れてしまう。
`bison`(GNUの`yacc`)だと`%pure_parser`というディレクティブを使うこと
で再帰可能にできるのだが、現在の`ruby`は`bison`を仮定しないことになっ
ている。現実にBSD由来のOSやWindowsなどでは`byacc`(Berkeley yacc)
を使うことが多いので`bison`が前提になるとちょっと面倒だ。

h4. `lex_strterm`

見てきたように`lex_strterm`は真偽値として見た場合はスキャナが文字列モードか
そうでないかを表すわけだが、実は内容にも意味がある。まず型を見てみよう。

▼ `lex_strterm`
<pre class="longlist">
  72  static NODE *lex_strterm;

(parse.y)
</pre>

まずこの定義から型は`NODE*`だとわかる。これは構文木に使うノードの型で、
第12章『構文木の構築』で詳しく説明する。とりあえずは、三要素を持つ構造体
である、`VALUE`なので`free()`する必要がない、の二点を押さえておけばよ
い。

▼ `NEW_STRTERM()`
<pre class="longlist">
2865  #define NEW_STRTERM(func, term, paren) \
2866          rb_node_newnode(NODE_STRTERM, (func), (term), (paren))

(parse.y)
</pre>

これは`lex_strterm`に格納するノードを作るマクロだ。まず`term`は文字列の終
端文字を示す。例えば`"`文字列ならば`"`である。`'`文字列ならば`'`である。

`paren`は`%`文字列のときに対応する括弧を格納するのに使う。例えば

<pre class="emlist">
%Q(..........)
</pre>

なら`paren`に`'('`が入る。そして`term`には閉じ括弧`')'`が入る。
`%`文字列以外のときは`paren`は0だ。

最後に`func`だが、文字列の種類を示す。
使える種類は以下のように決められている。

▼ `func`
<pre class="longlist">
2775  #define STR_FUNC_ESCAPE 0x01  /* \nなどバックスラッシュ記法が有効 */
2776  #define STR_FUNC_EXPAND 0x02  /* 埋め込み式が有効 */
2777  #define STR_FUNC_REGEXP 0x04  /* 正規表現である */
2778  #define STR_FUNC_QWORDS 0x08  /* %w(....)または%W(....) */
2779  #define STR_FUNC_INDENT 0x20  /* <<-EOS(終了記号がインデント可) */
2780
2781  enum string_type {
2782      str_squote = (0),
2783      str_dquote = (STR_FUNC_EXPAND),
2784      str_xquote = (STR_FUNC_ESCAPE|STR_FUNC_EXPAND),
2785      str_regexp = (STR_FUNC_REGEXP|STR_FUNC_ESCAPE|STR_FUNC_EXPAND),
2786      str_sword  = (STR_FUNC_QWORDS),
2787      str_dword  = (STR_FUNC_QWORDS|STR_FUNC_EXPAND),
2788  };

(parse.y)
</pre>

つまり`enum string_type`のそれぞれの意味は次のようだとわかる。

|`str_squote`|`'`文字列/`%q`|
|`str_dquote`|`"`文字列/`%Q`|
|`str_xquote`|コマンド文字列(本書では説明していない)|
|`str_regexp`|正規表現|
|`str_sword`|`%w`|
|`str_dword`|`%W`|

h4. 文字列スキャン関数

あとは文字列モードのときの`yylex()`、つまり冒頭の`if`を読めばいい。

▼ `yylex`-文字列
<pre class="longlist">
3114      if (lex_strterm) {
3115          int token;
3116          if (nd_type(lex_strterm) == NODE_HEREDOC) {
3117              token = here_document(lex_strterm);
3118              if (token == tSTRING_END) {
3119                  lex_strterm = 0;
3120                  lex_state = EXPR_END;
3121              }
3122          }
3123          else {
3124              token = parse_string(lex_strterm);
3125              if (token == tSTRING_END || token == tREGEXP_END) {
3126                  rb_gc_force_recycle((VALUE)lex_strterm);
3127                  lex_strterm = 0;
3128                  lex_state = EXPR_END;
3129              }
3130          }
3131          return token;
3132      }

(parse.y)
</pre>

大きくヒアドキュメントとそれ以外に分かれている。のだが、今回は
`parse_string()`は読まない。前述のように大量の条件付けがあるため、凄まじ
いスパゲッティコードになっている。例え説明してみたとしても「コードその
ままじゃん!」という文句が出ること必至だ。しかも苦労するわりに全然面白
くない。

しかし全く説明しないわけにもいかないので、スキャンする対象ごとに関数を
分離したものを添付CD-ROMに入れて
おく\footnote{`parse_string()`の解析:添付CD-ROM`doc/parse_string.html`}。
興味のある読者はそちらを眺めてみてほしい。

h4. ヒアドキュメント

普通の文字列に比べるとヒアドキュメントはなかなか面白い。やはり他の
要素と違って単位が「行」であるせいだろう。しかも開始記号がプログラムの
途中に置けるところが恐ろしい。まずヒアドキュメントの開始記号をスキャン
する`yylex()`のコードから示そう。

▼ `yylex`-`'<'`
<pre class="longlist">
3260        case '<':
3261          c = nextc();
3262          if (c == '<' &&
3263              lex_state != EXPR_END &&
3264              lex_state != EXPR_DOT &&
3265              lex_state != EXPR_ENDARG &&
3266              lex_state != EXPR_CLASS &&
3267              (!IS_ARG() || space_seen)) {
3268              int token = heredoc_identifier();
3269              if (token) return token;

(parse.y)
</pre>

例によって`lex_state`の群れは無視する。すると、ここでは「`<<`」だけを
読んでおり、残りは`heredoc_identifier()`でスキャンするらしいとわかる。
そこで`heredoc_identifier()`だ。

▼ `heredoc_identifier()`
<pre class="longlist">
2926  static int
2927  heredoc_identifier()
2928  {
          /* ……省略……開始記号を読む */
2979      tokfix();
2980      len = lex_p - lex_pbeg;   /*(A)*/
2981      lex_p = lex_pend;         /*(B)*/
2982      lex_strterm = rb_node_newnode(NODE_HEREDOC,
2983                          rb_str_new(tok(), toklen()),  /* nd_lit */
2984                          len,                          /* nd_nth */
2985          /*(C)*/       lex_lastline);                /* nd_orig */
2986
2987      return term == '`' ? tXSTRING_BEG : tSTRING_BEG;
2988  }

(parse.y)
</pre>

開始記号(`<<EOS`)を読むところはどうでもいいのでバッサリ省略した。
ここまでで入力バッファは図10のようになっているはずだ。
入力バッファは行単位だったことを思い出そう。

!images/ch_parser_lexparams.png(`"printf(<<EOS, n)"`のスキャン)!

`heredoc_identifier()`でやっていることは以下の通り。
(A)`len`は現在行のうち読み込んだバイト数だ。
(B)そしていきなり`lex_p`を行の末尾まで飛ばす。
ということは、読み込み中の行のうち開始記号の後が読み捨てられて
しまっている。この残りの部分はいつパースするのだろう。
その謎の答えは(C)で`lex_lastline`(読み込み中の行)と
`len`(既に読んだ長さ)を保存しているところにヒントがある。

では`heredoc_identifier()`前後の動的コールグラフを以下に簡単に示す。

<pre class="emlist">
yyparse
    yylex(case '<')
        heredoc_identifier(lex_strterm = ....)
    yylex(冒頭のif)
        here_document
</pre>

そしてこの`here_document()`がヒアドキュメント本体のスキャンを行っている。
以下に、異常系を省略しコメントを加えた`here_document()`を示す。
`lex_strterm`が`heredoc_identifier()`でセットしたままであることに
注意してほしい。

▼ `here_document()`(簡約版)
<pre class="longlist">
here_document(NODE *here)
{
    VALUE line;                      /* スキャン中の行 */
    VALUE str = rb_str_new("", 0);   /* 結果をためる文字列 */

    /* ……異常系の処理、省略…… */

    if (式の埋め込み式が無効) {
        do {
            line = lex_lastline;     /*(A)*/
            rb_str_cat(str, RSTRING(line)->ptr, RSTRING(line)->len);
            lex_p = lex_pend;        /*(B)*/
            if (nextc() == -1) {     /*(C)*/
                goto error;
            }
        } while (読み込み中の行が終了記号と等しくない);
    }
    else {
        /* 式の埋め込み式ができる場合……略 */
    }
    heredoc_restore(lex_strterm);
    lex_strterm = NEW_STRTERM(-1, 0, 0);
    yylval.node = NEW_STR(str);
    return tSTRING_CONTENT;
}
</pre>

`rb_str_cat()`はRubyの文字列の末尾に`char*`を連結する関数だ。
つまり(A)では現在読み込み中の行`lex_lastline`を`str`に連結している。
連結したらもう今の行は用済みだ。(B)で`lex_p`をいきなり行末に
飛ばす。そして(C)が問題で、ここでは終了チェックをしているように
見せかけつつ実は次の「行」を読み込んでいるのだ。思い出してほしいの
だが、`nextc()`は行が読み終わっていると勝手に次の行を読み込むという
仕様だった。だから(B)で強制的に行を終わらせているので
(C)で`lex_p`は次の行に移ることになる。

そして最後に`do`〜`while`ループを抜けて`heredoc_restore()`だ。

▼ `heredoc_restore()`
<pre class="longlist">
2990  static void
2991  heredoc_restore(here)
2992      NODE *here;
2993  {
2994      VALUE line = here->nd_orig;
2995      lex_lastline = line;
2996      lex_pbeg = RSTRING(line)->ptr;
2997      lex_pend = lex_pbeg + RSTRING(line)->len;
2998      lex_p = lex_pbeg + here->nd_nth;
2999      heredoc_end = ruby_sourceline;
3000      ruby_sourceline = nd_line(here);
3001      rb_gc_force_recycle(here->nd_lit);
3002      rb_gc_force_recycle((VALUE)here);
3003  }

(parse.y)
</pre>

`here->nd_orig`には開始記号のあった行が入っている。
`here->nd_nth`には開始記号のあった行のうち既に読んだ長さが入っている。
つまり開始記号の直後から何事もなかったかのようにスキャンしつづけられる
というわけだ(図11)。

!images/ch_parser_heredoc.png(ヒアドキュメントのスキャン分担図)!

