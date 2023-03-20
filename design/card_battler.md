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
