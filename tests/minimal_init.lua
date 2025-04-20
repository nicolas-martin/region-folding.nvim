-- Store installation paths for cleanup
_G.test_deps = {
    plenary_root = vim.fn.expand('~/.local/share/nvim/site/pack/vendor/start/plenary.nvim')
}

-- Add the plugin directory to runtimepath
local plugin_root = vim.fn.expand('<sfile>:h:h')
vim.opt.runtimepath:append(plugin_root)

-- Add plenary to runtimepath
if vim.fn.isdirectory(_G.test_deps.plenary_root) == 0 then
    print("Plenary not found. Installing...")
    vim.fn.system({'git', 'clone', 'https://github.com/nvim-lua/plenary.nvim', _G.test_deps.plenary_root})
end
vim.opt.runtimepath:append(_G.test_deps.plenary_root)

-- Try to load treesitter parsers if they exist
local function try_load_parser(lang)
    local ok = pcall(function()
        vim.treesitter.language.add(lang)
    end)
    if not ok then
        print(string.format("Note: %s parser not available, will use regex fallback", lang))
    end
end

-- Try to load parsers we might use
try_load_parser('lua')
try_load_parser('javascript')

-- Load plenary test harness
require('plenary.busted')
