---
layout: default
title: "Chapter 15: Methods"
---

h1. Chapter 15: Methods

In this chapter, I'll talk about method searching and invoking.


h2. Searching methods


h3. Terminology


In this chapter, both method calls and method definitions are discussed,
and there will appear really various "arguments". Therefore, to make it not
confusing, let's strictly define terms here:



<pre class="emlist">
m(a)          # a is a "normal argument"
m(*list)      # list is an "array argument"
m(&block)     # block is a "block argument"

def m(a)      # a is a "normal parameter"
def m(a=nil)  # a is an "option parameter", nil is "it default value".
def m(*rest)  # rest is a "rest parameter"
def m(&block) # block is a "block parameter"
</pre>


In short, they are all "arguments" when passing and "parameters" when receiving,
and each adjective is attached according to its type.


However, among the above things, the "block arguments" and the "block
parameters" will be discussed in the next chapter.




h3. Investigation


<p class="caption">▼The Source Program</p>

<pre class="longlist">
obj.method(7,8)
</pre>


<p class="caption">▼Its Syntax Tree</p>

<pre class="longlist">
NODE_CALL
nd_mid = 9049 (method)
nd_recv:
    NODE_VCALL
    nd_mid = 9617 (obj)
nd_args:
    NODE_ARRAY [
    0:
        NODE_LIT
        nd_lit = 7:Fixnum
    1:
        NODE_LIT
        nd_lit = 8:Fixnum
    ]
</pre>


The node for a method call is `NODE_CALL`.
The `nd_args` holds the arguments as a list of `NODE_ARRAY`.


Additionally, as the nodes for method calls, there are also `NODE_FCALL` and `NODE_VCALL`.
`NODE_FCALL` is for the "`method(args)`" form,
`NODE_VCALL` corresponds to method calls in the "`method`" form that is the same
form as the local variables.
`FCALL` and `VCALL` could actually be integrated into one,
but because there's no need to prepare arguments when it is `VCALL`,
they are separated from each other only in order to save both times and memories for it.


Now, let's look at the handler of `NODE_CALL` in `rb_eval()`.


<p class="caption">▼ `rb_eval()` − `NODE_CALL` </p>

<pre class="longlist">
2745  case NODE_CALL:
2746    {
2747        VALUE recv;
2748        int argc; VALUE *argv; /* used in SETUP_ARGS */
2749        TMP_PROTECT;
2750
2751        BEGIN_CALLARGS;
2752        recv = rb_eval(self, node->nd_recv);
2753        SETUP_ARGS(node->nd_args);
2754        END_CALLARGS;
2755
2756        SET_CURRENT_SOURCE();
2757        result = rb_call(CLASS_OF(recv),recv,node->nd_mid,argc,argv,0);
2758    }
2759    break;

(eval.c)
</pre>


The problems are probably the three macros, `BEGIN_CALLARGS SETUP_ARGS() END_CALLARGS`.
It seems that `rb_eval()` is to evaluate the receiver and
`rb_call()` is to invoke the method, we can roughly imagine that the evaluation
of the arguments might be done in the three macros, but what is actually done?
`BEGIN_CALLARGS` and `END_CALLARGS` are difficult to understand before talking
about the iterators, so they are explained in the next chapter "Block".
Here, let's investigate only about `SETUP_ARGS()`.




h3. `SETUP_ARGS()`


`SETUP_ARGS()` is the macro to evaluate the arguments of a method.
Inside of this macro, as the comment in the original program says,
the variables named `argc` and `argv` are used,
so they must be defined in advance.
And because it uses `TMP_ALLOC()`, it must use `TMP_PROTECT` in advance.
Therefore, something like the following is a boilerplate:



<pre class="emlist">
int argc; VALUE *argv;   /* used in SETUP_ARGS */
TMP_PROTECT;

SETUP_ARGS(args_node);
</pre>


`args_node` is (the node represents) the arguments of the method,
turn it into an array of the values obtained by evaluating it,
and store it in `argv`.
Let's look at it:


