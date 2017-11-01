local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local package = package
local require = require
local pcall = pcall

local mt = {}
local _M = {}

local function collect_modules(loader, tree, module, cache)
    local found = tree.manifest.repository[module]
    local version = loader.context[module]
    if not found or not version then return nil end
    local modules = cache or {}

    for _, rock in ipairs(found[version]) do
        for module, file in pairs(rock.modules) do
            if not package.loaded[module] then
                modules[module] = file
            end
        end

        for dep, _ in pairs(rock.dependencies) do
            modules = collect_modules(loader, tree, dep, modules)
        end
    end

    return modules
end

local blacklist = {
    ['luarocks.fs.win32'] = true,
}

local function preload(loader)
    local context
    local rocks_trees = loader and loader.rocks_trees

    if not rocks_trees then return end

    local modules

    for _, tree in ipairs(rocks_trees) do
        if not modules then
            modules = collect_modules(loader, tree, 'lua-rover')
        end
    end

    if not modules then return end

    for module, _ in pairs(modules) do
        if not blacklist[module] then
            require(module)
        end
    end
end

function mt.__call()
    local path = package.path
    local version = _VERSION:match('%d.%d')

    package.path = ('lua_modules/share/lua/%s/?.lua;%s'):format(version, path)

    local roverfile = require('rover.roverfile')
    local env = require('rover.env')

    package.path = path

    local ok, loader = pcall(require, 'luarocks.loader')

    if ok then preload(loader) end

    if roverfile.read() then
        package.path = env.path() -- remove global load paths
    end
end

return setmetatable(_M, mt)
