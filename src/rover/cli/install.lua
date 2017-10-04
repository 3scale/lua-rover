local setmetatable = setmetatable

local install = require('rover.install')
local lock = require('rover.lock')

local _M = {

}

local mt = { }

function mt:__call()
    local lockfile = lock.read()

    install:call(lockfile)
end

function _M:new(parser)
    parser:command('install', 'Install dependencies')

    return setmetatable({ }, mt)
end

return setmetatable(_M, mt)
