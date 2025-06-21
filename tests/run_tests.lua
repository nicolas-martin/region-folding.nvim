#!/usr/bin/env lua

-- Simple test runner for region-folding.nvim
-- This can be run with: nvim --headless -c "luafile tests/run_tests.lua" -c "quit"

local function run_tests()
	-- Add the plugin to the Lua path
	local plugin_path = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":p:h:h")
	package.path = plugin_path .. "/lua/?.lua;" .. package.path

	-- Mock vim API for testing
	if not vim then
		vim = {
			api = {
				nvim_create_buf = function() return 1 end,
				nvim_set_current_buf = function() end,
				nvim_get_current_buf = function() return 1 end,
				nvim_buf_set_lines = function() end,
				nvim_buf_get_lines = function() return {} end,
				nvim_buf_delete = function() end,
				nvim_buf_is_valid = function() return true end,
				nvim_create_augroup = function() return 1 end,
				nvim_create_autocmd = function() end,
				nvim_eval = function(expr)
					-- Mock treesitter foldexpr
					if expr == "nvim_treesitter#foldexpr()" then
						return "1"
					end
					return "0"
				end
			},
			bo = {},
			wo = {},
			v = { lnum = 1, foldstart = 1, foldend = 3 },
			fn = {
				fnamemodify = function(path, mods) return path end
			},
			cmd = function() end,
			deepcopy = function(t)
				local copy = {}
				for k, v in pairs(t) do copy[k] = v end
				return copy
			end,
			tbl_deep_extend = function(behavior, tbl1, tbl2)
				local result = {}
				for k, v in pairs(tbl1) do result[k] = v end
				for k, v in pairs(tbl2 or {}) do result[k] = v end
				return result
			end,
			treesitter = {
				get_parser = function() return { parse = function() return { { root = function() return {} end } } end } end,
				get_node_text = function() return "// #region test" end,
				query = {
					parse = function()
						return {
							iter_captures = function() return function() return nil end end,
							captures = {}
						}
					end
				}
			}
		}
	end

	print("Running region-folding.nvim tests...")

	-- Basic smoke test
	local plugin = require('region-folding')
	plugin.setup({
		region_text = {
			start = "#region",
			ending = "#endregion"
		},
		debug = true
	})

	print("✓ Plugin loaded successfully")

	-- Test treesitter module
	local ts = require('region-folding.treesitter')
	ts.setup({
		region_text = { start = "#region", ending = "#endregion" },
		debug = true
	})

	print("✓ Treesitter module loaded successfully")

	-- Test fold level function
	local fold_level = plugin.get_fold_level(1)
	print("✓ Fold level function works: " .. tostring(fold_level))

	-- Test fold text function
	local fold_text = plugin.get_fold_text()
	print("✓ Fold text function works: " .. fold_text)

	print("\nAll basic tests passed! ✓")
	print("\nTo run comprehensive tests, use a test framework like:")
	print("- busted (for Lua)")
	print("- plenary.nvim (for Neovim)")
	print("- Add this to your nvim config and run :luafile tests/region_folding_spec.lua")
end

-- Run tests
local ok, err = pcall(run_tests)
if not ok then
	print("Test failed: " .. tostring(err))
	os.exit(1)
else
	print("Tests completed successfully!")
end

