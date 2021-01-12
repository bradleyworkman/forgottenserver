local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

-- OTServ event handling functions start
function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid) end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg)  npcHandler:onCreatureSay(cid, type, msg) end
function onThink()                      npcHandler:onThink() end
-- OTServ event handling functions end

function creatureSayCallback(cid, type, msg)
    -- Place all your code in here. Remember that hi, bye and all that stuff is already handled by the npcsystem, so you do not have to take care of that yourself.
    if (not npcHandler:isFocused(cid)) then
        return false
    end

 	if msgcontains(msg, "infested area") or msgcontains(msg, "demon oak") then
       npcHandler:say('How do you know? Did you go into the infested area?', cid)
       talk_state = 1
       elseif msgcontains(msg, 'yes') and talk_state == 1 then
        if getPlayerStorageValue(cid, 35735) == 1 then
                   	npcHandler:say('I have searched for dareful heroes like you. ...', cid)
                   	npcHandler:say('Take this axe and bring that damn demon oak down, report back to me when you are done. The world depends on you now, kid. ...', cid)
                    	npcHandler:say('Good luck, I mean it.', cid)
                   	doPlayerSetStorageValue(cid, 35738, 1)
                   	DoPlayerAddItem(cid, 8293, 1)
                   	talk_state = 0
                end
            else
                npcHandler:say('I won\'t discuss any further with you for now.', cid)
                talk_state = 0
            end
 	if getPlayerStorageValue(cid, 35735) == 1 and msgcontains(msg, "infested area") or msgcontains(msg, "demon oak") then
                npcHandler:say('Did you really defeat it?', cid)
                talk_state = 2
        elseif msgcontains(msg, 'yes') and talk_state == 2 then
            if getPlayerStorageValue(cid, 35700) == 1 then
              npcHandler:say('You chopped down the demon oak?!? Unbelievable!! Let\'s hope it doesn\'t come back. As long as evil is still existent in the soil of the plains, it won\'t be over. Still, the demons suffered a setback, that\'s for sure. ...', cid)
              npcHandler:say('For your brave action, I tell you a secret which has been kept for many many years. There is an old house south of the location where you found the demon oak. There should be a grave with the name \'Yesim Adeit\' somewhere close by. ...', cid)
              npcHandler:say('It belongs to a Daramian nobleman named \'Teme Saiyid\'. I knew him well and he told me -almost augured- that someone will come who is worthy to obtain his treasure. I\'m sure this \'someone\' is you. Good luck in finding it!', cid)
		doPlayerSetStorageValue(cid, 35700, 2)
                talk_state = 0
            else
                npcHandler:say('Have you entered the infested area yet?', cid)
                talk_state = 0
            end

        elseif msgcontains(msg, 'no') and (talk_state >= 1 and talk_state <= 3) then
            npcHandler:say('Bye.', cid)
            talk_state = 0
        end
    -- Place all your code in here. Remember that hi, bye and all that stuff is already handled by the npcsystem, so you do not have to take care of that yourself.
    return true
end



npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())