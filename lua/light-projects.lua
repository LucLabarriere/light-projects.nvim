local M = {}

local Utils = require 'light-projects.utils'
Utils.setup(M)

M.keymaps = {}
M.presets = {}
M.projects = {}
M.project_paths_name_mapping = {}
M.cmdtypes = {
    raw = 0,
    toggleterm = 1,
    sequential = 2,
    lua_function = 3,
}

-- On setup, we store the projects, and initialize the current project
-- Tochange:
-- Toggling a project means:
-- Applying preset then modifying it with project specific settings
--
-- Applying a preset means:
-- We store the variables
-- We store the commands
-- We use set_keymap
--

M.setup_commands = function()
    vim.api.nvim_create_augroup("LightProjects", { clear = true })
    vim.api.nvim_create_autocmd(
        { "DirChanged", "VimEnter" }, {
            command = ":LightProjectsReload",
            group = "LightProjects",
        }
    )

    vim.api.nvim_create_user_command("LightProjectsReload", ":lua require('light-projects').reload()", {})
    vim.api.nvim_create_user_command("LightProjectsConfig", ":lua require('light-projects').open_config()", {})
end

M.store_projects = function(projects)
    for proj_name, config in pairs(projects) do
        M.projects[proj_name] = {}
        local p = M.projects[proj_name]
        p.variables = {}
        p.commands = {}

        -- Storing path to project
        if p.path == nil then
            print("Incorrect project config: path to " .. proj_name .. " is nil")
            return
        end
        p.path = Utils.get_path(config.path)

        -- Storing path - proj_name mapping to be able to toggle projects
        M.project_paths_name_mapping[p.path] = proj_name

        -- Applying preset
        if config.preset ~= nil then
            Utils.deep_copy(M.presets[config.preset], p)
        end

        -- Storing additional variables
        if config.variables ~= nil then
            for var_name, var_value in pairs(config.variables) do
                p.variables[var_name] = var_value
            end
        end
        print(p.variables)

        -- Storing additional commands
        if config.commands ~= nil then
            for cmd_name, cmd_value in pairs(config.commands) do
                p.commands[cmd_name] = cmd_value
            end
        end
        print(p.commands)
    end
end

M.toggle_project = function()
    local opts = { noremap = true, silent = true }
    local p_path = Utils.get_path(vim.fn.getcwd())
    local p_name = M.project_paths_name_mapping[p_path]
    if p_name == nil then return end

    local p = M.projects[p_path]

    if M.setup_args.verbose > 0 then
        print("LightProjects: [" .. M.project_paths[M.current_project_path] .. "]")

        if M.setup_args.verbose > 1 then
            print("LightProjects: current path: " .. M.current_project_path)
        end
    end

    -- Here, apply keymappings

    if M.project.callback ~= nil then
        M.project.callback()
    end
end

M.setup = function(setup_args)
    M.setup_args = setup_args or {}

    M.on_windows = vim.fn.has('win32')
    M.verbose = setup_args.verbose or 1
    M.default_cmdtype = setup_args.default_cmdtype or M.cmdtypes.raw
    M.config_path = M.setup_args.config_path

    M.setup_commands()
    M.store_projects(setup_args.projects or {})
    M.toggle_project()
end

M.reload = function()
    if M.config_path == nil then
        print("No config path set")
        return
    end

    vim.api.nvim_exec("source " .. M.config_path, false)
    M.toggle_project()
end

M.open_config = function()
    if M.config_path == nil then
        print("No config path set")
        return
    end

    vim.api.nvim_win_set_buf(0, vim.fn.bufadd(M.config_path))
end

M.set_keymap = function(mode, lhs, rhs, opts, light_projects_opts)
    -- By default, cd before executing toggleterm command
    if light_projects_opts.cd_before_cmd == nil then
        light_projects_opts.cd_before_cmd = true
    end

    if light_projects_opts.toggleterm == nil then
        light_projects_opts.toggleterm = M.use_toggleterm
    end

    if light_projects_opts.toggleterm == true then
        if light_projects_opts.cd_before_cmd == true then
            rhs = "cd " .. M.current_project_path .. "; " .. rhs
        end

        if M.on_windows then
            rhs = rhs:gsub('"', '\\"')
        end

        rhs = ":TermExec cmd='" .. rhs .. "'<CR>"
    end

    if M.project.variables ~= nil then
        for k, v in pairs(M.project.variables) do
            rhs = rhs:gsub("${" .. k .. "}", v)
        end
    end

    if M.setup_args.verbose > 2 then
        print("Registered command: " .. rhs)
    end

    vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
end

return M