<p class="caption">▼ `SETUP_ARGS()` </p>

<pre class="longlist">
1780  #define SETUP_ARGS(anode) do {\
1781      NODE *n = anode;\
1782      if (!n) {\                             no arguments
1783          argc = 0;\
1784          argv = 0;\
1785      }\
1786      else if (nd_type(n) == NODE_ARRAY) {\  only normal arguments
1787          argc=n->nd_alen;\
1788          if (argc > 0) {\   arguments present
1789              int i;\
1790              n = anode;\
1791              argv = TMP_ALLOC(argc);\
1792              for (i=0;i<argc;i++) {\
1793                  argv[i] = rb_eval(self,n->nd_head);\
1794                  n=n->nd_next;\
1795              }\
1796          }\
1797          else {\            no arguments
1798              argc = 0;\
1799              argv = 0;\
1800          }\
1801      }\
1802      else {\                                 both or one of an array argument
1803          VALUE args = rb_eval(self,n);\      and a block argument
1804          if (TYPE(args) != T_ARRAY)\
1805              args = rb_ary_to_ary(args);\
1806          argc = RARRAY(args)->len;\
1807          argv = ALLOCA_N(VALUE, argc);\
1808          MEMCPY(argv, RARRAY(args)->ptr, VALUE, argc);\
1809      }\
1810  } while (0)

(eval.c)
</pre>


This is a bit long, but since it clearly branches in three ways, not so terrible
actually. The meaning of each branch is written as comments.


We don't have to care about the case with no arguments, the two rest branches
are doing similar things. Roughly speaking, what they are doing consists of
three steps:


* allocate a space to store the arguments
* evaluate the expressions of the arguments
* copy the value into the variable space


If I write in the code (and tidy up a little), it becomes as follows.



<pre class="emlist">
/***** else if clause、argc!=0 *****/
int i;
n = anode;
argv = TMP_ALLOC(argc);                         /* 1 */
for (i = 0; i < argc; i++) {
    argv[i] = rb_eval(self, n->nd_head);        /* 2,3 */
    n = n->nd_next;
}

/***** else clause *****/
VALUE args = rb_eval(self, n);                  /* 2 */
if (TYPE(args) != T_ARRAY)
    args = rb_ary_to_ary(args);
argc = RARRAY(args)->len;
argv = ALLOCA_N(VALUE, argc);                   /* 1 */
MEMCPY(argv, RARRAY(args)->ptr, VALUE, argc);   /* 3 */
</pre>


`TMP_ALLOC()` is used in the `else if` side,
but `ALLOCA_N()`, which is ordinary `alloca()`, is used in the `else` side.
Why?
Isn't it dangerous in the `C_ALLOCA` environment because `alloca()` is
equivalent to `malloc()` ?


The point is that "in the `else` side the values of arguments are also stored in
`args`". If I illustrate, it would look like Figure 1.


!images/ch_method_anchor.jpg(Being in the heap is all right.)!


If at least one `VALUE` is on the stack, others can be successively marked through
it. This kind of `VALUE` plays a role to tie up the other `VALUE`s to the stack
like an anchor. Namely, it becomes "`anchor VALUE`".
In the `else` side, `args` is the anchor `VALUE`.


For your information, "anchor `VALUE`" is the word just coined now.




h3. `rb_call()`


`SETUP_ARGS()` is relatively off the track. Let's go back to the main line. The
function to invoke a method, it is `rb_call()`. In the original there're codes
like raising exceptions when it could not find anything, as usual I'll skip all
of them.


<p class="caption">▼ `rb_call()` (simplified)</p>

