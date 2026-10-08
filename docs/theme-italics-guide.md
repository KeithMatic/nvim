# Italics in your editor: a beginner's guide

This guide shows how your editor decides which code is drawn in *italics*, and how to change it. You can italicise kinds of code your theme doesn't offer, and keep those choices when you switch theme.

You won't need to know how themes work inside. Most of the time you only press `<leader>uy` and tick what you want. The editing part (section 3) is only for adding a kind of code that isn't on the list yet.

A few words used throughout:

- **Syntax type**: a kind of code text the editor colours on its own, such as comments, keywords, strings, function names or parameters.
- **Theme family**: a group of themes that share one setup. tokyonight (night, storm, moon) is one family, and catppuccin (frappe, macchiato, mocha) is another.
- **Theme italics**: which Syntax types are drawn in italics, chosen in the picker you open with `<leader>uy`. It has two sections:
  - **the theme's own options**: what your Theme family offers, remembered separately for each family;
  - **Extra italics**: Syntax types this config adds on top of any theme, chosen once and kept on every theme.

The line diagnostics (the messages at the end of a line) and the Breadcrumbs (the path at the top of the window) are always italic. They aren't in the picker.

---

## 1. Reviewing the Current Theme Configuration

### Step 1: See what you have now

1. Open any code file (for example `lua/theme.lua`).
2. Press `<leader>uy` (your leader key, then `u`, then `y`).
3. A list opens. Each row has:
   - a **tick** (on) or a **cross** (off);
   - a **section name**: your Theme family (`tokyonight` or `catppuccin`), or `extra`;
   - the **Syntax type**, such as `comments` or `parameters`.
4. Press `Esc` to close it without changing anything.

On tokyonight-moon (the default theme) you'll see tokyonight's 4 own options first, then 19 extras. On catppuccin you'll see its 12 own options, then 11 extras. On any other theme you'll see the extras only.

### Step 2: Know where each part lives

You don't need to open these to use the picker, but it helps to know where things are:

| What | Where | What it does |
|---|---|---|
| The list of themes | `lua/theme.lua` (at the top, `M.themes`) | The six themes `<leader>uC` offers. |
| The theme's own italic options | `lua/theme_italics.lua` (the `families` table) | What tokyonight and catppuccin let you italicise. |
| The Extra italics | `lua/theme_italics.lua` (the `extras` table) | The Syntax types this config can italicise on any theme. |
| The `<leader>uy` key | `lua/plugins/ui.lua` (search for `uy`) | Opens the picker. |
| What you've chosen | `theme.json` in Neovim's state folder (`:echo stdpath("state")`) | Saved automatically every time you flip a row. |

### Step 3: Read your saved choices (optional)

Your choices are kept in `theme.json`. Run `:echo stdpath("state")` to find the folder, then open the file inside it. It looks like this, all on one line:

```json
{"theme":"tokyonight-moon","italics":{"tokyonight":{"comments":true,"keywords":true}},"extra_italics":{"parameters":true}}
```

- `"theme"` is the theme you last picked.
- `"italics"` holds the theme's own options, **one set per Theme family**. Your tokyonight choices don't affect catppuccin.
- `"extra_italics"` holds the Extra italics, **one set for every theme**.

You never need to edit this file by hand. The picker writes it for you.

---

## 2. Identifying Syntax Types for Expansion

These are all the Extra italics, in the order the picker shows them. Every one starts **off**.

| In the picker | What it is | Example | Turns italic |
|---|---|---|---|
| comments | Notes for humans | `-- check the cache first` | the whole comment |
| documentation comments | Comments and strings that document code (docstrings) | `--- Returns the user's name.` | the whole comment |
| keywords | The language's own words | `local x = 1` | `local` |
| conditionals | Words that choose a path | `if ready then … else … end` | `if`, `then`, `else` |
| loops | Words that repeat | `for i = 1, 3 do … end` | `for`, `do` |
| return and exception keywords | Words that leave a function or raise an error | `return total`, `throw err` | `return`, `throw`, `try`, `catch` |
| imports | Words that bring in other code | `from os import path` | `from`, `import` |
| functions | Function names, where defined and where called | `local function greet()` | `greet` |
| methods | Functions called on an object | `list:insert(x)` | `insert` |
| variables | Names that hold values | `local count = 0` | `count` |
| parameters | The inputs a function takes | `function greet(name, age)` | `name`, `age` |
| properties | Fields of an object | `user.name` | `name` |
| built-ins (self, this) | Names the language provides | `self.name`, `print(x)` | `self`, `this`, `print`, `nil` |
| types | Type names | `let u: User` | `User` |
| constants | Values that never change | `MAX_SIZE = 10` | `MAX_SIZE` |
| modules | Module and namespace names | `import os` | `os` |
| decorators | Annotations above code | `@property` | `@property` |
| strings | Text in quotes | `"hello"` | `"hello"` |
| characters and escapes | Single characters and special sequences | `"line\n"` | `\n` |
| numbers | Numbers | `x = 3.14` | `3.14` |
| booleans | True and false | `done = true` | `true` |
| operators | Symbols and word operators | `a + b`, `not ready` | `+`, `not` |
| markup tags and attributes | HTML/JSX tags and their attributes | `<div class="box">` | `div`, `class` |

