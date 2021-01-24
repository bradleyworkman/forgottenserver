if not ShopModule then
    function ShopModule()
        shop_amount = {}
        shop_cost = {}
        shop_rlname = {}
        shop_itemid = {}
        shop_container = {}
        shop_npcuid = {}
        shop_eventtype = {}
        shop_subtype = {}
        shop_destination = {}
        shop_premium = {}

        npcs_loaded_shop = {}
        npcs_loaded_travel = {}

        -- Pattern used to get the amount of an item a player wants to buy/sell.
        PATTERN_COUNT = '%d+'

        -- The words for requesting trade window.
        SHOP_TRADEREQUEST = {"trade"}

        -- The word for accepting/declining an offer. CAN ONLY CONTAIN ONE FIELD! Should be a table with a single string value.
        SHOP_YESWORD = {"yes"}
        SHOP_NOWORD = {"no"}

        -- Pattern used to get the amount of an item a player wants to buy/sell.
        PATTERN_COUNT = "%d+"

        -- Constants used to separate buying from selling.
        SHOPMODULE_SELL_ITEM = 1
        SHOPMODULE_BUY_ITEM = 2
        SHOPMODULE_BUY_ITEM_CONTAINER = 3

        -- Constants used for shop mode. Notice: addBuyableItemContainer is working on all modes
        SHOPMODULE_MODE_TALK = 1 -- Old system used before client version 8.2: sell/buy item name
        SHOPMODULE_MODE_TRADE = 2 -- Trade window system introduced in client version 8.2
        SHOPMODULE_MODE_BOTH = 3 -- Both working at one time

        -- Used shop mode
        SHOPMODULE_MODE = SHOPMODULE_MODE_BOTH

        _module = {
            _npc_handler = nil,
            yesNode = nil,
            noNode = nil,
            noText = "",
            maxCount = 100,
            amount = 0
        }

        -- Initializes the module and associates handler to it.
        function _module:init(handler)
            self._npc_handler = handler
            self.yesNode = KeywordNode:new(SHOP_YESWORD, _module.onConfirm, {module = self})
            self.noNode = KeywordNode:new(SHOP_NOWORD, _module.onDecline, {module = self})
            self.noText = handler.messages['message_decline']

            if SHOPMODULE_MODE ~= SHOPMODULE_MODE_TALK then
                for i, word in pairs(SHOP_TRADEREQUEST) do
                    local obj = {}
                    obj[#obj + 1] = word
                    obj.callback = SHOP_TRADEREQUEST.callback or _module.messageMatcher
                    handler.keywordHandler:addKeyword(obj, _module.requestTrade, {module = self})
                end
            end

            return true
        end

        -- Parses all known parameters.
        function _module:parseParameters()
            local ret = NpcSystem.getParameter("shop_buyable")
            if ret then
                self:parseBuyable(ret)
            end

            local ret = NpcSystem.getParameter("shop_sellable")
            if ret then
                self:parseSellable(ret)
            end

            local ret = NpcSystem.getParameter("shop_buyable_containers")
            if ret then
                self:parseBuyableContainers(ret)
            end
        end

        -- Parse a string contaning a set of buyable items.
        function _module:parseBuyable(data)
            for item in string.gmatch(data, "[^;]+") do
                local i = 1

                local name = nil
                local itemid = nil
                local cost = nil
                local subType = nil
                local realName = nil

                for temp in string.gmatch(item, "[^,]+") do
                    if i == 1 then
                        name = temp
                    elseif i == 2 then
                        itemid = tonumber(temp)
                    elseif i == 3 then
                        cost = tonumber(temp)
                    elseif i == 4 then
                        subType = tonumber(temp)
                    elseif i == 5 then
                        realName = temp
                    else
                        print("[Warning : " .. Npc():getName() .. "] NpcSystem:", "Unknown parameter found in buyable items parameter.", temp, item)
                    end
                    i = i + 1
                end

                local it = ItemType(itemid)
                if subType == nil and it:getCharges() ~= 0 then
                    subType = it:getCharges()
                end

                if SHOPMODULE_MODE == SHOPMODULE_MODE_TRADE then
                    if itemid and cost then
                        if subType == nil and it:isFluidContainer() then
                            print("[Warning : " .. Npc():getName() .. "] NpcSystem:", "SubType missing for parameter item:", item)
                        else
                            self:addBuyableItem(nil, itemid, cost, subType, realName)
                        end
                    else
                        print("[Warning : " .. Npc():getName() .. "] NpcSystem:", "Parameter(s) missing for item:", itemid, cost)
                    end
                else
                    if name and itemid and cost then
                        if subType == nil and it:isFluidContainer() then
                            print("[Warning : " .. Npc():getName() .. "] NpcSystem:", "SubType missing for parameter item:", item)
                        else
                            local names = {}
                            names[#names + 1] = name
                            self:addBuyableItem(names, itemid, cost, subType, realName)
                        end
                    else
                        print("[Warning : " .. Npc():getName() .. "] NpcSystem:", "Parameter(s) missing for item:", name, itemid, cost)
                    end
                end
            end
        end

        -- Parse a string contaning a set of sellable items.
        function _module:parseSellable(data)
            for item in string.gmatch(data, "[^;]+") do
                local i = 1

                local name = nil
                local itemid = nil
                local cost = nil
                local realName = nil
                local subType = nil

                for temp in string.gmatch(item, "[^,]+") do
                    if i == 1 then
                        name = temp
                    elseif i == 2 then
                        itemid = tonumber(temp)
                    elseif i == 3 then
                        cost = tonumber(temp)
                    elseif i == 4 then
                        realName = temp
                    elseif i == 5 then
                        subType = tonumber(temp)
                    else
                        print("[Warning : " .. Npc():getName() .. "] NpcSystem:", "Unknown parameter found in sellable items parameter.", temp, item)
                    end
                    i = i + 1
                end

                if SHOPMODULE_MODE == SHOPMODULE_MODE_TRADE then
                    if itemid and cost then
                        self:addSellableItem(nil, itemid, cost, realName, subType)
                    else
                        print("[Warning : " .. Npc():getName() .. "] NpcSystem:", "Parameter(s) missing for item:", itemid, cost)
                    end
                else
                    if name and itemid and cost then
                        local names = {}
                        names[#names + 1] = name
                        self:addSellableItem(names, itemid, cost, realName, subType)
                    else
                        print("[Warning : " .. Npc():getName() .. "] NpcSystem:", "Parameter(s) missing for item:", name, itemid, cost)
                    end
                end
            end
        end

        -- Parse a string contaning a set of buyable items.
        function _module:parseBuyableContainers(data)
            for item in string.gmatch(data, "[^;]+") do
                local i = 1

                local name = nil
                local container = nil
                local itemid = nil
                local cost = nil
                local subType = nil
                local realName = nil

                for temp in string.gmatch(item, "[^,]+") do
                    if i == 1 then
                        name = temp
                    elseif i == 2 then
                        itemid = tonumber(temp)
                    elseif i == 3 then
                        itemid = tonumber(temp)
                    elseif i == 4 then
                        cost = tonumber(temp)
                    elseif i == 5 then
                        subType = tonumber(temp)
                    elseif i == 6 then
                        realName = temp
                    else
                        print("[Warning : " .. Npc():getName() .. "] NpcSystem:", "Unknown parameter found in buyable items parameter.", temp, item)
                    end
                    i = i + 1
                end

                if name and container and itemid and cost then
                    if subType == nil and ItemType(itemid):isFluidContainer() then
                        print("[Warning : " .. Npc():getName() .. "] NpcSystem:", "SubType missing for parameter item:", item)
                    else
                        local names = {}
                        names[#names + 1] = name
                        self:addBuyableItemContainer(names, container, itemid, cost, subType, realName)
                    end
                else
                    print("[Warning : " .. Npc():getName() .. "] NpcSystem:", "Parameter(s) missing for item:", name, container, itemid, cost)
                end
            end
        end

        -- Custom message matching callback function for requesting trade messages.
        function _module.messageMatcher(keywords, message)
            for i, word in pairs(keywords) do
                if type(word) == "string" then
                    if string.find(message, word) and not string.find(message, "[%w+]" .. word) and not string.find(message, word .. "[%w+]") then
                        return true
                    end
                end
            end

            return false
        end

        -- Resets the module-specific variables.
        function _module:reset()
            self.amount = 0
        end

        -- Function used to match a number value from a string.
        function _module:getCount(message)
            local ret = 1
            local b, e = string.find(message, PATTERN_COUNT)
            if b and e then
                ret = tonumber(string.sub(message, b, e))
            end

            if ret <= 0 then
                ret = 1
            elseif ret > self.maxCount then
                ret = self.maxCount
            end

            return ret
        end

        -- Adds a new buyable item.
        --  names = A table containing one or more strings of alternative names to this item. Used only for old buy/sell system.
        --  itemid = The itemid of the buyable item
        --  cost = The price of one single item
        --  subType - The subType of each rune or fluidcontainer item. Can be left out if it is not a rune/fluidcontainer. Default value is 1.
        --  realName - The real, full name for the item. Will be used as ITEMNAME in 'message_onbuy' and 'message_onsell' if defined. Default value is nil (ItemType(itemId):getName() will be used)
        function _module:addBuyableItem(names, itemid, cost, itemSubType, realName)
            if SHOPMODULE_MODE ~= SHOPMODULE_MODE_TALK then
                if itemSubType == nil then
                    itemSubType = 1
                end

                local shopItem = self:getShopItem(itemid, itemSubType)
                if shopItem == nil then
                    self._npc_handler.shopItems[#self._npc_handler.shopItems + 1] = {id = itemid, buy = cost, sell = -1, subType = itemSubType, name = realName or ItemType(itemid):getName()}
                else
                    shopItem.buy = cost
                end
            end

            if names and SHOPMODULE_MODE ~= SHOPMODULE_MODE_TRADE then
                for i, name in pairs(names) do
                    local parameters = {
                            itemid = itemid,
                            cost = cost,
                            eventType = SHOPMODULE_BUY_ITEM,
                            module = self,
                            realName = realName or ItemType(itemid):getName(),
                            subType = itemSubType or 1
                        }

                    keywords = {}
                    keywords[#keywords + 1] = "buy"
                    keywords[#keywords + 1] = name
                    local node = self._npc_handler.keywordHandler:addKeyword(keywords, _module.tradeItem, parameters)
                    node:addChildKeywordNode(self.yesNode)
                    node:addChildKeywordNode(self.noNode)
                end
            end

            if npcs_loaded_shop[getNpcCid()] == nil then
                npcs_loaded_shop[getNpcCid()] = getNpcCid()
                self._npc_handler.keywordHandler:addKeyword({'yes'}, _module.onConfirm, {module = self})
                self._npc_handler.keywordHandler:addKeyword({'no'}, _module.onDecline, {module = self})
            end
        end

        function _module:getShopItem(itemId, itemSubType)
            if ItemType(itemId):isFluidContainer() then
                for i = 1, #self._npc_handler.shopItems do
                    local shopItem = self._npc_handler.shopItems[i]
                    if shopItem.id == itemId and shopItem.subType == itemSubType then
                        return shopItem
                    end
                end
            else
                for i = 1, #self._npc_handler.shopItems do
                    local shopItem = self._npc_handler.shopItems[i]
                    if shopItem.id == itemId then
                        return shopItem
                    end
                end
            end
            return nil
        end

        -- Adds a new buyable container of items.
        --  names = A table containing one or more strings of alternative names to this item.
        --  container = Backpack, bag or any other itemid of container where bought items will be stored
        --  itemid = The itemid of the buyable item
        --  cost = The price of one single item
        --  subType - The subType of each rune or fluidcontainer item. Can be left out if it is not a rune/fluidcontainer. Default value is 1.
        --  realName - The real, full name for the item. Will be used as ITEMNAME in 'message_onbuy' and 'message_onsell' if defined. Default value is nil (ItemType(itemId):getName() will be used)
        function _module:addBuyableItemContainer(names, container, itemid, cost, subType, realName)
            if names then
                for i, name in pairs(names) do
                    local parameters = {
                            container = container,
                            itemid = itemid,
                            cost = cost,
                            eventType = SHOPMODULE_BUY_ITEM_CONTAINER,
                            module = self,
                            realName = realName or ItemType(itemid):getName(),
                            subType = subType or 1
                        }

                    keywords = {}
                    keywords[#keywords + 1] = "buy"
                    keywords[#keywords + 1] = name
                    local node = self._npc_handler.keywordHandler:addKeyword(keywords, _module.tradeItem, parameters)
                    node:addChildKeywordNode(self.yesNode)
                    node:addChildKeywordNode(self.noNode)
                end
            end
        end

        -- Adds a new sellable item.
        --  names = A table containing one or more strings of alternative names to this item. Used only by old buy/sell system.
        --  itemid = The itemid of the sellable item
        --  cost = The price of one single item
        --  realName - The real, full name for the item. Will be used as ITEMNAME in 'message_onbuy' and 'message_onsell' if defined. Default value is nil (ItemType(itemId):getName() will be used)
        function _module:addSellableItem(names, itemid, cost, realName, itemSubType)
            if SHOPMODULE_MODE ~= SHOPMODULE_MODE_TALK then
                if itemSubType == nil then
                    itemSubType = 0
                end

                local shopItem = self:getShopItem(itemid, itemSubType)
                if shopItem == nil then
                    self._npc_handler.shopItems[#self._npc_handler.shopItems + 1] = {id = itemid, buy = -1, sell = cost, subType = itemSubType, name = realName or ItemType(itemid):getName()}
                else
                    shopItem.sell = cost
                end
            end

            if names and SHOPMODULE_MODE ~= SHOPMODULE_MODE_TRADE then
                for i, name in pairs(names) do
                    local parameters = {
                        itemid = itemid,
                        cost = cost,
                        eventType = SHOPMODULE_SELL_ITEM,
                        module = self,
                        realName = realName or ItemType(itemid):getName()
                    }

                    keywords = {}
                    keywords[#keywords + 1] = "sell"
                    keywords[#keywords + 1] = name

                    local node = self._npc_handler.keywordHandler:addKeyword(keywords, _module.tradeItem, parameters)
                    node:addChildKeywordNode(self.yesNode)
                    node:addChildKeywordNode(self.noNode)
                end
            end
        end

        -- onModuleReset callback function. Calls _module:reset()
        function _module:callbackOnModuleReset()
            self:reset()
            return true
        end

        -- Callback onBuy() function. If you wish, you can change certain Npc to use your onBuy().
        function _module:callbackOnBuy(cid, itemid, subType, amount, ignoreCap, inBackpacks)
            local shopItem = self:getShopItem(itemid, subType)
            if shopItem == nil then
                error("[_module.onBuy] shopItem == nil")
                return false
            end

            if shopItem.buy == -1 then
                error("[_module.onSell] attempt to buy a non-buyable item")
                return false
            end

            local totalCost = amount * shopItem.buy
            if inBackpacks then
                totalCost = ItemType(itemid):isStackable() and totalCost + 20 or totalCost + (math.max(1, math.floor(amount / ItemType(ITEM_BACKPACK):getCapacity())) * 20)
            end

            local player = Player(cid)
            local parseInfo = {
                [TAG_PLAYERNAME] = player:getName(),
                [TAG_ITEMCOUNT] = amount,
                [TAG_TOTALCOST] = totalCost,
                [TAG_ITEMNAME] = shopItem.name
            }

            if player:getTotalMoney() < totalCost then
                local msg = self._npc_handler.messages['message_needmoney']
                msg = self._npc_handler:parseMessage(msg, parseInfo)
                player:sendCancelMessage(msg)
                return false
            end

            local subType = shopItem.subType or 1
            local a, b = doNpcSellItem(cid, itemid, amount, subType, ignoreCap, inBackpacks, ITEM_BACKPACK)
            if a < amount then
                local msgId = 'message_needmorespace'
                if a == 0 then
                    msgId = 'message_needspace'
                end

                local msg = self._npc_handler.messages[msgId]
                parseInfo[TAG_ITEMCOUNT] = a
                msg = self._npc_handler:parseMessage(msg, parseInfo)
                player:sendCancelMessage(msg)
                self._npc_handler.talkStart[cid] = os.time()

                if a > 0 then
                    if not player:removeTotalMoney((a * shopItem.buy) + (b * 20)) then
                        return false
                    end
                    return true
                end

                return false
            else
                local msg = self._npc_handler.messages['message_bought']
                msg = self._npc_handler:parseMessage(msg, parseInfo)
                player:sendTextMessage(MESSAGE_INFO_DESCR, msg)
                if not player:removeTotalMoney(totalCost) then
                    return false
                end
                self._npc_handler.talkStart[cid] = os.time()
                return true
            end
        end

        -- Callback onSell() function. If you wish, you can change certain Npc to use your onSell().
        function _module:callbackOnSell(cid, itemid, subType, amount, ignoreEquipped, _)
            local shopItem = self:getShopItem(itemid, subType)
            if shopItem == nil then
                error("[_module.onSell] items[itemid] == nil")
                return false
            end

            if shopItem.sell == -1 then
                error("[_module.onSell] attempt to sell a non-sellable item")
                return false
            end

            local player = Player(cid)
            local parseInfo = {
                [TAG_PLAYERNAME] = player:getName(),
                [TAG_ITEMCOUNT] = amount,
                [TAG_TOTALCOST] = amount * shopItem.sell,
                [TAG_ITEMNAME] = shopItem.name
            }

            if not isItemFluidContainer(itemid) then
                subType = -1
            end

            if player:removeItem(itemid, amount, subType, ignoreEquipped) then
                local msg = self._npc_handler.messages['message_sold']
                msg = self._npc_handler:parseMessage(msg, parseInfo)
                player:sendTextMessage(MESSAGE_INFO_DESCR, msg)
                player:addMoney(amount * shopItem.sell)
                self._npc_handler.talkStart[cid] = os.time()
                return true
            else
                local msg = self._npc_handler.messages[MESSAGE_NEEDITEM]
                msg = self._npc_handler:parseMessage(msg, parseInfo)
                player:sendCancelMessage(msg)
                self._npc_handler.talkStart[cid] = os.time()
                return false
            end
        end

        -- Callback for requesting a trade window with the NPC.
        function _module.requestTrade(cid, message, keywords, parameters, node)
            local module = parameters.module
            if not module.npcHandler:isFocused(cid) then
                return false
            end

            if not module.npcHandler:onTradeRequest(cid) then
                return false
            end

            local itemWindow = {}
            for i = 1, #module.npcHandler.shopItems do
                itemWindow[#itemWindow + 1] = module.npcHandler.shopItems[i]
            end

            if itemWindow[1] == nil then
                local parseInfo = { [TAG_PLAYERNAME] = Player(cid):getName() }
                local msg = module.npcHandler:parseMessage(module._npc_handler.messages['message_noshop'], parseInfo)
                module.npcHandler:say(msg, cid)
                return true
            end

            local parseInfo = { [TAG_PLAYERNAME] = Player(cid):getName() }
            local msg = module.npcHandler:parseMessage(module._npc_handler.messages['message_sendtrade'], parseInfo)
            openShopWindow(cid, itemWindow,
                function(cid, itemid, subType, amount, ignoreCap, inBackpacks) module.npcHandler:onBuy(cid, itemid, subType, amount, ignoreCap, inBackpacks) end,
                function(cid, itemid, subType, amount, ignoreCap, inBackpacks) module.npcHandler:onSell(cid, itemid, subType, amount, ignoreCap, inBackpacks) end)
            module.npcHandler:say(msg, cid)
            return true
        end

        -- onConfirm keyword callback function. Sells/buys the actual item.
        function _module.onConfirm(cid, message, keywords, parameters, node)
            local module = parameters.module
            if not module.npcHandler:isFocused(cid) or shop_npcuid[cid] ~= getNpcCid() then
                return false
            end
            shop_npcuid[cid] = 0

            local parentParameters = node:getParent():getParameters()
            local player = Player(cid)
            local parseInfo = {
                [TAG_PLAYERNAME] = player:getName(),
                [TAG_ITEMCOUNT] = shop_amount[cid],
                [TAG_TOTALCOST] = shop_cost[cid] * shop_amount[cid],
                [TAG_ITEMNAME] = shop_rlname[cid]
            }

            if shop_eventtype[cid] == SHOPMODULE_SELL_ITEM then
                local ret = doPlayerSellItem(cid, shop_itemid[cid], shop_amount[cid], shop_cost[cid] * shop_amount[cid])
                if ret == true then
                    local msg = module._npc_handler.messages['message_onsell']
                    msg = module.npcHandler:parseMessage(msg, parseInfo)
                    module.npcHandler:say(msg, cid)
                else
                    local msg = module._npc_handler.messages['message_missingitem']
                    msg = module.npcHandler:parseMessage(msg, parseInfo)
                    module.npcHandler:say(msg, cid)
                end
            elseif shop_eventtype[cid] == SHOPMODULE_BUY_ITEM then
                local cost = shop_cost[cid] * shop_amount[cid]
                if player:getTotalMoney() < cost then
                    local msg = module._npc_handler.messages['message_missingmoney']
                    msg = module.npcHandler:parseMessage(msg, parseInfo)
                    module.npcHandler:say(msg, cid)
                    return false
                end

                local a, b = doNpcSellItem(cid, shop_itemid[cid], shop_amount[cid], shop_subtype[cid], false, false, ITEM_BACKPACK)
                if a < shop_amount[cid] then
                    local msgId = 'message_needmorespace'
                    if a == 0 then
                        msgId = 'message_needspace'
                    end

                    local msg = module._npc_handler.messages[msgId]
                    msg = module.npcHandler:parseMessage(msg, parseInfo)
                    module.npcHandler:say(msg, cid)
                    if a > 0 then
                        if not player:removeTotalMoney(a * shop_cost[cid]) then
                            return false
                        end
                        if shop_itemid[cid] == ITEM_PARCEL then
                            doNpcSellItem(cid, ITEM_LABEL, shop_amount[cid], shop_subtype[cid], true, false, ITEM_BACKPACK)
                        end
                        return true
                    end
                    return false
                else
                    local msg = module._npc_handler.messages['message_onbuy']
                    msg = module.npcHandler:parseMessage(msg, parseInfo)
                    module.npcHandler:say(msg, cid)
                    if not player:removeTotalMoney(cost) then
                        return false
                    end
                    if shop_itemid[cid] == ITEM_PARCEL then
                        doNpcSellItem(cid, ITEM_LABEL, shop_amount[cid], shop_subtype[cid], true, false, ITEM_BACKPACK)
                    end
                    return true
                end
            elseif shop_eventtype[cid] == SHOPMODULE_BUY_ITEM_CONTAINER then
                local ret = doPlayerBuyItemContainer(cid, shop_container[cid], shop_itemid[cid], shop_amount[cid], shop_cost[cid] * shop_amount[cid], shop_subtype[cid])
                if ret == true then
                    local msg = module._npc_handler.messages['message_onbuy']
                    msg = module.npcHandler:parseMessage(msg, parseInfo)
                    module.npcHandler:say(msg, cid)
                else
                    local msg = module._npc_handler.messages['message_missingmoney']
                    msg = module.npcHandler:parseMessage(msg, parseInfo)
                    module.npcHandler:say(msg, cid)
                end
            end

            module.npcHandler:resetNpc(cid)
            return true
        end

        -- onDecline keyword callback function. Generally called when the player sais "no" after wanting to buy an item.
        function _module.onDecline(cid, message, keywords, parameters, node)
            local module = parameters.module
            if not module.npcHandler:isFocused(cid) or shop_npcuid[cid] ~= getNpcCid() then
                return false
            end
            shop_npcuid[cid] = 0

            local parentParameters = node:getParent():getParameters()
            local parseInfo = {
                [TAG_PLAYERNAME] = Player(cid):getName(),
                [TAG_ITEMCOUNT] = shop_amount[cid],
                [TAG_TOTALCOST] = shop_cost[cid] * shop_amount[cid],
                [TAG_ITEMNAME] = shop_rlname[cid]
            }

            local msg = module.npcHandler:parseMessage(module.noText, parseInfo)
            module.npcHandler:say(msg, cid)
            module.npcHandler:resetNpc(cid)
            return true
        end

        -- tradeItem callback function. Makes the npc say the message defined by 'message_buy' or 'message_sell'
        function _module.tradeItem(cid, message, keywords, parameters, node)
            local module = parameters.module
            if not module.npcHandler:isFocused(cid) then
                return false
            end

            if not module.npcHandler:onTradeRequest(cid) then
                return true
            end

            local count = module:getCount(message)
            module.amount = count

            shop_amount[cid] = module.amount
            shop_cost[cid] = parameters.cost
            shop_rlname[cid] = parameters.realName
            shop_itemid[cid] = parameters.itemid
            shop_container[cid] = parameters.container
            shop_npcuid[cid] = getNpcCid()
            shop_eventtype[cid] = parameters.eventType
            shop_subtype[cid] = parameters.subType

            local parseInfo = {
                [TAG_PLAYERNAME] = Player(cid):getName(),
                [TAG_ITEMCOUNT] = shop_amount[cid],
                [TAG_TOTALCOST] = shop_cost[cid] * shop_amount[cid],
                [TAG_ITEMNAME] = shop_rlname[cid]
            }

            if shop_eventtype[cid] == SHOPMODULE_SELL_ITEM then
                local msg = module._npc_handler.messages['message_sell']
                msg = module.npcHandler:parseMessage(msg, parseInfo)
                module.npcHandler:say(msg, cid)
            elseif shop_eventtype[cid] == SHOPMODULE_BUY_ITEM then
                local msg = module._npc_handler.messages['message_buy']
                msg = module.npcHandler:parseMessage(msg, parseInfo)
                module.npcHandler:say(msg, cid)
            elseif shop_eventtype[cid] == SHOPMODULE_BUY_ITEM_CONTAINER then
                local msg = module._npc_handler.messages['message_buy']
                msg = module.npcHandler:parseMessage(msg, parseInfo)
                module.npcHandler:say(msg, cid)
            end
            return true
        end

        return _module
    end
end