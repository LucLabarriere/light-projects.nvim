# light-projects.nvim

## Disclamer

This project has only been slightly tested on windows and linux. If you find
bugs, please open an issue! It is also at the early stages of development and is
subject to changes in the future

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
- Supports [ToggleTerm](https://github.com/akinsho/toggleterm.nvim) to execute a
  command in the float terminal (using `:TermExec cmd='my_cmd'<CR>`)
- Supports an additionnal callback to be ran when the project is loaded
- Command `LightProjectsConfig` (or `lp.open_config()`): Opens the config file
- Command `LightProjectsReload` (or `lp.reload()`): reloads the config file. It
  basically just sources the config file.
- Command `LightProjectsSwitch` (or `lp.telescope_project_picker()`): opens a
  [telescope](https://github.com/nvim-telescope/telescope.nvim) window to switch
  project. If the chosen project has an `entry_point` defined, opens the
  specified file. If not, just `cd` into the directory
- Command `LightProjectToggle` (or `lua lp.toggle_project()`): toggles the
  project. This is the command that is ran on `VimEnter` and `DirChanged`.
- Supports git bare repository with branches in the same folder. Checkout the
  (#git-bare-repositories) section for more information.

## Installation

For example using [vim-plug](https://github.com/junegunn/vim-plug):

```lua
Plug 'LucLabarriere/light-projects.nvim'
```

## Configuration

An example of a config file is given [in the repository](./example_config.lua).
The configuration is explained below.

### Keymaps

You can define the keymaps you will be using in the keymaps dictionary as so:

```lua
local lp = require('light-projects')
lp.keymaps = {
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

Then define a bunch of presets in the presets dictionary. For example, in the
example below, I define a preset called "lua" that I will use all my neovim
config files (see the [Command types](#command-types) section for more infos on
the `type` argument.

```lua
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

A more complicated example is given below. In there, I define the `cpp` preset
for my C++ projects. A bunch of variables are defined in the `variables`
dictionary (those can be overwritten in the project specific configurations).
Notice also that some variables (`${app_executable}` for example, remain
undefined in the preset)

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

In the setup call, a bunch of additional features and configs can be used.

```lua
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

			-- The entry_point key allows to specify a file to open when
			-- using the LightProjectsSwitch command
            entry_point = 'init.lua',
        },
        light_projects = {
            preset = lp.presets.lua,
            path = '~/work/light-projects.nvim',
            entry_point = 'lua/light-projects.lua',
        },
        vkengine = {
            preset = lp.presets.cpp,
            path = '~/work/vkengine',
            entry_point = 'src/main.cpp',
            variables = {
                app_executable = 'vkengine',
                bench_executable = 'benchmarks',
                test_executable = 'tests',
            },
            callback = function()
                print("This function is executed when the vkengine project gets loaded")
            end
        },
        pysand = {
            preset = lp.presets.python,
            path = '~/work/pysand',
            entry_point = 'pysand.py',
            variables = {
                app_executable = 'pysand.py',
            },
        }
    }
}

```

### Git bare repositories

For example, cloning this repository with these commands:

```bash
git clone https://github.com/LucLabarriere/light-projects.nvim.git --bare
cd light-projects.nvim
git worktree add main
git worktree add dev
```

will initialize a bare git repository pointing to remote github repo, with two
subfolders called `main`and `dev` storing local copies of the repository in
these branches. Then, configuring the project using:

```lua
light_projects = {
    preset=  lp.presets.lua,
    path = '~/work/light-projects.nvim',
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
  passed. For example, in the `cpp` example above, the `build_and_debug` command
  defined as:

```lua
    build_and_debug = { cmd = { 'build', 'debug' }, type = lp.cmdtypes.sequential }
```

will execute the `build` command (which is a `lp.cmdtypes.toggleterm` command),
followed by a raw command that starts a debug session. Thus, the session might
start before the build has completed. If you find a way to wait for the previous
command to finish before starting the next one, feel free to contribute!

## Contribute

This project is available under the MIT license. Feel free to use, modify, copy,
etc. Also if you think of something that is missing, consider opening an issue
or creating a pull request.
