local setmetatable = setmetatable
local yield = coroutine.yield
local unpack = unpack
local wait = ngx.thread.wait
local spawn = ngx.thread.spawn
local setmetatable = setmetatable
local pack = table.pack
local remove = table.remove

local _M = {

}

local UNSCHEDULED = 'unscheduled'
local PENDING = 'pending'
local FULFILLED = 'fulfilled'
local REJECTED = 'rejected'

function _M:new(fun, ...)
  return setmetatable({
    task = function(...) return fun(...) end,
    args = pack(...),
    state = UNSCHEDULED,
  }, { __index = self })
end

local function schedule(future)
  local state = future.state

  if not state then
    return nil, 'not initialized'
  end

  if state == UNSCHEDULED then
    future.state = PENDING
    future.co = spawn(future.task, unpack(future.args))
  end

  return future
end

local function execute(future)
  local co = future.co
  if not co then return nil, 'not scheduled' end

  local res = { wait(co) }
  local ok = remove(res, 1)

  if ok then
    future.res = res
    future.state = FULFILLED
  else
    future.state = REJECTED
    future.reason = res
  end

  future.co = nil

  return unpack(res)
end

function _M:value()
  local state = self.state

  if not state then
    return nil, 'not initialized'
  end

  if state == PENDING then
    return execute(self)
  else
    schedule(self)
    return self:value()
  end
end

local function call(future, ...)
  return schedule(future:new(...))
end

return setmetatable(_M, { __call = call })
