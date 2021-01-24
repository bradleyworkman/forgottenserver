<<<<<<< HEAD
local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()		npcHandler:onThink()		end


-- TODO this script is incorrect, see https://tibia.fandom.com/wiki/Al_Dee/Transcripts?oldid=367533

-- Basic Keywords
keywordHandler:addKeyword({'sell'}, StdModule.say, {npcHandler = npcHandler, text = 'Just ask me for a {trade} to see what I buy from you.'})
keywordHandler:addKeyword({'stuff'}, StdModule.say, {npcHandler = npcHandler, text = 'Just ask me for a {trade} to see my offers.'})
keywordHandler:addAliasKeyword({'wares'})

keywordHandler:addKeyword({'help'}, StdModule.say, {npcHandler = npcHandler, text = 'If you need general {equipment}, just ask me for a {trade}. I can also provide you with some general {hints} about the game.'})
keywordHandler:addAliasKeyword({'information'})

keywordHandler:addKeyword({'tools'}, StdModule.say, {npcHandler = npcHandler, text = 'As an adventurer, you should always have at least a {backpack}, a {rope}, a {shovel}, a {weapon}, an {armor} and a {shield}.'})
keywordHandler:addKeyword({'how', 'are', 'you'}, StdModule.say, {npcHandler = npcHandler, text = 'I\'m fine. I\'m so glad to have you here as my customer.'})
keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I\'m a merchant. Just ask me for a {trade} to see my offers.'})
keywordHandler:addKeyword({'name'}, StdModule.say, {npcHandler = npcHandler, text = 'My name is Al Dee, but you can call me Al. Can I interest you in a {trade}?'})
keywordHandler:addKeyword({'time'}, StdModule.say, {npcHandler = npcHandler, text = 'It\'s about |TIME|. I\'m so sorry, I have no watches to sell. Do you want to buy something else?'})
keywordHandler:addKeyword({'monsters'}, StdModule.say, {npcHandler = npcHandler, text = 'If you want to challenge monsters in the {dungeons}, you need some {weapons} and {armor} from the local {merchants}.'})
keywordHandler:addKeyword({'dungeon'}, StdModule.say, {npcHandler = npcHandler, text = 'If you want to explore the dungeons such as the {sewers}, you have to {equip} yourself with the vital stuff I am selling. It\'s {vital} in the deepest sense of the word.'})
keywordHandler:addKeyword({'sewers'}, StdModule.say, {npcHandler = npcHandler, text = 'Oh, our sewer system is very primitive - it\'s so primitive that it\'s overrun by {rats}. But the stuff I sell is safe from them. Just ask me for a {trade} to see it!'})
keywordHandler:addKeyword({'king'}, StdModule.say, {npcHandler = npcHandler, text = 'The king encouraged salesmen to travel here, but only I dared to take the risk, and a risk it was!'})
keywordHandler:addKeyword({'tibia'}, StdModule.say, {npcHandler = npcHandler, text = 'One day I will return to the continent as a rich, a very rich man!'})
keywordHandler:addKeyword({'thais'}, StdModule.say, {npcHandler = npcHandler, text = 'Thais is a crowded town.'})
keywordHandler:addKeyword({'mainland'}, StdModule.say, {npcHandler = npcHandler, text = 'Have you ever wondered what that \'main\' is people are talking about? Well, once you\'ve reached level 8, you should talk to the {oracle}. You can choose a {profession} afterwards and explore much more of Tibia.'})
keywordHandler:addKeyword({'weapon'}, StdModule.say, {npcHandler = npcHandler, text = 'Oh, I\'m sorry, but I don\'t deal with weapons. That\'s {Obi\'s} or {Lee\'Delle\'s} business. I could offer you a {pick} in exchange for a {small axe} if you should happen to own one.'})
keywordHandler:addKeyword({'armor'}, StdModule.say, {npcHandler = npcHandler, text = 'Armor and shields can be bought at {Dixi\'s} or at {Lee\'Delle\'s}. Dixi runs that shop near {Obi\'s}.'})
keywordHandler:addAliasKeyword({'shield'})

