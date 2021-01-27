require 'data/npc/lib/NPC'

local hyacinth = NPC({'hi','hello'}, {{'Greetings, traveller |PLAYERNAME|.','May {Crunor} bless you.'},{'Greetings, traveller |PLAYERNAME|.'}}, 'May {Crunor} bless you.')

function onCreatureAppear(...)      hyacinth:onCreatureAppear(...)      end
function onCreatureDisappear(...)   hyacinth:onCreatureDisappear(...)   end
function onCreatureSay(...)         hyacinth:onCreatureSay(...)         end
function onThink(...)               hyacinth:onThink(...)               end
function onCreatureMove(...)        hyacinth:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  hyacinth:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      hyacinth:onPlayerEndTrade(...)      end

local engine = hyacinth.dialogEngine

engine.all.connect('gods', engine.State('As far as I know there is a library in the village. Teach yourself about the {gods}.'))
engine.all.connect('job', engine.State('I am a druid and healer, a follower of {Crunor}.'))
engine.all.connect('name', engine.State('I am Hyacinth.'))
engine.all.connect('time', engine.State('{Time} does not matter to me.'))
engine.all.connect('king', engine.State('I don\'t care about {king}s, queens, and the like.'))
engine.all.connect('magic', engine.State('I am one of the few {magic} users on this isle. But I sense a follower of the dark path of {magic} hiding somewhere in the depths of the {dungeon}s.'))
engine.all.connect('tibia', engine.State('It is shaped by the will of the {gods}, so we don\'t have to question it.'))
engine.all.connect('spell', engine.State('I can\'t teach you {magic}. On the mainland you will learn your {spell}s soon enough.'))
engine.all.connect('weapon', engine.State('I don\'t care much about {weapon}s.'))
engine.all.connect('dungeon', engine.State('The {dungeon}s are dangerous for unexperienced adventurers.'))
engine.all.connect('crunor', engine.State('May {Crunor} bless you and protect you on your journeys!'))
engine.all.connect('amber', engine.State('I never talked to her longer.'))
engine.all.connect('cipfried', engine.State('His healing powers equal even mine.'))
engine.all.connect('dallheim', engine.State('A man of the sword.'))
engine.all.connect('obi', engine.State('A greedy and annoying person as most people are.'))
engine.all.connect('seymour', engine.State('He has some inner devils that torture him.'))
engine.all.connect('sell', engine.State('I just {sell} some revitalizing life fluids.'))

engine.all.to('bye', engine.State('May {Crunor} bless you.'))