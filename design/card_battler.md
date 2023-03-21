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