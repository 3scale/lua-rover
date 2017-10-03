local cli = require 'cliargs'

local _M = { }

local mt = {}

local function load_commands(commands)
    for i=1, #commands do
        commands[commands[i]] = require('rover.cli.' .. commands[i])
    end
    return commands
end

_M.commands = load_commands({ 'exec', 'install', 'lock' })

function mt.__call(self, arg)
    -- now we parse the options like usual:
    local args, err = cli:parse()

    if not args and err then
        print(err)
        os.exit(1)
    elseif args and #args == 0 then
        self.commands.install()
    else

    end
end

return setmetatable(_M, mt)
