---
title: Cheat Sheet
---

Small snippets to remember.

---

Screen shot to clipboard. Can then `ctrl-v` into browser.

```bash
import PNG:- | xclip -i -t image/png -selection clipboard
```

---

Copy to the system clipboard using a terminal sequence. Works over SSH/UART etc.

```bash
printf '\e]52;c;%s\a' "$(base64)"
```
