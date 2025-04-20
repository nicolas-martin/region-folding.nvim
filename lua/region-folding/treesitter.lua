local M = {}

-- Debug logging function (same as in init.lua)
local function log(msg, ...)
    if M.opt and M.opt.debug then
        local info = debug.getinfo(2, "Sl")
        local lineinfo = info.short_src .. ":" .. info.currentline
        print(string.format("[region-folding:%s] " .. msg, lineinfo, ...))
    end
end

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
    log("Parsing comment: %s", comment.text)
    -- Remove common comment prefixes to get to the actual content
    local content = comment.text:gsub("^[%-%/%#%\"%;%%]+%s*", "")
    log("After prefix removal: %s", content)

    -- Check for region markers
    local start_region = content:match("^" .. opt.region_text.start .. "%s*(.*)")
    if start_region then
        log("Found start region marker with title: %s", start_region)
        return {
            type = "start",
            title = #start_region > 0 and start_region or nil,
            line = comment.line
        }
    end

    if content:match("^" .. opt.region_text.ending .. "%s*") then
        log("Found end region marker")
        return {
            type = "end",
            line = comment.line
        }
    end

    return nil
end

-- Find region markers in the buffer
function M.get_regions()
    log("Getting all comments")
    local comments = get_all_comments()
    log("Found %d comments", #comments)

    local regions = {}
    local current_region = nil

    for _, comment in ipairs(comments) do
        local marker = parse_comment(comment, M.opt)
        if marker then
            if marker.type == "start" then
                log("Starting new region at line %d", marker.line)
                current_region = {
                    start = marker.line,
                    title = marker.title
                }
            elseif marker.type == "end" and current_region then
                log("Ending region at line %d (started at %d)", marker.line, current_region.start)
                current_region.ending = marker.line
                table.insert(regions, current_region)
                current_region = nil
            elseif marker.type == "end" then
                log("Warning: Found end marker without matching start at line %d", marker.line)
            end
        end
    end

    if current_region then
        log("Warning: Unclosed region starting at line %d", current_region.start)
    end

    log("Found %d complete regions", #regions)
    return regions
end

-- Get fold level for a line
function M.get_fold_level(lnum)
    -- Cache regions for performance
    if not M.cached_regions or M.cached_buffer ~= vim.api.nvim_get_current_buf() then
        log("Refreshing regions cache for buffer %d", vim.api.nvim_get_current_buf())
        M.cached_regions = M.get_regions()
        M.cached_buffer = vim.api.nvim_get_current_buf()
    end

    for _, region in ipairs(M.cached_regions) do
        if lnum == region.start then
            log("Line %d is region start", lnum)
            return "a1" -- Start fold
        elseif lnum == region.ending then
            log("Line %d is region end", lnum)
            return "s1" -- End fold
        end
    end

    log("Line %d is not a region boundary", lnum)
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

