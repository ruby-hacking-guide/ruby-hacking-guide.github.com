---
layout: default
title: Ruby Language Details
---
h1(#chapter). Chapter 8 : Ruby Language Details

I'll talk about the details of Ruby's syntax and evaluation,
which haven't been covered yet. I didn't intend a complete exposition,
so I left out everything which doesn't come up in this book.
That's why you won't be able to write Ruby programs just by
reading this. A complete exposition can be found in the
\footnote{Ruby reference manual: `archives/ruby-refm.tar.gz` in the attached CD-ROM}

Readers who know Ruby can skip over this chapter.

h2. Literals

The expressiveness of Ruby's literals is extremely high.
In my opinion, what makes Ruby a script language
is firstly the existence of
the toplevel, secondly it's the expressiveness of its literals.
Thirdly it might be the richness of its standard library.

A single literal already has enormous power, but even more
when multiple literals are combined.
Especially the ability of creating complex literals that hash and array literals
are combined is the biggest advantage of Ruby's literal.
One can write, for instance, a hash of arrays of regular expressions
by constructing straightforwardly.

What kind of expressions are valid?
Let's look at them one by one.

h3. Strings

Strings and regular expressions can't be missing in a scripting language.
The expressiveness of Ruby's string is very various even more than the
other Ruby's literals.

h4. Single Quoted Strings

<pre class="emlist">
'string'              # 「string」
'\\begin{document}'   # 「\begin{document}」
'\n'                  # 「\n」backslash and an n, not a newline
'\1'                  # 「\1」backslash and 1
'\''                  # 「'」
</pre>

This is the simplest form.
In C, what enclosed in single quotes becomes a character,
but in Ruby, it becomes a string.
Let's call this a `'`-string. The backslash escape
is in effect only for `\` itself and `'`. If one puts a backslash
in front of another character the backslash remains as
in the fourth example.

And Ruby's strings aren't divided by newline characters.
If we write a string over several lines the newlines are contained
in the string.

<pre class="emlist">
'multi
    line
        string'
</pre>

And if the `-K` option is given to the `ruby` command, multibyte strings
will be accepted. At present the three encodings EUC-JP (`-Ke`),
Shift JIS (`-Ks`), and UTF8 (`-Ku`) can be specified.

<pre class="emlist">
'「漢字が通る」と「マルチバイト文字が通る」はちょっと違う'
# 'There's a little difference between "Kanji are accepted" and "Multibyte characters are accepted".'
</pre>

h4. Double Quoted Strings

<pre class="emlist">
"string"              # 「string」
"\n"                  # newline
"\x0f"               # a byte given in hexadecimal form
"page#{n}.html"       # embedding a command
</pre>

With double quotes we can use command expansion and backslash notation.
The backslash notation is something classical that is also supported in C,
for instance, `\n` is a newline, `\b` is a backspace.
In Ruby, `Ctrl-C` and ESC can also be expressed, that's convenient.
However, merely listing the whole notation is not fun,
regarding its implementation, it just means a large number of cases to be
handled and there's nothing especially interesting.
Therefore, they are entirely left out here.

On the other hand, expression expansion is even more fantastic.
We can write an arbitrary Ruby expression inside `#{ }` and it
will be evaluated at runtime and embedded into the string. There
are no limitations like only one variable or only one method.
Getting this far, it is not a mere literal anymore but
the entire thing can be considered as an expression to express a string.

<pre class="emlist">
"embedded #{lvar} expression"
"embedded #{@ivar} expression"
"embedded #{1 + 1} expression"
"embedded #{method_call(arg)} expression"
"embedded #{"string in string"} expression"
</pre>

h4. Strings with `%`

<pre class="emlist">
%q(string)            # same as 'string'
%Q(string)            # same as "string"
%(string)             # same as %Q(string) or "string"
</pre>

If a lot of separator characters appear in a string, escaping all of them
becomes a burden. In that case the separator characters can be
changed by using `%`.
In the following example, the same string is written as a `"`-string and
`%`-string.

<pre class="emlist">
"<a href=\"http://i.loveruby.net#{path}\">"
%Q(<a href="http://i.loveruby.net#{path}">)
</pre>

The both expressions has the same length,
but the `%`-one is a lot nicer to look at.
When we have more characters to escape in it,
`%`-string would also have advantage in length.

Here we have used parentheses as delimiters, but something else is fine,
too. Like brackets or braces or `#`. Almost every symbol is fine, even
`%`.

<pre class="emlist">
%q#this is string#
%q[this is string]
%q%this is string%
</pre>

h4. Here Documents

Here document is a syntax which can express strings spanning multiple lines.
A normal string starts right after the delimiter `"`
and everything until the ending `"` would be the content.
When using here document,
the lines between the line which contains the starting `<<EOS` and
the line which contains the ending `EOS` would be the content.

<pre class="emlist">
"the characters between the starting symbol and the ending symbol
will become a string."

<<EOS
All lines between the starting and
the ending line are in this
here document
EOS
</pre>

Here we used `EOS` as identifier but any word is fine.
Precisely speaking, all the character matching `[a-zA-Z_0-9]` and multi-byte
characters can be used.

The characteristic of here document is that the delimiters are
"the lines containing the starting identifier or the ending identifier".
The line which contains the start symbol is the starting delimiter.
Therefore, the position of the start identifier in the line is not important.
Taking advantage of this, it doesn't matter that,
for instance, it is written in the middle of an expression:

<pre class="emlist">
printf(<<EOS, count_n(str))
count=%d
EOS
</pre>

In this case the string `"count=%d\n"` goes in the place of `<<EOS`.
So it's the same as the following.

<pre class="emlist">
printf("count=%d\n", count_n(str))
</pre>

The position of the starting identifier is really not restricted,
but on the contrary, there are strict
rules for the ending symbol: It must be at the beginning of the line
and there must not be another letter in that line. However
if we write the start symbol with a minus like this `<<-EOS` we
can indent the line with the end symbol.

<pre class="emlist">
     <<-EOS
It would be convenient if one could indent the content
of a here document. But that's not possible.
If you want that, writing a method to delete indents is
usually a way to go. But beware of tabs.
     EOS
</pre>

Furthermore, the start symbol can be enclosed in single or double quotes.
Then the properties of the whole here document change.
When we change `<<EOS` to `<<"EOS"` we can use embedded expressions
and backslash notation.

<pre class="emlist">
    <<"EOS"
One day is #{24 * 60 * 60} seconds.
Incredible.
EOS
</pre>

But `<<'EOS'` is not the same as a single quoted string. It starts
the complete literal mode. Everything even backslashes go
into the string as they are typed. This is useful for a string which
contains many backslashes.

In Part 2, I'll explain how to parse a here document.
But I'd like you to try to guess it before.

h3. Characters

Ruby strings are byte sequences, there are no character objects.
Instead there are the following expressions which return the
integers which correspond a certain character in ASCII code.

<pre class="emlist">
?a                    # the integer which corresponds to "a"
?.                    # the integer which corresponds to "."
?\n                   # LF
?\C-a                 # Ctrl-a
</pre>

h3. Regular Expressions

<pre class="emlist">
/regexp/
/^Content-Length:/i
/正規表現/
/\/\*.*?\*\//m        # An expression which matches C comments
/reg#{1 + 1}exp/      # the same as /reg2exp/
</pre>

What is contained between slashes is a regular expression.
Regular expressions are a language to designate string patterns.
For example

<pre class="emlist">
/abc/
</pre>

This regular expression matches a string where there's an `a` followed
by a `b` followed by a `c`. It matches "abc" or "fffffffabc" or
"abcxxxxx".

One can designate more special patterns.

<pre class="emlist">
/^From:/
</pre>

This matches a string where there's a `From` followed by a `:` at
the beginning of a line. There are several more expressions of this kind,
such that one can create quite complex patterns.

The uses are infinite:
Changing the matched part to another string, deleting the matched part,
determining if there's one match and so on...

A more concrete use case would be, for instance, extracting the `From:` header
from a mail, or changing the `\n` to an `\r`,
or checking if a string looks like a mail address.

Since the regular expression itself is an independent language, it has
its own parser and evaluator which are different from `ruby`.
They can be found in `regex.c`.
Hence, it's enough for `ruby` to be able to cut out the regular expression part
from a Ruby program and feed it. As a consequence, they are treated almost the
same as strings from the grammatical point of view.
Almost all of the features which strings have like escapes, backslash notations
and embedded expressions can be used in the same way in regular expressions.

However, we can say they are treated as the same as strings only when we are in
the viewpoint of "Ruby's syntax". As mentioned before, since regular expression
itself is a language, naturally we have to follow its language constraints.
To describe regular expression in detail, it's so large that one more can be
written, so I'd like you to read another book for this subject.
I recommend "Mastering Regular Expression" by Jeffrey E.F. Friedl.

h4. Regular Expressions with `%`

Also as with strings, regular expressions also have a syntax for changing
delimiters. In this case it is `%r`. To understand this, looking at some
examples are enough to understand.

<pre class="emlist">
%r(regexp)
%r[/\*.*?\*/]            # matches a C comment
%r("(?:[^"\\]+|\\.)*")   # matches a string in C
%r{reg#{1 + 1}exp}       # embedding a Ruby expression
</pre>

h3. Arrays

A comma-separated list enclosed in brackets `[]` is an array literal.

<pre class="emlist">
[1, 2, 3]
['This', 'is', 'an', 'array', 'of', 'string']

[/regexp/, {'hash'=>3}, 4, 'string', ?\C-a]

lvar = $gvar = @ivar = @@cvar = nil
[lvar, $gvar, @ivar, @@cvar]
[Object.new(), Object.new(), Object.new()]
</pre>

Ruby's array (`Array`) is a list of arbitrary objects. From a syntactical
standpoint, it's characteristic is that arbitrary expressions can be elements.
As mentioned earlier,
an array of hashes of regular expressions can easily be made.
Not just literals but also expressions which variables or method calls combined
together can also be written straightforwardly.

Note that this is "an expression which generates an array object" as with the
other literals.

<pre class="emlist">
i = 0
while i < 5
  p([1,2,3].id)    # Each time another object id is shown.
  i += 1
end
</pre>

h4. Word Arrays

When writing scripts one uses arrays of strings a lot, hence
there is a special notation only for arrays of strings.
That is `%w`. With an example it's immediately obvious.

<pre class="emlist">
%w( alpha beta gamma delta )   # ['alpha','beta','gamma','delta']
%w( 月 火 水 木 金 土 日 )
%w( Jan Feb Mar Apr May Jun
    Jul Aug Sep Oct Nov Dec )
</pre>

There's also `%W` where expressions can be embedded.
It's a feature implemented fairly recently.

<pre class="emlist">
n = 5
%w( list0 list#{n} )   # ['list0', 'list#{n}']
%W( list0 list#{n} )   # ['list0', 'list5']
</pre>

The author hasn't come up with a good use of `%W` yet.

h3. Hashes

Hash tables are data structure which store a one-to-one relation between
arbitrary objects.
By writing as follows, they will be expressions to generate tables.

<pre class="emlist">
{ 'key' => 'value', 'key2' => 'value2' }
{ 3 => 0, 'string' => 5, ['array'] => 9 }
{ Object.new() => 3, Object.new() => 'string' }

# Of course we can put it in several lines.
{ 0 => 0,
  1 => 3,
  2 => 6 }
</pre>

We explained hashes in detail in the third chapter "Names and
Nametables". They are fast lookup tables which allocate memory slots depending
on the hash values. In Ruby grammar,
both keys and values can be arbitrary expressions.

Furthermore, when used as an argument of a method call,
the `{...}` can be omitted under a certain condition.


<pre class="emlist">
  some_method(arg, key => value, key2 => value2)
# some_method(arg, {key => value, key2 => value2}) # same as above
</pre>

With this we can imitate named (keyword) arguments.

<pre class="emlist">
button.set_geometry('x' => 80, 'y' => '240')
</pre>

Of course in this case `set_geometry` must accept a hash as input.
Though real keyword arguments will be transformed into parameter variables,
it's not the case for this because this is just a "imitation".

h3. Ranges

Range literals are oddballs which don't appear in most other languages.
Here are some expressions which generate Range objects.

<pre class="emlist">
0..5          # from 0 to 5 containing 5
0...5         # from 0 to 5 not containing 5
1+2 .. 9+0    # from 3 to 9 containing 9
'a'..'z'      # strings from 'a' to 'z' containing 'z'
</pre>

If there are two dots the last element is included. If there
are three dots it is not included. Not only integers but also floats
and strings can be made into ranges, even a range between arbitrary objects can
be created if you'd attempt.
However, this is a specification of `Range` class, which is the class of range
objects, (it means a library), this is not a matter of grammar.
From the parser's standpoint,
it just enables to concatenate arbitrary expressions with `..`.
If a range cannot be generated with the objects as the evaluated results,
it would be a runtime error.

By the way, because the precedence of `..` and `...` is quite low,
sometimes it is interpreted in a surprising way.

<pre class="emlist">
1..5.to_a()   # 1..(5.to_a())
</pre>

I think my personality is relatively bent for Ruby grammar,
but somehow I don't like only this specification.

h3. Symbols

In Part 1, we talked about symbols at length.
It's something corresponds one-to-one to an arbitrary string.
In Ruby symbols are expressed with a `:` in front.

<pre class="emlist">
:identifier
:abcde
</pre>

These examples are pretty normal.
Actually, besides them, all variable names and method names
can become symbols with a `:` in front. Like this:

<pre class="emlist">
:$gvar
:@ivar
:@@cvar
:CONST
</pre>

Moreover, though we haven't talked this yet,
`[]` or `attr=` can be used as method names,
so naturally they can also be used as symbols.

<pre class="emlist">
:[]
:attr=
</pre>

When one uses these symbols as values in an array, it'll look quite
complicated.

h3. Numerical Values

This is the least interesting.
One possible thing I can introduce here is that,
when writing a million,

<pre class="emlist">
1_000_000
</pre>

as written above, we can use underscore delimiters in the middle.
But even this isn't particularly interesting.
From here on in this book,
we'll completely forget about numerical values.

h2. Methods

Let's talk about the definition and calling of methods.

h3. Definition and Calls

<pre class="emlist">
def some_method( arg )
  ....
end

class C
  def some_method( arg )
    ....
  end
end
</pre>

Methods are defined with `def`. If they are defined at toplevel
they become function style methods, inside a class they become
methods of this class. To call a method which was defined in a class,
one usually has to create an instance with `new` as shown below.

<pre class="emlist">
C.new().some_method(0)
</pre>

h3. The Return Value of Methods

The return value of a method is,
if a `return` is executed in the middle, its value.
Otherwise, it's the value of the statement which was executed last.

<pre class="emlist">
def one()     # 1 is returned
  return 1
  999
end

def two()     # 2 is returned
  999
  2
end

def three()   # 3 is returned
  if true then
    3
  else
    999
  end
end
</pre>

If the method body is empty,
it would automatically be `nil`,
and an expression without a value cannot put at the end.
Hence every method has a return value.

h3. Optional Arguments

Optional arguments can also be defined. If the number of arguments
doesn't suffice, the parameters are automatically assigned to
default values.

<pre class="emlist">
def some_method( arg = 9 )  # default value is 9
  p arg
end

some_method(0)    # 0 is shown.
some_method()     # The default value 9 is shown.
</pre>

There can also be several optional arguments.
But in that case they must all come at the end of the argument list.
If elements in the middle of the list were optional,
how the correspondences of the arguments would be very unclear.

<pre class="emlist">
def right_decl( arg1, arg2, darg1 = nil, darg2 = nil )
  ....
end

# This is not possible
def wrong_decl( arg, default = nil, arg2 )  # A middle argument cannot be optional
  ....
end
</pre>

h3. Omitting argument parentheses

In fact, the parentheses of a method call can be omitted.

<pre class="emlist">
puts 'Hello, World!'   # puts("Hello, World")
obj = Object.new       # obj = Object.new()
</pre>

In Python we can get the method object by leaving out parentheses,
but there is no such thing in Ruby.

If you'd like to, you can omit more parentheses.

<pre class="emlist">
  puts(File.basename fname)
# puts(File.basename(fname)) same as the above
</pre>

If we like we can even leave out more

<pre class="emlist">
  puts File.basename fname
# puts(File.basename(fname))  same as the above
</pre>

However, recently this kind of "nested omissions" became a cause of warnings.
It's likely that this will not pass anymore in Ruby 2.0.

Actually even the parentheses of the parameters definition can also be omitted.

<pre class="emlist">
def some_method param1, param2, param3
end

def other_method    # without arguments ... we see this a lot
end
</pre>

Parentheses are often left out in method calls, but leaving out
parentheses in the definition is not very popular.
However if there are no arguments, the parentheses are frequently omitted.

h3. Arguments and Lists

Because Arguments form a list of objects,
there's nothing odd if we can do something converse: extracting a list (an
array) as arguments,
as the following example.

<pre class="emlist">
def delegate(a, b, c)
  p(a, b, c)
end

list = [1, 2, 3]
delegate(*list)   # identical to delegate(1, 2, 3)
</pre>

In this way we can distribute an array into arguments.
Let's call this device a `*`argument now. Here we used a local variable
for demonstration, but of course there is no limitation.
We can also directly put a literal or a method call instead.

<pre class="emlist">
m(*[1,2,3])    # We could have written the expanded form in the first place...
m(*mcall())
</pre>

The @*@ argument can be used together with ordinary arguments,
but the @*@ argument must come last.
Otherwise, the correspondences to parameter variables cannot be determined in a
single way.

In the definition on the other hand we can handle the arguments in
bulk when we put a `*` in front of the parameter variable.

<pre class="emlist">
def some_method( *args )
  p args
end

some_method()          # prints []
some_method(0)         # prints [0]
some_method(0, 1)      # prints [0,1]
</pre>

The surplus arguments are gathered in an array. Only one `*`parameter
can be declared. It must also come after the default arguments.

<pre class="emlist">
def some_method0( arg, *rest )
end
def some_method1( arg, darg = nil, *rest )
end
</pre>

If we combine list expansion and bulk reception together, the arguments
of one method can be passed as a whole to another method. This might
be the most practical use of the `*`parameter.

<pre class="emlist">
# a method which passes its arguments to other_method
def delegate(*args)
  other_method(*args)
end

def other_method(a, b, c)
  return a + b + c
end

delegate(0, 1, 2)      # same as other_method(0, 1, 2)
delegate(10, 20, 30)   # same as other_method(10, 20, 30)
</pre>

h3. Various Method Call Expressions

Being just a single feature as 'method call' does not mean its representation
is also single. Here is about so-called syntactic sugar.
In Ruby there is a ton of it,
and they are really attractive for a person who has a fetish for parsers.
For instance the examples below are all method calls.

<pre class="emlist">
1 + 2                   # 1.+(2)
a == b                  # a.==(b)
~/regexp/               # /regexp/.~
obj.attr = val          # obj.attr=(val)
obj[i]                  # obj.[](i)
obj[k] = v              # obj.[]=(k,v)
`cvs diff abstract.rd`  # Kernel.`('cvs diff abstract.rd')
</pre>

It's hard to believe until you get used to it, but `attr=`, `[]=`, `\``
are (indeed) all method names. They can appear as names in a method definition
and can also be used as symbols.

<pre class="emlist">
class C
  def []( index )
  end
  def +( another )
  end
end
p(:attr=)
p(:[]=)
p(:`)
</pre>

As there are people who don't like sweets, there are also many people who
dislike syntactic sugar. Maybe they feel unfair when the things which are
essentially the same appear in faked looks.
(Why's everyone so serious?)

Let's see some more details.

h4. Symbol Appendices

<pre class="emlist">
obj.name?
obj.name!
</pre>

First a small thing. It's just appending a `?` or a `!`. Call and Definition
do not differ, so it's not too painful. There are convention for what
to use these method names, but there is no enforcement on language level.
It's just a convention at human level.
This is probably influenced from Lisp in which a great variety
of characters can be used in procedure names.

h4. Binary Operators

<pre class="emlist">
1 + 2    # 1.+(2)
</pre>

Binary Operators will be converted to a method call to the object on the
left hand side. Here the method `+` from the object `1` is called.
As listed below there are many of them. There are the general operators
`+` and `-`, also the equivalence operator `==` and the spaceship operator
`<=>' as in Perl, all sorts. They are listed in order of their precedence.

<pre class="emlist">
**
* / %
+ -
<< >>
&
| ^
> >= < <=
<=> == === =~
</pre>

The symbols `&` and `|` are methods, but the double symbols `&&` and `||`
are built-in operators. Remember how it is in C.

h4. Unary Operators

<pre class="emlist">
+2
-1.0
~/regexp/
</pre>

These are the unary operators. There are only three of them: `+ - ~`.
`+` and `-` work as they look like (by default).
The operator `~` matches a string or a regular expression
with the variable `$_`. With an integer it stands for bit conversion.

To distinguish the unary `+` from the binary `+` the method names
for the unary operators are `+@` and `-@` respectively.
Of course they can be called by just writing `+n` or `-n`.

((errata: + or - as the prefix of a numeric literal is actually scanned as a
part of the literal. This is a kind of optimizations.))


h4. Attribute Assignment

<pre class="emlist">
obj.attr = val   # obj.attr=(val)
</pre>

This is an attribute assignment fashion. The above will be translated
into the method call `attr=`. When using this together with method calls whose
parentheses are omitted, we can write code which looks like attribute access.

<pre class="emlist">
class C
  def i() @i end          # We can write the definition in one line
  def i=(n) @i = n end
end

c = C.new
c.i = 99
p c.i    # prints 99
</pre>

However it will turn out both are method calls.
They are similar to get/set property in Delphi or slot accessors in CLOS.

Besides, we cannot define a method such as `obj.attr(arg)=`,
which can take another argument in the attribute assignment fashion.

h4. Index Notation

<pre class="emlist">
obj[i]    # obj.[](i)
</pre>

The above will be translated into a method call for `[]`.
Array and hash access are also implemented with this device.

<pre class="emlist">
obj[i] = val   # obj.[]=(i, val)
</pre>

Index assignment fashion.
This is translated into a call for a method named `[]=`.

h3. `super`

We relatively often have
a situation where we want add a little bit to the behaviour of an already
existing method rather than replacing it.
Here a mechanism to call a method of the superclass when overwriting a method
is required.
In Ruby, that's `super`.

<pre class="emlist">
class A
  def test
    puts 'in A'
  end
end
class B < A
  def test
    super   # invokes A#test
  end
end
</pre>

Ruby's `super` differs from the one in Java. This single word
means "call the method with the same name in the superclass".
`super` is a reserved word.

When using `super`, be careful about the difference between
`super` with no arguments and `super` whose arguments are omitted.
The `super` whose arguments are omitted passes all the given parameter variables.

<pre class="emlist">
class A
  def test( *args )
    p args
  end
end

class B < A
  def test( a, b, c )
    # super with no arguments
    super()    # shows []

    # super with omitted arguments. Same result as super(a, b, c)
    super      # shows [1, 2, 3]
  end
end

B.new.test(1,2,3)
</pre>

h4. Visibility

In Ruby, even when calling the same method,
it can be or cannot be called depending on the location (meaning the
object). This functionality is usually called "visibility"
(whether it is visible).
In Ruby, the below three types of methods can be defined.

* `public`
* `private`
* `protected`

`public` methods can be called from anywhere in any form.
`private` methods can only be called in a form "syntactically" without a receiver.
In effect they can only be called by instances of the class
in which they were defined and in instances of its subclass.
`protected` methods can only be called by instances of the defining class
and its subclasses.
It differs from `private` that methods can still be called from other
instances of the same class.

The terms are the same as in C++ but the meaning is slightly different.
Be careful.

Usually we control visibility as shown below.

<pre class="emlist">
class C
  public
  def a1() end   # becomes public
  def a2() end   # becomes public

  private
  def b1() end   # becomes private
  def b2() end   # becomes private

  protected
  def c1() end   # becomes protected
  def c2() end   # becomes protected
end
</pre>

Here `public`, `private` and `protected are method calls without
parentheses. These aren't even reserved words.

`public` and `private` can also be used with an argument to set
the visibility of a particular method. But its mechanism is not interesting.
We'll leave this out.

h4. Module functions

Given a module 'M'. If there are two methods with the exact same
content

* `M.method_name`
* `M#method_name`(Visibility is `private`)


then we call this a module function.

It is not apparent why this should be useful. But let's look
at the next example which is happily used.

<pre class="emlist">
Math.sin(5)       # If used for a few times this is more convenient

include Math
sin(5)            # If used more often this is more practical
</pre>

It's important that both functions have the same content.
With a different `self` but with the same code the behavior should
still be the same. Instance variables become extremely difficult to use.
Hence such method is very likely a method in which only procedures are written
(like `sin`). That's why they are called module "functions".

h2. Iterators

Ruby's iterators differ a bit from Java's or C++'s iterator classes
or 'Iterator' design pattern. Precisely speaking, those iterators
are called exterior iterators, Ruby's iterators are interior iterators.
Regarding this, it's difficult to understand from the definition so
let's explain it with a concrete example.

<pre class="emlist">
arr = [0,2,4,6.8]
</pre>

This array is given and we want to access the elements in
order. In C style we would write the following.

<pre class="emlist">
i = 0
while i < arr.length
  print arr[i]
  i += 1
end
</pre>

Using an iterator we can write:

<pre class="emlist">
arr.each do |item|
  print item
end
</pre>

Everything from `each do` to `end` is the call to an iterator method.
More precisely `each` is the iterator method and between
`do` and `end` is the iterator block.
The part between the vertical bars are called block parameters,
which become variables to receive the parameters passed from the iterator method
to the block.

Saying it a little abstractly, an iterator is something like
a piece of code which has been cut out and passed. In our example the
piece `print item` has been cut out and is passed to the `each` method.
Then `each` takes all the elements of the array in order and passes them
to the cut out piece of code.

We can also think the other way round. The other parts except `print item`
are being cut out and enclosed into the `each` method.

<pre class="emlist">
i = 0
while i < arr.length
  print arr[i]
  i += 1
end

arr.each do |item|
  print item
end
</pre>

h3. Comparison with higher order functions

What comes closest in C to iterators are functions which receive function pointers,
it means higher order functions. But there are two points in which iterators in Ruby
and higher order functions in C differ.

Firstly, Ruby iterators can only take one block. For instance we can't
do the following.

<pre class="emlist">
# Mistake. Several blocks cannot be passed.
array_of_array.each do |i|
  ....
end do |j|
  ....
end
</pre>

Secondly, Ruby's blocks can share local variables with the code outside.

<pre class="emlist">
lvar = 'ok'
[0,1,2].each do |i|
  p lvar    # Can acces local variable outside the block.
end
</pre>

That's where iterators are convenient.

But variables can only be shared with the outside. They cannot be shared
with the inside of the iterator method ( e.g. `each`). Putting it intuitively,
only the variables in the place which looks of the source code continued are
visible.

h3. Block Local Variables

Local variables which are assigned inside a block stay local to that block,
it means they become block local variables. Let's check it out.

<pre class="emlist">
[0].each do
  i = 0
  p i     # 0
end
</pre>

For now, to create a block, we apply `each` on an array of length 1
(We can fully leave out the block parameter).
In that block, the `i` variable is first assigned .. meaning declared.
This makes `i` block local.

It is said block local, so it should not be able to access from the outside.
Let's test it.

<pre class="screen">
% ruby -e '
[0].each do
  i = 0
end
p i     # Here occurs an error.
'
-e:5: undefined local variable or method `i'
for #<Object:0x40163a9c> (NameError)
</pre>

When we referenced a block local variable from outside the block,
surely an error occured. Without a doubt it stayed local to the block.

Iterators can also be nested repeatedly. Each time
the new block creates another scope.

<pre class="emlist">
lvar = 0
[1].each do
  var1 = 1
  [2].each do
    var2 = 2
    [3].each do
      var3 = 3
      #  Here lvar, var1, var2, var3 can be seen
    end
    # Here lvar, var1, var2 can be seen
  end
  # Here lvar, var1 can be seen
end
# Here only lvar can be seen
</pre>

There's one point which you have to keep in mind. Differing from
nowadays' major languages Ruby's block local variables don't do shadowing.
Shadowing means for instance in C that in the code below the two declared
variables `i` are different.

<pre class="emlist">
{
    int i = 3;
    printf("%d\n", i);         /* 3 */
    {
        int i = 99;
        printf("%d\n", i);     /* 99 */
    }
    printf("%d\n", i);         /* 3 (元に戻った) */
}
</pre>

Inside the block the @i@ inside overshadows the @i@ outside.
That's why it's called shadowing.

But what happens with block local variables of Ruby where there's no shadowing.
Let's look at this example.

<pre class="emlist">
i = 0
p i           # 0
[0].each do
  i = 1
  p i         # 1
end
p i           # 1 the change is preserved
</pre>

Even when we assign @i@ inside the block,
if there is the same name outside, it would be used.
Therefore when we assign to inside @i@, the value of outside @i@ would be
changed. On this point there
came many complains: "This is error prone. Please do shadowing."
Each time there's nearly flaming but till now no conclusion was reached.

h3. The syntax of iterators

There are some smaller topics left.

First, there are two ways to write an iterator. One is the
`do` ~ `end` as used above, the other one is the enclosing in braces.
The two expressions below have exactly the same meaning.

<pre class="emlist">
arr.each do |i|
  puts i
end

arr.each {|i|    # The author likes a four space indentation for
    puts i       # an iterator with braces.
}
</pre>

But grammatically the precedence is different.
The braces bind much stronger than `do`~`end`.

<pre class="emlist">
m m do .... end    # m(m) do....end
m m { .... }       # m(m() {....})
</pre>

And iterators are definitely methods,
so there are also iterators that take arguments.

<pre class="emlist">
re = /^\d/                 # regular expression to match a digit at the beginning of the line
$stdin.grep(re) do |line|  # look repeatedly for this regular expression
  ....
end
</pre>

h3. `yield`

Of course users can write their own iterators. Methods which have
a `yield` in their definition text are iterators.
Let's try to write an iterator with the same effect as `Array#each`:

<pre class="emlist">
# adding the definition to the Array class
class Array
  def my_each
    i = 0
    while i < self.length
      yield self[i]
      i += 1
    end
  end
end

# this is the original each
[0,1,2,3,4].each do |i|
  p i
end

# my_each works the same
[0,1,2,3,4].my_each do |i|
  p i
end
</pre>

@yield@ calls the block. At this point control is passed to the block,
when the execution of the block finishes it returns back to the same
location. Think about it like a characteristic function call. When the
present method does not have a block a runtime error will occur.

<pre class="screen">
% ruby -e '[0,1,2].each'
-e:1:in `each': no block given (LocalJumpError)
        from -e:1
</pre>

h3. `Proc`

I said, that iterators are like cut out code which is passed as an
argument. But we can even more directly make code to an object
and carry it around.

<pre class="emlist">
twice = Proc.new {|n| n * 2 }
p twice.call(9)   # 18 will be printed
</pre>

In short, it is like a function. As might be expected from the fact it is
created with @new@, the return value of @Proc.new@ is an instance
of the @Proc@ class.

@Proc.new@ looks surely like an iterator and it is indeed so.
It is an ordinary iterator. There's only some mystic mechanism inside @Proc.new@
which turns an iterator block into an object.

Besides there is a function style method @lambda@ provided which
has the same effect as @Proc.new@. Choose whatever suits you.

<pre class="emlist">
twice = lambda {|n| n * 2 }
</pre>

h4. Iterators and `Proc`

Why did we start talking all of a sudden about @Proc@? Because there
is a deep relationship between iterators and @Proc@.
In fact, iterator blocks and @Proc@ objects are quite the same thing.
That's why one can be transformed into the other.

First, to turn an iterator block into a @Proc@ object
one has to put an @&@ in front of the parameter name.

<pre class="emlist">
def print_block( &block )
  p block
end

print_block() do end   # Shows something like <Proc:0x40155884>
print_block()          # Without a block nil is printed
</pre>

With an @&@ in front of the argument name, the block is transformed to
a @Proc@ object and assigned to the variable. If the method is not an
iterator (there's no block attached) @nil@ is assigned.

And in the other direction, if we want to pass a @Proc@ to an iterator
we also use @&@.

<pre class="emlist">
block = Proc.new {|i| p i }
[0,1,2].each(&block)
</pre>

This code means exactly the same as the code below.

<pre class="emlist">
[0,1,2].each {|i| p i }
</pre>

If we combine these two, we can delegate an iterator
block to a method somewhere else.

<pre class="emlist">
def each_item( &block )
  [0,1,2].each(&block)
end

each_item do |i|    # same as [0,1,2].each do |i|
  p i
end
</pre>

h2. Expressions

"Expressions" in Ruby are things with which we can create other expressions or
statements by combining with the others.
For instance a method call can be another method call's argument,
so it is an expression. The same goes for literals.
But literals and method calls are not always combinations of elements.
On the contrary, "expressions", which I'm going to introduce,
always consists of some elements.

h3. `if`

We probably do not need to explain the @if@ expression. If the conditional
expression is true, the body is executed. As explained in Part 1,
every object except @nil@ and @false@ is true in Ruby.

<pre class="emlist">
if cond0 then
  ....
elsif cond1 then
  ....
elsif cond2 then
  ....
else
  ....
end
</pre>

`elsif`/`else`-clauses can be omitted. Each `then` as well.
But there are some finer requirements concerning @then@.
For this kind of thing, looking at some examples is the best way to understand.
Here only thing I'd say is that the below codes are valid.

<pre class="emlist">
# 1                                    # 4
if cond then ..... end                 if cond
                                       then .... end
# 2
if cond; .... end                      # 5
                                       if cond
# 3                                    then
if cond then; .... end                   ....
                                       end
</pre>

And in Ruby, `if` is an expression, so there is the value of the entire `if`
expression. It is the value of the body where a condition expression is met.
For example, if the condition of the first `if` is true,
the value would be the one of its body.

<pre class="emlist">
p(if true  then 1 else 2 end)   #=> 1
p(if false then 1 else 2 end)   #=> 2
p(if false then 1 elsif true then 2 else 3 end)   #=> 2
</pre>

If there's no match, or the matched clause is empty,
the value would be @nil@.

<pre class="emlist">
p(if false then 1 end)    #=> nil
p(if true  then   end)    #=> nil
</pre>

h3. `unless`

An @if@ with a negated condition is an @unless@.
The following two expressions have the same meaning.

<pre class="emlist">
unless cond then          if not (cond) then
  ....                      ....
end                       end
</pre>

@unless@ can also have attached @else@ clauses but any @elsif@ cannot be
attached.
Needless to say, @then@ can be omitted.

@unless@ also has a value and its condition to decide is completely the same as
`if`. It means the entire value would be the value of the body of the matched
clause. If there's no match or the matched clause is empty,
the value would be @nil@.

h3. `and && or ||`

The most likely utilization of the @and@ is probably a boolean operation.
For instance in the conditional expression of an @if@.

<pre class="emlist">
if cond1 and cond2
  puts 'ok'
end
</pre>

But as in Perl, `sh` or Lisp, it can also be used as a conditional
branch expression.
The two following expressions have the same meaning.

<pre class="emlist">
                                        if invalid?(key)
invalid?(key) and return nil              return nil
                                        end
</pre>

@&&@ and @and@ have the same meaning. Different is the binding order.

<pre class="emlist">
method arg0 &&  arg1    # method(arg0 && arg1)
method arg0 and arg1    # method(arg0) and arg1
</pre>

Basically the symbolic operator creates an expression which can be an argument
(`arg`).
The alphabetical operator creates an expression which cannot become
an argument (`expr`).

As for @and@, if the evaluation of the left hand side is true,
the right hand side will also be evaluated.

On the other hand @or@ is the opposite of @and@. If the evaluation of the left hand
side is false, the right hand side will also be evaluated.

<pre class="emlist">
valid?(key) or return nil
</pre>

@or@ and @||@ have the same relationship as @&&@ and @and@. Only the precedence is
different.

h3. The Conditional Operator

There is a conditional operator similar to C:

<pre class="emlist">
cond ? iftrue : iffalse
</pre>

The space between the symbols is important.
If they bump together the following weirdness happens.

<pre class="emlist">
cond?iftrue:iffalse   # cond?(iftrue(:iffalse))
</pre>

The value of the conditional operator is the value of the last executed expression.
Either the value of the true side or the value of the false side.

h3. `while until`

Here's a `while` expression.

<pre class="emlist">
while cond do
  ....
end
</pre>

This is the simplest loop syntax. As long as @cond@ is true
the body is executed. The @do@ can be omitted.

<pre class="emlist">
until io_ready?(id) do
  sleep 0.5
end
</pre>

@until@ creates a loop whose condition definition is opposite.
As long as the condition is false it is executed.
The @do@ can be omitted.

Naturally there is also jump syntaxes to exit a loop.
@break@ as in C/C++/Java is also @break@,
but @continue@ is @next@.
Perhaps @next@ has come from Perl.

<pre class="emlist">
i = 0
while true
  if i > 10
    break   # exit the loop
  elsif i % 2 == 0
    i *= 2
    next    # next loop iteration
  end
  i += 1
end
</pre>

And there is another Perlism: the @redo@.

<pre class="emlist">
while cond
  # (A)
  ....
  redo
  ....
end
</pre>

It will return to (A) and repeat from there.
What differs from @next@ is it does not check the condition.

I might come into the world top 100, if the amount of Ruby programs
would be counted, but I haven't used @redo@ yet. It does not seem to be
necessary after all because I've lived happily despite of it.

h3. `case`

A special form of the @if@ expression. It performs branching on a series of
conditions. The following left and right expressions are identical in meaning.

<pre class="emlist">
case value
when cond1 then                if cond1 === value
  ....                           ....
when cond2 then                elsif cond2 === value
  ....                           ....
when cond3, cond4 then         elsif cond3 === value or cond4 === value
  ....                           ....
else                           else
  ....                           ....
end                            end
</pre>

The threefold equals @===@ is, as the same as the @==@, actually a method call.
Notice that the receiver is the object on the left hand side. Concretely,
if it is the `===` of an `Array`, it would check if it contains the `value`
as its element.
If it is a `Hash`, it tests whether it has the `value` as its key.
If its is an regular expression, it tests if the @value@ matches.
And so on.
Since `case` has many grammatical elements,
to list them all would be tedious, thus we will not cover them in this book.


h3. Exceptions

This is a control structure which can pass over method boundaries and
transmit errors. Readers who are acquainted to C++ or Java
will know about exceptions. Ruby exceptions are basically the
same.

In Ruby exceptions come in the form of the function style method `raise`.
`raise` is not a reserved word.

<pre class="emlist">
raise ArgumentError, "wrong number of argument"
</pre>

In Ruby exception are instances of the @Exception@ class and it's
subclasses. This form takes an exception class as its first argument
and an error message as its second argument. In the above case
an instance of @ArgumentError@ is created and "thrown". Exception
object would ditch the part after the @raise@ and start to return upwards the
method call stack.

<pre class="emlist">
def raise_exception
  raise ArgumentError, "wrong number of argument"
  # the code after the exception will not be executed
  puts 'after raise'
end
raise_exception()
</pre>

If nothing blocks the exception it will move on and on and
finally it will reach the top level.
When there's no place to return any more, @ruby@ gives out a message and ends
with a non-zero exit code.

<pre class="screen">
% ruby raise.rb
raise.rb:2:in `raise_exception': wrong number of argument (ArgumentError)
        from raise.rb:7
</pre>

However an @exit@ would be sufficient for this, and for an exception there
should be a way to set handlers.
In Ruby, @begin@~@rescue@~@end@ is used for this.
It resembles the @try@~@catch@ in C++ and Java.

<pre class="emlist">
def raise_exception
  raise ArgumentError, "wrong number of argument"
end

begin
  raise_exception()
rescue ArgumentError => err then
  puts 'exception catched'
  p err
end
</pre>

@rescue@ is a control structure which captures exceptions, it catches
exception objects of the specified class and its subclasses. In the
above example, an instance of @ArgumentError@ comes flying into the place
where @ArgumentError@ is targeted, so it matches this @rescue@.
By @=>err@ the exception object will be assigned to the local variable
@err@, after that the @rescue@ part is executed.

<pre class="screen">
% ruby rescue.rb
exception catched
#<ArgumentError: wrong number of argument>
</pre>

When an exception is rescued, it will go through the `rescue` and
it will start to execute the subsequent as if nothing happened,
but we can also make it retry from the `begin`.
To do so, `retry` is used.

<pre class="emlist">
begin    # the place to return
  ....
rescue ArgumentError => err then
  retry  # retry your life
end
</pre>

We can omit the @=>err@ and the @then@ after @rescue@. We can also leave
out the exception class. In this case, it means as the same as when the
@StandardError@ class is specified.

If we want to catch more exception classes, we can just write them in line.
When we want to handle different errors differently, we can specify several
`rescue` clauses.

<pre class="emlist">
begin
  raise IOError, 'port not ready'
rescue ArgumentError, TypeError
rescue IOError
rescue NameError
end
</pre>

When written in this way, a `rescue` clause that matches the exception class is
searched in order from the top. Only the matched clause will be executed.
For instance, only the clause of @IOError@ will be executed in the above case.

On the other hand, when there is an @else@ clause, it is executed
only when there is no exception.

<pre class="emlist">
begin
  nil    # Of course here will no error occur
rescue ArgumentError
  # This part will not be executed
else
  # This part will be executed
end
</pre>

Moreover an @ensure@ clause will be executed in every case:
when there is no exception, when there is an exception, rescued or not.

<pre class="emlist">
begin
  f = File.open('/etc/passwd')
  # do stuff
ensure   # this part will be executed anyway
  f.close
end
</pre>

By the way, this @begin@ expression also has a value. The value of the
whole @begin@~@end@ expression is the value of the part which was executed
last among @begin@/@rescue@/@else@ clauses.
It means the last statement of the clauses aside from `ensure`.
The reason why the @ensure@ is not counted is probably because
@ensure@ is usually used for cleanup (thus it is not a main line).

h3. Variables and Constants

Referring a variable or a constant. The value is the object the variable points to.
We already talked in too much detail about the various behaviors.

<pre class="emlist">
lvar
@ivar
@@cvar
CONST
$gvar
</pre>

I want to add one more thing.
Among the variables starting with @$@,
there are special kinds.
They are not necessarily global variables and
some have strange names.

First the Perlish variables @$_@ and @$~@. @$_@ saves the return
value of @gets@ and other methods, @$~@ contains the last match
of a regular expression.
They are incredible variables which are local variables and simultaneously
thread local variables.

And the @$!@ to hold the exception object when an error is occured,
the @$?@ to hold the status of a child process,
the @$SAFE@ to represent the security level,
they are all thread local.

h3. Assignment

Variable assignments are all performed by `=`. All variables are
typeless. What is saved is a reference to an object.
As its implementation, it was a `VALUE` (pointer).

<pre class="emlist">
var = 1
obj = Object.new
@ivar = 'string'
@@cvar = ['array']
PI = 3.1415926535
$gvar = {'key' => 'value'}
</pre>

However, as mentioned earlier `obj.attr=val` is not an assignment
but a method call.

h3. Self Assignment

<pre class="emlist">
var += 1
</pre>

This syntax is also in C/C++/Java. In Ruby,

<pre class="emlist">
var = var + 1
</pre>

it is a shortcut of this code.
Differing from C, the Ruby @+@ is a method and thus part of the library.
In C, the whole meaning of @+=@ is built in the language processor itself.
And in `C++`, @+=@ and @*=@ can be wholly overwritten,
but we cannot do this in Ruby.
In Ruby @+=@ is always defined as an operation of the combination of @+@ and assignment.

We can also combine self assignment and an attribute-access-flavor method.
The result more looks like an attribute.

<pre class="emlist">
class C
  def i() @i end          # A method definition can be written in one line.
  def i=(n) @i = n end
end

obj = C.new
obj.i = 1
obj.i += 2    # obj.i = obj.i + 2
p obj.i       # 3
</pre>

If there is `+=` there might also be `++` but this is not the case.
Why is that so? In Ruby assignment is dealt with on the language level.
But on the other hand methods are in the library. Keeping these two,
the world of variables and the world of objects, strictly apart is an
important peculiarity of Ruby. If @++@ were introduced the separation
might easily be broken. That's why there's no @++@

Some people don't want to go without the brevity of @++@. It has been
proposed again and again in the mailing list but was always turned down.
I am also in favor of @++@ but not as much as I can't do without,
and I have not felt so much needs of @++@ in Ruby in the first place,
so I've kept silent and decided to forget about it.

h3. `defined?`

@defined?@ is a syntax of a quite different color in Ruby. It tells whether an
expression value is "defined" or not at runtime.

<pre class="emlist">
var = 1
defined?(var)   #=> true
</pre>

In other words it tells whether a value can be obtained from the expression
received as its argument (is it okay to call it so?) when the expression is
evaluated. That said but of course you can't write an expression causing a parse
error, and it could not detect if the expression is something containing a
method call which raises an error in it.

I would have loved to tell you more about @defined?@
but it will not appear again in this book. What a pity.

h2. Statements

A statement is what basically cannot be combined with the other syntaxes,
in other words, they are lined vertically.

But it does not mean there's no evaluated value.
For instance there are return values
for class definition statements and method definition statements.
However this is rarely recommended and isn't useful,
you'd better regard them lightly in this way.
Here we also skip about the value of each statement.

h3. The Ending of a statement

Up to now we just said "For now one line's one statement".
But Ruby's statement ending's aren't that straightforward.

First a statement can be ended explicitly with a semicolon as in C.
Of course then we can write two and more statements in one line.

<pre class="emlist">
puts 'Hello, World!'; puts 'Hello, World once more!'
</pre>

On the other hand,
when the expression apparently continues,
such as just after opened parentheses, dyadic operators, or a comma,
the statement continues automatically.

<pre class="emlist">
# 1 + 3 * method(6, 7 + 8)
1 +
  3 *
     method(
            6,
            7 + 8)
</pre>

But it's also totally no problem to use a backslash to explicitly indicate the
continuation.

<pre class="emlist">
p 1 + \
  2
</pre>

h3. The Modifiers `if` and `unless`

The `if` modifier is an irregular version of the normal `if`
The programs on the left and right mean exactly the same.

<pre class="emlist">
on_true() if cond                if cond
                                   on_true()
                                 end
</pre>

The `unless` is the negative version.
Guard statements ( statements which exclude exceptional conditions) can
be conveniently written with it.

h3. The Modifiers `while` and `until`

`while` and `until` also have a back notation.

<pre class="emlist">
process() while have_content?
sleep(1) until ready?
</pre>

Combining this with `begin` and `end` gives a `do`-`while`-loop like in C.

<pre class="emlist">
begin
  res = get_response(id)
end while need_continue?(res)
</pre>

h3. Class Definition

<pre class="emlist">
class C < SuperClass
  ....
end
</pre>

Defines the class `C` which inherits from `SuperClass`

We talked quite extensively about classes in Part 1.
This statement will be executed, the class to be defined will
become @self@ within the statement, arbitrary expressions can be written within. Class
definitions can be nested. They form the foundation of Ruby execution
image.

h3. Method Definition

<pre class="emlist">
def m(arg)
end
</pre>

I've already written about method definition and won't add more.
This section is put to make it clear that
they also belong to statements.

h3. Singleton method definition

We already talked a lot about singleton methods in Part 1.
They do not belong to classes but to objects, in fact, they belong
to singleton classes. We define singleton methods by putting the
receiver in front of the method name. Parameter declaration is done
the same way like with ordinary methods.

<pre class="emlist">
def obj.some_method
end

def obj.some_method2( arg1, arg2, darg = nil, *rest, &block )
end
</pre>

h3. Definition of Singleton methods

<pre class="emlist">
class << obj
  ....
end
</pre>

From the viewpoint of purposes,
it is the statement to define some singleton methods in a bundle.
From the viewpoint of measures,
it is the statement in which the singleton class of `obj` becomes `self` when
executed.
In all over the Ruby program,
this is the only place where a singleton class is exposed.

<pre class="emlist">
class << obj
  p self  #=> #<Class:#<Object:0x40156fcc>>   # Singleton Class 「(obj)」
  def a() end   # def obj.a
  def b() end   # def obj.b
end
</pre>

h3. Multiple Assignment

With a multiple assignment, several assignments can be done all at once.
The following is the simplest case:

<pre class="emlist">
a, b, c = 1, 2, 3
</pre>

It's exactly the same as the following.

<pre class="emlist">
a = 1
b = 2
c = 3
</pre>

Just being concise is not interesting.
in fact, when an array comes in to be mixed,
it becomes something fun for the first time.

<pre class="emlist">
a, b, c = [1, 2, 3]
</pre>

This also has the same result as the above.
Furthermore, the right hand side does not need to be a grammatical list or a
literal.
It can also be a variable or a method call.

<pre class="emlist">
tmp = [1, 2, 3]
a, b, c = tmp
ret1, ret2 = some_method()   # some_method might probably return several values
</pre>

Precisely speaking it is as follows.
Here we'll assume @obj@ is (the object of) the value of the left hand side,

# `obj` if it is an array
# if its `to_ary` method is defined, it is used to convert `obj` to an array.
# `[obj]`


Decide the right-hand side by following this procedure and perform assignments.
It means the evaluation of the right-hand side and the operation of assignments
are totally independent from each other.

And it goes on, both the left and right hand side can be infinitely nested.

<pre class="emlist">
a, (b, c, d) = [1, [2, 3, 4]]
a, (b, (c, d)) = [1, [2, [3, 4]]]
(a, b), (c, d) = [[1, 2], [3, 4]]
</pre>

As the result of the execution of this program,
each line will be `a=1 b=2 c=3 d=4`.

And it goes on. The left hand side can be index or parameter assignments.

<pre class="emlist">
i = 0
arr = []
arr[i], arr[i+1], arr[i+2] = 0, 2, 4
p arr    # [0, 2, 4]

obj.attr0, obj.attr1, obj.attr2 = "a", "b", "c"
</pre>

And like with method parameters,
@*@ can be used to receive in a bundle.

<pre class="emlist">
first, *rest = 0, 1, 2, 3, 4
p first  # 0
p rest   # [1, 2, 3, 4]
</pre>

When all of them are used all at once, it's extremely confusing.

h4. Block parameter and multiple assignment

We brushed over block parameters when we were talking about iterators.
But there is a deep relationship between them and multiple assignment.
For instance in the following case.

<pre class="emlist">
array.each do |i|
  ....
end
</pre>

Every time when the block is called,
the `yield`ed arguments are multi-assigned to `i`.
Here there's only one variable on the left hand side, so it does not look like multi assignment.
But if there are two or more variables, it would a little more look like it.
For instance, @Hash#each@ is an repeated operation on the pairs of keys and values,
so usually we call it like this:

<pre class="emlist">
hash.each do |key, value|
  ....
end
</pre>

In this case, each array consist of a key and a value is `yield`ed
from the hash.

Hence we can also does the following thing by using nested multiple assignment.

<pre class="emlist">
# [[key,value],index] are yielded
hash.each_with_index do |(key, value), index|
  ....
end
</pre>

h3. `alias`

<pre class="emlist">
class C
  alias new orig
end
</pre>

Defining another method `new` with the same body as the already
defined method `orig`. `alias` are similar to hardlinks in a unix
file system. They are a means of assigning multiple names to one method body.
To say this inversely,
because the names themselves are independent of each other,
even if one method name is overwritten by a subclass method, the
other one still remains with the same behavior.

h3. `undef`

<pre class="emlist">
class C
  undef method_name
end
</pre>

Prohibits the calling of `C#method_name`. It's not just a simple
revoking of the definition. If there even were a method in the
superclass it would also be forbidden. In other words the method is
exchanged for a sign which says "This method must not be called".

`undef` is extremely powerful, once it is set it cannot be
deleted from the Ruby level because it is used to cover up contradictions
in the internal structure.
Only one left measure is inheriting and defining a method in the lower class.
Even in that case, calling `super` would cause an error occurring.

The method which corresponds to `unlink` in a file system
is `Module#remove_method`. While defining a class, `self` refers
to that class, we can call it as follows (Remember that `Class` is a
subclass of `Module`.)

<pre class="emlist">
class C
  remove_method(:method_name)
end
</pre>

But even with a `remove_method` one cannot cancel the `undef`.
It's because the sign put up by `undef` prohibits any kind of searches.

((errata: It can be redefined by using `def`))

h2. Some more small topics

h3. Comments

<pre class="emlist">
# examples of bad comments.
1 + 1            # compute 1+1.
alias my_id id   # my_id is an alias of id.
</pre>

From a `#` to the end of line is a comment.
It doesn't have a meaning for the program.

h3. Embedded documents

<pre class="emlist">
=begin
This is an embedded document.
It's so called because it is embedded in the program.
Plain and simple.
=end
</pre>

An embedded document stretches from
an `=begin` outside a string at the beginning of a line
to a `=end`. The interior can be arbitrary.
The program ignores it as a mere comment.

h3. Multi-byte strings

When the global variable @$KCODE@ is set to either @EUC@, @SJIS@
or @UTF8@, strings encoded in euc-jp, shift_jis, or utf8 respectively can be
used in a string of a data.

And if the option @-Ke@, @-Ks@ or @-Ku@ is given to the @ruby@
command multibyte strings can be used within the Ruby code.
String literals, regular expressions and even operator names
can contain multibyte characters. Hence it is possible to do
something like this:

<pre class="emlist">
def 表示( arg )
  puts arg
end

表示 'にほんご'
</pre>

But I really cannot recommend doing things like that.
