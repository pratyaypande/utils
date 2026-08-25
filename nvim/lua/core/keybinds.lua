-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<leader>?', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>p?', vim.diagnostic.goto_prev)
vim.keymap.set('n', '<leader>n?', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', '<F10>', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', '<F12>', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', '<S-F12>', "<cmd>tab split | lua vim.lsp.buf.definition()<CR>", opts)
    vim.keymap.set('n', '<M-F12>', '<C-o>', opts)
    vim.keymap.set('n', '<M-F10>', '<C-o>', opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<leader>fr', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})

-- State flag controlling auto-hover
local auto_hover_enabled = true

-- Dedicated augroup so we can manage this cleanly
local hover_group = vim.api.nvim_create_augroup('AutoHover', { clear = true })

vim.api.nvim_create_autocmd("CursorHold", {
  group = hover_group,
  pattern = { "*.c", "*.cpp", "*.h", "*.hpp" },
  callback = function()
    if auto_hover_enabled then
      vim.lsp.buf.hover()
    end
  end,
})

vim.o.updatetime = 500

-- Manual hover trigger (always works, regardless of toggle state)
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'LSP hover documentation' })

-- Toggle auto-hover on/off
vim.keymap.set('n', '<leader>de', function()
  auto_hover_enabled = not auto_hover_enabled
  vim.notify('Auto-hover ' .. (auto_hover_enabled and 'enabled' or 'disabled'))
end, { desc = 'Toggle auto-hover on CursorHold' })
