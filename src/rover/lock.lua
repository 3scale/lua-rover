local setmetatable = setmetatable
local pairs = pairs
local ipairs = ipairs
local type = type
local tostring = tostring
local assert = assert
local error = error
local insert = table.insert
local sort = table.sort
local format = string.format
local open = io.open

local deps = require('luarocks.deps')
local rover_rocspec  = require('rover.rockspec')

local _M = {
    DEFAULT_PATH = 'Roverfile.lock'
}

local mt = { __index = _M }

local dependencies_mt = {
    __tostring = function(t)
        local str = ""
        local dependencies = {}

        for name, version in pairs(t) do
            insert(dependencies, { name = name, version = version })
        end

        sort(dependencies, function(a,b) return a.name < b.name end)

        for i=1, #dependencies do
            str = str .. format('%s %s\n', dependencies[i].name, dependencies[i].version)
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
    local handle, err

    if type(file) == 'string' then
        handle, err = open(file)
    else
        handle = file
    end

    if not handle then return nil, err end

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

local function expand_dependencies(dep, dependencies, no_cache)
    local rockspec = rover_rocspec.find(dep.name, dep.constraints, no_cache)

    if not dependencies[rockspec.name] then
        dependencies[rockspec.name] = rockspec.version
    elseif dependencies[rockspec.name] ~= rockspec.version then
        error('cannot have two '  .. rockspec.name)
    end

    local matched, missing, _ = deps.match_deps(rockspec, nil, 'one')

    for _, dep in pairs(matched) do
        expand_dependencies(dep, dependencies, no_cache)
    end

    for _, dep in pairs(missing) do
        expand_dependencies(dep, dependencies, no_cache)
    end
end

function _M:resolve(no_cache)
    local index = assert(self:index())
    local dependencies = setmetatable({}, dependencies_mt)

    for name,spec in pairs(index) do
        expand_dependencies({
            name = name,
            constraints = rover_rocspec.parse_constraints(spec.version)
        }, dependencies, no_cache or {})
    end

    self.resolved = dependencies

    return dependencies
end

function _M:write(file)
    local path = self.roverfile and self.roverfile.path
    local f = file or (path and path .. '.lock') or _M.DEFAULT_PATH
    local h = type(f) == 'string' and io.open(f, 'w') or file

    local deps = self.resolved or self:resolve()

    assert(h:write(tostring(deps)))

    h:close()
end

local function add_to_index(index, module)
    local existing =  index[module.name]

    if existing and existing.version ~= module.version then
        return nil, format('duplicate dependency %s (%s ~= %s)', module.name, existing.version, module.version)
    else
        index[module.name] = module
    end

    return module
end

local function index_from_roverfile(roverfile)
    local modules = roverfile.modules
    local index = {}

    for i=1, #modules do
        local module, err = add_to_index(index, modules[i])

        if not module and err then return nil, err end
    end

    return index
end

local function index_from_dependencies(dependencies)
    local index = {}

    for name, version in pairs(dependencies) do
        local module, err = add_to_index(index, { name = name, version = version })
        if not module and err then return nil, err end
    end

    return index
end

function _M:index()
    if self.roverfile then
        return index_from_roverfile(self.roverfile)
    elseif self.dependencies then
        return index_from_dependencies(self.dependencies)
    else
        return nil, 'cannot index dependencies'
    end
end

return _M
