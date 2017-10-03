local exec = require('rover.exec')
local env = require('rover.env')

local cmd = table.remove(arg, 1)

exec(cmd, arg, env)
