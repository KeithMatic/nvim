# 09: Better escape

**What to build:** Typing `jj` or `jk` leaves insert mode and cmdline mode, with no visible pause after `j` and neither letter left behind. A `j` followed by another letter is typed normally. Visual, select and terminal modes are unaffected, so `j` still moves in visual mode and `jj` still reaches programs in the terminal (e.g. lazygit). The window for the second key is 200 ms.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] better-escape.nvim added with `jj` and `jk`, insert and cmdline modes only, 200 ms
- [x] Test: `jk` and `jj` in insert mode return to normal mode and leave no `j`/`k` in the buffer
- [x] Test: `ja` in insert mode inserts `ja`
- [x] Test: `jj` in visual mode moves the cursor two lines
- [x] Test: `jk` in the cmdline leaves the cmdline
- [x] Manual: typing words with `j` in them feels instant

## Comments

- better-escape maps every key of a sequence, so `j` and `k` are both mapped in insert and cmdline modes (checked free first; nothing else maps them).
- Cmdline mode includes `/` and `?` searches, so `jj`/`jk` abandon a search too (`<C-c>`, not `<Esc>`, so the cmdline is never run).
- Extra tests beyond the list: `jj` in the cmdline, a lone `jj`/`jk` leaves an unmodified buffer unmodified, a `j` past the 200 ms window is kept (checked to fail with a 1000 ms window), and no `j`/`k` mapping in terminal or select mode (a mapping check, since terminal behaviour is hard to drive headlessly).
