local _M = {
    env = require('rover.env')
}

local mt = {}

function mt.__call()
    package.path = _M.env.path()
end

return setmetatable(_M, mt)()
