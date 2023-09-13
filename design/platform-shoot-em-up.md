# 2023-05-23
Herein I am going to document development and thoughts regarding a shoot-em-up in the style of full metal jacket or whatever its called.

The overall design philosopy is going to be: minimal state. An example:

Instead of having a timer with a number being counted down, we instead do timers by just having a timestamp, duration and a central clock. We then only need to worry about updating the central clock to get functionality for all timers.

Animation is another related example. Instead of explicitly creating and setting animation objects with their own local timers, we simply specify the state and a starting time. Then it should be possible to derive the exact frame we are in by comparing with the global clock.

Now on to some topics thats on my mind:

* State controlled status effects
* How to handle sprite animations
* How to handle animation controlled hitboxes
* How to handle collision between temporary hitboxes and entities

## State controlled status effects

To give an example. Take a dash, where the player is invulnerable and moving horizontally.
There's two temporary status effects in here which is state predicated. First the invulnerability which last for the duration of the dash. The second is a temporary disabling of the motion system, e.g. to avoid gravity acting on th entity.

The first solution that comes to mind is setting state flags. Meaning setting a .is_invulnerable componenet and a skip_motion component. While this is fairly simple, it presents a problem in that these must be explicitly turned on or off on entering or exiting the state. So if the dash state is exitted unexpectly, these will remain.

Another way is to have some function which explicitly checks the state, but this can easily get out of hand.
draenei
The best approach I think is to create a separate entity which contains the relevant flags and explicit lifetime conditions. Meaning they die either on state change or when a timer expires. This way, the only thing we have to keep track of, is creating the entity and holding a reference.

Example:

```lua
weak_assemble(
    {
        {nw.component.is_invulnerable},
        {nw.component.skip_motion},
        {nw.component.timer, 0.3},
        {nw.component.die_on_timer_done},
        {nw.component.die_on_state_change, owner},
        {nw.component.target, owner}
    },
    "dash"
)
```

Another positive aspect of this design, is that it also solves the multiple-sources-of-invulnerability problem.

## Sprite animations

Currently the control of an entity is modelled using a sprite state component. This keeps track of when the state was entered, what the state name is and temporary data. 

Now sprite animations must also be included, as sort of a visualization. 

I think the best approach here is to derive the relevant visual information from the sprite_state component. Say for instance we have the dash state.

Visually we want to loop the characters "dash" animation for the duration of the dash. The exact animation can be specified via a look up map. So knowning the state, the lookup and the time we can derive the exact frame using the global clock.

However this brings up a challenge:

## Animation controlled hitboxes

Some animations have slices or hitboxes associated with them. For instance a melee hit animation will have an associate hitbox with it, that needs to be spawned and entered into the collision system. Additional this hitbox must follow the character position and state.

The simplest solution here is to upon updating the visual state, we also update the hitbox state. This means erasing any previous hitboxes and recreating any which may be attached to the current frame.

Alternatively we could mutate any existing hitboxes, but this is mostly an optimization on the same idea.

Note that this should not deal with any resolution of collision. Simply creating the hitboxes with sufficient data e.g. hitbox_name, owner_id, is_ghost etc.

## Animation hitboxes and gameplay effects

Having resolved the animation-hitbox issue, brings up another potential issue; gameplay effects.

Take for instance the melee hit example. Upon contact with an enemy it should deal damage, but only once! Meaning repeated contact should only result in a single damage dealing event.

So we have two issues here; how to associate a given collision with a given effect and how to keep track of repeat collision.

The naive solution would be to associate this data in the hitbox itself, however this presents multiple issues. Primarily the sprite state system would need to know what data to associate with each hitbox. Second if hitboxes are repeatably destroyed, any memory will also be destroyed with it.

A better approach is probably to create a secondary entity which listens and resolves collision effects. For instance:

```lua
weak_assemble(
    {
        {nw.component.hitbox_attention, owner, "attack"},
        {nw.component.effect, "damage"},
        {nw.component.power, 3},
        {nw.component.timer, animaton_time},
        {nw.component.die_on_timer_done},
        {nw.component.die_on_state_change}
    }
)
```

Now this can be created by the sprite_state system complete seperate from the sprite_animation system, which is great! Second the also resolves the multiple effects pr hitbox issue.

The only potential issue is that if two of these somehow accidentially exists simultanuous (e.g. from previous state) we could get double resolution. However this can be solved by associating the sprite_state with some magic unique value, and only trigger on collision matching this value.

