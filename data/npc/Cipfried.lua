require 'data/npc/lib/NPC'

local cipfried = NPC({'hi','hello'}, 'Hello, |PLAYERNAME|! I will {heal} you if you are injured. Feel free to ask me for help.', 'Farewell, |PLAYERNAME|!')

function onCreatureAppear(...)      cipfried:onCreatureAppear(...)      end
function onCreatureDisappear(...)   cipfried:onCreatureDisappear(...)   end
function onCreatureSay(...)         cipfried:onCreatureSay(...)         end
function onThink(...)               cipfried:onThink(...)               end
function onCreatureMove(...)        cipfried:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  cipfried:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      cipfried:onPlayerEndTrade(...)      end

local engine = cipfried.dialogEngine

engine.all.connect('anything', engine.State('|PLAYERNAME|, please be polite and start a conversation with a \'hello\' or a \'hi\'.'))
engine.all.connect('anything (if the player has less than 65 hp)', engine.State('Hello, |PLAYERNAME|! You are looking really bad. Let me {heal} your wounds.'))
engine.all.connect('anything (if the player is burning)', engine.State('Oh |PLAYERNAME|, you are burning! I will help you.'))
engine.all.connect('heal (if the player is poisoned)', engine.State('You are poisoned. I will help you.'))
engine.all.connect('heal', engine.State('You aren\'t looking really bad, |PLAYERNAME|. I only help in cases of real emergencies. Raise your health simply by eating food.'))
engine.all.connect('name', engine.State('My {name} is Cipfried.'))
engine.all.connect('job', engine.State('I am just a humble monk. Ask me if you need help or healing.'))
engine.all.connect({'monster','quest'}, engine.State('{Monster}s are a constant threat. Learn to fight by hunting rabbits, deer and sheep. Then try to fight {rat}s, bugs and perhaps {spiders}.'))
engine.all.connect('time', engine.State('Now, it is  h : mm  am/pm, my child.'))
engine.all.connect('god', engine.State('They created {Tibia} and all life on it. Visit our library and learn about them.'))
engine.all.connect({'al dee','obi'}, engine.State('He is a local shop owner.'))
engine.all.connect('seymour', engine.State('{Seymour} is a loyal follower of the {king} and responsible for the {academy}.'))
engine.all.connect('willie', engine.State('{Willie} is a fine farmer. His farm is located to the left of the temple.'))
engine.all.connect('tibia', engine.State('That\'s where we are. The world of {Tibia}.'))
engine.all.connect('rookgaard', engine.State('The {gods} have chosen this isle as the point of arrival for the newborn souls.'))
engine.all.connect({'rat','sewer'}, engine.State('In the north of this temple you find a {sewer} grate. Use it to enter the {sewer}s if you feel prepared. Don\'t forget a torch; you\'ll need it.'))
engine.all.connect('spiders', engine.State('If you face {spiders}, beware of the poisonous ones. If you are poisoned, you will constantly lose health. Come to me and I\'ll {heal} you from poison.'))
engine.all.connect('money', engine.State('If you need {money}, you have to slay {monster}s and take their gold. Look for {spiders} and {rat}s.'))
engine.all.connect('king', engine.State('Well, {King} Tibianus of course. The island of {Rookgaard} belongs to his kingdom.'))
engine.all.connect('gods', engine.State('They created {Tibia} and all life on it. Visit our {academy} and learn about them.'))
engine.all.connect('academy', engine.State('You should visit {Seymour} in the {academy} and ask him about a mission.'))
engine.all.connect('nothing', engine.State('Well, bye then.'))

engine.all.to('bye', engine.State('Farewell, |PLAYERNAME|!'))