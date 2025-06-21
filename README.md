# region-folding.nvim

A minimal Neovim plugin for custom code folding using region markers. Automatically folds regions while preserving treesitter folding for functions and other code structures.

![Region Folding Example](./assets/region-folding-example.png)

## Features

- **Custom region folding** with `#region` / `#endregion` markers
- **Smart fold text** showing region names and function names  
- **Treesitter compatibility** - works alongside existing fold methods
- **Multi-language support** - 20+ languages out of the box
- **Intelligent navigation** with `zj`/`zk` between all fold types
- **Auto-fold regions** while keeping functions visible by default

## Installation

**Lazy.nvim:**
```lua
{
  "nicolas-martin/region-folding.nvim",
  event = { "BufReadPost", "BufNewFile" },
  opts = {} -- Use defaults
}
```

**With custom options:**
```lua
{
  "nicolas-martin/region-folding.nvim", 
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    region_text = { start = "#region", ending = "#endregion" },
    fold_indicator = "▼"
  }
}
```

## Configuration

**Required fold settings in your `init.lua` or `options.lua`:**
```lua
-- Enable treesitter folding (required for function folding)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
```

## Fold Commands

| Command | Description |
|---------|-------------|
| `za` | Toggle fold at cursor |
| `zj` / `zk` | Navigate to next/previous fold |
| `zR` | Open all folds |
| `zM` | Close all folds |

## Troubleshooting

**Functions not folding, only regions work:**
- Ensure treesitter folding is enabled (see Configuration section above)
- Install language parsers: `:TSInstall <language>`
- Verify treesitter is working: `:checkhealth nvim-treesitter`

**No folding at all:**
- Check fold settings: `:set foldmethod? foldexpr?`
- Verify plugin loaded: `:lua print(require('region-folding'))`