# 2023-05-17

So I have basically implemented all of the above (expect for the state_change thing). Which means I have a lot of the shaffolding needed to make some stuff!

Have also implemented one-way platforms as part of bump collision response.

## AI as action and intent
The next challenge I think is going to be enemy AI. How to model and implement it.
Here I want to try and separate things into "actions" and "intent".

An action is some function of the AI which aims to alter the gamestate somehow. This could be things like:

* move
* idle
* melee attack
* shoot gun
* jump
* hit-stun
* etc.

Intent is the overall goal which the agent wishes to accomplish.
This is could be:

* Hit the player with a melee attack
* Follow patrol
* Stand still for 6 seconds.

The AI then perform one or several actions in order to achieve the goal.
For instance in order to achieve goal "hit player" the agent may perform moves until it is in range, then perform a melee attack action.

One way of accomplishing this is to treat the agent as a sort of FSM puppet. Meaning it can be in one or more states which represents the actions the agent can perform.
The "intent" system then manipulates the FSM puppet as a way of implementing the actions.

## Other method of hitbox collision effects

An alternative means of implementing hitbox collision resolution would be to assume that the hitbox always exists. Meaning upon creation of the entity, the hitbox is also created as a child entity.
It is not entered into the collision system, but rather already populated with data necessary for collision resolution. For instance if we have a bash hitbox, on creation we might do something like this:

```lua
bash_id = weak_assembly(
    {
        {nw.component.damage, 3},
        {nw.component.owner, owner},
        {nw.component.flaming},
        {nw.component.only_once_pr_activation}
    },
    "bash"
)
```

The animation system is still responsible for moving, reshaping and activating the hitbox. But all the auxcillerary data is populated upon creation. If different animations results in different damage/effects then the resulting hitboxes must have unique names, but that is a reasonable restriction.

Last note. In trying to model the decision making AI, i accidentally ended up making something very close to behavior tress. Funny how that works out sometimes :P

# 2023-05-20

So basically got both the pupper concept and scripting up and working. Works as intended. So now there's intent with automatic input buffering and works perfectly.

Only question is what's next? Kinda wanted to create something ala Metal Slug, something without to many stats. More focues on bullets and dodging and combat screens.
That brings up the question:

* Setting and visual style
* Enemy design and behavior
* Level design

An interesting note on on enemy and level design. A post on reddit made a point of these not being separatable in a platform focused game. Both work together.
They form a puzzle which the player must solve. Either by avoiding or hitting them. Also mentioned that the best platformers enemies can also be tools for progression e.g. super mario and shovel knight jumping boost enemies.

Essentially it all boils down to how the players abilities interact with the enemies and the level itself.

So if I were to speculate, one should probably start with the basic player abilities:

* Move horizontally
* Jump
* Dash
* Melee hit
* Ranged hit

One must know these in order to place obstacles. Next is probably enemy design and behavior e.g.:

* Move
* Shoot

Actually I think it is important to settle on a single, unique mechanic to focus the design on. For instance for shovel knight, it is the shovel. Hit with it, use it to jump on enemies etc. For mario the game is largely focused on jump. Is how you dispact enemies and progress. Hollow knight has the nail, whihc is similar to the shovel. Also other abilities, but that comes in later.

An idea could be the Cubemancer. You summon cubes. These are used for either attacking enemies (drop from sky) or creating platforms.

Just watched the first level of shovel knight. It basically introduces the core mechanics available to the player:

* Move horizontally
* Jumping
* Hitting
* Jump with shovel down

Also introduces the following level elements:

* Some terrain can be destroyed via hitting
    * Reveal passages
    * Reveal items
* Enemies:
    * Beetle
    * Skeleton

A good core mechanic should have multiple uses. For instance the shovel hit in shovel knight:

* Kill enemies
* Reveal passages
* Deflect projectiles
* Activate switches

Also the shovel jump can:

* Kill enemies
* Activate objects
* Destroy geometry
* Bounce off enemies and other objects

Jumping can:

* Avoid enemies
* Reach higher floors and objects

Ideas for mechanics:

Dynamite:

* Kill enemies
* Push and gain elevation
* Destroy objects
* Activate objects

Square:

* Kill enemies (on impact)
* Block projectiles
* Gain elevation

Dash:

* Reset jump
* Avoid attacks
* Horizontal motion, without ground

Jump:

