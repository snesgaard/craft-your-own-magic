# Theme
Craft your own magic!

# Idea
Platformer where you craft your own magic. Casting spells and stuff.

## Spell Crafting

Basically a spell has two mandatory components: form and effect.

The form dictates the "shape" of the spell. Meaning how it moves and what area it affects in the game.

The effect is how the spell affects actors when they come in contact with the form.

A spell is crafted by combining a form and an effect.

Additionally an quality may be attached to the spell, which changes the spells power, cost, cooldown etc.

In general effects are triggered using a power stat and a direction.

### Forms

* Mist -- Area that lingers and repeats effect
* Projectile -- Small hitbox that travels in straight line and effects the first hit actor
* Ball -- AOE on impact
* Aura -- AOE around caster
* Mine -- Small hitbox that lingers. Triggers on collision
* Self -- Target self

### Effects

* Fire -- Damage
* Ice -- Damage and slowdown (or freeze ailment)
* Healing -- Recover HP
* Push -- Move target along direction
* Pull -- Move target opposite target direction
* Timewarp -- Resets coolsdowns

### Quality

* Quicken -- Spell has no cooldown, but dimished effect
* Cantrip -- Spell has no mana cost, but dimished effect
* Empower -- Spell has greater effect, but greater cooldown

## Spell Anatomy

These are the spells stat. Is influenced by all components

* Power -- How powerful is the effect delivered
* Cooldown -- Wait period before the spell can be cast again
* Cost -- How much mana is needed to cast
* (maybe) Casttime -- How long does it take to cast


# Game Structure

Currently thinking a rougelike structure with premodelled rooms. Each room contains an encounter. After a certain number of rooms the player must face a boss.

Thinking navigation could be like Hades. Where each room has a reward on top of it.

Encounters can be things like:

* Combat
* Shops
* Treasure
* Event?

# Concerns
Haven't really done proper combat with AI actors before. Also not sure how designing a good boss would work.

## Mitigation
Infinite scaling enemies with score instead, if boss turns out to be too difficult.
