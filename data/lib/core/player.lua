local foodCondition = Condition(CONDITION_REGENERATION, CONDITIONID_DEFAULT)

function Player.is_shocked(self)
    return self:hasCondition(CONDITION_ENERGY)
end

function Player.is_burning(self)
    return self:hasCondition(CONDITION_FIRE)
end

function Player.is_poisoned(self)
    return self:hasCondition(CONDITION_POISON)
end

function Player.heal(self, min_health, conditions, effect)
    conditions = conditions or {CONDITION_BLEEDING,CONDITION_PARALYZE,CONDITION_DRUNK,CONDITION_FREEZING,CONDITION_DAZZLED,CONDITION_CURSED}

    effect = effect or CONST_ME_MAGIC_BLUE

    for _,c in ipairs(conditions) do
        player:removeCondition(c)
    end

    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)

    if player:getHealth() < min_health then
        player:setHealth(min_health)
    end
end

function Player.feed(self, food)
	local condition = self:getCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT)
	if condition then
		condition:setTicks(condition:getTicks() + (food * 1000))
	else
		local vocation = self:getVocation()
		if not vocation then
			return nil
		end

		foodCondition:setTicks(food * 1000)
		foodCondition:setParameter(CONDITION_PARAM_HEALTHGAIN, vocation:getHealthGainAmount())
		foodCondition:setParameter(CONDITION_PARAM_HEALTHTICKS, vocation:getHealthGainTicks() * 1000)
		foodCondition:setParameter(CONDITION_PARAM_MANAGAIN, vocation:getManaGainAmount())
		foodCondition:setParameter(CONDITION_PARAM_MANATICKS, vocation:getManaGainTicks() * 1000)

		self:addCondition(foodCondition)
	end
	return true
end

function Player.getClosestFreePosition(self, position, extended)
	if self:getGroup():getAccess() and self:getAccountType() >= ACCOUNT_TYPE_GOD then
		return position
	end
	return Creature.getClosestFreePosition(self, position, extended)
end

function Player.getDepotItems(self, depotId)
	return self:getDepotChest(depotId, true):getItemHoldingCount()
end

function Player.hasFlag(self, flag)
	return self:getGroup():hasFlag(flag)
end

local lossPercent = {
	[0] = 100,
	[1] = 70,
	[2] = 45,
	[3] = 25,
	[4] = 10,
	[5] = 0
}

function Player.getLossPercent(self)
	local blessings = 0
	for i = 1, 5 do
		if self:hasBlessing(i) then
			blessings = blessings + 1
		end
	end
	return lossPercent[blessings]
end

function Player.isPremium(self)
	return self:getPremiumDays() > 0 or configManager.getBoolean(configKeys.FREE_PREMIUM)
end

function Player.sendCancelMessage(self, message)
	if type(message) == "number" then
		message = Game.getReturnMessage(message)
	end
	return self:sendTextMessage(MESSAGE_STATUS_SMALL, message)
end

function Player.isUsingOtClient(self)
	return self:getClient().os >= CLIENTOS_OTCLIENT_LINUX
end

function Player.sendExtendedOpcode(self, opcode, buffer)
	if not self:isUsingOtClient() then
		return false
	end

	local networkMessage = NetworkMessage()
	networkMessage:addByte(0x32)
	networkMessage:addByte(opcode)
	networkMessage:addString(buffer)
	networkMessage:sendToPlayer(self)
	networkMessage:delete()
	return true
end

function Player:removeTotalMoney(amount)
    local moneyCount = self:getMoney()
    local bankCount = self:getBankBalance()

    if amount > (moneyCount + bankCount) then return false end

    local message = nil

    if moneyCount > 0 then
        -- if they had money on them, remove from there first
        local r = math.min(moneyCount, amount)
        self:removeMoney(r)

        message = ("Paid %d gold from inventory"):format(r)
    end

    if amount > moneyCount then
        -- need to withdraw from bank as well
        self:setBankBalance(bankCount + moneyCount - amount)

        if  message then
            message = ("%s and "):format(message)
        else
            message = "Paid "
        end

        message = ("%s%d gold from bank account"):format(message, amount - moneyCount)
    end

    message = ("%s. Your account balance is now %d gold."):format(message, self:getBankBalance())
    self:sendTextMessage(MESSAGE_INFO_DESCR, message)
    
    return true
end

function Player:getTotalMoney()
    return self:getMoney() + self:getBankBalance()
end

APPLY_SKILL_MULTIPLIER = true
local addSkillTriesFunc = Player.addSkillTries
function Player.addSkillTries(...)
	APPLY_SKILL_MULTIPLIER = false
	local ret = addSkillTriesFunc(...)
	APPLY_SKILL_MULTIPLIER = true
	return ret
end

local addManaSpentFunc = Player.addManaSpent
function Player.addManaSpent(...)
	APPLY_SKILL_MULTIPLIER = false
	local ret = addManaSpentFunc(...)
	APPLY_SKILL_MULTIPLIER = true
	return ret
end