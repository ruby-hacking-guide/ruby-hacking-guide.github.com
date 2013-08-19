* * * * *

layout: default\
title: Security\
—\
Translated by Clifford Escobar CAOILE & ocha-

Chapter 7: Security
===================

### Fundamentals

I say security but I don’t mean passwords or encryption. The Ruby
security\
feature is used for handling untrusted objects in a environment like
CGI\
programming.

For example, when you want to convert a string representing a number
into a\
integer, you can use the \`eval\` method. However. \`eval\` is a method
that “runs\
a string as a Ruby program.” If you \`eval\` a string from a unknown
person from\
the network, it is very dangerous. However for the programmer to fully\
differentiate between safe and unsafe things is very tiresome and
cumbersome.\
Therefore, it is for certain that a mistake will be made. So, let us
make it\
part of the language, was reasoning for this feature.

So then, how Ruby protect us from that sort of danger? Causes of
dangerous\
operations, for example, opening unintended files, are roughly divided
into two\
groups:

-   Dangerous data
-   Dangerous code

For the former, the code that handles these values is created by the\
programmers themselves, so therefore it is (relatively) safe. For the
latter,\
the program code absolutely cannot be trusted.

Because the solution is vastly different between the two causes, it is
important to\
differentiate them by level. This are called security levels. The Ruby
security\
level is represented by the \`\$SAFE\` global variable. The value ranges
from\
minimum value 0 to maximum value 4. When the variable is assigned, the
level\
increases. Once the level is raised it can never be lowered. And for
each\
level, the operations are limited.

I will not explain level 1 or 3.\
Level 0 is the normal program environment and the security system is
not\
running. Level 2 handles dangerous values. Level 4 handles dangerous
code.\
We can skip 0 and move on to explain in detail levels 2 and 4.

((errata: Level 1 handles dangerous values.\
“Level 2 has no use currently” is right.))

#### Level 1

This level is for dangerous data, for example, in normal CGI\
applications, etc.

A per-object “tainted mark” serves as the basis for the Level 1\
implementation. All objects read in externally are marked tainted, and\
any attempt to \`eval\` or \`File.open\` with a tainted object will
cause an\
exception to be raised and the attempt will be stopped.

This tainted mark is “infectious”. For example, when taking a part of a\
tainted string, that part is also tainted.

#### Level 4

This level is for dangerous programs, for example, running external\
(unknown) programs, etc.

At level 1, operations and the data it uses are checked, but at level\
4, operations themselves are restricted. For example, \`exit\`, file\
I/O, thread manipulation, redefining methods, etc. Of course, the\
tainted mark information is used, but basically the operations are the\
criteria.

#### Unit of Security

\`\$SAFE\` looks like a global variable but is in actuality a thread\
local variable. In other words, Ruby’s security system works on units\
of thread. In Java and .NET, rights can be set per component (object),\
but Ruby does not implement that. The assumed main target was probably\
CGI.

Therefore, if one wants to raise the security level of one part of the\
program, then it should be made into a different thread and have its\
security level raised. I haven’t yet explained how to create a thread,\
but I will show an example here:

<pre class="emlist">
1.  Raise the security level in a different thread\
    p(\$SAFE) \# 0 is the default\
    Thread.fork { \# Start a different thread\
     \$SAFE = 4 \# Raise the level\
     eval(str) \# Run the dangerous program\
    }\
    p(\$SAFE) \# Outside of the block, the level is still 0\
    \</pre\>

#### Reliability of \`\$SAFE\`

Even with implementing the spreading of tainted marks, or restricting\
operations, ultimately it is still handled manually. In other words,\
internal libraries and external libraries must be completely\
compatible and if they don’t, then the partway the “tainted” operations\
will not spread and the security will be lost. And actually this kind\
of hole is often reported. For this reason, this writer does not\
wholly trust it.

That is not to say, of course, that all Ruby programs are dangerous.\
Even at \`\$SAFE=0\` it is possible to write a secure program, and even\
at \`\$SAFE=4\` it is possible to write a program that fits your whim.\
However, one cannot put too much confidence on \`\$SAFE\` (yet).

In the first place, functionality and security do not go together. It\
is common sense that adding new features can make holes easier to\
open. Therefore it is prudent to think that \`ruby\` can probably be\
dangerous.

### Implementation

From now on, we’ll start to look into its implementation.\
In order to wholly grasp the security system of \`ruby\`,\
we have to look at “where is being checked” rather than its mechanism.\
However, this time we don’t have enough pages to do it,\
and just listing them up is not interesting.\
Therefore, in this chapter, I’ll only describe about the\
mechanism used for security checks.\
The APIs to check are mainly these below two:

-   \`rb\_secure(n)\` : If more than or equal to level n, it would raise
    \`SecurityError\`.
-   \`SafeStringValue()\` :\
     If more than or equal to level 1 and a string is tainted,\
     then it would raise an exception.

We won’t read \`SafeStringValue()\` here.

#### Tainted Mark

The taint mark is, to be concrete, the \`FL\_TAINT\` flag, which is set
to\
\`basic~~\>flags\`, and what is used to infect it is the \`OBJ\_INFECT\`
macro.\
Here is its usage.

\
\<pre class=“emlist”\>\
OBJ\_TAINT /\* set FL\_TAINT to obj **/\
OBJ\_TAINTED /** check if FL\_TAINT is set to obj **/\
OBJ\_INFECT /** infect FL\_TAINT from src to dest \*/\
\</pre\>

\
Since \`OBJ\_TAINT\` and \`OBJ\_TAINTED\` can be assumed not important,\
let’s briefly look over only \`OBJ\_INFECT\`.

\
\<p class=“caption”\>▼ \`OBJ\_INFECT\` \</p\>\
\<pre class=“longlist”\>\
 441 \#define OBJ\_INFECT do { \
 if && FL\_ABLE) \
 RBASIC (x)~~\>flags |= RBASIC (s)~~\>flags & FL\_TAINT; \
 } while
\
\
\</pre\>

\
\`FL\_ABLE\` checks if the argument \`VALUE\` is a pointer or not.\
If the both objects are pointers ,\
it would propagate the flag.



\
h4. \$SAFE

\
\<p class=“caption”\>▼ \`ruby\_safe\_level\` \</p\>\
\<pre class=“longlist”\>\
 124 int ruby\_safe\_level = 0;
\
7401 static void\
7402 safe\_setter\
7403 VALUE val;\
7404 {\
7405 int level = NUM2INT;\
7406\
7407 if {\
7408 rb\_raise;\
7410 }\
7411 ruby\_safe\_level = level;\
7412 curr\_thread~~\>safe = level;\
7413 }

(eval.c)\

</pre>
The substance of \`\$SAFE\` is \`ruby\_safe\_level\` in \`eval.c\`.\
As I previously wrote, \`\$SAFE\` is local to each thread,\
It needs to be written in \`eval.c\` where the implementation of threads
is located.\
In other words, it is in \`eval.c\` only because of the restrictions of
C,\
but it can essentially be located in another place.

\`safe\_setter()\` is the \`setter\` of the \`\$SAFE\` global variable.\
It means, because this function is the only way to access it from Ruby
level,\
the security level cannot be lowered.

However, as you can see, from C level,\
because \`static\` is not attached to \`ruby\_safe\_level\`,\
you can ignore the interface and modify the security level.

#### \`rb\_secure()\`

<p class="caption">
▼ \`rb\_secure()\`

</p>
<pre class="longlist">
136 void\
 137 rb\_secure(level)\
 138 int level;\
 139 {\
 140 if (level \<= ruby\_safe\_level) {\
 141 rb\_raise(rb\_eSecurityError, “Insecure operation \`%s’ at level
%d”,\
 142 rb\_id2name(ruby\_frame-\>last\_func), ruby\_safe\_level);\
 143 }\
 144 }

(eval.c)\

</pre>
If the current safe level is more than or equal to \`level\`,\
this would raise \`SecurityError\`. It’s simple.
