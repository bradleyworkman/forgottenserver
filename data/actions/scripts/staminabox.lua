function onUse(cid, item, fromPosition, itemEx, toPosition)
	local cfg = {}
	cfg.refuel = 42 * 60 * 1000
	if(getPlayerStamina(cid) >= cfg.refuel) then
		doPlayerSendCancel(cid, "Your stamina is already full.")
	else
		doPlayerSetStamina(cid, cfg.refuel)
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE, "Your stamina has been refilled, please relog to activate.")
		doRemoveItem(item.uid)
	end
	return true
end
