require 'data/npc/lib/NPC'

local amber = NPC({'hi','hello'}, {{'Oh hello, nice to see you |PLAYERNAME|.'},{'Oh hello, nice to see you |PLAYERNAME|.','See you later.'}}, 'See you later.')

function onCreatureAppear(...)      amber:onCreatureAppear(...)      end
function onCreatureDisappear(...)   amber:onCreatureDisappear(...)   end
function onCreatureSay(...)         amber:onCreatureSay(...)         end
function onThink(...)               amber:onThink(...)               end
function onCreatureMove(...)        amber:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  amber:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      amber:onPlayerEndTrade(...)      end

local engine = amber.dialogEngine

engine.all.connect('job', engine.State('I {explore} and seek {adventure}.'))
engine.all.connect('adventure', engine.State('I fought fierce {monsters}, climbed the highest mountains, and crossed the {sea} on a {raft}.'))
engine.all.connect('sea', engine.State('My trip over the {sea} was horrible. The weather was bad, the waves high and my {raft} quite simple.'))
engine.all.connect('explore', engine.State('I have been almost everywhere in {Tibia}.'))
engine.all.connect('tibia', engine.State('I try to {explore} each spot of {Tibia}, and one day I will succeed.'))
engine.all.connect('time', engine.State('Sorry, I lost my watch in a storm.'))
engine.all.connect('dungeon', engine.State('I have not had the {time} to {explore} the {dungeon}s of this isle, but I have seen two big caves in the east, and there is a ruined tower in the northwest.'))
engine.all.connect('king', engine.State('{King} Tibianus is the ruler of {Thais}.'))
engine.all.connect('thais', engine.State('A fine city, but the {king} has some problems enforcing the law.'))
engine.all.connect('castle', engine.State('If you travel to {Thais}, you really should visit the marvelous {castle}.'))
engine.all.connect('magic', engine.State('You can learn spells only in the guildhalls of the mainland.'))
engine.all.connect('weapon', engine.State('The best {weapon}s on this isle are just toothpicks, compared with the {weapon}s warriors of the mainland wield.'))
engine.all.connect('monsters', engine.State('Oh, I fought {orcs}, {cyclopses}, {minotaurs}, and even green {dragons}.'))
engine.all.connect({'minotaurs','cyclopses','dragons'}, engine.State('Horrible {monsters} they are.'))
engine.all.connect('orcs', engine.State('Not the nicest guys you can encounter. I had some clashes with them and was {prisoner} of the {orcs} for some months.'))
engine.all.connect({'orcish','prisoner'}, engine.State('I speak some {orcish} words, not much though, just \'yes\' and \'no\' and such basic.'))
engine.all.connect('yes', engine.State('It\'s \'mok\' in {orcish}. I help you more about that if you have some {food}.'))
engine.all.connect('no', engine.State({{'Too bad.'},{'In {orcish} that\'s \'burp\'. I help you more about that if you have some {food}.'}}))
engine.all.connect('food', engine.State('My favorite dish is {salmon}. Oh please, bring me some of it.'))
engine.all.connect('salmon', engine.State('Yeah! If you give me some {salmon} I will tell you more about the {orcish} language.'))
engine.all.connect('cipfried', engine.State('A gentle person. You should visit him, if you have problems.'))
engine.all.connect('dallheim', engine.State('An extraordinary warrior. He\'s the first and last line of defense of Rookgaard.'))
engine.all.connect('hyacinth', engine.State('{Hyacinth} is a great healer. He lives somewhere hidden on this isle.'))
engine.all.connect({'raft','mission','quest'}, engine.State('I left my {raft} at the south eastern shore. I forgot my private notebook on it. If you could return it to me I would be very grateful.'))
engine.all.connect('book', engine.State('Do you bring me my notebook?'))

engine.all.to('bye', engine.State('See you later.'))