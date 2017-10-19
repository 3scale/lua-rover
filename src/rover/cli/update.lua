local setmetatable = setmetatable

local update = require('rover.update')
local file = require('rover.roverfile')

local _M = {}

local mt = {}

function mt:__call(options)
    local roverfile = assert(file.read(options.roverfile))
    local lock = roverfile:lock()
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
    cmd:option('--roverfile', 'Path to Roverfile', 'Roverfile')

    return setmetatable({ parser = parser, cmd = cmd }, mt)
end


return setmetatable(_M, mt)
