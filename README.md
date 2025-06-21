# region-folding.nvim

A minimal Neovim plugin for custom code folding using region markers. Automatically folds regions while preserving treesitter folding for functions and other code structures.

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
    fold_indicator = "▼",
    debug = false
  }
}
```

## Usage

Add region markers to your code:

```go
// #region Configuration Types
type Config struct {
    Host string `json:"host"`
    Port int    `json:"port"`
}
// #endregion

func main() {  // This function can also be folded with treesitter
    // Your code here
}
```

**Result:**
- `▼ Configuration Types (8 lines)` ← Region fold (auto-folded)
- `▼ main() (15 lines)` ← Function fold (visible by default, foldable with `za`)

## Fold Commands

| Command | Description |
|---------|-------------|
| `za` | Toggle fold at cursor |
| `zj` / `zk` | Navigate to next/previous fold |
| `zR` | Open all folds |
| `zM` | Close all folds |

## Supported Languages

JavaScript, TypeScript, Python, Go, Lua, Rust, C/C++, Java, PHP, Ruby, Shell, YAML, TOML, and more.

## How It Works

1. **Regions auto-fold** on file open
2. **Functions stay visible** (can be manually folded)
3. **Smart fold text** shows region titles and function names
4. **Navigate seamlessly** between all fold types
