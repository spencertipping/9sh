# 9sh liability
Most distributed systems implicitly define liability using process: replication policy, ack semantics, and, critically, a commitment to store data in place without moving it. 9sh treats liability as a first-class concept and encodes it in the type system.


## User acknowledgement
User interfaces are written with user-oriented liability in mind, but we don't often formalize it. For example, the user must dismiss a modal popup, proving that they saw it. That mechanism forces the user to `ack` the message, whether or not they fully understood it. (For comprehension, messages tend to have specific `ack` instructions: "type the name of the thing you're trying to delete".)

Slack's read/unread message state is also a form of liability: it doesn't obligate the user to do any specific thing, but it repeats the message until the user satisfies its heuristics that the message has been read.


## Polymorphism
Let's consider Slack as an example: arguably "make sure everyone explicitly acknowledges this specific message" is a missing feature. The approximation tends to be `@here drop :thumbs-up: when you've done this`, but the system doesn't track outstanding liability for you, nor does it hold the message in the user's unread queue until they've acked it. Slack's liability model is monomorphic: no message metadata influences its interaction with the read/unread system.

9sh liability types are similarly monomorphic, but because you can write your own types, you can define a monomorphic agreement about polymorphic acknowledgement behavior. This allows you to have a stream that mixes message importance. The important thing isn't that every message is treated the same way, it's that the sender and receiver _agree_ about how each message is treated. From 9sh's perspective, that agreement is itself the liability transfer.
