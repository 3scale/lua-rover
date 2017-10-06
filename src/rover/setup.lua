local _M = {
    env = require('rover.env'),
    roverfile = require('rover.roverfile').read()
}

local mt = {}

local _, loader = pcall(require, 'luarocks.loader')

local function collect_modules(tree, module, cache)
    local found = tree.manifest.repository[module]
    local version = loader.context[module]
    if not found or not version then return nil end
    local modules = cache or {}

    for _, rock in ipairs(found[version]) do
        for module, file in pairs(rock.modules) do
            modules[module] = file
        end

        for dep, _ in pairs(rock.dependencies) do
            modules = collect_modules(tree, dep, modules)
        end
    end

    return modules
end

local function preload()
    local context

    if loader then
        local modules

        for _, tree in ipairs(loader.rocks_trees) do
            if not modules then
                modules = collect_modules(tree, 'lua-rover')
            end
        end

        for module, _ in pairs(modules) do
            pcall(require, module) -- preload everything
        end
    end
end

function mt.__call()
    if _M.roverfile then
        preload() -- preload all rover dependencies

        package.path = _M.env.path() -- remove global load paths
    end
end

return setmetatable(_M, mt)
