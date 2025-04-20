local region_folding = require('region-folding')

-- Helper function to create a mock buffer with content
local function create_mock_buffer(content)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(content, '\n'))
    return bufnr
end

describe('region-folding', function()
    -- Setup and teardown
    local bufnr

    before_each(function()
        -- Create a new buffer for each test
        bufnr = create_mock_buffer([[
-- #region Configuration
local config = {
    host = "localhost",
    port = 8080
}
-- #endregion

-- #region Functions
local function test()
    return true
end
-- #endregion
]])
        vim.api.nvim_set_current_buf(bufnr)
        vim.bo.filetype = 'lua'
        region_folding.setup({})
    end)

    after_each(function()
        -- Clean up the buffer
        vim.api.nvim_buf_delete(bufnr, {
            force = true
        })
    end)

    describe('fold level detection', function()
        it('should detect region start', function()
            local level = region_folding.get_fold_level(1)
            assert.equals('a1', level)
        end)

        it('should detect region end', function()
            local level = region_folding.get_fold_level(6)
            assert.equals('s1', level)
        end)

        it('should maintain fold level for non-region lines', function()
            local level = region_folding.get_fold_level(3)
            assert.equals('=', level)
        end)
    end)

    describe('fold text generation', function()
        it('should include region title in fold text', function()
            -- Set up fold start and end
            vim.v = vim.v or {}
            vim.v.foldstart = 1
            vim.v.foldend = 6

            local text = region_folding.get_fold_text()
            assert.truthy(text:match('Configuration'))
            assert.truthy(text:match('6 lines'))
        end)
    end)

    describe('language support', function()
        it('should handle different comment styles', function()
            -- Test JavaScript-style comments
            vim.bo.filetype = 'javascript'
            local js_buffer = create_mock_buffer([[
// #region API
const api = {
    version: '1.0'
};
// #endregion
]])
            vim.api.nvim_set_current_buf(js_buffer)

            local level = region_folding.get_fold_level(1)
            assert.equals('a1', level)

            vim.api.nvim_buf_delete(js_buffer, {
                force = true
            })
        end)
    end)
end)
