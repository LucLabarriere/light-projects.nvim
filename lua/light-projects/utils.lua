local Utils = {}

Utils.setup = function(root_mod)
    Utils.root = root_mod
end

-- Helper function to get a valid path
Utils.get_path = function(file_path)
    file_path = vim.fn.expand(file_path)

    if (Utils.root.on_windows) then
        file_path = file_path:gsub('\\', '/')
    end

    if file_path:sub(-1) ~= '/' then
        file_path = file_path .. '/'
    end

    return file_path
end

-- Helper ternary if function
Utils.tif = function(cond, a, b)
    if cond then
        return a
    else
        return b
    end
end

Utils.replace_vars = function(cmd, variables)
    if variables ~= nil then
        for k, v in pairs(variables) do
            cmd = cmd:gsub("${" .. k .. "}", v)
        end
    end
    return cmd
end

Utils.read_line = function(file_path)
    local file = io.open(file_path, "r")

    if file == nil then
        return nil
    end

    local line = file:read("*l")
    file:close()
    return line
end

return Utils
