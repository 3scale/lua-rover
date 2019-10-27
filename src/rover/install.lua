local pairs = pairs
local ipairs = ipairs
local next = next

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

-- get_dep_spec function ensures that a valid spec config is retrieved from
-- luarocks, only two archirtectures work on luarocks 2.4, `rock` and
-- `rockspec`, `all` arch is not enabled, so that arch need to be skipped at
-- search.
local function get_dep_spec(name, version)
    local query = search.make_query(name:lower(), version)
    query["arch"] = "rockspec"
    local spec = search.find_suitable_rock(query)
    if spec then
      return spec
    end

    query["arch"] = "rock"
    return search.find_suitable_rock(query)
end

local function install(name, version, deps_mode, force)

    assert(fs.check_command_permissions({}))

    if force and force[name] then
        repos.delete_version(name, version, deps_mode)
    end

    if not repos.is_installed(name, version) then

        local spec = assert(get_dep_spec(name:lower(), version))

        if spec:match("%.rockspec$") then
            assert(build.build_rockspec(spec, true, false, deps_mode))
            return 'installed'
        elseif spec:match("%.src%.rock$") then
            assert(build.build_rock(spec, false, deps_mode))
            return 'installed'
        else
            error("can't install " .. spec, ", due to invalid spec format")
        end
    end

    return 'exists'
end

local function should_install(dep, desired_groups)
    local groups = dep.groups or {}

    if not next(desired_groups) then return true end

    for _,group in ipairs(groups) do
        if desired_groups[group] then return true end
    end

    return false
end


function _M:call(lock, force, groups)
    local status = {}

    local tree = require('rover.tree')

    for name, rockspec in pairs(lock.dependencies) do

        local ret, err

        if should_install(rockspec, groups) then
            ret, err = install(name, rockspec.version, _M.DEPS_MODE, force)
        else
            ret = 'skipped'
            err = 'group not allowed'
        end

        table.insert(status, { name = name, version = rockspec.version, status = ret, error = err })
    end

    return status
end

return _M
