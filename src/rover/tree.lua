local setmetatable = setmetatable
local tostring = tostring

local path = require('luarocks.path')
local fs = require('luarocks.fs')
local cfg = require("luarocks.cfg")

local mt = { }
local _M = setmetatable({
    tree = 'lua_modules'
}, mt)

mt.__index = {
    rockspec_file = path.rockspec_file,
    lua_path = function(self)
        return path.deploy_lua_dir(self or _M)
    end,
    lua_cpath = function(self)
        return path.deploy_lib_dir(self or _M)
    end,
    bin_path = function(self)
        return path.deploy_bin_dir(self or _M)
    end,
    rocks_dir = function(self)
        return path.rocks_dir(tostring(self or _M))
    end
}
function mt.__tostring(self) return self.root or _M.root end

function mt.__call(self, root)
    self.root = fs.absolute_name(self.tree, fs.absolute_name(root))
    path.use_tree(self.root)

    -- because we are storing new field in the rockspec
    cfg.accept_unknown_fields = true

    return self
end

return _M(fs.current_dir())
