* * * * *

layout: default\
title: Finite-state scanner\
—

Translated by Peter Zotov <br>\
*I’m very grateful to my employer [Evil Martians](http://evl.ms) , who
sponsored\
the work, and [Nikolay Konovalenko](mailto:nlkonovalenko@gmail.com) ,
who put\
more effort in this translation than I could ever wish for. Without
them,\
I would be still figuring out what \`COND\_LEXPOP\` actually does.*

Chapter 11 Finite-state scanner
===============================

Outline
-------

In theory, the scanner and the parser are completely independent of each
other\
– the scanner is supposed to recognize tokens, while the parser is
supposed to\
process the resulting series of tokens. It would be nice if things were
that\
simple, but in reality it rarely is. Depending on the context of the
program it\
is often necessary to alter the way tokens are recognized or their
symbols. In\
this chapter we will take a look at the way the scanner and the parser\
cooperate.

### Practical examples

In most programming languages, spaces don’t have any specific meaning
unless\
they are used to separate words. However, Ruby is not an ordinary
language and\
meanings can change significantly depending on the presence of spaces.\
Here is an example

<pre class="emlist">
a[i] = 1 \# a[i] = (1)\
a [i] \# a([i])\

</pre>
The former is an example of assigning an index. The latter is an example
of\
omitting the method call parentheses and passing a member of an array to
a\
parameter.

Here is another example.

<pre class="emlist">
a + 1 \# (a) + (1)\
a *1 \# a\
\</pre\>
\
This seems to be really disliked by some.
\
However, the above examples might give one the impression that only
omitting\
the method call parentheses can be a source of trouble. Let’s look at a\
different example.
\
\<pre class=“emlist”\>\
\`cvs diff parse.y\` \# command call string\
obj.\` \# normal method call\
\</pre\>
\
Here, the former is a method call using a literal. In contrast, the
latter is a\
normal method call . Depending on the context,\
they could be handled quite differently.
\
Below is another example where the functioning changes dramatically
\
\<pre class=“emlist”\>\
print \# here-document\
……\
EOS
\
list =  kDO) {
4184                          if (COND\_P()) return kDO\_COND;
4185                          if (CMDARG\_P() && state != EXPR\_CMDARG)
4186                              return kDO\_BLOCK;
4187                          if (state  EXPR\_ENDARG)\
4188 return kDO\_BLOCK;\
4189 return kDO;\
4190 }\
4191 if /**\* Here****/\
4192 return kw~~\>id[0];\
4193 else {\
4194 if \
4195 lex\_state = EXPR\_BEG;\
4196 return kw~~\>id[1];\
4197 }\
4198 }\

\
This is located at the end of \`yylex\` after the identifiers are
scanned.\
The part that handles modifiers is the last \`if\`〜\`else\` Whether\
the return value is altered can be determined by whether or not the
state is\
\`EXPR\_BEG\`. This is where a modifier is identified. Basically, the
variable \`kw\`\
is the key and if you look far above you will find that it is \`struct
kwtable\`
\
I’ve already described in the previous chapter how \`struct kwtable\` is
a\
structure defined in \`keywords\` and the hash function
\`rb\_reserved\_word\` is\
created by \`gperf\`. I’ll show the structure here again.
\
▼ \`keywords\` - \`struct kwtable\`
\
pre.    1 struct kwtable ;\

\
I’ve already explained about \`name\` and \`id[0]\` - they are the
reserved word\
name and its symbol. Here I will speak about the remaining members.
\
First, \`id[1]\` is a symbol to deal with modifiers. For example, in
case of \`if\`\
that would be \`kIF\_MOD\`.\
When a reserved word does not have a modifier equivalent, \`id[0]\` and
\`id[1]\`\
contain the same things.
\
Because \`state\` is \`enum lex\_state\` it is the state to which a
transition\
should occur after the reserved word is read.\
Below is a list created in the \`kwstat.rb\` tool which I made. The tool
can be\
found on the CD.
\
\<pre class=“screen”\>\
 kwstat.rb ruby/keywords
---- EXPR\_ARG
defined?  super     yield

---- EXPR\_BEG
and     case    else    ensure  if      module  or      unless  when
begin   do      elsif   for     in      not     then    until   while

---- EXPR\_CLASS
class

---- EXPR\_END
BEGIN     \_\_FILE\_\_  end       nil       retry     true
END       \_\_LINE\_\_  false     redo      self

---- EXPR\_FNAME
alias  def    undef

---- EXPR\_MID
break   next    rescue  return

---- modifiers
if      rescue  unless  until   while
\</pre\>

h2. The \`do\` conflict

h3. The problem

There are two iterator forms - \`do\`〜\`end\` and \`{\`〜\`}\` Their difference is in
priority - \`{\`〜\`}\` has a much higher priority. A higher priority means that as
part of the grammar a unit is “small” which means it can be put into a smaller
rule. For example, it can be put not into \`stmt\` but \`expr\` or \`primary\`. In
the past \`{\`〜\`}\` iterators were in \`primary\` while \`do\`〜\`end\` iterators were
in \`stmt\`

By the way, there has been a request for an expression like this:

\<pre class="emlist"\>
m do .... end + m do .... end
\</pre\>

To allow for this, put the \`do\`〜\`end\` iterator in \`arg\` or \`primary\`.
Incidentally, the condition for \`while\` is \`expr\`, meaning it contains \`arg\`
and \`primary\`, so the \`do\` will cause a conflict here. Basically, it looks like
this:

\<pre class="emlist"\>
while m do
  ....
end
\</pre\>

At first glance, the \`do\` looks like the \`do\` of \`while\`. However, a closer
look reveals that it could be a \`m do\`〜\`end\` bundling. Something that’s not
obvious even to a person will definitely cause \`yacc\` to conflict. Let’s try it
in practice.

\<pre class="emlist"\>
/\* do conflict experiment \*/
token kWHILE kDO tIDENTIFIER kEND\
\
expr: kWHILE expr kDO expr kEND\
    | tIDENTIFIER\
    | tIDENTIFIER kDO expr kEND\
\</pre\>
\
I simplified the example to only include \`while\`, variable referencing
and\
iterators. This rule causes a shift/reduce conflict if the head of the\
conditional contains \`tIDENTIFIER\`. If \`tIDENTIFIER\` is used for
variable\
referencing and \`do\` is appended to \`while\`, then it’s reduction. If
it’s made\
an iterator \`do\`, then it’s a shift.
\
Unfortunately, in a shift/reduce conflict the shift is prioritized, so
if left\
unchecked, \`do\` will become an iterator \`do\`. That said, even if a
reduction\
is forced through operator priorities or some other method, \`do\` won’t
shift at\
all, becoming unusable. Thus, to solve the problem without any
contradictions,\
we need to either deal with on the scanner level or write a rule that
allows to\
use operators without putting the \`do\`〜\`end\` iterator into
\`expr\`.
\
However, not putting \`do\`〜\`end\` into \`expr\` is not a realistic
goal. That\
would require all rules for \`expr\` to be\
repeated. This leaves us only the scanner solution.
\
h3. Rule-level solution
\
Below is a simplified example of a relevant rule.
\
▼ \`do\` symbol\
\<pre class=“longlist”\>\
primary : kWHILE expr\_value do compstmt kEND
\
do : term\
                | kDO\_COND
\
primary : operation brace\_block\
                | method\_call brace\_block
\
brace\_block : ‘{’ opt\_block\_var compstmt ‘}’\
                | kDO opt\_block\_var compstmt kEND\
\</pre\>
\
As you can see, the terminal symbols for the \`do\` of \`while\` and for
the\
iterator \`do\` are different. For the former it’s \`kDO\_COND\` while
for the\
latter it’s \`kDO\` Then it’s simply a matter of pointing that
distinction out to\
the scanner.
\
h3. Symbol-level solution
\
Below is a partial view of the \`yylex\` section that processes reserved
words.\
It’s the only part tasked with processing \`do\` so looking at this code
should\
be enough to understand the criteria for making the distinction.
\
▼ \`yylex\`-Identifier-Reserved word
\
pre. 4183 if {\
4184 if ) return kDO\_COND;\
4185 if && state != EXPR\_CMDARG)\
4186 return kDO\_BLOCK;\
4187 if \
4188 return kDO\_BLOCK;\
4189 return kDO;\
4190 }\

\
It’s a little messy, but you only need the part associated with
\`kDO\_COND\`.\
That is because only two comparisons are meaningful.\
The first is the comparison between \`kDO\_COND\` and
\`kDO\`/\`kDO\_BLOCK\` \
The second is the comparison between \`kDO\` and \`kDO\_BLOCK\`.\
The rest are meaningless.\
Right now we only need to distinguish the conditional \`do\` - leave all
the\
other conditions alone.
\
Basically, \`COND\_P\` is the key.
\
h3. \`COND\_P\`
\
h4. \`cond\_stack\`
\
\`COND\_P\` is defined close to the head of \`parse.y\`
\
▼ \`cond\_stack\`\
\<pre class=“longlist”\>\
  75 \#ifdef HAVE\_LONG\_LONG\
  76 typedef unsigned LONG\_LONG stack\_type;\
  77 \#else\
  78 typedef unsigned long stack\_type;\
  79 \#endif\
  80\
  81 static stack\_type cond\_stack = 0;\
  82 \#define COND\_PUSH |&1))\
  83 \#define COND\_POP \
  84 \#define COND\_LEXPOP do while \
  89 \#define COND\_P
\
\
\</pre\>
\
The type \`stack\_type\` is either \`long\` or \`long long\` .
\`cond\_stack\` is initialized by \`yycompile\` at the start of parsing
and\
after that is handled only through macros. All you need, then, is to
understand\
those macros.
\
If you look at \`COND\_PUSH\`/\`POP\` you will see that these macros use
integers as\
stacks consisting of bits.
\
\<pre class=“emlist”\>\
MSB← →LSB\
…0000000000 Initial value 0\
…0000000001 COND\_PUSH\
…0000000010 COND\_PUSH\
…0000000101 COND\_PUSH\
…0000000010 COND\_POP\
…0000000100 COND\_PUSH\
…0000000010 COND\_POP\
\</pre\>
\
As for \`COND\_P\`, since it determines whether or not the least
significant bit\
 is a 1, it effectively determines whether the head of the stack is a 1.
\
The remaining \`COND\_LEXPOP\` is a little weird. It leaves \`COND\_P\`
at the\
head of the stack and executes a right shift. Basically, it “crushes”
the\
second bit from the bottom with the lowermost bit.
\
\<pre class=“emlist”\>\
MSB← →LSB\
…0000000000 Initial value 0\
…0000000001 COND\_PUSH\
…0000000010 COND\_PUSH\
…0000000101 COND\_PUSH\
…0000000011 COND\_LEXPOP\
…0000000100 COND\_PUSH\
…0000000010 COND\_LEXPOP\
\</pre\>
\
Now I will explain what that means.
\
h4. Investigating the function
\
Let us investigate the function of this stack. To do that I will list up
all\
the parts where \`COND\_PUSH COND\_POP\` are used.
\
\<pre class=“emlist”\>\
        | kWHILE expr\_value do \
—\
        | kUNTIL expr\_value do \
—\
        | kFOR block\_var kIN expr\_value do \
—\
      case ‘(’:\
                :\
                :\
        COND\_PUSH;\
        CMDARG\_PUSH;\
—\
      case ‘[’:\
                :\
                :\
        COND\_PUSH;\
        CMDARG\_PUSH;\
—\
      case ‘{’:\
                :\
                :\
        COND\_PUSH;\
        CMDARG\_PUSH;\
—\
      case ‘]’:\
      case ‘}’:\
      case ‘)’:\
        COND\_LEXPOP;\
        CMDARG\_LEXPOP;\
\</pre\>
\
From this we can derive the following general rules
\
** At the start of a conditional expression \`PUSH\`\
\* At opening parenthesis \`PUSH\`\
\* At the end of a conditional expression \`POP\`\
\* At closing parenthesis\`LEXPOP\`
\
With this, you should see how to use it. If you think about it for a
minute,\
the name \`cond\_stack\` itself is clearly the name for a macro that
determines\
whether or not it’s on the same level as the conditional expression
\
!images/ch\_contextual\_condp.jpg\`)!
\
Using this trick should also make situations like the one shown below
easy to\
deal with.
\
\<pre class=“emlist”\>\
while \# do is an iterator do\
  ….\
end\
\</pre\>
\
This means that on a 32-bit machine in the absence of \`long long\` if\
conditional expressions or parentheses are nested at 32 levels, things
could\
get strange. Of course, in reality you won’t need to nest so deep so
there’s no\
actual risk.
\
Finally, the definition of \`COND\_LEXPOP\` looks a bit strange – that
seems to\
be a way of dealing with lookahead. However, the rules now do not allow
for\
lookahead to occur, so there’s no purpose to make the distinction
between \`POP\`\
and \`LEXPOP\`. Basically, at this time it would be correct to say that\
\`COND\_LEXPOP\` has no meaning.
\
h2. \`tLPAREN\_ARG\`
\
h3. The problem
\
This one is very complicated. It only became workable in in Ruby 1.7 and
only\
fairly recently. The core of the issue is interpreting this:
\
\<pre class=“emlist”\>\
call* 1\

</pre>
As one of the following

<pre class="emlist">
(call(expr)) + 1\
call((expr) + 1)\

</pre>
In the past, it was always interpreted as the former. That is, the
parentheses\
were always treated as “Method parameter parentheses”. But since Ruby
1.7 it\
became possible to interpret it as the latter – basically, if a space is
added,\
the parentheses become “Parentheses of \`expr\`”

I will also provide an example to explain why the interpretation
changed.\
First, I wrote a statement as follows

<pre class="emlist">
p m() + 1\

</pre>
So far so good. But let’s assume the value returned by \`m\` is a
fraction and\
there are too many digits. Then we will have it displayed as an integer.

<pre class="emlist">
p m() + 1 .to\_i \# ??\

</pre>
Uh-oh, we need parentheses.

<pre class="emlist">
p (m() + 1).to\_i\

</pre>
How to interpret this? Up to 1.6 it will be this

<pre class="emlist">
(p(m() + 1)).to\_i\

</pre>
The much-needed \`to\_i\` is rendered meaningless, which is
unacceptable.\
To counter that, adding a space between it and the parentheses will
cause the\
parentheses to be treated specially as \`expr\` parentheses.

For those eager to test this, this feature was implemented in
\`parse.y\`\
revision 1.100(2001-05-31). Thus, it should be relatively prominent
when\
looking at the differences between it and 1.99. This is the command to
find the\
difference.

<pre class="screen">
\~/src/ruby  cvs diff -r1.99 -r1.100 parse.y
\</pre\>

h3. Investigation

First let us look at how the set-up works in reality. Using the \`ruby-lexer\`
tool{\`ruby-lexer\`: located in \`tools/ruby-lexer.tar.gz\` on the CD} we can look
at the list of symbols corresponding to the program.

\<pre class="screen"\>
 ruby-lexer ~~e ‘m(a)’\
tIDENTIFIER ‘(’ tIDENTIFIER ‘)’ ‘\n’\
\</pre\>
\
Similarly to Ruby, \`-e\` is the option to pass the program directly
from the\
command line. With this we can try all kinds of things. Let’s start with
the\
problem at hand – the case where the first parameter is enclosed in
parentheses.
\
\<pre class=“screen”\>\
 ruby-lexer -e 'm (a)'
tIDENTIFIER tLPAREN\_ARG tIDENTIFIER ')' '\\n'
\</pre\>

After adding a space, the symbol of the opening parenthesis became \`tLPAREN\_ARG\`.
Now let’s look at normal expression parentheses.

\<pre class="screen"\>
 ruby-lexer~~e ‘(a)’\
tLPAREN tIDENTIFIER ‘)’ ‘\n’\

</pre>
For normal expression parentheses it seems to be \`tLPAREN\`. To sum up:

  Input       Symbol of opening parenthesis
  ----------- -------------------------------
  \`m(a)\`    \`’(’\`
  \`m (a)\`   \`tLPAREN\_ARG\`
  \`(a)\`     \`tLPAREN\`

Thus the focus is distinguishing between the three. For now
\`tLPAREN\_ARG\` is\
the most important.

### The case of one parameter

We’ll start by looking at the \`yylex()\` section for \`’(‘\`
\
▼ \`yylex\`-\`’(‘\`\
\<pre class=“longlist”\>\
3841 case’(‘:\
3842 command\_start = Qtrue;\
3843 if (lex\_state  EXPR\_BEG || lex\_state  EXPR\_MID) {\
3844 c = tLPAREN;\
3845 }\
3846 else if (space\_seen) {\
3847 if (lex\_state  EXPR\_CMDARG) {
3848                  c = tLPAREN\_ARG;
3849              }
3850              else if (lex\_state  EXPR\_ARG) {\
3851 c = tLPAREN\_ARG;\
3852 yylval.id = last\_id;\
3853 }\
3854 }\
3855 COND\_PUSH(0);\
3856 CMDARG\_PUSH(0);\
3857 lex\_state = EXPR\_BEG;\
3858 return c;
\
(parse.y)\
\</pre\>
\
Since the first \`if\` is \`tLPAREN\` we’re looking at a normal
expression\
parenthesis. The distinguishing feature is that \`lex\_state\` is either
\`BEG\` or\
\`MID\` - that is, it’s clearly at the beginning of the expression.
\
The following \`space\_seen\` shows whether the parenthesis is preceded
by a space.\
If there is a space and \`lex\_state\` is either \`ARG\` or \`CMDARG\`,
basically if\
it’s before the first parameter, the symbol is not \`’(‘\` but
\`tLPAREN\_ARG\`.\
This way, for example, the following situation can be avoided
\
\<pre class=“emlist”\>\
m( \# Parenthesis not preceded by a space. Method parenthesis (’(‘)\
m arg, ( \# Unless first parameter, expression parenthesis (tLPAREN)\
\</pre\>
\
When it is neither \`tLPAREN\` nor \`tLPAREN\_ARG\`, the input character
\`c\` is used\
as is and becomes \`’(‘\`. This will definitely be a method call
parenthesis.
\
If such a clear distinction is made on the symbol level, no conflict
should\
occur even if rules are written as usual. Simplified, it becomes
something like\
this:
\
\<pre class=“emlist”\>\
stmt : command\_call
\
method\_call : tIDENTIFIER’(‘args’)‘/\* Normal method **/
\
command\_call : tIDENTIFIER command\_args /** Method with parentheses
omitted **/
\
command\_args : args
\
args : arg\
             : args ’,’ arg
\
arg : primary
\
primary : tLPAREN compstmt ’)’ /** Normal expression parenthesis **/\
             | tLPAREN\_ARG expr ’)’ /** First parameter enclosed in
parentheses \*/\
             | method\_call\
\</pre\>
\
Now I need you to focus on \`method\_call\` and \`command\_call\` If you
leave the\
\`’(‘\` without introducing \`tLPAREN\_ARG\`, then \`command\_args\`
will produce\
\`args\`, \`args\` will produce \`arg\`, \`arg\` will produce
\`primary\`. Then, \`’(‘\`\
will appear from \`tLPAREN\_ARG\` and conflict with \`method\_call\`
(see image 3)
\
![\`method\_call\` and \`command\_call\`](images/ch_contextual_trees.jpg "`method_call` and `command_call`")
\
h3. The case of two parameters and more
\
One might think that if the parenthesis becomes \`tLPAREN\_ARG\` all
will be well.\
That is not so. For example, consider the following
\
\<pre class=“emlist”\>\
m (a, a, a)\
\</pre\>
\
Before now, expressions like this one were treated as method calls and
did not\
produce errors. However, if \`tLPAREN\_ARG\` is introduced, the opening\
parenthesis becomes an \`expr\` parenthesis, and if two or more
parameters are\
present, that will cause a parse error. This needs to be resolved for
the sake\
of compatibility.
\
Unfortunately, rushing ahead and just adding a rule like
\
\<pre class=“emlist”\>\
command\_args : tLPAREN\_ARG args’)‘\
\</pre\>
\
will just cause a conflict. Let’s look at the bigger picture and think
carefully.
\
\<pre class=“emlist”\>\
stmt : command\_call\
             | expr
\
expr : arg
\
command\_call : tIDENTIFIER command\_args
\
command\_args : args\
             | tLPAREN\_ARG args’)‘
\
args : arg\
             : args’,‘arg
\
arg : primary
\
primary : tLPAREN compstmt’)‘\
             | tLPAREN\_ARG expr’)‘\
             | method\_call
\
method\_call : tIDENTIFIER’(‘args’)‘\
\</pre\>
\
Look at the first rule of \`command\_args\` Here, \`args\` produces
\`arg\` Then \`arg\`\
produces \`primary\` and out of there comes the \`tLPAREN\_ARG\` rule.
And since\
\`expr\` contains \`arg\` and as it is expanded, it becomes like this:
\
\<pre class=“emlist”\>\
command\_args : tLPAREN\_ARG arg’)‘\
             | tLPAREN\_ARG arg’)‘\
\</pre\>
\
This is a reduce/reduce conflict, which is very bad.
\
So, how can we deal with only 2+ parameters without causing a conflict?
We’ll\
have to write to accommodate for that situation specifically. In
practice, it’s\
solved like this:
\
▼ \`command\_args\`\
\<pre class=“longlist”\>\
command\_args : open\_args
\
open\_args : call\_args\
                | tLPAREN\_ARG’)‘\
                | tLPAREN\_ARG call\_args2’)‘
\
call\_args : command\
                | args opt\_block\_arg\
                | args’,‘tSTAR arg\_value opt\_block\_arg\
                | assocs opt\_block\_arg\
                | assocs’,‘tSTAR arg\_value opt\_block\_arg\
                | args’,‘assocs opt\_block\_arg\
                | args’,‘assocs’,‘tSTAR arg opt\_block\_arg\
                | tSTAR arg\_value opt\_block\_arg\
                | block\_arg
\
call\_args2 : arg\_value’,‘args opt\_block\_arg\
                | arg\_value’,‘block\_arg\
                | arg\_value’,‘tSTAR arg\_value opt\_block\_arg\
                | arg\_value’,‘args’,‘tSTAR arg\_value opt\_block\_arg\
                | assocs opt\_block\_arg\
                | assocs’,‘tSTAR arg\_value opt\_block\_arg\
                | arg\_value’,‘assocs opt\_block\_arg\
                | arg\_value’,‘args’,‘assocs opt\_block\_arg\
                | arg\_value’,‘assocs’,‘tSTAR arg\_value
opt\_block\_arg\
                | arg\_value’,‘args’,‘assocs’,‘\
                                  tSTAR arg\_value opt\_block\_arg\
                | tSTAR arg\_value opt\_block\_arg\
                | block\_arg
\
primary : literal\
                | strings\
                | xstring\
                       :\
                | tLPAREN\_ARG expr’)‘\
\</pre\>
\
Here \`command\_args\` is followed by another level - \`open\_args\`
which may not be\
reflected in the rules without consequence. The key is the second and
third\
rules of this \`open\_args\` This form is similar to the recent example,
but is\
actually subtly different. The difference is that \`call\_args2\` has
been\
introduced. The defining characteristic of this \`call\_args2\` is that
the number\
of parameters is always two or more. This is evidenced by the fact that
most\
rules contain \`’,‘\` The only exception is \`assocs\`, but since
\`assocs\` does not\
come out of \`expr\` it cannot conflict anyway.
\
That wasn’t a very good explanation. To put it simply, in a grammar
where this:
\
\<pre class=“emlist”\>\
command\_args : call\_args\
\</pre\>
\
doesn’t work, and only in such a grammar, the next rule is used to make
an\
addition. Thus, the best way to think here is “In what kind of grammar
would\
this rule not work?” Furthermore, since a conflict only occurs when the\
\`primary\` of \`tLPAREN\_ARG\` appears at the head of \`call\_args\`,
the scope can be\
limited further and the best way to think is “In what kind of grammar
does this\
rule not work when a \`tIDENTIFIER tLPAREN\_ARG\` line appears?” Below
are a few\
examples.
\
\<pre class=“emlist”\>\
m (a, a)\
\</pre\>
\
This is a situation when the \`tLPAREN\_ARG\` list contains two or more
items.
\
\<pre class=“emlist”\>\
m ()\
\</pre\>
\
Conversely, this is a situation when the \`tLPAREN\_ARG\` list is empty.
\
\<pre class=“emlist”\>\
m (\*args)\
m (&block)\
m (k =\> v)\
\</pre\>
\
This is a situation when the \`tLPAREN\_ARG\` list contains a special
expression\
(one not present in \`expr\`).
\
This should be sufficient for most cases. Now let’s compare the above
with a\
practical implementation.
\
▼ \`open\_args\`(1)\
\<pre class=“longlist”\>\
open\_args : call\_args\
                | tLPAREN\_ARG’)‘\
\</pre\>
\
First, the rule deals with empty lists
\
▼ \`open\_args\`(2)\
\<pre class=“longlist”\>\
                | tLPAREN\_ARG call\_args2’)‘
\
call\_args2 : arg\_value’,‘args opt\_block\_arg\
                | arg\_value’,‘block\_arg\
                | arg\_value’,‘tSTAR arg\_value opt\_block\_arg\
                | arg\_value’,‘args’,‘tSTAR arg\_value opt\_block\_arg\
                | assocs opt\_block\_arg\
                | assocs’,‘tSTAR arg\_value opt\_block\_arg\
                | arg\_value’,‘assocs opt\_block\_arg\
                | arg\_value’,‘args’,‘assocs opt\_block\_arg\
                | arg\_value’,‘assocs’,‘tSTAR arg\_value
opt\_block\_arg\
                | arg\_value’,‘args’,‘assocs’,‘\
                                  tSTAR arg\_value opt\_block\_arg\
                | tSTAR arg\_value opt\_block\_arg\
                | block\_arg\
\</pre\>
\
And \`call\_args2\` deals with elements containing special types such as
\`assocs\`,\
passing of arrays or passing of blocks. With this, the scope is now\
sufficiently broad.
\
h2. \`tLPAREN\_ARG\`(2)
\
h3. The problem
\
In the previous section I said that the examples provided should be
sufficient\
for “most” special method call expressions. I said “most” because
iterators are\
still not covered. For example, the below statement will not work:
\
\<pre class=“emlist”\>\
m (a) {….}\
m (a) do …. end\
\</pre\>
\
In this section we will once again look at the previously introduced
parts with\
solving this problem in mind.
\
h3. Rule-level solution
\
Let us start with the rules. The first part here is all familiar rules,\
so focus on the \`do\_block\` part
\
▼ \`command\_call\`\
\<pre class=“longlist”\>\
command\_call : command\
                | block\_command
\
command : operation command\_args
\
command\_args : open\_args
\
open\_args : call\_args\
                | tLPAREN\_ARG’)‘\
                | tLPAREN\_ARG call\_args2’)‘
\
block\_command : block\_call
\
block\_call : command do\_block
\
do\_block : kDO\_BLOCK opt\_block\_var compstmt’}’\
                | tLBRACE\_ARG opt\_block\_var compstmt ‘}’\

</pre>
Both \`do\` and \`{\` are completely new symbols \`kDO\_BLOCK\` and
\`tLBRACE\_ARG\`.\
Why isn’t it \`kDO\` or \`’{’\` you ask? In this kind of situation the
best answer\
is an experiment, so we will try replacing \`kDO\_BLOCK\` with \`kDO\`
and\
\`tLBRACE\_ARG\` with \`’{’\` and processing that with \`yacc\`

<pre class="screen">
 yacc parse.y
conflicts:  2 shift/reduce, 6 reduce/reduce
\</pre\>

It conflicts badly. A further investigation reveals that this statement is the
cause.

\<pre class="emlist"\>
m (a), b {....}
\</pre\>

That is because this kind of statement is already supposed to work. \`b{....}\`
becomes \`primary\`. And now a rule has been added that concatenates the block
with \`m\` That results in two possible interpretations:

\<pre class="emlist"\>
m((a), b) {....}
m((a), (b {....}))
\</pre\>

This is the cause of the conflict – namely, a 2 shift/reduce conflict.

The other conflict has to do with \`do\`〜\`end\`

\<pre class="emlist"\>
m((a)) do .... end     \# Add do〜end using block\_call
m((a)) do .... end     \# Add do〜end using primary
\</pre\>

These two conflict. This is 6 reduce/reduce conflict.

h3. \`{\`〜\`}\` iterator

This is the important part. As shown previously, you can avoid a conflict by
changing the \`do\` and \`'{'\` symbols.

▼ \`yylex\`-\`'{'\`

pre(longlist). 3884        case '{':
3885          if (IS\_ARG() || lex\_state == EXPR\_END)
3886              c = '{';          /\* block (primary) \*/
3887          else if (lex\_state == EXPR\_ENDARG)
3888              c = tLBRACE\_ARG;  /\* block (expr) \*/
3889          else
3890              c = tLBRACE;      /\* hash \*/
3891          COND\_PUSH(0);
3892          CMDARG\_PUSH(0);
3893          lex\_state = EXPR\_BEG;
3894          return c;
(parse.y)

\`IS\_ARG()\` is defined as

▼ \`IS\_ARG\`
\<pre class="longlist"\>
3104  \#define IS\_ARG() (lex\_state == EXPR\_ARG || lex\_state == EXPR\_CMDARG)

(parse.y)
\</pre\>

Thus, when the state is  \`EXPR\_ENDARG\` it will always be false. In other words,
when \`lex\_state\` is \`EXPR\_ENDARG\`, it will always become \`tLBRACE\_ARG\`, so the
key to everything is the transition to \`EXPR\_ENDARG\`.

h4. \`EXPR\_ENDARG\`

Now we need to know how to set \`EXPR\_ENDARG\` I used \`grep\` to find where it is
assigned.

▼ Transition to\`EXPR\_ENDARG\`
\<pre class="longlist"\>
open\_args       : call\_args
                | tLPAREN\_ARG  {lex\_state = EXPR\_ENDARG;} ')'
                | tLPAREN\_ARG call\_args2 {lex\_state = EXPR\_ENDARG;} ')'

primary         : tLPAREN\_ARG expr {lex\_state = EXPR\_ENDARG;} ')'
\</pre\>

That’s strange. One would expect the transition to \`EXPR\_ENDARG\` to occur after
the closing parenthesis corresponding to \`tLPAREN\_ARG\`, but it’s actually
assigned before \`')'\` I ran \`grep\` a few more times thinking there might be
other parts setting the \`EXPR\_ENDARG\` but found nothing.

Maybe there’s some mistake. Maybe \`lex\_state\` is being changed some other way.
Let’s use \`rubylex-analyser\` to visualize the \`lex\_state\` transition.

\<pre class="screen"\>
 rubylex-analyser ~~e ‘m (a) { nil }’\
*EXPR\_BEG\
EXPR\_BEG C “m” tIDENTIFIER EXPR\_CMDARG\
EXPR\_CMDARG S “(” tLPAREN\_ARG EXPR\_BEG\
                                              0:cond push\
                                              0:cmd push\
                                              1:cmd push-\
EXPR\_BEG C “a” tIDENTIFIER EXPR\_CMDARG\
EXPR\_CMDARG “)” ‘)’ EXPR\_END\
                                              0:cond lexpop\
                                              1:cmd lexpop\
*EXPR\_ENDARG\
EXPR\_ENDARG S “{” tLBRACE\_ARG EXPR\_BEG\
                                              0:cond push\
                                             10:cmd push\
                                              0:cmd resume\
EXPR\_BEG S “nil” kNIL EXPR\_END\
EXPR\_END S “}” ‘}’ EXPR\_END\
                                              0:cond lexpop\
                                              0:cmd lexpop\
EXPR\_END “\n” \n                   EXPR\_BEG\
\</pre\>
\
The three big branching lines show the state transition caused by
\`yylex\`.\
On the left is the state before \`yylex\` The middle two are the word
text and\
its symbols. Finally, on the right is the \`lex\_state\` after \`yylex\`
\
The problem here are parts of single lines that come out as
\`+EXPR\_ENDARG\`.\
This indicates a transition occurring during parser action. According to
this,\
for some reason an action is executed after reading the \`’)‘\` a
transition to\
\`EXPR\_ENDARG\` occurs and \`’‘2\>&1 | egrep’\^Reading|Reducing’\
Reducing via rule 1 ,~~\> `1
Reading a token: Next token is 304 (tIDENTIFIER)
Reading a token: Next token is 340 (tLPAREN_ARG)
Reducing via rule 446 (line 2234), tIDENTIFIER  -> operation
Reducing via rule 233 (line 1222),  -> `6\
Reading a token: Next token is 304 (tIDENTIFIER)\
Reading a token: Next token is 41 (‘)’)\
Reducing via rule 392 (line 1993), tIDENTIFIER ~~\> variable\
Reducing via rule 403 , variable~~\> var\_ref\
Reducing via rule 256 (line 1305), var\_ref ~~\> primary\
Reducing via rule 198 , primary~~\> arg\
Reducing via rule 42 (line 593), arg ~~\> expr\
Reducing via rule 260 ,~~\> `9
Reducing via rule 261 (line 1317), tLPAREN_ARG expr `9 ‘)’ ~~\> primary\
Reading a token: Next token is 344 \
                         :\
                         :\
\</pre\>
\
Here we’re using the option \`-c\` which stops the process at just
compiling and\
\`-e\` which allows to give a program from the command line. And we’re
using\
\`grep\` to single out token read and reduction reports.
\
Start by looking at the middle of the list. \`’)‘\` is read. Now look at
the end\
– the reduction (execution) of embedding action (\`@9\`) finally
happens. Indeed,\
this would allow \`EXPR\_ENDARG \` to be set after the \`’)‘\` before
the \`’ ‘)’\
Rule 2 tLPAREN\_ARG call\_args2 ‘)’\
Rule 3 tLPAREN\_ARG expr ‘)’\
\</pre\>
\
The embedding action can be substituted with an empty rule. For
example,\
we can rewrite this using rule 1 with no change in meaning whatsoever.
\
\<pre class=“emlist”\>\
target : tLPAREN\_ARG tmp ‘)’\
tmp :\
            {\
                lex\_state = EXPR\_ENDARG;\
            }\
\</pre\>
\
Assuming that this is before \`tmp\`, it’s possible that one terminal
symbol will\
be read by lookahead. Thus we can skip the \`tmp\` and read the next.\
And if we are certain that lookahead will occur, the assignment to
\`lex\_state\`\
is guaranteed to change to \`EXPR\_ENDARG\` after \`’)‘\`\
But is \`’)‘\` certain to be read by lookahead in this rule?
\
h4. Ascertaining lookahead
\
This is actually pretty clear. Think about the following input.
\
\<pre class=“emlist”\>\
m () { nil } \# A\
m (a) { nil } \# B\
m (a,b,c) { nil } \# C\
\</pre\>
\
I also took the opportunity to rewrite the rule to make it easier to
understand\
(with no actual changes).
\
\<pre class=“emlist”\>\
rule1: tLPAREN\_ARG e1’)‘\
rule2: tLPAREN\_ARG one\_arg e2’)‘\
rule3: tLPAREN\_ARG more\_args e3’)‘
\
e1: /\* empty **/\
e2: /** empty **/\
e3: /** empty **/\
\</pre\>
\
First, the case of input A. Reading up to
\
\<pre class=“emlist”\>\
m ’\` will be read\
by lookahead.
\
On to input B. First, reading up to here
\
\<pre class=“emlist”\>\
m ’\` a decision is made between \`rule2\` and \`rule3\` If what\
follows is a \`’,’\` then it can only be a comma to separate parameters,
thus\
\`rule3\` the rule for two or more parameters, is chosen. This is also
true if\
the input is not a simple \`a\` but something like an \`if\` or literal.
When the\
input is complete, a lookahead occurs to choose between \`rule2\` and
\`rule3\` -\
the rules for one parameter and two or more parameters respectively.
\
The presence of a separate embedding action is present before \`’)’\` in
every\
rule. There’s no going back after an action is executed, so the parser
will try\
to postpone executing an action until it is as certain as possible. For
that\
reason, situations when this certainty cannot be gained with a single
lookahead\
should be excluded when building a parser as it is a conflict.
\
Proceeding to input C.
\
\<pre class=“emlist”\>\
m ’\` it needs to be a variable\
reference. Basically, this time a lookahead is needed to confirm
parameter\
elements instead of embedding action reduction.
\
But what about the other inputs? For example, what if the third
parameter is a\
method call?
\
\<pre class=“emlist”\>\
m \# … ’,’ method\_call\
\</pre\>
\
Once again a lookahead is necessary because a choice needs to be made
between\
shift and reduction depending on whether what follows is \`’,’\` or
\`’)’\`. Thus,\
in this rule in all instances the \`’)’\` is read before the embedding
action is\
executed. This is quite complicated and more than a little impressive.
\
But would it be possible to set \`lex\_state\` using a normal action
instead of an\
embedding action? For example, like this:
\
\<pre class=“emlist”\>\
                | tLPAREN\_ARG ’)’ { lex\_state = EXPR\_ENDARG; }\
\</pre\>
\
This won’t do because another lookahead is likely to occur before the
action is\
reduced. This time the lookahead works to our disadvantage. With this it
should\
be clear that abusing the lookahead of a LALR parser is pretty tricky
and not\
something a novice should be doing.
\
h3. \`do\`〜\`end\` iterator
\
So far we’ve dealt with the \`{\`〜\`}\` iterator, but we still have
\`do\`〜\`end\`\
left. Since they’re both iterators, one would expect the same solutions
to work,\
but it isn’t so. The priorities are different. For example,
\
\<pre class=“emlist”\>\
m a, b \# m)\
m a, b do …. end \# m do….end\
\</pre\>
\
Thus it’s only appropriate to deal with them differently.
\
That said, in some situations the same solutions do apply.\
The example below is one such situation
\
\<pre class=“emlist”\>\
m \
m do …. end\
\</pre\>
\
In the end, our only option is to look at the real thing.\
Since we’re dealing with \`do\` here, we should look in the part of
\`yylex\`\
that handles reserved words.
\
▼ \`yylex\`-Identifiers-Reserved words-\`do\`\
\<pre class=“longlist”\>\
4183 if {\
4184 if ) return kDO\_COND;\
4185 if && state != EXPR\_CMDARG)\
4186 return kDO\_BLOCK;\
4187 if \
4188 return kDO\_BLOCK;\
4189 return kDO;\
4190 }
\
\
\</pre\>
\
This time we only need the part that distinguishes between
\`kDO\_BLOCK\` and \`kDO\`.\
Ignore \`kDO\_COND\` Only look at what’s always relevant in a
finite-state scanner.
\
The decision-making part using \`EXPR\_ENDARG\` is the same as
\`tLBRACE\_ARG\` so\
priorities shouldn’t be an issue here. Similarly to \`’ while \
  99 \#define CMDARG\_P
\
\
\</pre\>
\
The structure and interface of \`cmdarg\_stack\` is completely
identical\
to \`cond\_stack\`. It’s a stack of bits. Since it’s the same, we can
use the same\
means to investigate it. Let’s list up the places which use it.\
First, during the action we have this:
\
\<pre class=“emlist”\>\
command\_args : {\
                        \$<num>\$ = cmdarg\_stack;\
                        CMDARG\_PUSH;\
                    }\
                  open\_args\
                    {\
                        /** CMDARG\_POP() **/\
                        cmdarg\_stack = \$<num>1;\
                        \$\$ = \$2;\
                    }\
\</pre\>
\
\`\$<num>\$\` represents the left value with a forced casting. In this
case it\
comes out as the value of the embedding action itself, so it can be
produced in\
the next action with \`\$<num>1\`. Basically, it’s a structure where
\`cmdarg\_stack\`\
is hidden in \`\$\$\` before \`open\_args\` and then restored in the
next action.
\
But why use a hide-restore system instead of a simple push-pop? That
will be\
explained at the end of this section.
\
Searching \`yylex\` for more \`CMDARG\` relations, I found this.
\
|*. Token |*. Relation |\
| \`’\` |\
| \`’)’ ’]’ ’}’\` | \`CMDARG\_LEXPOP\` |
\
Basically, as long as it is enclosed in parentheses, \`CMDARG\_P\` is
false.
\
Consider both, and it can be said that when \`command\_args\` , a
parameter for a\
method call with parentheses omitted, is not enclosed in parentheses\
\`CMDARG\_P\` is true.
\
h4. \`EXPR\_CMDARG\`
\
Now let’s take a look at one more condition - \`EXPR\_CMDARG\`\
Like before, let us look for place where a transition to
\`EXPR\_CMDARG\` occurs.
\
▼ \`yylex\`-Identifiers-State Transitions\
\<pre class=“longlist”\>\
4201 if {\
4206 if \
4207 lex\_state = EXPR\_CMDARG;\
4208 else\
4209 lex\_state = EXPR\_ARG;\
4210 }\
4211 else {\
4212 lex\_state = EXPR\_END;\
4213 }
\
\
\</pre\>
\
This is code that handles identifiers inside \`yylex\`\
Leaving aside that there are a bunch of \`lex\_state\` tests in here,
let’s look\
first at \`cmd\_state\`\
And what is this?
\
▼ \`cmd\_state\`\
\<pre class=“longlist”\>\
3106 static int\
3107 yylex\
3108 {\
3109 static ID last\_id = 0;\
3110 register int c;\
3111 int space\_seen = 0;\
3112 int cmd\_state;\
3113\
3114 if {\
              /** ……omitted…… **/\
3132 }\
3133 cmd\_state = command\_start;\
3134 command\_start = Qfalse;
\
\
\</pre\>
\
Turns out it’s an \`yylex\` local variable. Furthermore, an
investigation using\
\`grep\` revealed that here is the only place where its value is
altered. This\
means it’s just a temporary variable for storing \`command\_start\`
during a\
single run of \`yylex\`
\
When does \`command\_start\` become true, then?
\
▼ \`command\_start\`\
\<pre class=“longlist”\>\
2327 static int command\_start = Qtrue;
\
2334 static NODE**\
2335 yycompile(f, line)\
2336 char **f;\
2337 int line;\
2338 {\
                   :\
2380 command\_start = 1;
\
      static int\
      yylex\
      {\
                   :\
            case ’\n’:\
              /** ……omitted…… \*/\
3165 command\_start = Qtrue;\
3166 lex\_state = EXPR\_BEG;\
3167 return’\n‘;
\
3821 case’;‘:\
3822 command\_start = Qtrue;
\
3841 case’\
\</pre\>
\
From this we understand that \`command\_start\` becomes true when one of
the\
\`parse.y\` static variables \`\\n ; \` run \`cmd\_state\`\
becomes true.
\
And here is the code in \`yylex\` that uses \`cmd\_state\`
\
▼ \`yylex\`-Identifiers-State transitions\
\<pre class=“longlist”\>\
4201 if {\
4206 if \
4207 lex\_state = EXPR\_CMDARG;\
4208 else\
4209 lex\_state = EXPR\_ARG;\
4210 }\
4211 else {\
4212 lex\_state = EXPR\_END;\
4213 }
\
\
\</pre\>
\
From this we understand the following: when after \`\\n ; && state !=
EXPR\_CMDARG)\
4186 return kDO\_BLOCK;
\
\
\</pre\>
\
Inside the parameter of a method call with parentheses omitted but not
before\
the first parameter. That means from the second parameter of
\`command\_call\`\
onward. Basically, like this:
\
\<pre class=“emlist”\>\
m arg, arg do …. end\
m , arg do …. end\
\</pre\>
\
Why is the case of \`EXPR\_CMDARG\` excluded? This example should clear
It up
\
\<pre class=“emlist”\>\
m do …. end\
\</pre\>
\
This pattern can already be handled using the \`do\`〜\`end\` iterator
which uses\
\`kDO\` and is defined in \`primary\` Thus, including that case would
cause another\
conflict.
\
h3. Reality and truth
\
Did you think we’re done? Not yet.\
Certainly, the theory is now complete, but only if everything that has
been\
written is correct.\
As a matter of fact, there is one falsehood in this section.\
Well, more accurately, it isn’t a falsehood but an inexact statement.\
It’s in the part about \`CMDARG\_P\`
\
\<div class=“center”\>\
Actually, \`CMDARG\_P\` becomes true when inside \`command\_args\` ,
that is to say,\
inside the parameter of a method call with parentheses omitted.\
\</div\>
\
But where exactly is “inside the parameter of a method call with
parentheses\
omitted”? Once again, let us use \`rubylex-analyser\` to inspect in
detail.
\
\<pre class=“screen”\>\
 rubylex-analyser -e  'm a,a,a,a;'
+EXPR\_BEG
EXPR\_BEG     C        "m"  tIDENTIFIER          EXPR\_CMDARG
EXPR\_CMDARG S         "a"  tIDENTIFIER          EXPR\_ARG
                                              1:cmd push-
EXPR\_ARG              ","  ','                  EXPR\_BEG
EXPR\_BEG              "a"  tIDENTIFIER          EXPR\_ARG
EXPR\_ARG              ","  ','                  EXPR\_BEG
EXPR\_BEG              "a"  tIDENTIFIER          EXPR\_ARG
EXPR\_ARG              ","  ','                  EXPR\_BEG
EXPR\_BEG              "a"  tIDENTIFIER          EXPR\_ARG
EXPR\_ARG              ";"  ';'                  EXPR\_BEG
                                              0:cmd resume
EXPR\_BEG     C       "\\n"  '                    EXPR\_BEG
\</pre\>

The \`1:cmd push-\` in the right column is the push to \`cmd\_stack\`. When the
rightmost digit in that line is 1 \`CMDARG\_P()\` become true. To sum up, the
period of \`CMDARG\_P()\` can be described as:

\<div class="center"\>
From immediately after the first parameter of a method call with parentheses omitted
To the terminal symbol following the final parameter
\</div\>

But, very strictly speaking, even this is still not entirely accurate.

\<pre class="screen"\>
 rubylex-analyser~~e ‘m a(),a,a;’\
+EXPR\_BEG\
EXPR\_BEG C “m” tIDENTIFIER EXPR\_CMDARG\
EXPR\_CMDARG S “a” tIDENTIFIER EXPR\_ARG\
                                              1:cmd push-\
EXPR\_ARG “(” ‘(’ EXPR\_BEG\
                                              0:cond push\
                                             10:cmd push\
EXPR\_BEG C “)” ‘)’ EXPR\_END\
                                              0:cond lexpop\
                                              1:cmd lexpop\
EXPR\_END “,” ‘,’ EXPR\_BEG\
EXPR\_BEG “a” tIDENTIFIER EXPR\_ARG\
EXPR\_ARG “,” ‘,’ EXPR\_BEG\
EXPR\_BEG “a” tIDENTIFIER EXPR\_ARG\
EXPR\_ARG “;” ‘;’ EXPR\_BEG\
                                              0:cmd resume\
EXPR\_BEG C “\n” ‘EXPR\_BEG\
\</pre\>
\
When the first terminal symbol of the first parameter has been read,\
\`CMDARG\_P()\` is true. Therefore, the complete answer would be:
\
\<div class=“center”\>\
From the first terminal symbol of the first parameter of a method call
with parentheses omitted\
To the terminal symbol following the final parameter\
\</div\>
\
What repercussions does this fact have? Recall the code that uses
\`CMDARG\_P()\`
\
▼ \`yylex\`-Identifiers-Reserved words-\`kDO\`-\`kDO\_BLOCK\`\
\<pre class=“longlist”\>\
4185 if (CMDARG\_P() && state != EXPR\_CMDARG)\
4186 return kDO\_BLOCK;
\
(parse.y)\
\</pre\>
\
\`EXPR\_CMDARG\` stands for “Before the first parameter of
\`command\_call\`” and is\
excluded. But wait, this meaning is also included in \`CMDARG\_P()\`.\
Thus, the final conclusion of this section:
\
\<div class=“center”\>\
EXPR\_CMDARG is completely useless\
\</div\>
\
Truth be told, when I realized this, I almost broke down crying. I was
sure it\
had to mean SOMETHING and spent enormous effort analyzing the source,
but\
couldn’t understand anything. Finally, I ran all kind of tests on the
code\
using \`rubylex-analyser\` and arrived at the conclusion that it has no
meaning\
whatsoever.
\
I didn’t spend so much time doing something meaningless just to fill up
more\
pages. It was an attempt to simulate a situation likely to happen in
reality.\
No program is perfect, all programs contain their own mistakes.
Complicated\
situations like the one discussed here are where mistakes occur most
easily,\
and when they do, reading the source material with the assumption that
it’s\
flawless can really backfire. In the end, when reading the source code,
you can\
only trust the what actually happens.
\
Hopefully, this will teach you the importance of dynamic analysis. When\
investigating something, focus on what really happens. The source code
will not\
tell you everything. It can’t tell anything other than what the reader
infers.
\
And with this very useful sermon, I close the chapter.
\
h4. Still not the end
\
Another thing I forgot. I can’t end the chapter without explaining why\
\`CMDARG\_P()\` takes that value. Here’s the problematic part:
\
▼ \`command\_args\`\
\<pre class=“longlist”\>\
1209 command\_args : {\
1210 \$<num>\$ = cmdarg\_stack;\
1211 CMDARG\_PUSH(1);\
1212 }\
1213 open\_args\
1214 {\
1215 /\* CMDARG\_POP() \*/\
1216 cmdarg\_stack = \$<num>1;\
1217 \$\$ = \$2;\
1218 }
\
1221 open\_args : call\_args
\
(parse.y)\
\</pre\>
\
All things considered, this looks like another influence from
lookahead.\
\`command\_args\` is always in the following context:
\
\<pre class=“emlist”\>\
tIDENTIFIER \_\
\</pre\>
\
Thus, this looks like a variable reference or a method call. If it’s a
variable\
reference, it needs to be reduced to \`variable\` and if it’s a method
call it\
needs to be reduced to \`operation\` We cannot decide how to proceed
without\
employing lookahead. Thus a lookahead always occurs at the head of\
\`command\_args\` and after the first terminal symbol of the first
parameter is\
read, \`CMDARG\_PUSH()\` is executed.
\
The reason why \`POP\` and \`LEXPOP\` exist separately in
\`cmdarg\_stack\` is also\
here. Observe the following example:
\
\<pre class=“screen”\>\
% rubylex-analyser ~~e ’m m , a’\
~~e:1: warning: parenthesize argument(s) for future version\
*EXPR\_BEG\
EXPR\_BEG C “m” tIDENTIFIER EXPR\_CMDARG\
EXPR\_CMDARG S “m” tIDENTIFIER EXPR\_ARG\
                                              1:cmd push-\
EXPR\_ARG S “(” tLPAREN\_ARG EXPR\_BEG\
                                              0:cond push\
                                             10:cmd push\
                                            101:cmd push-\
EXPR\_BEG C “a” tIDENTIFIER EXPR\_CMDARG\
EXPR\_CMDARG “)” ’)’ EXPR\_END\
                                              0:cond lexpop\
                                             11:cmd lexpop\
*EXPR\_ENDARG\
EXPR\_ENDARG “,”’,’ EXPR\_BEG\
EXPR\_BEG S “a” tIDENTIFIER EXPR\_ARG\
EXPR\_ARG “\n” \n                   EXPR\_BEG\
                                             10:cmd resume\
                                              0:cmd resume\

</pre>
Looking only at the parts related to \`cmd\` and how they correspond to
each other…

<pre class="emlist">
  1:cmd push- parserpush(1)\
 10:cmd push scannerpush\
101:cmd push- parserpush(2)\
 11:cmd lexpop scannerpop\
 10:cmd resume parserpop(2)\
  0:cmd resume parserpop(1)\

</pre>
The \`cmd push-\` with a minus sign at the end is a parser push.
Basically,\
\`push\` and \`pop\` do not correspond. Originally there were supposed
to be two\
consecutive \`push-\` and the stack would become 110, but due to the
lookahead\
the stack became 101 instead. \`CMDARG\_LEXPOP()\` is a last-resort
measure to\
deal with this. The scanner always pushes 0 so normally what it pops
should\
also always be 0. When it isn’t 0, we can only assume that it’s 1 due to
the\
parser \`push\` being late. Thus, the value is left.

Conversely, at the time of the parser \`pop\` the stack is supposed to
be back in\
normal state and usually \`pop\` shouldn’t cause any trouble. When it
doesn’t do\
that, the reason is basically that it should work right. Whether popping
or\
hiding in \`\$\$\` and restoring, the process is the same. When you
consider all\
the following alterations, it’s really impossible to tell how
lookahead’s\
behavior will change. Moreover, this problem appears in a grammar that’s
going\
to be forbidden in the future (that’s why there is a warning). To make\
something like this work, the trick is to consider numerous possible
situations\
and respond them. And that is why I think this kind of implementation is
right\
for Ruby. Therein lies the real solution.
