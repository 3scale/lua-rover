local fetch = require('luarocks.fetch')
local search = require('luarocks.search')
local deps = require('luarocks.deps')
local manif = require('luarocks.manif')
local path = require('luarocks.path')
local dir = require('luarocks.dir')

local tree = require('rover.tree')

local _M = { }

local function find_cached_rockspec(query)
    local versions = manif.get_versions({query.name}, 'one')
    local rockspec, err
    path.use_tree(tostring(tree))

    for i=1, #versions do
        local version = deps.parse_version(versions[i])

        if deps.match_constraints(version, query.constraints) then
            local file = tree.rockspec_file(query.name, versions[i])
            rockspec, err = fetch.load_local_rockspec(file, false)
            if rockspec then break end
        end
    end

    return rockspec, err
end

local function find_remote_rockspec(query)
    local rockspec, err, rock
    local file = search.find_rock_checking_lua_versions(query)

    if not file then
        return nil, "could not find module " ..query
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

local function load_rockspec(query, no_cache)
    local use_cache = not no_cache[query.name]
    local rockspec, err

    if use_cache then
        rockspec, err = find_cached_rockspec(query)
    end

    if not rockspec then
        rockspec, err = find_remote_rockspec(query)
    end

    return rockspec, err
end

function _M.find(query, no_cache)
    return load_rockspec(query, no_cache or {})
end

return _M
