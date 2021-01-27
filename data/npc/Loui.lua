require 'data/npc/lib/NPC'

local loui = NPC({'hi','hello'}, {{'BEWARE! Beware of that {hole}!'},{'BEWARE! Beware of that {hole}!','STAY AWAY FROM THAT {HOLE}!'}}, 'May the {gods} protect you! And stay away from that {hole}!')

function onCreatureAppear(...)      loui:onCreatureAppear(...)      end
function onCreatureDisappear(...)   loui:onCreatureDisappear(...)   end
function onCreatureSay(...)         loui:onCreatureSay(...)         end
function onThink(...)               loui:onThink(...)               end
function onCreatureMove(...)        loui:onCreatureMove(...)        end
function onPlayerCloseChannel(...)  loui:onPlayerCloseChannel(...)  end
function onPlayerEndTrade(...)      loui:onPlayerEndTrade(...)      end

local engine = loui.dialogEngine

engine.all.connect({'hole','story'}, engine.State('While looking for {herbs} I found that {hole}. I went down though I had no torch. And then I heard THEM! There must be dozens!'))
engine.all.connect('herbs', engine.State('I was looking for some {herbs} as I foolishly entered this unholy {hole}.'))
engine.all.connect('gods', engine.State('They created {Tibia} and all lifeforms. Talk to other {monk}s and priests to learn more about them.'))
engine.all.connect('job', engine.State('I am a {monk}, collecting healing {herbs}.'))
engine.all.connect('blueberrie', engine.State('Was it...? Yes, I might have looked for {blueberrie}s as I foolishly entered this unholy {hole}.'))
engine.all.connect('life', engine.State('The {gods} blessed {Tibia} with abundant forms of {life}.'))
engine.all.connect('name', engine.State('My {name} is {Loui}.'))
engine.all.connect('heal', engine.State('Sorry I am out of mana and ingredients, please visit Cipfried in the town.'))
engine.all.connect('time', engine.State('Now, it is 6:56 am, my child.'))
engine.all.connect('tibia', engine.State('Everything around us, that is {Tibia}.'))
engine.all.connect('monk', engine.State('I am a humble servant of the {gods}.'))
engine.all.connect('quest', engine.State('I have no {quest}s but to stay away from that {hole} and I\'d recomend you to do the same.'))
engine.all.connect('rats', engine.State('The good thing is, those horrible {rats} stay in the town mostly. The bad thing is, they do so because outside the bigger {Monsters} devour them.'))
engine.all.connect('monsters', engine.State('There must be an army of them, just down this {hole}.'))
engine.all.connect({'money','gold'}, engine.State('I\'m penniless and poor as becomes a humble {monk} like me.'))
engine.all.connect('loui', engine.State('Waaaah! Don\'t shock me like that!'))
engine.all.connect('rookgaard', engine.State('This is the place where everything starts.'))
engine.all.connect('academy', engine.State('Most adventurers take their first steps there.'))
engine.all.connect({'al dee','obi'}, engine.State('He owns a shop in the town.'))
engine.all.connect('willie', engine.State('The {gods} may protect me from his foul language.'))
engine.all.connect('seymour', engine.State('{Seymour} is the headmaster of the local {academy}.'))

engine.all.to('bye', engine.State('May the {gods} protect you! And stay away from that {hole}!'))