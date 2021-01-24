local al_dee = ShopKeeper({'hi','hello'}, 'Hello, hello, |PLAYERNAME|! Please come in, look, and buy! I\'m a specialist for all sorts of {tools}. Just ask me for a {trade} to see my offers! You can also ask me for general {hints} about the game.')

function onCreatureAppear(...)      al_dee:onCreatureAppear(...)      end
function onCreatureDisappear(...)   al_dee:onCreatureDisappear(...)   end
function onCreatureSay(...)         al_dee:onCreatureSay(...)         end
function onThink(...)               al_dee:onThink(...)               end
function onCreatureMove(...)        al_dee:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  al_dee:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      al_dee:onPlayerEndTrade(...)      end

local engine = al_dee.dialogEngine

engine.all.to("bye", engine.State("good-bye |PLAYERNAME|"))