keywordHandler:addKeyword({'fishing'}, StdModule.say, {npcHandler = npcHandler, text = 'I sell fishing rods and worms if you want to fish. Simply ask me for a {trade}.'})
keywordHandler:addAliasKeyword({'cookies'})

keywordHandler:addKeyword({'food'}, StdModule.say, {npcHandler = npcHandler, text = 'Hmm, the best address to look for food might be {Willie} or {Billy}. {Norma} also has some snacks for sale.'})
keywordHandler:addKeyword({'bank'}, StdModule.say, {npcHandler = npcHandler, text = 'A bank is quite useful. You can deposit your money safely there. This way you don\'t have to carry it around with you all the time. You could also invest your money in my {wares}!'})
keywordHandler:addKeyword({'academy'}, StdModule.say, {npcHandler = npcHandler, text = 'The big building in the centre of Rookgaard. They have a library, a training centre, a {bank} and the room of the {oracle}. {Seymour} is the teacher there.'})
keywordHandler:addKeyword({'temple'}, StdModule.say, {npcHandler = npcHandler, text = 'The monk {Cipfried} takes care of our temple. He can heal you if you\'re badly injured or poisoned.'})
keywordHandler:addKeyword({'premium'}, StdModule.say, {npcHandler = npcHandler, text = 'As a premium adventurer you have many advantages. You really should check them out!'})
keywordHandler:addKeyword({'merchants'}, StdModule.say, {npcHandler = npcHandler, text = 'To view the offers of a merchant, simply talk to him or her and ask for a {trade}. They will gladly show you their offers and also the things they buy from you.'})
keywordHandler:addKeyword({'profession'}, StdModule.say, {npcHandler = npcHandler, text = 'You will learn everything you need to know about professions once you\'ve reached the {Island of Destiny}.'})
keywordHandler:addKeyword({'Island of Destiny'}, StdModule.say, {npcHandler = npcHandler, text = 'The Island of Destiny can be reached via the {oracle} once you are level 8. This trip will help you choose your {profession}!'})


