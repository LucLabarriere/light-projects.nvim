local lp = require 'light-projects'

lp.keymaps = {
  -- Define your custom keymaps here
  -- The name you give the keymap is reused for command definitions
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
}

-- Presets are stored in lp.presets, add any preset you need
lp.presets.cpp = {
  variables = {
    c_compiler = 'clang',
    cxx_compiler = 'clang++',
    config = 'Debug',
  },
  cmds = {
    configure = {
      cmd = '$env:VCPKG_FEATURE_FLAGS="manifests";'
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

lp.presets.lua = {
  cmds = {
    source = { cmd = 'source %', type = lp.cmdtypes.raw },
  },
}

lp.presets.python = {
  cmds = {
    run = { cmd = 'python ${app_executable}', type = lp.cmdtypes.toggleterm },
  },
}

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
      dap = {
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
