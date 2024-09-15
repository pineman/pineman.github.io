# Just use curl (or how hard can it be to make HTTP requests?)

Recently we've needed to do a lot of HTTP requests to weird APIs. One
endpoint in particular is basically the wild west of HTTP - High,
unpredictable latency and redirects a lot: often absolutely, from HTTPS
to HTTP and even to non-resolving URLs.

I started this endeavour with good ole
[HTTP.rb](https://github.com/httprb/http), as one does, blissfully
unaware of this long tail of responses. I configured a 15s timeout for
this endpoint call to deal with its unpredictability. And things were
going great! HTTP.rb does The Right Thing 99% of the time regarding
following redirects and other errors, so I went on my merry way.

... Until I started tracking my requests more closely and noticed some
were taking longer than 15s. Much longer, in fact. Turns out the timeout
settings are per-HTTP-request - i.e., a call to `HTTP.get` with
`max_hops: 10` and `timeout: 15` can take up to 150s, modulo other
shenanigans we'll get to. This is not okay as each redirect can easily
take 10s, wrecking my performance SLO - which, while relatively lax, is
certainly not to exceed around 30s, and very hopefully below that. I
needed a way to set a global timeout for ALL redirects in this call to
`HTTP.get` [^1].

So. What to do? The obvious and, of course, naive solution, is to just
stick a `Timeout::timeout` around the request and be done with it. I
really, really didn't want to do this, as I had already read the
(hopefully) famous [article by Charles
Nutter](https://web.archive.org/web/20110903054547/http://blog.headius.com/2008/02/ruby-threadraise-threadkill-timeoutrb.html)
(and the "repost" [by Mike
Perham](https://www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/))
about how fundamentally broken it is. [This
post](https://redgetan.cc/understanding-timeouts-in-cruby/) is
incredible - it goes into the internals of how Timeout works in CRuby.

As a quick summary, `Timeout::timeout` essentially spins up a whole new
thread (if not using Fibers), just to sleep in it for the duration of
the timeout. If the block of code runs before the timeout is elapsed,
the thread is killed, and so it doesn't wake up. If it does wake up,
however, it uses `Thread#raise` to raise an error in the calling thread
at any point, arbritarily, which is SUPER dangerous! There's no
guarantee as to when exactly the sleeping thread will run or when the
calling thread will receive the signal, so all manner of standard race
problems apply.

Speaking with some colleagues we noted the probable Right Way™ to solve
this would be to use Fibers and async-http, possibly with Faraday. I,
uh, didn't do that. My logic and testing was already very much on top of
HTTP.rb's behavior, so it'd be a pretty big change. Besides, our project
doesn't use any async stuff yet, so I'd be pioneering this in. Guess
what I did - I stuck `Timeout::timeout` in there and moved on.

... Until I started getting errors I hadn't before. And the stacktrace
makes no sense - the line where the error was raised couldn't possibly
even raise that error. I had a rescue around all the HTTP calls I was
doing, so how wasn't it rescued there?!... Oh. God. Wait. It's
`Timeout::timeout`, isn't it?...

It was. I suspect it was doubly-bad as HTTP.rb itself uses
`Timeout::timeout` for its timeouts [^2]. I was triggering this
condition fairly often, in just hundreds of requests, on my machine -
there's no way we can ship it like this.

Time to look for alternatives, I guess... I'll try not to get into
hideous technical detail, for both your sake and mine. I checked, and it
seemed to me that the stdlib Net:HTTP also used `Timeout::timeout` -
albeit less than HTTP.rb (looks like that it's just for the open
timeout), so I skipped it for now.

Then I looked at [async-http](https://github.com/socketry/async-http),
which was exciting - if everything is nonblocking, cancelling on a timer
is a non-issue (or even just raising an error like `Task.with_timeout`
does). But I had lots of trouble trying to port all the behavior I was
used to in HTTP.rb, with redirections, ssl options, headers, all that.
The API wasn't as ergonomic as I'd hoped [^3]. I tried using it with the
[Faraday adapter](), but I found out that I couldn't use Faraday for
entirely different, project-specific, reasons.

Next I checked out [httpx](https://github.com/HoneyryderChuck/httpx) on
a recommendation. It uses `IO.select` and even ships with its own
non-blocking DNS resolver (curse you `getaddrinfo`)! This filled me with
hope. The code was easy to read and the API super ergonomic. But, alas,
it doesn't provide a way to set a global timeout across redirects. This
is when I had an idea: I'll hack around this by manually checking the
elapsed time since the first request on each redirection, using the
`on_response_completed` callback. This worked surprisingly well! In the
worst case scenario it could take `2*timeout`, but it's good enough!

Except... Now the responses from the endpoints are different. httpx has
different semantics on what headers to send and what to do on redirects.
Admitedly, this is probably hard mode for http clients (yes the
endpoints I'm hitting are really that weird). Forget about timeouts if I
don't have semantic correctness.

This is when I went mad and starting clicking desperately on all http
clients I could find. [httpclient](https://github.com/nahi/httpclient)
uses `Timeout::timeout` as well... And
[httparty](https://github.com/jnunemaker/httparty) calls Net::HTTP...
[Excon](https://github.com/excon/excon) uses `IO.select` - yay!

But then I found [Typhoeus](https://github.com/typhoeus/typhoeus), a
wrapper around libcurl, which I know has a global timeout including
redirects (`--max-time` through the `curl` cli). I tried it out and it's
pretty simple, easy to use and does the right thing (of course, it's
`curl`)! So this seems to be the endgame, the ultimate solution for my
usecase today, at least from my testing so far.

So, is the conclusion that we should all just use cURL? Really?! A C
project started almost 30 years ago?!

Yes.

Tongue-in-cheek. But, in retrospect, it sounds obvious - cURL is
venerable and legendary. Lindy's law in effect! Of course though, pure
ruby gems have many advantages compared to ffi/native gems, not least of
which not randomly segfaulting [^4]. But we'll see how it goes for me
and curl wrappers.

Also, please burn `Timeout::timeout` with fire.

[^1]: I later found an imperfect but "good enough" solution to this
    using HTTPX, but it hadn't come to me at this time. Using the
    callbacks plugin, check the time elapsed since starting on each
    redirect and bail out if over the target.

[^2]: There seems to be a [timeout
    redesign](https://github.com/httprb/http/issues/773) coming for the
    next version, which sounds great!

[^3]: This is when it hits me that HTTP clients are SUPER non-trivial.
    You'd think making HTTP requests was easy. Yeah.

[^4]: Also, pure ruby gems work in async! A curl wrapper can't yield to
    the event loop since it's off in libcurl - which obviously isn't
    aware that we're running it in a fiber in an event loop!
