if not TravelModule then
    function TravelModule()
        -- The word for accepting/declining an offer. CAN ONLY CONTAIN ONE FIELD! Should be a table with a single string value.
        TRAVEL_YESWORD = {"yes"}
        TRAVEL_NOWORD = {"no"}

        _module = {
            npcHandler = nil,
            destinations = nil,
            yesNode = nil,
            noNode = nil,
        }

        -- Add it to the parseable module list.
        Modules.parseableModules["module_travel"] = _module

        function _module:init(handler)
            self.npcHandler = handler
            self.yesNode = KeywordNode:new(TRAVEL_YESWORD, _module.onConfirm, {module = self})
            self.noNode = KeywordNode:new(TRAVEL_NOWORD, _module.onDecline, {module = self})
            self.destinations = {}
            return true
        end

        -- Parses all known parameters.
        function _module:parseParameters()
            local ret = NpcSystem.getParameter("travel_destinations")
            if ret then
                self:parseDestinations(ret)

                self.npcHandler.keywordHandler:addKeyword({"destination"}, _module.listDestinations, {module = self})
                self.npcHandler.keywordHandler:addKeyword({"where"}, _module.listDestinations, {module = self})
                self.npcHandler.keywordHandler:addKeyword({"travel"}, _module.listDestinations, {module = self})

            end
        end

        function _module:parseDestinations(data)
            for destination in string.gmatch(data, "[^;]+") do
                local i = 1

                local name = nil
                local x = nil
                local y = nil
                local z = nil
                local cost = nil
                local premium = false

                for temp in string.gmatch(destination, "[^,]+") do
                    if i == 1 then
                        name = temp
                    elseif i == 2 then
                        x = tonumber(temp)
                    elseif i == 3 then
                        y = tonumber(temp)
                    elseif i == 4 then
                        z = tonumber(temp)
                    elseif i == 5 then
                        cost = tonumber(temp)
                    elseif i == 6 then
                        premium = temp == "true"
                    else
                        print("[Warning : " .. Npc():getName() .. "] NpcSystem:", "Unknown parameter found in travel destination parameter.", temp, destination)
                    end
                    i = i + 1
                end

                if name and x and y and z and cost then
                    self:addDestination(name, {x=x, y=y, z=z}, cost, premium)
                else
                    print("[Warning : " .. Npc():getName() .. "] NpcSystem:", "Parameter(s) missing for travel destination:", name, x, y, z, cost, premium)
                end
            end
        end

        function _module:addDestination(name, position, price, premium)
            self.destinations[#self.destinations + 1] = name

            local parameters = {
                cost = price,
                destination = position,
                premium = premium,
                module = self
            }
            local keywords = {}
            keywords[#keywords + 1] = name

            local keywords2 = {}
            keywords2[#keywords2 + 1] = "bring me to " .. name
            local node = self.npcHandler.keywordHandler:addKeyword(keywords, _module.travel, parameters)
            self.npcHandler.keywordHandler:addKeyword(keywords2, _module.bringMeTo, parameters)
            node:addChildKeywordNode(self.yesNode)
            node:addChildKeywordNode(self.noNode)

            if npcs_loaded_travel[getNpcCid()] == nil then
                npcs_loaded_travel[getNpcCid()] = getNpcCid()
                self.npcHandler.keywordHandler:addKeyword({'yes'}, _module.onConfirm, {module = self})
                self.npcHandler.keywordHandler:addKeyword({'no'}, _module.onDecline, {module = self})
            end
        end

        function _module.travel(cid, message, keywords, parameters, node)
            local module = parameters.module
            if not module.npcHandler:isFocused(cid) then
                return false
            end

            local npcHandler = module.npcHandler

            shop_destination[cid] = parameters.destination
            shop_cost[cid] = parameters.cost
            shop_premium[cid] = parameters.premium
            shop_npcuid[cid] = getNpcCid()

            local cost = parameters.cost
            local destination = parameters.destination
            local premium = parameters.premium

            module.npcHandler:say("Do you want to travel to " .. keywords[1] .. " for " .. cost .. " gold coins?", cid)
            return true
        end

        function _module.onConfirm(cid, message, keywords, parameters, node)
            local module = parameters.module
            if not module.npcHandler:isFocused(cid) then
                return false
            end

            if shop_npcuid[cid] ~= Npc().uid then
                return false
            end

            local npcHandler = module.npcHandler

            local cost = shop_cost[cid]
            local destination = Position(shop_destination[cid])

            local player = Player(cid)
            if player:isPremium() or not shop_premium[cid] then
                if not player:removeTotalMoney(cost) then
                    npcHandler:say("You do not have enough money!", cid)
                elseif player:isPzLocked(cid) then
                    npcHandler:say("Get out of there with this blood.", cid)
                else
                    npcHandler:say("It was a pleasure doing business with you.", cid)
                    npcHandler:releaseFocus(cid)

                    local position = player:getPosition()
                    player:teleportTo(destination)

                    position:sendMagicEffect(CONST_ME_TELEPORT)
                    destination:sendMagicEffect(CONST_ME_TELEPORT)
                end
            else
                npcHandler:say("I can only allow premium players to travel there.", cid)
            end

            npcHandler:resetNpc(cid)
            return true
        end

        -- onDecline keyword callback function. Generally called when the player sais "no" after wanting to buy an item.
        function _module.onDecline(cid, message, keywords, parameters, node)
            local module = parameters.module
            if not module.npcHandler:isFocused(cid) or shop_npcuid[cid] ~= getNpcCid() then
                return false
            end
            local parentParameters = node:getParent():getParameters()
            local parseInfo = { [TAG_PLAYERNAME] = Player(cid):getName() }
            local msg = module.npcHandler:parseMessage(module.npcHandler.messages['message_decline'], parseInfo)
            module.npcHandler:say(msg, cid)
            module.npcHandler:resetNpc(cid)
            return true
        end

        function _module.bringMeTo(cid, message, keywords, parameters, node)
            local module = parameters.module
            if not module.npcHandler:isFocused(cid) then
                return false
            end

            local cost = parameters.cost
            local destination = Position(parameters.destination)

            local player = Player(cid)
            if player:isPremium() or not parameters.premium then
                if player:removeTotalMoney(cost) then
                    local position = player:getPosition()
                    player:teleportTo(destination)

                    position:sendMagicEffect(CONST_ME_TELEPORT)
                    destination:sendMagicEffect(CONST_ME_TELEPORT)
                end
            end
            return true
        end

        function _module.listDestinations(cid, message, keywords, parameters, node)
            local module = parameters.module
            if not module.npcHandler:isFocused(cid) then
                return false
            end

            local msg = "I can bring you to "
            --local i = 1
            local maxn = #module.destinations
            for i, destination in pairs(module.destinations) do
                msg = msg .. destination
                if i == maxn - 1 then
                    msg = msg .. " and "
                elseif i == maxn then
                    msg = msg .. "."
                else
                    msg = msg .. ", "
                end
                i = i + 1
            end

            module.npcHandler:say(msg, cid)
            module.npcHandler:resetNpc(cid)
            return true
        end

        return _module
    end
end