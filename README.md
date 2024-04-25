## A good way to use `systemd`

TLDR: Our systemd services should be of `Type=notify` and they should use the `sd_notify` API to tell systemd when they're properly started.  We can also use targets to start and stop ATARS (or a subset of its components) without rebooting.

### In this repo

`service.py` is a simple Python script that starts up, spends 6 seconds "initializing", then enters a loop.  `foo` and `bar` are symlinks to `service.py,` so they do the exact same thing (but with different names).

`foobar.target`, `foo.service`, `bar.service` are systemd unit files (they go in `/etc/systemd/system`)

- When the `foobar` target is started, it automatically starts `foo`.
- When `foo` is started, it performs its initialization and only then starts `bar`
- When `foobar` is stopped, both `foo` and `bar` are stopped automatically.

### The `sd_notify` part

Take a look in `foo.service`:

```
[Unit]
Description=foo
PartOf=foobar.target

[Service]
# Type=notify means that the service isn't considered "started" until
# it receives notification using the sd_notify API
# and any dependencies will be on hold until that happens
Type=notify
ExecStart=/home/ubuntu/sd_notify_test/foo

[Install]
WantedBy=foobar.target
```

And the chunk in `service.py` that performs the notification:

```
n = sdnotify.SystemdNotifier()
n.notify("READY=1")
```

You can find `sd_notify` on the [command-line](https://www.freedesktop.org/software/systemd/man/latest/systemd-notify.html), as well as in [C/C++](https://www.freedesktop.org/software/systemd/man/latest/sd_notify.html)


Here's the behavior before `sd_notify`
```
Apr 24 17:31:22 brimming-wigeon bar[9781]: INFO:bar:starting
Apr 24 17:31:22 brimming-wigeon foo[9780]: INFO:foo:starting
Apr 24 17:31:22 brimming-wigeon bar[9781]: INFO:bar:sleeping 6s for initialization
Apr 24 17:31:22 brimming-wigeon foo[9780]: INFO:foo:sleeping 6s for initialization
Apr 24 17:31:28 brimming-wigeon bar[9781]: INFO:bar:fully started
Apr 24 17:31:28 brimming-wigeon bar[9781]: INFO:bar:loop 0
Apr 24 17:31:28 brimming-wigeon foo[9780]: INFO:foo:fully started
Apr 24 17:31:28 brimming-wigeon foo[9780]: INFO:foo:loop 0
Apr 24 17:31:33 brimming-wigeon bar[9781]: INFO:bar:loop 1
Apr 24 17:31:33 brimming-wigeon foo[9780]: INFO:foo:loop 1
Apr 24 17:31:38 brimming-wigeon bar[9781]: INFO:bar:loop 2
Apr 24 17:31:38 brimming-wigeon foo[9780]: INFO:foo:loop 2
Apr 24 17:31:43 brimming-wigeon bar[9781]: INFO:bar:loop 3
Apr 24 17:31:43 brimming-wigeon foo[9780]: INFO:foo:loop 3
```

Here's the behavior after `sd_notify`

```
Apr 24 19:13:25 brimming-wigeon systemd[1]: Starting foo...
Apr 24 19:13:25 brimming-wigeon foo[11546]: INFO:foo:starting
Apr 24 19:13:25 brimming-wigeon foo[11546]: INFO:foo:sleeping 6s for initialization
Apr 24 19:13:31 brimming-wigeon foo[11546]: INFO:foo:fully started
Apr 24 19:13:31 brimming-wigeon systemd[1]: Started foo.
Apr 24 19:13:31 brimming-wigeon foo[11546]: INFO:foo:loop 0
Apr 24 19:13:31 brimming-wigeon systemd[1]: Starting bar...
Apr 24 19:13:31 brimming-wigeon bar[11547]: INFO:bar:starting
Apr 24 19:13:31 brimming-wigeon bar[11547]: INFO:bar:sleeping 6s for initialization
Apr 24 19:13:36 brimming-wigeon foo[11546]: INFO:foo:loop 1
Apr 24 19:13:38 brimming-wigeon bar[11547]: INFO:bar:fully started
Apr 24 19:13:37 brimming-wigeon systemd[1]: Started bar.
Apr 24 19:13:38 brimming-wigeon bar[11547]: INFO:bar:loop 0
Apr 24 19:13:42 brimming-wigeon foo[11546]: INFO:foo:loop 2
Apr 24 19:13:43 brimming-wigeon bar[11547]: INFO:bar:loop 1
```

This is correct!

### The dependency part

The trick here is to make our `systemd` dependency graph even stronger, such that if `A -> B` then when A starts, then B automatically starts.  When A dies, then B automatically dies.  If B dies, A lives on.

There are three directives we have to use to make this happen:

- `Unit/PartOf=` — use this directive in the child to indicate that it's part of a parent, and can't survive on its own
- `Unit/After=` — use this directive in the child to indicate that it must start after its parent (this isn't done automatically!)
- `Install/WantedBy=` - use this directive in the child to compel systemd to start the child when the parent is started.
