-- Test suite for region-folding.nvim
local helpers = require('tests.helpers')

describe("region-folding", function()
	local plugin

	before_each(function()
		-- Setup clean environment
		plugin = require('region-folding')
		plugin.setup({
			region_text = {
				start = "#region",
				ending = "#endregion"
			},
			space_after_comment = true,
			fold_indicator = "▼",
			debug = false
		})
	end)

	after_each(function()
		-- Clean up
		helpers.cleanup_buffer()
	end)

	describe("JavaScript", function()
		it("should detect region markers in JavaScript comments", function()
			local content = {
				"function example() {",
				"    // #region Configuration",
				"    const config = {",
				"        host: 'localhost',",
				"        port: 3000",
				"    };",
				"    // #endregion",
				"",
				"    return config;",
				"}"
			}

			local buf = helpers.create_buffer("javascript", content)
			local ts = require('region-folding.treesitter')
			local regions = ts.get_regions()

			assert.equal(1, #regions)
			assert.equal(2, regions[1].start)
			assert.equal(7, regions[1].ending)
			assert.equal("Configuration", regions[1].title)
		end)

		it("should create proper fold levels for JavaScript", function()
			local content = {
				"// #region Setup",
				"const x = 1;",
				"// #endregion"
			}

			helpers.create_buffer("javascript", content)
			local fold_level = plugin.get_fold_level(1)
			assert.equal("a1", fold_level)

			fold_level = plugin.get_fold_level(3)
			assert.equal("s1", fold_level)
		end)
	end)

	describe("Python", function()
		it("should detect region markers in Python comments", function()
			local content = {
				"def main():",
				"    # #region Helper Functions",
				"    def validate(data):",
				"        return True",
				"",
				"    def process(data):",
				"        return data",
				"    # #endregion",
				"",
				"    return process(validate({}))"
			}

			helpers.create_buffer("python", content)
			local ts = require('region-folding.treesitter')
			local regions = ts.get_regions()

			assert.equal(1, #regions)
			assert.equal(2, regions[1].start)
			assert.equal(8, regions[1].ending)
			assert.equal("Helper Functions", regions[1].title)
		end)
	end)

	describe("Lua", function()
		it("should detect region markers in Lua comments", function()
			local content = {
				"local M = {}",
				"",
				"-- #region Public API",
				"function M.setup(opts)",
				"    -- implementation",
				"end",
				"",
				"function M.get_fold_level(lnum)",
				"    -- implementation",
				"end",
				"-- #endregion",
				"",
				"return M"
			}

			helpers.create_buffer("lua", content)
			local ts = require('region-folding.treesitter')
			local regions = ts.get_regions()

			assert.equal(1, #regions)
			assert.equal(3, regions[1].start)
			assert.equal(11, regions[1].ending)
			assert.equal("Public API", regions[1].title)
		end)
	end)

	describe("Go", function()
		it("should detect region markers in Go comments", function()
			local content = {
				"package main",
				"",
				"// #region HTTP Handlers",
				"func handleGet(w http.ResponseWriter, r *http.Request) {",
				"    // implementation",
				"}",
				"",
				"func handlePost(w http.ResponseWriter, r *http.Request) {",
				"    // implementation",
				"}",
				"// #endregion"
			}

			helpers.create_buffer("go", content)
			local ts = require('region-folding.treesitter')
			local regions = ts.get_regions()

			assert.equal(1, #regions)
			assert.equal(3, regions[1].start)
			assert.equal(11, regions[1].ending)
			assert.equal("HTTP Handlers", regions[1].title)
		end)
	end)

	describe("Rust", function()
		it("should detect region markers in Rust comments", function()
			local content = {
				"// #region Structs",
				"struct User {",
				"    name: String,",
				"    age: u32,",
				"}",
				"",
				"struct Config {",
				"    debug: bool,",
				"}",
				"// #endregion"
			}

			helpers.create_buffer("rust", content)
			local ts = require('region-folding.treesitter')
			local regions = ts.get_regions()

			assert.equal(1, #regions)
			assert.equal(1, regions[1].start)
			assert.equal(10, regions[1].ending)
			assert.equal("Structs", regions[1].title)
		end)
	end)

	describe("Nested regions", function()
		it("should handle nested regions correctly", function()
			local content = {
				"// #region Outer",
				"const outer = true;",
				"// #region Inner",
				"const inner = true;",
				"// #endregion",
				"const more = true;",
				"// #endregion"
			}

			helpers.create_buffer("javascript", content)
			local ts = require('region-folding.treesitter')
			local regions = ts.get_regions()

			-- Should find both regions
			assert.equal(2, #regions)

			-- First region should be the inner one (processed first)
			assert.equal(3, regions[1].start)
			assert.equal(5, regions[1].ending)
			assert.equal("Inner", regions[1].title)

			-- Second region should be the outer one
			assert.equal(1, regions[2].start)
			assert.equal(7, regions[2].ending)
			assert.equal("Outer", regions[2].title)
		end)
	end)

	describe("Edge cases", function()
		it("should handle regions without titles", function()
			local content = {
				"// #region",
				"const x = 1;",
				"// #endregion"
			}

			helpers.create_buffer("javascript", content)
			local ts = require('region-folding.treesitter')
			local regions = ts.get_regions()

			assert.equal(1, #regions)
			assert.equal(1, regions[1].start)
			assert.equal(3, regions[1].ending)
			assert.is_nil(regions[1].title)
		end)

		it("should handle unclosed regions gracefully", function()
			local content = {
				"// #region Unclosed",
				"const x = 1;",
				"const y = 2;"
			}

			helpers.create_buffer("javascript", content)
			local ts = require('region-folding.treesitter')
			local regions = ts.get_regions()

			-- Should not create any regions for unclosed ones
			assert.equal(0, #regions)
		end)

		it("should handle orphaned endregion", function()
			local content = {
				"const x = 1;",
				"// #endregion",
				"const y = 2;"
			}

			helpers.create_buffer("javascript", content)
			local ts = require('region-folding.treesitter')
			local regions = ts.get_regions()

			-- Should not create any regions
			assert.equal(0, #regions)
		end)
	end)

	describe("Fold text", function()
		it("should generate correct fold text with title", function()
			local content = {
				"// #region Test Region",
				"const x = 1;",
				"const y = 2;",
				"// #endregion"
			}

			helpers.create_buffer("javascript", content)
			vim.v.foldstart = 1
			vim.v.foldend = 4

			local fold_text = plugin.get_fold_text()
			assert.equal("▼ Test Region (4 lines)", fold_text)
		end)

		it("should generate correct fold text without title", function()
			local content = {
				"// #region",
				"const x = 1;",
				"// #endregion"
			}

			helpers.create_buffer("javascript", content)
			vim.v.foldstart = 1
			vim.v.foldend = 3

			local fold_text = plugin.get_fold_text()
			assert.equal("▼ folded region (3 lines)", fold_text)
		end)
	end)

	describe("Integration with existing foldexpr", function()
		it("should prioritize region markers over existing foldexpr", function()
			local content = {
				"function test() {",
				"    // #region Config",
				"    const config = {};",
				"    // #endregion",
				"    return config;",
				"}"
			}

			helpers.create_buffer("javascript", content)

			-- Simulate existing foldexpr that would fold the function
			helpers.set_original_foldexpr("nvim_treesitter#foldexpr()")

			-- Region markers should take priority
			local fold_level = plugin.get_fold_level(2)
			assert.equal("a1", fold_level)

			fold_level = plugin.get_fold_level(4)
			assert.equal("s1", fold_level)

			-- Non-region lines should use original foldexpr
			fold_level = plugin.get_fold_level(1)
			assert.not_equal("=", fold_level) -- Should evaluate original foldexpr
		end)
	end)
end)

