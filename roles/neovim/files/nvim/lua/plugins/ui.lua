return {
  { "catppuccin/nvim", name = "catppuccin", priority = 1000, config = function()
    vim.cmd.colorscheme "catppuccin"
  end },
  {
    "folke/which-key.nvim",
      event = "VeryLazy",
      config = true,
      init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 300
      end,
        opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
       },
      keys = {
        {
          "<leader>?",
          function()
            require("which-key").show({ global = true })
          end,
          desc = "Buffer Local Keymaps (which-key)",
        },
      },
  },
  {'akinsho/toggleterm.nvim',
    version = "*",
    opts = {
      open_mapping = [[<c-j>]],
    }
  },
  { 'kosayoda/nvim-lightbulb' },
  { 'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim', "nvim-treesitter/nvim-treesitter" },
    lazy = false,
    config = function()
      require('telescope').setup({
        defaults = {
          layout_strategy = 'flex',
          layout_config = {
            width = 0.9,
            height = 0.9,
            prompt_position = 'top',
            preview_cutoff = 120,
          },
          mappings = {
            i = {
              ["<esc>"] = require('telescope.actions').close,
            },
          },
        },
      })
    end,
    keys = {
      {
        "<C-p>",
	function() require("telescope.builtin").find_files() end,
	desc = "Find file (Telescope)",
      },
      {
	"<leader>fg",
	function() require("telescope.builtin").live_grep() end,
	desc = "Live grep (Telescope)",
      },
      {
	"<leader>fb",
	function() require("telescope.builtin").buffers() end,
	desc = "Buffers (Telescope)",
      },
      {
	"<leader>fh",
	function() require("telescope.builtin").help_tags() end,
	desc = "Help tags (Telescope)",
      },
    },
  },
  { 'stevearc/dressing.nvim', opts = {}, },
  {
    'mrjones2014/legendary.nvim',
    version = 'v2.13.12',
    priority = 10000,
    lazy = false,
    init = function()
      require('legendary').setup({
        extensions = { lazy_nvim = true },
        include_builtin = true,
        include_legendary_cmds = false,
        auto_register_which_key = true,
        select_prompt = nil,
      })
    end,
    keys = {
      {
        "<C-S-p>",
        function() require('legendary').find() end,
        desc = "Command pallete",
      },
    },
    dependencies = { 'nvim-telescope/telescope.nvim' },
  },
  { 'mrjones2014/smart-splits.nvim', version = '>=1.0.0' },
  {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    opts = {},
    cmd = "NvimTreeToggle",
    keys = {
      {
	"<C-b>",
	"<cmd>NvimTreeToggle<cr>",
	desc = "Toggle NvimTree",
      },
    },
  }
}
