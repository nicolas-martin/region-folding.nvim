local M = {}

-- Get the Treesitter parser for the current buffer
local function get_parser()
    local buf = vim.api.nvim_get_current_buf()
    local ft = vim.bo.filetype

    -- Try to get the parser
    if ft and ft ~= '' then
        local ok, parser = pcall(vim.treesitter.get_parser, buf, ft)
        if ok then
            return parser
        end
    end
    return nil
end

-- Get the root node of the syntax tree
local function get_root()
    local parser = get_parser()
    if not parser then
        return nil
    end
    return parser:parse()[1]:root()
end

-- Fallback regex-based comment detection
local function get_comments_by_regex()
    local comments = {}
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Common comment patterns
    local patterns = {
        ['^%s*//'] = true, -- C-style
        ['^%s*%-%-'] = true, -- Lua
        ['^%s*#'] = true, -- Shell, Python, Ruby
        ['^%s*"'] = true, -- VimScript
        ['^%s*;'] = true, -- Lisp, Assembly
        ['^%s*%%'] = true -- Erlang, MATLAB
    }

    for i, line in ipairs(lines) do
        -- Check if line starts with any common comment pattern
        for pattern, _ in pairs(patterns) do
            if line:match(pattern) then
                table.insert(comments, {
                    text = line:gsub("^%s*", ""):gsub("%s*$", ""), -- Trim whitespace
                    line = i
                })
                break
            end
        end
    end

    return comments
end

-- Find all comments in the buffer
local function get_all_comments()
    local root = get_root()
    if root then
        -- Use Treesitter if available
        local comments = {}
        local query = vim.treesitter.query.parse(vim.bo.filetype, [[
            (comment) @comment
        ]])

        if query then
            for id, node in query:iter_captures(root, 0) do
                if query.captures[id] == "comment" then
                    local start_row = node:range()
                    local text = vim.treesitter.get_node_text(node, 0)
                    table.insert(comments, {
                        node = node,
                        text = text:gsub("^%s*", ""):gsub("%s*$", ""), -- Trim whitespace
                        line = start_row + 1 -- Convert to 1-based line number
                    })
                end
            end
            return comments
        end
    end

    -- Fall back to regex-based detection if Treesitter is not available
    return get_comments_by_regex()
end

-- Parse a comment for region markers
local function parse_comment(comment, opt)
    -- Remove common comment prefixes to get to the actual content
    local content = comment.text:gsub("^[%-%/%#%\"%;%%]+%s*", "")

    -- Check for region markers
    local start_region = content:match("^" .. opt.region_text.start .. "%s*(.*)")
    if start_region then
        return {
            type = "start",
            title = #start_region > 0 and start_region or nil,
            line = comment.line
        }
    end

    if content:match("^" .. opt.region_text.ending .. "%s*") then
        return {
            type = "end",
            line = comment.line
        }
    end

    return nil
end

-- Find region markers in the buffer
function M.get_regions()
    local comments = get_all_comments()
    local regions = {}
    local current_region = nil

    for _, comment in ipairs(comments) do
        local marker = parse_comment(comment, M.opt)
        if marker then
            if marker.type == "start" then
                current_region = {
                    start = marker.line,
                    title = marker.title
                }
            elseif marker.type == "end" and current_region then
                current_region.ending = marker.line
                table.insert(regions, current_region)
                current_region = nil
            end
        end
    end

    return regions
end

-- Get fold level for a line
function M.get_fold_level(lnum)
    -- Cache regions for performance
    if not M.cached_regions or M.cached_buffer ~= vim.api.nvim_get_current_buf() then
        M.cached_regions = M.get_regions()
        M.cached_buffer = vim.api.nvim_get_current_buf()
    end

    for _, region in ipairs(M.cached_regions) do
        if lnum == region.start then
            return "a1" -- Start fold
        elseif lnum == region.ending then
            return "s1" -- End fold
        end
    end

    return "=" -- Use previous fold level
end

-- Get fold text for a region
function M.get_fold_text(start_line)
    -- Cache regions for performance
    if not M.cached_regions or M.cached_buffer ~= vim.api.nvim_get_current_buf() then
        M.cached_regions = M.get_regions()
        M.cached_buffer = vim.api.nvim_get_current_buf()
    end

    -- Find the region that starts at this line
    for _, region in ipairs(M.cached_regions) do
        if region.start == start_line then
            return region.title, region.ending - region.start + 1
        end
    end

    return nil, nil
end

-- Initialize with options
function M.setup(opt)
    M.opt = opt
    M.cached_regions = nil
    M.cached_buffer = nil
end

return M
