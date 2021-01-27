require 'data/npc/lib/NPC'

local dixi = NPC({'hi','hello'}, {{'Hello, Mam. How may I {help} you, |PLAYERNAME|.'},{'Hello, Mam. How may I {help} you, |PLAYERNAME|.','Good bye.'}}, 'Good bye, Mam.')

function onCreatureAppear(...)      dixi:onCreatureAppear(...)      end
function onCreatureDisappear(...)   dixi:onCreatureDisappear(...)   end
function onCreatureSay(...)         dixi:onCreatureSay(...)         end
function onThink(...)               dixi:onThink(...)               end
function onCreatureMove(...)        dixi:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  dixi:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      dixi:onPlayerEndTrade(...)      end

local engine = dixi.dialogEngine

engine.all.connect('help', engine.State('If you need something, please let me know.'))
engine.all.connect('job', engine.State('I\'m helping my grandfather Obi with this shop. Do you want to buy or {sell} anything?'))
engine.all.connect('name', engine.State('I\'m Dixi.'))
engine.all.connect('sell', engine.State('We\'re selling many things. Please have a look at the blackboards downstairs to see a list of our inventory.'))
engine.all.connect('weapon', engine.State('We {sell} spears, rapiers, sabres, daggers, hand axes, axes, and short swords. Just tell me what you want to buy.'))
engine.all.connect('armor', engine.State('We {sell} jackets, coats, doublets, leather {armor}, and leather legs. Just tell me what you want to buy.'))
engine.all.connect('helmets', engine.State('We {sell} leather {helmets}, studded {helmets}, and chain {helmets}. Just tell me what you want to buy.'))
engine.all.connect('equipment', engine.State('We {sell} torches, bags, scrolls, shovels, picks, backpacks, sickles, scythes, ropes, fishing rods and sixpacks of worms. Just tell me what you want to buy.'))

engine.all.to('bye', engine.State('Good bye, Mam.'))