# Issue tracker: GitHub

Issues and specs live in GitHub Issues for `KeithMatic/nvim`.
Use the `gh` CLI from this repository.

## Conventions

- Create: `gh issue create --title "..." --body-file <file>`
- Read: `gh issue view <number> --comments`
- List: `gh issue list --state open`, with label filters as needed.
- Comment: `gh issue comment <number> --body-file <file>`
- Label: `gh issue edit <number> --add-label "..." --remove-label "..."`
- Close completed work: `gh issue close <number>`
- Use the role strings in `triage-labels.md`.
- Write multiline bodies to a file and pass `--body-file`.

When a skill says "publish to the issue tracker", create a GitHub issue.
When it says "fetch the relevant ticket", read the issue and its comments.

Existing `.scratch/` files are historical references. Read them when
referenced; create new tickets on GitHub.

## Pull requests as a triage surface

**PRs as a request surface: no.**

## Wayfinding operations

- Map: one issue labelled `wayfinder:map`, containing Notes,
  Decisions-so-far, and Fog.
- Children: linked sub-issues labelled `wayfinder:<type>`, where type is
  research, prototype, grilling, or task. If sub-issues are unavailable,
  use a task list in the map and `Part of #<map>` in each child.
- Blocking: use native GitHub issue dependencies. If unavailable,
  record `Blocked by: #<number>` in the child. All blockers must be closed.
- Frontier: open, unblocked children with no assignee, in map order.
- Claim: assign the ticket to the driving developer before working.
- Resolve: comment with the answer, close the child, and append a
  summary and link to the map's Decisions-so-far.
