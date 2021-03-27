---
title: USB and Linux
---

## Which device am I using?

Use udev rules to SYMLINK a device based on its USB parameters.
Usually link to `/dev/modem` or `/dev/angle_encoder` etc.

Rules can be based on anything in

    udevadm info -a -n ttyUSB1

with the only rule being you can only look at the values from the
main device and a single (any) parent.

Rules are written into `/etc/udev/rules.d/10-local.rules`
The 10 makes it more important than the default rules (which I think
have a priority of 50). The `.rules` ending is required.

For example, to get the Sierra module working, and always mounting the
modem port at `/dev/modem` I used the rules

    DRIVERS=="sierra", ATTRS{bInterfaceNumber}=="02", SYMLINK+="modem"

The Sierra module brings up 4 interfaces (which can bee seen in `dmesg`)
and you had to guess and check to figure out which interface number
the correct one corresponded to. Once you knew which `/dev/ttyUSB*`
corresponded to the modems communication channel you had to do a

    udevadm info -a -n ttyUSB1
    udevadm info -a -n ttyUSB2
    udevadm info -a -n ttyUSB3
    udevadm info -a -n ttyUSB4

and check the differences.

Once the rules are established any device plugging/unplugging should
see those rules. But do see the next section.

## My udev rules don't work on boot!

Currently udev starts AFTER the devices have been registered by the kernel.
You can make udev rerun all its rules with this

    udevadm trigger

For SECRET_PROJECT_E I have added an init.d script that runs really late in the
boot process and simply calls that. Ideally we should make udev start
earlier. I don't know how to do this yet.

## My USB device is frozen?!

Each usb device should have a entry in `lsusb`. Look for the fields that
look like

    1d6b:0002
    0458:0007
    0403:6001

The first number is the vendor id, the second is the product id.

You can restart a usb device by using usb_modeswitch

    usb_modeswitch -R -v <vendor_id> -p <product_id>

I don't know if you can distinguish between multiple identical products
that are plugged in.


