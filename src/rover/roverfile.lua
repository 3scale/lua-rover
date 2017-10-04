local setmetatable = setmetatable
local load = load
local pcall = pcall

local insert = table.insert

local dsl = require('rover.dsl')
local lock = require('rover.lock')

local _M = {
    DEFAULT_PATH = 'Roverfile'
}

local mt = { __index = _M }

function _M.read(file)
    local p = file or _M.DEFAULT_PATH

    local roverfile = _M.new()

    local handle = type(p) == 'string' and io.open(p) or p

    local ok, err = roverfile:eval(handle:read('*a'))

    if ok then return roverfile else return false, err end
end

function _M.new()
    return setmetatable({ modules = { }}, mt)
end

local function add_modules(table, modules)
    for i=1, #(modules) do
        insert(table, modules[i])
    end
end

function _M:eval(chunk)
    local dsl = dsl.new(self)
    local ok, err = load(chunk, _M.DEFAULT_PATH, 't', dsl:env())

    local modules = {}

    if ok then
        ok, err = pcall(ok)
    end

    if ok then
        add_modules(modules, dsl.modules)

        for i=1, #(dsl.rockspecs) do
            add_modules(modules, dsl.rockspecs[i].modules)
        end

        add_modules(self.modules, modules)

        return modules
    else
        return nil, err
    end
end

function _M:lock()
    return lock.new(self)
end

return _M
