local default_tree = require('rover.tree')

local _M = {

}

local mt = {
    __pairs = function(table)
        local t = {
            LUA_PATH = table.path(),
            LUA_CPATH = table.cpath(),
            PATH = table.bin(),
        }

        return next, t, nil
    end
}

local path_patterns = {
    '?.lua',
    '?/init.lua',
}

local cpath_patterns = {
    '?.so'
}

local function split(str, sep)
    if not str then return {} end
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(str, pattern, function(c) fields[#fields+1] = c end)
    return fields
end

function _M.path(tree)
    local lua_dir = (tree or default_tree):lua_path()
    local paths = split(os.getenv('LUA_PATH'), ';')

    for i=1, #path_patterns do
        table.insert(paths, i, lua_dir .. '/' .. path_patterns[i])
    end

    return table.concat(paths, ';') .. ';;'
end

function _M.cpath(tree)
    local lib_dir = (tree or default_tree):lua_cpath()
    local paths = split(os.getenv('LUA_CPATH'), ';')

    for i=1, #cpath_patterns do
        table.insert(paths, i, lib_dir .. '/' .. cpath_patterns[i])
    end

    return table.concat(paths, ';') .. ';'
end

function _M.bin(tree)
    local bin = (tree or default_tree):bin_path()
    local path = os.getenv('PATH')

    return bin .. ':' .. path
end

return setmetatable(_M, mt)
