local ffi = require 'ffi'

local typeof = ffi.typeof

local C = ffi.C

local function ffi_error()
    return ffi.string(C.strerror(ffi.errno()))
end

ffi.cdef([[
char *strerror(int errnum);
int execvp(const char *path, char *const argv[]);
int setenv(const char*, const char*, int);
]])

local string_array_t = typeof("const char *[?]")

local function setenv(name, value)
    local overwrite_flag = 1
    if C.setenv(name, value, overwrite_flag) == -1 then
        return nil, ffi_error()
    else
        return value
    end
end

local function execvp(filename, args, env)
    local argv = string_array_t(#args + 1 + 1)

    for i=1, #args do
        argv[i] = tostring(args[i])
    end

    argv[0] = filename
    argv[#args + 1] = nil

    local cargv = ffi.cast("char *const*", argv)

    for name, value in pairs(env or {}) do
        assert(setenv(name, value))
    end

    C.execvp(filename, cargv)
    error(ffi_error())
end

return execvp
