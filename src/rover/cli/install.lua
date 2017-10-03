local setmetatable = setmetatable

local cliargs = require('cliargs')
local install = require('rover.install')
local lock = require('rover.lock')

local cli = cliargs:command('install', 'Install dependencies')

local _M = {

}

local mt = { }

function mt:__call(options)
    local lockfile = lock.read()

    install:call(lockfile)
end

cli:action(_M)

return setmetatable(_M, mt)
