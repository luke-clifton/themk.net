---
title: D-Bus Overview
---

The D-Bus daemon has multiple instances, specifically a session and
system instance. The system instance is for all things at all times,
while the session instance is for login sessions.

For embedded systems, we would tend to want system sessions,
as we are usually looking at global events.

D-Bus has the concept of an address on the bus. This has to be a unique
name. It is usually a reverse DNS to ensure uniqueness.

    com.example.xyz

A single program can register such an address with the bus. It can then
register objects in a hierarchy at that address. Each object must be contained
within (or actually be) the root object designated by `/`. Essentially
this means object names have to start with a `/`.

    /com/example/xyz/manager
    /com/example/xyz/sensor/yy

Each of these objects can implement an interface

    com.example.xyz.manager
    com.example.xyz.sensor

These interfaces can define a set of methods. e.g.

    GetInfo()
    GetReading()

Which are usually referred to prefixed with their interface name

    com.example.xyz.manager.GetInfo
    com.example.xyz.sensor.GetReading

When calling a method (which is done by sending a message) you need
to supply the destination (`com.example.xyz`), the Object name
(`/com/example/xyz/manager`) and the complete method name (including
the interface) (`com.example.xyz.manager.GetInfo`).

What follows is an example of using the command line tool `dbus-send`
to call a method

    dbus-send --print-reply --system --dest=com.example.xyz \
      /com/example/xyz/manager com.example.xyz.manager.GetInfo

or

    dbus-send --print-reply --system --dest=com.example.xyz \
      /com/example/xyz/sensor/yy com.example.xyz.sensor.GetReading


Many binding let you create a proxy object.

#### Client
``` python
import dbus

# Get the system bus
bus = dbus.SystemBus()    # as opposed to SessionBus()

# Find on that bus, at the address 'com.example.xyz' the
# object '/com/example/xyz/manager'

obj = bus.get_object('com.example.xyz', '/com/example/xyz/manager')
# And then get the particular interface of that object
interface = dbus.Interface(obj, 'com.example.xyz.manager')

print interface.GetInfo()
interface.SetInfo("Huzzah! D-Bus!")
print interface.GetInfo()
```
#### Server
~~~ {.python}
import dbus
import dbus.service
import gobject

# Most binding use either glib (gtk) or qt or ev for the event loop
from dbus.mainloop.glib import DBusGMainLoop

class MyUsefulDbusClass(dbus.service.Object):
    def __init__(self):
        self.info = "Some Info"

        # Inconsistent terminology here. BusName does not refer to the bus (as in
        # session vs system), but to the address on the bus. So this is registering
        # a new address on the System bus.
        bus_name = dbus.service.BusName('com.example.xyz', bus = dbus.SystemBus())

        # And this is registering an object
        dbus.service.Object.__init__(self, bus_name, '/com/example/xyz/manager')

    # This decorator is used to say that this object implements
    # the com.example.xyz.manager interface, and that interface
    # has a function named GetInfo
    @dbus.service.method('com.example.xyz.manger') # (3)
    def GetInfo():
        return self.info

    @dbus.service.method('com.example.xyz.manager')
    def SetInfo(new_info):
        self.info = new_info

DBusGMainLoop(set_as_default=True)

service = MyUsefulDbusClass()

loop = gobject.MainLoop()
loop.run()
~~~

But wait... you still won't be able to use this.. D-Bus has a security mechanism
so that not anyone can just go and put any old service up.

## Security

The d-bus system relies heavily on commonly known names to provide
services to other applications, so anyone who can register a service
could take one of these names and other programs on the bus would not
know. In order to allow yourself to do stuff on the bus take a look at
`/etc/dbus-1/system.d/`. All the files in here specify who is allowed to
do what.

The basic idea is that you set a policy for a certain set of users, and
then you set up `<deny>` and `<allow>` blocks which match against a bunch
of rules. All of the rules inside a particular `<deny>` or `<allow>` block
need to match. The rules are attributes of the tags.

