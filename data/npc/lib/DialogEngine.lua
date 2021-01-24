function DialogEngine(greetings, responses)
    --[[
        DialogEngine is the primary class responsible for keeping track of what talk state the NPC is in (where in the dialog 'tree' they are), where they can transition to from there (what words/phrases they respond to at that point), and performing the actual state transition given the correct input.

        Users of this class should create objects of the child class DialogEngine.State, connect them, and add them to the machine. You may wish to call DialogEngine.exit() in order to exit the state machine and return the NPC state to default (ie listening for a greeting). See _All (DialogEngine.all) for helper methods that register a State as a sort of global that can be traversed to from any other state or can traverse to any other (registered) state.

        State can be transitioned by feeding the machine (see DialogEngine.on_say) input text which it then tries to match against valid transitions from the current state.

        If the machine processes input that does not represent a valid state transition and the machine has an unhandled method defined, it will be called, passing the query along.

        REQUIRED greetings - single phrase or list of phrases to respond to (ie enter the state machine)

        OPTIONAL responses - (see DialogEngine.State)
    ]]
    local _machine = {}

    -- private state for this machine
    local _current_states = nil

    _machine.reset = function(player)
        --[[
            reset private state of this machine; used on initialization and when the state machine exits (ex reaches a state with no outgoing edges)

            sets this machine back to default state ie listening for a greeting to respond with

            no return
        ]]

        if player then
            _current_states:__set(player, nil)

            for i,state in ipairs(_machine) do
                state.reset(player)
            end
        end

        _current_states = {}

        function _current_states:__set(player, state)
            self[player:getId()] = state
        end

        function _current_states:__get(player)
            return self[player:getId()]
        end

    end
    _machine.reset()

    _machine.exit = function(player, query)
        --[[
            REQUIRED query - the message that caused the transition 
        ]]

        current_state = _current_states:__get(player)

        if not current_state then return end

        current_state._on_exit(player, query)
        if _machine.on_exit then _machine.on_exit(player, query) end

        _machine.reset(player)
    end

    local _EdgeMap = function()
        -- helper class to store state machine mapping of queries to states
        local _edges = {}

        _edges.size = function()
            -- return number of edges stored in this map
            count = 0
            for _ in pairs(_edges) do count = count + 1 end

            return count
        end

        _edges.empty = function() 
            -- return true if this map has no edges else false
            return _edges.size() == 0
        end

        _edges.get = function(query)
            --[[
                REQUIRED query - string to check for valid transition

                note that query is compared case insensitive and produces a match on first occurence of a keyword -- ie if query contains multiple keywords you may get to a different state each time!

                return state pointed to by query or nil if no such state exists
            ]]

            query = query:lower()

            -- look for exact matches, if one is found return the state it points to
            for keyphrase,other in pairs(_edges) do
                if query == keyphrase then
                    return other
                end
            end

            -- look for partial matches, word by word
            for word in query:gmatch("%g+") do
                if _edges[word] then
                    return _edges[word]
                end
            end

            return nil
        end

        _edges.set = function(query, state)
            --[[
                REQUIRED query - a string or list of strings that should represent a valid state transition (see _EdgeMap.get)
                
                REQUIRED state - a DialogEngine.State to map to

                add new edges that points to state (one for each string given)

                no return
            ]]
            query = type(query) == "string" and {query} or query

            for i,keyphrase in ipairs(query) do
                _edges[keyphrase:lower()] = state
            end
        end

        return _edges
    end

    local _All = function()
        -- helper class to provide a special mapping on this machine which can store a state that can be reached from any other registered state with a given keyword
        local all = {}

        -- private state for DialogEngine.all
        local _edges = _EdgeMap()
        local _registered = {}

        all._has_next = function(state)
            --[[
                REQUIRED state - a DialogEngine state to check for outgoing edges in all

                return true if this state has been registered to work with all and there are any all edges to traverse
            ]]
            return _registered[state] and not _edges.empty()
        end

        all._next = function(query, state)
            --[[
                REQUIRED query - a string input representing a state transition

                REQUIRED state - a DialogEngine to check for an out going edge in all

                return a new state connected to state via edge matched by query (see _EdgeMap.get) if one exists else nil
            ]]
            return _registered[state] and _edges.get(query) or nil
        end

        all.from = function(state)
            --[[
                REQUIRED state - a DialogEngine.State

                register state such that the machine can traverse from it to any state in all

                no return
            ]]
            _registered[state] = true
        end
        
        all.to = function(query, state)
            --[[
                REQUIRED query - a string or list of strings that should represent a valid state transition (see _EdgeMap.get)
                
                REQUIRED state - a DialogEngine.State to transition to if query is matched (see _EdgeMap.set)

                add new edges to all that points to state (one for each string given)

                no return
            ]]
            _edges.set(query, state)
        end

        all.connect = function(query, state)
            --[[
                REQUIRED query - a string or list of strings that should represent a valid state transition (see _EdgeMap.get)
                
                REQUIRED state - a DialogEngine.State to transition to if query is matched

                convenience method for both registering a state and for creating edges in all to that state

                no return
            ]]
            all.from(state)
            all.to(query, state)
        end

        return all
    end
    -- initialize this machines all
    _machine.all = _All()

    -- if greetings is a string, convert it to a list with a single element (its current value), this is a simple optimization to prevent needing to check its type on every call to on_say
    greetings = type(greetings) == "string" and {greetings} or greetings
    _machine.on_say = function(player, query)
        --[[
            REQUIRED player - the player that is querying
            REQUIRED query  - the message to process and respond to

            if this machine is in the default state, it is listening for query to be a greeting so it can transition to the first state (and call that states on_enter handler) else this machine will process query and transition to the correct state if necessary as well as call the current state's on_exit handler, and the new state's on_enter hander.

            if the current state's on_exit handler returns false, the machine will remain in it's current state

            if the machine transitions to a new state and the on_enter handler returns false, the machine will exit (see DialogEngine.exit)

            if the machines new state is a leaf node (ie a state which has no valid outgoing edges and cannot legally transition to another state) than the machine will exit (see DialogEngine.exit)
        ]]

        local _is_greet = function(query)
            --[[
                REQUIRED query - a string of player input to check if it is a valid greeting

                note: greetings are matched case insensitive but for exact wording, unlike state transitions that are checked for partial match (see _EdgeMap.get)
            ]]
            for i,greeting in ipairs(greetings) do
                if query:lower() == greeting:lower() then return true end
            end
            return false
        end

        current_state = _current_states:__get(player)

        if not current_state and _is_greet(query) then
            _current_states:__set(player, _machine[1])

            -- returning false from an on_enter handler will exit the machine
            if false == _machine[1]._on_enter(player, query) then
                _machine.exit(player, query)
            end
        elseif current_state then
            local _next = current_state._next(query) or _machine.all._next(query, current_state)

            if _next then
                -- returning false from an on_exit handler will prevent transitioning to the next state
                if false ~= current_state._on_exit(player, query) then
                    _current_states:__set(player, _next)

                    -- returning false from an on-enter handler will exit the machine
                    if false == _next._on_enter(player, query) then
                        _machine.exit(player, query)
                    end
                end
            elseif _machine.unhandled then
                _machine.unhandled(player, query)
            end
        end

        current_state = _current_states:__get(player)

        -- transitioning to a state with no valid edges leading away from it will result in the machine exiting (ie returning to default state)
        if current_state and current_state._is_leaf() and not _machine.all._has_next(current_state) then
            _machine.exit(player, query)
        end

        return _machine
    end

    _machine.State = function(responses)
        --[[
            State class is the bread and butter of creating a DialogEngine. Users are expected to construct the machine completely by creating states, connecting them, and adding them to the machine.

            OPTIONAL responses - a single response or a list of responses to use when entering this state

            if responses is a list of responses, one is taken at random for the first time entering this state and the list is cycled through for each additional time the state is entered until this machine has been exited

            For more fine grained control over a states behavior a developer can define State.on_enter (see State._on_enter) and State.on_exit (see State._on_exit).

            a response can either be a string or a list of strings to say

            DialogEngine:respond() will be called with the response
        ]]

        responses = type(responses) == "string" and {responses} or responses
        local _state = {}

        -- private state of this State object

        -- an index value into responses; keeps track of what our last response was so we can cycle the list
        local _last_response = nil
        local _edges = _EdgeMap()

        -- reset the mutable state of this object
        _state.reset = function(player)
            if player then 
                _last_response[player] = nil
                return
            end

            _last_response = {}
        end

        _state.reset()

        _state._next = function(query)
            --[[
                REQUIRED query - a string input representing a state transition

                return a new state connected to this state via edge matched by query (see _EdgeMap.get) if one exists else nil
            ]]
            return _edges.get(query)
        end

        _state._is_leaf = function()
            --[[
                return true if this state has no edges (ie cant transition to any other state)
            ]]
            return not _edges.empty()
        end

        _state._on_enter = function(player, query)
            --[[
                REQUIRED query - the string that triggered a transition to this state

                this method will trigger the NPC to respond with whatever was passed in to this state at initialization, it will then call state.on_enter passing the query along.

                if on_enter returns false, the state machine exits (ie goes back to listening for a greeting)
            ]]

            if responses and #responses > 0 then
                if not _last_response[player] then
                    _last_response[player] = math.random(1, #responses)
                end
                
                local response = responses[(_last_response[player] % #responses) + 1]
                response = type(response) == "string" and {response} or response

                _last_response[player] = _last_response[player] + 1

                _machine.respond(player, response)
            end

            if _state.on_enter then
                return _state.on_enter(player, query)
            end
        end

        _state._on_exit = function(player, query)
            --[[
                REQUIRED query - the string that triggered a transition away from this state

                this method will call state.on_exit

                if on_exit returns false, the state machine will not transition to the next state, but this does not prevent the machine from exiting 
            ]]

            if _state.on_exit then
                return _state.on_exit(player, query)
            end
        end

        _state.to = function(query, state)
            --[[
                REQUIRED query - a string or list of strings that should represent a valid state transition (see _EdgeMap.get)
                
                REQUIRED state - a DialogEngine.State to transition to if query is matched (see _EdgeMap.set)

                add new edges to all that points to state (one for each string given)

                no return
            ]]
            _edges.set(query, state)
        end

        _machine[#_machine+1] = _state
        return _state
    end

    -- set the initial state of this machine to always be the response to a greeting
    _default_state = _machine.State(responses)
    _default_state.on_enter = function(...)
        if _machine.on_enter then _machine.on_enter(...) end
    end

    _machine.all.from(_default_state)

    return _machine
end