---
title: Codata and ListT Done Right
---

When deciding how to implement `ListT` (the monad transformer) in Haskell,
one is [tempted to do something like](https://hackage.haskell.org/package/mtl-2.2.2/docs/Control-Monad-List.html#t:ListT):

```haskell
newtype ListT m a = ListT {runListT :: m [a]}
```

The problem with this version of `ListT` is that it does not form a `Monad`
unless the base monad is commutative (i.e. the order of operations does not
matter). This rules out potentially useful instances such as `ListT IO` which
you might like to use as a simple streaming interface.

How can we come up with a version of `ListT` that works? The one above was
the only obvious version.

## A Quick Detour, Codata

Data can be thought of as a way of constructing something. A function
from a value to a type.

```haskell
data A = MkA Int
```

Here, the constructor `MkA` has the type `Int -> A`

Codata, on the other hand, is a way of deconstructing something. That is,
we flip the arrows! (This is what "co" tends to mean). So we are looking for
something with the type `A -> Int` instead. Data types in Haskell are actually
both data and codata. We even have special syntax for codata. It looks like
this:

```haskell
data A = A
    { getA :: Int
    }
```

Here, `getA` has the type `A -> Int`.

It's also trivial to convert between a data and codata in Haskell. Basically
all we have to do is create a destructor that witnesses every constructor.

For example:

```haskell
data A = X Int | Y Char
```

can be expressed as

```haskell
data CoA = CoA
    { getA :: Either Int Char  -- Left witnesses X, Right witnesses Y
    }
```

> Side note, `Either Int Char` is the same thing as `A`, so this feels like
> cheating. Remember, data is codata in Haskell

Back to `List`. Let's quickly define it:

```haskell
data List a = Cons a (List a) | Nil
```

Can we "convert" this to codata?

```haskell
data CoList a = CoList { getList :: Maybe (a, CoList a) }
```

Here, `Nothing` witnesses the `Nil`, and `Just` witnesses the `Cons`.

## ListT, with Codata

So, now that we have a codata version of `List` (which is the same thing
as `List` in Haskell, because data is codata), can we come up with a better
`ListT`? Sure, we can do the same trivial thing we tried to do with our
regular `List` definition, just wrap it in the base monad!

```haskell
data ListT m a = ListT { runListT :: m (Maybe (a, ListT m a)) }
```

Which is [exactly `ListT` done right](https://hackage.haskell.org/package/list-t-1.0.4/docs/ListT.html#t:ListT).

Proving that this forms a monad is left as an exercise to the reader.

It also fits our intuition of what `ListT` might be for streaming. Each element
is produced in the base monad along with the rest of the list.

This corresponds closely with streaming or iterator patterns in other languages.
e.g. Rust has the [`Iterator` trait](https://doc.rust-lang.org/std/iter/trait.Iterator.html)
which has the sole method `fn next(&mut self) -> Option<Self::Item>` which
is the same as our `ListT IO`. The `IO` is implied, the return type is an
`Option` of the next element, and instead of returning the rest of the list, the
list is mutated in place.

So, next time you are struggling to find the correct path forward for your
data types, consider thinking about it with the arrows flipped!
