require 'data/npc/lib/DialogEngine'

logging.level = DEBUG

function isPrivateChannel(type_)
    return table.contains({TALKTYPE_PRIVATE_PN,TALKTYPE_PRIVATE_NP,TALKTYPE_PRIVATE}, type_)
end

function isPublicChannel(type_)
    return not isPrivateChannel(type_)
end

-- Actions that can advance an NPCs state
GREET           = 1
FAREWELL        = 2
CLOSE_CHANNEL   = 3
TIMEOUT         = 4
WALK_AWAY       = 5
BEGIN_TRADE     = 6
END_TRADE       = 7

-- TODO remove this function
function doCreatureSayWithDelay(creatureID, message, type_, delay, playerID)
    if not Player(playerID) then return nil end
    return addEvent(function(creatureID, message, type_, playerID)
            if not Player(playerID) then return end
            local creature = Creature(cid)
            creature:say(message, type_, false, playerID, creature:getPosition())
        end, delay < 1 and 1500 or delay, creatureID, message, type_, playerID)
end

if not NPC then
    function NPC(...)
        --[[
        OPTIONAL {value} 1,...n - parameters to pass to this NPC's dialogEngine (see DialogEngine)

        This function creates a new NPC object (see data/lib/datastructures::mix) and returns it. It inherits from the current npc userdata (as returned from Npc()) and includes the properties dialogEngine and messages as well as the child class State.

        NPC is a state machine that keeps track of the current state the NPC is in for each player in the area. The dialogEngine is a state machine that keeps track of the current dialog state for each player that is engaged with the NPC (not in the default state)

        This represents a very powerful model where an NPC or it's child class can create new NPC states and define behavior for entering and leaving those states. The 'default' state means the NPC is just listening for the player to engage them in dialog and it will be removed from the current states when the player disappears.
        ]]
        local _npc = mix("NPC")
        _npc.dialogEngine = DialogEngine(...)

        -- override the + operator on messages so that we can set new messages without changing the old ones; child classes can call self.messages = self.messages + {NEW_KEY="NEW VALUE"} and NEW_KEY will not override a message that already exists on NPC
        _npc.messages = setmetatable({},{
            __add = function(lhs, rhs)
                --[[
                    REQUIRED {table} lhs - left hand side of the + operator
                    REQUIRED {table} rhs - right hand side of the + operator
                
                    return a new table that contains all messages in lhs as well as any messages in rhs that did not conflict with keys in lhs
                ]]
                    if type(rhs) ~= "table" then
                        logging:error("syntax error near '+'")
                    end

                    local t = {}

                    for k,v in pairs(lhs) do t[k] = v end

                    for k,v in pairs(rhs) do
                       if not t[k] then t[k] = v end
                    end

                    return t
                end
        })

        _inherit_from_userdata(_npc, Npc())

        function _npc:format(str, player)
            --[[
            REQUIRED {string} str    - a format string to substitute into
            OPTIONAL {Player} player - a player object to substitute values in from

            return a new string such that |PLAYERNAME| has been substituted for the player name if the player exists ele nil

            TODO provide for more substitutions on player properties
            ]]
            return str:gsub("|PLAYERNAME|", player and player:getName() or 'nil')
        end

        _npc.State = function(id)
            --[[
            REQUIRED {string} id - an id for the new State object

            return a new State oject for thie NPC

            A State consists of a name and a list of edges to follow. The State can have an "on_enter" method and an "on_exit" method that will be called by the NPC when a player moves into this state or out of it by their actions (ex. when a player greets this NPC it will move into the engaged state, when they walk away it will exit the engaged state)

            The new state is inserted into the NPC's _states variable by ID so that it can be referenced from child classes
            ]]
            _state = {
                id=id,
                edges={},
            }

            function _state:_on_enter(...)
            --[[
                OPTIONAL {value} 1,...n - arguments to pass to this states on_enter callback if it exists

                return nil
            ]]
                if self.on_enter then self.on_enter(...) end
            end

            function _state:_on_exit(...)
            --[[
                OPTIONAL {value} 1,...n - arguments to pass to this states on_exit callback if it exists

                return nil
            ]]
                if self.on_exit then self.on_exit(...) end
            end

            function _state:to(action, other)
            --[[
                REQUIRED {number} action - an action that represents an edge between this state and other
                REQUIRED {state}  other  - a state to connect to this one via the edge action

                return nil

                if the NPC is current in self state with a player and the action occurs than the NPC will advance to other state, else nothing will happen

                Note a state can only move to exactly one other state given a specific action, you cannot move to multiple states from a single action (or it would become indeterminate)
            ]]
                self.edges[action] = other
            end

            _npc._states[id] = _state

            return _state
        end

        -- private state variables
        local _last_spoke = nil

        function _npc:reset(player)
            --[[
            OPTIONAL {Player} player - a player to reset this NPCs state for

            return nil

            If player is supplied, then the state of the NPC for that player is reset else the entire NPC is reset for all player states
            
            TODO clear event queue (delayed talk events)
            ]]

            if player then
                if not self:is_busy() then
                    doNpcSetCreatureFocus(0)
                end

                self.dialogEngine.exit(player)

                return
            end

            -- we're reseting ALL state of the npc
            _last_spoke = {}

            self._active_states = mix("Map<NPC.States>",{
                __set = function(self, player, state)
                    self[player:getId()] = state
                end,
                __get = function(self, player)
                    return self[player:getId()]
                end
            })
            self._states={}

            self.dialogEngine.reset()

            doNpcSetCreatureFocus(0)
        end

        -- initialize mutable private state
        _npc:reset()

        function _npc:_do(player, action)
            --[[
            REQUIRED {Player} player - a player who is performing an action on this NPC 
            REQUIRED {number} action - the action the player is performing

            return nil

            This is an internal function for advancing this NPC state machine, if the NPC is aware of the player and they have performed an action that connects another state with the current one, then we leave the current state (call on_exit) and move to the new one (call on_enter)
            ]]
            _current_state = self._active_states:__get(player)

            _next_state = _current_state.edges[action]

            if _next_state then
                _current_state:_on_exit(player, action)
                self._active_states:__set(player, _next_state)
                _next_state:_on_enter(player, action)
            end
        end

        function _npc:_is(player, name)
            --[[
            REQUIRED {Player} player - a player to check the state of
            REQUIRED {string} name   - a name of the state to check if the player is currently in

            return true if the NPC is currently in the state described by name, else false

            This is an internal function for checking a player's current state
            ]]

            local state = self._active_states:__get(player)
            return state and name == state.id
        end

        function _npc:is_busy()
            --[[
            return true if and only if this NPC is in a non-default state with any known player
            ]]

            for player,state in pairs(self._active_states) do
                if "default" ~= state.id then return true end
            end

            return false
        end

        function _npc:is_default(player)
            --[[
            REQUIRED {Player} player - a player to check if the NPC is default with

            return true if and only if the player is in the default state with this NPC
            ]]
            return self:_is(player, "default")
        end

        function _npc:is_engaged(player)
            --[[
            REQUIRED {Player} player - a player to check if the NPC is engaged with

            return true if and only if the player is in the engaged state with this NPC
            ]]
            return self:_is(player, "engaged")
        end

        function _npc:refresh(player)
            --[[
            REQUIRED {Player} player - a player to reset the timeout clock for

            return nil
            ]]
            _last_spoke[player] = now()
        end

        function _npc:is_stale(player)
            --[[
            REQUIRED {Player} player - a player to check if they should be timed out

            return true if and only if the last time this player performed an action on the NPC is less than or equal to this NPC's timeout value
            ]]

            return _last_spoke[player] and now() - _last_spoke[player] > self:getTimeout()
        end

        function _npc:onCreatureAppear(creature)
            --[[
            REQUIRED {Creature} creature - a creature that appeared to this NPC

            return nil

            standard NPC callback function; if the creature is a player, it is moved into the default state with this NPC
            ]]
            logging:debug(string.format("%s::onCreatureAppear", self:getName()), creature:getName())

            if not creature:isPlayer() then return end
            -- enter the state machine when a player appears
            self._active_states:__set(creature, _npc._states['default'])
        end

        function _npc:onCreatureDisappear(creature)
            --[[
            REQUIRED {Creature} creature - a creature that disappeared to this NPC

            return nil

            standard NPC callback function; if the creature is a player, its current state is marked for deletion
            ]]

            logging:debug(string.format("%s::onCreatureDisappear", self:getName()), creature:getName())

            if not creature:isPlayer() then return end
            -- exit the state machine and clean up when a player disappears
            self._active_states:__set(creature, nil)
            _last_spoke[creature] = nil
        end

        function _npc:get_distance(creature)
            --[[
            REQUIRED {Creature} creature - a creature to get the distance to

            return the distance in whole number of tiles between this NPC and the creature
            ]]
            return getDistanceTo(creature:getId())
        end

        function _npc:onCreatureSay(creature, type_, message)
            --[[
            REQUIRED {Creature}     creature  - a creature that said something this NPC heard
            REQUIRED {SpeakClasses} type_     - a message type
            REQUIRED {string}       message   - a string that was said by the creature

            return nil

            standard NPC callback function; will process this message with dialogEngine if appropriate (ex was said within listenRadius of this NPC etc.)
            ]]
            logging:debug(string.format("%s::onCreatureSay", self:getName()), creature:getName(), type_, message)

            if not creature:isPlayer() then return end

            if self:get_distance(creature) > self:getListenRadius() then return end

            if self:is_engaged(creature) and isPrivateChannel(type_) or self:is_default() then
                self:refresh(creature)
                self.dialogEngine.on_say(creature, message)
            end
        end

        function _npc:onThink()
            --[[
            return nil

            standard NPC callback function; will perform a TIMEOUT action if appropriate
            ]]
            for player,state in pairs(self._active_states) do
                if self:is_stale(player) then
                    self:_do(player, TIMEOUT)
                end
            end

            --[[
            if not self:is_busy() then
                -- TODO default wandering state, should we do something here? (ex talk globally, etc)
            end
            ]]
        end

        function _npc:onCreatureMove(creature, from, to)
            --[[
            REQUIRED {Creature}     creature - a creature that moved in this NPC's vicinity
            REQUIRED {Position}     from     - an {x,y,z} point the creature started on
            REQUIRED {Position}     to       - an {x,y,z} point the creature finished on

            return nil

            standard NPC callback function; will perform a WALK_AWAY action if appropriate
            ]]
            logging:debug(string.format("%s::onCreatureMove", self:getName()), creature:getName(), jsonify(from), jsonify(to))

            if not creature:isPlayer() then return end
            if self:_is(creature, 'default') then return end

            if self:get_distance(creature) > self:getListenRadius() then
                self:_do(creature, WALK_AWAY)
            end
        end

        function _npc:onPlayerCloseChannel(player)
            --[[
            REQUIRED {Player} player - the player that closed the channel

            return nil

            standard NPC callback function; advances the state of this NPC with Player with a CLOSE_CHANNEL action
            ]]
            logging:debug(string.format("%s::onPlayerCloseChannel", self:getName()), player:getName())

            self:_do(player, CLOSE_CHANNEL)
        end

        function _npc:onPlayerEndTrade(player)
            --[[
            REQUIRED {Player} player - the player that ended the trade

            return nil

            standard NPC callback function; advances the state of this NPC with Player with an END_TRADE action
            ]]
            logging:debug(string.format("%s::onPlayerEndTrade", self:getName()), player:getName())

            self:_do(player, END_TRADE)
        end

        _npc.dialogEngine.on_enter = function(player, query)
            _npc:_do(player, GREET)
        end

        _npc.dialogEngine.on_exit = function(player, query)
            _npc:_do(player, FAREWELL)
        end

        _npc.dialogEngine.respond = function(player, response)
            --[[
            REQUIRED {Player} player   - the player we are responding to
            REQUIRED {string} response - a message that this NPC should say to the player

            if a response is a single string, it is automatically said at once as soon as we enter this state in the machine (ex the map has a connection to this state via the phrase "axe", player says "axe" and we transition to this state).

            note: passing {'foo', 'bar', 'roo'} is passing a list of 3 responses to be cycled through each time this state is visited while this machine has not been exited while passing {{'foo','bar','roo'}} is passing a list with a single response that consists of saying 'foo','bar',and 'roo' in succession with delay time between them each time this state is entered.
            ]]

                -- TODO say these things w/delay (ie use an event & add to queue)
                for _,line in ipairs(response) do
                    selfSay(_npc:format(line, player), player)
                end
            end

        _default = _npc.State('default')
        _default.on_enter = function(player, action)
            --[[
                REQUIRED {Player} player - the player that is moving into the default state
                REQUIRED {number} action - the action that moved the player into the default state
            ]]
                _npc:reset(player)
            end

        _engaged = _npc.State('engaged')
        _engaged.on_enter = function(player, action)
            --[[
                REQUIRED {Player} player - the player that is moving into the engaged state
                REQUIRED {number} action - the action that moved the player into the engaged state
            ]]
                doNpcSetCreatureFocus(player:getId())
            end

        -- setup the NPC state machine graph here
        _default:to(GREET, _engaged)

        _engaged:to(CLOSE_CHANNEL, _default)
        _engaged:to(FAREWELL, _default)
        _engaged:to(TIMEOUT, _default)
        _engaged:to(WALK_AWAY, _default)

        return _npc
    end
end