<pre class="longlist">
static VALUE
rb_call(klass, recv, mid, argc, argv, scope)
    VALUE klass, recv;
    ID    mid;
    int argc;
    const VALUE *argv;
    int scope;
{
    NODE  *body;
    int    noex;
    ID     id = mid;
    struct cache_entry *ent;

    /* search over method cache */
    ent = cache + EXPR1(klass, mid);
    if (ent->mid == mid && ent->klass == klass) {
        /* cache hit */
        klass = ent->origin;
        id    = ent->mid0;
        noex  = ent->noex;
        body  = ent->method;
    }
    else {
        /* cache miss, searching step-by-step  */
        body = rb_get_method_body(&klass, &id, &noex);
    }

    /* ... check the visibility ... */

    return rb_call0(klass, recv, mid, id,
                    argc, argv, body, noex & NOEX_UNDEF);
}
</pre>


The basic way of searching methods was discussed in chapter 2: "Object".
It is following its superclasses and searching `m_tbl`. This is done by
`search_method()`.


The principle is certainly this, but when it comes to the phase to execute
actually, if it searches by looking up its hash many times for each method call,
its speed would be too slow.
To improve this, in `ruby`, once a method is called, it will be cached.
If a method is called once, it's often immediately called again.
This is known as an experiential fact and  this cache records the high hit rate.


What is looking up the cache is the first half of `rb_call()`. Only with



<pre class="emlist">
ent = cache + EXPR1(klass, mid);
</pre>


this line, the cache is searched.
We'll examine its mechanism in detail later.


When any cache was not hit, the next `rb_get_method_body()` searches the class
tree step-by-step and caches the result at the same time.
Figure 2 shows the entire flow of searching.


!images/ch_method_msearch.jpg(Method Search)!




h3. Method Cache


Next, let's examine the structure of the method cache in detail.


<p class="caption">▼Method Cache</p>

<pre class="longlist">
 180  #define CACHE_SIZE 0x800
 181  #define CACHE_MASK 0x7ff
 182  #define EXPR1(c,m) ((((c)>>3)^(m))&CACHE_MASK)
 183
 184  struct cache_entry {            /* method hash table. */
 185      ID mid;                     /* method's id */
 186      ID mid0;                    /* method's original id */
 187      VALUE klass;                /* receiver's class */
 188      VALUE origin;               /* where method defined  */
 189      NODE *method;
 190      int noex;
 191  };
 192
 193  static struct cache_entry cache[CACHE_SIZE];

(eval.c)
</pre>


If I describe the mechanism shortly, it is a hash table. I mentioned that the
principle of the hash table is to convert a table search to an indexing of an
array. Three things are necessary to accomplish: an array to store the data,
a key, and a hash function.


First, the array here is an array of `struct cache_entry`. And the method is
uniquely determined by only the class and the method name, so these two become
the key of the hash calculation. The rest is done by creating a hash function
to generate the index (`0x000` ~ `0x7ff`) of the cache array form the key.
It is `EXPR1()`. Among its arguments, `c` is the class object and `m` is the
method name (`ID`). (Figure 3)


!images/ch_method_mhash.jpg(Method Cache)!


However, `EXPR1()` is not a perfect hash function or anything, so a different
method can generate the same index coincidentally. But because this is nothing
more than a cache, conflicts do not cause a problem.
It just slows its performance down a little.



h4. The effect of Method Cache


By the way, how much effective is the method cache in actuality?
We could not be convinced just by being said "it is known as ...".
Let's measure by ourselves.


|_. Type |_. Program |_. Hit Rate |
| generating LALR(1) parser | racc ruby.y | 99.9% |
| generating a mail thread | a mailer | 99.1% |
| generating a document | rd2html rubyrefm.rd | 97.8% |


Surprisingly, in all of the three experiments the hit rate is more than 95%.
This is awesome. Apparently, the effect of "it is know as ..." is outstanding.





h2. Invocation

h3. `rb_call0()`


There have been many things and finally we arrived at the method invoking.
However, this `rb_call0()` is huge. As it's more than 200 lines, it would come
to 5,6 pages. If the whole part is laid out here, it would be disastrous. Let's
look at it by dividing into small portions. Starting with the outline:


<p class="caption">▼ `rb_call0()` (Outline)</p>

