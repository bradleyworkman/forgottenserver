require 'data/npc/lib/NPC'

if not ItemQueue then
    function ItemQueue()
    --[[
        return a new ItemQueue object (see data/lib/datastructures::mix, data/lib/datastructures::Queue)
    ]]
        _queue = {}
   
        function _queue:count()
        --[[
            return the number of items in this ItemQueue, including children items if this is a container
        ]]

            local count = 0
            local holding_count = nil
            for _,item in ipairs(self) do
                holding_count = item.getItemHoldingCount and item:getItemHoldingCount()
                count = count + (holding_count or 1)
            end

            return count
        end

        return mix("ItemQueue", _queue, Queue())
    end
end

if not ItemFactory then
    function ItemFactory(shop_keeper, shop_item, in_containers)
    --[[
        REQUIRED {ShopKeeper} shop_keeper   - the shop_keeper we should generate Items for
        REQUIRED {ShopItem}   shop_item     - the shop item representing the Item we should generate
        OPTIONAL {bool}       in_containers - true if we should generate the Items in containers

        return a new ItemFactory object (see data/lib/datastructures::mix) for creating game items
    ]]
        _factory = mix("ItemFactory", {})

        function _factory.make(amount)
        --[[
            REQUIRED {number} amount - the number of items this factory should make

            return a new ItemQueue (see ItemQueue) that contains the requested number of items, in the shop_keepers container if in_containers is supplied
        ]]
            local items = ItemQueue()

            if ItemType(shop_item.id):isStackable() then
                if in_containers then
                    item = Game.createItem(shop_keeper.__container_id__, 1)
                    item:addItem(shop_item.id, amount)
                else
                    item = Game.createItem(shop_item.id, amount)
                end

                items.push_back(item)
            else
                for i=1,amount do
                    if in_containers then
                        item = Game.createItem(shop_keeper.__container_id__, 1)
                        for i=i,math.min(i+item:getItemHoldingCount(), amount) do
                            item:addItem(shop_item.id, shop_item.subtype)
                        end
                    else
                        item = Game.createItem(shop_item.id, shop_item.subtype)
                    end

                    items:push_back(item)
                end
            end

            return items
        end

        return _factory
    end
end

