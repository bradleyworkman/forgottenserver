require 'data/npc/lib/ShopKeeper'

local billy = ShopKeeper({'hi','hello'}, nil, 'YOU RUDE $§&$')

function onCreatureAppear(...)      billy:onCreatureAppear(...)      end
function onCreatureDisappear(...)   billy:onCreatureDisappear(...)   end
function onCreatureSay(...)         billy:onCreatureSay(...)         end
function onThink(...)               billy:onThink(...)               end
function onCreatureMove(...)        billy:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  billy:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      billy:onPlayerEndTrade(...)      end

local engine = billy.dialogEngine
local _enter = engine.on_enter
engine.on_enter = function(player, query)
    _enter(player, query)
    if player:isPremium() then
        engine.respond(player, 'Howdy |PLAYERNAME|.')
    else
        engine.respond(player, 'You did not pay your tax. Get lost!')
        return false
    end
end

engine.all.connect('god', engine.State('I am the {god} of cooking, indeed!'))
engine.all.connect('help', engine.State('Can\'t {help} you, sorry. I\'m a {cook}, not a priest.'))
engine.all.connect('job', engine.State('I am farmer and a {cook}.'))
engine.all.connect('time', engine.State('I came here to have some peace and leisure so leave me alone with \'time\'.'))
engine.all.connect('king', engine.State('The {king} and his tax collectors are far away. You\'ll meet them soon enough.'))
engine.all.connect({'spell','magic'}, engine.State('I can {spell} but know no {spell}.'))
engine.all.connect('sell', engine.State('I {sell} various kinds of {food}.'))
engine.all.connect('buy', engine.State('I {buy} {food} of most kind. Since I am a great {cook} I need much of it.'))
engine.all.connect('food', engine.State('Are you looking for {food}? I have bread, cheese, ham, and meat.'))
engine.all.connect('weapon', engine.State('Ask one of the shopkeepers. They make a fortune here with all those wannabe heroes.'))
engine.all.connect('dungeon', engine.State('You\'ll find a lot of {dungeon}s if you look around.'))
engine.all.connect('monsters', engine.State('Don\'t be afraid, in the town you should be save.'))
engine.all.connect('amber', engine.State('Shes pretty indeed! I wonder if she likes bearded men.'))
engine.all.connect('cipfried', engine.State('He never leaves this temple and only has {time} to care about those new arivals.'))
engine.all.connect('dallheim', engine.State('One of the {king}s best men, here to protect us.'))
engine.all.connect('obi', engine.State('I like him, we usualy have a drink or two once a week and share storys about {Willie}.'))
engine.all.connect('seymour', engine.State('I don\'t like his headmaster behaviour. Then again, he IS a headmaster after all.'))
engine.all.connect('willie', engine.State('Don\'t listen to that old wannabe, I\'m the best {cook} around.'))
engine.all.connect('cook', engine.State('I am the best {cook} around. You can {sell} me most types of {food}.'))

rat_state = engine.State('So you bring me a fresh {rat} for my famous stew?')

engine.all.connect({'sell rat', 'rat'}, rat_state)

rat_reward_state = engine.State()
rat_reward_state.on_enter = function(player, query)
    if player:removeItem(2813, 1) then
        engine.respond(player, 'Here you are.')
        player:addMoney(2)
    else
        engine.respond(player, 'You don\'t have one.')
    end
end
engine.all.from(rat_reward_state)

rat_state.on_exit = function(player, query, destination)
    if destination ~= rat_reward_state then
        engine.respond(player, 'Then not.')
    end
end
rat_state.to('yes', rat_reward_state)

quest_state = engine.State('Have you found a pan for me?')
engine.all.connect('pan', quest_state)

reward_state = engine.State()
engine.all.from(reward_state)
reward_state.on_enter = function(player, query)
    if player:removeItem(2563, 1) then
        player:addItem(8704, 1)
        engine.respond(player, 'A pan! At last! Take this in case you eat something my cousin has cooked.')
    else
        engine.respond(player, 'Hey! You don\'t have it!')
    end
end

quest_state.to('yes', reward_state)
quest_state.on_exit = function(player, query, destination)
    if destination ~= reward_state then
        engine.respond(player, '$&*@!')
    end
end

engine.all.to('bye', engine.State(nil))