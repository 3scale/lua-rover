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

    it('dependency, hash and multipe groups', function()
      local dep = _M.parse_line('apicast scm-1|91a28825d759f580cae17c2344|foobar,production')
      assert.same({ hash = '91a28825d759f580cae17c2344' }, dep.source)
      assert.same({ 'foobar', 'production' }, dep.groups)
    end)

  end)
end)
