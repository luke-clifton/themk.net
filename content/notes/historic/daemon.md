---
title: Daemons in init
---

> See systemd note for details on how to do this with systemd

A proper daemon would do a lot of work to make sure that it is the
only one running, to make sure that it forks and does all the proper
daemony things, but you can cheat a lot by using a program called
`start-stop-daemon`.

Simply write a regular program and make an init.d script that starts it
and stops it like this

    start-stop-daemon --start --exec python \
        --startas /home/root/sampler/sampler.py \
        --make-pid --pidfile /path/to/sampler.pid -b

The `--start` tells it to start it, the `--exec` option says that the program
that is started will be an instance of python (to find out what you should
put here, start your program normally, determine its PID (with `ps`) and
do an

    ls -l /proc/<pid>/exe

This will show you what is really being run (e.g. `/usr/bin/python`))
The `--startas` options tells it which command to run to start the process.
`--make-pid` tells it to make a pid-file which it will use later on to see
if the process is still running. `--pidfile` tells it where to put the pidfile
and `-b` tells it to "background" the task.

To stop use

    start-stop-daemon --stop --exec python --pidfile /path/to/sampler.pid

This process will ensure that only a single instance of your program is running
at any given time (it uses the PID file and the value of `--exec` to know
whether or not your program is running).

Have a look at the example `init.d` script that launches a python script
as a daemon
