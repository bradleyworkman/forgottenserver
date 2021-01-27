require 'data/npc/lib/NPC'

local seymour = NPC({'hi','hello'}, 'Hello, |PLAYERNAME|. What do you need?', 'Good bye! And remember: {No} running up and down in the {academy}!')

function onCreatureAppear(...)      seymour:onCreatureAppear(...)      end
function onCreatureDisappear(...)   seymour:onCreatureDisappear(...)   end
function onCreatureSay(...)         seymour:onCreatureSay(...)         end
function onThink(...)               seymour:onThink(...)               end
function onCreatureMove(...)        seymour:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  seymour:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      seymour:onPlayerEndTrade(...)      end

local engine = seymour.dialogEngine

engine.all.connect('gods', engine.State('You can learn much about {Tibia}\'s {gods} in our {library}.'))
engine.all.connect({'hints','help'}, engine.State('I can assist you with my {advice}.'))
engine.all.connect('advice', engine.State('Read the blackboard for some {hints} and visit the {training} center in the {cellar}.'))
engine.all.connect({'training','cellar'}, engine.State('You can try some basic things down there, but don\'t challenge the {monsters} in our arena if you are inexperienced.'))
engine.all.connect('monsters', engine.State('You can learn about {Tibia}\'s {monsters} in our {library}.'))
engine.all.connect('job', engine.State('I am the master of this fine {academy}.'))
engine.all.connect('academy', engine.State('Our {academy} has a {library}, a {training} center in the {cellar}s and the {oracle} upstairs.'))
engine.all.connect('library', engine.State('Go and read our books. Ignorance may mean death, so be careful.'))
engine.all.connect('name', engine.State('My {name} is Seymour, but to you I am \'Sir\' Seymour.'))
engine.all.connect('time', engine.State('It is 8:26 pm, so you are late. Hurry!'))
engine.all.connect('king', engine.State('Hail to {King} Tibianus! Long live our {king}! Not that he cares for an old veteran who is stuck on this godforsaken island...'))
engine.all.connect('magic', engine.State('The only {magic}-user on this isle is old {Hyacinth}.'))
engine.all.connect('tibia', engine.State('Oh, how I miss the crowded streets of Thais. I know one day I will get promoted and get a {job} at the {castle}... I must get out of here! The faster the better! It is {people} like you who are driving me mad.'))
engine.all.connect('sell', engine.State('I {sell} the {Key} to Adventure for 5 gold! If you are interested, tell me that you want to buy the {key}.'))
engine.all.connect('key', engine.State('Do you want to buy the {Key} to Adventure for 5 gold coins?'))
engine.all.connect('no', engine.State({{'Go and find some {rat}s to kill!'},{'As you wish.'},{'HEY! You don\'t have one! Stop playing tricks on me or I will give some extra work!'}}))
engine.all.connect({'mission','quest'}, engine.State('Well I would like to send our {king} a little present, but I do not have a suitable {box}. If you find a nice {box}, please bring it to me.'))
engine.all.connect('box', engine.State('Do you have a suitable present {box} for me?'))
engine.all.connect('weapon', engine.State('You need fine {weapon}s to fight the tougher beasts. Unfortunately only the most basic {weapon}s and armor are available here. You will have to fight some {monsters} to get a better {weapon}.'))
engine.all.connect('castle', engine.State('The {castle} of Thais is the greatest achievement in Tibian history.'))
engine.all.connect('dungeon', engine.State('There are some {dungeon}s on this isle. You should strong enough to explore them now, but make sure to take a rope with you.'))
engine.all.connect({'vocation','oracle'}, engine.State('You will find the {oracle} upstairs. Talk to the {oracle} as soon as you have made level 8. Choose a {vocation} and a new home town, and you will be sent off to the continent.'))
engine.all.connect('rat', engine.State('Have you brought a dead {rat} to me to pick up your reward?'))
engine.all.connect('rookgaard', engine.State('Here on {Rookgaard} we have some {people}, a temple, some shops, a farm and an {academy}.'))
engine.all.connect('people', engine.State('Well, there\'s me, {Cipfried}, {Willie}, {Obi}, {Amber}, {Dallheim}, {Al Dee}, Norma, and {Hyacinth}.'))
engine.all.connect('quentin', engine.State('He is responsible for the temple in Thais.'))
engine.all.connect('al dee', engine.State('He is a shop owner in the northwestern part of the village.'))
engine.all.connect('amber', engine.State('A traveller from the main land. I wonder what brought her here, since {no} one comes here of his own free will.'))
engine.all.connect('cipfried', engine.State('A humble monk with healing powers, and a pupil of the great {Quentin} himself.'))
engine.all.connect('dallheim', engine.State('Oh good {Dallheim}! What a fighter he is! Without him we would be doomed.'))
engine.all.connect('hyacinth', engine.State('A mysterious druid who lives somewhere in the wilderness. He {sell}s precious {life fluids}.'))
engine.all.connect('life fluids', engine.State('A rare {magic} potion that restores health.'))
engine.all.connect('obi', engine.State('A cousin of Thais\' smith Sam. He has a shop here where you can buy most stuff an adventurer needs.'))
engine.all.connect('willie', engine.State('{Willie} is a fine farmer, although he has short temper.'))

engine.all.to('bye', engine.State('Good bye! And remember: {No} running up and down in the {academy}!'))