<pre class="longlist">
4482  static VALUE
4483  rb_call0(klass, recv, id, oid, argc, argv, body, nosuper)
4484      VALUE klass, recv;
4485      ID    id;
4486      ID    oid;
4487      int argc;                   /* OK */
4488      VALUE *argv;                /* OK */
4489      NODE *body;                 /* OK */
4490      int nosuper;
4491  {
4492      NODE *b2;           /* OK */
4493      volatile VALUE result = Qnil;
4494      int itr;
4495      static int tick;
4496      TMP_PROTECT;
4497
4498      switch (ruby_iter->iter) {
4499        case ITER_PRE:
4500          itr = ITER_CUR;
4501          break;
4502        case ITER_CUR:
4503        default:
4504          itr = ITER_NOT;
4505          break;
4506      }
4507
4508      if ((++tick & 0xff) == 0) {
4509          CHECK_INTS;             /* better than nothing */
4510          stack_check();
4511      }
4512      PUSH_ITER(itr);
4513      PUSH_FRAME();
4514
4515      ruby_frame->last_func = id;
4516      ruby_frame->orig_func = oid;
4517      ruby_frame->last_class = nosuper?0:klass;
4518      ruby_frame->self = recv;
4519      ruby_frame->argc = argc;
4520      ruby_frame->argv = argv;
4521
4522      switch (nd_type(body)) {
              /* ... main process ... */
4698
4699        default:
4700          rb_bug("unknown node type %d", nd_type(body));
4701          break;
4702      }
4703      POP_FRAME();
4704      POP_ITER();
4705      return result;
4706  }

(eval.c)
</pre>


First, an `ITER` is pushed and whether or not the method is an iterator is
finally fixed. As its value is used by the `PUSH_FRAME()` which comes
immediately after it, `PUSH_ITER()` needs to appear beforehand.
`PUSH_FRAME()` will be discussed soon.


And if I first describe about the "... main process ..." part,
it branches based on the following node types
and each branch does its invoking process.


| `NODE_CFUNC`   | methods defined in C |
| `NODE_IVAR`    | `attr_reader` |
| `NODE_ATTRSET` | `attr_writer` |
| `NODE_SUPER`   | `super` |
| `NODE_ZSUPER`  | `super` without arguments |
| `NODE_DMETHOD` | invoke `UnboundMethod` |
| `NODE_BMETHOD` | invoke `Method` |
| `NODE_SCOPE`   | methods defined in Ruby |


Some of the above nodes are not explained in this book but not so important and
could be ignored.  The important things are only `NODE_CFUNC`, `NODE_SCOPE` and
`NODE_ZSUPER`.




h3. `PUSH_FRAME()`


<p class="caption">▼ `PUSH_FRAME() POP_FRAME()` </p>

<pre class="longlist">
 536  #define PUSH_FRAME() do {               \
 537      struct FRAME _frame;                \
 538      _frame.prev = ruby_frame;           \
 539      _frame.tmp  = 0;                    \
 540      _frame.node = ruby_current_node;    \
 541      _frame.iter = ruby_iter->iter;      \
 542      _frame.cbase = ruby_frame->cbase;   \
 543      _frame.argc = 0;                    \
 544      _frame.argv = 0;                    \
 545      _frame.flags = FRAME_ALLOCA;        \
 546      ruby_frame = &_frame

 548  #define POP_FRAME()                     \
 549      ruby_current_node = _frame.node;    \
 550      ruby_frame = _frame.prev;           \
 551  } while (0)

(eval.c)
</pre>


First, we'd like to make sure the entire `FRAME` is allocated on the stack.
This is identical to `module_setup()`. The rest is basically just doing
ordinary initializations.


If I add one more description, the flag `FRAME_ALLOCA` indicates the allocation
method of the `FRAME`. `FRAME_ALLOCA` obviously indicates "it is on the stack".




h3. `rb_call0()` - `NODE_CFUNC`


A lot of things are written in this part of the original code,
but most of them are related to `trace_func` and substantive code is only the
following line:


