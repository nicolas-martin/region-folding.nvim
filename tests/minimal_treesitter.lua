-- Install treesitter if not already installed
local parser_install_dir = vim.fn.stdpath("data") .. "/treesitter"
vim.opt.runtimepath:append(parser_install_dir)

-- Install nvim-treesitter if not present
local treesitter_path = vim.fn.stdpath("data") .. "/site/pack/nvim-treesitter/start/nvim-treesitter"
if vim.fn.empty(vim.fn.glob(treesitter_path)) > 0 then
    vim.fn.system({"git", "clone", "https://github.com/nvim-treesitter/nvim-treesitter.git", treesitter_path})
end

-- Add treesitter to runtime path
vim.opt.runtimepath:append(treesitter_path)

-- Configure treesitter
local opts = {
    parser_install_dir = parser_install_dir,
    ensure_installed = {"go"},
    sync_install = true,
    highlight = {
        enable = true
    },
    indent = {
        enable = true
    },
    fold = {
        enable = true
    }
}

-- Set up treesitter config
require("nvim-treesitter.configs").setup(opts)
print("Treesitter config setup complete")

-- Install the Go parser if needed
local install = require("nvim-treesitter.install")
install.ensure_installed("go")
print("Ensured Go parser is installed")

-- Wait for FileType and then set up folding
vim.api.nvim_create_autocmd({"FileType"}, {
    pattern = {"go"},
    callback = function()
        print("FileType 'go' detected")

        -- Schedule the parser check and folding setup
        vim.schedule(function()
            -- Check parser status
            local parser = vim.treesitter.get_parser(0)
            print("Treesitter parser status: " .. tostring(parser ~= nil))
            if parser then
                print("Parser language: " .. parser:lang())
            end

            -- Configure folding
            vim.opt.foldmethod = "expr"
            print("Set foldmethod: " .. vim.opt.foldmethod:get())

            vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
            print("Set foldexpr: " .. vim.opt.foldexpr:get())

            vim.opt.foldenable = true
            print("Set foldenable: " .. tostring(vim.opt.foldenable:get()))

            vim.opt.foldlevel = 99
            print("Set foldlevel: " .. vim.opt.foldlevel:get())

            vim.opt.foldminlines = 3
            print("Set foldminlines: " .. vim.opt.foldminlines:get())
        end)
    end
})
