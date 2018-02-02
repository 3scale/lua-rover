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
local concat = table.concat
local unpack = unpack

local deps = require('luarocks.deps')
local rover_rockspec = require('rover.rockspec')

local _M = {
    DEFAULT_PATH = 'Roverfile.lock'
}

local mt = { __index = _M }

local dependencies_mt = {
    __tostring = function(t)
        local dependencies = {}

        for name, rockspec in pairs(t) do
            insert(dependencies, {
                name = name, version = rockspec.version,
                hash = rockspec.source.hash,
                groups = rockspec.groups or {}
            })
        end

        sort(dependencies, function(a,b) return a.name < b.name end)

        for i=1, #dependencies do
            local str = format('%s %s|%s|%s',
                dependencies[i].name,
                dependencies[i].version,
                dependencies[i].hash or '',
                concat(dependencies[i].groups, ',')
            )

            dependencies[i] = str
        end

        return concat(dependencies, "\n")
    end
}

function _M.new(roverfile)
    return setmetatable({
        roverfile = roverfile,
        dependencies = setmetatable({}, dependencies_mt)
    }, mt)
end

local function split(str, sep)
    local sep, fields = sep or ":", {}
    local len = string.len(sep)
    local init = 0
    local match
    local begin
    if not str then return fields end

    while init do
        begin = init
        match, init = string.find(str, sep, init + 1, true)

        if match then
            insert(fields, string.sub(str, begin, match - begin - len))
        else
            insert(fields, string.sub(str, begin + len))
        end
    end

    return fields
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
        local dep, err = _M.parse_line(line)

        if dep then
            lock:add(dep)
        else
            return false, err
        end
    end

    return lock
end

function _M.parse_line(line)
    local constraint, hash, groups = unpack(split(line, '|'))
    local dep, err = assert(deps.parse_dep(constraint))

    if not dep then return nil, err end

    dep.source = { hash = hash }
    dep.groups = split(groups, ',')

    return dep
end

function _M:add(dep)
    local version

    for _, constraint in ipairs(dep.constraints) do
        if constraint.op == '==' then
            version = deps.show_version(constraint.version, false)
        end
    end

    if version then
        self.dependencies[dep.name] = {
            name = dep.name, version = version, source = dep.source, groups = dep.groups
        }
    else
        return nil, 'invalid constraints'
    end
end

local function rockspec_mismatch(cache, rockspec)
    local other = cache[rockspec.name]

    return other.version ~= rockspec.version or other.source.hash ~= rockspec.source.hash
end


local function expand_dependencies(dep, dependencies, no_cache)
    local rockspec = rover_rockspec.find(dep.name, dep.constraints, no_cache)
    local groups = dep.groups

    if not dependencies[rockspec.name] then
        -- TODO: would be better to introduce "dependency" class/object
        dependencies[rockspec.name] = rockspec
        rockspec.groups = groups
    elseif rockspec_mismatch(dependencies, rockspec) then
        error('cannot have two '  .. rockspec.name)
    end

    local matched, missing, _ = deps.match_deps(rockspec, nil, 'one')

    for _, dep in pairs(matched) do
        dep.groups = groups
        expand_dependencies(dep, dependencies, no_cache)
    end

    for _, dep in pairs(missing) do
        dep.groups = groups
        expand_dependencies(dep, dependencies, no_cache)
    end
end

function _M:resolve(no_cache)
    local index = assert(self:index())
    local dependencies = setmetatable({}, dependencies_mt)

    for name,spec in pairs(index) do
        expand_dependencies({
            name = name,
            groups = type(spec.group) == 'table' and spec.group or { spec.group },
            constraints = rover_rockspec.parse_constraints(spec.version)
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

    for _, module in pairs(dependencies) do
        local module, err = add_to_index(index, module)
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
