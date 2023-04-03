local M = {}

M.get_path = function(file_path)
    file_path = vim.fn.expand(file_path)

    if (M.on_windows) then
        file_path = file_path:gsub('\\', '/')
    end

    if file_path:sub(-1) ~= '/' then
        file_path = file_path .. '/'
    end

    return file_path
end

M.tif = function(cond, a, b)
    if cond then
        return a
    else
        return b
    end
end

M.exe = function(exe_base_name)
    if M.on_windows then
        exe_base_name = exe_base_name .. '.exe'
    end

    return exe_base_name
end

M.setup_default_key_mappings = function(default_mappings)
    if default_mappings == nil then
        return
    end

    for _, action in pairs(M.possible_default_actions) do
        if (default_mappings[action] ~= nil) then
            M.default_mappings[action] = default_mappings[action]
        end
    end
end

M.setup_autocommands = function()
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

M.setup = function(setup_args)
    if setup_args.verbose == nil then setup_args.verbose = 0 end
    if setup_args == nil then setup_args = {} end
    if setup_args.default_mappings == nil then setup_args.default_mappings = {} end
    if setup_args.projects == nil then setup_args.projects = {} end

    M.setup_args = setup_args

    M.possible_default_actions = {
        'configure',
        'build',
        'run',
        'test',
        'bench',
        'clean',
        'debug',
        'build_and_run',
        'build_and_test',
        'build_and_bench',
        'build_and_debug',
    }
    M.on_windows = vim.fn.has('win32')

    M.setup_autocommands()
    M.reload()
end

M.reload = function()
    M.default_mappings = {}
    M.project_paths = {}
    M.use_toggleterm = M.setup_args.use_toggleterm
    M.setup_default_key_mappings(M.setup_args.default_mappings)
    M.current_project_path = M.get_path(vim.fn.getcwd())
    M.config_path = M.setup_args.config_path

    local opts = { noremap = true, silent = true }

    if M.setup_args.verbose > 1 then
        print("LightProjects: current path: " .. M.current_project_path)
    end

    -- Storing paths
    for proj_name, p in pairs(M.setup_args.projects) do -- Path to project
        if p.path == nil then
            print("LightProjects: Project " .. proj_name .. " has no path")
            return
        end

        M.project_paths[M.get_path(p.path)] = proj_name
    end

    -- Default mappings
    M.project = M.setup_args.projects[M.project_paths[M.current_project_path]]

    if M.project ~= nil and M.setup_args.verbose > 0 then
        print("LightProjects: [" .. M.project_paths[M.current_project_path] .. "]")
    else
        return
    end

    local operations = {
        build_and_run = { 'build', 'run' },
        build_and_test = { 'build', 'test' },
        build_and_bench = { 'build', 'bench' },
        build_and_debug = { 'build', 'debug' },
    }

    for op, actions in pairs(operations) do
        if M.project[op] == nil and M.project[actions[1]] ~= nil and M.project[actions[2]] ~= nil then
            M.project[op] = {
                cmd = M.project[actions[1]].cmd .. "; " .. M.project[actions[2]].cmd
            }
        end
    end

    for _, action in pairs(M.possible_default_actions) do
        if M.project[action] ~= nil then
            local a = M.project[action]
            M.set_keymap(
                'n', M.default_mappings[action], a.cmd, opts, {
                    toggleterm = a.toggleterm,
                    cd_before_cmd = a.cd_before_cmd,
                }
            )
        end
    end

    if M.project.callback ~= nil then
        M.project.callback()
    end
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
