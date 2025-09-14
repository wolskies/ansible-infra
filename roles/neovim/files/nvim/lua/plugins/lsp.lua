return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPost", "BufNewFile" }, -- Load LSP when a buffer is opened or created
        config = function()
            local lspconfig = require("lspconfig")
            lspconfig.lua_ls.setup({})
            lspconfig.rust_analyzer.setup({})
            lspconfig.pyright.setup({})
        end,
        keys = {
            {
                "K",
                function()
                    vim.lsp.buf.hover()
                end,
                desc = "LSP Hover",
            },
	    {
		"<leader>gd",
		function()
		    vim.lsp.buf.definition()
		end,
		desc = "Go to Definition",
	    },
	    {
		"<leader>gr",
		function()
		    vim.lsp.buf.references()
		end,
		desc = "Go to References",
	    },
	    {
		"<leader>gi",
		function()
		    vim.lsp.buf.implementation()
		end,
		desc = "Go to Implementation",
	    },
	    {
		"<leader>rn",
		function()
		    vim.lsp.buf.rename()
		end,
		desc = "Rename Symbol",
	    },
	    {
		"<leader>ca",
		function()
		    vim.lsp.buf.code_action()
		end,
		desc = "Code Action",
	    }
        }
    },
}
