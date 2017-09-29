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

function _M:eval(chunk)
    local dsl = dsl.new(self)
    local ok, err = load(chunk, _M.DEFAULT_PATH, 't', dsl:env())

    local modules = {}

    if ok then
        ok, err = pcall(ok)
    end

    if ok then
        for i=1, #(dsl.modules) do
            insert(modules, dsl.modules[i])
            insert(self.modules, dsl.modules[i])
        end

        return modules
    else
        return nil, err
    end
end

function _M:lock()
    return lock.new(self)
end

return _M
