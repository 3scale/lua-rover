local setmetatable = setmetatable

local update = require('rover.update')
local roverfile = require('rover.roverfile')

local _M = {}

local mt = {}

function mt:__call(options)
    local lock = roverfile.read():lock()
    local all = true
    local dependencies = {}

    for i=1, #(options.dependencies) do
        dependencies[options.dependencies[i]] = true
        all = false
    end

    if all then
        dependencies = lock:index()
    end

    return assert(update:call(lock, dependencies))
end

function _M:new(parser)
    local cmd = parser:command('update', 'Update dependencies')

    cmd:argument('dependencies'):args("*")

    return setmetatable({ parser = parser, cmd = cmd }, mt)
end


return setmetatable(_M, mt)
