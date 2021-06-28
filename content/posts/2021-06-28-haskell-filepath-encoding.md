---
title: FilePath encoding in Haskell
---

There are a lot of articles on the internet about the various string
types in Haskell. There is, in particular, a lot of hate for the
`String` type.

``` {.haskell}
type String = [Char]
```

But today I want to talk about `String`s close relative,
[`FilePath`](https://hackage.haskell.org/package/base-4.15.0.0/docs/System-IO.html#t:FilePath).

``` {.haskell}
type FilePath = String
```

A lot of people have the wrong idea about `FilePath`. Even many
otherwise excellent resources on Haskell blunder the introduction.

> FilePath is just a type synonym for String
>
> -- Learn You a Haskell

> FilePath is simply another name for String.
>
> -- Real World Haskell

> FilePath is a type synonym for `String`. So, for instance, the
> `readFile` function takes a `String`.
>
> -- wikibooks.org/wiki/Haskell

For the longest time, I always treated the `FilePath` synonym as a hint
to the user that this particular `String` is meant to be a file path. I
was also always annoyed by the fact that file paths are not really
`String`s on unix platforms. They are arbitrary sequences of non-0
bytes. How do you refer to the file with an invalid unicode name?

So what gives? Do Haskellers just run around assuming that all filenames
are Unicode, and we all live on some perpetual happy path? This was
deeply unsatisfying for me. I spent a lot of time messing around with
the `System.Posix.ByteString` library instead, in a hope to be able to
work outside of those happy path assumptions. But I was wrong.

The documentation gives a hint that there is more to it, though it is
subtle.

> File and directory names are values of type `String`, whose precise
> meaning is operating system dependent.

While it never explicitly says this, what it means is that `FilePath`
types have a special encoding that is operating system dependent. In
particular, a `FilePath` value uses the [file system
encoding](https://hackage.haskell.org/package/base-4.14.0.0/docs/GHC-IO-Encoding.html#v:getFileSystemEncoding).
From the documentation for `getFileSystemEncoding`:

> The Unicode encoding of the current locale, but allowing arbitrary
> undecodable bytes to be round-tripped through it.

That answers one question: we can ship arbitrary bytes through a
`FilePath`. For non-windows platforms, the (probably internal) details
for this is that it uses "UTF-8b", which uses "surrogate escaping" to
embed arbitrary bytes in the stream. Surrogates are Unicode code points
that are illegal in UTF-8 streams. They are `Char` values in the range
of `0xD800` to `0xDBFF` and `0xDC00` to `0xDFFF`. What the UTF-8b
encoding does is, upon encountering an invalid UTF-8 byte, it emits the
raw byte bit-wise-`AND`ed with `0xDC00`. So we get a totally valid
stream of `Char`s out. The trick is to undo this on the other end. And
indeed, every single function (in `base`) that takes a `FilePath` will
undo this encoding, and the exact same bytes will come out the other end
as came in. If you write a function that takes a `FilePath`, you better
be doing this as well!

This encoding scheme has some pretty important consequences. In
particular, `bytestring` and `text` libraries provide no mechanism to
either create or consume `FilePath`s, while they both provide the same
for `String`. Do not be fooled! `String` is not `FilePath`! You can NOT
use `Data.Text.pack` on a `FilePath`. It will give you incorrect
results! You can not use `Data.ByteString.Char8.pack` on a `FilePath`!

Even within `base` you can't treat `FilePath` the same as `String`. You
can NOT (by default) use `putStrLn` on a `FilePath`. You can not (by
default) use `getLine` to read a `FilePath`. `putStrLn` expects a
`String` and will not perform the required decoding when dealing with a
`FilePath`. You will not be able to read arbitrary byte sequences with
`getLine`, and thus can't read newline (or, more robustly, `\NUL`)
terminated file names from `stdin` without hitting the dreaded

    hGetLine: invalid argument (invalid byte sequence)

on funny file names.

If you do want to use these with `FilePath`s instead of `String`s, you
will need to tell GHC to do so by using `hSetEncoding` on the relevant
handles and setting the encoding to the file system encoding.

Be aware that using `ByteString` IO, as is often recommended, will not
save you. You can not convert a `ByteString` to a `FilePath`, at least
not in a way supported by the `bytestring` package.

What about FFI? Well, do NOT use `Foreign.C.String` to marshal
`FilePath`s. That module is for `String`s only! The functions in that
module use the locale encoding, not the file system encoding. You want
to use the functions in
[`GHC.Foreign`](https://hackage.haskell.org/package/base-4.14.0.0/docs/GHC-Foreign.html),
and provide them with the correct `TextEncoding` (probably the one you
get when you query
[`getFileSystemEncoding`](https://hackage.haskell.org/package/base-4.14.0.0/docs/GHC-IO-Encoding.html#v:getFileSystemEncoding)).

You can also use `GHC.Foreign` to construct and deconstruct a
`ByteString` if you are using a library that has made the misguided, but
probably well-meaning, decision to accept or supply `ByteString`s for
file names. Do this by composing `GHC.Foreign.newCStringLen` with
`Data.ByteString.Unsafe.unsafePackMallocCStringLen` and
`GHC.Foreign.peekCStringLen` with `Data.ByteString.useAsCStringLen`.
Note: The functions in the `GHC.Foreign` module accept `String`s, but
here it is OK because they also accept the `TextEncoding`.

And finally, `getArgs` is the mischievous rule breaker here. By default,
on non-windows systems, `argvEncoding` is the same as the file system
encoding. So, when you use `System.Environment.getArgs` on Unix systems,
you are actually getting a `[FilePath]` instead of a `[String]` as
documented.

<details> <summary> Exercise: can you now implement a simple
[`echo`](https://www.man7.org/linux/man-pages/man1/echo.1p.html) in
Haskell? (expand for solution)
</summary>
``` {.haskell}
module Main where

import System.Environment
import GHC.IO.Encoding

main :: IO ()
main = do
    args <- getArgs
    argvEncoding >>= setLocaleEncoding
    putStrLn (unwords args)
```

Did your simple `echo` program work with the following invocation?

    ./myEcho One Two $(printf '\231')

</details>

## Conclusion

Be aware of what `TextEncoding` is in use. As `String` and `FilePath`
tend to use different ones, and mixing them is obviously bad. Ideally
each different encoding would be realised in the type system, but alas,
it is not so.
