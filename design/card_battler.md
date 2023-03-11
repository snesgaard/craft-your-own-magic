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