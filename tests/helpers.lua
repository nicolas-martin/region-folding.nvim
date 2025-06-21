-- Test helpers for region-folding.nvim tests
local M = {}

-- Create a buffer with given filetype and content
function M.create_buffer(filetype, content)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(buf)
	vim.bo.filetype = filetype

	if content then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
	end

	return buf
end

-- Clean up the current buffer
function M.cleanup_buffer()
	local buf = vim.api.nvim_get_current_buf()
	if vim.api.nvim_buf_is_valid(buf) then
		vim.api.nvim_buf_delete(buf, { force = true })
	end
end

-- Set up a mock original foldexpr for testing integration
function M.set_original_foldexpr(expr)
	local plugin = require('region-folding')
	local bufnr = vim.api.nvim_get_current_buf()

	-- Access the internal original_foldexprs table (this is a bit hacky for testing)
	-- In a real scenario, this would be set automatically by the plugin
	local original_foldexprs = {}
	if plugin._test_set_original_foldexpr then
		plugin._test_set_original_foldexpr(bufnr, expr)
	else
		-- Set the window option to simulate existing foldexpr
		vim.wo.foldexpr = expr
	end
end

-- Create test fixtures for different file types
function M.create_fixtures()
	local fixtures = {}

	-- JavaScript fixture
	fixtures.javascript = {
		"function example() {",
		"    // #region Configuration Setup",
		"    const config = {",
		"        host: 'localhost',",
		"        port: 3000,",
		"        ssl: false",
		"    };",
		"    // #endregion",
		"",
		"    // #region Helper Functions",
		"    function validateConfig(cfg) {",
		"        return cfg.host && cfg.port;",
		"    }",
		"",
		"    function initConfig(cfg) {",
		"        return { ...config, ...cfg };",
		"    }",
		"    // #endregion",
		"",
		"    return initConfig(config);",
		"}"
	}

	-- Python fixture
	fixtures.python = {
		"class DataProcessor:",
		"    def __init__(self):",
		"        # #region Configuration",
		"        self.config = {",
		"            'batch_size': 100,",
		"            'timeout': 30",
		"        }",
		"        # #endregion",
		"",
		"    # #region Processing Methods",
		"    def process_batch(self, data):",
		"        '''Process a batch of data'''",
		"        return [self._process_item(item) for item in data]",
		"",
		"    def _process_item(self, item):",
		"        '''Process a single item'''",
		"        return item.strip().lower()",
		"    # #endregion",
		"",
		"    def run(self):",
		"        pass"
	}

	-- Lua fixture
	fixtures.lua = {
		"local M = {}",
		"",
		"-- #region Default Configuration",
		"local default_config = {",
		"    enabled = true,",
		"    debug = false,",
		"    max_depth = 10",
		"}",
		"-- #endregion",
		"",
		"-- #region Public API",
		"function M.setup(user_config)",
		"    local config = vim.tbl_deep_extend('force', default_config, user_config or {})",
		"    M.config = config",
		"end",
		"",
		"function M.process(data)",
		"    if not M.config.enabled then",
		"        return data",
		"    end",
		"    return data",
		"end",
		"-- #endregion",
		"",
		"return M"
	}

	-- Go fixture
	fixtures.go = {
		"package main",
		"",
		"import (",
		'    "fmt"',
		'    "net/http"',
		")",
		"",
		"// #region Configuration",
		"type Config struct {",
		"    Host string",
		"    Port int",
		"    Debug bool",
		"}",
		"",
		"var defaultConfig = Config{",
		'    Host: "localhost",',
		"    Port: 8080,",
		"    Debug: false,",
		"}",
		"// #endregion",
		"",
		"// #region HTTP Handlers",
		"func handleHealth(w http.ResponseWriter, r *http.Request) {",
		'    fmt.Fprintf(w, "OK")',
		"}",
		"",
		"func handleAPI(w http.ResponseWriter, r *http.Request) {",
		'    fmt.Fprintf(w, "API Response")',
		"}",
		"// #endregion",
		"",
		"func main() {",
		"    http.HandleFunc(\"/health\", handleHealth)",
		"    http.HandleFunc(\"/api\", handleAPI)",
		"    http.ListenAndServe(\":8080\", nil)",
		"}"
	}

	return fixtures
end

-- Write fixture to file
function M.write_fixture(filepath, content)
	local file = io.open(filepath, 'w')
	if file then
		for _, line in ipairs(content) do
			file:write(line .. '\n')
		end
		file:close()
		return true
	end
	return false
end

-- Load fixture from file and create buffer
function M.load_fixture_buffer(filepath, filetype)
	local file = io.open(filepath, 'r')
	if not file then
		error("Could not open fixture file: " .. filepath)
	end

	local content = {}
	for line in file:lines() do
		table.insert(content, line)
	end
	file:close()

	return M.create_buffer(filetype, content)
end

return M

