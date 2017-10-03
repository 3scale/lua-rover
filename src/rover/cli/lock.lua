local setmetatable = setmetatable

local file = require('rover.roverfile')
local cliargs = require('cliargs')

local cli = cliargs:command('lock', 'Lock dependencies')


local _M = {
    _NAME = 'Lock dependencies',
}

cli:action(_M)

local mt = { }

function mt:__call(options)
    local roverfile, err = file.read()

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

return setmetatable(_M, mt)
