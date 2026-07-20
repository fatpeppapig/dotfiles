-- ============================================================
-- Plugins (vim.pack — built into Neovim 0.12+, no bootstrap needed)
-- ============================================================

vim.pack.add({
  'https://github.com/nvim-mini/mini.nvim',
  'https://github.com/leafgarland/typescript-vim',
  'https://github.com/pangloss/vim-javascript',
  'https://github.com/mxw/vim-jsx',
  'https://github.com/evanleck/vim-svelte',
})

local pick = require('mini.pick')
pick.setup({
  source = { show = pick.default_show },  -- disable icons in file/buffer pickers
})

require('mini.files').setup({
  content = {
    prefix = function() return '', '' end,  -- disable icons (tofu boxes without a Nerd Font)
  },
})

require('mini.tabline').setup()

-- ============================================================
-- Basic Setup
-- ============================================================

vim.opt.mouse = 'a'
vim.opt.cursorline = true
vim.opt.tabpagemax = 80
vim.opt.wrap = false

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.shiftround = true
vim.opt.expandtab = true

vim.opt.smartindent = true
vim.opt.laststatus = 2
vim.opt.number = true
vim.opt.hlsearch = true
vim.opt.title = true
vim.opt.hidden = true

vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

vim.opt.clipboard = 'unnamedplus'

-- ============================================================
-- Colors
-- ============================================================


vim.cmd.colorscheme 'habamax'

vim.keymap.set('n', '<space>', '<Cmd>nohlsearch<Bar>echo<CR>', { silent = true })

-- ============================================================
-- Buffer / tab navigation
-- ============================================================

vim.keymap.set('n', 'bn', '<Cmd>bn<CR>')
vim.keymap.set('n', 'bp', '<Cmd>bp<CR>')
vim.keymap.set('n', 'bd', '<Cmd>bd<CR>')

vim.keymap.set('n', 'tn', '<Cmd>tabn<CR>')
vim.keymap.set('n', 'tp', '<Cmd>tabp<CR>')

-- ============================================================
-- Fuzzy file open (mini.pick)
-- ============================================================

vim.keymap.set('n', '<C-p>', function() require('mini.pick').builtin.files() end)

-- ============================================================
-- File explorer (mini.files)
-- ============================================================

vim.keymap.set('n', '<C-e>', function() require('mini.files').open() end)
vim.keymap.set('n', '<ESC>', function() require('mini.files').close() end)

vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  callback = function(args)
    local buf_id = args.data.buf_id
    vim.keymap.set('n', '<CR>', function()
      require('mini.files').go_in({ close_on_file = true })
    end, { buffer = buf_id })
  end,
})

-- ============================================================
-- LSP
-- ============================================================

local function root_dir(start, names)
  local abs = vim.fn.fnamemodify(start, ':p')
  local found = vim.fs.find(names, { path = vim.fs.dirname(abs), upward = true })[1]
  return found and vim.fs.dirname(found) or vim.fs.dirname(abs)
end

local function local_bin(root, name)
  local path = root .. '/node_modules/.bin/' .. name
  if vim.fn.filereadable(path) == 1 then return path end
  return name
end

local function local_tsserver_lib(root)
  local path = root .. '/node_modules/typescript/lib/tsserver.js'
  if vim.fn.filereadable(path) == 1 then return path end
  return nil
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'rust',
  callback = function(args)
    vim.lsp.start({
      name = 'rust-analyzer',
      cmd = { 'rust-analyzer' },
      root_dir = root_dir(args.file, { 'Cargo.toml' }),
    })
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  callback = function(args)
    local root = root_dir(args.file, { 'package.json', 'tsconfig.json' })
    local tslib = local_tsserver_lib(root)
    vim.lsp.start({
      name = 'ts-ls',
      cmd = { local_bin(root, 'typescript-language-server'), '--stdio' },
      root_dir = root,
      init_options = tslib and { tsserver = { path = tslib } } or nil,
    })
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'svelte',
  callback = function(args)
    local root = root_dir(args.file, { 'package.json', 'svelte.config.js' })
    vim.lsp.start({
      name = 'svelte-ls',
      cmd = { local_bin(root, 'svelteserver'), '--stdio' },
      root_dir = root,
    })
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local buf = args.buf
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = buf })
    vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, { buffer = buf })
    vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, { buffer = buf })
  end,
})

-- ============================================================
-- Format on save
-- ============================================================

local function local_prettier(start)
  local dir = vim.fs.dirname(vim.fn.fnamemodify(start, ':p'))
  while dir ~= '/' do
    local path = dir .. '/node_modules/.bin/prettier'
    if vim.fn.filereadable(path) == 1 then return path end
    dir = vim.fs.dirname(dir)
  end
  return nil
end

vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { '*.ts', '*.tsx', '*.js', '*.jsx', '*.json', '*.css', '*.scss', '*.md', '*.svelte' },
  callback = function(args)
    local abs_file = vim.fn.fnamemodify(args.file, ':p')
    local prettier = local_prettier(abs_file)
    if prettier then
      local view = vim.fn.winsaveview()
      vim.cmd('silent! %!' .. prettier .. ' --stdin-filepath ' .. vim.fn.shellescape(abs_file))
      if vim.v.shell_error ~= 0 then
        vim.cmd('undo')
        vim.notify('prettier failed, changes reverted', vim.log.levels.WARN)
      else
        vim.fn.winrestview(view)
      end
    else
      vim.lsp.buf.format({ async = false })
    end
  end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.rs',
  callback = function() vim.lsp.buf.format({ async = false }) end,
})
