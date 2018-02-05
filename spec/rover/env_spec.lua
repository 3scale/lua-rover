local env = require('rover.env')

local tree = require('rover.tree')

describe('env', function()
  describe('path', function()
    it('is a string', function()
      assert.is_string(env.path(tree))
    end)
  end)

  describe('cpath', function()
    it('is a string', function()
      assert.is_string(env.cpath(tree))
    end)
  end)

  describe('bin', function()
    it('is a string', function()
      assert.is_string(env.bin(tree))
    end)
  end)
end)
