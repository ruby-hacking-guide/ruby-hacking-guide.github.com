* * * * *

layout: default\
title: Variables and constants\
—

Translated by Vincent ISAMBART

Chapter 6: Variables and constants
==================================

Outline of this chapter
-----------------------

### Ruby variables

In Ruby there are quite a lot of different types of variables and\
constants. Let’s line them up, starting from the largest scope.

-   Global variables
-   Constants
-   Class variables
-   Instance variables
-   Local variables

Instance variables were already explained in chapter 2 “Objects”. In\
this chapter we’ll talk about:

-   Global variables
-   Class variables
-   Constants

We will talk about local variables in the third part of the book.

### API for variables

The object of this chapter’s analysis is \`variable.c\`. Let’s first\
look at the available API.

<pre class="emlist">
VALUE rb\_iv\_get(VALUE obj, char **name)\
VALUE rb\_ivar\_get\
VALUE rb\_iv\_set\
VALUE rb\_ivar\_set\
\</pre\>
\
We’ve already spoken about those functions, but must mention them again\
as they are in \`variable.c\`. They are of course used for accessing
instance\
variables.
\
\<pre class=“emlist”\>\
VALUE rb\_cv\_get\
VALUE rb\_cvar\_get\
VALUE rb\_cv\_set\
VALUE rb\_cvar\_set\
\</pre\>
\
These functions are the API for accessing class variables. Class\
variables belong directly to classes so the functions take a class as\
parameter. There are in two groups, depending if their name starts\
with \`rb\_Xv\` or \`rb\_Xvar\`. The difference lies in the type of the\
variable “name”. The ones with a shorter name are generally easier to\
use because they take a \`char\*\`. The ones with a longer name are
more\
for internal use as they take a \`ID\`.
\
\<pre class=“emlist”\>\
VALUE rb\_const\_get\
VALUE rb\_const\_get\_at\
VALUE rb\_const\_set\
\</pre\>
\
These functions are for accessing constants. Constants also belong to\
classes so they take classes as parameter. \`rb\_const\_get\` follows\
the superclass chain, whereas \`rb\_const\_get\_at\` does not .
\
\<pre class=“emlist”\>\
struct global\_entry**rb\_global\_entry(ID name)\
VALUE rb\_gv\_get(char **name)\
VALUE rb\_gvar\_get\
VALUE rb\_gv\_set\
VALUE rb\_gvar\_set\
\</pre\>
\
These last functions are for accessing global variables. They are a\
little different from the others due to the use of \`struct\
global\_entry\`. We’ll explain this while describing the implementation.
\
h3. Important points
\
The most important topic of this chapter is “Where and how are
variables\
stored?”, in other words: data structures.
\
The second most important matter is how we search for the values. The
scopes\
of Ruby variables and constants are quite complicated because\
variables and constants are sometimes inherited, sometimes looked for\
outside of the local scope… To have a better understanding, you\
should first try to guess from the behavior how it could be\
implemented, then compare that with what is really done.
\
h2. Class variables
\
Class variables are variables that belong to classes. In Java or C++\
they are called static variables. They can be accessed from both the\
class or its instances. But “from an instance” or “from the class” is\
information only available in the evaluator, and we do not have one\
for the moment. So from the C level it’s like having no access\
range. We’ll just focus on the way these variables are stored.
\
h3. Reading
\
The functions to get a class variable are \`rb\_cvar\_get\` and\
\`rb\_cv\_get\`. The function with the longer name takes \`ID\` as\
parameter and the one with the shorter one takes \`char\*\`. Because
the\
one taking an \`ID\` seems closer to the internals, we’ll look at it.
\
▼ \`rb\_cvar\_get\`\
\<pre class=“longlist”\>\
1508 VALUE\
1509 rb\_cvar\_get\
1510 VALUE klass;\
1511 ID id;\
1512 {\
1513 VALUE value;\
1514 VALUE tmp;\
1515\
1516 tmp = klass;\
1517 while {\
1518 if ~~\>iv\_tbl) {\
1519 if ~~\>iv\_tbl,id,&value)) {\
1520 if ) {\
1521 cvar\_override\_check;\
1522 }\
1523 return value;\
1524 }\
1525 }\
1526 tmp = RCLASS (tmp)~~\>super;\
1527 }\
1528\
1529 rb\_name\_error, rb\_class2name);\
1531 return Qnil; /\* not reached \*/\
1532 }
\
\
\</pre\>
\
This function reads a class variable in \`klass\`.
\
Error management functions like \`rb\_raise\` can be simply ignored\
like I said before. The \`rb\_name\_error\` that appears this time is a\
function for raising an exception, so it can be ignored for the same\
reasons. In \`ruby\`, you can assume that all functions ending with\
\`\_error\` raise an exception.
\
After removing all this, we can see that while following the
\`klass\`’s\
superclass chain we only search in \`iv\_tbl\`. At this point you
should\
say “What? \`iv\_tbl\` is the instance variables table, isn’t it?” As a\
matter of fact, class variables are stored in the instance variable\
table.
\
We can do this because when creating \`ID\`s, the whole name of the\
variables is taken into account, including the prefix: \`rb\_intern\`\
will return different \`ID\`s for “\`@var\`” and
“\``` @var`". At the Ruby
level, the variable type is determined only by the prefix so there's
no way to access a class variable called ` ``var\` from Ruby.
\
h2. Constants
\
It’s a little abrupt but I’d like you to remember the members of\
\`struct RClass\`. If we exclude the \`basic\` member, \`struct
RClass\`\
contains:
\
\* \`VALUE super\`\
\* \`struct st\_table **iv\_tbl\`\
** \`struct st\_table **m\_tbl\`
\
Then, considering that:
\
\# constants belong to a class\
\# we can’t see any table dedicated to constants in \`struct RClass\`\
\# class variables and instance variables are both in \`iv\_tbl\`
\
Could it mean that the constants are also…
\
h3. Assignment
\
\`rb\_const\_set\` is a function to set the value of constants: it sets\
the constant \`id\` in the class \`klass\` to the value \`val\`.
\
▼ \`rb\_const\_set\`\
\<pre class="longlist"\>\
1377 void\
1378 rb\_const\_set\
1379 VALUE klass;\
1380 ID id;\
1381 VALUE val;\
1382 {\
1383 mod\_av\_set;\
1384 }
\
\
\</pre\>
\
\`mod\_av\_set\` does all the hard work:
\
▼ \`mod\_av\_set\`\
\<pre class="longlist"\>\
1352 static void\
1353 mod\_av\_set\
1354 VALUE klass;\
1355 ID id;\
1356 VALUE val;\
1357 int isconst;\
1358 {\
1359 char**dest = isconst ?”constant" : “class variable”;\
1360\
1361 if && rb\_safe\_level \>= 4)\
1362 rb\_raise;\
1363 if ) rb\_error\_frozen;\
1364 if ~~\>iv\_tbl) {\
1365 RCLASS (klass)~~\>iv\_tbl = st\_init\_numtable;\
1366 }\
1367 else if {\
1368 if ~~\>iv\_tbl, id, 0) ||\
1369 )) {\
1370 rb\_warn);\
1371 }\
1372 }\
1373\
1374 st\_insert~~\>iv\_tbl, id, val);\
1375 }
\
\
\</pre\>
\
You can this time again ignore the warning checks \`,\
\`rb\_error\_frozen\` and \`rb\_warn\`). Here’s what’s left:
\
▼ \`mod\_av\_set\` \
\<pre class=“longlist”\>\
 if ~~\>iv\_tbl) {\
 RCLASS (klass)~~\>iv\_tbl = st\_init\_numtable;\
 }\
 st\_insert~~\>iv\_tbl, id, val);\
\</pre\>
\
We’re now sure constants also reside in the instance table. It means\
in the \`iv\_tbl\` of \`struct RClass\`, the following are mixed
together:
\
\# the class’s own instance variables\
\# class variables\
\# constants
\
h3. Reading
\
We now know how the constants are stored. We’ll now check how they\
really work.
\
h4. \`rb\_const\_get\`
\
We’ll now look at \`rconst\_get\`, the function to read a\
constant. This functions returns the constant referred to by \`id\` from
the class\
\`klass\`.
\
▼ \`rb\_const\_get\`\
\<pre class=“longlist”\>\
1156 VALUE\
1157 rb\_const\_get\
1158 VALUE klass;\
1159 ID id;\
1160 {\
1161 VALUE value, tmp;\
1162 int mod\_retry = 0;\
1163\
1164 tmp = klass;\
1165 retry:\
1166 while {\
1167 if ~~\>iv\_tbl &&\
 st\_lookup~~\>iv\_tbl,id,&value)) {\
1168 return value;\
1169 }\
1170 if )\
 return value;\
1171 tmp = RCLASS (tmp)~~\>super;\
1172 }\
1173 if  T\_MODULE) {
1174          mod\_retry = 1;
1175          tmp = rb\_cObject;
1176          goto retry;
1177      }
1178
1179      /\* Uninitialized constant \*/
1180      if (klass && klass != rb\_cObject) {
1181          rb\_name\_error(id, "uninitialized constant %s at %s",
1182                        rb\_id2name(id),
1183                        RSTRING(rb\_class\_path(klass))-\>ptr);
1184      }
1185      else { /\* global\_uninitialized \*/
1186          rb\_name\_error(id, "uninitialized constant %s",rb\_id2name(id));
1187      }
1188      return Qnil;                /\* not reached \*/
1189  }

(variable.c)
\</pre\>

There's a lot of code in the way. First, we should at least remove the
\`rb\_name\_error()\` in the second half. In the middle, what's around
\`mod\_entry\` seems to be a special handling for modules. Let's also
remove that for the time being. The function gets reduced to this:

▼ \`rb\_const\_get\` (simplified)
\<pre class="longlist"\>
VALUE
rb\_const\_get(klass, id)
    VALUE klass;
    ID id;
{
    VALUE value, tmp;

    tmp = klass;
    while (tmp) {
        if (RCLASS(tmp)-\>iv\_tbl && st\_lookup(RCLASS(tmp)-\>iv\_tbl,id,&value)) {
            return value;
        }
        if (tmp  rb\_cObject && top\_const\_get) return value;\
 tmp = RCLASS (tmp)~~\>super;\
 }\
}\
\</pre\>
\
Now it should be pretty easy to understand. The function searches for
the\
constant in \`iv\_tbl\` while climbing \`klass\`’s superclass chain.
That\
means:
\
\<pre class=“emlist”\>\
class A\
 Const = “ok”\
end\
class B \< A\
 p \# can be accessed\
end\
\</pre\>
\
The only problem remaining is \`top\_const\_get\`. This function is
only\
called for \`rb\_cObject\` so \`top\` must mean “top-level”. If you
don’t\
remember, at the top-level, the class is \`Object\`. This means the
same\
as “in the class statement defining \`C\`, the class becomes \`C\`”,\
meaning that “the top-level’s class is \`Object\`”.
\
\<pre class=“emlist”\>\
\# the class of the top-level is Object\
class A\
 \# the class is A\
 class B\
 \# the class is B\
 end\
end\
\</pre\>
\
So \`top\_const\_get\` probably does something specific to the top\
level.
\
h4. \`top\_const\_get\`
\
Let’s look at this \`top\_const\_get\` function. It looks up the \`id\`\
constant writes the value in \`klassp\` and returns.
\
▼ \`top\_const\_get\`\
\<pre class=“longlist”\>\
1102 static int\
1103 top\_const\_get\
1104 ID id;\
1105 VALUE **klassp;\
1106 {\
1107 /** pre-defined class **/\
1108 if ) return Qtrue;\
1109\
1110 /** autoload **/\
1111 if ) {\
1112 rb\_autoload\_load;\
1113**klassp = rb\_const\_get;\
1114 return Qtrue;\
1115 }\
1116 return Qfalse;\
1117 }
\
\
\</pre\>
\
\`rb\_class\_tbl\` was already mentioned in chapter 4 “Classes and\
modules”. It’s the table for storing the classes defined at the\
top-level. Built-in classes like \`String\` or \`Array\` have for
example\
an entry in it. That’s why we should not forget to search in this\
table when looking for top-level constants.
\
The next block is related to autoloading. This allows us to
automatically\
load a library when accessing a top-level constant for the first\
time. This can be used like this:
\
\<pre class=“emlist”\>\
autoload \# VeryBigClass is defined in it\
\</pre\>
\
After this, when \`VeryBigClass\` is accessed for the first time, the\
\`verybigclass\` library is loaded . As long as\
\`VeryBigClass\` is defined in the library, execution can continue
smoothly. It’s\
an efficient approach, when a library is too big and a lot of time is
spent on loading.
\
This autoload is processed by \`rb\_autoload\_xxxx\`. We won’t discuss\
autoload further in this chapter because there will probably be a big\
change in how it works soon .
\
h4. Other classes?
\
But where did the code for looking up constants in other classes end
up?\
After all, constants are first looked up in the outside classes, then\
in the superclasses.
\
In fact, we do not yet have enough knowledge to look at that. The\
outside classes change depending on the location in the program. In\
other words it depends of the program context. So we need first to\
understand how the internal state of the\
evaluator is handled. Specifically, this search in other classes is done
in the\
\`ev\_const\_get\` function of \`eval.c\`. We’ll look at it and finish\
with the constants in the third part of the book.
\
h2. Global variables
\
h3. General remarks
\
Global variables can be accessed from anywhere. Or put the other way\
around, there is no need to restrict access to them. Because they are\
not attached to any context, the table only has to be at one place, and\
there’s no need to do any check. Therefore implementation is very\
simple.
\
But there is still quite a lot of code. The reason for this is that
global\
variables are quite different from normal variables. Functions like\
the following are only available for global variables:
\
\* you can “hook” access of global variables\
\* you can alias them with \`alias\`
\
Let’s explain this simply.
\
h4. Aliases of variables
\
\<pre class=“emlist”\>\
alias \$newname \$oldname\
\</pre\>
\
After this, you can use \`\$newname\` instead of \`\$oldname\`.
\`alias\` for\
variables is mainly a counter-measure for “symbol variables”. “symbol\
variables” are variables inherited from Perl like \`\$=\` or \`\$0\`.
\`\$=\`\
decides if during string comparison upper and lower case letters\
should be differentiated. \`\$0\` shows the name of the main Ruby\
program. There are some other symbol variables but anyway as their\
name is only one character long, they are difficult to remember for\
people who don’t know Perl. So, aliases were created to make them a
little\
easier to understand.
\
That said, currently symbol variables are not recommended, and are\
moved one by one in singleton methods of suitable modules. The current\
school of thought is that \`\$=\` and others will be abolished in 2.0.
\
h4. Hooks
\
You can “hook” read and write of global variables.
\
Hooks can be also be set at the Ruby level, but I was thinking: why not\
instead look at C level special variables for system use like\
\`\$KCODE\`? \`\$KCODE\` is the variable containing the encoding the\
interpreter currently uses to handle strings. It can only be set to\
special values like \`“EUC”\` or \`“UTF8”\`. But this is too bothersome
so\
it can also be set it to \`“e”\` or \`“u”\`.
\
\<pre class=“emlist”\>\
p \# “NONE” \
\$KCODE = “e”\
p \# “EUC”\
\$KCODE = “u”\
p \# “UTF8”\
\</pre\>
\
Knowing that you can hook assignment of global variables, you should\
understand easily how this can be done. By the way, \`\$KCODE\`’s K
comes\
from “kanji” .
\
You might say that even with \`alias\` or hooks,\
global variables just aren’t used much, so it’s functionality that
doesn’t\
really mater. It’s adequate not to talk much about unused\
functions, and I need some pages for the analysis of the parser and\
evaluator. That’s why I’ll proceed with the explanation below throwing\
away what’s not really important.
\
h3. Data structure
\
When we were looking at how variables work, I said that the way they\
are stored is important. That’s why I’d like you to firmly grasp the\
structure used by global variables.
\
▼ Data structure for global variables\
\<pre class=“longlist”\>\
 21 static st\_table **rb\_global\_tbl;
\
 334 struct global\_entry {\
 335 struct global\_variable**var;\
 336 ID id;\
 337 };
\
 324 struct global\_variable {\
 325 int counter; /\* reference counter **/\
 326 void**data; /\* value of the variable **/\
 327 VALUE ; /** function to get the variable **/\
 328 void ; /** function to set the variable **/\
 329 void ; /** function to mark the variable **/\
 330 int block\_trace;\
 331 struct trace\_var**trace;\
 332 };
\
\
\</pre\>
\
\`rb\_global\_tbl\` is the main table. All global variables are stored
in\
this table. The keys of this table are of course variable names\
. A value is expressed by a \`struct global\_entry\` and a \`struct\
global\_variable\` .
\
![Global variables table at execution time](images/ch_variable_gvar.png "Global variables table at execution time")
\
The structure representing the variables is split in two to be able to\
create \`alias\`es. When an \`alias\` is established, two
\`global\_entry\`s\
point to the same \`struct global\_variable\`.
\
It’s at this time that the reference counter is necessary. I explained
the general idea of\
a reference counter in the previous section “Garbage\
collection”. Reviewing it briefly, when a new reference to the\
structure is made, the counter in incremented by 1. When the reference\
is not used anymore, the counter is decreased by 1. When the counter\
reaches 0, the structure is no longer useful so \`free\` can be\
called.
\
When hooks are set at the Ruby level, a list of \`struct trace\_var\`s
is\
stored in the \`trace\` member of \`struct global\_variable\`, but I
won’t\
talk about it, and omit \`struct trace\_var\`.
\
h3. Reading
\
You can have a general understanding of global variables just by looking
at how\
they are read. The functions for reading them are \`rb\_gv\_get\` and\
\`rb\_gvar\_get\`.
\
▼ \`rb\_gv\_get rb\_gvar\_get\`\
\<pre class=“longlist”\>\
 716 VALUE\
 717 rb\_gv\_get\
 718 const char **name;\
 719 {\
 720 struct global\_entry**entry;\
 721\
 722 entry = rb\_global\_entry);\
 723 return rb\_gvar\_get;\
 724 }
\
 649 VALUE\
 650 rb\_gvar\_get\
 651 struct global\_entry **entry;\
 652 {\
 653 struct global\_variable**var = entry~~\>var;\
 654 return ;\
 655 }
\
\
\</pre\>
\
A substantial part of the content seems to turn around the\
\`rb\_global\_entry\` function, but that does not prevent us\
understanding what’s going on. \`global\_id\` is a function that
converts a\
\`char\*\` to \`ID\` and checks if it’s the \`ID\` of a global\
variable. \`\` is of course a function call using the\
function pointer \`var~~\>getter\`. If \`p\` is a function pointer,\
\`\` calls the function.
\
But the main part is still \`rb\_global\_entry\`.
\
▼ \`rb\_global\_entry\`\
\<pre class=“longlist”\>\
 351 struct global\_entry\*\
 352 rb\_global\_entry\
 353 ID id;\
 354 {\
 355 struct global\_entry **entry;\
 356\
 357 if ) {\
 358 struct global\_variable**var;\
 359 entry = ALLOC (struct global\_entry);\
 360 st\_add\_direct;\
 361 var = ALLOC (struct global\_variable);\
 362 entry~~\>id = id;\
 363 entry~~\>var = var;\
 364 var~~\>counter = 1;\
 365 var~~\>data = 0;\
 366 var~~\>getter = undef\_getter;\
 367 var~~\>setter = undef\_setter;\
 368 var~~\>marker = undef\_marker;\
 369\
 370 var~~\>block\_trace = 0;\
 371 var~~\>trace = 0;\
 372 }\
 373 return entry;\
 374 }
\
\
\</pre\>
\
The main treatment is only done by the \`st\_lookup\` at the beginning.\
What’s done afterwards is just creating a new entry. As, when\
accessing a non existing global variable, an entry is automatically\
created, \`rb\_global\_entry\` will never return NULL.
\
This was mainly done for speed. When the parser finds a global\
variable, it gets the corresponding \`struct global\_entry\`. When\
reading the value of the variable, the parser just has to get the\
value from the entry \`), and has no need to do any\
check.
\
Let’s now continue a little with the code that follows.
\`var~~\>getter\`\
and others are set to \`undef\_xxxx\`. \`undef\` means that the global\
\`setter/getter/marker\` for the variable are currently undefined.
\
\`undef\_getter\` just shows a warning and returns \`nil\`, as even\
undefined global variables can be read. \`undef\_setter\` is quite\
interesting so let’s look at it.
\
▼ \`undef\_setter\`\
\<pre class=“longlist”\>\
 385 static void\
 386 undef\_setter\
 387 VALUE val;\
 388 ID id;\
 389 void**data;\
 390 struct global\_variable \*var;\
 391 {\
 392 var~~\>getter = val\_getter;\
 393 var~~\>setter = val\_setter;\
 394 var~~\>marker = val\_marker;\
 395\
 396 var~~\>data = (void\*)val;\
 397 }

(variable.c)\

</pre>
\`val\_getter()\` takes the value from \`entry~~\>data\` and returns\
it. \`val\_getter\` just puts a value in \`entry~~\>data\`. Setting\
handlers this way allows us not to need special handling for undefined\
variables (figure 2). Skillfully done, isn’t it?

![Setting and consultation of global variables](images/ch_variable_gaccess.png "Setting and consultation of global variables")
