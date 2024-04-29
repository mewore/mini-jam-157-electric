# mini-jam-157-electric

## TODO

- [x] 💚 MVP idea - top-down tower defense
    - The game takes place inside a maze-like structure
    - The player places battery-nutrients on the ground, luring a wire-slime-mold-creature to grow towards them and
      ingest them, growing further
    - The player must guide the wire to a clock. While powered, it ticks away. When it makes a full circle, the level is
      won. If the enemies eat the wires in the clock, the game is lost.
    - Creatures storm in from the edge of the map, finding their way to their target. They like to chew away at the
      wire.
        - If they eat an unpowered wire, it simply disappears.
        - If they bite the wire while it's powered, they get zapped and die on the spot. This takes away some of the
          collected reserve of electricity.

### MVP

- [x] 💙💜 Simple maze tilemap
- [x] 💙💜 Simple wire tilemap
- [x] 💙 Energy meter; wire origin point
- [x] 💙 Clicking on a spot in the maze grows the wire up to it - the growth costs as much energy as the grown tiles
- [x] 💙 Batteries, providing the wire with energy
- [x] 💙 Creature origin points
- [x] 💙💜 Creature
- [x] 💙 Fog of war enveloping everything more than 3 tiles away from the wire, the origin of the creatures and the clock
- [x] 💙 Each creature walks around randomly, revealing a 1x1 area of the fog of war. They always prefer to explore or,
  if unable to explore, to return to spots closer to the origin.
- [x] 💙 The wire pieces light up
- [x] 💙 When creatures encounter the wire, they start gnawing on it. After some time, these parts of the wire are
  destroyed. Disconnected parts of the wire become unusable, but they can be reunited.
- [x] 💙💜 Clock entity
- [x] 💙 When creatures encounter the clock, they start gnawing on it. If they succeed, the level is lost. The player
  can also lose if a creature eats the wire origin.
- [x] 💙 When the player runs out of energy, the level is lost - ~~there is a camera shake and the lights of the wire
  shut down one by one~~
- [x] 💙 Creature gnawing progress.
- [x] 💙 Hold {Space} to unleash an electric surge attack
- [ ] 💜 Battery sprite
- [ ] 💙 If the wire is connected to the clock and the wire has enough power, the clock starts ticking and the power
  starts draining. The only way to stop this is to get disconnected.
- [ ] 💙 If the clock is active for a total of 10 seconds, the level is won.
- [ ] 💚 1 level
- [ ] 💟 Publish `0.1.0`

### Basic features

- [ ] 💙 Main menu (just with a Play button)
- [ ] 💙 Pausing (just "press Esc to continue")
- [ ] 💙 Main menu: Volume controls
- [ ] 💙 Entity instructions at the bottom of the screen when hovering over an entity
- [ ] 💙💜 When the level is won, everything stops, the clock rings, all the creatures die, and the level-won screen is
  shown slightly after that
- [ ] 💛 Clock ring SFX
- [ ] 💛 Wire grow SFX (bubbly-sounding?)
- [ ] 💛 Not enough charge SFX (wrong-answer sound?)
- [ ] 💛 Collected energy SFX (a short, chime-y zap)
- [ ] 💛 Shock attack charge SFX (a long mechanical-electric sound, gradually increasing in intensity)
- [ ] 💛 Shock attack unleash SFX (a zappy explosion)
- [ ] 💛 Shock attack cancel SFX (a long winding-down sound)
- [ ] 💛 Creature spawn SFX (squeak)
- [ ] 💛 Creature death SFX (?)
- [ ] 💛 Creature gnawing SFX (crunch)
- [ ] 💛 Creature gnawing success SFX (big crunch)
- [ ] 💛 Level won SFX/music (happy chime)
- [ ] 💛 Level lost SFX/music (wop wop wop)
- [ ] 💛 Game music (tacky, funky sounding electronic music)
- [ ] 💛 Main menu music (more chill, still funky)
- [ ] 💚 5 levels
- [ ] 💙 Level list in main menu
- [ ] 💟 Publish `0.2.0`

### Advanced features

- [ ] 💜 Cover art
- [ ] 💜 Main menu art
- [ ] 💙 Pause menu: Restart button
- [ ] 💙 Pause menu: Volume controls
- [ ] 💙 The camera shakes when there is an electric surge attack
- [ ] 💙 Particle effects upon creature death
- [ ] 💙 Particle effects upon wire growth
- [ ] 💙 Particle effects upon wire getting eaten
- [ ] 💙 Particle effects upon battery energy usage (maybe special particle-entities, which spawn from the battery and
  fly into the )
- [ ] 💚 10 levels
- [ ] 💟 Publish `0.3.0`

### Expert features

- [ ] 💙💜 Cool-looking fog of war
- [ ] 💜 Icon
- [ ] 💚 25 levels
- [ ] 💟 Publish `0.4.0`

---

#### Legend

- 💙 Code/Godot
- 💜 Art
- 💚 Design
- 💛 Audio
- 💟 Special
