# 09: Better escape

**What to build:** Typing `jj` or `jk` leaves insert mode and cmdline mode, with no visible pause after `j` and neither letter left behind. A `j` followed by another letter is typed normally. Visual, select and terminal modes are unaffected, so `j` still moves in visual mode and `jj` still reaches programs in the terminal (e.g. lazygit). The window for the second key is 200 ms.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] better-escape.nvim added with `jj` and `jk`, insert and cmdline modes only, 200 ms
- [ ] Test: `jk` and `jj` in insert mode return to normal mode and leave no `j`/`k` in the buffer
- [ ] Test: `ja` in insert mode inserts `ja`
- [ ] Test: `jj` in visual mode moves the cursor two lines
- [ ] Test: `jk` in the cmdline leaves the cmdline
- [ ] Manual: typing words with `j` in them feels instant
