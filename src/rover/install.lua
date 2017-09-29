local pairs = pairs

local fs = require('luarocks.fs')
local build = require("luarocks.build")
local repos = require("luarocks.repos")
local search = require('luarocks.search')

local _M = {
    DEPS_MODE = 'none'
}

-- this is really smelly fix for a really smelly issue
-- https://github.com/openresty/resty-cli/issues/35
local lines = getmetatable(io.output()).lines

getmetatable(io.output()).lines = function(self, ...)
    local iter = lines(self, ...)

    return function()
        local ok, ret = pcall(iter)

        if ok then return ret
        else return nil end
    end
end

local function install(name, version, deps_mode)

    assert(fs.check_command_permissions({}))

    if not repos.is_installed(name, version) then
        local spec = search.find_suitable_rock(search.make_query(name:lower(), version))

        if spec:match("%.rockspec$") then
            assert(build.build_rockspec(spec, true, false, deps_mode))
            return 'installed'
        elseif spec:match("%.src%.rock$") then
            assert(build.build_rock(spec, false, deps_mode))
            return 'installed'
        else
            error("can't install " .. spec)
        end
    end

    return 'exists'
end

function _M:call(lock)
    local status = {}

    for name, version in pairs(lock.dependencies) do
        local ret, err = install(name, version, _M.DEPS_MODE)
        table.insert(status, { name = name, version = version, status = ret, error = err })
    end

    return status
end

return _M
