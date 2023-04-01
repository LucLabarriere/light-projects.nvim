# light-projects.nvim

I made this neovim plugin for my personal use. I wanted a simple interface to
set up _per project_ key bindings without having to create `.lua` files in my
project folders.

## Features

- Creates a config `json` file containing a list of projects with specific key
  bindings
- The key bindings get loaded on `VimEnter` autocommand as well as whenever the
  root directory is changed
- Three default keybindings can be created : `run`, `build` and `configure` and
  others can be set

## Installation

Using your package manager, for example using
[vim-plug](https://github.com/junegunn/vim-plug):

```lua
Plug 'LucLabarriere/light-projects.nvim'
-- ...

require('light-projects').setup()
```

## Features

- Handles raw commands or commands executed in a
  [ToggleTerm](https://github.com/akinsho/toggleterm.nvim) terminal.

- Commands:
  - `LightProjectsReload`: reloads the current config file
  - `LightProjectsConfig`: opens the current config file for modification

## Configuration

### Setup

The default setup arguments are:

```lua
require('light-projects').setup{
    config_path = vim.expand(vim.fn.stdpath('config')),
    run_mapping = nil, -- Example: '<Leader>rr'
    build_mapping = nil, -- Example: '<Leader>bb'
    configure_mapping = nil, -- Example: '<Leader>cc'
}
```

### Config file

For example, here's part of my config file on Windows:

```json
{
    "nvim_conf": {
        "path": "C:/Users/Luc/.config/nvim",
        "run": {
            "cmd": [
                ":so %<CR>"
            ]
        },
        "key_maps": [
            {
                "mode": "n",
                "lfs": "<Leader>hello",
                "rhs": ":echo 'hello'<CR>"
            }
        ]
    },

    "vkengine": {
        "path": "C:/Users/Luc/work/vkengine",
        "run": {
            "cmd": [
                "build/Debug/vkengine.exe"
            ],
            "type": "ToggleTerm"
        },
        "build": {
            "cmd": [
                ":TermExec",
                "cmd=\"cmake --build build --config Debug\"",
                "<CR>"
            ],
            "type": "raw"
        },
        "configure": {
            "cmd": [
                "$env:VCPKG_FEATURE_FLAGS=\"manifests\";",
                "cmake",
                ".",
                "build",
                "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
                "-DCMAKE_CXX_COMPILER=\"clang++.exe\"",
                "-DCMAKE_C_COMPILER=\"clang.exe\"",
                "-G \"Ninja Multi-Config\""
            ],
            "type": "ToggleTerm"
        }
    }
}
```


