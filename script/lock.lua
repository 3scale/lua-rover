local roverfile = assert(require('rover.roverfile').read())

local lock = roverfile:lock()

lock:write()
