local M = {}

M.on_windows = vim.fn.has('win32')

M.get_path = function(file_path)
    file_path = vim.fn.expand(file_path)

    if (M.on_windows) then
        file_path = file_path:gsub('\\', '/')
    end
    return file_path
end

M.get_cfg_folder = function()
    return M.get_path(vim.fn.stdpath('config'))
end

M.write_file = function(file_path, content)
    local file = io.open(file_path, 'w')
    if (file ~= nil) then
        file:write(content)
        file:close()
    end
end

M.read_file = function(file_path)
    local file = io.open(file_path, 'r')
    if (file ~= nil) then
        local content = file:read('*all')
        file:close()
        return content
    end
end

M.parse_command = function(content)
    local kmap = content['key_map']
    local cmd = content['cmd']
    local cmdtype = content['type']

    cmd = table.concat(cmd, ' ')

    if cmdtype == 'ToggleTerm' then
        cmd = ":TermExec cmd='" .. cmd .. "'"
    end

    cmd = cmd .. '<CR>'

    return {
        cmd = cmd,
        kmap = kmap,
    }
end

M.setup = function(setup_args)
    -- Config path
    if (setup_args == nil) then
        setup_args = {}
    end

    if (setup_args.config_path ~= nil) then
        M.config_path = setup_args['config_path']
    else
        M.config_path = M.get_cfg_folder() .. "/light_projects.json"
    end

    M.default_config = [[
{
    "nvim_conf": {
        "path": "C:/Users/Luc/.config/nvim",
        "run": ":so %<CR>",
        "key_maps": [
            {
                "mode": "n",
                "lfs": "<Leader>hello",
                "rhs": ":echo 'hello'<CR>"
            }
        ]
    }
}
]]

    M.run_mapping = setup_args.run_mapping
    M.build_mapping = setup_args.build_mapping
    M.configure_mapping = setup_args.configure_mapping

    if (not vim.fn.filereadable) then
        M.write_file(M.default_config, M.config_path)
    end

    M.key_maps_register = {} -- stores key maps for projects
    M.paths_register = {}    -- stores paths to projects

    -- Default keymaps
    vim.api.nvim_create_augroup("LightProjects", { clear = true })
    vim.api.nvim_create_autocmd(
        { "DirChanged", "VimEnter" }, {
            command = ":LightProjectsReload",
            group = "LightProjects",
        }
    )

    vim.api.nvim_create_user_command("LightProjectsReload", ":lua require('light-projects').reload()", {})
    vim.api.nvim_create_user_command("LightProjectsConfig", ":lua require('light-projects').open_config()", {})

    M.reload()
end

M.reload = function()
    M.projects = vim.json.decode(M.read_file(M.config_path))

    for proj_name, p in pairs(M.projects) do
        M.paths_register[p['path']] = proj_name
        M.key_maps_register[proj_name] = {}

        local key_maps = p['key_maps']

        if p['configure'] ~= nil then
            local res = M.parse_command(p['configure'])
            if M.configure_mapping ~= nil then
                table.insert(M.key_maps_register[proj_name], { "n", M.configure_mapping, res.cmd })
            end
        end

        if p['build'] ~= nil then
            local res = M.parse_command(p['build'])
            if M.build_mapping ~= nil then
                table.insert(M.key_maps_register[proj_name], { "n", M.build_mapping, res.cmd })
            end
        end

        if p['run'] ~= nil then
            local res = M.parse_command(p['run'])
            if M.run_mapping ~= nil then
                table.insert(M.key_maps_register[proj_name], { "n", M.run_mapping, res.cmd })
            end
        end

        -- Additional keymaps
        if (key_maps ~= nil) then
            for _, m in pairs(key_maps) do
                table.insert(M.key_maps_register[proj_name], { m.mode, m.lfs, m.rhs })
            end
        end
    end

    M.setup_keymaps()
end

M.setup_keymaps = function()
    local opts = { noremap = true, silent = true }
    local curr_path = M.get_path(vim.fn.getcwd())
    local proj_name = M.paths_register[curr_path]

    if proj_name ~= nil then
        for _, m in pairs(M.key_maps_register[proj_name]) do
            vim.api.nvim_set_keymap(m[1], m[2], m[3], opts)
        end
    end
end

M.open_config = function()
    vim.api.nvim_win_set_buf(0, vim.fn.bufadd(M.config_path))
end

return M
