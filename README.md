Litmus
======
Litmus tests to determine viability of different languages for prescience engine

##### Benchmark numbers in turns per second (light playouts)
- python idiomatic:   47 k/s
- python performant:  53 k/s
- cython dumb:      110 k/s
- cython idiomatic: 292 k/s
- c++ idiomatic:    2437 k/s
- c++ smarter:      4150 k/s
- rust stupid:      3600 k/s

##### TODO
- haskell
- cython with STL/numpy

# Requirements
##### Unit actions
- apply/remove instaneous effects to self or other units
  - dmg enemy
  - heal ally
- apply/remove ongoing effects to self or other units
  - add (de)buff to stats of other unit
  - add (not-stat buff based) effect to other unit
  - dispell effect on another unit

### Effects
-----------
**Implicit (modify unit on buff add/removal)**
* On_ (Attribute (de)buff) [potency]:
  * bravery, cowardice, heavy (-move spd), slow, hasted, protect/shell (phys/mag def)

**Implicit (modify unit on buff update)**
* On_ (HoT/DoT) [potency]:
  * poison, burning, bleeding, regen

**Just check status bit**
* On_ (Death Sentence):
  * doom, gradual petrify/slow numb #once duration ends, replace with final form
* OnTurn:
  * doubling/trippling (multiple actions per turn)
* OnAction:
	* sleep, stunned/paralzyed/stopped/silenced/disabled/immobilized/petrified/dread, (prevent or restrict types of actions can take)
	* confuse/berserk (#???[random]???# action taken or effective team),
	* charm, controlled (change effective team)
	* overheating (take dmg/die if take action) #???[potency]???#
* OnAttack [potency]:
  * blind (-acc, every Nth atk misses or hits other target, etc), enlarge/mini (-acc +atk +def +every Nth auto-hits)
	  * ^^ psuedo potency that works with duration to determine when to set flag
* OnAttacked:
  * sleep, (phys/mag) blinking, reflecting, floating, decoyed (avoid next atk)

**Unit needs to lookup buff during action**
* OnDamage [potency?]:
  * empowered-for-dmg-type (eg. en-holy, en-dark)
* OnDamaged [potency?]:
  * vulnerable-to-dmg-type (eg. oiled/wet/frozen)
* OnDamaged/OnHealed/OnStatused [linked unit]:
  * guarded (defender)
  * life-link (ally/enemy also loses/gains hp)
  * synchronize (ally/enemy also gains status)

### Buff/Effects Implementation
-----------------------
**On the unit**

Unit checks if affected by an effect with simple bit flag check for majority of buffs.
Only needs to lookup buff if additional data is required (eg. potency or linked unit).

    EffectsBitFlags (64b) -- quick check for presence of certain status effect

**Separate**

Keep an array of all effects so we can update them in vectorized fashion.
Keep sorted by unit it pertains to for improved cache performance (when effects need to modify unit's bitflags, when unit needs to lookup its buffs, and reduces size as we don't store unit ids).
Additionally keep lookup of where in the array an unit's effects start and end.

    UnitId2BuffArrayRange :: Map UnitId (StartIdx, EndIdx)
    EffectsArray -- array of effects, sorted by unit