<p class="caption">▼ `rb_call0()` − `NODE_CFUNC` (simplified)</p>

<pre class="longlist">
case NODE_CFUNC:
  result = call_cfunc(body->nd_cfnc, recv, len, argc, argv);
  break;
</pre>


Then, as for `call_cfunc()` ...


<p class="caption">▼ `call_cfunc()` (simplified)</p>

<pre class="longlist">
4394  static VALUE
4395  call_cfunc(func, recv, len, argc, argv)
4396      VALUE (*func)();
4397      VALUE recv;
4398      int len, argc;
4399      VALUE *argv;
4400  {
4401      if (len >= 0 && argc != len) {
4402          rb_raise(rb_eArgError, "wrong number of arguments(%d for %d)",
4403                   argc, len);
4404      }
4405
4406      switch (len) {
4407        case -2:
4408          return (*func)(recv, rb_ary_new4(argc, argv));
4409          break;
4410        case -1:
4411          return (*func)(argc, argv, recv);
4412          break;
4413        case 0:
4414          return (*func)(recv);
4415          break;
4416        case 1:
4417          return (*func)(recv, argv[0]);
4418          break;
4419        case 2:
4420          return (*func)(recv, argv[0], argv[1]);
4421          break;
                ：
                ：
4475        default:
4476          rb_raise(rb_eArgError, "too many arguments(%d)", len);
4477          break;
4478      }
4479      return Qnil;                /* not reached */
4480  }

(eval.c)
</pre>


As shown above, it branches based on the argument count.
The maximum argument count is 15.


Note that neither `SCOPE` or `VARS` is pushed when it is `NODE_CFUNC`. It makes
sense because a method defined in C does not use Ruby's local
variables. But it simultaneously means that if the "current" local variables are
accessed by `C`, they are actually the local variables of the previous `FRAME`.
And in some places, say, `rb_svar` (`eval.c`), it is actually done.



h3. `rb_call0()` - `NODE_SCOPE`


`NODE_SCOPE` is to invoke a method defined in Ruby.
This part forms the foundation of Ruby.


<p class="caption">▼ `rb_call0()` − `NODE_SCOPE` (outline)</p>

<pre class="longlist">
4568  case NODE_SCOPE:
4569    {
4570        int state;
4571        VALUE *local_vars;  /* OK */
4572        NODE *saved_cref = 0;
4573
4574        PUSH_SCOPE();
4575
            /* （A）forward CREF */
4576        if (body->nd_rval) {
4577            saved_cref = ruby_cref;
4578            ruby_cref = (NODE*)body->nd_rval;
4579            ruby_frame->cbase = body->nd_rval;
4580        }
            /* （B）initialize ruby_scope->local_vars */
4581        if (body->nd_tbl) {
4582            local_vars = TMP_ALLOC(body->nd_tbl[0]+1);
4583            *local_vars++ = (VALUE)body;
4584            rb_mem_clear(local_vars, body->nd_tbl[0]);
4585            ruby_scope->local_tbl = body->nd_tbl;
4586            ruby_scope->local_vars = local_vars;
4587        }
4588        else {
4589            local_vars = ruby_scope->local_vars = 0;
4590            ruby_scope->local_tbl  = 0;
4591        }
4592        b2 = body = body->nd_next;
4593
4594        PUSH_VARS();
4595        PUSH_TAG(PROT_FUNC);
4596
4597        if ((state = EXEC_TAG()) == 0) {
4598            NODE *node = 0;
4599            int i;

                /* ……（C）assign the arguments to the local variables …… */

4666            if (trace_func) {
4667                call_trace_func("call", b2, recv, id, klass);
4668            }
4669            ruby_last_node = b2;
                /* （D）method body */
4670            result = rb_eval(recv, body);
4671        }
4672        else if (state == TAG_RETURN) { /* back via return */
4673            result = prot_tag->retval;
4674            state = 0;
4675        }
4676        POP_TAG();
4677        POP_VARS();
4678        POP_SCOPE();
4679        ruby_cref = saved_cref;
4680        if (trace_func) {
4681            call_trace_func("return", ruby_last_node, recv, id, klass);
4682        }
4683        switch (state) {
4684          case 0:
4685            break;
4686
4687          case TAG_RETRY:
4688            if (rb_block_given_p()) {
4689               JUMP_TAG(state);
4690            }
4691            /* fall through */
4692          default:
4693            jump_tag_but_local_jump(state);
4694            break;
4695        }
4696    }
4697    break;

