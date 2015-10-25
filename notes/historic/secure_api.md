---
title: HMAC for authenticating messages
---

    {
        "msg" = "something that can be seen",
        "sig" = "dasjj2hJH1bsja197AHbeb"
    }

Where sig is generated with a SHA5 HMAC of the "msg" field using a known
shared key.
