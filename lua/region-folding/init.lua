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

-- Store original fold settings for each buffer
local original_fold_settings = {}

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

-- Check if a line is inside any region
local function is_inside_region(lnum)
	local ts = require('region-folding.treesitter')
	local regions = ts.get_regions()
	
	for _, region in ipairs(regions) do
		if lnum > region.start and lnum < region.ending then
			return true
		end
	end
	return false
end

-- Function to determine fold level for a given line
function M.get_fold_level(lnum)
	local bufnr = vim.api.nvim_get_current_buf()
	local original_settings = original_fold_settings[bufnr]

	-- First check if this line has a region marker
	local region_result = require('region-folding.treesitter').get_fold_level(lnum)

	-- If we found a region marker, use it
	if region_result ~= "=" then
		return region_result
	end

	-- Check if we're inside a region
	if is_inside_region(lnum) then
		return "="
	end

	-- If there are original fold settings and no region marker, use them
	if original_settings then
		if original_settings.foldmethod == "expr" and original_settings.foldexpr and 
		   original_settings.foldexpr ~= "" and original_settings.foldexpr ~= "0" then
			-- Save current line number
			local saved_v_lnum = vim.v.lnum
			-- Set v:lnum for the original foldexpr
			vim.v.lnum = lnum

			-- Evaluate the original foldexpr
			local ok, result = pcall(vim.api.nvim_eval, original_settings.foldexpr)
			-- Restore v:lnum
			vim.v.lnum = saved_v_lnum

			-- If evaluation succeeded and returned a valid fold level
			if ok and result ~= nil and result ~= -1 then
				-- Adjust treesitter fold levels so regions are at level 1 and treesitter at 2+
				if type(result) == "number" and result > 0 then
					result = result + 1
				elseif type(result) == "string" and result:match("^>%d+$") then
					local level = tonumber(result:match("%d+"))
					result = ">" .. (level + 1)
				elseif type(result) == "string" and result:match("^<%d+$") then
					local level = tonumber(result:match("%d+"))
					result = "<" .. (level + 1)
				elseif type(result) == "string" and result:match("^a%d+$") then
					local level = tonumber(result:match("%d+"))
					result = "a" .. (level + 1)
				elseif type(result) == "string" and result:match("^s%d+$") then
					local level = tonumber(result:match("%d+"))
					result = "s" .. (level + 1)
				end
				return result
			end
		elseif original_settings.foldmethod == "indent" then
			-- Use indent-based folding
			local indent = vim.fn.indent(lnum)
			local next_indent = vim.fn.indent(lnum + 1)
			
			if next_indent > indent then
				return ">" .. math.floor(next_indent / vim.bo.shiftwidth) + 1
			elseif indent > 0 then
				return math.floor(indent / vim.bo.shiftwidth) + 1
			end
		end
	end

	-- Default to maintaining current fold level
	return "="
end

-- Function to extract treesitter-based fold text (like function names)
local function get_treesitter_fold_text(start_line)
	local bufnr = vim.api.nvim_get_current_buf()
	local line_text = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, start_line, false)[1]
	
	if not line_text then
		return nil
	end
	
	-- Extract function names for different languages
	local patterns = {
		-- Go: func functionName(
		go = "func%s+([%w_]+)%s*%(",
		-- JavaScript/TypeScript: function functionName( or const functionName = 
		javascript = "function%s+([%w_]+)%s*%(", 
		typescript = "function%s+([%w_]+)%s*%(",
		-- Python: def function_name(
		python = "def%s+([%w_]+)%s*%(", 
		-- C/C++: returnType functionName(
		c = "%w+%s+([%w_]+)%s*%(", 
		cpp = "%w+%s+([%w_]+)%s*%(", 
		-- Lua: function functionName( or local function functionName(
		lua = "function%s+([%w_%.]+)%s*%(", 
		-- Rust: fn function_name(
		rust = "fn%s+([%w_]+)%s*%(", 
		-- Java: modifier returnType functionName(
		java = "%w+%s+%w+%s+([%w_]+)%s*%(", 
	}
	
	local ft = vim.bo.filetype
	local pattern = patterns[ft]
	
	if pattern then
		local func_name = line_text:match(pattern)
		if func_name then
			return func_name
		end
	end
	
	-- Fallback: try to extract any identifier before parentheses
	local fallback_name = line_text:match("([%w_]+)%s*%(")
	if fallback_name then
		return fallback_name
	end
	
	return nil
end

-- Function to create fold text
function M.get_fold_text()
	local ts = require('region-folding.treesitter')
	local title, lines_count = ts.get_fold_text(vim.v.foldstart)
	local fold_lines = vim.v.foldend - vim.v.foldstart + 1

	-- Create fold text
	if title then
		-- This is a region fold
		return string.format("%s %s (%d lines)", opt.fold_indicator, title, lines_count)
	else
		-- Try to get treesitter fold text (like function name)
		local func_name = get_treesitter_fold_text(vim.v.foldstart)
		if func_name then
			return string.format("%s %s() (%d lines)", opt.fold_indicator, func_name, fold_lines)
		else
			return string.format("%s folded region (%d lines)", opt.fold_indicator, fold_lines)
		end
	end
end

-- Create autocommands for buffer events
local function setup_autocommands()
	local group = vim.api.nvim_create_augroup("RegionFolding", {
		clear = true
	})
	vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
		group = group,
		callback = function()
			local bufnr = vim.api.nvim_get_current_buf()
			local current_foldexpr = vim.wo.foldexpr
			local current_foldmethod = vim.wo.foldmethod

			-- Only store the original fold settings if they're not our own
			if not original_fold_settings[bufnr] and current_foldexpr ~=
				"v:lua.require'region-folding'.get_fold_level(v:lnum)" then
				original_fold_settings[bufnr] = {
					foldmethod = current_foldmethod,
					foldexpr = current_foldexpr
				}
			end

			-- Always set up region-folding for hybrid folding (works with or without regions)
			vim.wo.foldmethod = "expr"
			vim.wo.foldexpr = "v:lua.require'region-folding'.get_fold_level(v:lnum)"
			vim.wo.foldtext = "v:lua.require'region-folding'.get_fold_text()"

			-- Refresh folding
			vim.cmd("silent! normal! zx")
			
			-- Close region folds by default if any exist
			local ts = require('region-folding.treesitter')
			local regions = ts.get_regions()
			if #regions > 0 then
				vim.schedule(function()
					for _, region in ipairs(regions) do
						vim.cmd(string.format("silent! %dfoldclose", region.start))
					end
				end)
			end
		end
	})

	-- Clear cache on buffer write to ensure fresh region detection
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		callback = function()
			local ts = require('region-folding.treesitter')
			ts.clear_cache()
		end
	})

	-- Clean up original_fold_settings when buffer is deleted
	vim.api.nvim_create_autocmd("BufDelete", {
		group = group,
		callback = function(args)
			original_fold_settings[args.buf] = nil
		end
	})
end

-- Initialize the plugin
setup_autocommands()

return M
