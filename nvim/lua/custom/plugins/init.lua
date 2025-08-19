-- you can add your own plugins here or in other files in this directory!
--  i promise not to create any merge conflicts in this directory :)
--
-- see the kickstart.nvim readme for more information
-- format on save and linters
return {
	'nvimtools/none-ls.nvim',
	dependencies = {
		'nvimtools/none-ls-extras.nvim',
		'jayp0521/mason-null-ls.nvim', -- ensure dependencies are installed
	},
	config = function()
		local null_ls = require 'null-ls'
		local formatting = null_ls.builtins.formatting -- to setup formatters
		local diagnostics = null_ls.builtins.diagnostics -- to setup linters

		-- list of formatters & linters for mason to install
		require('mason-null-ls').setup {
			ensure_installed = {
				'checkmake',
				'prettier', -- ts/js formatter
				'stylua', -- lua formatter
				'eslint_d', -- ts/js linter
				'shfmt',
				'ruff',
			},
			-- auto-install configured formatters & linters (with null-ls)
			automatic_installation = true,
		}

		local null_ls = require 'null-ls'
		local formatting = null_ls.builtins.formatting
		local diagnostics = null_ls.builtins.diagnostics

		local sources = {
			diagnostics.checkmake,
			formatting.prettier.with { filetypes = { 'html', 'json', 'yaml', 'markdown' } },
			formatting.stylua,
			formatting.shfmt.with { args = { '-i', '4' } },
			formatting.terraform_fmt,
			require('none-ls.formatting.ruff').with { extra_args = { '--extend-select', 'i' } },
			require 'none-ls.formatting.ruff_format',
		}

		local augroup = vim.api.nvim_create_augroup('lspformatting', { clear = true })

		null_ls.setup {
			sources = sources,
			on_attach = function(client, bufnr)
				if client.supports_method 'textDocument/formatting' then
					vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
					vim.api.nvim_create_autocmd('BufWritePre', {
						group = augroup,
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format { async = false }
						end,
					})
				end
			end,
		}

		local augroup = vim.api.nvim_create_augroup('lspformatting', {})
		null_ls.setup {
			-- debug = true, -- enable debug mode. inspect logs with :nulllslog.
			sources = sources,
			-- you can reuse a shared lspconfig on_attach callback here
			on_attach = function(client, bufnr)
				if client.supports_method 'textdocument/formatting' then
					vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
					vim.api.nvim_create_autocmd('bufwritepre', {
						group = augroup,
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format { async = false }
						end,
					})
				end
			end,
		}
	end,
}
