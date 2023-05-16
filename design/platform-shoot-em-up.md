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