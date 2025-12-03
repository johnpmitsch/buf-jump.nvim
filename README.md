# buf-jump.nvim

A lightweight buffer history navigation plugin for Neovim. Navigate through your buffer history per-window, similar to how you navigate web browser history.

## Features

- **Per-window history** — Each window maintains its own independent buffer history
- **Familiar navigation** — Jump back and forward through buffers you've visited
- **Count support** — Use `3bjp` to jump back 3 buffers at once
- **Clean history** — Automatically removes deleted buffers and ignores unlisted/unnamed buffers
- **Zero dependencies** — Pure Lua, no external requirements

## Requirements

- Neovim ≥ 0.7.0

## Installation

<details>
<summary><b>lazy.nvim</b></summary>

```lua
{
  "johnpmitsch/buf-jump.nvim",
  event = "BufWinEnter",
  opts = {},
}
```

</details>

<details>
<summary><b>packer.nvim</b></summary>

```lua
use {
  "johnpmitsch/buf-jump.nvim",
  config = function()
    require("buf-jump").setup()
  end,
}
```

</details>

<details>
<summary><b>mini.deps</b></summary>

```lua
MiniDeps.add("johnpmitsch/buf-jump.nvim")
require("buf-jump").setup()
```

</details>

<details>
<summary><b>Manual</b></summary>

Clone to your Neovim packages directory:

```bash
git clone https://github.com/johnpmitsch/buf-jump.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/buf-jump.nvim
```

Then add to your config:

```lua
require("buf-jump").setup()
```

</details>

## Configuration

```lua
require("buf-jump").setup({
  -- Set to false to disable default keymaps
  -- Set to a table to customize them
  mappings = {
    list = "bjl",      -- Show buffer history
    back = "bjp",      -- Go to previous buffer
    forward = "bjn",   -- Go to next buffer
  },
})
```

### Examples

**Using different keymaps:**

```lua
require("buf-jump").setup({
  mappings = {
    list = "<leader>bl",
    back = "[b",
    forward = "]b",
  },
})
```

**Commands only (no keymaps):**

```lua
require("buf-jump").setup({
  mappings = false,
})
```

## Usage

| Keymap | Command | Description |
|--------|---------|-------------|
| `bjl` | `:BufJumpList` | Display buffer history for current window |
| `bjp` | `:BufJumpBack` | Jump to previous buffer in history |
| `bjn` | `:BufJumpForward` | Jump to next buffer in history |

All navigation commands support counts:

```
3bjp      " Jump back 3 buffers
2bjn      " Jump forward 2 buffers
:5BufJumpBack
```

## API

For programmatic use or custom keymaps:

```lua
local bj = require("buf-jump")

bj.back()           -- Go back one buffer
bj.back(3)          -- Go back 3 buffers
bj.forward()        -- Go forward one buffer
bj.forward(2)       -- Go forward 2 buffers
bj.list()           -- Print buffer history
bj.add(bufnr)       -- Manually add a buffer to history
bj.remove(bufnr)    -- Remove a buffer from history
bj.remove(-1)       -- Clear all history
```

## How It Works

buf-jump maintains a per-window stack of visited buffers. When you enter a buffer, it's added to the current window's history. The plugin tracks your position in this history, allowing you to move backward and forward through previously visited buffers.

Unlike Neovim's built-in jumplist (`:jumps`), which tracks cursor positions across files, buf-jump focuses purely on buffer navigation—making it ideal for quickly switching between files you're actively working on.

## License

MIT