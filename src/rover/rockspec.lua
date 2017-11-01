local type = type

local fetch = require('luarocks.fetch')
local search = require('luarocks.search')
local deps = require('luarocks.deps')
local manif = require('luarocks.manif_core')
local vers = pcall(require, 'luarocks.vers') or {}
local path = require('luarocks.path')
local dir = require('luarocks.dir')

local tree = require('rover.tree')

local parse_constraints = deps.parse_constraints or vers.parse_constraints or error('missing parse_constraints')
local any_constraints = parse_constraints('>= 0')

local _M = { }

local function find_cached_rockspec(name, constraints)
    local versions = manif.get_versions(name, 'one')
    local rockspec, err

    for i=1, #versions do
        local version = deps.parse_version(versions[i])

        if deps.match_constraints(version, constraints) then
            local file = tree.rockspec_file(name, versions[i])
            rockspec, err = fetch.load_local_rockspec(file, false)
            if rockspec then break end
        end
    end

    return rockspec, err
end

local function find_remote_rockspec(name, constraints)
    local rockspec, err, rock
    local query = {
        name = name:lower(),
        constraints = constraints,
        arch = 'src rockspec',
    }
    local file = search.find_suitable_rock(query)

    if not file then
        return nil, "could not find module " .. deps.show_dep(query)
    end

    if file:match("%.src%.rock$") then
        rock, err = fetch.fetch_and_unpack_rock(file)
        file = dir.path(rock, path.rockspec_name_from_rock(file))
    end

    if file:match("%.rockspec$") then
        rockspec, err = fetch.load_rockspec(file)

        if rockspec and not rock then
            fetch.fetch_sources(rockspec, false)
        end
    else
        error("can't handle " .. file)
    end

    return rockspec, err
end

local function load_rockspec(name, constraints, no_cache)
    local use_cache = not no_cache[name]
    local rockspec, err

    if use_cache then
        rockspec, err = find_cached_rockspec(name, constraints)
    end

    if not rockspec then
        rockspec, err = find_remote_rockspec(name, constraints)
    end

    return rockspec, err
end

function _M.find(name, constraints, no_cache)
    return load_rockspec(name, _M.parse_constraints(constraints), no_cache or {})
end

function _M.find_installed(name, constraints)
    return find_cached_rockspec(name, constraints or any_constraints)
end

function _M.parse_constraints(constraints)
    if not constraints then return any_constraints
    elseif type(constraints) == 'string' then
        return parse_constraints(constraints)
    else
        return constraints
    end
end

return _M