* Gain elevation
* Avoid attacks
* Reset dash

In general want some intense metal slug experience.

Speaking of which, it has the following core mechanics:

* Move
* Shoot
* Jump
* Duck

# 2023-05-23

Okay I have decided to just experiment with character moveset. When I find something interesting either combat or platforming I design around it.

Speaking of which I need to compute the jump height -> gravity -> velocity algorithm again. Consider:

y = g * x ^ 2 + v * x
y' = 2 * g * x + v

meaning the highest point is given by:

0 = 2 * g * x + v
x = - v / (2 * g)

Inserting this into the original equation gives:

y = g * v ^ 2 / 4 / g ^ 2 - v ^ 2 / 2 / g

y = (g / 4 / g ^2 - 1 / 2 / g) * v ^ 2
y = (1 / 4 / g - 1 / 2 / g) * v ^ 2

y = 1 / (4 * g) * v ^ 2
v = 2 * sqrt(y * g)
Now in terms of v

# 2023-05-24

So have made some initial character movesets and animations. Was kinda fun. But stil hasen't brought me closer to what to do. I'm leaning towards platformer. Not for technical reasons, but rather design.

I really have no idea where to start or stop. Kinda get the idea of the level design process. You create a rough idea of the challenges/problems you present the player, and go from there.

But in order to do that you must have:

* Main character moveset
* Enemies
* Obstacles and props
* General rules
* A theme

This is kinda where I am stuck. Don't really know where to start. Either on moveset or theme or enemies. All I know is that I want general platforming capability.

* Tiles
* Jumping
* Horizontal moves
* Character driven

Anyways back to my thoughts. The reason I want a platformer is to keep things simple. Simple enemies and stuff. I dont relaly know how to design around or design more complicated enemy AI for a brawler. Also I like fast paced movement.

I think I like somehting like a goblin shaman mc or something. Also had an idea of using spawned blocks for platforming and combat. Regardless the core moveset is the most important. The game must be beatable with it. Otherwise it would be more of a metroidvania.

* Move
* Jump
* Dash
* Strike
* Down-strike in air

# 2023-06-01

So I have implemented the basic player mechanics. Went with a rocket-fist concept about charging and flying punches. Also figured out how to store and configure hitbox information (slice data in Aseprite). So the next step is probably enemy AI and enemies in general. There are two components to this:

* Enemy behavior
* Combat system

The behavior or script is how the enemy behaves. Which moves it makes based onw hat conditions. This should just be super simple like shovel knight or Skul. Sensors are probably going to be fairly important here. These are basically hitboxes that check certain regions in the world and return which objects overlaps with it. This way line of sight can be implemented, along with things like walking until an edge is met.

Another thing that has been on my mind is in general how to handle buffs and other changes in state: as components or as separate entities.

Take something like a poison effect ala Slay the Spire. Fundementally it needs a timer and a numerical value. The timer determines when the poison ticks and the numerical value determines how much damage is dealt pr tick. We can either model this as a component which contains the number and a timestamp, or a separate entity which contains the number, a target and a timer.

Advantage of the component apporach is that it is much easier to understand and manipulate. Say we want to compute the total level of poison affecting the player. We would have to locate all entities with poison numerical value. Then filter based on their target. In the component based approach you simply read the number.

For more conditional lifetime, we can again think of Slay the Spire. Take for instance the temporary strength buffs. Instead of creating some complicated buff entity with conditional lifetime, it instead creates two pieces of data. One is the actual strength increase. The other is a strength weakening component with the same numcerical value. The game is then coded in such a way that when the turn ends the weakening component is subtrated from the strength and removed.

A similar situation can be thought of in terms of a player dash. In this state the player has two effects put on it:

* skip motion
* invincibility

We can model this in the same manner. We create the actual data and some auxeliary data that tells the system to remove the original data on state change (decrement the numerical values).

```lua
stack.set(nw.component.invincibility, id)
stack.set(nw.component.remove_on_state_change, id, "invincibility")
```

```lua
stack.map(nw.component.invincibility, id, add, 1)
stack.set(nw.component.on_state_change, id, "invincibility", "sub", 1)
-- or more complicate condition
stack.set(nw.component.after_time_or_state_change, id, 0.2, "invincibility", "sub", 1)
```

