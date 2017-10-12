local pairs = pairs
local insert = table.insert

local rover_rockspec = require('rover.rockspec')
local _M = {

}

local function parse_license(name)
    return name:match('^[%w-%d%.]+')
end

function _M.call(lock)
    local index = lock:index()

    local dependencies = {}

    for name, spec in pairs(index) do
        local rockspec = rover_rockspec.find(name, spec.version)

        insert(dependencies, {
            name = name,
            version = spec.version,
            license = parse_license(rockspec.description.license),
        })
    end

    local i = 0
    local n = #dependencies

    return function()
        i = i + 1
        if i <= n then return dependencies[i] end
    end
end

return _M
