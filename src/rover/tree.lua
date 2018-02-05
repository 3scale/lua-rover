local setmetatable = setmetatable
local tostring = tostring

local path = require('luarocks.path')
local fs = require('luarocks.fs')
local cfg = require("luarocks.cfg")

local mt = { }
local _M = setmetatable({
    tree = 'lua_modules'
}, mt)


local __index = {
  rockspec_file = path.rockspec_file,
  lua_path = function(self)
    return path.deploy_lua_dir(tostring(self or _M))
  end,
  lua_cpath = function(self)
    return path.deploy_lib_dir(tostring(self or _M))
  end,
  bin_path = function(self)
    return path.deploy_bin_dir(tostring(self or _M))
  end,
  rocks_path = function(self)
    return path.rocks_dir(tostring(self or _M))
  end
}

local __index_fn = {
  lua_dir = __index.lua_path,
  lib_dir = __index.lua_cpath,
  bin_dir = __index.bin_path,
  rocks_dir = __index.rocks_path,
}

mt.__index = function(self, key)
  if __index_fn[key] then
    return __index_fn[key](self)
  else
    return __index[key]
  end
end

function mt.__tostring(self) return self.root or _M.root end

function mt.__call(self, root)
    self.root = fs.absolute_name(self.tree, fs.absolute_name(root))
    path.use_tree(self.root)

    cfg.rocks_trees = { self }

    -- because we are storing new field in the rockspec
    cfg.accept_unknown_fields = true

    return self
end

return _M(fs.current_dir())
