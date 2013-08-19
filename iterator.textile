* * * * *

layout: default\
title: “Chapter 16: Blocks”\
—

Chapter 16: Blocks
==================

Iterator
--------

In this chapter, \`BLOCK\`, which is the last big name among the seven
Ruby stacks,\
comes in.\
After finishing this, the internal state of the evaluator is virtually
understood.

### The Whole Picture

What is the mechanism of iterators?\
First, let’s think about a small program as below:

<p class="caption">
▼The Source Program

</p>
<pre class="longlist">
iter\_method() do\
 9 \# a mark to find this block\
end\

</pre>
Let’s check the terms just in case.\
As for this program, \`iter\_method\` is an iterator method,\
\`do\` \~ \`end\` is an iterator block.\
Here is the syntax tree of this program being dumped.

<p class="caption">
▼Its Syntax Tree

</p>
<pre class="longlist">
NODE\_ITER\
nd\_iter:\
 NODE\_FCALL\
 nd\_mid = 9617 (iter\_method)\
 nd\_args = (null)\
nd\_var = (null)\
nd\_body:\
 NODE\_LIT\
 nd\_lit = 9:Fixnum\

</pre>
Looking for the block by using the 9 written in the iterator block as a
trace,\
we can understand that \`NODE\_ITER\` seems to represent the iterator
block.\
And \`NODE\_FCALL\` which calls \`iter\_method\` is at the “below” of
that\
\`NODE\_ITER\`. In other words, the node of iterator block appears
earlier than the call\
of the iterator method. This means, before calling an iterator method,\
a block is pushed at another node.

And checking by following the flow of code with debugger,\
I found that the invocation of an iterator is separated into 3 steps:\
\`NODE\_ITER NODE\_CALL\` and \`NODE\_YIELD\`.\
This means,

\#1 push a block (\`NODE\_ITER\`)\
\#2 call the method which is an iterator (\`NODE\_CALL\`)\
\#3 \`yield\` (\`NODE\_YEILD\`)

that’s all.

### Push a block

First, let’s start with the first step, that is \`NODE\_ITER\`, which is
the node\
to push a block.

<p class="caption">
▼ \`rb\_eval()\` − \`NODE\_ITER\` (simplified)

</p>
<pre class="longlist">
case NODE\_ITER:\
 {\
 iter\_retry:\
 PUSH\_TAG(PROT\_FUNC);\
 PUSH\_BLOCK(node~~\>nd\_var, node~~\>nd\_body);

state = EXEC\_TAG();\
 if (state  0) {
          PUSH\_ITER(ITER\_PRE);
          result = rb\_eval(self, node-\>nd\_iter);
          POP\_ITER();
      }
      else if (\_block.tag-\>dst  state) {\
 state &= TAG\_MASK;\
 if (state  TAG\_RETURN || state  TAG\_BREAK) {\
 result = prot\_tag~~\>retval;\
 }\
 }\
 POP\_BLOCK;\
 POP\_TAG;\
 switch {\
 case 0:\
 break;
\
 case TAG\_RETRY:\
 goto iter\_retry;
\
 case TAG\_BREAK:\
 break;
\
 case TAG\_RETURN:\
 return\_value;\
 /\* fall through **/\
 default:\
 JUMP\_TAG;\
 }\
 }\
 break;\
\</pre\>

\
Since the original code contains the support of the \`for\` statement,
it is\
deleted. After removing the code relating to tags,\
there are only push/pop of \`ITER\` and \`BLOCK\` left.\
Because the rest is ordinarily doing \`rb\_eval\` with \`NODE\_FCALL\`,\
these \`ITER\` and \`BLOCK\` are the necessary conditions to turn a
method into an iterator.

\
The necessity of pushing \`BLOCK\` is fairly reasonable, but what’s
\`ITER\` for?\
Actually, to think about the meaning of \`ITER\`, you need to think from
the\
viewpoint of the side that uses \`BLOCK\`.

\
For example, suppose a method is just called. And \`ruby\_block\`
exists.\
But since \`BLOCK\` is pushed regardless of the break of method calls,\
the existence of a block does not mean the block is pushed for that
method.\
It’s possible that the block is pushed for the previous method.

\
\<div class=“image”\>\
<img src="images/ch_iterator_stacks.jpg" alt="(stacks)"><br>\
Figure 1: no one-to-one correspondence between \`FRAME\` and \`BLOCK\`\
** 上が先端 the end is above\
\* FRAMEに対応するBLOCKがあるか？ Is there any BLOCK that corresponds to
FRAME ?\
\* ある（けどイテレータではない） Yes. \
\* ある（本当にイテレータ） Yes. \
\* ない No.\
\</div\>

\
So, in order to determine for which method the block is pushed, \`ITER\`
is used.\
\`BLOCK\` is not pushed for each \`FRAME\`\
because pushing \`BLOCK\` is a little heavy.\
How much heavy is,\
let’s check it in practice.



\
h4. \`PUSH\_BLOCK\`

\
The argument of \`PUSH\_BLOCK\` is the block parameter and\
the block body.

\
\<p class=“caption”\>▼ \`PUSH\_BLOCK POP\_BLOCK\` \</p\>
\
\<pre class=“longlist”\>\
 592 \#define PUSH\_BLOCK do { \
 593 struct BLOCK *block; \
 594*block.tag = new\_blktag; \
 595 *block.var = v; \
 596*block.body = b; \
 597 *block.self = self; \
 598*block.frame = **ruby\_frame; \
 599 *block.klass = ruby\_class; \
 600*block.frame.node = ruby\_current\_node;\
 601 *block.scope = ruby\_scope; \
 602*block.prev = ruby\_block; \
 603 *block.iter = ruby\_iter-\>iter; \
 604*block.vmode = scope\_vmode; \
 605 *block.flags = BLOCK\_D\_SCOPE; \
 606*block.dyna\_vars = ruby\_dyna\_vars; \
 607 *block.wrapper = ruby\_wrapper; \
 608 ruby\_block = &\_block
\
 610 \#define POP\_BLOCK \
 611 if ) \
 612*block.tag~~\>flags |= BLOCK\_ORPHAN; \
 613 else if ) \
 614 rb\_gc\_force\_recycle*block.tag); \
 615 ruby\_block =*block.prev; \
 616 } while
\
\
\</pre\>

\
Let’s make sure that a \`BLOCK\` is “the snapshot of the environment of
the moment\
of creation”. As a proof of it, except for \`CREF\` and \`BLOCK\`, the
six stack\
frames are saved. \`CREF\` can be substituted by
\`ruby\_frame~~\>cbase\`, there’s no\
need to push.

\
And, I’d like to check the three points about the mechanism of push.\
\`BLOCK\` is fully allocated on the stack.\
\`BLOCK\` contains the full copy of \`FRAME\` at the moment.\
\`BLOCK\` is different from the other many stack frame structs in having
the\
pointer to the previous \`BLOCK\` .

\
The flags used in various ways at \`POP\_BLOCK\` is not explained now\
because it can only be understood after seeing the implementation of
\`Proc\`\
later.

\
And the talk is about “\`BLOCK\` is heavy”, certainly it seems a little
heavy.\
When looking inside of \`new\_blktag\`,\
we can see it does \`malloc\` and store plenty of members.\
But let’s defer the final judge until after looking at and comparing
with \`PUSH\_ITER\`.


\
h4. \`PUSH\_ITER\`

\
\<p class=“caption”\>▼ \`PUSH\_ITER POP\_ITER\` \</p\>
\
\<pre class=“longlist”\>\
 773 \#define PUSH\_ITER do { \
 774 struct iter *iter; \
 775*iter.prev = ruby\_iter; \
 776 *iter.iter = ; \
 777 ruby\_iter = &\_iter
\
 779 \#define POP\_ITER \
 780 ruby\_iter =*iter.prev; \
 781 } while
\
\
\</pre\>

\
On the contrary, this is apparently light.\
It only uses the stack space and has only two members.\
Even if this is pushed for each \`FRAME\`,\
it would probably matter little.



\
h3. Iterator Method Call

\
After pushing a block, the next thing is to call an iterator method .
There also needs a little machinery.\
Do you remember that there’s a code to modify\
the value of \`ruby\_iter\` at the beginning of \`rb\_call0\`?\
Here.

\
\<p class=“caption”\>▼ \`rb\_call0\` − moving to \`ITER\_CUR\` \</p\>
\
\<pre class=“longlist”\>\
4498 switch {\
4499 case ITER\_PRE:\
4500 itr = ITER\_CUR;\
4501 break;\
4502 case ITER\_CUR:\
4503 default:\
4504 itr = ITER\_NOT;\
4505 break;\
4506 }
\
\
\</pre\>

\
Since \`ITER\_PRE\` is pushed previously at \`NODE\_TER\`, this code
makes\
\`ruby\_iter\` \`ITER\_CUR\`.\
At this moment, a method finally “becomes” an iterator.\
Figure 2 shows the state of the stacks.

\
\<div class=“image”\>\
<img src="images/ch_iterator_itertrans.jpg" alt="(itertrans)"><br>\
Figure 2: the state of the Ruby stacks on an iterator call.\
** 上が先端 the end is above\
\* イテレータか？（FRAMEに対応するITERがITER\_CURか？）\
 Is this an iterator? \
\</div\>

\
The possible value of \`ruby\_iter\` is not the one of two boolean
values\
, but one of three steps because there’s a little gap\
between the timings when pushing a block and invoking an iterator
method.\
For example, there’s the evaluation of the arguments of an iterator
method.\
Since it’s possible that it contains method calls inside it,\
there’s the possibility that one of that methods mistakenly thinks that
the\
just pushed block is for itself and uses it during the evaluation.\
Therefore, the timing when a method becomes an iterator,\
this means turning into \`ITER\_CUR\`,\
has to be the place inside of \`rb\_call\` that is just before finishing
the invocation.

\
\<p class=“caption”\>▼ the processing order\</p\>\
\<div class=“longlist”\>\
method <span class="ami">{ block }</span> \# push a block<br>\
method { block } \# evaluate the aruguments<br>\
<span class="ami">method</span> { block } \# a method call <br>\
\</div\>

\
For example, in the last chapter “Method”, there’s a macro named
\`BEGIN\_CALLARGS\` at a handler of \`NODE\_CALL\`.\
This is where making use of the third step \`ITER\`.\
Let’s go back a little and try to see it.

\
h4. \`BEGIN\_CALLARGS END\_CALLARGS\`

\
\<p class=“caption”\>▼ \`BEGIN\_CALLARGS END\_CALLARGS\` \</p\>
\
\<pre class=“longlist”\>\
1812 \#define BEGIN\_CALLARGS do \
1817 PUSH\_ITER
\
1819 \#define END\_CALLARGS \
1820 ruby\_block = tmp\_block;\
1821 POP\_ITER;\
1822 } while
\
\
\</pre\>

\
When \`ruby\_iter\` is \`ITER\_PRE\`, a \`ruby\_block\` is set aside.\
This code is important, for instance, in the below case:


\
\<pre class=“emlist”\>\
obj.m1 { yield }.m2 { nil }\
\</pre\>

\
The evaluation order of this expression is:

\
\#1 push the block of \`m2\`\
\#2 push the block of \`m1\`\
\#3 call the method \`m1\`\
\#4 call the method \`m2\`

\
Therefore, if there was not \`BEGIN\_CALLARGS\`,\
\`m1\` will call the block of \`m2\`.

\
And, if there’s one more iterator connected,\
the number of \`BEGIN\_CALLARGS\` increases at the same time in this
case,\
so there’s no problem.



\
h3. Block Invocation

\
The third phase of iterator invocation, it means the last phase,\
is block invocation.

\
\<p class=“caption”\>▼ \`rb\_eval\` − \`NODE\_YIELD\` \</p\>
\
\<pre class=“longlist”\>\
2579 case NODE\_YIELD:\
2580 if {\
2581 result = avalue\_to\_yvalue);\
2582 }\
2583 else {\
2584 result = Qundef; /\* no arg **/\
2585 }\
2586 SET\_CURRENT\_SOURCE;\
2587 result = rb\_yield\_0;\
2588 break;
\
\
\</pre\>

\
\`nd\_stts\` is the parameter of \`yield\`.\
\`avalue\_to\_yvalue\` was mentioned a little at the multiple
assignments,\
but you can ignore this.\
<br>)<br>\
The heart of the behavior is not this but \`rb\_yield\_0\`.\
Since this function is also very long,\
I show the code after extremely simplifying it.\
Most of the methods to simplify are previously used.

\
** cut the codes relating to \`trace\_func\`.\
\* cut errors\
\* cut the codes exist only to prevent from GC\
\* As the same as \`massign\`, there’s the parameter \`pcall\`.\
This parameter is to change the level of restriction of the parameter
check,\
so not important here. Therefore, assume \`pcal=0\` and perform constant
foldings.

\
And this time, I turn on the “optimize for readability option” as
follows.
\
\* when a code branching has equivalent kind of branches,\
 leave the main one and cut the rest.\
\* if a condition is true/false in the almost all case, assume it is
true/false.\
\* assume there’s no tag jump occurs, delete all codes relating to tag.


\
If things are done until this,\
it becomes very shorter.

\
\<p class=“caption”\>▼ \`rb\_yield\_0\` \</p\>
\
\<pre class=“longlist”\>\
static VALUE\
rb\_yield\_0\
 VALUE val, self, klass;\
{\
 volatile VALUE result = Qnil;\
 volatile VALUE old\_cref;\
 volatile VALUE old\_wrapper;\
 struct BLOCK \* volatile block;\
 struct SCOPE \* volatile old\_scope;\
 struct FRAME frame;\
 int state;
\
 PUSH\_VARS;\
 PUSH\_CLASS;\
 block = ruby\_block;\
 frame = block~~\>frame;\
 frame.prev = ruby\_frame;\
 ruby\_frame = &(frame);\
 old\_cref = (VALUE)ruby\_cref;\
 ruby\_cref = (NODE**)ruby\_frame~~\>cbase;\
 old\_wrapper = ruby\_wrapper;\
 ruby\_wrapper = block~~\>wrapper;\
 old\_scope = ruby\_scope;\
 ruby\_scope = block~~\>scope;\
 ruby\_block = block~~\>prev;\
 ruby\_dyna\_vars = new\_dvar;\
 ruby\_class = block~~\>klass;\
 self = block~~\>self;
\
 /** set the block arguments **/\
 massign;
\
 PUSH\_ITER;\
 /** execute the block body **/\
 result = rb\_eval;\
 POP\_ITER;
\
 POP\_CLASS;\
 /** ……collect ruby\_dyna\_vars…… **/\
 POP\_VARS;\
 ruby\_block = block;\
 ruby\_frame = ruby\_frame~~\>prev;\
 ruby\_cref = old\_cref;\
 ruby\_wrapper = old\_wrapper;\
 ruby\_scope = old\_scope;
\
 return result;\
}\
\</pre\>

\
As you can see, the most stack frames are replaced with what saved at
\`ruby\_block\`.\
Things to simple save/restore are easy to understand,\
so let’s see the handling of the other frames we need to be careful
about.

\
h4. \`FRAME\`


\
\<pre class=“emlist”\>\
struct FRAME frame;
\
frame = block~~\>frame; /** copy the entire struct **/\
frame.prev = ruby\_frame; /** by these two lines…… **/\
ruby\_frame = &; /** ……frame is pushed **/\
\</pre\>

\
Differing from the other frames, a \`FRAME\` is not used in the saved
state,\
but a new \`FRAME\` is created by duplicating.\
This would look like Figure 3.

\
\<div class=“image”\>\
<img src="images/ch_iterator_framepush.jpg" alt="(framepush)"><br>\
Figure 3: push a copied frame\
** コピーして作る creating by copying\

</div>
As we’ve seen the code until here,\
it seems that \`FRAME\` will never be “reused”.\
When pushing \`FRAME\`, a new \`FRAME\` will always be created.

#### \`BLOCK\`

<pre class="emlist">
block = ruby\_block;\
 ：\
ruby\_block = block~~\>prev;\
 ：\
ruby\_block = block;\
\</pre\>


\
What is the most mysterious is this behavior of \`BLOCK\`.\
We can’t easily understand whether it is saving or popping.\
It’s comprehensible that the first statement and the third statement are
as a pair,\
and the state will be eventually back.\
However, what is the consequence of the second statement?

\
To put the consequence of I’ve pondered a lot in one phrase,\
“going back to the \`ruby\_block\` of at the moment when pushing the
block”.\
An iterator is, in short, the syntax to go back to the previous frame.\
Therefore, all we have to do is turning the state of the stack frame
into what\
was at the moment when creating the block.\
And, the value of \`ruby\_block\` at the moment when creating the block
is,\
it seems certain that it was \`block~~\>prev\`.\
Therefore, it is contained in \`prev\`.

Additionally, for the question “is it no problem to assume what invoked
is\
always the top of \`ruby\_block\`?”,\
there’s no choice but saying “as the \`rb\_yield\_0\` side, you can
assume so”.\
To push the block which should be invoked on the top of the
\`ruby\_block\` is the\
work of the side to prepare the block,\
and not the work of \`rb\_yield\_0\`.

An example of it is \`BEGIN\_CALLARGS\` which was discussed in the
previous chapter.\
When an iterator call cascades, the two blocks are pushed and the top of
the\
stack will be the block which should not be used.\
Therefore, it is purposefully checked and set aside.

#### \`VARS\`

Come to think of it,\
I think we have not looked the contents of \`PUSH\_VARS()\` and
\`POP\_VARS()\` yet.\
Let’s see them here.

<p class="caption">
▼ \`PUSH\_VARS() POP\_VARS()\`

</p>
<pre class="longlist">
619 \#define PUSH\_VARS() do { \
 620 struct RVarmap \* volatile *old; \
 621*old = ruby\_dyna\_vars; \
 622 ruby\_dyna\_vars = 0

624 \#define POP\_VARS() \
 625 if (*old && ) { \
 626 if ~~\>flags) /\* if were not recycled **/ \
 627 FL\_SET; \
 628 } \
 629 ruby\_dyna\_vars = *old; \
 630 } while
\
\
\</pre\>

\
This is also not pushing a new struct, to say “set aside/restore” is
closer.\
In practice, in \`rb\_yield\_0\`, \`PUSH\_VARS\` is used only to set
aside the value.\
What actually prepares \`ruby\_dyna\_vars\` is this line.


\
\<pre class=“emlist”\>\
ruby\_dyna\_vars = new\_dvar;\
\</pre\>

\
This takes the \`dyna\_vars\` saved in \`BLOCK\` and sets it.\
An entry is attached at the same time.\
I’d like you to recall the description of the structure of
\`ruby\_dyna\_vars\` in Part 2,\
it said the \`RVarmap\` whose \`id\` is 0 such as the one created here
is used as\
the break between block scopes.

\
However, in fact, between the parser and the evaluator, the form of the
link\
stored in \`ruby\_dyna\_vars\` is slightly different.\
Let’s look at the \`dvar\_asgn\_curr\` function, which assigns a block
local\
variable at the current block.

\
\<p class=“caption”\>▼ \`dvar\_asgn\_curr\` \</p\>
\
\<pre class=“longlist”\>\
 737 static inline void\
 738 dvar\_asgn\_curr\
 739 ID id;\
 740 VALUE value;\
 741 {\
 742 dvar\_asgn\_internal;\
 743 }
\
 699 static void\
 700 dvar\_asgn\_internal\
 701 ID id;\
 702 VALUE value;\
 703 int curr;\
 704 {\
 705 int n = 0;\
 706 struct RVarmap **vars = ruby\_dyna\_vars;\
 707\
 708 while {\
 709 if {\
 710 /** first null is a dvar header **/\
 711 n++;\
 712 if break;\
 713 }\
 714 if {\
 715 vars~~\>val = value;\
 716 return;\
 717 }\
 718 vars = vars~~\>next;\
 719 }\
 720 if {\
 721 ruby\_dyna\_vars = new\_dvar;\
 722 }\
 723 else {\
 724 vars = new\_dvar;\
 725 ruby\_dyna\_vars-\>next = vars;\
 726 }\
 727 }
\
\
\</pre\>

\
The last \`if\` statement is to add a variable.\
If we focus on there, we can see a link is always pushed in at the
“next” to\
\`ruby\_dyna\_vars\`. This means, it would look like Figure 4.

\
\<div class=“image”\>\
<img src="images/ch_iterator_dynavarseval.jpg" alt="(dynavarseval)"><br>\
Figure 4: the structure of \`ruby\_dyna\_vars\`\
** ブロック起動時に追加 added when invoking a block\
\* ブロック起動直後 immediately after invoking a block\
\* ブロック変数を追加 add block variables\
\* 追加された変数 added variables\
\</div\>

\
This differs from the case of the parser in one point:\
the headers to indicate the breaks of scopes are attached before the\
links. If a header is attached after the links, the first one of the
scope\
cannot be inserted properly. <br>\
)
\
\<div class=“image”\>\
<img src="images/ch_iterator_insert.jpg" alt="(insert)"><br>\
Figure 5: cannot properly insert an entry\
\* ここに挿入しないといけない must be inserted here\
\</div\>



\
h3. Target Specified Jump

\
The code relates to jump tags are omitted in the previously shown code,\
but there’s an effort that we’ve never seen before in the jump of
\`rb\_yield\_0\`.\
Why is the effort necessary?\
I’ll tell the reason in advance. I’d like you to see the below program:


\
\<pre class=“emlist”\>\
.each do\
 break\
end\
\# the place to reach by break\
\</pre\>

\
like this way, in the case when doing \`break\` from inside of a block,\
it is necessary to get out of the block and go to the method that pushed
the\
block.\
What does it actually mean?\
Let’s think by looking at the call graph when invoking an iterator.


\
\<pre class=“emlist”\>\
rb\_eval …. catch\
 rb\_eval …. catch\
 rb\_eval\
 rb\_yield\_0\
 rb\_eval …. throw\
\</pre\>

\
Since what pushed the block is \`NODE\_ITER\`,\
it should go back to a \`NODE\_ITER\` when doing \`break\`.\
However, \`NODE\_CALL\` is waiting for \`TAG\_BREAK\` before
\`NODE\_ITER\`,\
in order to turn a \`break\` over methods into an error.\
This is a problem. We need to somehow find a way to go straight back to
a \`NODE\_ITER\`.

\
And actually, “going back to a \`NODE\_ITER\`” will still be a problem.\
If iterators are nesting,\
there could be multiple \`NODE\_ITER\`s,\
thus the one corresponds to the current block is not always the first
\`NODE\_ITER\`.\
In other words, we need to restrict only “the \`NODE\_ITER\` that pushed
the\
currently being invoked block”

\
Then, let’s see how this is resolved.

\
\<p class=“caption”\>▼ \`rb\_yield\_0\` − the parts relates to
tags\</p\>
\
\<pre class=“longlist”\>\
3826 PUSH\_TAG;\
3827 if )  0) {
              /\* ……evaluate the body…… \*/
3838      }
3839      else {
3840          switch (state) {
3841            case TAG\_REDO:
3842              state = 0;
3843              CHECK\_INTS;
3844              goto redo;
3845            case TAG\_NEXT:
3846              state = 0;
3847              result = prot\_tag-\>retval;
3848              break;
3849            case TAG\_BREAK:
3850            case TAG\_RETURN:
3851              state |= (serial++ \<\< 8);
3852              state |= 0x10;
3853              block-\>tag-\>dst = state;
3854              break;
3855            default:
3856              break;
3857          }
3858      }
3859      POP\_TAG();

(eval.c)
\</pre\>


The parts of \`TAG\_BREAK\` and \`TAG\_RETURN\` are crucial.


First, \`serial\` is a static variable of \`rb\_yield\_0()\`,
its value will be different every time calling \`rb\_yield\_0\`.
"serial" is the serial of "serial number".


The reason why left shifting by 8 bits seems in order to avoid overlapping the
values of \`TAG\_xxxx\`.
\`TAG\_xxxx\` is in the range between \`0x1\` \~ \`0x8\`, 4 bits are enough.
And, the bit-or of \`0x10\` seems to prevent \`serial\` from overflow.
In 32-bit machine, \`serial\` can use only 24 bits (only 16 million times),
recent machine can let it overflow within less than 10 seconds.
If this happens, the top 24 bits become all 0 in line.
Therefore, if \`0x10\` did not exist, \`state\` would be the same value as \`TAG\_xxxx\`
(See also Figure 6).


\<div class="image"\>
\<img src="images/ch\_iterator\_dst.jpg" alt="(dst)"\>\<br\>
Fig.6: \<tt\>block-&gt;tag-&gt;dst\</tt\>
\* 常に１ always 1
\</div\>


Now, \`tag-\>dst\` became the value which differs from \`TAG\_xxxx\` and is unique for each call.
In this situation, because an ordinary \`switch\` as previous ones cannot receive it,
the side to stop jumps should need efforts to some extent.
The place where making an effort is this place of \`rb\_eval:NODE\_ITER\`:


\<p class="caption"\>▼ \`rb\_eval()\` − \`NODE\_ITER\`  (to stop jumps)\</p\>

\<pre class="longlist"\>
case NODE\_ITER:
  {
      state = EXEC\_TAG();
      if (state  0) {\
 /\* …… invoke an iterator …… **/\
 }\
 else if {\
 state &= TAG\_MASK;\
 if {\
 result = prot\_tag~~\>retval;\
 }\
 }\
 }\
\</pre\>

\
In corresponding \`NODE\_ITER\` and \`rb\_yield\_0\`, \`block\` should
point to the same thing,\
so \`tag~~\>dst\` which was set at \`rb\_yield\_0\` comes in here.\
Because of this, only the corresponding \`NODE\_ITER\` can properly stop
the jump.



\
h3. Check of a block

\
Whether or not a currently being evaluated method is an iterator,\
in other words, whether there’s a block,\
can be checked by \`rb\_block\_given\_p\`.\
After reading the above all, we can tell its implementation.

\
\<p class=“caption”\>▼ \`rb\_block\_given\_p\` \</p\>
\
\<pre class=“longlist”\>\
3726 int\
3727 rb\_block\_given\_p\
3728 {\
3729 if \
3730 return Qtrue;\
3731 return Qfalse;\
3732 }
\
\
\</pre\>

\
I think there’s no problem. What I’d like to talk about this time is
actually\
another function to check, it is \`rb\_f\_block\_given\_p\`.

\
\<p class=“caption”\>▼ \`rb\_f\_block\_given\_p\` \</p\>
\
\<pre class=“longlist”\>\
3740 static VALUE\
3741 rb\_f\_block\_given\_p\
3742 {\
3743 if \
3744 return Qtrue;\
3745 return Qfalse;\
3746 }
\
\
\</pre\>

\
This is the substance of Ruby’s \`block\_given?\`.\
In comparison to \`rb\_block\_given\_p\`,\
this is different in checking the \`prev\` of \`ruby\_frame\`.\
Why is this?

\
Thinking about the mechanism to push a block,\
to check the current \`ruby\_frame\` like \`rb\_block\_given\_p\` is
right.\
But when calling \`block\_given?\` from Ruby-level,\
since \`block\_given?\` itself is a method,\
an extra \`FRAME\` is pushed.\
Hence, we need to check the previous one.



\
h2. \`Proc\`

\
To describe a \`Proc\` object from the viewpoint of implementing,\
it is “a \`BLOCK\` which can be bring out to Ruby level”.\
Being able to bring out to Ruby level means having more latitude,\
but it also means when and where it will be used becomes completely
unpredictable.\
Focusing on how the influence of this fact is, let’s look at the
implementation.

\
h3. \`Proc\` object creation

\
A \`Proc\` object is created with \`Proc.new\`.\
Its substance is \`proc\_new\`.

\
\<p class=“caption”\>▼ \`proc\_new\` \</p\>
\
\<pre class=“longlist”\>\
6418 static VALUE\
6419 proc\_new\
6420 VALUE klass;\
6421 {\
6422 volatile VALUE proc;\
6423 struct BLOCK**data, **p;\
6424 struct RVarmap**vars;\
6425\
6426 if && !rb\_f\_block\_given\_p) {\
6427 rb\_raise;\
6428 }\
6429\
 /\* （A）allocate both struct RData and struct BLOCK **/\
6430 proc = Data\_Make\_Struct;\
6431**data = **ruby\_block;\
6432\
6433 data~~\>orig\_thread = rb\_thread\_current;\
6434 data~~\>wrapper = ruby\_wrapper;\
6435 data~~\>iter = data~~\>prev?Qtrue:Qfalse;\
 /** （B）the essential initialization is finished by here **/\
6436 frame\_dup;\
6437 if {\
6438 blk\_copy\_prev;\
6439 }\
6440 else {\
6441 data~~\>prev = 0;\
6442 }\
6443 data~~\>flags |= BLOCK\_DYNAMIC;\
6444 data~~\>tag~~\>flags |= BLOCK\_DYNAMIC;\
6445\
6446 for {\
6447 for {\
6448 if ) break;\
6449 FL\_SET;\
6450 }\
6451 }\
6452 scope\_dup;\
6453 proc\_save\_safe\_level;\
6454\
6455 return proc;\
6456 }
\
\
\</pre\>

\
The creation of a \`Proc\` object itself is unexpectedly simple.\
Between and , a space for an \`Proc\` object is allocated and its\
initialization completes.\
\`Data\_Make\_Struct\` is a simple macro that does both \`malloc\` and\
\`Data\_Wrap\_Struct\` at the same time.

\
The problems exist after that:
\
** \`frame\_dup\`\
\* \`blk\_copy\_prev\`\
\* \`FL\_SET\`\
\* \`scope\_dup\`
\
These four have the same purposes. They are:

\
\* move all of what were put on the machine stack to the heap.\
\* prevent from collecting even if after \`POP\`

\
Here, “all” means the all things including \`prev\`.\
For the all stack frames pushed there, it duplicates each frame by\
doing \`malloc\` and copying.\
\`VARS\` is usually forced to be collected by \`rb\_gc\_force\_recycle\`
at the same moment of \`POP\`,\
but this behavior is stopped by setting the \`DVAR\_DONT\_RECYCLE\`
flag.\
And so on. Really extreme things are done.

\
Why are these extreme things necessary? This is because, unlike iterator
blocks,\
a \`Proc\` can persist longer than the method that created it.\
And the end of a method means the things allocated on the machine stack
such as\
\`FRAME\`, \`ITER\`, and \`local\_vars\` of \`SCOPE\` are invalidated.\
It’s easy to predict what the consequence of using the invalidated
memories.\
.

\
I tried to contrive a way to at least use the same \`FRAME\` from
multiple \`Proc\`,\
but since there are the places such as \`old\_frame\` where setting
aside the\
pointers to the local variables, it does not seem going well.\
If it requires a lot efforts in anyway,\
another effort, say, allocating all of them with \`malloc\` from the
frist place,\
seems better to give it a try.

\
Anyway, I sentimentally think that it’s surprising that it runs with
that speed\
even though doing these extreme things.\
Indeed, it has become a good time.


\
h3. Floating Frame

\
Previously, I mentioned it just in one phrase “duplicate all frames”,\
but since that was unclear, let’s look at more details.\
The points are the next two:

\
\* How to duplicate all\
\* Why all of them are duplicated

\
Then first, let’s start with the summary of how each stack frame is
saved.

\
|*. Frame |*. location |*. has \`prev\` pointer? |\
| \`FRAME\` | stack | yes |\
| \`SCOPE\` | stack | no |\
| \`local\_tbl\` | heap | |\
| \`local\_vars\` | stack | |\
| \`VARS\` | heap | no |\
| \`BLOCK\` | stack | yes |

\
\`CLASS CREF ITER\` are not necessary this time. Since \`CLASS\` is a
general Ruby\
object, \`rb\_gc\_force\_recycle\` is not called with it even by mistake
and both \`CREF\` and \`ITER\` becomes unnecessary after storing its\
values at the moment in \`FRAME\`.\
The four frames in the above table are important\
because these will be modified or referred to multiple times later.\
The rest three will not.

\
Then, this talk moves to how to duplicate all.\
I said “how”, but it does not about such as “by \`malloc()\`”.\
The problem is how to duplicate “all”.\
It is because, here I’d like you to see the above table,\
there are some frames without any \`prev\` pointer.\
In other words, we cannot follow links.\
In this situation, how can we duplicate all?

\
A fairly clever technique used to counter this.\
Let’s take \`SCOPE\` as an example.\
A function named \`scope\_dup\` is used previously in order to duplicate
\`SCOPE\`,\
so let’s see it first.

\
\<p class=“caption”\>▼ \`scope\_dup\` only the beginning\</p\>
\
\<pre class=“longlist”\>\
6187 static void\
6188 scope\_dup\
6189 struct SCOPE**scope;\
6190 {\
6191 ID **tbl;\
6192 VALUE**vars;\
6193\
6194 scope~~\>flags |= SCOPE\_DONT\_RECYCLE;
\
\
\</pre\>

\
As you can see, \`SCOPE\_DONT\_RECYCLE\` is set.\
Then next, take a look at the definition of \`POP\_SCOPE\`:

\
\<p class=“caption”\>▼ \`POP\_SCOPE\` only the beginning\</p\>
\
\<pre class=“longlist”\>\
 869 \#define POP\_SCOPE \
 870 if { \
 871 if scope\_dup; \
 872 } \
\
\
\</pre\>

\
When it pops, if \`SCOPE\_DONT\_RECYCLE\` flag was set to the current
\`SCOPE\` ,\
it also does \`scope\_dup\` of the previous \`SCOPE\` .\
In other words, \`SCOPE\_DONT\_RECYCLE\` is also set to this one.\
In this way, one by one, the flag is propagated at the time when it
pops.\


\
\<p class=“image”\>\
<img src="images/ch_iterator_flaginfect.jpg" alt="(flaginfect)"><br>\
Figure 7: flag propagation\
\</p\>

\
Since \`VARS\` also does not have any \`prev\` pointer,\
the same technique is used to propagate the \`DVAR\_DONT\_RECYCLE\`
flag.

\
Next, the second point, try to think about “why all of them are
duplicated”.\
We can understand that the local variables of \`SCOPE\` can be referred
to later\
if its \`Proc\` is created.\
However, is it necessary to copy all of them including the previous
\`SCOPE\` in\
order to accomplish that?

\
Honestly speaking, I couldn’t find the answer of this question and has
been\
worried about how can I write this section for almost three days,\
I’ve just got the answer. Take a look at the next program:


\
\<pre class=“emlist”\>\
def get\_proc\
 Proc.new { nil }\
end
\
env = get\_proc { p ‘ok’ }\
eval\
\</pre\>

\
I have not explained this feature, but by passing a \`Proc\` object as
the second\
argument of \`eval\`, you can evaluate the string in that environment.

\
It means, as the readers who have read until here can probably tell, it
pushes\
the various environments taken from the \`Proc\` and evaluates.\
In this case, it naturally also pushes \`BLOCK\` and\
you can turn the \`BLOCK\` into a \`Proc\` again.\
Then, using the \`Proc\` when doing \`eval\` … if things are done like
this, you\
can access almost all information of \`ruby\_block\` from Ruby level as
you like.\
This is the reason why the entire stacks need to be fully duplicated.\
<br>\
<br>))

\
h3. Invocation of \`Proc\`

\
Next, we’ll look at the invocation of a created \`Proc\`.\
Since \`Proc\#call\` can be used from Ruby to invoke,\
we can follow the substance of it.

\
The substance of \`Proc\#call\` is \`proc\_call\`:

\
\<p class=“caption”\>▼ \`proc\_call\` \</p\>
\
\<pre class=“longlist”\>\
6570 static VALUE\
6571 proc\_call\
6572 VALUE proc, args; /\* OK **/\
6573 {\
6574 return proc\_invoke;\
6575 }
\
\
\</pre\>

\
Delegate to \`proc\_invoke\`. When I look up \`invoke\` in a
dictionary,\
it was written such as “call on (God, etc.) for help”,\
but when it is in the context of programming,\
it is often used in the almost same meaning as “activate”.

\
The prototype of the \`proc\_invoke\` is,


\
\<pre class=“emlist”\>\
proc\_invoke\
\</pre\>

\
However, according to the previous code, \`pcall=Qtrue\` and
\`self=Qundef\` in this case,\
so these two can be removed by constant foldings.

\
\<p class=“caption”\>▼ \`proc\_invoke\` \</p\>
\
\<pre class=“longlist”\>\
static VALUE\
proc\_invoke\
 VALUE proc, args;\
 VALUE self;\
{\
 struct BLOCK** volatile old\_block;\
 struct BLOCK*block;\
 struct BLOCK **data;\
 volatile VALUE result = Qnil;\
 int state;\
 volatile int orphan;\
 volatile int safe = ruby\_safe\_level;\
 volatile VALUE old\_wrapper = ruby\_wrapper;\
 struct RVarmap** volatile old\_dvars = ruby\_dyna\_vars;

/\*（A）take BLOCK from proc and assign it to data **/\
 Data\_Get\_Struct;\
 /\*（B）blk\_orphan**/\
 orphan = blk\_orphan(data);

ruby\_wrapper = data~~\>wrapper;\
 ruby\_dyna\_vars = data~~\>dyna\_vars;\
 /\*（C）push BLOCK from data \*/\
 old\_block = ruby\_block;\
 *block = **data;\
 ruby\_block = &\_block;
\
 /\*（D）transition to ITER\_CUR**/\
 PUSH\_ITER;\
 ruby\_frame-\>iter = ITER\_CUR;
\
 PUSH\_TAG;\
 state = EXEC\_TAG;\
 if {\
 proc\_set\_safe\_level;\
 /\*（E）invoke the block **/\
 result = rb\_yield\_0;\
 }\
 POP\_TAG;
\
 POP\_ITER;\
 if {\
 state &= TAG\_MASK; /** target specified jump **/\
 }\
 ruby\_block = old\_block;\
 ruby\_wrapper = old\_wrapper;\
 ruby\_dyna\_vars = old\_dvars;\
 ruby\_safe\_level = safe;
\
 switch {\
 case 0:\
 break;\
 case TAG\_BREAK:\
 result = prot\_tag-\>retval;\
 break;\
 case TAG\_RETURN:\
 if { /** orphan procedure **/\
 localjump\_error;\
 }\
 /** fall through \*/\
 default:\
 JUMP\_TAG;\
 }\
 return result;\
}\
\</pre\>


\
The crucial points are three: C, D, and E.

\
(C) At \`NODE\_ITER\` a \`BLOCK\` is created from the syntax tree and
pushed,\
but this time, a \`BLOCK\` is taken from \`Proc\` and pushed.

\
 It was \`ITER\_PRE\` before becoming \`ITER\_CUR\` at \`rb\_call0\`,\
but this time it goes directly into \`ITER\_CUR\`.

\
 If the case was an ordinary iterator,\
its method call exists before \`yeild\` occurs then going to
\`rb\_yield\_0\`,\
but this time \`rb\_yield*()\` is directly called and invokes the just
pushed block.

In other words, in the case of iterator, the procedures are separated
into three places,\
\`NODE\_ITER\` \~ \`rb\_call0()\` \~ \`NODE\_YIELD\`. But this time,
they are done all at once.

Finally, I’ll talk about the meaning of \`blk\_orphan()\`.\
As the name suggests, it is a function to determine the state of “the
method\
which created the \`Proc\` has finished”.\
For example, the \`SCOPE\` used by a \`BLOCK\` has already been popped,\
you can determine it has finished.

### Block and \`Proc\`

In the previous chapter, various things about arguments and parameters
of\
methods are discussed, but I have not described about block parameters
yet.\
Although it is brief, here I’ll perform the final part of that series.

<pre class="emlist">
def m(&block)\
end\

</pre>
This is a “block parameter”. The way to enable this is very simple.\
If \`m\` is an iterator,\
it is certain that a \`BLOCK\` was already pushed,\
turn it into a \`Proc\` and assign into (in this case) the local
variable \`block\`.\
How to turn a block into a \`Proc\` is just calling \`proc\_new()\`,
which was previously described.\
The reason why just calling is enough can be a little incomprehensible.\
However whichever \`Proc.new\` or \`m\`,\
the situation “a method is called and a \`BLOCK\` is pushed” is the
same.\
Therefore, from C level, anytime you can turn a block into a \`Proc\`\
by just calling \`proc\_new()\`.

And if \`m\` is not an iterator, all we have to do is simply assigning
\`nil\`.

Next, it is the side to pass a block.

<pre class="emlist">
m(&block)\

</pre>
This is a “block argument”. This is also simple,\
take a \`BLOCK\` from (a \`Proc\` object stored in) \`block\` and push
it.\
What differs from \`PUSH\_BLOCK()\` is only whether a \`BLOCK\` has
already been\
created in advance or not.

The function to do this procedure is \`block\_pass()\`.\
If you are curious about, check and confirm around it.\
However, it really does just only what was described here,\
it’s possible you’ll be disappointed…
