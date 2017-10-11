local install = require('rover.install')

local _M = {

}

function _M:call(lock, dependencies)
    local res, err = lock:resolve(dependencies)

    if not res and err then return nil, err end

    res, err = install:call(lock, dependencies)

    if not res and err then return nil, err end

    lock:write()

    return res, err
end


return _M