```lua
stack.set(nw.component.invincibility, id)
stack.assemble(
    {
        {nw.component.target, id}
        {nw.component.operation, "invincibility", "remove"},
        {nw.component.trigger, "state_change", id}
    },
    buff_id
)
```
I like option 2 the best. Short and very readable. It just becomes a bit problomatic if something like this has multiple conditions. E.g. if invincibility should be removed after either 200ms or on state change. This would effectively require a unique component for unique combination of conditions case.

In terms of option 3, one can simply add more trigger conditions that can work independently. The problems is of course that it reintroduces the whole buff as entity approach.

Another apporach would be to take a rules based approach instead. Meaning no temporary modifcation of state, since we know that when the player is in dash state it is invincible and motion should be skipped. So we need not turn the invincility flag on or off since it is directly derived from the state flag. 

The problem here is of course that some effects are purely state driven (e.g. buff placed by spell)
and thus do not entirely resolve the problem.

All in all it is very hard to chose since whether one or the other is better really depends on the application.

My current need is:

* Certain states needs to change depending on animation timers and state

Anyways think this is too hard for me to figure out for now. Instead should focus on my immediate need:

* Refactor 
    * nw.component.puppet("player") -> nw.component.puppet, "player"
    * nw.component.script("player") -> nw.component.script, "player"
    * Local and global sensor checks
    * Basic patrolling AI
    * Only destroy and recreate hitboxes on magic value change. Otherwise simply change the collision state
    * Try out the component and cleanup component approach

The goal is to do the demoing. The danger in continuing the whole effect discussion is that I easily get stuck in an inifite lopp, incapable of figuring out which pros outwiehgts which cons.

Actually just tried the cleanup approach. Wasn't actually all that hard to replicate and it is much more straightforward. Goes to show I shouldn't think generally, but rather on specific needs.

# 2023-06-03

So have succesfully implemented an AI agent using the behavior tree approach. It's behavior is fairly simple. It patrols from side to side until the player is spotted. Then it moves towards the player and attacks them. Furthermore it uses the player puppet, demonstrating that the decoupling between controls and puppet is working nicely. Also demonstrated with both simple attacking and a more complicated charge -> fly punch cycle.

Next step is to build more of the basic elements. According to my notes these includes:

* Switches, lever and ground
* Doors 
* Movable blocks

Afterwards, I should revisit the design documents and draw up some levels. Also combat system.

# 2023-06-12

So again things have been implemented. Also made a new character moveset using a rig-like animation approach. Works fairly well. Next step is probably making an enemy agent or two: Bonk-bot and Shoot-bot:

* Rough animations
* Ai with simple patrol -> attack pattern
* Base damage and health system
* Hp display

The idea is to prototype the demonstrate some basic combat and abilities and stuff.

Also heres a card game idea for a deckbuilder CCG. Think a combat system ala Netrunner. You have two types of cards: spells and relics. Spells are normal, instant effects.

Relics are sortoff a minion replacement. Instead of being a minion on the board, it is sortof like hardware and software in netrunner. It gives you permanent abilities and reactions. So you can setup a complex series of interactions ala hearthstone, but without having to deal with minions you need to command.

I guess minions could be okay as well, as initially one only needs to draw a single sprite. Also have good idea for the card/effect resolution engine. But man all the GUI really kills me :/

First all. All cards and elements always exists. They can be toggled or moved around, but never destroyed. If a character dies, it is moved to a dead pile.

Second GUI needs to be figured out some how. Again thing an approach of pure rendering with some background logic is good. So clicks on the GUI is merely transferred back to the logic as events.

And model as much of the game as data as possible. Also find GUI lib probably

# 2023-06-18

So I basically went full behavior trees and its awesome. Both for implementing AI agent behavior and player character control. Thinking I am going to deprecate the puppet_control system, since the behavior tree and do it's job, in a more concise way.

Goal is still to implement some basic combat. Hitting and health and maybe some hit stunning. Since the AI agent is ready, rest should be straight forward coding.

* Healthbars
* Numbers
* Hitstun?
    * Make behavior interruptable

Okay så probably need to revamp the combat side of things. I need to basically:

* Health and damage
* !!! Hit push-back
* !!! Hit stun
* !!! Ai interrupts
* !!! Behavior system

# 2023-06-24

So having made health and push and stunning prototypes I think it is time to formalize things a bit.
I am thinking about making systems/rules formalizing.

## Health
 
Data:

* Health
* Max Health
* Invincible
    * Immune

Health is life. As along as health is greater than 0, the actor is alive and can act in the world.
When health is reduced to 0, the character is considered dead and cannot act in any way.
Health is reduce through damage and healing.

