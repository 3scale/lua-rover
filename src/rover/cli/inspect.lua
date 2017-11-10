local setmetatable = setmetatable

local inspect = require('rover.inspect')
local lock = require('rover.lock')
local tree = require('rover.tree')

local _M = {

}

local mt = { }

function mt:__call(options)
    local lockfile, err = lock.read(options.roverfile .. '.lock')

    if not lockfile then
        return error(err)
    end

    tree(options.path)

    for dependency in inspect.call(lockfile) do
        print(dependency.name, ' ', dependency.version, ' ', dependency.license)
    end
end

function _M:new(parser)
    local cmd = parser:command('inspect', 'Inspect dependencies')

    cmd:option('--roverfile', 'Path to Roverfile', os.getenv('ROVER_ROVERFILE') or 'Roverfile')
    cmd:option('--path', 'Path where to install dependencies', os.getenv('ROVER_PATH') or '.')

    return setmetatable({ }, mt)
end

return setmetatable(_M, mt)