-- Names
keywordHandler:addKeyword({'cipfried'}, StdModule.say, {npcHandler = npcHandler, text = 'He is just an old monk. However, he can heal you if you are badly injured or poisoned.'})
keywordHandler:addKeyword({'zirella'}, StdModule.say, {npcHandler = npcHandler, text = 'Poor old woman, her son {Tom} never visits her.'})
keywordHandler:addKeyword({'santiago'}, StdModule.say, {npcHandler = npcHandler, text = 'He dedicated his life to welcome newcomers to this island.'})
keywordHandler:addKeyword({'loui'}, StdModule.say, {npcHandler = npcHandler, text = 'No idea who that is.'})
keywordHandler:addKeyword({'paulie'}, StdModule.say, {npcHandler = npcHandler, text = 'He\'s the local {bank} clerk.'})
keywordHandler:addKeyword({'hyacinth'}, StdModule.say, {npcHandler = npcHandler, text = 'He mostly stays by himself. He\'s a hermit outside of town - good luck finding him.'})
keywordHandler:addKeyword({'dixi'}, StdModule.say, {npcHandler = npcHandler, text = 'She\'s {Obi\'s} granddaughter and deals with {armors} and {shields}. Her shop is south west of town, close to the {temple}.'})
keywordHandler:addKeyword({'obi'}, StdModule.say, {npcHandler = npcHandler, text = 'He sells {weapons}. His shop is south west of town, close to the {temple}.'})
keywordHandler:addKeyword({'lee\'delle'}, StdModule.say, {npcHandler = npcHandler, text = 'If you are a {premium} adventurer, you should check out {Lee\'Delle\'s} shop. She lives in the western part of town, just across the bridge.'})
keywordHandler:addKeyword({'tom'}, StdModule.say, {npcHandler = npcHandler, text = 'He\'s the local tanner. You could try selling fresh corpses or leather to him.'})
keywordHandler:addKeyword({'amber'}, StdModule.say, {npcHandler = npcHandler, text = 'She\'s currently recovering from her travels in the {academy}. It\'s always nice to chat with her!'})
keywordHandler:addKeyword({'oracle'}, StdModule.say, {npcHandler = npcHandler, text = 'You can find the oracle on the top floor of the {academy}, just above {Seymour}. Go there when you are level 8.'})
keywordHandler:addKeyword({'seymour'}, StdModule.say, {npcHandler = npcHandler, text = 'Seymour is a teacher running the {academy}. He has many important {information} about Tibia.'})
keywordHandler:addKeyword({'lily'}, StdModule.say, {npcHandler = npcHandler, text = 'She sells health {potions} and antidote potions. Also, she buys {blueberries} and {cookies} in case you find any.'})
keywordHandler:addKeyword({'willie'}, StdModule.say, {npcHandler = npcHandler, text = 'This is a local farmer. If you need fresh {food} to regain your health, it\'s a good place to go. However, many monsters also carry food such as meat or cheese. Or you could simply pick {blueberries}.'})
keywordHandler:addKeyword({'billy'}, StdModule.say, {npcHandler = npcHandler, text = 'This is a local farmer. If you need fresh {food} to regain your health, it\'s a good place to go. He\'s only trading with {premium} adventurers though.'})
keywordHandler:addKeyword({'norma'}, StdModule.say, {npcHandler = npcHandler, text = 'She used to sell equipment, but I think she has opened a small bar now. Talks about changing her name to \'Mary\' and such, strange girl.'})
keywordHandler:addKeyword({'zerbrus'}, StdModule.say, {npcHandler = npcHandler, text = 'Some call him a hero. He protects the town from {monsters}.'})
keywordHandler:addAliasKeyword({'dallheim'})

-- Pick quest
local pickKeyword = keywordHandler:addKeyword({'pick'}, StdModule.say, {npcHandler = npcHandler, text = 'Picks are hard to come by. I trade them only in exchange for high quality small axes. Would you like to make that deal?'})
	pickKeyword:addChildKeyword({'yes'}, StdModule.say, {npcHandler = npcHandler, text = 'Splendid! Here, take your pick.', reset = true},
		function(player) return player:getItemCount(2559) > 0 end,
		function(player)
			player:removeItem(2559, 1)
			player:addItem(2553, 1)
		end
	)
	-- TODO when they say No
	pickKeyword:addChildKeyword({'yes'}, StdModule.say, {npcHandler = npcHandler, text = 'Sorry, I am looking for a SMALL axe.', reset = true})
	pickKeyword:addChildKeyword({''}, StdModule.say, {npcHandler = npcHandler, text = 'Well, then don\'t.', reset = true})
keywordHandler:addAliasKeyword({'small', 'axe'})

npcHandler:setMessage(MESSAGE_WALKAWAY, 'Bye, bye.')
npcHandler:setMessage(MESSAGE_FAREWELL, 'Bye, bye |PLAYERNAME|.')
npcHandler:setMessage(MESSAGE_SENDTRADE, 'Take a look in the trade window to your left.')
npcHandler:setMessage(MESSAGE_GREET,	'Hello, hello, |PLAYERNAME|! Please come in, look, and buy! I\'m a specialist for all sorts of {tools}. Just ask me for a {trade} to see my offers! You can also ask me for general {hints} about the game. ...',
	'You can also ask me about each {citizen} of the isle.')

npcHandler:addModule(FocusModule:new())
=======
local _npc_handler = NPCHandler()

function onCreatureAppear(cid)         _npc_handler:onCreatureAppear(cid)         end
function onCreatureDisappear(cid)      _npc_handler:onCreatureDisappear(cid)      end
function onCreatureSay(cid, type, msg) _npc_handler:onCreatureSay(cid, type, msg) end
function onThink()                     _npc_handler:onThink()                     end

