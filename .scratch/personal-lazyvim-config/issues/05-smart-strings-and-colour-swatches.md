# 05: Smart strings + colour swatches

**What to build:** fstring-converter, backticks and colorize parity. In Python, typing a `{…}` placeholder inside a normal string turns it into an f-string automatically. In JS/TS, typing `${` inside a quoted string turns it into a template literal. Colour values (hex codes and Tailwind colour classes) are highlighted with their actual colour. Path completion already comes from the completion engine and only needs confirming.

**Blocked by:** 01

**Status:** done

- [x] nvim-puppeteer installed and active for Python and JS/TS filetypes
- [x] mini-hipatterns LazyVim extra enabled
- [x] Test (Python buffer): typing `{name}` inside `"hello "` results in an f-string
- [x] Test (TS buffer): typing `${` inside a single- or double-quoted string results in a template literal
- [x] Test: a hex colour in a buffer receives a highlight whose background is that colour
- [x] Path completion confirmed available as a completion source
