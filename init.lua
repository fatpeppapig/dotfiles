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

vim.g.mapleader = ';'

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
-- Fuzzy file open (mini.pick, backed by find — always current,
-- unaffected by git tracked/untracked status, hidden dirs excluded)
--
-- Uses -prune rather than -not -path: the earlier version only
-- filtered node_modules/etc out of the *results*, but still walked
-- every file inside those directories first — -prune stops find
-- from descending into them at all, which is what actually made
-- this slow on any real project.
-- ============================================================

vim.keymap.set('n', '<C-p>', function()
  local cwd = vim.fn.getcwd()
  local items = vim.fn.systemlist(
    [[find . -mindepth 1 \( -name node_modules -o -name .git -o -name dist -o -name build -o -name '.*' \) -prune -o -type f -print]]
  )
  require('mini.pick').start({
    source = { items = items, name = 'Files', cwd = cwd },
  })
end)

vim.opt.ignorecase = true
vim.opt.smartcase = true

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
-- Diagnostics — view the message under the cursor, or list every
-- diagnostic in the buffer in a browsable location list
-- ============================================================

vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

-- ============================================================
-- LSP
-- ============================================================

local function root_dir(start, names)
  local abs = vim.fn.fnamemodify(start, ':p')
  local found = vim.fs.find(names, { path = vim.fs.dirname(abs), upward = true })[1]
  return found and vim.fs.dirname(found) or vim.fs.dirname(abs)
end

-- Walks upward from a file (not a directory) looking for
-- node_modules/.bin/NAME, past monorepo/workspace boundaries where
-- binaries get hoisted to a root above the nearest package.json
local function local_bin(start, name)
  local dir = vim.fs.dirname(vim.fn.fnamemodify(start, ':p'))
  while dir ~= '/' do
    local path = dir .. '/node_modules/.bin/' .. name
    if vim.fn.filereadable(path) == 1 then return path end
    dir = vim.fs.dirname(dir)
  end
  return name
end

-- Classic TypeScript (<=6) ships tsserver.js; TypeScript 7+'s native
-- Go compiler does not — this distinguishes which LSP strategy applies
local function local_tsserver_lib(start)
  local dir = vim.fs.dirname(vim.fn.fnamemodify(start, ':p'))
  while dir ~= '/' do
    local path = dir .. '/node_modules/typescript/lib/tsserver.js'
    if vim.fn.filereadable(path) == 1 then return path end
    dir = vim.fs.dirname(dir)
  end
  return nil
end

-- True if this project has TypeScript at all, classic or native —
-- used to gate plain .js files, which should get LSP if TS is
-- present (it powers JS intelligence too) but stay silent if not,
-- rather than falling back to some unrelated global `tsc`
local function has_local_typescript(start)
  return local_tsserver_lib(start) ~= nil or local_bin(start, 'tsc') ~= 'tsc'
end

local function start_ts_lsp(args)
  local root = root_dir(args.file, { 'package.json', 'tsconfig.json' })
  local tslib = local_tsserver_lib(args.file)
  if tslib then
    -- Classic TypeScript (<=6): typescript-language-server wraps tsserver.js
    vim.lsp.start({
      name = 'ts-ls',
      cmd = { local_bin(args.file, 'typescript-language-server'), '--stdio' },
      root_dir = root,
      init_options = { tsserver = { path = tslib } },
    })
  else
    -- TypeScript 7+ (native Go compiler): tsc speaks LSP directly now
    vim.lsp.start({
      name = 'tsgo',
      cmd = { local_bin(args.file, 'tsc'), '--lsp', '--stdio' },
      root_dir = root,
    })
  end
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'typescript', 'typescriptreact' },
  callback = start_ts_lsp,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'javascript', 'javascriptreact' },
  callback = function(args)
    if not has_local_typescript(args.file) then return end  -- plain JS, no TS anywhere: skip quietly
    start_ts_lsp(args)
  end,
})

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
  pattern = 'svelte',
  callback = function(args)
    local root = root_dir(args.file, { 'package.json', 'svelte.config.js' })
    vim.lsp.start({
      name = 'svelte-ls',
      cmd = { local_bin(args.file, 'svelteserver'), '--stdio' },
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

vim.keymap.set('n', '<leader>i', function()
  vim.lsp.buf.code_action({
    context = { only = { 'source.addMissingImports.ts', 'source.addMissingImports' } },
    apply = true,
  })
end)

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

local function format_with_prettier(prettier, file, bufnr)
  local project_root = prettier:gsub('/node_modules/%.bin/prettier$', '')
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n') .. '\n'
  local result = vim.system(
    { prettier, '--stdin-filepath', file },
    { stdin = content, text = true, cwd = project_root }
  ):wait()
  if result.code == 0 then
    local view = vim.fn.winsaveview()
    local new_lines = vim.split((result.stdout:gsub('\n$', '')), '\n')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
    vim.fn.winrestview(view)
  else
    vim.notify('prettier failed: ' .. (result.stderr or 'unknown error'), vim.log.levels.WARN)
  end
end

vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { '*.ts', '*.tsx', '*.js', '*.jsx', '*.json', '*.css', '*.scss', '*.md', '*.svelte' },
  callback = function(args)
    local abs_file = vim.fn.fnamemodify(args.file, ':p')
    local prettier = local_prettier(abs_file)
    if prettier then
      format_with_prettier(prettier, abs_file, args.buf)
    else
      vim.lsp.buf.format({ async = false })
    end
  end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.rs',
  callback = function() vim.lsp.buf.format({ async = false }) end,
})
