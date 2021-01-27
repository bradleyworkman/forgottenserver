require 'data/npc/lib/NPC'

local lily = NPC({'hi','hello'}, {{'Welcome, |PLAYERNAME|.'},{'Welcome, |PLAYERNAME|.','Take care.'}}, 'Take care.')

function onCreatureAppear(...)      lily:onCreatureAppear(...)      end
function onCreatureDisappear(...)   lily:onCreatureDisappear(...)   end
function onCreatureSay(...)         lily:onCreatureSay(...)         end
function onThink(...)               lily:onThink(...)               end
function onCreatureMove(...)        lily:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  lily:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      lily:onPlayerEndTrade(...)      end

local engine = lily.dialogEngine

engine.all.connect('help', engine.State('I can sell you an antidote rune. It\'s against the {poison} of so many dangerous {creatures}.'))
engine.all.connect({'creatures','monsters','poison'}, engine.State('Many {monsters} are poisonous. Don\'t let them bite you or you will need one of my antidote runes.'))
engine.all.connect('job', engine.State('I am a druid, bound to the spirit of nature. I\'m selling antidote runes that {help} against {poison}. Oh, and I buy blueberries, of course.'))
engine.all.connect('name', engine.State('My {name} is Lily.'))
engine.all.connect('time', engine.State('It is about 10:19 am.'))
engine.all.connect('hyacinth', engine.State('{Hyacinth} lives in the forest. He\'s never in town so I don\'t know him very well.'))

engine.all.to('bye', engine.State('Take care.'))