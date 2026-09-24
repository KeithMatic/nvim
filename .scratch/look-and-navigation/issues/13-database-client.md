# 13: Database client (sqmeow trial)

**What to build:** sqmeow.nvim is the database client on trial: connections, a schema browser and results that can be paged, edited and exported, with queries run off the editor thread. Its engine installs automatically when the plugin is installed or updated. SQL table and column completion in `.sql` files keeps working through blink. dadbod-ui is turned off so there's one database UI. Going back is a one-line change.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] sqmeow added, release-versioned, loaded on its command, engine installed by its build hook
- [x] dadbod-ui disabled; vim-dadbod and dadbod-completion kept
- [x] Test: `:Sqmeow` exists; dadbod-ui's commands don't
- [x] Test: in a `.sql` buffer, blink's sources include dadbod completion
- [x] Test: the boot spec still passes
- [x] Manual: connect to a database, run a query, page the results