_npc_handler:setMessage('message_greet','Hello, hello, |PLAYERNAME|! Please come in, look, and buy! I\'m a specialist for all sorts of {tools}. Just ask me for a {trade} to see my offers! You can also ask me for general {hints} about the game.')
keywordHandler:addKeyword({'tools'} , StdModule.say , {_npc_handler = _npc_handler, text = 'As an adventurer, you should always have at least a {backpack}, a {rope}, a {shovel}, a {weapon}, an {armor} and a {shield}.'})
keywordHandler:addKeyword({'trade'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Take a look in the trade window to your right.'})
keywordHandler:addKeyword({'backpack'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Yes, I am selling that. Simply ask me for a {trade} to view all my offers.'})
keywordHandler:addAliasKeyword({'rope'})
keywordHandler:addAliasKeyword({'shovel'})
keywordHandler:addKeyword({'weapon'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Oh, I\'m sorry, but I don\'t deal with weapons. That\'s {Obi\'s} or {Lee\'Delle\'s} business. I could offer you a {pick} in exchange for a {small axe} if you should happen to own one.'})
keywordHandler:addKeyword({'armor'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Armor and shields can be bought at {Dixi\'s} or at {Lee\'Delle\'s}. Dixi runs that shop near {Obi\'s}.'})
keywordHandler:addAliasKeyword({'shield'})
keywordHandler:addKeyword({'food'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Hmm, the best address to look for food might be {Willie} or {Billy}. {Norma} also has some snacks for sale.'})
keywordHandler:addKeyword({'potions'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Sorry, I don\'t sell potions. You should visit {Lily} for that.'})
keywordHandler:addKeyword({'cookies'} , StdModule.say , {_npc_handler = _npc_handler, text = 'I sell fishing rods and worms if you want to fish. Simply ask me for a {trade}.'})
keywordHandler:addAliasKeyword({'fishing'})
keywordHandler:addKeyword({'worms'} , StdModule.say , {_npc_handler = _npc_handler, text = 'I have enough worms myself and don\'t want any more. Use them for fishing.'})
keywordHandler:addKeyword({'help'} , StdModule.say , {_npc_handler = _npc_handler, text = 'If you need general equipment, just ask me for a {trade}. I can also provide you with some general {hints} about the game.'})
keywordHandler:addAliasKeyword({'information'})
keywordHandler:addKeyword({'job'} , StdModule.say , {_npc_handler = _npc_handler, text = 'I\'m a merchant. Just ask me for a {trade} to see my offers.'})
keywordHandler:addKeyword({'name'} , StdModule.say , {_npc_handler = _npc_handler, text = 'My name is Al Dee, but you can call me Al. Can I interest you in a {trade}?'})
keywordHandler:addKeyword({'time'} , StdModule.say , {_npc_handler = _npc_handler, text = 'It\'s about 0:00 am. I\'m so sorry, I have no watches to sell. Do you want to buy something else?'})
keywordHandler:addKeyword({'premium'} , StdModule.say , {_npc_handler = _npc_handler, text = 'As a premium adventurer you have many advantages. You really should check them out!'})
keywordHandler:addKeyword({'king'} , StdModule.say , {_npc_handler = _npc_handler, text = 'The king encouraged salesmen to travel here, but only I dared to take the risk, and a risk it was!'})
keywordHandler:addKeyword({'sell'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Just ask me for a {trade} to see what I buy from you.'})
keywordHandler:addKeyword({'wares'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Just ask me for a {trade} to see my offers.'})
keywordHandler:addAliasKeyword({'stuff'})

-- Pick quest
local pickKeyword = keywordHandler:addKeyword({'pick'}, StdModule.say, {_npc_handler = _npc_handler, text = 'Picks are hard to come by. I trade them only in exchange for high quality small axes. Would you like to make that deal?'})
    pickKeyword:addChildKeyword({'yes'}, StdModule.say, {_npc_handler = _npc_handler, text = 'Splendid! Here, take your pick.', reset = true},
        function(player) return player:getItemCount(2559) > 0 end,
        function(player)
            player:removeItem(2559, 1)
            player:addItem(2553, 1)
        end
    )
    -- TODO when they say No
    pickKeyword:addChildKeyword({'yes'}, StdModule.say, {_npc_handler = _npc_handler, text = 'Sorry, I am looking for a SMALL axe.', reset = true})
    pickKeyword:addChildKeyword({''}, StdModule.say, {_npc_handler = _npc_handler, text = 'Well, then don\'t.', reset = true})
keywordHandler:addAliasKeyword({'small', 'axe'})

keywordHandler:addKeyword({'dungeon'} , StdModule.say , {_npc_handler = _npc_handler, text = 'If you want to explore the dungeons such as the {sewers}, you have to {equip} yourself with the {vital} stuff I am selling. It\'s vital in the deepest sense of the word.'})
keywordHandler:addKeyword({'sewers'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Oh, our sewer system is very primitive - it\'s so primitive that it\'s overrun by {rats}. But the stuff I sell is safe from them. Just ask me for a {trade} to see it!'})
keywordHandler:addKeyword({'vital'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Well, vital means - necessary for you to survive!'})
keywordHandler:addKeyword({'rats'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Rats plague our {sewers}. You can sell fresh rat corpses to {Seymour} or {Tom} the tanner.'})
keywordHandler:addKeyword({'monsters'} , StdModule.say , {_npc_handler = _npc_handler, text = 'If you want to challenge monsters in the {dungeons}, you need some {weapons} and {armor} from the local {merchants}.'})
keywordHandler:addKeyword({'merchants'} , StdModule.say , {_npc_handler = _npc_handler, text = 'To view the offers of a merchant, simply talk to him or her and ask for a {trade}. They will gladly show you their offers and also the things they buy from you.'})
keywordHandler:addKeyword({'Tibia'} , StdModule.say , {_npc_handler = _npc_handler, text = 'One day I will return to the continent as a rich, a very rich man!'})
keywordHandler:addKeyword({'Rookgaard'} , StdModule.say , {_npc_handler = _npc_handler, text = 'On the island of Rookgaard you can gather important experiences to prepare yourself for {mainland}.'})
keywordHandler:addKeyword({'mainland'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Have you ever wondered what that \'main\' is people are talking about? Well, once you\'ve reached level 8, you should talk to the {oracle}. You can choose a {profession} afterwards and explore much more of Tibia.'})
keywordHandler:addKeyword({'profession'} , StdModule.say , {_npc_handler = _npc_handler, text = 'You will learn everything you need to know about professions once you\'ve reached the {Island of Destiny}.'})
keywordHandler:addKeyword({'Island','of','Destiny'} , StdModule.say , {_npc_handler = _npc_handler, text = 'The Island of Destiny can be reached via the {oracle} once you are level 8. This trip will help you choose your {profession}!'})
keywordHandler:addKeyword({'Thais'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Thais is a crowded town.'})
keywordHandler:addKeyword({'academy'} , StdModule.say , {_npc_handler = _npc_handler, text = 'The big building in the centre of Rookgaard. They have a library, a training centre, a {bank} and the room of the {oracle}. {Seymour} is the teacher there.'})
keywordHandler:addKeyword({'bank'} , StdModule.say , {_npc_handler = _npc_handler, text = 'A bank is quite useful. You can deposit your money safely there. This way you don\'t have to carry it around with you all the time. You could also invest your money in my {wares}!'})
keywordHandler:addKeyword({'oracle'} , StdModule.say , {_npc_handler = _npc_handler, text = 'You can find the oracle on the top floor of the {academy}, just above {Seymour}. Go there when you are level 8.'})
keywordHandler:addKeyword({'temple'} , StdModule.say , {_npc_handler = _npc_handler, text = 'The monk {Cipfried} takes care of our temple. He can heal you if you\'re badly injured or poisoned.'})
keywordHandler:addKeyword({'Dallheim'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Some call him a hero. He protects the town from {monsters}.'})
keywordHandler:addAliasKeyword({'Zerbrus'})
keywordHandler:addKeyword({'Amber'} , StdModule.say , {_npc_handler = _npc_handler, text = 'She\'s currently recovering from her travels in the {academy}. It\'s always nice to chat with her!'})
keywordHandler:addKeyword({'Billy'} , StdModule.say , {_npc_handler = _npc_handler, text = 'This is a local farmer. If you need fresh {food} to regain your health, it\'s a good place to go. He\'s only trading with {premium} adventurers though.'})
keywordHandler:addKeyword({'Cipfried'} , StdModule.say , {_npc_handler = _npc_handler, text = 'He is just an old monk. However, he can heal you if you are badly injured or poisoned.'})
keywordHandler:addKeyword({'Dixi'} , StdModule.say , {_npc_handler = _npc_handler, text = 'She\'s {Obi\'s} granddaughter and deals with {armors} and {shields}. Her shop is south west of town, close to the {temple}.'})
keywordHandler:addKeyword({'Hyacinth'} , StdModule.say , {_npc_handler = _npc_handler, text = 'He mostly stays by himself. He\'s a hermit outside of town - good luck finding him.'})
keywordHandler:addKeyword({'Lee\'Delle'} , StdModule.say , {_npc_handler = _npc_handler, text = 'If you are a {premium} adventurer, you should check out {Lee\'Delle\'s} shop. She lives in the western part of town, just across the bridge.'})
keywordHandler:addKeyword({'Lily'} , StdModule.say , {_npc_handler = _npc_handler, text = 'She sells health {potions} and antidote potions. Also, she buys {blueberries} and {cookies} in case you find any.'})
keywordHandler:addKeyword({'Loui'} , StdModule.say , {_npc_handler = _npc_handler, text = 'No idea who that is.'})
keywordHandler:addKeyword({'Norma'} , StdModule.say , {_npc_handler = _npc_handler, text = 'She used to sell equipment, but I think she has opened a small bar now. Talks about changing her name to \'Mary\' and such, strange girl.'})
keywordHandler:addKeyword({'Obi'} , StdModule.say , {_npc_handler = _npc_handler, text = 'He sells {weapons}. His shop is south west of town, close to the {temple}.'})
keywordHandler:addKeyword({'Paulie'} , StdModule.say , {_npc_handler = _npc_handler, text = 'He\'s the local {bank} clerk.'})
keywordHandler:addKeyword({'Santiago'} , StdModule.say , {_npc_handler = _npc_handler, text = 'He dedicated his life to welcome newcomers to this island.'})
keywordHandler:addKeyword({'Seymour'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Seymour is a teacher running the {academy}. He has many important {information} about Tibia.'})
keywordHandler:addKeyword({'Tom'} , StdModule.say , {_npc_handler = _npc_handler, text = 'He\'s the local tanner. You could try selling fresh corpses or leather to him.'})
keywordHandler:addKeyword({'Willie'} , StdModule.say , {_npc_handler = _npc_handler, text = 'This is a local farmer. If you need fresh {food} to regain your health, it\'s a good place to go. However, many monsters also carry food such as meat or cheese. Or you could simply pick {blueberries}.'})
keywordHandler:addKeyword({'Zirella'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Poor old woman, her son {Tom} never visits her.'})
keywordHandler:addKeyword({'bye'} , StdModule.say , {_npc_handler = _npc_handler, text = 'Bye, bye |PLAYERNAME|.'})

_npc_handler:setMessage('message_walkaway', 'Bye, bye.')
_npc_handler:setMessage('message_farewell', 'Bye, bye |PLAYERNAME|.')
_npc_handler:setMessage('message_sendtrade', 'Take a look in the trade window to your left.')
>>>>>>> c321e7dc (- major refactor of NPC system (not working!))
