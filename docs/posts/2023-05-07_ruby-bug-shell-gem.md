# I found a (microscopic) ruby bug and it got fixed in 3 hours

I'm using [highlight.js](https://highlightjs.org/) for syntax
highlighting in this blog, client-side. I was looking to pre-compute it
statically, so I wrote a little node.js helper that reads stdin,
highlights the html using the library, and prints to stdout (not only is
it more unixy, I already have too many temp files being created). So to
call it from ruby, I found the [shell
gem](https://github.com/ruby/shell). [^1] It used to be in the stdlib
and the DSL syntax is super cool, with me being a rubyist now and all.

Anyway, I tried it and it seemed to work. However, since I was
prototyping, I put the `require` statement right next to its usage, in a
loop. When I tried hoisting it outside, where `require` normally goes,
the script started raising an error:

``` plaintext
.../3.1.0/gems/shell-0.8.1/lib/shell/process-controller.rb:261:in `close': uninitialized stream (IOError)
    from .../3.1.0/gems/shell-0.8.1/lib/shell/process-controller.rb:261:in `block (4 levels) in sfork'
    from .../3.1.0/gems/shell-0.8.1/lib/shell/process-controller.rb:259:in `each_object'
    from .../3.1.0/gems/shell-0.8.1/lib/shell/process-controller.rb:259:in `block (3 levels) in sfork'
    from .../3.1.0/gems/shell-0.8.1/lib/shell/process-controller.rb:251:in `fork'
    from .../3.1.0/gems/shell-0.8.1/lib/shell/process-controller.rb:251:in `block (2 levels) in sfork'
    from .../3.1.0/gems/shell-0.8.1/lib/shell/process-controller.rb:64:in `synchronize'
    from .../3.1.0/gems/shell-0.8.1/lib/shell/process-controller.rb:64:in `block_output_synchronize'
    from .../3.1.0/gems/shell-0.8.1/lib/shell/process-controller.rb:243:in `block in sfork'
```

That is... strange? I try and look for usages of this gem on
[sourcegraph](https://sourcegraph.com/search), but my code seems okay.
So I look into the gem's code. It essentially forks and then closes all
IO objects except stdin/out/err, and it's failing to close some of them.
I attempt to debug the script, but it fails due to the IO objects
closing and the debugger losing connection! [^2]

I play with the gem's code, writing debug output to a file directly,
resulting in a list of the IO objects the gem's trying to close, marking
the one that fails. I don't know where the failing object comes from
though, as I only have an hex address, so I come with the idea of
monkey-patching `IO#initialize` [^3] to try and match up the IO objects.
This doesn't help, as the IO object that fails to `close` doesn't show
up in my debug log. I then try essentially the same idea using `rbtrace`
with `rbtrace -p $(pgrep ruby) -m 'IO#initialize(self, __source__)'`.
Still, no avail.

I then try various ruby versions, since the shell gem is a bit outdated
or infrequently updated. Aha! It starts failing on 3.1.0, but succeeds
on 3.0.6. Maybe the gem just hasn't been updated to work on ruby 3.1.0.
I look through the release notes looking for nuances regarding IO
objects or fork behavior, but nothing. Could this be a ruby bug...?

I get an idea: I'll compile ruby with debug symbols, hoping that I can
inspect the IO object that fails. This turns out to be slightly tricky
and the binary I build is missing many things (probably missing lots of
configure flags), so I use ruby-build and its env vars. This works - I
can debug ruby (using `lldb`), create a breakpoint in `io.c`, where
`close` is implemented, and inspect the object at the address I got
earlier. I print some bytes off the pointer, and the only interesting
thing I see is the string `pandoc`, which I am running using the
backticks method to convert markdown to html. This gives me a clue that
the IO object is coming from the backticks method somehow [^4],
somewhere, but I want to be completely sure.

I realize I'm in a nice VM environment - it ought to be instrumentable
and introspectable, right? So I use `ObjectSpace.dump_all(output: io)`
to dump all objects, and cross-ref with address of the failed IO object
from my debug log. I get something like this:

``` plaintext
{"address":"0x101315888", "type":"FILE", "class":"0x10109ea50", "file":"./build.rb", "line":14, "method":"`", "generation":16, "memsize":40}
```

And line 14 is exactly where I call `pandoc` using backticks.
`0x10109ea50` is the `IO` class object.

Eventually I create a minimal reproduction case calling backticks and
the 4 lines of code from the gem. I find that inserting `GC.start` just
before calling the loop makes it succeed! Could this really be a bug in
ruby? [Do those really exist](https://wiki.c2.com/?CompilerBug)? A mere
mortal like me couldn't find one. Nonetheless, I have to do something
about it. The shell gem looks a bit inactive, and I've extracted the
offending code anyway to a nice repro case of only 5 lines. The code
makes sense to run in a forked process...

So, after careful deliberation, I decide to open a [bug in
ruby](https://bugs.ruby-lang.org/issues/19624)! Amazingly, it gets a
reply in just 3 hours on a Sunday! Looks like Nobuyoshi Nakada indeed
considered it a bug in MRI, and even implemented a pretty smart test
case. Truly a testament to async open source as the great software
development model of the world, as an old friend reminded me, after I
kept him waiting for beers as I was typing out the bug report very
nervously :)

**UPDATE 20/09/2023**: Turns out it wasn't a bug in ruby after all!...
I'll declare this as "not my fault" as I explicitly asked if the code
was incorrect 😅

All in all, a pretty cool win for me, even if I couldn't actually fix
the (microscopic!) bug myself, and it took a whole weekend! Hopefully
this kicks off a series of open source contributions for me :)

[^1]: My mind skipped over backticks completely, as would become
    fateful, I think because doing `echo #{html} | node` sounded stupid
    to me at first.

[^2]: In hindsight, I could have skipped closing TCP IO objects, but I
    digress.

[^3]: Like this:

    ``` ruby
    class IO
      old = instance_method(:initialize)
      define_method(:initialize) { |*args|
        File.write('/Users/pineman/debug', caller.inspect, mode: 'a+')
        File.write('/Users/pineman/debug', "NEW IO: #{self.inspect}"+"\n", mode: 'a+')
        old.bind(self).(*args)
      }
    end
    ```

[^4]: I found you can override backticks, aka `` Kernel.` ``, with

    ``` ruby
    def `(cmd)
      puts cmd
    end
    ```
