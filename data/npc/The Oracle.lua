require 'data/npc/lib/NPC'

local the_oracle = NPC({'hi','hello'}, '|PLAYERNAME|, ARE YOU PREPARED TO FACE YOUR DESTINY?', nil)

function onCreatureAppear(...)      the_oracle:onCreatureAppear(...)      end
function onCreatureDisappear(...)   the_oracle:onCreatureDisappear(...)   end
function onCreatureSay(...)         the_oracle:onCreatureSay(...)         end
function onThink(...)               the_oracle:onThink(...)               end
function onCreatureMove(...)        the_oracle:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  the_oracle:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      the_oracle:onPlayerEndTrade(...)      end

local engine = the_oracle.dialogEngine

engine.all.connect('yes', engine.State({{'I WILL BRING YOU TO THE ISLAND OF DESTINY AND YOU WILL BE UNABLE TO RETURN HERE! ARE YOU SURE?'},{'SO BE IT!'}}))

engine.all.to('bye', engine.State(nil))