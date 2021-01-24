-- global constants used in the standard library
_BAD_ARGUMENT = "bad argument #%s to '%s' (%s expected, got %s)"
_WRONG_NUMBER_ARGUMENTS = "wrong number of arguments to '%s'"

function map(f, t)
--[[
    REQUIRED {function} f - function to map onto table t
    REQUIRED {table}    t - table to get values from

    return a new tightly packed table with all the values of f(t[n]) for n in 1,#t

    throws errors if called with the wrong number of arguments or if t is not a tightly packed array (see is_list)
]]
    local fn = 'map'

    if not f or not t then
        error(_WRONG_NUMBER_ARGUMENTS:format(fn))
    end

    if not is_list(t) then
        error(_BAD_ARGUMENT:format('2', fn, 'array', type(t)))
    end

    local r = {}

    for _,v in ipairs(t) do
        table.insert(r, f(v))
    end

    return r
end

function reduce(f, t, i)
--[[
    REQUIRED {function} f - the accumulator function
    REQUIRED {table}    t - table to get values from
    REQUIRED {value}    i - initial value to accumulate from

    return the accumulated value of applying function f over table t

    accumulator function f should have the form function(accumulated_value, current_value) such that accumulated_value is the result of the last call to f (or initial value if first call) and current_value is a value in the tightly packed array t (see is_list)

    throws errors if called with the wrong number of arguments or if t is not a tightly packed array
]]
    local fn = 'reduce'

    if not f or not t or not i then
        error(_WRONG_NUMBER_ARGUMENTS:format(fn))
    end

    if not is_list(t) then
        error(_BAD_ARGUMENT:format('2', fn, 'array', type(t)))
    end

    for _,v in ipairs(t) do
        i = f(i, v)
    end

    return i
end

function filter(f, t)
--[[
    REQUIRED {function} f - filter function to apply to every element of t
    REQUIRED {table}    t - a tightly packed array of values to filter

    returns a new tightly packed array containing only the values from t that f returned a truthy value for

    throws errors if called with the wrong number of arguments or if t is not a tightly packed array
]]
    local fn = 'filter'

    if not f or not t then
        error(_WRONG_NUMBER_ARGUMENTS:format(fn))
    end

    if not is_list(t) then
        error(_BAD_ARGUMENT:format('2', fn, 'array', type(t)))
    end

    local r = {}
    for _,v in ipairs(t) do
        if f(v) then
            table.insert(r, v)
        end
    end

    return r
end

function join(str, t)
--[[
    REQUIRED {string} str - a separator string to place between all elements of t
    REQUIRED {table}  t   - a table (tight array) of elements to join into a string

    return a string joining elements of t with separator str

    tostring will be called on all elements of t
]]
    return table.concat(map(tostring, t), str)
end

function size(t)
--[[
    REQUIRED {table} t - a table to count the elements of

    return the number of keys in t

    counts the direct keys on t using pairs function, works on tight and sparse tables
]]

    local s = 0
    for _,v in pairs(t) do
        s = s + 1
    end

    return s
end

function now()
--[[
    returns the current operating system time in milliseconds
]]
    return os.time() * 1000
end

function reverse_lookup(t, value)
--[[
    REQUIRED {table} t     - table to search
    REQUIRED {value} value - value to search table t for
   
    return the key associated with value in table t if it exists, else nil
]]

    for k,v in pairs(t) do
        if v == value then return k end
    end

    return nil
end

function contains(t, v)
--[[
    REQUIRED {table} t - table to search
    REQUIRED {value} v - value to search for

    returns true if table t contains value v else returns false
]]

    return nil ~= reverse_lookup(t, v)
end

function is_list(t)
--[[
    REQUIRED {table} t - table to test

    returns true if and only if t is a tightly packed array
]]
    if type(t) ~= "table" then return false end

    count = 0
    for k,v in pairs(t) do
        count = count + 1
    end

    return #t == count
end

function butlast(s, n)
--[[
    REQUIRED {string} s - the string to truncate
    OPTIONAL {number} n - the number of characters to remove from the end of the string; default 1

    return the string representing all but the last n characters of s
]]
    n = n and n > 0 and n or 1

    return string.sub(s,1,string.len(s)-n)
end

function identity(x)
--[[
    OPTIONAL {value} x - any Lua value; default nil

    returns the value x unaltered
]]
    return x
end

function sum(...)
--[[
    OPTIONAL {number} 1,...n - either single tightly packed array of numbers to sum or N numbers to sum; default 0

    return the mathematical sum of the numbers passed to the function
]]
    local args = {...}
    args = #args == 1 and args[1] or args
    return reduce(function(s, v) return s + v end, args, 0)
end