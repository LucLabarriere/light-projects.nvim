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
- The key bindings get loaded on `VimEnter` and `DirChanged` autocmds (set
  use_autoreload to false in the setup arguments to disable this behaviour)
- Supports [ToggleTerm](https://github.com/akinsho/toggleterm.nvim) to execute a
  command in the float terminal (using `:TermExec cmd='my_cmd'<CR>`)
- Supports an additionnal callback to be ran when the project is loaded
- Command `LightProjectsConfig` (or `require('light-projects').open_config()`):
  Opens the config file
- Command `LightProjectsReload` (or `require('light-projects').reload()`):
  reloads the current config file. It basically just sources the config file.
- `require('light-projects').tif(condition, val_if_true, val_if_false)`: simple
  ternary if function

![Demo Animation](../assets/lp-example.gif?raw=true)

In this demo, clangd (C++ LSP) does not work because the project is not built
with the CMAKE_EXPORT_COMPILE_COMMANDS variable. Thus, I execute
`:LightProjectsConfig` to open the config file, modify the `configure` command,
switch back to my cpp project, execute the `configure` command in a ToggleTerm
window, and restart my LSP with `:LspRestart`.

## Installation

For example using [vim-plug](https://github.com/junegunn/vim-plug):

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

    -- By default, the config file is reloaded when the current directory is changed
    use_autoreload = true,

    -- Use the default mappings you need
    default_mappings = {
        configure = '<leader>cc',
        build = '<leader>bb',
        run = '<leader>rr',
        test = '<leader>tt',
        bench = '<leader>ee',
        debug = '<leader>dd',
        clean = '<leader>cle',

        -- If you don't define these commands manually in the project definition,
        -- they get defaulted to their combinations. For example for build_and_run:
        -- :TermExec cmd='build; run'<CR>
        build_and_run = '<leader>br',
        build_and_test = '<leader>bt',
        build_and_bench = '<leader>be',
        build_and_debug = '<leader>bd',
    },

    -- Here are examples of projects that I defined (works on linux and windows)
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
                -- except that it has a 5th argument to interpret the right-hand side as a
                -- ToggleTerm command
                lp.set_keymap('n', '<leader>hello', 'echo "hello"', opts, {
                    toggleterm = true,
                })
            end
        },
        -- My commands when working on a C++ project called "my_cpp_project"
        my_cpp_project =
            path = '~/work/my_cpp_project/',
            -- Those variables will be replaced in the commands below
            -- for example, ${config} is replaced by 'Debug' here
            variables = {
                config = 'Debug',
                cxx_compiler = 'clang++',
                c_compiler = 'clang'),
                app_executable = 'my_cpp_project',
                test_executable = 'HashMap_test',
                bench_executable = 'HashMap_bench',
				-- You might like to using the ternary if function
				-- example_variable = lp.tif(condition, value_if_true, value_if_false),

            },
            -- Run cmake to configure the project
            configure = {
                cmd = 'cmake . -B build'
                    .. ' -DCMAKE_CXX_COMPILER=${cxx_compiler}'
                    .. ' -DCMAKE_C_COMPILER=${c_compiler}'
                    .. ' -G "Ninja Multi-Config"'
                    .. ' -DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
            },
            -- Build app
            build = {
                cmd = 'cmake --build build --config ${config}',
            },
            -- Run the main app
            run = {
                cmd = 'build/${config}/${app_executable}',
            },
            -- My unit tests
            test = {
                cmd = 'cd build; ctest',
            },
            -- My benchmarks
            bench = {
                cmd = 'build/${config}/${bench_executable}',
            },
        },
,
    },
}
```

## Contribute

This project is available under the MIT license. Feel free to use, modify, copy,
etc. Also if you think of something that is missing, consider opening an issue
or creating a pull request.

## Known bugs

- The `configure` command defined in the example config file does not work on
  vim mode shells.
