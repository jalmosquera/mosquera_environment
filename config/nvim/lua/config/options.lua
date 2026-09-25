-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Keep runtime artifacts out of the repository-backed Neovim configuration.
local state = vim.fn.stdpath("state")

vim.opt.undodir = state .. "/undo//"
vim.opt.spellfile = state .. "/spell/en.utf-8.add"
vim.opt.backupdir = state .. "/backup//"
vim.opt.directory = state .. "/swap//"
vim.opt.viewdir = state .. "/view//"
vim.opt.shadafile = state .. "/shada/main.shada"
