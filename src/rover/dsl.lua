local setmetatable = setmetatable
local ipairs = ipairs
local insert = table.insert
local format = string.format
local unpack = unpack

local _M = {

}

local mt = { __index = _M }

function _M.new()
    return setmetatable({
        modules = {}
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
        manifest = manifest('root')
    }, module_mt)
end

function _M:module(spec)
    local mod = module(unpack(spec))
    insert(self.modules, mod)
    return mod
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
            modules[i].group = name
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

local exported = { 'module', 'manifest', 'luarocks', 'opm', 'group' }

function _M:env()
    local env = {}

    for _,fn in ipairs(exported) do
        env[fn] = wrap_self(self, fn)
    end

    return env
end

return _M
