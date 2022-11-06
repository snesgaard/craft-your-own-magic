# Design Philosophy
Level/encounter design for a roguelike is tricky as the exact capabilities of the player is unknown. Thus encounters, which fundamentally challenge player capability, tests against the unknown.

Here we will study some examples to more accurately determine what parameters to consider.

## Slay the spire
In combat the player roughly speaking interacts with the encounters via damage and block. The means of generating these are practically infinite in terms of deck and reclic combinations, but it is these two numbers that matters in the end.

Encounters tests the players ability to generate damage and block, with early encounters having few limits on the player whereas later encouters puts big restrictions on them.

For instance the hexaghost tests whether the player can deal about 240 damage in 7 turns (and a little block).

The chosen tests whether you can deal roughly 100 damage in 3 turns.

The gremlin nob test whehter you can deal roughly 80 damage in 3 turns without relying on skills.

Note that these tests are now hard in the sense that failing loses you the game. But rather you lose health. Losing enough tests (health) then ultimately loses you the game.

Thus encounters can be designed with the player as a black box in mind. We do not know how the player generates damage and block, only we test their ability to do so.

## Hades
An encounter in Hades is basically a room with enemies spawning in waves. The player must elimate all enemies in said room before given a reward and proceeding.

The primary way of player interaction is damage, positioning and iframes. In that sense it is similar to Slay the Spire; damage is needed to kill the enemy, positioning and iframes are needed to not die.

The game then tests the player's ability to do both, losing health with each "failed" test.

Each room is predesigned in terms of layout. The randomized elements are the enemies and the rewards.

## Risk of Rain
Each character in risk also has the basic capability of dealing damage, avoiding damage, and jumping. The exact means varies from character to character. Unlike Slay the Spire and Hades the exact endgoal is not know, as the player must explore the stage to find resources and an exit. Difficulty slowly increasing as the timer ticks down.

# General Thoughts
Similar to Spire and Hades I should think of the player as a black box. A black box that generates damage and avoids damage via positioning.

As such I should make sure that the basic kit the player is given, can achieve both outcomes. It shouldn't necessarily be sufficient for getting you through the game (without great skill), but it should enable to you generate both outputs.

An encounter should be designed to test these capabilities under certain constraints. Light initially, harsh in late game.

## Time Pressure
Both Spire, Hades and Risk share an element of time pressure. In Hades and Spire you only have a certain number of rooms before must face a boss. In Risk time ticks and difficulty increases, thus the more time you spent looting and searching a stage, the harder the game gets.

The idea is that each action has a cost. In Hades and Spire, choosing a certain encounter means you implicitly do not choose others, and thus their rewards. Opportinity cost is the name of the game.

## Combat Encounter Design

The easiest solution here is probably to take the Slay the Spire approach, meaning each room has a predetermined layout with predetermined enemies. And should be "beatable" with the base kit.

So for instance, no placing enemies on ledges that requires a ranged attack, if the player doesn't have one in his basic kit. A ranged attack can of course make it easier to deal with, but it must not be required.

Thus, in some sense, coming up with all kinds of interesting player abilities is actually secondary to level design. It must be designed primarly around the base kit.

## Enemy Design
In same sense enemies are similar to the player. The mostly interact with the world via positioning and damage. Thus the most important aspect is how they do this.

Secondary interactions would be things that modifies their primary interactions. E.g. an enemy ala gremlin nob that increases strength everytime the player casts certain spells.


# Props

## Airstream
Launches an actor upwards,

## Trap
If an actor steps on the trap, it triggers after a bit dealing damage to whoever stands on it.

## Terrain
Unpasable geometry

## One way platforms
Can be passed form below.

## Poison fog
Deals damage on intervals to any actor inside it.

## Barrels
Explode on damage, dealing damage and throwback.

# Enemies

## Bone throwers
Throws bones as a basic ranged attack.

## Big bois
Huge and slow. Deals massive damage and has tons of hp, but is very slow and predictable.

## Bombers
Explodes on death. Attempts to attack the player and close distance.

## Necromancers
Spawns ghost that attacks the player. Tries to run away.

# Base player kit

* Horizontal movement
* Jumping
* Dash (iframes and no gravity)
