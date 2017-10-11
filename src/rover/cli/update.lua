local setmetatable = setmetatable

local update = require('rover.update')
local lock = require('rover.lock')

local _M = {}

local mt = {}

function mt:__call(options)
    local lck = lock.read()
    local all = true
    local dependencies = {}

    for i=1, #(options.dependencies) do
        dependencies[options.dependencies[i]] = true
        all = false
    end

    if all then
        dependencies = lck:index()
    end


    return assert(update:call(lck, dependencies))
end

function _M:new(parser)
    local cmd = parser:command('update', 'Update dependencies')

    cmd:argument('dependencies'):args("*")

    return setmetatable({ parser = parser, cmd = cmd }, mt)
end


return setmetatable(_M, mt)
