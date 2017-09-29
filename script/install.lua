local lock = require('rover.lock').read()

local install = require('rover.install')

install:call(lock)
