-- Helper function to create a mock buffer with content
local function create_mock_buffer(content)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(content, '\n'))
    return bufnr
end

describe('treesitter folding', function()
    local bufnr

    before_each(function()
        -- Create a new buffer with Go code
        bufnr = create_mock_buffer([[
package main

import (
    "fmt"
)

type User struct {
    Name string
    Age  int
}

func main() {
    user := User{
        Name: "test",
        Age: 25,
    }
    fmt.Println(user)
}
]])
        -- Set buffer as current and configure
        vim.api.nvim_set_current_buf(bufnr)
        vim.bo.filetype = 'go'

        -- Load minimal treesitter config
        dofile('tests/minimal_treesitter.lua')
    end)

    after_each(function()
        vim.api.nvim_buf_delete(bufnr, {
            force = true
        })
    end)

    it('should create folds for Go structures', function()
        -- Wait a bit for TreeSitter to initialize
        vim.wait(500)

        -- Debug: Print node info at import line
        local ts_utils = require('nvim-treesitter.ts_utils')
        local node_at_import = ts_utils.get_node_at_pos(bufnr, 2, 0) -- line 3 is 2 in 0-indexed
        if node_at_import then
            local start_row, _, end_row, _ = node_at_import:range()
            print(string.format("Node at line 3: type=%s, range=(%d, %d)", node_at_import:type(), start_row + 1,
                end_row + 1 -- Convert to 1-indexed
            ))
        else
            print("No node found at line 3")
        end

        -- Check fold levels at key points
        -- Import block should be foldable
        assert.is_true(vim.fn.foldlevel(3) > 0, "Import block should be foldable")

        -- Struct definition should be foldable
        assert.is_true(vim.fn.foldlevel(7) > 0, "Struct definition should be foldable")

        -- Main function should be foldable
        assert.is_true(vim.fn.foldlevel(11) > 0, "Main function should be foldable")
    end)

    it('should respect foldnestmax setting', function()
        vim.wait(500)

        -- Get the maximum fold level in the buffer
        local max_fold = 0
        for i = 1, vim.fn.line('$') do
            max_fold = math.max(max_fold, vim.fn.foldlevel(i))
        end

        assert.is_true(max_fold <= vim.opt.foldnestmax:get(), "Fold nesting should not exceed foldnestmax")
    end)

    it('should properly calculate fold levels', function()
        vim.wait(500)

        -- Check specific fold levels
        -- Top level (package, import) should be level 1
        assert.equals(1, vim.fn.foldlevel(3), "Import block should be level 1")

        -- Struct definition should be level 1
        assert.equals(1, vim.fn.foldlevel(7), "Struct should be level 1")

        -- Inside struct should be level 2
        assert.equals(2, vim.fn.foldlevel(8), "Inside struct should be level 2")

        -- Main function should be level 1
        assert.equals(1, vim.fn.foldlevel(11), "Main function should be level 1")
    end)
end)
