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

## Usage

Add region markers to organize your code:

```go
package main

import (
    "database/sql"
    "log" 
    "net/http"
)

// #region Configuration Constants
const (
    DefaultPort = 8080
    MaxRetries  = 3
)
// #endregion

// #region Database Types  
type User struct {
    ID       int    `json:"id"`
    Username string `json:"username"`
    Email    string `json:"email"`
}
// #endregion

// #region Database Methods
func NewDatabase(dsn string) (*Database, error) {
    conn, err := sql.Open(dbDriver, dsn)
    if err != nil {
        return nil, err
    }
    return &Database{conn: conn}, nil
}

func (db *Database) GetUser(id int) (*User, error) {
    // Implementation...
}
// #endregion

// #region HTTP Handlers
func handleGetUser(w http.ResponseWriter, r *http.Request) {
    // Handler implementation...
}

func handleCreateUser(w http.ResponseWriter, r *http.Request) {
    // Handler implementation...
}
// #endregion

func main() {
    // #region Server Setup
    db, err := NewDatabase("postgres://...")
    if err != nil {
        log.Fatal(err)
    }
    
    http.HandleFunc("/users", handleGetUser)
    log.Fatal(http.ListenAndServe(":8080", nil))
    // #endregion
}
```

**Result:**
- `▼ Configuration Constants (8 lines)` ← Auto-folded
- `▼ Database Types (12 lines)` ← Auto-folded  
- `▼ Database Methods (16 lines)` ← Auto-folded
- `▼ HTTP Handlers (16 lines)` ← Auto-folded
- `func main() { ... ▼ Server Setup (12 lines) }` ← Function visible, nested region auto-folded

## Fold Commands

| Command | Description |
|---------|-------------|
| `za` | Toggle fold at cursor |
| `zj` / `zk` | Navigate to next/previous fold |
| `zR` | Open all folds |
| `zM` | Close all folds |
