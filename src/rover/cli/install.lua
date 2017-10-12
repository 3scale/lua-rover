local setmetatable = setmetatable

local install = require('rover.install')
local rover_lock = require('rover.lock')
local tree = require('rover.tree')


local _M = {

}

local mt = { }

function mt:__call(options)
    local lock = options.roverfile .. '.lock'
    local lockfile = assert(rover_lock.read(lock))

    tree(options.path)

    install:call(lockfile)
end

function _M:new(parser)
    local cmd = parser:command('install', 'Install dependencies')

    cmd:option('--roverfile', 'Path to Roverfile', os.getenv('ROVER_ROVERFILE') or 'Roverfile')
    cmd:option('--path', 'Path where to install dependencies', os.getenv('ROVER_PATH') or '.')

    return setmetatable({ }, mt)
end

return setmetatable(_M, mt)
