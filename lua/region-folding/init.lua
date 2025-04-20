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
    fold_indicator = "▼",
    -- Debug mode
    debug = false
}

-- Initialize with defaults immediately
local opt = vim.deepcopy(default_opt)

-- Store original foldexpr for each buffer
local original_foldexprs = {}

-- Debug logging function
local function log(msg, ...)
    if opt.debug then
        local info = debug.getinfo(2, "Sl")
        local lineinfo = info.short_src .. ":" .. info.currentline
        print(string.format("[region-folding:%s] " .. msg, lineinfo, ...))
    end
end

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
    local bufnr = vim.api.nvim_get_current_buf()
    local original_foldexpr = original_foldexprs[bufnr]

    log("Checking fold level for line %d", lnum)
    log("Original foldexpr: %s", original_foldexpr or "none")

    -- If there's an original foldexpr, evaluate it first
    if original_foldexpr and original_foldexpr ~= "" then
        -- Save current line number
        local saved_v_lnum = vim.v.lnum
        -- Set v:lnum for the original foldexpr
        vim.v.lnum = lnum

        -- Evaluate the original foldexpr
        local ok, result = pcall(vim.api.nvim_eval, original_foldexpr)
        -- Restore v:lnum
        vim.v.lnum = saved_v_lnum

        log("Original foldexpr evaluation: ok=%s, result=%s", ok, result)

        -- If evaluation succeeded and returned a valid fold level
        if ok and result ~= nil and result ~= -1 and result ~= "=" and result ~= 0 and result ~= "0" then
            log("Using original fold level: %s", result)
            return result
        end
    end

    -- Fallback to region folding
    local region_result = require('region-folding.treesitter').get_fold_level(lnum)
    log("Region folding result: %s", region_result)
    return region_result
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
            local bufnr = vim.api.nvim_get_current_buf()
            local current_foldexpr = vim.wo.foldexpr

            log("Buffer entered: %d, Current foldexpr: %s", bufnr, current_foldexpr)

            -- Only store the original foldexpr if it's not our own
            if not original_foldexprs[bufnr] and current_foldexpr ~=
                "v:lua.require'region-folding'.get_fold_level(v:lnum)" then
                original_foldexprs[bufnr] = current_foldexpr
                log("Stored original foldexpr: %s", current_foldexpr)
            end

            -- Don't override if treesitter folding is active and working
            if current_foldexpr == "nvim_treesitter#foldexpr()" then
                local saved_v_lnum = vim.v.lnum
                vim.v.lnum = 1
                local ok, result = pcall(vim.api.nvim_eval, current_foldexpr)
                vim.v.lnum = saved_v_lnum

                if ok and result ~= nil and result ~= -1 and result ~= "=" and result ~= 0 and result ~= "0" then
                    log("Treesitter folding is active and working, not overriding")
                    return
                end
            end

            -- Set up fold settings for the buffer
            vim.wo.foldmethod = "expr"
            vim.wo.foldexpr = "v:lua.require'region-folding'.get_fold_level(v:lnum)"
            vim.wo.foldtext = "v:lua.require'region-folding'.get_fold_text()"

            -- Refresh folding
            vim.cmd("normal! zx")
            log("Set up region folding for buffer")
        end
    })

    -- Clean up original_foldexprs when buffer is deleted
    vim.api.nvim_create_autocmd("BufDelete", {
        group = group,
        callback = function(args)
            log("Buffer deleted, cleaning up: %d", args.buf)
            original_foldexprs[args.buf] = nil
        end
    })
end

-- Initialize the plugin
setup_autocommands()

return M
