local setmetatable = setmetatable
local remove = table.remove

local exec = require('rover.exec')
local env = require('rover.env')

local _M = {}

local mt = {}

function mt:__call(options)
    local cmd = remove(options.command, 1)
    return exec(cmd, options.command, env)
end

function _M:new(parser)
    local cmd = parser:command('exec', 'Exec command')

    cmd:argument('command'):args("+")

    cmd:handle_options(false)

    return setmetatable({ parser = parser, cmd = cmd }, mt)
end


return setmetatable(_M, mt)
