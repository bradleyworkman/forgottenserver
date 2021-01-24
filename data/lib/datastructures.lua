require 'data/lib/standard'
require 'data/lib/logging'

function _inherit_from_userdata(base, _super)
--[[
    REQUIRED {table}    base   - a table, usually the result of a call to mix (see mix), to set the metatable method __index on
    REQUIRED {userdata} _super - a userdata defined object with a metatable (ex Player, Npc, etc.) to "inherit" functions from

    This method is meant for internal use only, to extend core object classes via mix(), do not use it unless you are sure you know what you are doing.

    The inherit method assumes all functions on _super are called via ':' to pass a self variable!
]]
    getmetatable(base).__index = function(table_, key)
            -- check if the key exists on the base table
            for k,v in pairs(base) do
                if k == key then return v end
            end

            -- if the key exists on _super (userdata) object and it's a function we will return a closure that assumes the function on _super is an object method
            if type(_super[key]) == "function" then
                return function(self, ...)
                        local meta = getmetatable(self)

                        if self == base or meta and meta.__in_chain and meta.__in_chain(base) then

                            -- TODO can't we always return this? Why do we care about if we're part of the chain, isnt THIS object always "inheriting" methods from _super?
                            return _super[key](_super, ...)
                        end

                        return _super[key](self, ...)
                    end
            end

            -- key didnt exist on base and it isnt a function in super, just return the value from super
            return _super[key]
        end
end

function mix(name, ...)
    --[[
        REQUIRED {string} name  - a class name for the returned object
        OPTIONAL {table} 2,...n - objects to inherit from (left to right)

        return an object that will inherit properties and methods from the optional list of objects if provided

        This is the main method behind the object oriented system. Properties will be searched first on the base object and then from left to right through the inheritance chain, returning the first one found.

        Objects returned by this function have the meta properties __class__ and __chain__ representing the arguments passed to this function. Furthermore they will have the metamethods __in_chain and __tostring.

        DO NOT SET metamethod __index on an object returned from this function, you will break the entire inheritance scheme
    ]]
    local chain = {...}
    local head = {}
    local fn = "mix"

    if not name then
        error(_WRONG_NUMBER_ARGUMENTS:format(fn))
    end

    local found = type(name)
    local expected = "string"
    if found ~= expected then
        error(_BAD_ARGUMENT:format(1, fn, expected, found))
    end

    expected = "table"
    for i,link in ipairs(chain) do
        found = type(link)
        if found ~= expected then
            error(_BAD_ARGUMENT:format(1 + i, fn, expected, found))
        end
    end

    return setmetatable(head, {
        __class__ = name,
        __chain__ = chain,
        __in_chain = function(other)
            --[[
                REQUIRED {table} other - an object to test if this object inherits from or not
            ]]
                return contains(chain, other)
            end,

        __index = function(table_, key)
                -- check on this base object for the key first
                for k,v in pairs(table_) do
                    if k == key then return v end
                end

                -- walk the chain from left to right, returning the first value found with this key
                for _,_super in ipairs(chain) do
                    if _super[key] then
                        return _super[key]
                    end
                end

                -- if we didnt find the key in any object along the inheritance chain, return nil
                return nil
            end,

        __tostring = function()
            --[[
                return a string representation of this object

                includes properties and methods found all the way up the inheritance chain. Return is of the form CLASSNAME..JSON
            ]]
                local facade = {}

                for k,v in pairs(head) do
                    facade[k] = v
                end

                for _,link in ipairs(chain) do
                    for k,v in pairs(link) do
                        if not facade[k] then
                            facade[k] = v
                        end
                    end
                end

                return string.format("%s%s",name,jsonify(facade))
            end})
end

function class(o)
--[[
    REQUIRED {table} o - table to return the metavalue class for

    return the class name passed to mix when this object was created
]]
    return getmetatable(o).__class__
end

function classes(o)
--[[
    REQUIRED {table} o - table to return a list of classes for

    return a tightly packed list of class names as passed to mix for all objects in this object's inheritance chain
]]
    local metatable = getmetatable(o)
    return metatable.__chain__ and filter(identity, map(class, metatable.__chain__)) or {}
end

if not Queue then
    function Queue(...)
    --[[
        OPTIONAL {value} 1,...n - either single tightly packed array of values or n values to initialize the queue with; default {}

        return a new Queue object (see mix)

        Queue is FIFO ordering, elements are popped from the queue in the same order they are added

        if you want to pass a single table element to exist as the first element in the queue instead of being the queue, you can call Queue(myTableElement, nil) to force myTableElement to be a single element in the Queue instead of the base

        TODO optimize this class, removing from the front is not a very fast operation, for heavy lifting this would have be fixed. You could keep an internal array and indices to avoid ever popping elements
    ]]
        local nargs = select('#', ...)

        if nargs > 1 then
            _queue = {...}
        elseif nargs == 1 then
            local arg = select(1,...)
            if type(arg) == "table" then
                _queue = arg
            else
                _queue = {arg}
            end
        else
            _queue = {}
        end

        function _queue:pop_front()
        --[[
            return the first element in the queue

            the element is removed from the queue
        ]]
            local tmp = self[1]
            table.remove(self, 1)
            return tmp
        end

        function _queue:push_back(x)
        --[[
            REQUIRED {value} x - a value to append to the back of the queue

            return nil
        ]]
            table.insert(self, x)
        end

        function _queue:size()
        --[[
            return the number of elements in this queue
        ]]
            return size(self)
        end

        return mix("Queue", _queue)
    end
end