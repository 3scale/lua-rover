local _M = require('rover.roverfile')

describe('roverfile', function()
    it('is', function() assert(_M) end)

    local function tmp(content)
        local file = io.tmpfile()

        file:write(content or '')
        file:seek('set', 0)

        return file
    end

    describe('.read', function()
        it('reads a file', function()
            local file = tmp("\n")
            assert(_M.read(file))
        end)

        it('evaluates', function()
            local file = tmp([[syntax-error]])

            local ok, err = _M.read(file)

            assert.match([[expected near '-']], err, nil, true)
            assert.falsy(ok)
        end)
    end)

    describe(':eval', function()
        it('uses dsl', function()

            local roverfile = _M.new()


            assert(roverfile:eval([[
luarocks {
    module { 'inspect' },

    manifest 'luajit' {
        module { '30log', '>= 1.3' },
        module { 'bpf' },
    }
}

opm {
}
            ]]))
        end)
    end)
end)