Max heal is the upper limit for health. Healing cannot bring health above this value. If max health is raised or lowered health is adjusted to respect this limit.

An invicible character cannot received damage.

## Knockback

* Knockback
* immune-knockback

Each attack has a knockback stat which is equal or greater than 0. An entity hit with this attack will be moved horizontally by said value. Direction of motion will be the defined by the difference in position between hitboxes.

Immune-knockback means an actor cannot be moved via knockback.

Question how does this interact with non-health entities. E.g. a lever should not be knockbackable, but a box could be. Or perhaps a knockbackable lever would be fun?

But then marking all entities with collision as knockback-immune would be annyoing as doors and tiles would also need that component.

Maybe something like, if it has health it is automatically knockbackable unless immune. If it doesn't, it must explicitly be marked as being susceptible to knockback

## Hitstun

* is_stunned
* immune-stun
* stun

A attack with the stun component will stun an entity. Meaning it's ai is reset and the is_stunned property is applied for a brief period of time. Entities should respect the is_stunned property by not acting and playing the stun animation.

The immune-stun property means the entity will not be hit-stunned.

## Daze

* is_dazed
* immune-daze
* daze
* resistance-daze
* resistance-daze-max

Daze is similar to stun, in that it temporally disables an entity. However it is longer lasting than stun. Daze is triggered when the resistance-daze stat is equal or greater than the resistance-daze-max stat.
When this happens, is_dazed is set, resistance-daze is set to 0 and resistance-daze-max is increased.

immune-daze means this entity can never be dased.

Daze can only affect entities with health.

# 2023-07-23

Been almost a month since I write this log. A lot has happened. Been iterating on the behavior tree approach and it still works pretty well.

Also been trying out a new workflow for developing new enemies:

* Decide on overall theme and role
* Rough out design silhouette
* Build basic forms for animation
* Animate walking, hit, idle using forms
* Add silhouette to animations
* Integrate into game and develop AI for it.

Developed two enemies "skeleton-cloak" and "zombie-axe" using this method. Is fairly fast for prototyping and iteration. Animation is still by far the slowest as figuring out poses, adding forms and timing everything still takes time. Staying on model in terms of scale is still a bit of a problem.

Another important innovation is add a layer with reference for animation. Makes staying on model a bit easier

If I were to revise the workflow it would probably be:

* Design and role
* Idle silhouette + basic forms
* Animate using forms
    * Import into engine
    * Tweak timing, spacing etc.
    * Adjust sizes to stay on model
* Add silhouette to animations

Afterwards:

* Idle color + shading
* Add shading to animations

Importance put on reducing time from idea to testing in-engine.

Also added a cool system for syncing particle effects with hitbox animations. Basically just add an sfx property to the slice in Aseprite and you can do things such as sparks flying from scraping metal or impact sparks.

Am ironing out most of the techincal problems one by one.

Guess one thing that is missing is a death system. Meaning when actors run out of HP, they should die. Thinking that is just adding a death animation / sprite, and dealing with this in the behavior tree.

On a more negative side, I still have no idea what to do with this game overall. Is cool making designs and animating them, but would like to approach something more playable soon. Something that you can engage with. 

It really is design that is my current headache. My initial inspiration was creating something ala Metal Slug. A sidescroller shoot-em-up. Should be easy to pick up and play, without too much in the way of mechanical complexity. Basically just hit and/or shoot with maybe some explosions on top of it.

Maybe what I should try to just to create level, sortof a vertical slice. With a couple of enemies, maybe a boss fight, music and final shading. Just to see what it would take. It would have to start with planning.

* Decide an a setting and theme
* Decide on player abilities
* Brainstorm a couple of enemy designs
* Design level/encounter sections
* Put these together into a final level (5 mins length max.)
* Design a boss-fight at the end.

Simplicity is important here. Both for the player and also for me. Since I am not very experience with level design, I must keep things simple to not loose my mind :P

# 2023-07-30

Still not making a lot progress on the game part. Have in the art department. Drawing exercises and shading makes me itching to start creating more stuff for the game.

Now I do have some more overall considerations on how the design process could look like:

* Decide on overall game concept
* Decide on central mechanics of the game
* Decide on player abilities
* Design obstacles
* Design encounters and level

To elaborate a bit.

## Game Concept
This is the games overall theme and genre. An example: "Sidescroller beat-em up in a desert with necromancer".

