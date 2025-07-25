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


-- Find all comments in the buffer using treesitter only
local function get_all_comments()
	local root = get_root()
	if not root then
		return {}
	end

	local comments = {}
	local ft = vim.bo.filetype

	-- Handle different comment types based on language
	local queries = {
		-- Most languages use 'comment' node
		default = "(comment) @comment",
		-- Some languages might have different comment node names
		c = "(comment) @comment",
		cpp = "(comment) @comment",
		javascript = "(comment) @comment",
		typescript = "(comment) @comment",
		python = "(comment) @comment",
		lua = "(comment) @comment",
		go = "(comment) @comment",
		rust = "(comment) @comment",
		java = "(comment) @comment",
		php = "(comment) @comment",
		ruby = "(comment) @comment",
		shell = "(comment) @comment",
		bash = "(comment) @comment",
		yaml = "(comment) @comment",
		toml = "(comment) @comment"
	}

	local query_string = queries[ft] or queries.default
	local ok, query = pcall(vim.treesitter.query.parse, ft, query_string)

	if not ok or not query then
		return {}
	end

	for id, node in query:iter_captures(root, 0) do
		if query.captures[id] == "comment" then
			local start_row = node:range()
			local text = vim.treesitter.get_node_text(node, 0)
			table.insert(comments, {
				node = node,
				text = text:gsub("^%s*", ""):gsub("%s*$", ""), -- Trim whitespace
				line = start_row + 1                           -- Convert to 1-based line number
			})
		end
	end

	return comments
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

-- Get cached regions, updating if necessary
function M.get_cached_regions()
	local current_buf = vim.api.nvim_get_current_buf()
	local changedtick = vim.api.nvim_buf_get_changedtick(current_buf)
	
	-- Cache regions for performance, but invalidate on buffer or content changes
	if not M.cached_regions or M.cached_buffer ~= current_buf or M.cached_changedtick ~= changedtick then
		M.cached_regions = M.get_regions()
		M.cached_buffer = current_buf
		M.cached_changedtick = changedtick
	end
	
	return M.cached_regions
end

-- Get fold level for a line
function M.get_fold_level(lnum)
	local regions = M.get_cached_regions()

	for _, region in ipairs(regions) do
		if lnum == region.start then
			return ">1" -- Start fold at level 1
		elseif lnum == region.ending then
			return "<1" -- End fold at level 1
		end
	end

	return "=" -- Use previous fold level
end

-- Get fold text for a region
function M.get_fold_text(start_line)
	local regions = M.get_cached_regions()

	-- Find the region that starts at this line
	for _, region in ipairs(regions) do
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
	M.cached_changedtick = nil
end

-- Clear cache (useful for testing)
function M.clear_cache()
	M.cached_regions = nil
	M.cached_buffer = nil
	M.cached_changedtick = nil
end

return M
