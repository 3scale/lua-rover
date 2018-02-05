local tree = require('rover.tree')

local path = require('luarocks.path')

describe('tree', function()

  it('works with path.rocks_dir', function()
    local rocks_dir = path.rocks_dir(tree)

    assert.is_string(rocks_dir)
  end)

  describe('.lua_dir', function()
    it('is a string', function()
      assert.is_string(tree.lua_dir)
    end)
  end)

  describe('.lib_dir', function()
    it('is a string', function()
      assert.is_string(tree.lib_dir)
    end)
  end)

  describe('.bin_dir', function()
    it('is a string', function()
      assert.is_string(tree.bin_dir)
    end)
  end)

  describe('.rocks_dir', function()
    it('is a string', function()
      assert.is_string(tree.rocks_dir)
    end)
  end)

  describe(':lua_path()', function()
    it('returns a string', function()
      assert.is_string(tree:lua_path())
    end)
  end)

  describe(':lua_cpath()', function()
    it('returns a string', function()
      assert.is_string(tree:lua_cpath())
    end)
  end)

  describe(':bin_path()', function()
    it('returns a string', function()
      assert.is_string(tree:bin_path())
    end)
  end)
end)
