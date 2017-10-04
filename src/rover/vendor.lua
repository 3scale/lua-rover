local require = require
local pcall = pcall

require('rover.tree')

local _M = {

}

function _M.require(modname)
    local ok, ret = pcall(require, 'rover.vendor. ' .. modname)

    if ok and ret then return ret end

    return require(modname)
end

return _M
