local roverfile = require('rover.roverfile').read()

local lock = roverfile:lock()

lock:write()