**Why some rows are hidden:** if your Theme family already offers a Syntax type itself, the extra with the same name is hidden and the theme's own option is used instead. So you never see two "comments" rows.

- **tokyonight** offers comments, keywords, functions and variables. Those four extras are hidden.
- **catppuccin** offers comments, conditionals, loops, functions, keywords, strings, variables, numbers, booleans, properties, types and operators. Those twelve extras are hidden.

**A good place to start:** turn on **parameters**, **built-ins**, and **decorators**, and keep the theme's **comments** on. That's a classic look with Operator Mono's cursive italic. If everything is italic, nothing stands out, so add more one at a time.

---

## 3. Adding Italics to New Syntax Types

### Turning an Extra italic on or off

1. Press `<leader>uy`.
2. Move to the row you want and press `Enter`. The tick turns into a cross, or the other way round, and your code updates straight away.
3. The list opens again, so you can flip more rows. Press `Esc` when you're done.

That's it: the choice is saved and comes back next time you start Neovim. Extra italics also stay the same when you switch theme with `<leader>uC`.

Turning a row **off** puts back exactly what the theme drew before.

### Adding a Syntax type that isn't on the list

Say you want **labels** (the names `goto` jumps to, like `::continue::` in Lua) to be italic. They aren't in the list, so you add them.

**Step 1: find the Syntax type's name.** Put the cursor on an example of it in a file and run `:Inspect`. A small window lists the names that colour that word. Use the ones that start with `@`, for example `@label`. (Section 4 has more on `:Inspect`.)

**Step 2: open the list of extras.** Open `lua/theme_italics.lua` and find `local extras = {`. Each line inside is one row of the picker. The last one looks like this:

```lua
  { name = "tags", label = "markup tags and attributes", groups = { "@tag", "@tag.attribute" } },
}
```

**Step 3: add your line** just above the closing `}`:

```lua
  { name = "tags", label = "markup tags and attributes", groups = { "@tag", "@tag.attribute" } },
  { name = "labels", groups = { "@label" } },
}
```

The three parts of the line:

- `name`: a short, unique word, saved in `theme.json`. Use lower case and no spaces.
- `label` (optional): what the picker shows. Leave it out and the picker shows `name`.
- `groups`: the `@` names from `:Inspect`, in quotes, separated by commas. Each one also covers its more specific versions, so `@label` covers `@label.lua` too.

**Step 4: save and restart Neovim.** Press `<leader>uy`, and `labels` is the last row, in the `extra` section. Flip it on.

A few rules keep things tidy:

- **Each Syntax type stays in its own row.** If you list a more specific name in your row, for example `@function.builtin`, it belongs to your row only and not to the broader one (`functions`). That's why turning on "functions" doesn't also italicise built-in functions.
- **Matching a theme option hides your row.** If your `name` is the same as one of your Theme family's own options (for example `strings` on catppuccin), the row is hidden on that family and the theme's own option is used.
- **Old-style names work too.** Names without an `@`, like `Comment` or `String`, are what older parts of the editor use. List them as well when `:Inspect` shows them.

---

## 4. Testing and Validation

### Check that your terminal draws italics at all

In a WezTerm window (outside Neovim), run:

```sh
printf '\e[3mThis should be italic\e[0m\n'
```

You should see Operator Mono's flowing, cursive italic. If the text is upright, the problem is the terminal's font setup, not this config.

### Find out which Syntax type a word is

1. Put the cursor on the word.
2. Run `:Inspect`.
3. Read the list. For example, on `name` in `function greet(name)` you'll see `@variable.parameter`, which is the **parameters** row. If a language server is running you'll also see names starting with `@lsp`. Those add colour on top and don't remove italics.

### A checklist to run after any change

1. **Make a small sample file** with one of everything: a comment, a function with a parameter, a string, a number, `self`/`this`, an import, a `return`. Keep it in a scratch folder for reuse.
2. **Flip each row you care about** in `<leader>uy`, and watch the sample change straight away.
3. **Flip it back** and check the word goes back to how the theme drew it.
4. **Switch theme** with `<leader>uC`, from tokyonight-moon to catppuccin-mocha and back. Your Extra italics should stay. The picker should show tokyonight's own rows on tokyonight and catppuccin's own rows on catppuccin.
5. **Restart Neovim** and check your choices are still there.
6. **Open a file with a language server** (any Lua file in this config works) and check italics are still there once it has loaded.

### One thing that may surprise you

On **tokyonight**, the theme's own **functions** option also italicises the word `function` itself, not only function names. That's how tokyonight is built, not something this config does. Because tokyonight offers **functions** itself, the **functions** extra is hidden there, so on tokyonight you can't have italic function names with an upright `function` keyword. On catppuccin, its own **functions** option leaves the `function` keyword upright, but it also italicises built-in functions like `print`, even with the **built-ins** extra off.

### For the curious: the automated tests

`tests/theme_italics_spec.lua` checks all of the above automatically: every extra on tokyonight, catppuccin and an outside theme; the picker's rows; saving and restarting; and the language-server case. Run it with:

```sh
tests/run.sh tests/theme_italics_spec.lua
```
