local setmetatable = setmetatable
local pairs = pairs

local path = require('luarocks.path')
local fetch = require('luarocks.fetch')
local search = require('luarocks.search')
local deps = require('luarocks.deps')
local vers = pcall(require, 'luarocks.vers') or {}
local manif = require('luarocks.manif_core')

local parse_constraints = deps.parse_constraints or vers.parse_constraints or error('missing parse_constraints')

path.use_tree(os.getenv('PWD') .. '/lua_modules')

local _M = {
    DEFAULT_PATH = 'Roverfile.lock'
}

local mt = { __index = _M }

local dependencies_mt = {
    __tostring = function(t)
        local str = ""
        for name, version in pairs(t) do
            str = str .. name .. ' ' .. version .. "\n"
        end

        return str
    end
}

function _M.new(roverfile)
    return setmetatable({
        roverfile = roverfile,
        dependencies = setmetatable({}, dependencies_mt)
    }, mt)
end

function _M.read(lockfile)
    local file = lockfile or _M.DEFAULT_PATH
    local handle = type(file) == 'string' and io.open(file) or file

    local lock = _M.new()


    for line in handle:lines() do
        local dep, err = deps.parse_dep(line)

        if dep then
            lock:add(dep)
        else return false, err
        end
    end

    return lock
end

function _M:add(dep)
    local version

    for _, constraint in ipairs(dep.constraints) do
        if constraint.op == '==' then
            version = deps.show_version(constraint.version, false)
        end
    end

    if version then
        self.dependencies[dep.name] = version
    else
        return nil, 'invalid constraints'
    end
end

local function load_rockspec(name, constraints)
    local versions = manif.get_versions(name, 'one')

    local rockspec, err

    for i=1, #versions do
        local version = deps.parse_version(versions[i])

        if deps.match_constraints(version, constraints) then
            local file = path.rockspec_file(name, versions[i])
            rockspec, err = fetch.load_local_rockspec(file, false)
        end
    end

    if not rockspec then
        local query = { name = name:lower(), constraints = constraints }
        query.arch = 'rockspec'
        local spec = assert(search.find_suitable_rock(query))
        rockspec, err = assert(fetch.load_rockspec(spec))
    end

    return rockspec, err
end

local function expand_dependencies(dep, dependencies)
    local rockspec = load_rockspec(dep.name, dep.constraints)

    if not dependencies[rockspec.name] then
        dependencies[rockspec.name] = rockspec.version
    elseif dependencies[rockspec.name] ~= rockspec.version then
        error('cannot have two '  .. rockspec.name)
    end

    local matched, missing, _ = deps.match_deps(rockspec, nil, 'one')

    for _, dep in pairs(matched) do
        expand_dependencies(dep, dependencies)
    end

    for _, dep in pairs(missing) do
        expand_dependencies(dep, dependencies)
    end
end

function _M:resolve()
    local index = self:index()
    local dependencies = setmetatable({}, dependencies_mt)

    for name,spec in pairs(index) do
        expand_dependencies({ name = name, constraints = parse_constraints(spec.version) }, dependencies)
    end

    self.resolved = dependencies

    return dependencies
end

function _M:write(file)
    local f = file or _M.DEFAULT_PATH
    local h = type(f) == 'string' and io.open(f, 'w') or file

    local deps = self.resolved or self:resolve()

    assert(h:write(tostring(deps)))

    h:close()
end

function _M:index()
    local modules = self.roverfile.modules
    local index = {}

    for i=1, #modules do
        if index[modules[i].name] then
            return nil, 'duplicate dependency', modules[i].name
        else
            index[modules[i].name] = modules[i]
        end
    end

    return index
end

return _M
