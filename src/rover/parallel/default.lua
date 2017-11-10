local setmetatable = setmetatable
local unpack

local _M = {


}

local function call(t, fun, args)
  return t:new(fun, args)
end

function _M:new(fun, args)
  return setmetatable({
    res = { fun(args) }
  }, { __index = self })
end

function _M:value()
  return unpack(self.res)
end

setmetatable(_M, { __call = call })

return _M
