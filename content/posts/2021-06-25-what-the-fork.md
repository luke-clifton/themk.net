---
title: What the Fork!?
---

*sigh*

What do you do when you want fork a program? What do you think is right?

## File Descriptors

Do you close all file descriptors except ones that are passed in
explicitly when you fork a process? You probably should. If you
accidentally inherit a file descriptor and don't close it, it, well.. it
never closes (until you and all your children die). The OS can't free
the `inode`, and processes waiting for the handle to be closed will wait
for you to die. Also, you are giving the child permission to read or
write files you might not want it to. Ever used `<(cmd)` to get a secret
into a program?

Ok. So you close all file descriptors. But.. how do you know which file
descriptors to close? Maybe your caller set some environment variable to
a file descriptor and your child will want to use it, or passed in as an
argument (e.g. using bashes process substitution `<(cmd)`).

Solution: make sure you set `CLOEXEC` on all file descriptors that you
don't want to be inherited when they are created. Unfortunately, your
libraries probably won't do this. Double unfortunately, on some
operating systems it is impossible to atomically create a file
descriptor and set `CLOEXEC` (*cough* macOS *cough*). So if you use
threads (or any of your libraries do), you are even more out of luck.

You might be tempted to scan your environment and args for things that
might look like file descriptors, and then not close those ones. But you
will probably run into false positives. File descriptors are usually
lowish numbers which could commonly crop up for a variety of reasons.

The best approach is probably to not close file descriptors, and to
open, and set `CLOEXEC` on any that you will need as early as possible,
before there is any chance of spawning threads that might ruin your day.
You may also want to avoid threads. Or at least, avoid creating file
descriptors or forking from threads. And keep a keen eye on your
dependencies. Good luck.

## What to do after the fork?

Do you do anything after a fork? You probably should not. It would be
wise to stick to the list of functions documented in
[`man 7 signal-safety`](https://man7.org/linux/man-pages/man7/signal-safety.7.html).
Sure, this is not a signal handler, but we are actually under the same
constraints. That is, we are in a state where any number of locks might
be being held by threads that are no longer going to run. So, even
calling `malloc()` may hang the child. Don't use threads? You are
probably OK. Just make sure none of your libraries do (or ever will)!

Want to read `/proc/self/fd` to know which file descriptors to close?
Too bad, `opendir` is not in the list of safe functions to use.

## What do you do with SIGINT?

[I'll just leave this here](https://www.cons.org/cracauer/sigint.html)

## Conclusion

*sigh*
