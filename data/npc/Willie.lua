require 'data/npc/lib/NPC'

local willie = NPC({'hi','hello'}, 'Hiho |PLAYERNAME|.', 'Yeah, bye.')

function onCreatureAppear(...)      willie:onCreatureAppear(...)      end
function onCreatureDisappear(...)   willie:onCreatureDisappear(...)   end
function onCreatureSay(...)         willie:onCreatureSay(...)         end
function onThink(...)               willie:onThink(...)               end
function onCreatureMove(...)        willie:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  willie:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      willie:onPlayerEndTrade(...)      end

local engine = willie.dialogEngine

engine.all.connect('god', engine.State('I am a farmer, not a preacher.'))
engine.all.connect('help', engine.State('{Help} yourself, I have not stolen my {time}.'))
engine.all.connect('job', engine.State('I am a farmer and a {cook}.'))
engine.all.connect('cook', engine.State('I try out old and new {recipes}. You can {sell} me all {food} you have.'))
engine.all.connect('food', engine.State('Are you looking for {food}? I have bread, cheese, ham, and meat.'))
engine.all.connect('recipes', engine.State('I would love to try a {banana}-pie. But I lack the {banana}s. If you get me one, I will reward you.'))
engine.all.connect('banana', engine.State('Have you found a {banana} for me?'))
engine.all.connect('no', engine.State('Too bad.'))
engine.all.connect('name', engine.State('Willie.'))
engine.all.connect('time', engine.State('Am I a clock or what?'))
engine.all.connect('king', engine.State('I\'m glad that we don\'t see many officials here.'))
engine.all.connect('magic', engine.State('I am magician in the kitchen.'))
engine.all.connect('tibia', engine.State('If I were you, I would stay here.'))
engine.all.connect('sell', engine.State('I {sell} {food} of many kinds.'))
engine.all.connect('buy', engine.State('I {buy} {food} of any kind. Since I am a great {cook} I need much of it.'))
engine.all.connect('spell', engine.State('I know how to {spell} and i know how to spit, you little @!#&&. Wanna see?.'))
engine.all.connect('weapon', engine.State('I\'m not in the {weapon} business, but if you don\'t stop to harass me, I will put my hayfork in your &$&#$ and *$!&&*# it.'))
engine.all.connect('dungeon', engine.State('I have {no} {time} for your {dungeon} nonsense.'))
engine.all.connect('monsters', engine.State('Are you afraid of {monsters} ... you baby?'))
engine.all.connect('amber', engine.State('Quite a babe.'))
engine.all.connect('cipfried', engine.State('Our little monkey.'))
engine.all.connect('dallheim', engine.State('Uhm, fine guy I think.'))
engine.all.connect('obi', engine.State('This little $&#@& has only #@$*# in his mind. One day I will put a #@$@ in his *@&&#@!'))
engine.all.connect('seymour', engine.State('This joke of a man thinks he is sooo important.'))

engine.all.to('bye', engine.State('Yeah, bye.'))