local map = vim.keymap.set

map("n", "<leader>W", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<leader>Q", "<cmd>qa<cr>", { desc = "Quit all" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