if not ShopKeeper then
    function ShopKeeper(...)
        --[[
        OPTIONAL {value} 1,...n - parameters to pass to the parent class NPC on construction (see data/npc/lib/NPC)

        return a new ShopKeeper object (see data/lib/datastructures::mix)
        ]]

        local _super = NPC(...)
        local _shop_keeper = mix("ShopKeeper",
            {
                -- TODO get this number from configuration
                __container_id__  = ITEM_BACKPACK,
                __container_cost__ = 20
            },
            _super)

        -- see data/npc/lib/NPC for why we add these tables together
        _shop_keeper.messages = _shop_keeper.messages + {
            SOLD_TOAST = "Bought |AMOUNT|x |ITEMNAME| for |COST| gold.",
            SOLD_SOME = "You do not have enough room for all items.",

            BOUGHT_TOAST = "Sold |AMOUNT|x |ITEMNAME| for |COST| gold.",

            ON_TRADE = "Of course, just browse through my wares.",
            ON_CLOSESHOP = "Thank you, come back whenever you're in need of something else."
        }

        function _shop_keeper:format(str, player, amount, shop_item, cost)
            --[[
            REQUIRED {string}   str       - a format string to substitute into
            OPTIONAL {Player}   player    - a player object to substitute values in from
            OPTIONAL {number}   amount    - the amount of items that were sold/bought
            OPTIONAL {ShopItem} shop_item - the shop item the NPC is currently selling/buying
            OPTIONAL {number}   cost      - the total cost of amount shop_items (including container cost etc.)

            return a new string such that format parameters (ex |AMOUNT|) in str have been substituted for their values
            ]]
            str = _super:format(str, player)
            str = str:gsub("|AMOUNT|", tostring(amount))
            str = str:gsub("|ITEMNAME|", shop_item and tostring(shop_item.name) or 'nil')
            str = str:gsub("|COST|", tostring(cost))

            return str
        end

        _shop_keeper.on_buy = function(player, item_ID, subtype, amount, ignore_equipped)
                --[[
                {Player}   player          - the player who clicked sell in store interface
                {uint16_t} item_ID         - the server item_ID for the item the player attempted to buy
                {int32_t}  subtype         - either the subtype of a fluid type item (ie what fluid was in the fluid container) or the stack count of the item; guaranteed to be in [1-100] if count
                {uint8_t}  amount          - total count of the number of items the player attempted to buy; guaranteed to be in [1,100]
                {bool}     ignore_equipped - true if we should only look in the players container, false if we should consider equipment

                return nil

                callback when player clicked sell in the client's store interface

                Server guarantees us the player exists, the ShopKeeper actually sells the item, and subtype is either a fluid type or a stack count
                ]]

                local _header = ("%s::on_buy:"):format(_shop_keeper:getName())

                local function _debug(...)
                    logging:debug(_header,...)
                end

                local function _error(...)
                    logging:error(_header,...)
                end

                _debug(player:getName(), item_ID, subtype, amount, ignore_equipped)

                local function _more_details(player)
                    player.ip = player:getIp()
                    player.client = player:getClient()
                    player.capacity = player:getFreeCapacity()
                end

                local _player = mix("Player", {
                    name=player:getName(),
                    id=player:getId(),
                    position=player:getPosition(),
                    account=player:getAccountId(),
                    type=player:getAccountType(),
                    money=player:getTotalMoney()
                })

                _inherit_from_userdata(_player, player)

                local shop_item = _shop_keeper:get_shop_item(_player, item_ID, subtype)

                if player:removeItem(itemid, amount, subType, ignoreEquipped) then
                    local payment = amount * shop_item.buyPrice

                    _player:sendTextMessage(MESSAGE_INFO_DESCR, _shop_keeper:format(
                        _shop_keeper.messages.BOUGHT_TOAST,
                        _player,
                        amount,
                        shop_item,
                        payment))

                    player:addMoney(payment)

                    _debug(("%s sold %dx %s"):format(player, amount, shop_item))

                else
                    -- official 8.6 client wont ever let us get here (you cant try to sell items you dont have)
                    _more_details(_player)
                    _error(("%s did not have %dx %s"):format(player, amount, shop_item))
                end
            end

        _shop_keeper.on_sell = function(player, item_ID, subtype, amount, ignore_capacity, in_containers)
                --[[
                {Player}   player          - the player who clicked buy in store interface
                {uint16_t} item_ID         - the server item_ID for the item the player attempted to buy
                {int32_t}  subtype         - either the subtype of a fluid type item (ie what fluid was in the fluid container) or the stack count of the item; guaranteed to be in [1-100] if count
                {uint8_t}  amount          - total count of the number of items the player attempted to buy; guaranteed to be in [1,100]
                {bool}     ignore_capacity - true if we should sell this item regardless of the players capacity, false if we should verify that the player has the cap to hold the items
                {bool}     in_containers   - true if the player requested the items be bought in container, else false

                return nil

                callback when player clicked buy in the client's store interface

                Server guarantees us the player exists, the ShopKeeper actually sells the item, and subtype is either a fluid type or a stack count
                ]]

                local _header = ("%s::on_sell:"):format(_shop_keeper:getName())

                local function _debug(...)
                    logging:debug(_header,...)
                end

                local function _error(...)
                    logging:error(_header,...)
                end

                _debug(player:getName(), item_ID, subtype, amount, ignore_capacity, in_containers)

                local function _more_details(player)
                    player.ip = player:getIp()
                    player.client = player:getClient()
                    player.capacity = player:getFreeCapacity()
                end

                local _player = mix("Player", {
                    name=player:getName(),
                    id=player:getId(),
                    position=player:getPosition(),
                    account=player:getAccountId(),
                    type=player:getAccountType(),
                    money=player:getTotalMoney()
                })

                _inherit_from_userdata(_player, player)

                function weigh(items)
                    return sum(map(function(item) return item:getWeight() end, items))
                end

                local shop_item = _shop_keeper:get_shop_item(_player, item_ID, subtype)

                local items = ItemFactory(_shop_keeper, shop_item, in_containers).make(amount)

                local total_cost = _shop_keeper:price(items)
                local total_weight = weigh(items)

                if _player:getTotalMoney() < total_cost then
                    -- official 8.6 client prevents this from happening
                    _more_details(_player)
                    _error(("%s did not have the money (%d) to buy %dx %s"):format(player, total_cost, amount, shop_item))
                end

                if not ignore_capacity and _player:getFreeCapacity() < total_weight then
                    -- official 8.6 client prevents this from happening
                    _more_details(_player)
                    _error(("%s did not have the capacity (%d) to carry %dx %s"):format(_player, total_weight, amount, shop_item))
                end

                while #items > 0 do
                  local item = items:pop_front()

                  if RETURNVALUE_NOERROR ~= _player:addItemEx(item, ignore_capacity) then
                    local amount_sold = amount - items:count()
                    local actual_cost = total_cost - _shop_keeper:price(items)

                    -- player does not have enough slots
                    _player:sendCancelMessage(_shop_keeper:format(
                        _shop_keeper.messages.SOLD_SOME,
                        _player,
                        amount_sold,
                        shop_item,
                        actual_cost))

                    _debug(("%s cant carry %dx %s (no more empty slots)"):format(
                        _player,
                        amount,
                        shop_item))

                    break
                  end
                end

                -- whatever is left in items is what wasnt sold
                local amount_sold = amount - items:count()
                local actual_cost = total_cost - _shop_keeper:price(items)

                if not _player:removeTotalMoney(actual_cost) then
                    _more_details(_player)
                    _error(("%s could not afford %d"):format(_player, actual_cost))
                end

                _player:sendTextMessage(MESSAGE_INFO_DESCR, _shop_keeper:format(
                    _shop_keeper.messages.SOLD_TOAST,
                    _player,
                    amount_sold,
                    shop_item,
                    actual_cost))

                _debug(("%s bought %dx %s"):format(
                    _player,
                    amount_sold,
                    shop_item))
            end

        -- TODO on reset close all shop windows for all players this NPC is engaged with

        function _shop_keeper:price(items)
            --[[
                REQUIRED {ItemQueue}|{Item} items - a list of Items to price or a single Item to price

                return a number that is the cost of the items in this queue or the cost of the single item
            ]]

            if class(items) == "ItemQueue" then
                local p = 0
                local holding_count = nil

                for _,item in ipairs(items) do
                    holding_count = item.getItemHoldingCount and item:getItemHoldingCount() or 0

                    if holding_count > 0 then
                        -- loop over all items in item
                        p = p + self.__container_cost__
                        for i = 1,holding_count do
                            p = p + self:price(item:getItem(i-1))
                        end
                    else
                        p = p + self:price(item)
                    end
                end

                return p
            end

            shop_item = self:get_shop_item(nil, items:getId(), items:getSubType())

            if not shop_item then
                logging:error(("%s::price: tried pricing an item that the NPC doesn't sell"):format(self:getName()))
            end

            return shop_item.sellPrice
        end

        function _shop_keeper:get_shop_item(player, item_ID, subtype)
            --[[
                OPTIONAL {Player} player  - the player to fetch the ShopItem for
                REQUIRED {number} item_ID - id of the ShopItem to get
                REQUIRED {number} subtype - the subtype of the ShopItem

                return ShopItem of this NPC that has the same type and subtype as requested if it exists, else nil
            ]]
            for _,item in ipairs(self:get_shop_items(player)) do
                if item.id == item_ID then
                    if not isItemFluidContainer(item_ID) or item.subtype == subtype then
                        return item
                    end
                end
            end

            return nil
        end

        function _shop_keeper:get_shop_items(player)
            --[[
            OPTIONAL {Player} player - the player which we want to fetch the shop items for

            return a list of ShopItem that should be available to this player for buy and sell

            note:
                getShopItems() returns a list of tables with the following properties

                {uint16_t}    id        - server ID of the item; default 0
                {int32_t}     subtype   - subtype of the item; default 1
                {uint32_t}    buyPrice  - the price the NPC should pay for the item; default 0
                {uint32_t}    sellPrice - the price the NPC should sell the item for; default 0
                {std::string} name      - the name the NPC should display the item to the player as; need not exist as a real item name


            Subclasses and instances should override this method and return a new list of ShopItems if they wish to affect what is sold by this NPC possibly on a per player/account basis (see Npc::getShopItems) for more details on how to accomplish this.
            ]]

            return map(function(shop_info)
                    return mix("ShopItem", shop_info)
                end, self:getShopItems())
        end

        function _shop_keeper:is_trading(player)
            --[[
                REQUIRED {Player} player - player to check the state of

                return true if and only if the current state of the player with this NPC is trading
            ]]
            return self:_is(player, "trading")
        end

        function _shop_keeper:onCreatureSay(creature, type_, message)
            --[[
            REQUIRED {Creature}     creature  - a creature that said something this NPC heard
            REQUIRED {SpeakClasses} type_     - a message type
            REQUIRED {string}       message   - a string that was said by the creature

            return nil

            standard NPC callback function; Overriding the NPC onCreatureSay to process messages while trading as well
            ]]
            _super:onCreatureSay(creature, type_, message)

            -- TODO verify that you could talk to an NPC while trading in 8.6
            if self:is_trading(creature) and isPrivateChannel(type_) then
                self.dialogEngine.on_say(creature, message)
            end
        end

        function _shop_keeper:open_shop_window(player)
            --[[
                REQUIRED {Player} player - the player to open the shop window for

                return nil

                Open the shop window on the client for this player
            ]]
            self:openShopWindow(player:getId(), self:get_shop_items(), self.on_buy, self.on_sell)
        end

        local on_trade = _shop_keeper.dialogEngine.State()
        on_trade.on_enter = function(player, query)
                --[[
                REQUIRED {Player} player - the player whose messages have triggered this state transition
                REQUIRED {string} query  - the message that triggered this state transition

                return nil
                ]]

                if not _shop_keeper:is_trading(player) then
                    selfSay(_shop_keeper.messages.ON_TRADE, player)
                    _shop_keeper:_do(player, BEGIN_TRADE)
                end
            end

        _shop_keeper.dialogEngine.all.connect("trade", on_trade)

        -- create a new NPC state for trading, add to parent classes state machine graph; notice that on_trade is a dialogEngine state and _trading is an NPC state, on_trade occurs when a player says something and _trading is a state the NPC goes into when trading
        local _trading = _shop_keeper.State('trading')
        _trading.on_enter = function(player, action)
                --[[
                REQUIRED {Player} player - the player whose actions have triggered this state transition
                REQUIRED {number} action - the action the player made to trigger this transition

                return nil
                ]]
                _shop_keeper:open_shop_window(player)
            end

        _trading.on_exit = function(player, action)
                --[[
                REQUIRED {Player} player - the player whose actions have triggered this state transition
                REQUIRED {number} action - the action the player made to trigger this transition

                return nil
                ]]
                _shop_keeper:refresh(player)
                _shop_keeper:closeShopWindow(player)

                -- TODO in 8.6 did shop keepers say bye to players?
                selfSay(_shop_keeper:format(_shop_keeper.messages.ON_CLOSESHOP, player), player)
            end

        _default = _shop_keeper._states['default']
        _engaged = _shop_keeper._states['engaged']

        _engaged:to(BEGIN_TRADE, _trading)

        _trading:to(END_TRADE, _engaged)
        _trading:to(CLOSE_CHANNEL, _default)
        _trading:to(FAREWELL, _default)
        _trading:to(TIMEOUT, _default)
        _trading:to(WALK_AWAY, _default)

        return _shop_keeper
    end
end