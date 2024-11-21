local pairs = pairs
local insert = table.insert
local queries = require("luarocks.queries")

local rover_rockspec = require('rover.rockspec')
local _M = {

}

function _M.call(lock)
    local index = lock:index()

    local dependencies = {}

    for name, spec in pairs(index) do
        local query = queries.new(name, nil, spec.version, false, "src|rockspec")
        local rockspec = rover_rockspec.find(query)

        insert(dependencies, {
            name = name,
            version = spec.version,
            license = rockspec.description.license,
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
