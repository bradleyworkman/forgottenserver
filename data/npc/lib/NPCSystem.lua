-- Advanced NPC System by Jiddo
if not NPCSystem then

	--	For more information, look at the top of npchandler.lua...
	TAG_PLAYERNAME = '|PLAYERNAME|'
	TAG_ITEMCOUNT = '|ITEMCOUNT|'
	TAG_TOTALCOST = '|TOTALCOST|'
	TAG_ITEMNAME = '|ITEMNAME|'

	-- Constant strings defining the keywords to replace in the default messages.
	NPCSystem = {}

	-- Gets an npcparameter with the specified key. Returns nil if no such parameter is found.
	function NPCSystem.getParameter(key)
		local ret = getNpcParameter(tostring(key))
		if (type(ret) == 'number' and ret == 0) then
			return nil
		else
			return ret
		end
	end

	-- Loads the underlying classes of the NPCSystem.
	dofile('data/npc/lib/keywordhandler.lua')
	dofile('data/npc/lib/NPCHandler.lua')

	dofile('data/npc/lib/modules/FocusModule.lua')
	dofile('data/npc/lib/modules/KeywordModule.lua')
	dofile('data/npc/lib/modules/ShopModule.lua')
	dofile('data/npc/lib/modules/StandardModule.lua')
	dofile('data/npc/lib/modules/TravelModule.lua')
end