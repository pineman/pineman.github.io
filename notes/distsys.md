https://news.ycombinator.com/item?id=48765639
"if you have a db and a message queue, how do you get your update to alter both or neither (i.e. transactionally)"
stricly speaking, as worded, it hints towards 'exactly once' semantics, which you can't get in distributed systems - so the answer is no (note: you can use XA/2PC I guess if supported).
but obviously, a more productive answer is "what are you trying to do?".
in most cases, "at most once" (booking airplanes (i think) => sagas) or "at least once" (pumps => email reveals) semantics are good enough.

> Outbox's power is that it turns an atomicity problem into an idempotency problem. You atomically write to the outbox, then you have an idempotent "workflow" that processes events from the outbox. This turns "at most once" semantics (where an event could be dropped entirely) to "at least once" semantics (where the event processing could run multiple times). For many systems, that's a big improvement.
