local lock = require('rover.lock').read()

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

update:call(lock, dependencies)
