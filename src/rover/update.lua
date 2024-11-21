local install = require('rover.install')
local tree = require('rover.tree')
local path = require('luarocks.path')

local _M = {

}

function _M:call(lock, dependencies)
    path.use_tree(tostring(tree))
    local res, err = lock:resolve(dependencies)

    if not res and err then return nil, err end

    res, err = install:call(lock, dependencies)

    if not res and err then return nil, err end

    lock:write()

    return res, err
end


return _M
