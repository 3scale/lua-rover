local _M = require('rover.cli.exec')
local argparse = require('argparse')

describe('rover exec', function()
    it('passes arguments', function()
        local exec = _M:new(argparse())

        assert(exec.cmd:parse({'resty', '-e', 'print(package.path)'}))
    end)
end)
