# 9sh actors
9sh actors are [VFS](vfs.md)-scoped accessors to [cylinders](cylinders.md), generally prefixed with `@`. Actors are often processes, but they can also be pipes to other users, remote endpoints, or any other thing you might interact with.

Actors live in `///act` and participate in shell grammar. As commands, each actor defines its own parse continuation:

``` sh
$ @foo bar bif     # invoke the actor with args
$ @py 3 | 4        # @py's parser maps | to Python bitwise-or
$ @foo < file      # send it a file
$ @foo > file      # read from the actor
$ cat file | @foo  # pipe things to it
$ cd @foo          # cd into it
$ kill @foo        # request that the actor be terminated
$ rm @foo          # delete the actor
```

**Cylinders are never public;** any public access is mediated by an actor. You can publish an actor on the P2P WebRTC mesh by linking it into an endpoint:

**TODO:** split `///mesh` to differentiate between "I'm publishing" and "I'm subscribing". Claude came up with this mesh concept and it lacks nuance.

``` sh
$ mkdir ///mesh/endpoint     # create an endpoint
$ ln @foo ///mesh/endpoint/  # publish @foo to that endpoint
$ cat ///mesh/endpoint/sdp   # get the SDP connection string
```

If Alice gives her SDP to Bob, Bob can connect to it:

``` sh
bob$ cat alice-sdp > ///mesh/alice  # establish a connection
bob$ cat ///mesh/alice              # check connection state
bob$ @alice.foo hi there            # interact with ///mesh/alice/@foo
```

**NOTE:** permissions are determined by the actor, not by aspects of the endpoint connection. Specifically, Alice can test Bob's permissions by interacting with her own `///mesh/endpoint/@foo`. If Alice can do something with that object, Bob can do it too.


## Actor events
`$PWD` subscribes to all in-scope actors for event updates, which are then printed to the terminal with attribution. This allows actors to say things to the user; for example:

``` sh
$ @alice.foo you there?
[@alice.foo] yep, we're connected
```

The default subscription is mechanically `tail -f @actor | sed -r "s/^/[$ACTOR] /"` or similar, but `$PWD` may choose select something else. Subscriptions also transfer [liability](liability.md) to track read/unread messages.


## Broadcast channels
Channels are just actors prefixed with `#` instead of `@`. Like `@` actors, `#` channels are also cylinders.
