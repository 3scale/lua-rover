local path = require('luarocks.path')

local _M = {
    root = os.getenv('PWD') .. '/lua_modules'
}

local mt = {
    __index = {
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
    },
    __tostring = function(t) return t.root or _M.root end
}

path.use_tree(_M.root)

return setmetatable(_M, mt)