(eval.c)
</pre>


(A) `CREF` forwarding, which was described at the section of constants in the
previous chapter.
In other words, `cbase` is transplanted to `FRAME` from the method entry.


(B) The content here is completely identical to what is done at `module_setup()`.
An array is allocated at `local_vars` of `SCOPE`. With this and
`PUSH_SCOPE()` and `PUSH_VARS()`, the local variable scope creation is completed.
After this, one can execute `rb_eval()` in the exactly same environment as the
interior of the method.


==(C)== This sets the received arguments to the parameter variables.
The parameter variables are in essence identical to the local variables. Things
such as the number of arguments are specified by `NODE_ARGS`, all it has to do
is setting one by one. Details will be explained soon. And,

(D) this executes the method body. Obviously, the receiver (`recv`) becomes
`self`. In other words, it becomes the first argument of `rb_eval()`. After all,
the method is completely invoked.




h3. Set Parameters


Then, we'll examine the totally skipped part, which sets parameters.
But before that, I'd like you to first check the syntax tree of the method again.



<pre class="screen">
% ruby -rnodedump -e 'def m(a) nil end'
NODE_SCOPE
nd_rval = (null)
nd_tbl = 3 [ _ ~ a ]
nd_next:
    NODE_BLOCK
    nd_head:
        NODE_ARGS
        nd_cnt  = 1
        nd_rest = -1
        nd_opt = (null)
    nd_next:
        NODE_BLOCK
        nd_head:
            NODE_NEWLINE
            nd_file = "-e"
            nd_nth  = 1
            nd_next:
                NODE_NIL
        nd_next = (null)
</pre>


`NODE_ARGS` is the node to specify the parameters of a method.
I aggressively dumped several things,
and it seemed its members are used as follows:


| `nd_cnt` | the number of the normal parameters |
| `nd_rest` | the variable `ID` of the `rest` parameter. `-1` if the `rest` parameter is missing |
| `nd_opt` | holds the syntax tree to represent the default values of the option parameters. a list of `NODE_BLOCK` |


If one has this amount of the information, the local variable `ID` for each
parameter variable can be uniquely determined.
First, I mentioned that 0 and 1 are always `$_` and `$~`.
In 2 and later, the necessary number of ordinary parameters are in line.
The number of option parameters can be determined by the length of `NODE_BLOCK`.
Again next to them, the rest-parameter comes.


For example, if you write a definition as below,



<pre class="emlist">
def m(a, b, c = nil, *rest)
  lvar1 = nil
end
</pre>


local variable IDs are assigned as follows.



<pre class="emlist">
0   1   2   3   4   5      6
$_  $~  a   b   c   rest   lvar1
</pre>


Are you still with me?
Taking this into considerations, let's look at the code.


<p class="caption">▼ `rb_call0()` − `NODE_SCOPE` −assignments of arguments</p>

