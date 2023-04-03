# light-projects.nvim

<!--toc:start-->
- [light-projects.nvim](#light-projectsnvim)
  - [Features](#features)
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [Contribute](#contribute)
<!--toc:end-->

I made this neovim plugin for my personal use. I wanted a simple interface to
set up _per project_ configurations without having to create `.lua` files in my
project folders.

## Features

- Default key bindings for common programming tasks (build, run, tests, etc.)
- The key bindings get loaded on `VimEnter` and `DirChanged` autocmds
- Supports [ToggleTerm](https://github.com/akinsho/toggleterm.nvim) to execute a
  command in the float terminal (using `:TermExec cmd='my_cmd'<CR>`)
- Supports an additionnal callback to be ran when the project is loaded
- Command `LightProjectsConfig` (or `require('light-projects').open_config()`):
  Opens the config file

## Installation

Using your package manager, for example using
[vim-plug](https://github.com/junegunn/vim-plug):

```lua
Plug 'LucLabarriere/light-projects.nvim'
```

## Configuration

Here's an example of a setup() call:

```lua
local lp = require('light-projects')

lp.setup {
    -- Possible values:
    --      - 0 : silent
    --      - 1 : prints the name of the current project
    --      - 2 : prints the current path as well
    --      - 3 : prints each registered command
    verbose = 1,

    -- Don't modify this line to be able to use the LightProjectsConfig command
    config_path = string.sub(debug.getinfo(1, "S").source, 2),

    -- By default, run the commands using :TermExec cmd='my_cmd'<CR>
    use_toggleterm = true,

    -- Use the default mappings you need
    default_mappings = {
        configure = '<leader>cc',
        build = '<leader>bb',
        run = '<leader>rr',
        test = '<leader>tt',
        bench = '<leader>be',
        debug = '<leader>deb',
        clean = '<leader>cle',
        build_and_run = '<leader>br',
        build_and_test = '<leader>bt',
        build_and_bench = '<leader>bbe',
        build_and_debug = '<leader>bdeb',
    },

    -- Here are examples of projects that I defined (on Windows)
    projects = {
        nvim_conf = {
            path = '~/.config/nvim',
            run = {
                cmd = ':so %<CR>',  -- Sources the current file
                toggleterm = false, -- Execute this as a regular vim command
            },
            -- Here is an example of a callback execution at project startup
            callback = function()
                local opts = { noremap = true, silent = true }
                -- This uses the set_keymap function that is similar to nvim_set_keymap
                -- exepect that it has a 5th argument to interpret the right and side as a
                -- ToggleTerm command
                lp.set_keymap('n', '<leader>hello', 'echo "hello"', opts, {
                    toggleterm = true,
                })
            end
        },
        -- My commands when working on a C++ project called "interview"
        interview = {
            path = '~/work/interview/',
            -- Those variables will be replaced in the commands below
            -- for example, ${config} is replaced by 'Debug' here
            variables = {
                config = 'Debug'
            },
            -- Run cmake to configure the project
            configure = {
                -- Note that the quotes (") are escaped by default. If you need non-escaped
                -- quotes, open an issue or a pull request!
                cmd = 'cmake . -B build -DCMAKE_CXX_COMPILER="clang++.exe"\
                    "-DCMAKE_C_COMPILER="clang.exe", -G "Ninja Multi-Config"\
                    "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
                toggleterm = true, -- I set use_toggleterm = true previously so this as no effect
                cd_before_cmd = true, -- This is the default. Only works with ToggleTerm commands
            },
            -- Build app
            build = {
                cmd = 'cmake --build build --config ${config}',
            },
            -- Run the main app
            run = {
                cmd = 'build/${config}/interview.exe',
            },
            -- My unit tests
            test = {
                cmd = 'cd build; ctest',
            },
            -- My benchmarks
            bench = {
                cmd = 'build/${config}/HashMap_bench.exe',
            },
        },
    },
}
```

## Contribute

This project is available under the MIT license. Feel free to use, modify, copy,
etc. Also if you think of something that is missing, consider opening an issue
or creating a pull request.
