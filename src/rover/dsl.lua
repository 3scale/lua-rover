local setmetatable = setmetatable
local ipairs = ipairs
local insert = table.insert
local concat = table.concat
local format = string.format
local unpack = unpack

local fetch = require('luarocks.fetch')
local fs = require('luarocks.fs')

local _M = {

}

local mt = { __index = _M }

local function root(path)
    if path == 'Roverfile' then return nil end
    return path:gsub('/Roverfile', '')
end

function _M.new(roverfile)
    return setmetatable({
        root = root(roverfile.path),
        modules = {},
        rockspecs = {},
    }, mt)
end

local manifest_mt = {
    __tostring = function(manifest)
        return format("manifest:%s", manifest.name)
    end
}

local function manifest(name)
    return setmetatable({ name = name }, manifest_mt)
end

local module_mt = {
    __tostring = function(module)
        return format("%s:%s", module.name, module.version)
    end
}

local function module(name, version)
    return setmetatable({
        name = name, version = version or '>= 0',
        groups = { 'production' },
        manifest = manifest('root')
    }, module_mt)
end


function _M:module(spec)
    local mod = module(unpack(spec))
    insert(self.modules, mod)
    return mod
end

local rockspec_mt = {
    __tostring = function(rockspec)
        return format("rockspec:%s", rockspec.name)
    end
}

local function rockspec(name)
    local rockspec = assert(fetch.load_local_rockspec(name, true))
    local modules = {}

    local spec = setmetatable({
        name = name,
        spec = rockspec,
        modules = modules }, rockspec_mt)


    for i=1, #(rockspec.dependencies) do
        local dep = rockspec.dependencies[i]
        local version = {}

        for c=1, #(dep.constraints) do
            version[c] = format('%s %s', dep.constraints[c].op, dep.constraints[c].version.string)
        end

        local mod = module(dep.name, concat(version, ', '))
        mod.rockspec = spec
        insert(modules, mod)
    end

    return spec
end

function _M:rockspec(name)
    local path = fs.absolute_name(name, self.root)
    local spec = rockspec(path)

    insert(self.rockspecs, spec)

    return spec
end

function _M:manifest(name)
    assert(name)
    local m = manifest(name)

    return function(modules)
        for i=1, #modules do
            modules[i].manifest = m
        end

        return { m, modules }
    end
end

function _M:group(name)
    assert(name)

    return function(modules)
        for i=1, #modules do
            modules[i].groups = { name }
        end

        return { 'group', name, modules }
    end
end

function _M:luarocks()
    return function(...) return {'luarocks', ... } end
end

function _M:opm()
    return function(...) return {'opm', ... } end
end


local function wrap_self(self, fn)
    return function(...)
        return self[fn](self, ...)
    end
end

local exported = { 'module', 'manifest', 'luarocks', 'opm', 'group', 'rockspec' }

function _M:env()
    local env = {}

    for _,fn in ipairs(exported) do
        env[fn] = wrap_self(self, fn)
    end

    return env
end

return _M
