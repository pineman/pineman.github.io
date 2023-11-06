# Ruby's ASCII-8BIT, mailers and feature launches

We've hit a couple of bugs during a recent feature launch. This
feature's 1.0 is an email - so no takesies backsies, you better get it
right the first time. Unfortunately, this was not the case. We did hit a
couple of bugs (curse you [string
types](https://wiki.c2.com/?StringlyTyped). Maybe don't store booleans
in CSVs? Maybe don't read data off CSVs. But I digress).

We initially shrugged off one of them during the first batch of emails,
but it came back around for the second batch. Luckily it only affected
our own dog fooding account. This is the error:

``` text
ActionView::Template::Error
incompatible character encodings: ASCII-8BIT and UTF-8 (ActionView::Template::Error)
```

So, let's start at the beginning: context, mental priming, emotional
control. What's the first thing that jumps to mind?

If your answer is *"\*\*\*\*ing email doesn't like utf-8"*, you're
literally me. You can deduce my emotions otherwise - my colleague on
call with me certainly did. So I'll skip ahead and spoil that
`ASCII-8BIT` doesn't mean *"blahblah ASCII only \*hand-wave\* email is
old"* - in ruby it literally is [an
alias](https://idiosyncratic-ruby.com/56-us-ascii-8bit.html#aliases) for
`BINARY`, meaning raw bytes. But I only found that out by the end of the
investigation.

I guess the "8bit" part gives it away, but I interpreted it as *"ASCII,
except some random character has the 7th bit set so it's complaining
loudly ohgodwhy"*. Maybe if I had immediately seen `BINARY` the
investigation could've been cut shorter, but it was already pretty short
by most accounts. [What else am I gonna blog
about](https://twitter.com/pineman_/status/1720426537768386659)? Let's
dive in.

### Investigation

Like all good things in life, you need the initial idea that comes after
the knee jerk reaction. The first good idea is to reproduce the bug,
which is pretty easy: just call the mailer inline, using `deliver_now`,
in the rails console connected to production (how great is that btw?
🤠). That reveals where it blows up:

``` text
/app/vendor/bundle/ruby/3.2.0/gems/activesupport-7.0.8/lib/active_support/core_ext/string/output_safety.rb:197:in `concat': incompatible character encodings: ASCII-8BIT and UTF-8 (ActionView::Template::Error)
```

That's cool and all, but this still doesn't tell me what string exactly,
out of the whole html email, is causing it to blow up. At this point my
colleague has the (correct) hunch that it's probably blowing up on emoji
in the name of a string identifier we template into the view. Pedantic,
boring old me however wants to be 100% sure.

This where I notice it fails in this `concat` method - so I have the
second good idea of monkey patching it. Again, how great is that?! Here
my co-worker notes, in a much less enthusiastic tone, that while yes
ruby is pretty cool, in another language you probably wouldn't even have
the need to monkey patch this method now because the bug wouldn't even
exist. I silently nod in approval, but move on as what would life be
without gnarly bugs? Another digression, another hit of the rubberband
on the wrist.

I read the method (cmd-p `output_safety`, `197G`, thanks rubymine) - it
uses an `ActiveSupport::SafeBuffer` and calls `original_concat`. I try
to reproduce the bug, having the emoji hunch in mind:

``` text
ActiveSupport::SafeBuffer.new("🤣").safe_concat("🤣")
```

This, of course, doesn't blow up: string literals are natively utf-8 in
ruby, so no encoding mismatches here. Let's try forcing this mysterious
`ASCII-8BIT` encoding (which, remember, at this point I didn't know was
an alias for `BINARY` and for some reason just didn't google it):

``` text
ActiveSupport::SafeBuffer.new("🤣").safe_concat(128.chr.force_encoding("ASCII-8BIT"))
/app/vendor/bundle/ruby/3.2.0/gems/activesupport-7.0.8/lib/active_support/core_ext/string/output_safety.rb:197:in `concat': incompatible character encodings: UTF-8 and ASCII-8BIT (Encoding::CompatibilityError)
```

Aha! `128.chr` just means `0b10000000`, which has the 7bit set. I
sort-of note, in the back of my head, that the encodings are backwards
here: my repro case says
`incompatible character encodings: UTF-8 and ASCII-8BIT` while the
original error says
`incompatible character encodings: ASCII-8BIT and UTF-8`. Which means
the email template was `ASCII-8BIT` at the time of the concatenation
with e.g. an emoji. I assumed that mailers' views were encoded as
`ASCII-8BIT` due to *"\*hand-wave\* email"* (foreshadowing 🫠) and moved
on. I want to find out on *what string* it's blowing up on. This is the
initial monkey-patch, printing the whole buffer and the small string to
be concatenated:

``` ruby
module ActiveSupport
  class SafeBuffer < String
    def safe_concat(value)
      begin
        raise SafeConcatError unless html_safe?
        original_concat(value)
      rescue => e
        puts self
        p value
        puts e.backtrace
        raise e
      end
    end
  end
end
```

This gets me closer - running the mailer again now prints:

``` text
(irb):312:in `write': "\xF0" from ASCII-8BIT to UTF-8 (Encoding::UndefinedConversionError)
(irb):310:in `concat': incompatible character encodings: ASCII-8BIT and UTF-8 (Encoding::CompatibilityError)
```

So we've got a mysterious `F0` byte somewhere. It's coming from the
latter parts of the email, which our feature didn't touch. The buffer
and the backtrace didn't print then though, for some reason, but did
when I changed the `puts` to just `p`. So now I know exactly where it's
blowing up, what the state of the buffer was, and what string was
causing this - it contains the emoji 🔀, which in utf-8 starts with
`0xF0`, or decimal `240`.

I try concating the offending string with a buffer of one emoji, and it
doesn't crash for the same reason again: ruby string literals are utf-8.
We check that the `ASCII-8BIT` encoding doesn't change the byte
representation of the emoji, and sure enough it doesn't. I try to force
the buffer to be encoded in `ASCII-8BIT`, but fail.

This is when we start doubting everything. Paranoia ensues. Are other
people an illusion of my mind? Is the name value coming from the DB as
`ASCII-8BIT`? We were getting it from our read replica... was its
encoding different? Sure enough, everything from the DB comes as
`UTF-8`, our paranoia is unjustified and other people are real.

I reproduce the bug using the mailer again. Scrolling... Wait, look!

``` text
... f06\"> \xF0\x9F\x94\x80Rec ...
```

Why does the buffer *already* contain an `F0`? The original buffer
already has this emoji?! Shows up as hexa escapes though - I chalk it up
to being due to using `p` instead of `puts`, but clearly the emoji was
concated succesfully before we crashed?!? And, perplexingly, this
earlier part of the email is the new part that we created for the
feature. Why is it breaking further down the line in code we didn't
touch?

### Dire straits

In dire situations like these, you **desperately** need the initial idea
that comes after the knee jerk reaction.

This is where the third great idea comes in: smoke break with the
airpods still on. It's time for some serious pair hypothesis crafting,
despite the rain and dark.

Clearly the view *does* knows how to render emojis all along. What if
the buffer starts out as `UTF-8`, the first emoji concat works... but
then switches to being `ASCII-8BIT` at some point, causing the second
emoji concat to fail? Let's go for broke, print the buffer's `.encoding`
at each call, and trace exactly when it switches (spewing large amounts
of text to my terminal will forever be my superpower. Thanks tmux and
vim). This is the final monkey patch:

``` ruby
module ActiveSupport
  class SafeBuffer < String
    def safe_concat(value)
      p self.encoding
      p self
      begin
        raise SafeConcatError unless html_safe?
        original_concat(value)
      rescue => e
        p "HIT TROUBLE"
        p self.encoding
        p self
        p value
        p value.encoding
        p e.backtrace
        raise e
      end
    end
  end
end
```

We trigger the mailer again, and sure enough it starts out life as
`UTF-8`, and we see it grow incrementally. We get to the first emoji
concat. The buffer was `UTF-8`, but the string itself... is in
`ASCII-8BIT`? Why...? We'd just seen that the value from the DB is
`UTF-8`. And sure enough, as soon as this `ASCII-8BIT` string is
concated with the buffer, it too is tainted to become `ASCII-8BIT`! It
blows up further ahead when the now `ASCII-8BIT` tries to concat the
second emoji string, which this time is correctly encoded as `UTF-8`!

This is when it becomes clear to my colleague that the "tainted"
`ASCII-8BIT` string is actually coming from a CSV file we built for the
new feature. This file is generated on demand but then cached, so
subsequent emails download and parse it from Google Cloud Storage (side
note: do not make CSV parsing load bearing. But if you do, remember to
convert strings to booleans on a boolean column 🫠). This file's
encoding is coming from GCloud as `ASCII-8BIT`, so my coworker does a
simple `.force_encoding(Encoding::UTF8)` on it, which cleanly fixes the
bug.

### ASCII-8BIT? WHY GOOGLE WHY

I'm not satisfied yet, and now I'm just angry. I go spelunking to find
out why files from gcloud storage, using the official ruby sdk, are
encoded using this mysterious `ASCII-8BIT` encoding. I find [the
code](https://github.com/googleapis/google-cloud-ruby/blob/9b455708c115a6e894e2b32521e5817fddc89b0a/google-cloud-storage/lib/google/cloud/storage/file.rb#L1038).
I type "thanks google" on my colleague's PR with the fix & curse some
more on our team's internal chat.

No one's complaining on the issue tracker... I find a reference on some
[random thread about
pub/sub](https://github.com/googleapis/google-cloud-ruby/pull/1564).
Wait. "canonical bytes representation"? Does that just mean binary?
Oh... That makes sense, I guess. Google doesn't make any assumptions
about encoding (as I mistakenly thought, because what the hell does
`ACSII-8BIT` mean), so it just says it's binary. It just happens that
'binary' has to have a whacky name in ruby, of course. Why. Why must it
be called `ASCII-8BIT`?! What do you mean, how does that even make
sense?!?!? ASCII is only 7 bits!!... A quick grep on ruby's source code
confirms that `ASCII-8BIT` is an alias for `BINARY`.

I remind myself of the other times I went to read up on history of a
particular historical change in ruby. My head is already hurting. I do
not wish to jump into this rabbit hole after one and a half hours of
fighting encoding errors. Not now. Maybe not ever.

I like computers.
