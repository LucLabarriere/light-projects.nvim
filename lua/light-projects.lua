local M = {}

local Utils = require 'light-projects.utils'
local Plenary_scan = require 'plenary.scandir'

Utils.setup(M)

M.keymaps = {}
M.presets = {}
M.projects = {}
M.command_buffer = {}
M.project_paths_name_mapping = {}
M.cmdtypes = {
    raw = 0,
    toggleterm = 1,
    sequential = 2,
    lua_function = 3,
}

M.setup_commands = function()
    vim.api.nvim_create_augroup("LightProjects", { clear = true })
    vim.api.nvim_create_autocmd(
        { "DirChanged", "VimEnter" }, {
            command = ":LightProjectsToggle",
            group = "LightProjects",
        }
    )

    vim.api.nvim_create_user_command("LightProjectsReload", ":lua require('light-projects').reload()", {})
    vim.api.nvim_create_user_command("LightProjectsToggle", ":lua require('light-projects').toggle_project()", {})
    vim.api.nvim_create_user_command("LightProjectsConfig", ":lua require('light-projects').open_config()", {})
    vim.api.nvim_create_user_command(
        "LightProjectsSwitch",
        ":lua require('light-projects').telescope_project_picker()",
        {}
    )
end

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

M.telescope_project_picker = function(opts)
    opts = opts or {}
    pickers.new(opts, {
        prompt_title = "LightProjects",
        finder = finders.new_table {
            results = M.project_names,
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                local p = M.projects[selection[1]]

                vim.cmd('cd ' .. p.path)
                if p.entry_point ~= nil then
                    vim.cmd('e ' .. p.entry_point)
                end
            end)
            return true
        end,
    }):find()
end

M.parse_raw_command = function(cmd, variables)
    cmd = Utils.replace_vars(cmd, variables)
    return function() vim.cmd(cmd) end
end

M.execute_next_cmd = function()
    if M.command_buffer ~= nil and #M.command_buffer > 0 then
        M.command_buffer[1]()
        table.remove(M.command_buffer, 1)
    end
end

M.parse_toggleterm_command = function(cmd, proj_path, variables)
    if M.cd_before_cmd then
        cmd = "cd " .. Utils.Path(proj_path) .. " && " .. cmd
    end
    cmd = Utils.replace_vars(cmd, variables)
    local toggleterm = require('toggleterm')

    local ending_callback = " &&  nvim --server "
        .. M.server
        .. " --remote-send \"<ESC>:sleep 10m | lua require(\'light-projects\').execute_next_cmd()<CR>\""

    require('toggleterm.terminal').get_or_create_term()
    return function() toggleterm.exec(cmd .. ending_callback, nil, nil, nil, nil, true) end
end

M.parse_sequential_command = function(cmd, other_commands)
    local functions = {}

    for _, v in pairs(cmd) do
        table.insert(functions, other_commands[v])
    end

    return function()
        M.command_buffer = {}
        for _, v in pairs(functions) do
            table.insert(M.command_buffer, v)
        end
        M.execute_next_cmd()
    end
end

