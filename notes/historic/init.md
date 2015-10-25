---
title: init.d
---

A different system found in many distributions these days is `systemd`.

`init.d` is what is used to start and stop daemons and to also run scripts
at boot time.

Scripts in `init.d` take a single argument. This argument can be one of
`{start|stop|restart|status}` or a few others. The only ones you need
to implement really are `start` and `stop` (and restart, which is trivial).

Copy other `init.d` scripts.

If it's a daemon use the `start-stop-daemon program` (see daemon.md)

You can now use

    /etc/init.d/my_script start
    /etc/init.d/my_script stop

to control your daemons.

This is also how you restart system daemons like cron or ntp.

## Why aren't my scripts running at boot?

Two reasons common.

1. When you run the script manually the script is executed with your PATH
   variable. However, when the script is run at boot it uses a different
   PATH variable which probably isn't what you want it to be. Set PATH
   at the top of your script.

2. You didn't install it. Use
        
        update-rc.d my_script defaults
    
   to install the daemon at all the default run-levels (run levels are
   different modes of booting Linux, you can see which run level you are
   currently booted with `runlevel`). It will also install the proper
   scripts to stop the daemon during shutdown (eg it will call

        /etc/init.d/my_script stop

   when shuting down)

#### Example Startup Script
~~~ {.bash}
#!/bin/sh

# Human readable name
NAME="Service Name"

# Where to store the pid file
PIDFILE=/path/to/service.pid

# Name of the program to launch
PROGRAM=/path/to/service.py

# exec argument to start-stop-daemon
EXEC=python

startdaemon(){
    echo -n "Starting $NAME: "

    if start-stop-daemon --start --exec $EXEC --startas $PROGRAM --make-pid --pidfile $PIDFILE -b -q; then
        echo "done"
    else
        echo "already running... did you mean restart?"
    fi
}

stopdaemon(){
    echo -n "Stopping $NAME: "
    if start-stop-daemon --stop --exec $EXEC --pidfile $PIDFILE -q; then
        echo "done"
    else
        echo "nothing to stop"
    fi
}

case $1 in
    start)
        startdaemon
        ;;
    stop)
        stopdaemon
        ;;
    restart)
        stopdaemon
        sleep 2
        startdaemon
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        ;;
esac
~~~
