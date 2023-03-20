# AoC 2022: day 3, profiling Go, existential crisis

###### 2022/12/03

Ok hi! One of my first projects ever was a [blog written in python
flask](https://github.com/pineman/code/tree/main/old_proj/pineblog)
(please don't look at it, it was 2015). Even though I shut it down a
couple of months after having it up on my server (a VPS at the time), my
admiration for blogging didn't stop and, of course, I read a bazillion
blog posts since then. But now, here we are, finally! My own tech blog,
v2.0. Just some flat hand-made HTML files to start this time, maybe some
templating soon, then we'll see. I'm also deliberately putting only a
medium amount of effort on this writing, at best, otherwise I'll end up
not writing anything. Trying to keep it real simple, so my brain thinks
it's easy and does it. I'll take this opportunity to share some of my
favorite blogs, from people I admire (this excludes of course eng. blogs
from companies like netflix, dropbox, twitter, cloudflare, ...):

- <https://jvns.ca/>
- <https://rachelbythebay.com/w/>
- <https://www.brendangregg.com/blog/>
- <https://martin.kleppmann.com/archive.html>
- <http://dtrace.org/blogs/bmc/>

But onwards to today's topic!

So this year I'm yet again trying to follow through on Advent of Code,
instead of... forgetting about it on day two, as with the past
*whatever* years. As I read [day three's
statement](https://adventofcode.com/2022/day/3), I immediately thought
of the "obvious" O(n^2) solution: for each item in the first
compartment, check if it's in the second compartment - on the first hit,
sum its priority and break (this description is almost executable python
of course, but I'm solving this year entirely in Go for now).

So here's the problem, and why I'm writing this: I promptly decided not
to implement this solution, without a second more of consideration. My
intuition always steers away from O(n^2), as it's usually the fastest
(slowest?) way to fail an interview problem. So I wanted to be smarter.
And, for some reason, my intution also thinks sets are really smart
(probably from solving leetcode in python, plus hash tables are
amazing). So, a-ha, idea: build a set for each compartment, and
intersect them. Building a set should be O(n), intersecting them should
be linear as well [^1], and voilà! Linear time without "ugly" for loops
(... in python, which I guess is my brain's default language). So I
eagerly went along, and implemented my set-based solution (in Go, which
doesn't have sets in the stdlib, which I just found out). Turns out that
in part two, I had to implement a three-way set intersection, which I
solved by refactoring my intersection function to be more generic and
chaining calls to it. Annoying, but I did it.

I suspect by now everyone sees the problem with this reasoning, that of
course I didn't at the time. **The big-oh justification I just wrote is
all wrong!** Maybe not in a theoretical sense, but in a practical sense
(but probably in a theoretical sense as well): this problem is so
simple, its volume of data so small and well crafted, that just the map
overhead is overwhelming! Or, at least, cpu time complexity is not the
whole story, because I didn't even think about memory access! Or yet
some other reason I clearly missed! Because here's the proof: using a
bigger input [^2], and using `go test -bench`, my set solution takes
5.42 seconds to solve part two (not counting reading the input file and
turning it into an array of string), while the 'naive', 'dumb', more
procedural solution runs in 139ms (more on this solution later). That's
a \~39x speedup (!!). And that's pretty slow: I saw some rust and C++
going at just \~10ms for part two, another order of magnitude faster.
So, I took this opportunity to profile my Go code. Find all my (bad)
code
[here](https://github.com/pineman/AoC2022/blob/main/2022/day3/three.go#L48).

### Profiling for fun

These are the resources I followed:
<https://jvns.ca/blog/2017/09/24/profiling-go-with-pprof/> and
<https://go.dev/blog/pprof> (in fact, the first half of this latter link
describes exactly the problem I had: using a map when an array is
sufficient). Of course, my code today is contrived and basically holds
no mystery. But nonetheless, all I had to do was run `go test -bench`
with the `-cpuprofile` and `-memprofile` flags, as I already had
benchmark functions in my test file. This produces output files that
`go tool pprof` can read and then generate output in text, or even png
or pdf. Here's the cpu time breakdown, generated with
`go tool pprof -top -cum cpu.out`, for part two only (truncated):

``` plaintext
     flat  flat%   sum%        cum   cum%
        0     0%     0%      5.50s 84.23%  github.com/pineman/code/chall/aoc2022/go/day3.Benchmark_partTwoBigBoy_set
        0     0%     0%      5.50s 84.23%  testing.(*B).run1.func1
        0     0%     0%      5.50s 84.23%  testing.(*B).runN
    0.03s  0.46%  0.46%      5.38s 82.39%  github.com/pineman/code/chall/aoc2022/go/day3.partTwo_set
    0.30s  4.59%  5.05%      3.83s 58.65%  github.com/pineman/code/chall/aoc2022/go/day3.itemMap (inline)
    1.54s 23.58% 28.64%      3.67s 56.20%  runtime.mapassign_fast32
    0.07s  1.07% 29.71%      1.37s 20.98%  github.com/pineman/code/chall/aoc2022/go/day3.intersectMap (inline)
        0     0% 29.71%      1.09s 16.69%  runtime.systemstack
```

From the cumulative column, it looks like `itemMap` and `intersectMap`
were on the stack 59% and 21% of the time, respectively, to the shock of
no one. Just building maps and iterating through them away, heating my
house. Imagine all the hashing and pointer chasing... Well, here's the
memory profile:

``` plaintext
     flat  flat%   sum%        cum   cum%
        0     0%     0%  2395.03MB 99.69%  github.com/pineman/code/chall/aoc2022/go/day3.Benchmark_partTwoBigBoy_set
        0     0%     0%  2395.03MB 99.69%  testing.(*B).run1.func1
        0     0%     0%  2395.03MB 99.69%  testing.(*B).runN
        0     0%     0%  2144.65MB 89.27%  github.com/pineman/code/chall/aoc2022/go/day3.partTwo_set
1986.64MB 82.69% 82.69%  1986.64MB 82.69%  github.com/pineman/code/chall/aoc2022/go/day3.itemMap (inline)
        0     0% 82.69%   250.38MB 10.42%  github.com/pineman/code/chall/aoc2022/go.GetBigBoyInput
 100.66MB  4.19% 86.88%   250.38MB 10.42%  github.com/pineman/code/chall/aoc2022/go.getInput
 112.01MB  4.66% 91.55%   112.01MB  4.66%  github.com/pineman/code/chall/aoc2022/go/day3.intersectMap (inline)
 100.66MB  4.19% 95.74%   100.66MB  4.19%  os.ReadFile
        0     0% 95.74%    49.07MB  2.04%  strings.Split (inline)
  49.07MB  2.04% 97.78%    49.07MB  2.04%  strings.genSplit
     46MB  1.91% 99.69%       46MB  1.91%  github.com/pineman/code/chall/aoc2022/go/day3.getFirstKey (inline)
```

Is that... 2GB **just** in maps? Is this right?... Oh god... The input
file is 100MB, as noted by `getInput`! I think I've had quite enough of
this embarrassment. For comparison, heres the cpu and mem profiles of
the 'procedural' version:

``` plaintext
     flat  flat%   sum%        cum   cum%
        0     0%     0%      3.18s 93.26%  github.com/pineman/code/chall/aoc2022/go/day3.Benchmark_partTwoBigBoy
        0     0%     0%      3.18s 93.26%  testing.(*B).runN
    0.60s 17.60% 17.60%      2.92s 85.63%  github.com/pineman/code/chall/aoc2022/go/day3.partTwo
        0     0% 17.60%      2.87s 84.16%  testing.(*B).launch
    0.16s  4.69% 22.29%      2.30s 67.45%  strings.ContainsRune (inline)
    0.39s 11.44% 33.72%      2.14s 62.76%  strings.IndexRune
    0.12s  3.52% 37.24%      1.80s 52.79%  strings.IndexByte (inline)
    1.54s 45.16% 82.40%      1.54s 45.16%  indexbytebody
```

``` plaintext
     flat  flat%   sum%        cum   cum%
        0     0%     0%   250.88MB 97.64%  testing.(*B).run1.func1
        0     0%     0%   250.88MB 97.64%  testing.(*B).runN
        0     0%     0%   250.38MB 97.44%  github.com/pineman/code/chall/aoc2022/go.GetBigBoyInput
 100.66MB 39.17% 39.17%   250.38MB 97.44%  github.com/pineman/code/chall/aoc2022/go.getInput
        0     0% 39.17%   250.38MB 97.44%  github.com/pineman/code/chall/aoc2022/go/day3.Benchmark_partTwoBigBoy
 100.66MB 39.17% 78.34%   101.16MB 39.37%  os.ReadFile
        0     0% 78.34%    49.07MB 19.10%  strings.Split (inline)
  49.07MB 19.10% 97.44%    49.07MB 19.10%  strings.genSplit
```

Nothing much to say here. 70% of time comparing characters, which is the
core of what we want to do, anyway, and not much extra memory
consumption compared to the input file size. For extra fun, here's the
svg files `pprof` can generate, for the slow version:
[cpu](assets/profile001.svg), [mem](assets/profile002.svg); and for the
fast version: [cpu](assets/profile003.svg), [mem](assets/profile004.svg)

### Conclusion

["Make it work. Make it right. Make it
fast."](https://wiki.c2.com/?MakeItWorkMakeItRightMakeItFast) - I know
this! Normally I'd like to think I do this (or, at least, when 'making
it work' doesn't involve a huge amount of tech debt I guess). Also:
measure before you optimize! Performance assumptions are sometimes hard
to make out of intuition. Also also: [something something premature
optimization](https://wiki.c2.com/?PrematureOptimization) (I love
computer science quotes). **SO WHY DIDN'T I DO THIS FROM THE START?**
Why did I chase "full generality" just for the sake of it? I have no
answers for you, dear reader. It might even be an unconfortable answer
for me. I'm half blaming it on [mental
priming](https://en.wikipedia.org/wiki/Priming_(psychology)), and the
fact that I'm using AoC2022 to learn Go (after "learning Go" twice in
the last three years) - so it makes sense to implement more things, in
more generality, to learn more about the language; and indeed I did that
for day one and two, even though I couldn't resist the temptation of
writing a [one liner in python for day
one](https://github.com/pineman/aoc/blob/main/2022/day1/python/one_oneliner.py).
Still, it hurts a little... But that's not all.

When I finish solving a day, I go and browse other people's solutions to
compare to mine. I open an image with maybe 30 lines of code. As I read
it, I realize: hey, this is exactly the same as my solution, but taking
out all the set logic! It's even well commented. Instead of building a
set for each compartment and then intersecting them, just directly check
if each item of the first is in the second and third. "Right, I thought
of this solution. It even looks exactly the same as mine, bar two lines
of code", I said to myself, half proudly still. "It's gotta be slower".
So I implement it. And it's faster. 39x faster. And this is the real
kick in the teeth: **the solution I was looking at was written by
[ChatGPT](https://openai.com/blog/chatgpt/)**. At first I didn't know
how to feel. Some thirty minutes in, and I find my solution is stupid
and completely obliterated by an AI that took just 2 seconds to do it...
Welp, after [reading up more on
ChatGPT](https://news.ycombinator.com/item?id=33847479), I'm convinced
it won't put me out of a job just yet, or even next year. But in the
next 10, 20 years?... I'm much more anxious.

[^1]:
    Assuming lookup is O(1)... approximately. Of course, it's more
    like amortized cost - in a terrible hash table (or just a terrible
    day or input) buckets are arrays, and using a terrible hash function
    all items end up in the same bucket, so the cost starts to look a
    lot more like O(n) due to linear searches, and intersection goes
    more like O(n^2) (maybe O(nlg n) using un-sorted trees). I bet all
    of this is wrong though.

[^2]:
    People on... the internet... usually craft these so-called 'big
    boy' inputs. [Here's the one I
    used](https://github.com/pineman/AoC2022/blob/main/2022/input/3/bigboy.7z).
