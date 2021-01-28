require 'data/npc/lib/ShopKeeper'

local lee_delle = ShopKeeper({'hi','hello'}, 'Hello, hello, |PLAYERNAME|! Please come in, look, and buy!', 'Bye, bye.')

function onCreatureAppear(...)      lee_delle:onCreatureAppear(...)      end
function onCreatureDisappear(...)   lee_delle:onCreatureDisappear(...)   end
function onCreatureSay(...)         lee_delle:onCreatureSay(...)         end
function onThink(...)               lee_delle:onThink(...)               end
function onCreatureMove(...)        lee_delle:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  lee_delle:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      lee_delle:onPlayerEndTrade(...)      end

local engine = lee_delle.dialogEngine

engine.all.connect('help', engine.State('I am already helping you by selling {stuff}.'))
engine.all.connect('stuff', engine.State('I {sell} {equipment} of all kinds. Just ask me about the type of {wares} you are interested in.'))
engine.all.connect({'wares','offer'}, engine.State('I {sell} {weapons}, {shield}s, armor, {helmets}, and {equipment}. For what do you want to ask?'))
engine.all.connect('weapons', engine.State('I {sell} spears, rapiers, sabres, daggers, hand axes, axes, and short swords. Just tell me what you want to buy.'))
engine.all.connect('shield', engine.State('I {sell} wooden {shield}s and studded {shield}s. Just tell me what you want to buy.'))
engine.all.connect('armors', engine.State('I {sell} jackets, coats, doublets, leather armor, and leather legs. Just tell me what you want to buy.'))
engine.all.connect('helmets', engine.State('I {sell} leather {helmets}, studded {helmets}, and chain {helmets}. Just tell me what you want to buy.'))
engine.all.connect('equipment', engine.State('I {sell} torches, bags, scrolls, shovels, picks, backpacks, sickles, scythes, ropes, fishing rods and sixpacks of worms. Just tell me what you want to buy.'))
engine.all.connect('job', engine.State('I am a merchant, so what can I do for you?'))
engine.all.connect('name', engine.State('My {name} is Lee\'Delle. Do you want to buy something?'))
engine.all.connect('tibia', engine.State('The continent is even more exciting than this isle!'))
engine.all.connect('sell', engine.State('I {sell} much. Have a look at the blackboards for my {wares} or just ask.'))
engine.all.connect({'flowers','mission','quest'}, engine.State('I really love {flowers}. Sadly my favourites, {honey flowers} are very rare on this isle. If you can find me one, I\'ll give you a little reward.'))
engine.all.connect('dungeon', engine.State('be carefull down there. Make sure you bought enough torches and a rope or you might get lost.'))
engine.all.connect('monsters', engine.State('There are plenty of them. Buy here the {equipment} to kill them and {sell} their loot afterwards!'))
engine.all.connect('thais', engine.State('{Thais} is the capital of the thaian empire.'))
engine.all.connect('dallheim', engine.State('He is a great warrior and our protector.'))

time_state = engine.State()
time_state.on_enter = function(player, query)
    engine.respond(player, ('It is about %s. I am so sorry, I have no watches to {sell}. Do you want to buy something else?'):format(get_world_time_for_dialog()))
end

engine.all.connect('time', time_state)

quest_state = engine.State()
quest_state.on_enter = function(player, query)
    if player:removeItem(2103, 1) then
        player:addItem(2468, 1)
        engine.respond(player, 'Oh, thank you so much! Please take this piece of armor as reward.')
    else
        engine.respond(player, '{Honey flower}s are my favourites <sigh>.')
    end
end
engine.all.connect('honey flowers', quest_state)

engine.all.to('bye', engine.State('Bye, bye.'))