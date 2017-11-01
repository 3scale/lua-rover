require('rover.setup')()

local parser = require('rover.vendor').require('argparse')() {
    name = "rover",
    description = "Rover provides consistent environment for Lua projects."
}
local command_target = '_cmd'
parser:command_target(command_target)

parser:flag("-v --version", "Show version info and exit.")
    :action(function() print("Rover from git") os.exit(0) end)


local _M = { }

local mt = {}

local function load_commands(commands, parser)
    for i=1, #commands do
        commands[commands[i]] = require('rover.cli.' .. commands[i]):new(parser)
    end
    return commands
end

_M.commands = load_commands({ 'exec', 'install', 'lock', 'update', 'inspect' }, parser)

function mt.__call(self, arg)
    -- now we parse the options like usual:
    local ok, ret = self.parse(arg)
    local cmd = ok and ret[command_target]

    if ok and cmd then
        self.commands[cmd](ret)
    elseif ok then
        self.commands.install(ret)
    else
        print(ret)
        os.exit(1)
    end
end

function _M.parse(arg)
    return parser:pparse(arg)
end

return setmetatable(_M, mt)
