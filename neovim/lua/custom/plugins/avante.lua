-- avante.nvim - AI-powered code generation with agentic capabilities
-- Write a function signature, press <leader>aa, and the AI implements it
-- You can navigate elsewhere while it works asynchronously
return {
  'yetone/avante.nvim',
  event = 'VeryLazy',
  version = false, -- use latest
  build = 'make',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'stevearc/dressing.nvim',
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    -- Optional but recommended
    'nvim-tree/nvim-web-devicons',
    {
      -- Support for image pasting
      'HakonHarnes/img-clip.nvim',
      event = 'VeryLazy',
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = { insert_mode = true },
        },
      },
    },
    {
      -- Render markdown in avante
      'MeanderingProgrammer/render-markdown.nvim',
      opts = { file_types = { 'markdown', 'Avante' } },
      ft = { 'markdown', 'Avante' },
    },
  },
  opts = {
    -- Provider: "claude", "openai", "copilot", "gemini", etc.
    provider = 'claude',
    -- Set to false if you don't want auto-suggestions
    auto_suggestions_provider = 'claude',
    claude = {
      endpoint = 'https://api.anthropic.com',
      model = 'claude-sonnet-4-20250514',
      temperature = 0,
      max_tokens = 4096,
    },
    behaviour = {
      auto_suggestions = false, -- Set to true for inline suggestions
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = false,
    },
    mappings = {
      --- @class AvanteConflictMappings
      diff = {
        ours = 'co',
        theirs = 'ct',
        all_theirs = 'ca',
        both = 'cb',
        cursor = 'cc',
        next = ']x',
        prev = '[x',
      },
      suggestion = {
        accept = '<M-l>',
        next = '<M-]>',
        prev = '<M-[>',
        dismiss = '<C-]>',
      },
      jump = {
        next = ']]',
        prev = '[[',
      },
      submit = {
        normal = '<CR>',
        insert = '<C-s>',
      },
      sidebar = {
        apply_all = 'A',
        apply_cursor = 'a',
        switch_windows = '<Tab>',
        reverse_switch_windows = '<S-Tab>',
      },
    },
    hints = { enabled = true },
    windows = {
      position = 'right',
      wrap = true,
      width = 30, -- percentage
      sidebar_header = {
        enabled = true,
        align = 'center',
        rounded = true,
      },
    },
  },
}
