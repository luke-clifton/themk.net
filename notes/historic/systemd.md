---
title: systemd
---

Systemd is a replacement for the old init script. This is the
program that is launched when linux boots, and is the parent of
all other processes.

Systemd using the Linux kernel feature control groups (or `CGROUPS`)
to keep track of processes. This allows it to know when a program
has stopped, and it can then be restarted. This is more robust then
keeping and checking PID files or using `daemon-start-stop`. It is,
however, not portable.

## `systemd` Services

A `systemd` service is defined in a `.service` file. These files
live in `/usr/lib/systemd/system` or `/usr/lib/systemd/user`.

Important properties for the `.service` files for us are in
the `[Service]` section

    Restart=always
    BusName=name
    StartExec=/usr/bin/my_program
    Type=simple

and in the `[Install]` section it is often useful to define
an alias

    Alias=dbus-com.example.xyz.service

The name of the service is taken from the file name.

To start, stop and restart a service

    # systemctl start my_prog.service
    # systemctl stop my_prog.service
    # systemctl restart my_prog.service

To get the status of a service

    $ systemctl status my_prog.service

~~~
$ systemctl status annoy.service
annoy.service
   Loaded: loaded (/usr/lib/systemd/system/annoy.service; enabled)
   Active: active (running) since Mon 2013-10-21 13:50:02 WST; 48min ago
 Main PID: 19607 (python2)
   CGroup: /system.slice/annoy.service
           └─19607 python2 /home/lukec/test/pd/server.py

Oct 21 13:50:02 bardeen systemd[1]: Starting annoy.service...
Oct 21 13:50:02 bardeen systemd[1]: Started annoy.service.

~~~
and to enable or disable a service from starting automatically
at boot or being activated by `systemd` in other ways (such
as DBus activation or socket activations

    # systemctl enable my_prog.service
    # ssytemctl disable my_prog.service

To take a look at the log file for a particular service do

    journalctl -u example.service

Or if you are on a really old system

    journalctl _SYSTEMD_UNIT=example.service


