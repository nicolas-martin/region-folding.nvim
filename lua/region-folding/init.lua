local M = {}

-- Default configuration
local default_opt = {
    -- Region marker text (without comment syntax)
    region_text = {
        start = "#region",
        ending = "#endregion"
    },
    -- Optional space between comment and region text
    space_after_comment = true,
    -- Fold indicator symbol
    fold_indicator = "▼"
}

-- Initialize with defaults immediately
local opt = vim.deepcopy(default_opt)

-- Setup function to initialize the plugin
function M.setup(user_opt)
    if user_opt and user_opt.opts then
        opt = vim.tbl_deep_extend("force", default_opt, user_opt.opts)
    else
        opt = vim.tbl_deep_extend("force", default_opt, user_opt or {})
    end

    -- Initialize treesitter module with options
    require('region-folding.treesitter').setup(opt)
end

-- Function to determine fold level for a given line
function M.get_fold_level(lnum)
    return require('region-folding.treesitter').get_fold_level(lnum)
end

-- Function to create fold text
function M.get_fold_text()
    local ts = require('region-folding.treesitter')
    local title, lines_count = ts.get_fold_text(vim.v.foldstart)

    -- Create fold text
    if title then
        return string.format("%s %s (%d lines)", opt.fold_indicator, title, lines_count)
    else
        return string.format("%s folded region (%d lines)", opt.fold_indicator, vim.v.foldend - vim.v.foldstart + 1)
    end
end

-- Create autocommands for buffer events
local function setup_autocommands()
    local group = vim.api.nvim_create_augroup("RegionFolding", {
        clear = true
    })
    vim.api.nvim_create_autocmd({"BufEnter", "BufReadPost"}, {
        group = group,
        callback = function()
            -- Set up fold settings for the buffer
            vim.wo.foldmethod = "expr"
            vim.wo.foldexpr = "v:lua.require'region-folding'.get_fold_level(v:lnum)"
            vim.wo.foldtext = "v:lua.require'region-folding'.get_fold_text()"
            -- Refresh folding
            vim.cmd("normal! zx")
        end
    })
end

-- Initialize the plugin
setup_autocommands()

return M
