# light-projects.nvim

## Disclamer

This project has only been slightly tested on Windows, MacOS and linux. If you
find bugs, please open an issue! It is also at the early stages of development
and is subject to changes in the future

## Description

<!--toc:start-->

- [light-projects.nvim](#light-projectsnvim)
  - [Features](#features)
  - [Installation](#installation)
  - [Configuration](#configuration)
    - [Keymaps](#keymaps)
    - [Presets](#presets)
    - [Setup](#setup)
    - [Git bare repositories](#git-bare-repositories)
    - [Command types](#command-types)
    - [Separate config file](#separate-config-file)
  - [Sequential commands](#sequential-commands)
  - [Contribute](#contribute)
  <!--toc:end-->

I made this neovim plugin for my personal use. I wanted a simple interface to
set up _per project_ configurations without having to create `.lua` files in my
project folders.

![Demo Animation](../assets/lp-example.gif?raw=true)

In this demo, clangd (C++ LSP) does not work because the project is not built
with the CMAKE_EXPORT_COMPILE_COMMANDS variable. Thus, I execute
`:LightProjectsConfig` to open the config file, modify the `configure` command,
switch back to my cpp project, execute the `configure` command in a ToggleTerm
window, and restart my LSP with `:LspRestart`.

## Features

- Create keybindings for common (custom) tasks, such as `run`, `build`, `debug`,
  etc.
- The key bindings get loaded on `VimEnter` and `DirChanged` autocmds
- Optional support for [ToggleTerm](https://github.com/akinsho/toggleterm.nvim)
  to execute a command in the float terminal (using
  `:TermExec cmd='my_cmd'<CR>`)
- Supports an additionnal callback to be ran when the project is loaded
- Command `LightProjectsConfig` (or `lp.open_config()`): Opens the config file
- Command `LightProjectsReload` (or `lp.reload()`): reloads the config file. It
  triggers `reload_callback` set in setup.
- Command `LightProjectsSwitch` (or `lp.telescope_project_picker()`): opens a
  [telescope](https://github.com/nvim-telescope/telescope.nvim) window to switch
  project. If the chosen project has an `entry_point` defined, opens the
  specified file. If not, just `cd` into the directory
- Command `LightProjectToggle` (or `lua lp.toggle_project()`): toggles the
  project. This is the command that is ran on `VimEnter` and `DirChanged`.
- Supports git bare repository with branches in the same folder. Checkout the
  [git bare repositories](#git-bare-repositories) section for more information.
- Notifications when a project is loaded using
  [nvim-notify](https://github.com/rcarriga/nvim-notify) (optional, enabled with
  `use_notify = true` in the config)
- Debug adapter protocol (DAP) basic config support

## Installation

For example using [vim-plug](https://github.com/junegunn/vim-plug):

```lua
Plug 'LucLabarriere/light-projects.nvim'
```

or [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    'LucLabarriere/light-projects.nvim',
    lazy = false,
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope.nvim',
        'rcarriga/nvim-notify', -- optional
    },
    config = function()
        -- Setup here
    end
}
```

note that `nvim-lua/plenary.nvim` and `nvim-telescope/telescope.nvim` are
dependencies so make sure to load them before

## Configuration

An example of a config file is given [in the repository](./example_config.lua).
The configuration is explained below.

### Keymaps

Define your key mappings:

```lua
local keymaps = {
    configure = '<leader>cc',
    build = '<leader>bb',
    source = '<leader>so',
    run = '<leader>rr',
    test = '<leader>tt',
    bench = '<leader>ce',
    debug = '<leader>dd',
    clean = '<leader>cle',
    tidy = '<leader>ti',
    build_and_run = '<leader>br',
    build_and_test = '<leader>bt',
    build_and_bench = '<leader>be',
    build_and_debug = '<leader>bd',
	-- ...
}
```

In the example, the names chosen are arbitrary, chose whatever command name you
like

### Presets

Then define a bunch of presets in the presets dictionary. In the
example below, I define a preset called "lua" that I will use for my neovim
config files (see the [Command types](#command-types) section for more infos on
the `type` argument.

```lua
local presets = {}
lp.presets.lua = {
    cmds = {
        source = { cmd = 'source %', type = lp.cmdtypes.raw },
    },
}
```

For my python projects I use:

```lua
lp.presets.python = {
    cmds = {
        run = { cmd = 'python ${app_executable}', type = lp.cmdtypes.toggleterm },
    }
}
```

The `${app_executable}` variable will have to be set for each project. Note that
in these examples, the `source` and `run` entries correspond to the ones defined
in the `lp.keymaps` dictionary

A more complicated example is given below. I define the `cpp` preset
for my C++ projects. Variables are defined in the `variables`
dictionary (those can be overwritten in the project specific configurations).
Notice also that some variables (such as `${app_executable}`), remain
undefined in the preset.

```lua
lp.presets.cpp = {
    variables = {
        c_compiler = 'clang',
        cxx_compiler = 'clang++',
        config = 'Debug',
    },
    cmds = {
        configure = {
            cmd =
                '$env:VCPKG_FEATURE_FLAGS="manifests";'
                .. 'cmake . -B build'
                .. ' -DCMAKE_CXX_COMPILER=${cxx_compiler}'
                .. ' -DCMAKE_C_COMPILER=${c_compiler}'
                .. ' -G "Ninja Multi-Config"'
                .. ' -DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
        },
        build = { cmd = 'cmake --build build --config ${config}' },
        run = { cmd = 'build/${config}/${app_executable}' },
        test = { cmd = 'cd build; ctest' },
        bench = { cmd = 'build/benchmarks/${config}/${bench_executable}' },
        clean = { cmd = 'rm -rf build' },
        debug = { cmd = 'DapContinue', type = lp.cmdtypes.raw },
        build_and_run = { cmd = { 'build', 'run' }, type = lp.cmdtypes.sequential },
        build_and_test = { cmd = { 'build', 'test' }, type = lp.cmdtypes.sequential },
        build_and_bench = { cmd = { 'build', 'bench' }, type = lp.cmdtypes.sequential },
        build_and_debug = { cmd = { 'build', 'debug' }, type = lp.cmdtypes.sequential },
    },
}
```

Also in this example, note that the `build_and_x` commands are sequential
commands, meaning that the `cmd` entry has to be given as a table of command
names to execute in order.

### Setup

In the setup call, additional features and configs can be used.

```lua
lp.setup {
  -- Possible values:
  --      - 0 : silent
  --      - 1 : prints the name of the current project
  --      - 2 : prints the current path as well
  --      - 3 : prints each registered command
  verbose = 1,

  -- Don't modify this line to be able to use the LightProjectsConfig command
  config_path = string.sub(debug.getinfo(1, 'S').source, 2),

  -- By default, run the commands using :TermExec cmd='my_cmd'<CR>
  -- Available cmdtypes:
  -- lp.cmdtypes.raw
  -- lp.cmdtypes.toggleterm
  -- lp.cmdtypes.sequential
  -- lp.cmdtypes.lua_function
  default_cmdtype = lp.cmdtypes.toggleterm,

  projects = {
    nvim_config = {
      preset = lp.presets.lua,
      path = '~/.config/nvim',
      entry_point = 'init.lua',
    },
    my_lua_project = {
      preset = lp.presets.lua,
      path = '~/path/to/my_lua_project',
      entry_point = 'lua/lua_project.lua',
    },
    my_cpp_project = {
      preset = lp.presets.cpp,
      path = '~/path/to/my_cpp_project',
      entry_point = 'src/main.cpp',
      variables = {
        app_executable = 'my_executable',
        bench_executable = 'benchmarks',
        test_executable = 'tests',
      },
      dap = { -- Debug adapter protocol config
        config = require('dap').configurations.cpp,
        program = 'build/${config}/${app_executable}',
        args = {},
      },
      callback = function()
        print 'This function is executed when the my_cpp_project project gets loaded'
      end,
    },
  },
}

```

### Git bare repositories

For example, cloning this repository with these commands:

```bash
git clone https://github.com/LucLabarriere/light-projects.nvim.git --bare light-projects.nvim/.git
cd light-projects.nvim
git worktree add main
git worktree add dev
```

will initialize a bare git repository pointing to the github repo, with two
worktrees called `main`and `dev` storing local copies of the repository in these
branches. Setting up this project with these settings:

```lua
light_projects = {
    preset=  lp.presets.lua,
    path = '~/work/light-projects.nvim/.git',
    entry_point = 'lua/light-projects.lua',
    bare_git = true,
},
```

will allow for automatic detection of project branches in the
`LightProjectSwitch` command:
![Demo git bare repositories](../assets/lp-git-bare.png?raw=true)

### Command types

As of today, four command types are available:

- `lp.cmdtypes.raw`: The command is executed as a vim command (using `:cmd<CR>`)
- `lp.cmdtypes.toggleterm`: The command is executed as a
  [ToggleTerm](https://github.com/akinsho/toggleterm.nvim) command (using
  `:TermExec cmd='cmd'<CR>`)
- `lp.cmdtypes.lua_function`: The command is executed as a lua function. For
  example, this `run` command prints "Hello" when executed

```lua
	run = { cmd = function() print("Hello") end, type = lp.cmdtypes.lua_function }
```

- `lp.cmdtypes.sequential`: Executes the given command in order. This is kind of
  experimental and may have undefined behaviors if mixed command types are
  passed (So far, it works well for ToggleTerm commmands).

### Separate config file

If you're like me, you have your nvim config files stored in a remote
repository, shared accross multiple computers. If so, you might want to define
your projects in a separate config file. Here is how I do it using
[lazy.nvim](https://github.com/folke/lazy.nvim). I have a global config shared
accross computers:

```lua
{
    'LucLabarriere/light-projects.nvim',
    lazy = false,
    dependencies = {
        'rcarriga/nvim-notify',
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope.nvim',
    },
    keys = {
        { "<leader>lr", "<cmd>LightProjectsReload<CR>", "n" },
        { "<leader>ls", "<cmd>LightProjectsSwitch<CR>", "n" },
        { "<leader>lc", "<cmd>LightProjectsConfig<CR>", "n" },
    },
    config = function()
        local lp = require('light-projects')

        lp.keymaps = {
            configure = '<leader>cc',
            build = '<leader>bb',
            source = '<leader>so',
            run = '<leader>rr',
            -- ... configure addition keymaps here
        }

        lp.presets.lua = {
            cmds = {
                source = { cmd = 'source %', type = lp.cmdtypes.raw },
            },
        }
        -- ... configure additional presets here

        local setup_args = {
            verbose = 0,

            reload_callback = function()
                vim.cmd(':Lazy reload light-projects.nvim')
            end,

            default_cmdtype = lp.cmdtypes.toggleterm,
            use_notify = true,
            -- configure global settings here
        }

        -- Load a computer specific config file and call a custom function to setup the projects
        dofile(vim.fn.expand("~/.nvimenv.lua")).setup_light_projects(lp, setup_args)
    end
}
```

Then, in `~/.nvimenv.lua`:

```lua
local M = {}
M.setup_light_projects = function(lp, setup_args)
    -- Setting config path here will make the LightProjectsConfig command open this file
    setup_args.config_path = string.sub(debug.getinfo(1, "S").source, 2)

    setup_args.projects = {
        nvim_config = {
            preset = lp.presets.lua,
            path = '~/.config/nvim',
            entry_point = 'init.lua',
        },
        -- .. setup additional projects here
    }

    lp.setup(setup_args)
end

return M
```

## Sequential commands

I had a hard time setting up sequential commands. I found a hack by using the nvim server (created by default at
startup) to request the next command to be executed. When a ToggleTerm command is executed, here is command used:

```bash
cmd && nvim --server server_name --remote-send "<ESC>:sleep 10m | lua require('light-projects').execute_next_cmd()<CR>"
```

In which the `:sleep 10m` seems necessary on windows (if you have an idea why,
please let me know!).

## Contribute

This project is available under the MIT license. Feel free to use, modify, copy,
etc. Also if you think of something that is missing, consider opening an issue
or creating a pull request.
