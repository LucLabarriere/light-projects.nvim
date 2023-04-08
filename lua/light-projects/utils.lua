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

Utils.deep_copy = function (orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[Utils.deepcopy(orig_key, copies)] = Utils.deepcopy(orig_value, copies)
            end
            setmetatable(copy, Utils.deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

return Utils
