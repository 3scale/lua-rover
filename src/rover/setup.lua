local _M = {
    env = require('rover.env'),
    roverfile = require('rover.roverfile').read()
}

local mt = {}

function mt.__call()
    if _M.roverfile then
        package.path = _M.env.path()
    end
end

return setmetatable(_M, mt)()
