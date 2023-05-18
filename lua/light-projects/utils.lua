local Utils = {}
local Path = require 'plenary.path'

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

local is_uri = function(filename)
  return string.match(filename, "^%w+://") ~= nil
end

local function is_root(pathname)
  if Path.path.sep == "\\" then
    return string.match(pathname, "^[A-Z]:\\?$")
  end
  return pathname == "/"
end

Utils.clean_path = function(pathname)
  if is_uri(pathname) then
    return pathname
  end

  -- Remove double path seps, it's annoying
  pathname = pathname:gsub(Path.path.sep .. Path.path.sep, Path.path.sep)

  -- Remove trailing path sep if not root
  if not is_root(pathname) and pathname:sub(-1) == Path.path.sep then
    return pathname:sub(1, -2)
  end
  return pathname
end

Utils.Path = function(pathname)
    return Path:new(Utils.clean_path(vim.fn.expand(pathname)))
end

return Utils
