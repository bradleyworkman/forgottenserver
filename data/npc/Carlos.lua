require 'data/npc/lib/NPC'

local carlos = NPC({'hi','hello'}, 'Hey there,  player ! Well, that\'s how trading with NPCs like me works. I think you are ready now to cross the bridge to Rookgaard! Take care!', nil)

function onCreatureAppear(...)      carlos:onCreatureAppear(...)      end
function onCreatureDisappear(...)   carlos:onCreatureDisappear(...)   end
function onCreatureSay(...)         carlos:onCreatureSay(...)         end
function onThink(...)               carlos:onThink(...)               end
function onCreatureMove(...)        carlos:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  carlos:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      carlos:onPlayerEndTrade(...)      end

local engine = carlos.dialogEngine


engine.all.to('bye', engine.State(nil))