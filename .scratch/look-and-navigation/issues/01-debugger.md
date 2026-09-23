# 01: Debugger

**What to build:** Neovim starts without the nvim-dap configuration error, and the debug adapters the language extras already set up (Python, Go, C/C++, Rust) are usable. LazyVim's debugger extra gives nvim-dap its config; the debugger's panels follow Transparency, and the line the debugger stopped on keeps its background.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The debugger extra is enabled alongside the other extras
- [x] Only the debugger's plugins are added to the lockfile in this commit
- [x] Test: the boot spec passes (no errors or error notifications at startup)
- [x] dap-ui panels have no background; `DapStoppedLine` keeps its background
- [x] Manual: restart Neovim, no nvim-dap error; Mason finishes installing debugpy
