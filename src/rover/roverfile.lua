local setmetatable = setmetatable
local load = load
local pcall = pcall
local open = io.open
local insert = table.insert

local dsl = require('rover.dsl')
local lock = require('rover.lock')

local _M = {
    DEFAULT_PATH = 'Roverfile'
}

local mt = { __index = _M }

local function read(self)
    local handle, err = open(self.path)
    if not handle then return nil, err end

    local ok
    ok, err = self:eval(handle:read('*a'))

    if ok then return self else return nil, err end
end

function _M.read(path)
    local roverfile = _M.new(path)
    return roverfile:read()
end

function _M.new(path)
    return setmetatable({
        read = read,
        path = path or _M.DEFAULT_PATH,
        modules = {}
    }, mt)
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