Sets the overall theme, mechanics and visual language. This should also include the overall goal/win condition of the game.
In short: "what is the game about"

## Central Mechanics
These are basically the rules on which the game will operate.
Think of it in terms of systems and base mechanics by which these systems will interact.
E.g. health, motion.

## Player Abilities
Overall how will the player interact with the systems. What options and abilities should be available to them.

## Obstacles
An obstacle is a problem for the player to solve, ideally with multiple solutions.
These can be enemies or level geometry or something else depending on the game design.

An obstacle should present an interesting problem on it's own. As in interacting with it in a completely blank room, should be fairly interesting.
E.g. enemies in Dark Souls are pretty great and interesting on their own. They're obviously infinitely better in context of the levels.

## Encounter
An encouter is a collection of obstacles: e.g. geometry + enemies. In general it can be thought of as a single scene.
Can be puzzles, combat, platformning or a combination of all three.
All depends on what obstacles are put in.

## Level
A level is a collection of encounters. These can be in a linear sequence or spread out in a more open manner.
Level should contain a goal or objective of some kind. Can be as simple as move all the way to the right.

## In Conclusion
I think obstacle and encounter design are greatly underappreciated. I have played many JRPGs that have great combat and craft systems, meaning great player ability design, but bad obstacle and encounter design.
Typically in the sense that they're too simple or too easy. They have simple solutions and do not encourage enganging in their systems.

Mana Khemia is IMO a good example. The battle system is excellent with different abilities and the party swapping and timeline mechanics. But most encounters can be solved via the simple algorithm of:

* If hurt, heal
* otherwise use the most damaging ability you have

No need to vary up play, or build differently.

Slay the Spire is an example of a game with excellent obstacle and encounter design. Unless you have a truly degenerately powerful deck, few enemies can be effeciently defeated by mindlessly attacking.
Take for instance the simple Lice. The cover mechanic on this enemy creates many ways of solving it:

* Attack it one round and finish it off after the cover wears off.
* Attack it with a single powerful attack, which kills it before cover kicks in
* Use some combination of non-attack and attack damage, to kill it before cover activates

Or Advocado

* Defeat it quickly before you take too much damage
* Build heavy defenses and slowly chip away it's health

Then you have things like the Chosen and Awakened One which puts soft restrictions on your abilities, punishing you for relying too much on a single mechanic.

Let us try to analyze something in this manner

## Slay the Spire

Here we mostly focus on the combat portion of the game.

### Concept
Roguelike deck-builder with turn-based combat, centered on climbing and destroying a mysterious spire.

### Central Mechanics

Cards -- Player abilities are given as cards, which are drawn from a player built deck. Each round a new hand is drawn randomly.
Health -- Like most games. When it reaches 0, the associated entity dies. Health is reduce via damage and increased via healing
Block -- Temporary health. Damage typically first reduces block, before it reduces health. Block is removed at the start of a turn.
Energy -- Used to play cards. Starts at 3 and is refilled at the start of a turn.
Intention -- The player can in general see roughly what the enemy will do on their turn.
Exhaust -- When a card is exhausted, it is added to the exhaust pile, rather than the discard pile

Card types: Attack, Skill, Powers

### Player Abilities
On the players turn, the player can do the following:

* Play a card 
* Use a potion

Cards can only be played if the player can pay the required energy.
Potions can always be used, but is single use only.

### Obstacles

Lice -- An enemy which gains block on the first attack. Forcing players to work around it.
Cultist -- An enemy which gains strength pr round, forcing player into a damage race while balancing defense.
Jawworm -- An enemy which can gain strength, but also defend and attack heavily. A damage race, where the player must balance both defense and offense.
Chosen -- An enemy which puts a debuff on the player, penalising skill usage. Effectively asks player whether can deal 100 damage during the first deck rotation.
Awakened One -- Gains strength on each power played. Meaning either the player must refrain from playing powers, or have a powerful scaling strategy that can offset the increased offense of the awakened one.

### Encounters

* Three lice
* Cultist + Chosen
* Cultist, Cultist, Awakened One
* 3 x Jawworm
* Jawworm + Lice
* Cultist + Jawworm

## Tomb Explorer

### Concept
A side-scroller beat-em up, centered on delving deeper into an ancient tomb for treasure.

### Central Mechanics