M.store_projects = function(projects)
    M.project_names = {}

    for proj_name, config in pairs(projects) do
        local p = {}
        p.variables = {}
        p.cmds = {}
        p.raw_cmds = {}

        -- Storing path to project
        if config.path == nil then
            print("Incorrect project config: path to " .. proj_name .. " is nil")
            return
        end
        p.path = Utils.Path(config.path).filename

        -- Applying preset
        if config.preset ~= nil then
            if config.preset.variables == nil and config.preset.cmds == nil then
                print("Incorrect project config: preset " .. config.preset .. " is empty")
            else
                if config.preset.variables ~= nil then
                    for var_name, var_value in pairs(config.preset.variables) do
                        p.variables[var_name] = var_value
                    end
                end

                if config.preset.cmds ~= nil then
                    for cmd_name, cmd_value in pairs(config.preset.cmds) do
                        if cmd_value.type == nil then
                            cmd_value.type = M.default_cmdtype
                        end
                        p.raw_cmds[cmd_name] = cmd_value
                    end
                end

                if config.preset.callback ~= nil then
                    config.callback = config.preset.callback
                end

                if config.preset.entry_point ~= nil then
                    config.entry_point = config.preset.entry_point
                end
            end
        end

        -- Storing additional variables
        if config.variables ~= nil then
            for var_name, var_value in pairs(config.variables) do
                p.variables[var_name] = var_value
            end
        end

        -- Storing additional commands
        if config.cmds ~= nil then
            for cmd_name, cmd_value in pairs(config.cmds) do
                if cmd_value.type == nil then
                    cmd_value.type = M.default_cmdtype
                end
                p.raw_cmds[cmd_name] = cmd_value
            end
        end

        -- Parsing commands and storing them as lua functions
        for cmd_name, cmd in pairs(p.raw_cmds) do
            if cmd.type == M.cmdtypes.raw then
                p.cmds[cmd_name] = M.parse_raw_command(cmd.cmd, p.variables)
            elseif cmd.type == M.cmdtypes.lua_function then
                p.cmds[cmd_name] = cmd.cmd
            elseif cmd.type == M.cmdtypes.toggleterm then
                p.cmds[cmd_name] = M.parse_toggleterm_command(cmd.cmd, p.path, p.variables)
            end
        end

        -- Parsing sequential commands
        for cmd_name, cmd in pairs(p.raw_cmds) do
            if cmd.type == M.cmdtypes.sequential then
                p.cmds[cmd_name] = M.parse_sequential_command(cmd.cmd, p.cmds)
            end
        end

        -- Storing on project toggle callback
        p.callback = config.callback

        -- Storing project entry point
        p.entry_point = config.entry_point

        -- Wethever the folder is a bare git repo or not
        p.bare_git = config.bare_git

        if p.bare_git then
            local base_path = Utils.Path(p.path)
            local worktrees_path = base_path:joinpath('worktrees')
            local branches = Plenary_scan.scan_dir(worktrees_path.filename, { hidden = true, depth = 1, add_dirs = true })

            for i, _ in ipairs(branches) do
                local path = Utils.Path(branches[i])
                local path_infos = path:_split()
                local line = Utils.read_line(path:joinpath('gitdir').filename)
                branches[i] = path_infos[#path_infos]

                if line ~= nil then
                    local branched_path = Utils.Path(string.gsub(line, '.git$', '')).filename
                    local branched_proj_name = proj_name .. ' (' .. branches[i] .. ')'
                    M.project_paths_name_mapping[branched_path] = branched_proj_name
                    M.projects[branched_proj_name] = vim.deepcopy(p)
                    M.projects[branched_proj_name].path = branched_path
                    table.insert(M.project_names, branched_proj_name)
                end
            end
        else
            -- Storing path - proj_name mapping to be able to toggle projects
            M.project_paths_name_mapping[Utils.Path(p.path).filename] = proj_name
            M.projects[proj_name] = p
            table.insert(M.project_names, proj_name)
        end
    end
end


M.toggle_project = function()
    local p_path = Utils.Path(vim.fn.getcwd()).filename
    local p_name = M.project_paths_name_mapping[p_path]
    if p_name == nil then return end

    local p = M.projects[p_name]

    if M.setup_args.verbose > 0 then
        print("LightProjects: [" .. p_name .. "]")

        if M.setup_args.verbose > 1 then
            print("LightProjects: current path: " .. p_path)
        end
    end

    for cmd_name, cmd in pairs(p.cmds) do
        if M.keymap_names[cmd_name] == nil then
            print("LightProjects: Command '" .. cmd_name .. "' set but no matching keymap found")
        else
            local km = M.keymaps[cmd_name]
            vim.keymap.set('n', km, cmd, { noremap = true, silent = true, desc = 'LightProjects: ' .. cmd_name })
        end
    end

    if p.callback ~= nil then
        p.callback()
    end

    if M.use_notify then
        M.notify("Switched to: [" .. p_name .. "]", "info", {
            title = 'LightProjects',
            render = "compact",
            timeout = 10,
            stages = "fade" }
        )
    end
end

M.setup = function(setup_args)
    M.setup_args = setup_args or {}
    M.keymap_names = {}

    for k, _ in pairs(M.keymaps) do
        M.keymap_names[k] = k
    end

    if M.server == nil then
        M.server = vim.fn.serverlist()[1]
    end

    if setup_args.use_notify then
        M.notify = require('notify')
        M.use_notify = true
    end

    M.n_windows = vim.fn.has('win32')
    M.verbose = setup_args.verbose or 1
    M.default_cmdtype = setup_args.default_cmdtype or M.cmdtypes.raw
    M.config_path = M.setup_args.config_path
    M.cd_before_cmd = setup_args.cd_before_cmd or true
    M.reload_callback = setup_args.reload_callback or nil;

    M.setup_commands()
    M.store_projects(setup_args.projects or {})
end

M.reload = function()
    if M.verbose > 1 then
        print("LightProjects: Reloading")
    end

    if M.reload_callback == nil then
        print("LightProjects: No reload callback set")
        return
    end

    M.reload_callback()
end

M.open_config = function()
    if M.config_path == nil then
        print("LightProjects: No config path set")
        return
    end

    vim.api.nvim_win_set_buf(0, vim.fn.bufadd(M.config_path))
end

--local terms = require('toggleterm.terminal')
--local terminal = terms.get_all()[1]
--print(terminal.id)

return M
