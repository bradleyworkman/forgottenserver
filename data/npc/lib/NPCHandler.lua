if not NPCHandler then
    function NPCHandler()
        -- Constant talkdelay behaviors.
        TALKDELAY_NONE = 0 -- No talkdelay. Npc will reply immedeatly.
        TALKDELAY_ONTHINK = 1 -- Talkdelay handled through the onThink callback function. (Default)

        -- Currently applied talkdelay behavior. TALKDELAY_ONTHINK is default.
        NPCHANDLER_TALKDELAY = TALKDELAY_ONTHINK

        _handler = {
            keywordHandler = nil,
            focuses = nil,
            talkStart = nil,
            idleTime = 120,
            talkRadius = 3,
            talkDelayTime = 1, -- Seconds to delay outgoing messages.
            talkDelay = nil,
            modules = {},
            shopItems = nil, -- They must be here since ShopModule uses 'static' functions
            eventSay = nil,
            eventDelayedSay = nil,
            topic = nil,
            messages = {
                -- These are the default replies of all npcs. They can/should be changed individually for each npc.
                'message_greet' = "Greetings, |PLAYERNAME|.",
                'message_farewell' = "Good bye, |PLAYERNAME|.",
                'message_buy' = "Do you want to buy |ITEMCOUNT| |ITEMNAME| for |TOTALCOST| gold coins?",
                'message_onbuy' = "Here you are.",
                'message_bought' = "Bought |ITEMCOUNT|x |ITEMNAME| for |TOTALCOST| gold.",
                'message_sell' = "Do you want to sell |ITEMCOUNT| |ITEMNAME| for |TOTALCOST| gold coins?",
                'message_onsell' = "Here you are, |TOTALCOST| gold.",
                'message_sold' = "Sold |ITEMCOUNT|x |ITEMNAME| for |TOTALCOST| gold.",
                'message_missingmoney' = "You don't have enough money.",
                'message_needmoremoney' = "You don't have enough money.",
                'message_missingitem' = "You don't have so many.",
                'message_needitem' = "You do not have this object.",
                'message_needspace' = "You do not have enough capacity.",
                'message_needmorespace' = "You do not have enough capacity for all items.",
                'message_walkaway' = "Good bye.",
                'message_walkaway_male' = "adios amigo.",
                'message_walkaway_female' = "adios chica",
                'message_decline' = "Then not.",
                'message_sendtrade' = "Of course, just browse through my wares.",
                'message_noshop' = "Sorry, I'm not offering anything.",
                'message_oncloseshop' = "Thank you, come back whenever you're in need of something else."
            }
        }

        _callbacks = {}
        _module_callbacks = {
            onCreatureAppear={},
            onCreatureDisappear={},
            onCreatureSay={},
            onPlayerEndTrade={},
            onPlayerCloseChannel={},
            onBuy={},
            onSell={},
            onTradeRequest={},
            onAddFocus={},
            onReleaseFocus={},
            onThink={},
            onGreet={},
            onFarewell={},
            onMessageDefault={}
        }

        -- Parses all known parameters for the npc. Also parses parseable modules.
        local _message_keys = {'message_greet','message_farewell','message_decline','message_needmorespace','message_needspace','message_sendtrade','message_noshop','message_oncloseshop','message_onbuy','message_onsell','message_missingmoney','message_needmoney','message_missingitem','message_needitem','message_walkaway','message_buy','message_sell','message_bought','message_sold'}

        function _on(t, ...)
            local callback = _callbacks[t]
            if callback == nil or callback(...) then
                for i,_module_callback in ipairs(_module_callbacks[t]) do
                    if not _module_callback(...) then
                        return false
                    end
                end
            end

            return true
        end

        local ret = NPCSystem.getParameter('idletime')
        if ret then
            _handler.idleTime = tonumber(ret)
        end

        local ret = NPCSystem.getParameter('talkradius')
        if ret then
            _handler.talkRadius = tonumber(ret)
        end

        -- set messages
        for i,key in ipairs(_message_keys) do
            _handler:setMessage(key, NPCSystem.getParameter(key))
        end

        -- Parse modules.
        for parameter, Module in pairs({"module_keywords":KeywordModule, "module_travel":TravelModule, "module_shop":ShopModule}) do
            local ret = NPCSystem.getParameter(parameter)
            if ret ~= 0 then
                local _module = Module()
                _module:init(_handler)
                _module:parseParameters()
                _handle.modules[#_handler.modules + 1] = _module

                if _module.callbackOnCreatureAppear:
                    _module_callbacks['onCreatureAppear'].insert(_module.callbackOnCreatureAppear)
                end

                if _module.callbackOnCreatureDisappear:
                    _module_callbacks['onCreatureDisappear'].insert(_module.callbackOnCreatureDisappear)
                end

                if _module.callbackOnCreatureSay:
                    _module_callbacks['onCreatureSay'].insert(_module.callbackOnCreatureSay)
                end

                if _module.callbackOnPlayerEndTrade:
                    _module_callbacks['onPlayerEndTrade'].insert(_module.callbackOnPlayerEndTrade)
                end

                if _module.callbackOnPlayerCloseChannel:
                    _module_callbacks['onPlayerCloseChannel'].insert(_module.callbackOnPlayerCloseChannel)
                end

                if _module.callbackOnBuy:
                    _module_callbacks['onBuy'].insert(_module.callbackOnBuy)
                end

                if _module.callbackOnSell:
                    _module_callbacks['onSell'].insert(_module.callbackOnSell)
                end

                if _module.callbackOnTradeRequest:
                    _module_callbacks['onTradeRequest'].insert(_module.callbackOnTradeRequest)
                end

                if _module.callbackOnAddFocus:
                    _module_callbacks['onAddFocus'].insert(_module.callbackOnAddFocus)
                end

                if _module.callbackOnReleaseFocus:
                    _module_callbacks['onReleaseFocus'].insert(_module.callbackOnReleaseFocus)
                end

                if _module.callbackOnThink:
                    _module_callbacks['onThink'].insert(_module.callbackOnThink)
                end

                if _module.callbackOnGreet:
                    _module_callbacks['onGreet'].insert(_module.callbackOnGreet)
                end

                if _module.callbackOnFarewell:
                    _module_callbacks['onFarewell'].insert(_module.callbackOnFarewell)
                end

                if _module.callbackOnMessageDefault:
                    _module_callbacks['onMessageDefault'].insert(_module.callbackOnMessageDefault)
                end

                if _module.callbackOnModuleReset:
                    _module_callbacks['onReset'].insert(_module.callbackOnModuleReset)
                end
            end
        end

        -- Re-defines the maximum idle time allowed for a player when talking to this npc.
        function _handler:setMaxIdleTime(newTime)
            self.idleTime = newTime
        end

        -- Function used to change the focus of this npc.
        function _handler:addFocus(newFocus)
            if self:isFocused(newFocus) then
                return
            end

            self.focuses[#self.focuses + 1] = newFocus
            self.topic[newFocus] = 0

            _on('onAddFocus')
            self:updateFocus()
        end

        -- Function used to verify if npc is focused to certain player
        function _handler:isFocused(focus)
            for k,v in pairs(self.focuses) do
                if v == focus then
                    return true
                end
            end
            return false
        end

        -- This function should be called on each onThink and makes sure the npc faces the player it is talking to.
        --    Should also be called whenever a new player is focused.
        function _handler:updateFocus()
            for pos, focus in pairs(self.focuses) do
                if focus then
                    doNpcSetCreatureFocus(focus)
                    return
                end
            end
            doNpcSetCreatureFocus(0)
        end

        -- Used when the npc should un-focus the player.
        function _handler:releaseFocus(focus)
            if shop_cost[focus] then
                shop_amount[focus] = nil
                shop_cost[focus] = nil
                shop_rlname[focus] = nil
                shop_itemid[focus] = nil
                shop_container[focus] = nil
                shop_npcuid[focus] = nil
                shop_eventtype[focus] = nil
                shop_subtype[focus] = nil
                shop_destination[focus] = nil
                shop_premium[focus] = nil
            end

            print("releaseFocus::self ",self)
            print("releaseFocus::self.eventDelayedSay ", self.eventDelayedSay)
            print("releaseFocus::self.eventDelayedSay[focus] ", self.eventDelayedSay[focus])

            if self.eventDelayedSay[focus] then
                self:cancelNPCTalk(self.eventDelayedSay[focus])
            end

            if not self:isFocused(focus) then
                return
            end

            local pos = nil
            for k,v in pairs(self.focuses) do
                if v == focus then
                    pos = k
                end
            end
            self.focuses[pos] = nil

            self.eventSay[focus] = nil
            self.eventDelayedSay[focus] = nil
            self.talkStart[focus] = nil
            self.topic[focus] = nil

            _on('onReleaseFocus', focus)

            if Player(focus) then
                closeShopWindow(focus) --Even if it can not exist, we need to prevent it.
                self:updateFocus()
            end
        end

        -- Changes the callback function for the given id to callback.
        function _handler:setCallback(id, callback)
            self._callbacks[id] = callback
        end

        -- Changes the default response message with the specified id to newMessage.
        function _handler:setMessage(id, newMessage)
            if id and newMessage and self.messages then
                self.messages[id] = newMessage
            end
        end

        -- Translates all message tags found in msg using parseInfo
        function _handler:parseMessage(msg, parseInfo)
            local ret = msg
            for search, replace in pairs(parseInfo) do
                ret = string.gsub(ret, search, replace)
            end
            return ret
        end

        -- Makes sure the npc un-focuses the currently focused player
        function _handler:unGreet(cid)
            if not self:isFocused(cid) then
                return
            end

            if _on('onFarewell') then
                    local msg = self.messages['message_farewell']
                    local player = Player(cid)
                    local playerName = player and player:getName() or -1
                    local parseInfo = { [TAG_PLAYERNAME] = playerName }
                    self:resetNpc(cid)
                    msg = self:parseMessage(msg, parseInfo)
                    self:say(msg, cid, true)
                    self:releaseFocus(cid)
            end
        end

        -- Greets a new player.
        function _handler:greet(cid)
            if cid ~= 0 and _on('onGreet', cid) then
                local msg = self.messages['message_greet']
                local player = Player(cid)
                local playerName = player and player:getName() or -1
                local parseInfo = { [TAG_PLAYERNAME] = playerName }
                msg = self:parseMessage(msg, parseInfo)
                self:say(msg, cid)
            end
            self:addFocus(cid)
        end

        -- Handles onCreatureAppear events. If you with to handle this yourself, please use the 'onCreatureAppear' callback.
        function _handler:onCreatureAppear(creature)
            _on('onCreatureAppear', creature:getId())

        end

        -- Handles onCreatureDisappear events. If you with to handle this yourself, please use the 'onCreatureDisappear' callback.
        function _handler:onCreatureDisappear(creature)
            local cid = creature:getId()
            if getNpcCid() == cid then
                return
            end

            if _on('onCreatureDisappear', cid) then
                if self:isFocused(cid) then
                    self:unGreet(cid)
                end
            end
        end

        -- Handles onCreatureSay events. If you with to handle this yourself, please use the 'onCreatureSay' callback.
        function _handler:onCreatureSay(creature, msgtype, msg)
            local cid = creature:getId()


            if _on('onCreatureSay', cid, msgtype, msg) and self:isInRange(cid) then
                if self.keywordHandler and (self:isFocused(cid) and msgtype == TALKTYPE_PRIVATE_PN or not self:isFocused(cid)) then
                    if not self.keywordHandler:processMessage(cid, msg) then
                        callback = _callbacks['onMessageDefault']
                        ret = callback and callback()

                        self.talkStart[cid] = os.time()
                    end
                end
        end

        -- Handles onPlayerEndTrade events. If you wish to handle this yourself, use the 'onPlayerEndTrade' callback.
        function _handler:onPlayerEndTrade(creature)
            local cid = creature:getId()
            if _on('onPlayerEndTrade', cid, msgtype, msg) and self:isFocused(cid) then
                local player = Player(cid)
                local playerName = player and player:getName() or -1
                local parseInfo = { [TAG_PLAYERNAME] = playerName }
                local msg = self:parseMessage(self.messages['message_oncloseshop'], parseInfo)
                self:say(msg, cid)
            end
        end

        -- Handles onPlayerCloseChannel events. If you wish to handle this yourself, use the 'onPlayerCloseChannel' callback.
        function _handler:onPlayerCloseChannel(creature)
            local cid = creature:getId()

            if _on('onPlayerCloseChannel') then
                if self:isFocused(cid) then
                    self:unGreet(cid)
                end
            end
        end

        -- Handles onBuy events. If you wish to handle this yourself, use the 'onBuy' callback.
        function _handler:onBuy(creature, itemid, subType, amount, ignoreCap, inBackpacks)
            _on('onBuy', creature:getId(), itemid, subType, amount, ignoreCap, inBackpacks)
        end

        -- Handles onSell events. If you wish to handle this yourself, use the 'onSell' callback.
        function _handler:onSell(creature, itemid, subType, amount, ignoreCap, inBackpacks)
            local cid = creature:getId()

            _on('onSell', cid, itemid, subType, amount, ignoreCap, inBackpacks)
        end

        -- Handles onTradeRequest events. If you wish to handle this yourself, use the 'onTradeRequest' callback.
        function _handler:onTradeRequest(cid)
            return _on('onTradeRequest', cid)
        end

        -- Handles onThink events. If you wish to handle this yourself, please use the 'onThink' callback.
        function _handler:onThink()
            local callback = _callbacks['onThink']
            if callback == nil or callback() then
                if NPCHANDLER_TALKDELAY == TALKDELAY_ONTHINK then
                    for cid, talkDelay in pairs(self.talkDelay) do
                        if talkDelay.time and talkDelay.message and os.time() >= talkDelay.time then
                            selfSay(talkDelay.message, cid, talkDelay.publicize and true or false)
                            self.talkDelay[cid] = nil
                        end
                    end
                end

                for i,_module_callback in ipairs(_module_callbacks['onThink']) do
                    if not _module_callback(...) then
                        return false
                    end
                end

                for pos, focus in pairs(self.focuses) do
                    if focus then
                        if not self:isInRange(focus) then
                            self:onWalkAway(focus)
                        elseif self.talkStart[focus] and (os.time() - self.talkStart[focus]) > self.idleTime then
                            self:unGreet(focus)
                        else
                            self:updateFocus()
                        end
                    end
                end
            end
        end

        -- Tries to greet the player with the given cid.
        function _handler:onGreet(cid)
            if self:isInRange(cid) then
                if not self:isFocused(cid) then
                    self:greet(cid)
                    return
                end
            end
        end

        -- Simply calls the underlying unGreet function.
        function _handler:onFarewell(cid)
            self:unGreet(cid)
        end

        -- Should be called on this npc's focus if the distance to focus is greater then talkRadius.
        function _handler:onWalkAway(cid)
            if self:isFocused(cid) and _on('onCreatureDisappear', cid) then
                local msg = self.messages['message_walkaway']

                local player = Player(cid)
                local playerName = player and player:getName() or -1
                local playerSex = player and player:getSex() or 0

                local parseInfo = { [TAG_PLAYERNAME] = playerName }
                local message = self:parseMessage(msg, parseInfo)

                local msg_male = self.messages['message_walkaway_male']
                local message_male = self:parseMessage(msg_male, parseInfo)
                local msg_female = self.messages['message_walkaway_female']
                local message_female = self:parseMessage(msg_female, parseInfo)

                if message_female ~= message_male then
                    if playerSex == PLAYERSEX_FEMALE then
                        selfSay(message_female)
                    else
                        selfSay(message_male)
                    end
                elseif message ~= "" then
                    selfSay(message)
                end

                self:resetNpc(cid)
                self:releaseFocus(cid)
            end
        end

        -- Returns true if cid is within the talkRadius of this npc.
        function _handler:isInRange(cid)
            local distance = Player(cid) and getDistanceTo(cid) or -1
            if distance == -1 then
                return false
            end

            return distance <= self.talkRadius
        end

        -- Resets the npc into its initial state (in regard of the keywordhandler).
        --    All modules are also receiving a reset call through their callbackOnModuleReset function.
        function _handler:resetNpc(cid)
            for i,_reset in ipairs(_module_callbacks['onReset']) do
                _reset()
            end
        end

        function _handler:cancelNPCTalk(events)
            for aux = 1, #events do
                stopEvent(events[aux].event)
            end
            events = nil
        end

        function _handler:doNPCTalkALot(msgs, interval, playerID, publicize, callback)
            local ret = {}
            local npcID = getNpcCid()

            if self.eventDelayedSay[playerID] then
                self:cancelNPCTalk(self.eventDelayedSay[playerID])
            end

            self.eventDelayedSay[playerID] = {}

            for aux = 1, #msgs do
                self.eventDelayedSay[playerID][aux] = {}
                doCreatureSayWithDelay(npcID, msgs[aux], publicize and TALKTYPE_SAY or TALKTYPE_PRIVATE_NP, ((aux-1) * (interval or 4000)) + 700, self.eventDelayedSay[playerID][aux], playerID)
                ret[#ret + 1] = self.eventDelayedSay[playerID][aux]
            end

            if callback then
                addEvent(callback, ((#msgs) * (interval or 4000)) + 700, npcID, playerID)
            end

            return(ret)
        end

        -- Makes the npc represented by this instance of _handler say something.
        --    This implements the currently set type of talkdelay.
        --    shallDelay is a boolean value. If it is false, the message is not delayed. Default value is true.
        function _handler:say(message, playerID, publicize, shallDelay, delay, callback)
            local delay = delay or (self.talkDelayTime * 1000)
            local publicize = publicize and true or false
            local shallDelay = not shallDelay and true or shallDelay

            if type(message) == "table" then
                return self:doNPCTalkALot(message, delay, playerID, publicize, callback)
            end

            if self.eventDelayedSay[playerID] then
                self:cancelNPCTalk(self.eventDelayedSay[playerID])
            end

            if NPCHANDLER_TALKDELAY == TALKDELAY_NONE or shallDelay == false then
                selfSay(message, playerID, publicize and TALKTYPE_SAY or TALKTYPE_PRIVATE_NP)
                return
            end

            stopEvent(self.eventSay[playerID])
            self.eventSay[playerID] = addEvent(function(npcID)
                local npc = Npc(npcID)
                local player = Player(playerID)

                if npc and player then
                    npc:say(message, publicize and TALKTYPE_SAY or TALKTYPE_PRIVATE_NP, false, player, npc:getPosition())
                end

                if callback then
                    callback(npcID, playerID)
                end

            end, delay, getNpcCid())
        end

        return _handler
    end
end