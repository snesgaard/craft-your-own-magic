# Idea

A card battler ala Slay the Spire or Aeons End.

Essencially a turn-based game where the actions available are randomized each turn.

# Minimum Viable Product

Just a battle vs a barrel or something. Just static sprites without any fancy animations.

Abilities are simply functions, which also invokes the battle logic. E.g. damage.
Battle logic evokes events via the entity events system.

First instance battle should only have 1 or 2 abilities (e.g. damage, heal)

Battle should end when an entity is defeated.

No mouse control.

Battle is implemented as a function ala behavior trees.

# TODO

- [X] ability menu
    - layout
    - keyboard navigation / logic
- [X] combat end
- [X] ai actions

# 19th March 2023

Success! Made MVP on battler. It has got the following features:

* Ability menu with keyboard navigation
* Animation/ability system
* Basic flow
    * Turns
    * Dying
    * Ending
* Basic abilities
    * Damage
    * Healing
* tweens

Flow is implemented as stated above, as functions which gradually stores and completes state. The secret recipe for storing progress is parenting and entities as components. The former means that cleaning up is fairly straight forward. The later allows using the :ensure operation for intilization and stored progress. Really powerful as it allows for both reactionary control flow and scripted flow.

The next goal is to get some basic card game up and running. Thinking approach something ala Aeon's End with the delayed casting.

To get there I'm thinking about the implementing the following:

* Targeting system
    * Ala menu, each targeting request is an entity

* Ability system / data structure
    * Data representation of abilities with targeting and effects

* Deck system
    * Base system for rules on shuffling drawing, discarding etc.

# 21st March 2023

Ended up modularizing the abilities as functions with custom targeting.
Tried to representing targeting and abilities as data, and it ended up being so convoluted that it would almost constitute a secondary programming language within Lua.

So will just be spelling out the needed functionality for now without trying to create some grand unified solution for targeting. Will probably do that, when some obviously shared functionality emerges.

Other than that, it works fine. Abilities are just functions which are called in extension of the player_turn, in a similar manner that the turn resolution calls the player_turn function.

Unsure as to what the next work should be. Kinda wanna start going art. Doing some character design, fleshing out the GUI. In general giving the field a bit more personality than just white boxes. Think that could be pretty satisfying.

Other points would be to redesign the battle system to be overall closer to Aeon's end. Am thinking about the following features:

* Card-based abilities.
* Delayed cast ala Aeon's End.
* Deck-based AI ala gloomhaven.

In all of this, I think it is important that I focus on what's on the screen. Don't go into the framework design rabbit hole, because that is where all productivity goes to die. And also not worry too much about animation for now.

So character sprites will have a single static image for each state for now (idle, casting, hurt, etc.)

As for the code I am thinking this for now:

* Refactor turn logic to do the following:
    * Set enemy intent
    * Player actions until finish
    * Resolve enemy actions
    * Repeat
* Deck system (only when needed)
    * Card organization
    * Shuffling
    * Draws and stuff

As for the graphical side of things:

* Character sprite for player and enemy
* Sprite for card
* Healthbar GUI
* Graphics for spell slots

# 7th April 2023

Reporting in. State of the game is that I have enemy AI up and running, basic gameflow and some basic mechanics in the form of status effects, attacking, healing etc.

Ended up doing a major refactor of the control logic. Went full data driven programming, meaning the same function is always called and progress is retained using the ECS world state. A key invation that enabled this was ensuring that components .destroy method is called on removal, if any. This way I can use the ensure keyword the allocate entities for each step, and have them be automatically deleted later.

Also figured out a way of fully representing abilities using data, no functions needed here. So far, it is only the AI that uses the format, need to refactor play abilities to also use this format.

Mechanics wise ended up going for a simplier energy play-until-done ala hearthstone and slay the spire. Mostly to keep things simple, while I was figuring how to structure the gameflow.

Which brings me to same future tasks:

* <yes> Refactor player abilities to use data-drive format
    * Implement continue like pattern
    * Re-implement AI targeting
