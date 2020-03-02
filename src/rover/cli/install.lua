local setmetatable = setmetatable
local ipairs = ipairs
local next = next
local install = require('rover.install')
local rover_lock = require('rover.lock')
local tree = require('rover.tree')


local _M = {

}

local mt = { }

local function format_status(status)
    return string.format("package: %s\tstatus: %s %s", status.name, status.status, status.error or '')
end

function mt:__call(options)
    install.set_extra_cflags(os.getenv("EXTRA_CFLAGS"))
    local lock = options.roverfile .. '.lock'
    local lockfile = assert(rover_lock.read(lock))

    tree(options.path)

    local groups = {}

    for _,group in ipairs(options.only) do
        groups[group] = true
    end

    for _,group in ipairs(options.without) do
        groups[group] = false
    end

    setmetatable(groups, { __index = function() return true end })

    if next(options.only) then
        setmetatable(groups, { __index = function() return false end })
    end

    local status = install:call(lockfile, false, groups)

    for _,line in pairs(status) do
        print(format_status(line))
    end
end

function _M:new(parser)
    local cmd = parser:command('install', 'Install dependencies')

    cmd:option('--roverfile', 'Path to Roverfile', os.getenv('ROVER_ROVERFILE') or 'Roverfile')
    cmd:option('--path', 'Path where to install dependencies', os.getenv('ROVER_PATH') or '.')
    cmd:mutex(
        cmd:option('--without', ' List of groups referencing gems to skip during installation', {}):args('*'),
        cmd:option('--only', ' List of groups referencing gems to install during installation', {}):args('*')
    )

    return setmetatable({ }, mt)
end

return setmetatable(_M, mt)
