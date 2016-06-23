# litmus
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

##### Requirements for unit actions
- apply/remove instaneous effects to self or other units
  - dmg enemy
  - heal ally
- apply/remove ongoing effects to self or other units
  - add (de)buff to stats of other unit
  - dispell effect on another unit