* Status icons should be temporally sorted
* Animation integration with abitilies

I'm thinking design-wise, I will stick to slay-the-spire and copy some of the enemy abilities and cards. Just to get a feeling for how flexible this format is.

# 18th April 2023

A lot has happen since last log entry. So summarize

* Initial animation integration with abilities
* Merged player and AI turn taking into one data structure
* Some basic abilities like dagger spray and bouncing flask
* Some initial sprites for player character and balls

The animation and ability integration turned out to be a lot more difficult than expected. Reason is that I kinda abandoned the ECS approach. Each ability had a run function which both governt how what effect abilities would have and controlled the animation side of things.

This was fine for simple approaches, but for something like slay the spires bouncing flask, it was way too much. Creating a separate system for controlling the effect animation and delivery was much more straightforward.

Thus this should the approach I take for other effects and animations. Stringing control together in the run function such as starting animations and checking for done is fine. But all the logic and state maintanence should be in separate systems.

However this brings up the question of structure. I could potentially end of with many systems and animations, which would lead to a book keeping nightmare. A way to resolve this could be.

* Having a giant animation file, with all systems ala component or event.
* Mapping each animation to a specific state component, making iteration over all easy.

Refactoring everything into this format is probably going to be a bit of a pain due to no tests.

On the todo list:

* ---refactor animations into systems/animation, this includes spell effects
* ---remove bouncing flask system
* ---remove sfx system
* ---remove animation.lua--
* ---remove generic cast or refactor it into using sfx entities

20th April 2023

Think I got the sfx animation method down. Went the system route. Works fairly well.

Think I should test it by implementing other slay the spire cards. Another idea could be to update the GUI a bit. Either adding an explaination box or try to add the cards to the GUI.

24th April 2023

Have run into problems with the card rendering and animation system. Reason is twofold:

* Cards are currently values without any unique IDs
* Events are not ordered temporally

To consequences of the former is that we only have the incides to track individual cards for the purposes of animations. The consequence of the latter is that we essentially have trouble determining the final state, if multiple events happen in the same frame.

Take for instance if we have an empty hand and we get a draw card and discard card event. Depending on the ordering we either have 1 or 0 cards in hand after both.

If we had either IDs or ordering we could definitely say what the final ordering should be.

Another thing, which this also ties into to, is animation. Meaning sometimes we want to wait when invokating an action, for all reactions to complete. This is best illustrated by Hearthstone, where chains of reaction can be very long and very complex.

Things like drawing and discarding cards are in some sense part of the mutation, animation chain of events.

Read a post where it essentialy argue Hearthstone had an engine that running constructs a tree of actions. Each action such as card drawing, turn ending, spell casting. Would be triggered as a node. Entities in the game can then append actions either before or after the action has been completed. The action graph is then dynamically built.

Another important detail is that each action has an associated viewer and handler method. The handler method performs the actual transformation of gamestate. The viewer method visualizes and animates the change in game state.

This way the transformation and visualization are decoupled in a sense, such that transformation can be run without the visualization. However they are coupled enough that transformation and animation is synchronized when running in normal mode.

If I were to employ this approach, the ordering and ID would be not relevant anymore. Since each action would only conclude upon visualization completion. Thus instead of relying on implicit catching of events, one would instead call the change directly in the visualizer. So the ordering would naturally follow the ordering of the gameplay actions.

So for me, this could mean that upon invoking a card draw in the gameplay system, we also immediate code that a card draw is also animated. Then attach this to the action allowing us to.

So essentially a phase contains a handler and a view method.

An action consists of a sequence of phases. The document names prepare and perform phases.
The former being where actions are prepared, meaning targets are selected etc. Perform actually carries out the gamestate change. Other entities can react to the conclusion of each phase. With prepare being essentially before and perform after the action has been carried out.

If we ignore the view for a bit, it is important to note that each action reacts to the output of the handler.

It should be noted that a phase could also be to queue one or more phases. For instance something like wallop would be an attack phase which also queues a block phase.