
local fs = require("luarocks.fs")
local path = require("luarocks.path")
local persist = require('luarocks.persist')
local type_check = require("luarocks.type_check")

require('rover.install')

local file = assert(arg[1], 'missing rockspec')
local rockspec = assert(persist.load_into_table(file))

local luamod_blacklist = {
    test = true,
    tests = true,
}

local prefix = ""

for _, parent in ipairs({"src", "lua"}) do
    if fs.is_dir(parent) then
        fs.change_dir(parent)
        prefix = parent.."/"
        break
    end
end

for _, file in ipairs(fs.find()) do
    local luamod = file:match("(.*)%.lua$")
    if luamod and not luamod_blacklist[luamod] then
        rockspec.build.modules[path.path_to_module(file)] = prefix..file
    end
end

fs.pop_dir()

print('writing updated ', file)
assert(persist.save_from_table(file, rockspec, type_check.rockspec_order))
