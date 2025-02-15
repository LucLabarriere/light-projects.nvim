# light-projects.nvim

## Disclamer

This project has been extensively tested on Linux, MacOS and Windows for my personal projects.
However, if you find a bug or have a suggestion, please open an issue.

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

This plugin offers a _"simple"_ interface to set up _per project_ configurations.

![Demo Animation](../assets/lp-example.gif?raw=true)

In this demo, clangd (C++ LSP) does not work because the project is not built
with the CMAKE_EXPORT_COMPILE_COMMANDS variable. Thus, I execute
`:LightProjectsConfig` to open the config file, modify the `configure` command,
switch back to my cpp project, execute the `configure` command in a ToggleTerm
window, and restart my LSP with `:LspRestart`.

## Features

- Create keybindings for common (custom) tasks, such as `run`, `build`, `debug`,
  etc.
- Optional support for [ToggleTerm](https://github.com/akinsho/toggleterm.nvim)
  to execute a command in the float terminal (using `:TermExec cmd='my_cmd'<CR>`)
- Supports an additionnal callback to be ran when the project is loaded
- Command `LightProjectsConfig` (or `lp.open_config()`): Opens the config file
- Command `LightProjectsReload` (or `lp.reload()`): reloads the config file. It
  triggers `reload_callback` set in setup (default config uses Lazy.nvim to reload
  the plugin).
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

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    'LucLabarriere/light-projects.nvim',
    lazy = false,
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope.nvim',
        'rcarriga/nvim-notify', -- optional
        'akinsho/toggleterm.nvim', --optional
    },
    config = function()
        -- Setup here
    end
}
```

note that `nvim-lua/plenary.nvim` and `nvim-telescope/telescope.nvim` are
dependencies so make sure to load them before

## Configuration

### Small config examples

#### Python and lua example

```lua
local lp = require 'light-projects'

lp.keymaps = {
  run = '<leader>rr',
}

lp.presets.lua = {
  cmds = {
    run = { cmd = 'source %', type = lp.cmdtypes.raw },
  },
}

lp.presets.python = {
  default_cmdtype = lp.cmdtypes.term,
  cmds = {
    run = { cmd = 'python %' },
  },
}

lp.setup {
  projects = {
    nvim_config = {
      preset = lp.presets.lua,
      path = '~/.config/nvim',
      entry_point = 'init.lua',
    },

    py_project= {
      preset = lp.presets.python,
      path = '~/projects/py_project',
      entry_point = 'main.py',
    },
  },
}
```

#### C++ example

```lua
local lp = require 'light-projects'

lp.keymaps = {
  run = '<leader>rr',
  build = '<leader>bb',
  generate = '<leader>cc',
}

lp.presets.cpp = {
  default_cmdtype = lp.cmdtypes.term,
  -- default_cmdtype = lp.cmdtypes.toggleterm, -- or toggleterm

  variables = {
    config = 'Release',
    build_dir = 'build',
    c_compiler = 'clang',
    cxx_compiler = 'clang++',
  },

  cmds = {
    run = { cmd = './${build_dir}/${executable}' },
    build = { cmd = 'cmake --build ${build_dir}' },
    generate = {
      cmd = 'cmake . -B ${build_dir}'
        .. ' -DCMAKE_BUILD_TYPE=${config}'
        .. ' -DCMAKE_EXPORT_COMPILE_COMMANDS=on'
        .. ' -DCMAKE_CXX_COMPILER=${cxx_compiler}'
        .. ' -DCMAKE_C_COMPILER=${c_compiler}',
    },
  },
}

lp.setup {
  projects = {
    cpp_project = {
      preset = lp.presets.cpp,
      path = '~/work/cpp_project',
      entry_point = 'CMakeLists.txt',
      variables = {
        executable = 'cpp_project_exe',
      },
      cmds = {
        run = { cmd = './${build_dir}/${executable}' },
      },
      callback = function() -- executable when switching to this project
        print("Switched to my c++ project!")
      end

      dap = { -- Debugger config
        config = require('dap').configurations.cpp,
        program = '${build_dir}/${executable}',
        args = {},
      },
    },
  },
}
```

### Configuration guide

- Define key mappings:

```lua
local keymaps = {
    build = '<leader>bb',
    run = '<leader>rr',
	-- ...
}
```

In the example, the names chosen are arbitrary.

### Presets

- Then, define presets.

```lua
lp.presets.cpp = {
  entry_point = 'src/main.cpp',
  default_cmdtype = lp.cmdtypes.term

  variables = {
    config = 'Debug',
    executable = "my-exe",
  },

  cmds = {
    run = { cmd = './${executable}', autosave = true },
    build = { cmd = 'build_cmd --config ${config}' },

    -- Sequential command: Runs 'build' then 'run' in order
    build_and_run = { cmd = { 'build', 'run' }, type = lp.cmdtypes.sequential },
    -- ...
  },
}

```

- Call setup

```lua
lp.setup {
  -- Possible values:
  --      - 0 : silent
  --      - 1 : prints the name of the current project
  --      - 2 : prints the current path as well
  --      - 3 : prints each registered command
  verbose = 0, --default value = 0

  -- Calling LightProjectsConfig opens this file
  -- default value points to the file that calls the setup() function
  config_path = "/path/to/config/file"

  -- By default, run the commands using :my_cmd<CR>
  -- Available cmdtypes:
  -- lp.cmdtypes.raw
  -- lp.cmdtypes.term
  -- lp.cmdtypes.toggleterm
  -- lp.cmdtypes.sequential
  -- lp.cmdtypes.lua_function
  default_cmdtype = lp.cmdtypes.raw,

  projects = {
    -- See example configs for more info
  },
}

```

### Git bare repositories

This plugin handles git bare repositories and worktrees. For example,
cloning this repository with these commands:

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
- `lp.cmdtypes.term`: The command is executed as a vim command (using `:term cmd<CR>`)
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
