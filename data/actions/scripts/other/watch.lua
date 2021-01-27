function onUse(cid, item, fromPosition, itemEx, toPosition)
	doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, ("The time is %s."):format(getFormattedWorldTime()))
	return true
end
