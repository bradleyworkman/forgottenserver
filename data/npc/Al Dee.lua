require 'data/npc/lib/ShopKeeper'

local al_dee = ShopKeeper({'hello','hi'}, 'Hello, hello, |PLAYERNAME|! Please come in, look, and buy! I\'m a specialist for all sorts of  {tools} . Just ask me for a  {trade}  to see my offers! You can also ask me for general  hints  about the game.', 'Bye, bye |PLAYERNAME|.')

al_dee.messages.ON_TRADE = 'Take a look in the {trade} window to your right.'

function onCreatureAppear(...)      al_dee:onCreatureAppear(...)      end
function onCreatureDisappear(...)   al_dee:onCreatureDisappear(...)   end
function onCreatureSay(...)         al_dee:onCreatureSay(...)         end
function onThink(...)               al_dee:onThink(...)               end
function onCreatureMove(...)        al_dee:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  al_dee:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      al_dee:onPlayerEndTrade(...)      end

local engine = al_dee.dialogEngine

engine.all.connect('tools', engine.State('As an adventurer, you should always have at least a  {backpack} , a  {rope} , a  {shovel} , a  {weapon} , an  {armor}  and a  {shield} .'))
engine.all.connect({'rope','shovel','backpack'}, engine.State('Yes, I am selling that. Simply ask me for a  {trade}  to view all my offers.'))
engine.all.connect('weapon', engine.State('Oh, I\'m sorry, but I don\'t deal with {weapon}s. That\'s  {Obi}\'s  or  {Lee\'Delle}\'s  business. I could offer you a  {pick}  in exchange for a  {small axe}  if you should happen to own one.'))
engine.all.connect({'shield','armor'}, engine.State('{Armor} and {shield}s can be bought at  {Dixi}\'s  or at  {Lee\'Delle}\'s . {Dixi} runs that shop near  {Obi}\'s .'))
engine.all.connect('food', engine.State('Hmm, the best address to look for {food} might be  {Willie}  or  {Billy} .  {Norma}  also has some snacks for sale.'))
engine.all.connect('potions', engine.State('Sorry, I don\'t {sell} {potions}. You should visit  {Lily}  for that.'))
engine.all.connect({'cookies','fishing'}, engine.State('I {sell} {fishing} rods and {worms} if you want to fish. Simply ask me for a  {trade} .'))
engine.all.connect('worms', engine.State('I have enough {worms} myself and don\'t want any more. Use them for {fishing}.'))
engine.all.connect({'information','help'}, engine.State('If you need general equipment, just ask me for a  {trade} . I can also provide you with some general  hints  about the game.'))
engine.all.connect('job', engine.State('I\'m a merchant. Just ask me for a  {trade}  to see my offers.'))
engine.all.connect('name', engine.State('My {name} is Al Dee, but you can call me Al. Can I interest you in a  {trade} ?'))
engine.all.connect('time', engine.State('It\'s about 0:00 am. I\'m so sorry, I have no watches to {sell}. Do you want to buy something else?'))
engine.all.connect('premium', engine.State('As a {premium} adventurer you have many advantages. You really should check them out!'))
engine.all.connect('king', engine.State('The {king} encouraged salesmen to travel here, but only I dared to take the risk, and a risk it was!'))
engine.all.connect('sell', engine.State('Just ask me for a  {trade}  to see what I buy from you.'))
engine.all.connect({'wares','stuff'}, engine.State('Just ask me for a  {trade}  to see my offers.'))
engine.all.connect({'pick','small axe'}, engine.State('{Pick}s are hard to come by. I {trade} them only in exchange for high quality {small axe}s. Would you like to make that deal?'))
engine.all.connect('dungeon', engine.State('If you want to explore the {dungeon}s such as the  {sewers} , you have to  equip  yourself with the  {vital}  {stuff} I am selling. It\'s {vital} in the deepest sense of the word.'))
engine.all.connect('sewers', engine.State('Oh, our sewer system is very primitive - it\'s so primitive that it\'s overrun by  {rats} . But the {stuff} I {sell} is safe from them. Just ask me for a  {trade}  to see it!'))
engine.all.connect('vital', engine.State('Well, {vital} means - necessary for you to survive!'))
engine.all.connect('rats', engine.State('{Rats} plague our  {sewers} . You can {sell} fresh rat corpses to  {Seymour}  or  {Tom}  the tanner.'))
engine.all.connect('monsters', engine.State('If you want to challenge {monsters} in the  {dungeon}s , you need some  {weapon}s  and  {armor}  from the local  {merchants} .'))
engine.all.connect('merchants', engine.State('To view the offers of a merchant, simply talk to him or her and ask for a  {trade} . They will gladly show you their offers and also the things they buy from you.'))
engine.all.connect('tibia', engine.State('One day I will return to the continent as a rich, a very rich man!'))
engine.all.connect('rookgaard', engine.State('On the island of {Rookgaard} you can gather important experiences to prepare yourself for  {mainland} .'))
engine.all.connect('mainland', engine.State('Have you ever wondered what that \'main\' is people are talking about? Well, once you\'ve reached level 8, you should talk to the  {oracle} . You can choose a  {profession}  afterwards and explore much more of {Tibia}.'))
engine.all.connect('profession', engine.State('You will learn everything you need to know about {profession}s once you\'ve reached the  {Island of Destiny} .'))
engine.all.connect('island of destiny', engine.State('The {Island of Destiny} can be reached via the  {oracle}  once you are level 8. This trip will {help} you choose your  {profession} !'))
engine.all.connect('thais', engine.State('{Thais} is a crowded town.'))
engine.all.connect('academy', engine.State('The big building in the centre of {Rookgaard}. They have a library, a training centre, a  {bank}  and the room of the  {oracle} .  {Seymour}  is the teacher there.'))
engine.all.connect('bank', engine.State('A {bank} is quite useful. You can deposit your money safely there. This way you don\'t have to carry it around with you all the {time}. You could also invest your money in my  {wares} !'))
engine.all.connect('oracle', engine.State('You can find the {oracle} on the top floor of the  {academy} , just above  {Seymour} . Go there when you are level 8.'))
engine.all.connect('temple', engine.State('The monk  {Cipfried}  takes care of our {temple}. He can heal you if you\'re badly injured or poisoned.'))
engine.all.connect({'zerbrus','dallheim'}, engine.State('Some call him a hero. He protects the town from  {monsters} .'))
engine.all.connect('amber', engine.State('She\'s currently recovering from her travels in the  {academy} . It\'s always nice to chat with her!'))
engine.all.connect('billy', engine.State('This is a local farmer. If you need fresh  {food}  to regain your health, it\'s a good place to go. He\'s only trading with  {premium}  adventurers though.'))
engine.all.connect('cipfried', engine.State('He is just an old monk. However, he can heal you if you are badly injured or poisoned.'))
engine.all.connect('dixi', engine.State('She\'s  {Obi}\'s  granddaughter and deals with  {armor}s  and  {shield}s . Her shop is south west of town, close to the  {temple} .'))
engine.all.connect('hyacinth', engine.State('He mostly stays by himself. He\'s a hermit outside of town - good luck finding him.'))
engine.all.connect('lee\'delle', engine.State('If you are a  {premium}  adventurer, you should check out  {Lee\'Delle}\'s  shop. She lives in the western part of town, just across the bridge.'))
engine.all.connect('lily', engine.State('She {sell}s health  {potions}  and antidote {potions}. Also, she buys  blueberries  and  {cookies}  in case you find any.'))
engine.all.connect('loui', engine.State('No idea who that is.'))
engine.all.connect('norma', engine.State('She used to {sell} equipment, but I think she has opened a small bar now. Talks about changing her {name} to \'Mary\' and such, strange girl.'))
engine.all.connect('obi', engine.State('He {sell}s  {weapon}s . His shop is south west of town, close to the  {temple} .'))
engine.all.connect('paulie', engine.State('He\'s the local  {bank}  clerk.'))
engine.all.connect('santiago', engine.State('He dedicated his life to welcome newcomers to this island.'))
engine.all.connect('seymour', engine.State('{Seymour} is a teacher running the  {academy} . He has many important  {information}  about {Tibia}.'))
engine.all.connect('tom', engine.State('He\'s the local tanner. You could try selling fresh corpses or leather to him.'))
engine.all.connect('willie', engine.State('This is a local farmer. If you need fresh  {food}  to regain your health, it\'s a good place to go. However, many {monsters} also carry {food} such as meat or cheese. Or you could simply {pick}  blueberries .'))
engine.all.connect('zirella', engine.State('Poor old woman, her son  {Tom}  never visits her.'))

engine.all.to('bye', engine.State('Bye, bye |PLAYERNAME|.'))