<pre class="longlist">
4601  if (nd_type(body) == NODE_ARGS) { /* no body */
4602      node = body;           /* NODE_ARGS */
4603      body = 0;              /* the method body */
4604  }
4605  else if (nd_type(body) == NODE_BLOCK) { /* has body */
4606      node = body->nd_head;  /* NODE_ARGS */
4607      body = body->nd_next;  /* the method body */
4608  }
4609  if (node) {  /* have somewhat parameters */
4610      if (nd_type(node) != NODE_ARGS) {
4611          rb_bug("no argument-node");
4612      }
4613
4614      i = node->nd_cnt;
4615      if (i > argc) {
4616          rb_raise(rb_eArgError, "wrong number of arguments(%d for %d)",
4617                   argc, i);
4618      }
4619      if (node->nd_rest == -1) {  /* no rest parameter */
              /* counting the number of parameters */
4620          int opt = i;   /* the number of parameters (i is nd_cnt) */
4621          NODE *optnode = node->nd_opt;
4622
4623          while (optnode) {
4624              opt++;
4625              optnode = optnode->nd_next;
4626          }
4627          if (opt < argc) {
4628              rb_raise(rb_eArgError,
4629                  "wrong number of arguments(%d for %d)", argc, opt);
4630          }
              /* assigning at the second time in rb_call0 */
4631          ruby_frame->argc = opt;
4632          ruby_frame->argv = local_vars+2;
4633      }
4634
4635      if (local_vars) { /* has parameters */
4636          if (i > 0) {             /* has normal parameters */
4637              /* +2 to skip the spaces for $_ and $~ */
4638              MEMCPY(local_vars+2, argv, VALUE, i);
4639          }
4640          argv += i; argc -= i;
4641          if (node->nd_opt) {      /* has option parameters */
4642              NODE *opt = node->nd_opt;
4643
4644              while (opt && argc) {
4645                  assign(recv, opt->nd_head, *argv, 1);
4646                  argv++; argc--;
4647                  opt = opt->nd_next;
4648              }
4649              if (opt) {
4650                  rb_eval(recv, opt);
4651              }
4652          }
4653          local_vars = ruby_scope->local_vars;
4654          if (node->nd_rest >= 0) { /* has rest parameter */
4655              VALUE v;
4656
                  /* make an array of the remainning parameters and assign it to a variable */
4657              if (argc > 0)
4658                  v = rb_ary_new4(argc,argv);
4659              else
4660                  v = rb_ary_new2(0);
4661              ruby_scope->local_vars[node->nd_rest] = v;
4662          }
4663      }
4664  }

(eval.c)
</pre>


Since comments are added more than before,
you might be able to understand what it is doing by following step-by-step.


One thing I'd like to mention is about `argc` and `argv` of `ruby_frame`.
It seems to be updated only when any rest-parameter does not exist,
why is it only when any rest-parameter does not exist?


This point can be understood by thinking about the purpose of `argc` and `argv`.
These members actually exist for `super` without arguments.
It means the following form:



<pre class="emlist">
super
</pre>


This `super` has a behavior to directly pass the parameters of the currently executing method.
To enable to pass at the moment, the arguments are saved in `ruby_frame->argv`.


Going back to the previous story here,
if there's a rest-parameter, passing the original parameters list somehow seems more convenient.
If there's not, the one after option parameters are assigned seems better.



<pre class="emlist">
def m(a, b, *rest)
  super     # probably 5, 6, 7, 8 should be passed
end
m(5, 6, 7, 8)

def m(a, b = 6)
  super     # probably 5, 6 should be passed
end
m(5)
</pre>



This is a question of which is better as a specification rather than "it must be".
If a method has a rest-parameter,
it supposed to also have a rest-parameter at superclass.
Thus, if the value after processed is passed, there's the high possibility of being inconvenient.


Now, I've said various things, but the story of method invocation is all done.
The rest is, as the ending of this chapter, looking at the implementation of
`super` which is just discussed.




h3. `super`


What corresponds to `super` are `NODE_SUPER` and `NODE_ZSUPER`.
`NODE_SUPER` is ordinary `super`,
and `NODE_ZSUPER` is `super` without arguments.


<p class="caption">▼ `rb_eval()` − `NODE_SUPER` </p>

