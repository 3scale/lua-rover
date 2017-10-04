local setmetatable = setmetatable

local file = require('rover.roverfile')

local _M = {
    _NAME = 'Lock dependencies',
}

local mt = { }

function mt:__call()
    local roverfile, err = assert(file.read())

    if not roverfile and err then
        return nil, err
    end

    local lock = roverfile:lock()

    print('Resolving Roverfile')

    local t1 = os.time()
    lock:resolve()
    print('Resolved Roverfile.lock in ', os.difftime(os.time(), t1), 's')
    return lock:write()
end


function _M:new(parser)
    parser:command('lock', self._NAME)

    return setmetatable({ }, mt)
end

return setmetatable(_M, mt)