Health -- if this reaches 0, the entity dies.
Horizontal movement -- Entities can only move freely horizontally, even when in air
Veritcal movement -- If flying can move freely vertically, otherwise motion is governed as a ballistic curve
Energy Crystal -- These are spent on abilities. When spent the crystal goes on cooldown, and is unavailable for some time.

### Player Abilities

Horizontal movement -- As all entites
Jumping -- Can jump on ground and have an additional jump mid air
Attacking -- Create a hitbox, which damages enemies on contact
Block/Parry -- Player can block to reduce incoming damage. A well timed block results negates damage, and damages the attacker.
Specials -- Player can have access to up to three specials at a time. These expent energy crystals for powerful effects.
Bowgun -- Fires arrows used for attacking. Can be stuck on walls for platformning.

### Obstacles

#### Geometry
Elevation -- Blocks horizontal motion. Elevation must be increased to pass it.
Pits -- Entites can fall into it and may die.
Barrel -- Explodes on hit.
Jetstream -- Accelerates entity in a given direction
Terrain -- Cannot be passed through by entities.

#### Enemies
Grenadier -- Enemy which throws grenades. Projectiles follows a ballistic curve, and takes time to arrive which allows the player to move out of the way.
Small fries -- Small enemy with minor melee attacks. Will swarm the player, attacking on mass.
Big grunt -- Slow and heavy hitting enemy. Attacks are very forward facing and can be avoided by moving behind the enemy.
Flyer -- Free horizontal and vertical movement. Will generally fly overhead in a fixed pattern and try to hit the player with overhead bombs.
Summoner -- Will continually spawn minions which attacks the player. Summons disappear when summoner is defeated.
Supporter -- Heavily buffs the speed of enemies. Runs away from the player.
Turret -- Fires projectiles in a straight line towards the player. Doesn't move otherwise. Can repulse nearby enemies via an AOE.

## Descent of the Cryomancer
A side-sroller beat-em up. Descent into an ancient tomb for secrets and treasure. Focus on creation of level geometry.

### Central Mechanics

Health -- If this reaches 0, the entity dies.
Platforming -- Generally speaking entities can move freely horizontally. Only flyers can move freely vertically, others move in ballistic curves.
Terrain -- Squares which are generally impassible by entities and effects.
One-way platform -- Squares can be passed through from all directions, except above.
Rime Crystals -- These are spent on creating ice and special moves. When spent, goes on cooldown before it can be used again.

### Player Abilities

Ice Blocks -- Create a temporary platform. This acts as terrain with a lifetime.
Jumping -- Can double jump to gain elevation
Dash -- Quick horizontal movement. Cancels vertical momemtum. Gain invincibility.
Ice Projectiles -- Fires small ice projectiles. Damages enemies. If it hits terrain, will form a temporary small one-way platform.
Horizontal Movement
Frost Nova -- Charged move. Results in a big ice explosion, with damage scaling with the charge time. Forms one-way platforms used for jumping.

# 2023-08-11

Not a lot has happened on the game development/coding side of things.
Have experimented alot with art, expecially color palettes and bounce back lighting.


## Colors

To summarize feel that creating color palettes by spanning the primary and secondary colors as well as a neutral tone, mixed with a common unifier color creates a nice palette.
Then all these tones share a common set of bounce lighting and core shadow colors. Sketched some plants and did a full illustration of some birds on a cliff. Seems to work fairly well.
In case I need more colors, I can always mix the existing ones in the palette if e.g. I need a darker blue.

A full color bridge is made of 5 colors: core shadow, bounce light, half-tone, direct light and highlight. By employing the shared core and bounce light tones, I have 7 color bridges, using only 23 colors.
Could probably prune it even further by merging some of the similar colors.

Now the whole reason I went through the color palette process, was to create some "universal" palette which I can use to create assets. Such that I dont have to solve for some universal color harmony before hand. Just the general feel (purple in this case).

## Stuck in Limbo

Am still not further along actually getting going with more game development. Still don't know what to make exactly.
I know that the overall design document approach is the right way to go. But is hard to keep my passion going using that approach.
Also conherency of vision can be problem. Sometimes a week or two can pass before I work on the game, and I usually forget where I was going and why.

Also sometimes feels like I'm stuck when I resume work on the same animation for third time in a row.

I know logically that the design document and plan is the way to go. To keep track of what I am making and roughly how I am going to make it.
Also keeping scope limited, such that I don't end up working on something for months and lose interesting without finishing it.

An idea could be: