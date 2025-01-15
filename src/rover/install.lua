local pairs = pairs
local ipairs = ipairs
local next = next

local fs = require('luarocks.fs')
local build = require("luarocks.build")
local cfg = require("luarocks.core.cfg")
local repos = require("luarocks.repos")
local search = require('luarocks.search')
local fetch = require('luarocks.fetch')
local path = require('luarocks.path')

local _M = {
    DEPS_MODE = 'none'
}

-- this is really smelly fix for a really smelly issue
-- https://github.com/openresty/resty-cli/issues/35
local lines = getmetatable(io.output()).lines

getmetatable(io.output()).lines = function(self, ...)
    local iter = lines(self, ...)

    return function()
        local ok, ret = pcall(iter)

        if ok then return ret
        else return nil end
    end
end

local function build_rock(rock_file, opts)
   local ok, err, errcode

   local unpack_dir
   unpack_dir, err, errcode = fetch.fetch_and_unpack_rock(rock_file)
   if not unpack_dir then
      return nil, err, errcode
   end
   local rockspec_file = path.rockspec_name_from_rock(rock_file)

   ok, err = fs.change_dir(unpack_dir)
   if not ok then return nil, err end

   local rockspec
   rockspec, err, errcode = fetch.load_rockspec(rockspec_file)
   if not rockspec then
      return nil, err, errcode
   end

   ok, err, errcode = build.build_rockspec(rockspec, opts)

   fs.pop_dir()
   return ok, err, errcode
end

local function install(name, version, deps_mode, force)

    assert(fs.check_command_permissions({}))

    if force and force[name] then
        repos.delete_version(name, version, deps_mode)
    end

    local opts = build.opts({
      need_to_fetch = true,
      minimal_mode = false,
      deps_mode = deps_mode,
      build_only_deps = false,
      namespace = "",
      branch = "",
      verify = false,
      check_lua_versions = false,
      pin = false,
      rebuild = force,
      no_install = false,
    })

    if not repos.is_installed(name, version) then
        local spec, err = assert(search.find_src_or_rockspec(name, nil, version))
        if not spec then
           return nil, err
        end

        if spec:match("%.rockspec$") then
            local rockspec, err = fetch.load_rockspec(spec, nil, opts.verify)
            if not rockspec then
               return nil, err
            end
            assert(build.build_rockspec(rockspec, opts))
            return 'installed'
        elseif spec:match("%.src%.rock$") then
            opts.need_to_fetch = false
            assert(build_rock(spec, opts))
            return 'installed'
        else
            error("can't install " .. spec, ", due to invalid spec format")
        end
    end

    return 'exists'
end

local function should_install(dep, desired_groups)
    local groups = dep.groups or {}

    if not next(desired_groups) then return true end

    for _,group in ipairs(groups) do
        if desired_groups[group] then return true end
    end

    return false
end

function _M.set_extra_cflags(flag)
  if not flag then
    return
  end

  cfg.variables.CFLAGS =  cfg.variables.CFLAGS .. " " .. flag
end

function _M:call(lock, force, groups)
    local status = {}

    local tree = require('rover.tree')

    for name, rockspec in pairs(lock.dependencies) do

        local ret, err

        if should_install(rockspec, groups) then
            ret, err = install(name, rockspec.version, _M.DEPS_MODE, force)
        else
            ret = 'skipped'
            err = 'group not allowed'
        end

        table.insert(status, { name = name, version = rockspec.version, status = ret, error = err })
    end

    return status
end

return _M
