-- Minimal Neovim config for testing region-folding plugin
-- Usage: nvim -u minimal_config.lua

-- Set up basic vim options
vim.opt.compatible = false
vim.opt.runtimepath:prepend('/Users/nma/dev/region-folding')

-- Add treesitter paths
vim.opt.runtimepath:prepend('/Users/nma/.local/share/nvim/lazy/nvim-treesitter')

-- Set treesitter parser path
vim.treesitter.language.add('go', {
    path = '/Users/nma/.local/share/nvim/treesitter/parser/go.so'
})

-- Basic settings for folding - regions will be manually closed
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- Enable treesitter folding as default
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'

-- Load and setup the plugin
local ok, plugin = pcall(require, 'region-folding')
if not ok then
	print("❌ Failed to load region-folding: " .. tostring(plugin))
	return
end

plugin.setup({
	region_text = { start = "#region", ending = "#endregion" },
	space_after_comment = true,
	fold_indicator = "▼"
})

-- Define signs for region markers
vim.fn.sign_define("RegionStart", { text = "▶", texthl = "DiagnosticInfo" })
vim.fn.sign_define("RegionEnd", { text = "◀", texthl = "DiagnosticHint" })

-- Add command to show debug info
vim.api.nvim_create_user_command('DebugRegions', function()
	local ts = require('region-folding.treesitter')
	local regions = ts.get_regions()
	print("=== Region Debug Info ===")
	print("Found " .. #regions .. " regions:")
	for i, region in ipairs(regions) do
		print(string.format("  %d: lines %d-%d (%s)", i, region.start, region.ending, region.title or "no title"))
		-- Place signs
		vim.fn.sign_place(0, "RegionFold", "RegionStart", "", {lnum = region.start})
		vim.fn.sign_place(0, "RegionFold", "RegionEnd", "", {lnum = region.ending})
	end
	
	-- Check fold settings
	print("=== Fold Settings ===")
	print("foldmethod: " .. vim.wo.foldmethod)
	print("foldexpr: " .. vim.wo.foldexpr)
	print("foldlevel: " .. vim.wo.foldlevel)
	print("foldlevelstart: " .. vim.opt.foldlevelstart:get())
	
	-- Test fold level function manually
	print("=== Manual Fold Level Test ===")
	for line = 10, 12 do
		local level = require('region-folding').get_fold_level(line)
		print(string.format("Line %d: fold level = %s", line, level))
	end
end, {})

-- Add command to manually refresh folds
vim.api.nvim_create_user_command('RefreshFolds', function()
	vim.cmd('set foldmethod=expr')
	vim.cmd([[set foldexpr=v:lua.require'region-folding'.get_fold_level(v:lnum)]])
	vim.cmd('normal! zx')
end, {})

-- Add command to test treesitter folding on main function
vim.api.nvim_create_user_command('TestMainFold', function()
	local line = 95  -- main function line
	print("Testing fold at line " .. line)
	print("Treesitter fold level:", vim.fn.eval('nvim_treesitter#foldexpr()'))
	vim.cmd('normal! ' .. line .. 'G')
	vim.cmd('normal! za')
end, {})

-- Add command to test fold navigation
vim.api.nvim_create_user_command('TestFoldNav', function()
	print("Testing fold navigation:")
	print("Current line:", vim.fn.line('.'))
	vim.cmd('normal! gg')  -- Go to top
	vim.cmd('normal! zj')  -- Go to next fold
	print("After zj from top, line:", vim.fn.line('.'))
	vim.cmd('normal! zj')  -- Go to next fold
	print("After second zj, line:", vim.fn.line('.'))
	vim.cmd('normal! zk')  -- Go to previous fold
	print("After zk, line:", vim.fn.line('.'))
end, {})

-- Add command to check fold levels at key lines
vim.api.nvim_create_user_command('CheckFoldLevels', function()
	local test_lines = {11, 35, 37, 69, 71, 93, 95, 100}
	print("=== Fold Level Check ===")
	print("Current foldlevel setting:", vim.wo.foldlevel)
	for _, line in ipairs(test_lines) do
		local level = require('region-folding').get_fold_level(line)
		local actual_level = vim.fn.foldlevel(line)
		print(string.format("Line %d: foldexpr=%s, actual=%d", line, level, actual_level))
	end
end, {})

-- Add custom fold toggle function
vim.api.nvim_create_user_command('ToggleRegionFold', function()
	local line = vim.fn.line('.')
	local ts = require('region-folding.treesitter')
	local regions = ts.get_regions()
	
	print("Current line: " .. line)
	print("Fold level: " .. require('region-folding').get_fold_level(line))
	
	-- Find if current line is in a region
	for _, region in ipairs(regions) do
		if line >= region.start and line <= region.ending then
			print(string.format("Found region: lines %d-%d (%s)", region.start, region.ending, region.title or "no title"))
			-- Navigate to region start and use normal fold commands
			vim.cmd(string.format('normal! %dGza', region.start))
			return
		end
	end
	
	print("No region found for current line")
end, {})

-- Map a key for testing
vim.keymap.set('n', '<leader>zz', '<cmd>ToggleRegionFold<cr>', { desc = 'Toggle region fold' })

print("✅ Region-folding plugin loaded successfully")
print("📁 Test file: /Users/nma/dev/region-folding/tests/fixtures/example.go")
print("🔧 Commands to test:")
print("   :e tests/fixtures/example.go")
print("   :lua print('Regions found:', #require('region-folding.treesitter').get_regions())")
print("   'za' to toggle fold, 'zo' to open, 'zc' to close")
print("   'zj' to go to next fold, 'zk' to go to previous fold")
print("   'zR' to open all folds, 'zM' to close all folds")
print("   By default, only regions are folded (auto-closed)")
print("   :TestMainFold to test main function folding")
print("   :TestFoldNav to test fold navigation (zj/zk)")
print("   :CheckFoldLevels to debug fold levels")
print("   :DebugRegions to show region debug info")

