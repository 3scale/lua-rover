local setmetatable = setmetatable

local exec = require('rover.exec')
local env = require('rover.env')

local cliargs = require('cliargs')
local cli = cliargs
    :command('exec', 'Exec command')
    :argument('command', 'Command to be executed')
    :splat('args', 'Arguments to the command', nil, 999)


local _M = {

}

cli:action(_M)


local mt = {}

function mt:__call(options)
    return exec(options.command, options.args or {}, env)
end

return setmetatable(_M, mt)
