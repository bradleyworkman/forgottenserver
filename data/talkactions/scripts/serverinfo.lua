function onSay(player, words, param)
    -- TODO when is this called (first login?), what do we want to say here? Did tibia have an official message?
    --[[
    TODO should this be doPlayerPopupFYI? return false or true?

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Server Info:"
					.. "\nExp rate: " .. Game.getExperienceStage(player:getLevel())
					.. "\nSkill rate: " .. configManager.getNumber(configKeys.RATE_SKILL)
					.. "\nMagic rate: " .. configManager.getNumber(configKeys.RATE_MAGIC)
					.. "\nLoot rate: " .. configManager.getNumber(configKeys.RATE_LOOT))
    ]]

	return false
end