<pre class="longlist">
2780        case NODE_SUPER:
2781        case NODE_ZSUPER:
2782          {
2783              int argc; VALUE *argv; /* used in SETUP_ARGS */
2784              TMP_PROTECT;
2785
                  /*（A）case when super is forbidden */
2786              if (ruby_frame->last_class == 0) {
2787                  if (ruby_frame->orig_func) {
2788                      rb_name_error(ruby_frame->last_func,
2789                                    "superclass method `%s' disabled",
2790                                    rb_id2name(ruby_frame->orig_func));
2791                  }
2792                  else {
2793                      rb_raise(rb_eNoMethodError,
                                   "super called outside of method");
2794                  }
2795              }
                  /*（B）setup or evaluate parameters */
2796              if (nd_type(node) == NODE_ZSUPER) {
2797                  argc = ruby_frame->argc;
2798                  argv = ruby_frame->argv;
2799              }
2800              else {
2801                  BEGIN_CALLARGS;
2802                  SETUP_ARGS(node->nd_args);
2803                  END_CALLARGS;
2804              }
2805
                  /*（C）yet mysterious PUSH_ITER() */
2806              PUSH_ITER(ruby_iter->iter?ITER_PRE:ITER_NOT);
2807              SET_CURRENT_SOURCE();
2808              result = rb_call(RCLASS(ruby_frame->last_class)->super,
2809                               ruby_frame->self, ruby_frame->orig_func,
2810                               argc, argv, 3);
2811              POP_ITER();
2812          }
2813          break;

(eval.c)
</pre>


For `super` without arguments, I said that `ruby_frame->argv` is directly used
as arguments, this is directly shown at (B).


==(C)== just before calling `rb_call()`, doing `PUSH_ITER()`.
This is also what cannot be explained in detail, but in this way the block
passed to the current method can be handed over to the next method (meaning, the
method of superclass that is going to be called).



And finally, (A) when `ruby_frame->last_class` is 0, calling `super` seems forbidden.
Since the error message says "`must be enabled by rb_enable_super()`",
it seems it becomes callable by calling `rb_enable_super()`.
<br>((errata: The error message "`must be enabled by rb_enable_super()`" exists not
in this list but in `rb_call_super()`.))
<br>Why?


First, If we investigate in what kind of situation `last_class` becomes 0,
it seems that it is while executing the method whose substance is defined in C (`NODE_CFUNC`).
Moreover, it is the same when doing `alias` or replacing such method.


I've understood until there, but even though reading source codes, I couldn't
understand the subsequents of them.
Because I couldn't, I searched "`rb_enable_super`" over the `ruby`'s
mailing list archives and found it.
According to that mail, the situation looks like as follows:


For example, there's a method named `String.new`.
Of course, this is a method to create a string.
`String.new` creates a struct of `T_STRING`.
Therefore, you can expect that the receiver is always of `T_STRING` when
writing an instance methods of `String`.


Then, `super` of `String.new` is `Object.new`.
`Object.new` create a struct of `T_OBJECT`.
What happens if `String.new` is replaced by new definition and `super` is called?



<pre class="emlist">
def String.new
  super
end
</pre>

As a consequence, an object whose struct is of `T_OBJECT` but whose class is `String` is created.
However, a method of `String` is written with expectation of a struct of `T_STRING`,
so naturally it downs.


How can we avoid this? The answer is to forbid to call any method expecting a
struct of a different struct type.
But the information of "expecting struct type" is not attached to method,
and also not to class.
For example, if there's a way to obtain `T_STRING` from `String` class,
it can be checked before calling, but currently we can't do such thing.
Therefore, as the second-best plan,
"`super` from methods defined in C is forbidden" is defined.
In this way, if the layer of methods at C level is precisely created,
it cannot be got down at least.
And, when the case is "It's absolutely safe, so allow `super`",
`super` can be enabled by calling `rb_enable_super()`.


In short, the heart of the problem is miss match of struct types.
This is the same as the problem that occurs at the allocation framework.


Then, how to solve this is to solve the root of the problem that "the class
does not know the struct-type of the instance".
But, in order to resolve this, at least new API is necessary,
and if doing more deeply, compatibility will be lost.
Therefore, for the time being, the final solution has not decided yet.