~~~ {#policy .xml}
<policy user="root">
    <!-- Policy definition for root user-->
    <allow rule1="blah" rule2="blahblah"/>
    <allow own="com.example.xyz"/> <!-- Allows root to own this address -->
    <!-- Allow root to send messages to this address and interface combination -->
    <allow send_destination="com.example.xyz"
           send_interface="com.example.xyz.manager">
</policy>
~~~

What follows is the default security policy. You need to punch holes in
it to allow your service to be used and registered.

~~~ {#policy_default .xml}
<policy context="default">
  <!-- All users can connect to system bus -->
  <allow user="*"/>

  <!-- Holes must be punched in service configuration files for
       name ownership and sending method calls -->
  <deny own="*"/>
  <deny send_type="method_call"/>

  <!-- Signals and reply messages (method returns, errors) are allowed
       by default -->
  <allow send_type="signal"/>
  <allow send_requested_reply="true" send_type="method_return"/>
  <allow send_requested_reply="true" send_type="error"/>

  <!-- All messages may be received by default -->
  <allow receive_type="method_call"/>
  <allow receive_type="method_return"/>
  <allow receive_type="error"/>
  <allow receive_type="signal"/>

  <!-- Allow anyone to talk to the message bus -->
  <allow send_destination="org.freedesktop.DBus"/>
  <!-- But disallow some specific bus services -->
  <deny send_destination="org.freedesktop.DBus"
        send_interface="org.freedesktop.DBus"
        send_member="UpdateActivationEnvironment"/>
</policy>
~~~

#### Example policy configurations

~~~ {.xml}
<?xml version="1.0"?> <!--*-nxml-*-->
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
"http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">

<!-- Policy to allow root to start the service, and anyone to use ALL
     the methods in it. -->
<busconfig>

    <policy user="root">
        <allow own="com.example.xyz"/>
    </policy>

    <policy context="default">
        <allow send_interface="com.example.xyz.manager"
               send_destination="com.example.xyz"/>
        <allow send_interface="org.freedesktop.DBus.Introspectable"
               send_destination="com.example.xyz"/>
    </policy>

</busconfig>
~~~
~~~ {.xml}
<?xml version="1.0"?> <!--*-nxml-*-->
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
"http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">

<!-- Policy that only allows root to start a server and run methods -->
<busconfig>

    <policy user="root">
        <allow own="com.example.xyz"/>
        <allow send_interface="com.example.xyz.manager"
               send_destination="com.example.xyz"/>
        <allow send_interface="org.freedesktop.DBus.Introspectable"
               send_destination="com.example.xyz"/>
    </policy>

</busconfig>
~~~
~~~ {.xml}
<?xml version="1.0"?> <!--*-nxml-*-->
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
"http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">

<!-- Policy to allow root to own and do everything, and let anyone only access the
     GetInfo method and the introspectable interface -->
<busconfig>

    <policy user="root">
        <allow own="com.example.xyz"/>
        <allow send_interface="com.example.xyz.manager"
               send_destination="com.example.xyz"/>
        <allow send_interface="org.freedesktop.DBus.Introspectable"
               send_destination="com.example.xyz"/>
    </policy>

    <policy context="default">
        <allow send_interface="com.example.xyz.manager"
               send_destination="com.example.xyz"
               send_member="GetInfo"/>
        <allow send_interface="org.freedesktop.DBus.Introspectable"
               send_destination="com.example.xyz"/>
    </policy>

</busconfig>
~~~

## Auto-starting (D-Bus Activation)

Auto starting a dbus service only when it is needed is possible.
You will need to create both a dbus.service file and a systemd.service
file.
Take a look in `/usr/share/dbus-1/system-services/` and
`/usr/lib/systemd/system/`

You will need to enable your systemd service before it will be
automatically started by systemd

    sudo systemctl enable my_service.service

and you have to make sure the dbus.service file points to the systemd
service.

