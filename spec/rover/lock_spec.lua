local _M = require('rover.lock')

describe('lock', function()
  describe('.parse_line', function()
    it('dependency with version', function()
      local dep = _M.parse_line('argparse 0.5.0-1')
      assert.same({ }, dep.source)
    end)

    it('dependency and empty hash', function()
      local dep = _M.parse_line('argparse 0.5.0-1|')
      assert.same({ hash = '' }, dep.source)
    end)

    it('dependency and hash', function()
      local dep = _M.parse_line('argparse 0.5.0-1|foobar')
      assert.same({ hash = 'foobar' }, dep.source)
    end)

    it('dependency, empty hash and a group', function()
      local dep = _M.parse_line('argparse 0.5.0-1||production')

      assert.same({'production'}, dep.groups)
    end)
  end)
end)
