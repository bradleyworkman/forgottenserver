require 'data/npc/lib/NPC'

local zerbrus = NPC({'hi','hello'}, {{'Greetings young traveller.'},{'Greetings young traveller.','Hm.'}}, 'Bye.')

function onCreatureAppear(...)      zerbrus:onCreatureAppear(...)      end
function onCreatureDisappear(...)   zerbrus:onCreatureDisappear(...)   end
function onCreatureSay(...)         zerbrus:onCreatureSay(...)         end
function onThink(...)               zerbrus:onThink(...)               end
function onCreatureMove(...)        zerbrus:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  zerbrus:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      zerbrus:onPlayerEndTrade(...)      end

local engine = zerbrus.dialogEngine

engine.all.connect('god', engine.State('I am a follower of {Banor}.'))
engine.all.connect('banor', engine.State('The heavenly warrior! Read books to learn about him.'))
engine.all.connect('help', engine.State('I have to stay here, sorry, but I can {heal} you if you are wounded.'))
engine.all.connect('name', engine.State('Zerbrus at your service.'))
engine.all.connect('job', engine.State('I am the bridgeguard. I defend Rookgaard against the beasts of the {wilderness} and the {dungeons}!'))
engine.all.connect('wilderness', engine.State('There are wolves, bears, snakes, deers</u>, and spiders. You can find some dungeon entrances there, too.'))
engine.all.connect('dungeons', engine.State('{Dungeons} are dangerous, be prepared.'))
engine.all.connect('time', engine.State('My duty is eternal. {Time} is of no importance.'))
engine.all.connect('king', engine.State('HAIL TO THE {KING}!'))
engine.all.connect('magic', engine.State('You will learn about {magic} soon enough.'))
engine.all.connect('tibia', engine.State('In the world of {tibia} many challanges</u> await the brave adventurers.'))
engine.all.connect('sell', engine.State('Ask the shopowners for their wares.'))
engine.all.connect('weapon', engine.State('My {weapon} is property of the royal army. Find your own one.'))
engine.all.connect('heal', engine.State('You aren\'t looking really bad. Sorry, I can\'t {help} you.'))
engine.all.connect('monsters', engine.State('I will slay all {monsters} who dare to attack this little town.'))
engine.all.connect('amber', engine.State('Shes verry</u> attractive. To bad my duty leaves me no {time} to date her.'))
engine.all.connect('dallheim', engine.State('He does a fine {job}.'))
engine.all.connect('hyacinth', engine.State('One of theese</u> reclusive druids.'))
engine.all.connect('seymour', engine.State('His {job} to teach the young heroes is important for our all survival.'))
engine.all.connect('willie', engine.State('He can swear and curse as good as the rowdyest</u> seaman I met.'))

engine.all.to('bye', engine.State('Bye.'))