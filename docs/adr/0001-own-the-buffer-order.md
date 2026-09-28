# Own the order of the Buffer sticks

The **Buffer sticks** replace bufferline, and we still want to pin files, reorder them, and close
everything left or right of one. buffer-sticks.nvim draws buffers in creation order and has no way to
sort them, so the config keeps its own ordered list of files and wraps the plugin's buffer list to
draw in that order; stepping to the previous/next file follows the same order.

## Considered options

- **Keep creation order**: no wrapper, but no reordering, and "left/right" would mean older/newer
  rather than anything visible.
- **Fork the plugin, or wait for an upstream sort option**: clean, but blocks the feature on
  someone else's release.

## Consequences

The wrapper leans on a plugin internal, so a plugin update can break the order silently; if upstream
gains a sort option, the wrapper should move onto it. Backing this out means dropping pin, reorder
and close-left/right together.
