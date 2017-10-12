local setmetatable = setmetatable

local inspect = require('rover.inspect')
local lock = require('rover.lock')

local _M = {

}

local mt = { }

function mt:__call()
    local lockfile, err = lock.read()

    if not lockfile then
        return error(err)
    end

    for dependency in inspect.call(lockfile) do
        print(dependency.name, ' ', dependency.version, ' ', dependency.license)
    end
end

function _M:new(parser)
    parser:command('inspect', 'Inspect dependencies')

    return setmetatable({ }, mt)
end

return setmetatable(_M, mt)
