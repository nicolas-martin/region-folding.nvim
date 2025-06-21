# Region Folding Plugin - Usage Guide

## Overview
The region-folding.nvim plugin enables code folding using `#region` and `#endregion` markers in comments. It uses treesitter for accurate comment detection and works alongside existing fold methods.

## Installation & Setup

Add to your Neovim configuration:

```lua
{
  "nicolas-martin/region-folding.nvim",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    region_text = {
      start = "#region",
      ending = "#endregion",
    },
    space_after_comment = true,
    fold_indicator = "▼",
    debug = false
  },
}
```

## Supported Languages

The plugin works with any language that has treesitter comment support:

- **JavaScript/TypeScript**: `// #region` and `// #endregion`
- **Python**: `# #region` and `# #endregion`  
- **Lua**: `-- #region` and `-- #endregion`
- **Go**: `// #region` and `// #endregion`
- **Rust**: `// #region` and `// #endregion`
- **C/C++**: `// #region` and `// #endregion`
- **Java**: `// #region` and `// #endregion`
- **PHP**: `// #region` and `// #endregion`
- **Ruby**: `# #region` and `# #endregion`
- **Shell/Bash**: `# #region` and `# #endregion`
- **And many more...**

## Usage Examples

### JavaScript
```javascript
function example() {
    // #region Configuration Setup
    const config = {
        host: 'localhost',
        port: 3000,
        ssl: false
    };
    const database = {
        url: 'mongodb://localhost:27017',
        name: 'testdb'
    };
    // #endregion

    // #region Helper Functions
    function validateConfig(cfg) {
        return cfg.host && cfg.port;
    }

    function initDatabase(db) {
        return { ...database, ...db };
    }
    // #endregion

    return { config, database };
}
```

### Python
```python
class DataProcessor:
    def __init__(self):
        # #region Configuration
        self.config = {
            'batch_size': 100,
            'timeout': 30,
            'retries': 3
        }
        self.database_config = {
            'host': 'localhost',
            'port': 5432,
            'name': 'testdb'
        }
        # #endregion

    # #region Data Processing Methods
    def process_batch(self, data):
        '''Process a batch of data'''
        processed = []
        for item in data:
            try:
                result = self._process_item(item)
                processed.append(result)
            except Exception as e:
                self._handle_error(e, item)
        return processed

    def _process_item(self, item):
        '''Process a single item'''
        if not item:
            return None
        return item.strip().lower()
    # #endregion
```

### Lua
```lua
local M = {}

-- #region Default Configuration
local default_config = {
    enabled = true,
    debug = false,
    max_depth = 10,
    timeout = 5000,
    cache_size = 1000
}
-- #endregion

-- #region Public API
function M.setup(user_config)
    local config = vim.tbl_deep_extend('force', default_config, user_config or {})
    
    if not validate_config(config) then
        error('Invalid configuration provided')
    end
    
    M.config = config
    return M
end

function M.process(data)
    if not M.config or not M.config.enabled then
        return data
    end
    
    local processed = deep_copy(data)
    return processed
end
-- #endregion

return M
```

## Fold Operations

Once regions are defined, use standard Neovim fold commands:

| Command | Description |
|---------|-------------|
| `zo` | Open fold under cursor |
| `zc` | Close fold under cursor |
| `za` | Toggle fold under cursor |
| `zR` | Open all folds in file |
| `zM` | Close all folds in file |
| `zj` | Move to next fold |
| `zk` | Move to previous fold |

## Fold Display

When folded, regions show:
```
▼ Configuration Setup (8 lines)
▼ Helper Functions (12 lines)
▼ Data Processing Methods (16 lines)
```

## Features

✅ **Pure Treesitter**: No regex fallbacks, accurate comment detection  
✅ **Multi-language**: Works with 20+ programming languages  
✅ **Compatible**: Works alongside existing fold methods (treesitter, indent, etc.)  
✅ **Nested Regions**: Supports nested region markers  
✅ **Customizable**: Configure markers, indicators, and spacing  
✅ **Performance**: Efficient caching for large files  

## Testing

The plugin includes comprehensive tests:

```bash
# Run simple test
nvim --headless -c "luafile simple_test.lua" -c "qa"

# Run multi-language demo
nvim --headless -c "luafile demo.lua" -c "qa"

# Run comprehensive test suite (requires plenary.nvim)
nvim --headless -c "luafile tests/region_folding_spec.lua" -c "qa"
```

## Configuration Options

```lua
opts = {
  -- Region marker text (without comment syntax)
  region_text = {
    start = "#region",    -- Default: "#region"
    ending = "#endregion" -- Default: "#endregion"
  },
  -- Control spacing between comment and region text
  space_after_comment = true, -- Default: true
  -- Customize the fold indicator symbol
  fold_indicator = "▼",      -- Default: "▼"
  -- Enable debug logging
  debug = false              -- Default: false
}
```

## Troubleshooting

1. **No regions detected**: Ensure treesitter parser is installed for your language
2. **Regions not folding**: Check that region markers have matching start/end pairs
3. **Compatibility issues**: Plugin prioritizes region markers over existing foldexprs

For more help, see the test files for working examples in multiple languages.