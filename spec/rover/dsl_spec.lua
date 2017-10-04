
local _M = require('rover.dsl')

describe('DSL', function()

    it('has luarocks', function()
        local dsl = _M.new()

        assert(dsl:luarocks({}))
    end)

    it('has module', function()
        local dsl = _M.new()

        assert(dsl:module({}))
    end)

    it('has manifest', function()
        local dsl = _M.new()

        assert(dsl:manifest({}))
    end)

    it('has rockspec', function()
        local dsl = _M.new()

        assert(dsl:rockspec('lua-rover-scm-1.rockspec'))
    end)
end)
