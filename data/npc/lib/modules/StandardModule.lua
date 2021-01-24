if not StandardModule then
    function StandardModule()
        local _module = {}

        -- These callback function must be called with parameters.npcHandler = npcHandler in the parameters table or they will not work correctly.
        -- Notice: The members of _module have not yet been tested. If you find any bugs, please report them to me.
        -- Usage:
            -- keywordHandler:addKeyword({"offer"}, _module.say, {npcHandler = npcHandler, text = "I sell many powerful melee weapons."})
        function _module.say(cid, message, keywords, parameters, node)
            print("_module.say::cid: ", cid)

            local npcHandler = parameters.npcHandler
            if npcHandler == nil then
                error("_module.say called without any npcHandler instance.")
            end
            local onlyFocus = (parameters.onlyFocus == nil or parameters.onlyFocus == true)
            if not npcHandler:isFocused(cid) and onlyFocus then
                return false
            end

            local parseInfo = {[TAG_PLAYERNAME] = Player(cid):getName()}
            npcHandler:say(npcHandler:parseMessage(parameters.text or parameters.message, parseInfo), cid, parameters.publicize and true)
            if parameters.reset then
                npcHandler:resetNpc(cid)
            elseif parameters.moveup then
                npcHandler.keywordHandler:moveUp(cid, parameters.moveup)
            end

            return true
        end

        --Usage:
            -- local node1 = keywordHandler:addKeyword({"promot"}, _module.say, {npcHandler = npcHandler, text = "I can promote you for 20000 gold coins. Do you want me to promote you?"})
            -- node1:addChildKeyword({"yes"}, _module.promotePlayer, {npcHandler = npcHandler, cost = 20000, level = 20}, text = "Congratulations! You are now promoted.")
            -- node1:addChildKeyword({"no"}, _module.say, {npcHandler = npcHandler, text = "Allright then. Come back when you are ready."}, reset = true)
        function _module.promotePlayer(cid, message, keywords, parameters, node)
            local npcHandler = parameters.npcHandler
            if npcHandler == nil then
                error("_module.promotePlayer called without any npcHandler instance.")
            end

            if not npcHandler:isFocused(cid) then
                return false
            end

            local player = Player(cid)
            if player:isPremium() or not parameters.premium then
                local promotion = player:getVocation():getPromotion()
                if player:getStorageValue(STORAGEVALUE_PROMOTION) == 1 then
                    npcHandler:say("You are already promoted!", cid)
                elseif player:getLevel() < parameters.level then
                    npcHandler:say("I am sorry, but I can only promote you once you have reached level " .. parameters.level .. ".", cid)
                elseif not player:removeTotalMoney(parameters.cost) then
                    npcHandler:say("You do not have enough money!", cid)
                else
                    npcHandler:say(parameters.text, cid)
                    player:setVocation(promotion)
                    player:setStorageValue(STORAGEVALUE_PROMOTION, 1)
                end
            else
                npcHandler:say("You need a premium account in order to get promoted.", cid)
            end
            npcHandler:resetNpc(cid)
            return true
        end

        function _module.learnSpell(cid, message, keywords, parameters, node)
            local npcHandler = parameters.npcHandler
            if npcHandler == nil then
                error("_module.learnSpell called without any npcHandler instance.")
            end

            if not npcHandler:isFocused(cid) then
                return false
            end

            local player = Player(cid)
            if player:isPremium() or not parameters.premium then
                if player:hasLearnedSpell(parameters.spellName) then
                    npcHandler:say("You already know this spell.", cid)
                elseif not player:canLearnSpell(parameters.spellName) then
                    npcHandler:say("You cannot learn this spell.", cid)
                elseif not player:removeTotalMoney(parameters.price) then
                    npcHandler:say("You do not have enough money, this spell costs " .. parameters.price .. " gold.", cid)
                else
                    npcHandler:say("You have learned " .. parameters.spellName .. ".", cid)
                    player:learnSpell(parameters.spellName)
                end
            else
                npcHandler:say("You need a premium account in order to buy " .. parameters.spellName .. ".", cid)
            end
            npcHandler:resetNpc(cid)
            return true
        end

        function _module.bless(cid, message, keywords, parameters, node)
            local npcHandler = parameters.npcHandler
            if npcHandler == nil then
                error("_module.bless called without any npcHandler instance.")
            end

            if not npcHandler:isFocused(cid) or Game.getWorldType() == WORLD_TYPE_PVP_ENFORCED then
                return false
            end

            local player = Player(cid)
            if player:isPremium() or not parameters.premium then
                if player:hasBlessing(parameters.bless) then
                    npcHandler:say("Gods have already blessed you with this blessing!", cid)
                elseif not player:removeTotalMoney(parameters.cost) then
                    npcHandler:say("You don't have enough money for blessing.", cid)
                else
                    player:addBlessing(parameters.bless)
                    npcHandler:say("You have been blessed by one of the five gods!", cid)
                end
            else
                npcHandler:say("You need a premium account in order to be blessed.", cid)
            end
            npcHandler:resetNpc(cid)
            return true
        end

        function _module.travel(cid, message, keywords, parameters, node)
            local npcHandler = parameters.npcHandler
            if npcHandler == nil then
                error("_module.travel called without any npcHandler instance.")
            end

            if not npcHandler:isFocused(cid) then
                return false
            end

            local player = Player(cid)
            if player:isPremium() or not parameters.premium then
                if player:isPzLocked() then
                    npcHandler:say("First get rid of those blood stains! You are not going to ruin my vehicle!", cid)
                elseif parameters.level and player:getLevel() < parameters.level then
                    npcHandler:say("You must reach level " .. parameters.level .. " before I can let you go there.", cid)
                elseif not player:removeTotalMoney(parameters.cost) then
                    npcHandler:say("You don't have enough money.", cid)
                else
                    npcHandler:say(parameters.msg or "Set the sails!", cid)
                    npcHandler:releaseFocus(cid)

                    local destination = Position(parameters.destination)
                    local position = player:getPosition()
                    player:teleportTo(destination)

                    position:sendMagicEffect(CONST_ME_TELEPORT)
                    destination:sendMagicEffect(CONST_ME_TELEPORT)
                end
            else
                npcHandler:say("I'm sorry, but you need a premium account in order to travel onboard our ships.", cid)
            end
            npcHandler:resetNpc(cid)
            return true
        end

        return _module
    end
    
end