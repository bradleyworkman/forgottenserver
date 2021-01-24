require 'data/lib/standard'

-- global constants defining log level
DEBUG = 0
INFO = 1
WARN = 2
ERROR = 3

if not Logging then
    function Logging(level)
    --[[
        OPTIONAL {number} level - the level that logging should be set to, messages at or above this level are output

        return a Logging object with methods to output data (tostring is called on all parameters of logging methods)

        all log messages are timestamped in ISO-18601 format (without timezone)

        TODO log to a file
    ]]
        local function _format(...)
            local timestamp = os.date("%Y-%m-%dT%H:%M:%S")
            local args = {}

            for i = 1, select('#', ...) do
                table.insert(args, tostring(select(i, ...)))
            end

            return string.format("[%s] %s", timestamp, join(" ", args))
        end

        local _log = {level=level or INFO}

        function _log:debug(...)
        --[[
            OPTIONAL {value} 1,...n - values to append to log message, tostriung is called on the arguments and they are appended to the message in order separated by a " "

            return nil
        ]]
            if self.level > DEBUG then return end
            print(_format("DEBUG:",...))
        end

        function _log:info(...)
        --[[
            see debug
        ]]
            if self.level > INFO then return end
            print(_format("INFO:",...))
        end

        function _log:warning(msg, ...)
        --[[
            see debug
        ]]
            if self.level > WARN then return end
            print(_format("WARNING:",...))
        end

        function _log:error(...)
        --[[
            see debug
        ]]
            if self.level > ERROR then return end
            print(_format("ERROR:"))
            error(join(" ", {...}))
        end

        return _log
    end
end

-- TODO set logging level based on configuration
logging = logging or Logging()

function jsonify(o,visited)
--[[
    REQUIRED {value} o       - a Lua value to marshal to JSON 
    OPTIONAL {table} visited - a list of values that have already been jsonified and will be tostring'd instead, this value is used to prevent circular references in a table

    return a string representing the value in valid JSON
]]
    visited = type(visited) == "table" and visited or {}

    if contains({"thread", "userdata", "function"}, type(o)) or contains(visited, o) then
        return string.format('"[%s]"', o)
    end

    if type(o) == "table" then
        table.insert(visited, o)

        local buf = ""
        if is_list(o) then
            for _,v in ipairs(o) do
                buf = string.format("%s%s,", buf, jsonify(v, visited))
            end

            return string.format("[%s]", butlast(buf))
        else
            for k,v in pairs(o) do
                buf = string.format('%s"%s":%s,', buf, tostring(k), jsonify(v, visited))
            end

            return string.format("{%s}", butlast(buf))
        end

    else -- string, number, boolean, nil
        return string.format('"%s"',o)
    end
end