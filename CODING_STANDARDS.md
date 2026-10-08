# Coding standards

Judgement calls a reviewer applies to every change. Anything a tool enforces (stylua, the tests) is left to the tool.

## which-key descriptions start with a verb, in Title Case

A key's `desc` names the action it takes: a verb first, every word capitalised. A key that opens a status view may use a plain noun label instead.

Why: which-key lists a group's keys side by side, so one shape lets you scan them as a list of actions.

Example, `lua/plugins/preview.lua`:

```lua
{ "<leader>vs", "<cmd>KiteHost start<cr>", desc = "Start Live Server" },
{ "<leader>vi", "<cmd>KiteHost status<cr>", desc = "Live Server Status" },
```

## A design doc's Terms section uses the glossary in `CONTEXT.md`

Open the Terms section with "These follow the glossary in `CONTEXT.md`.", then list the glossary's terms with its meanings and _Avoid_ words. A term the glossary lacks goes into `CONTEXT.md` in the same change, so the doc and the glossary keep one meaning.

Why: `CONTEXT.md` is the single source of the project's language; a doc that defines its own terms drifts from it.

Example, `docs/theme-italics-design.md`:

```markdown
## Terms

These follow the glossary in `CONTEXT.md`.

- **Theme family**: curated themes that share one setup and one set of options: ...
```
