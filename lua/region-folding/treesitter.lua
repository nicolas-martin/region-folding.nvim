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


-- Find all comments in the buffer using treesitter only
local function get_all_comments()
	local root = get_root()
	if not root then
		log("No treesitter parser available for filetype: %s", vim.bo.filetype)
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
		log("Failed to parse query for filetype %s: %s", ft, query_string)
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

	log("Found %d comments using treesitter", #comments)
	return comments
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
	local current_buf = vim.api.nvim_get_current_buf()
	
	-- Cache regions for performance, but make sure we're using the right buffer
	if not M.cached_regions or M.cached_buffer ~= current_buf or #M.cached_regions == 0 then
		log("Refreshing regions cache for buffer %d (cached_regions: %s, cached_buffer: %s, regions_count: %d)", 
		    current_buf, 
		    M.cached_regions and "exists" or "nil", 
		    M.cached_buffer or "nil",
		    M.cached_regions and #M.cached_regions or 0)
		M.cached_regions = M.get_regions()
		M.cached_buffer = current_buf
		log("Cached %d regions for buffer %d", #M.cached_regions, current_buf)
	end

	log("Checking line %d against %d cached regions", lnum, #M.cached_regions)
	for _, region in ipairs(M.cached_regions) do
		log("Region: start=%d, end=%d", region.start, region.ending)
		if lnum == region.start then
			log("Line %d is region start", lnum)
			return ">1" -- Start fold at level 1
		elseif lnum == region.ending then
			log("Line %d is region end", lnum)
			return "<1" -- End fold at level 1
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

-- Clear cache (useful for testing)
function M.clear_cache()
	M.cached_regions = nil
	M.cached_buffer = nil
end

return M
