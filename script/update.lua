local roverfile = require('rover.roverfile').read()

local lock = roverfile:lock()
local dependencies = {}
local update_all = true

for i=1, #arg do
    dependencies[arg[i]] = true
    update_all = false
end

if update_all then
    dependencies = lock:index()
end

local update = require('rover.update')

assert(update:call(lock, dependencies))
