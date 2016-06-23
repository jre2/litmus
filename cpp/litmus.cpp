#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>

#include <vector>
#include <algorithm>
#include <functional>

#include <string>
#include <iostream>
#include <sstream>

#include <chrono>

#define DEBUG false

struct Unit;
struct State;

enum class GameStage { InProgress, Team0Won, Team1Won };
enum class Team { Team0, Team1 };

struct State {
  State() : turn(0), stage(GameStage::InProgress), nextUnitId(0) {};
  void update();
  void doTurn();

  int turn;
  GameStage stage;

  int nextUnitId;
  std::vector<Unit> units;
};

struct Unit {
  Unit( int id, Team team, int row ) : id(id), team(team), row(row) {
    ct = id;
    spd = 4;

    hp = 100;
    atk = 2;
    heal = 1;
    isAlive = true;
  };
  void update();
  void doTurn( State* st );

  int id;

  int ct;
  int spd;

  bool isAlive;
  int hp;
  int atk;
  int heal;

  Team team;
  int row;
};

/*
 * Creating test state
 */

void addUnit( State& st, Team team, int row ) {
  Unit u( st.nextUnitId++, team, row );
  st.units.push_back( u );
}

State mkTest() {
  State st;

  for (int i=0; i<1; i++ ) {
    addUnit( st, Team::Team0, 4 );
    addUnit( st, Team::Team1, 4 );
  }
  for (int i=0; i<2; i++ ) {
    addUnit( st, Team::Team0, 3 );
    addUnit( st, Team::Team1, 3 );
  }
  for (int i=0; i<3; i++ ) {
    addUnit( st, Team::Team0, 2 );
    addUnit( st, Team::Team1, 2 );
  }
  for (int i=0; i<5; i++ ) {
    addUnit( st, Team::Team0, 1 );
    addUnit( st, Team::Team1, 1 );
  }

  return st;
}

/*
 * Rendering
 */
std::string show( Unit u );
std::string show( State st );

std::string show( State st ) {
  std::ostringstream s;

  s << "###################################" << " Turn " << st.turn << " ####################################" << std::endl;

  for (int row=5; row>0; row--) {
    for (Unit u : st.units) {
      if (u.team == Team::Team0 && u.row == row) {
        s << show( u ) << " ";
      }
    };
    s << std::endl;
  };

  s << "--------------------" << std::endl;

  for (int row=1; row<=5; row++) {
    for (Unit u : st.units) {
      if (u.team == Team::Team1 && u.row == row) {
        s << show( u ) << " ";
      }
    };
    s << std::endl;
  };

  int team0hp = 0;
  int team1hp = 0;
  for (Unit& u : st.units) {
    if (!u.isAlive)
      continue;

    if (u.team == Team::Team0)
      team0hp += u.hp;
    else if (u.team == Team::Team1)
      team1hp += u.hp;
  }
  s << "Team 0: " << team0hp << " Team 1: " << team1hp << std::endl;

  return s.str();
};

std::string show( Unit u ) {
  std::ostringstream s;
  if (u.isAlive)
    s << "<" << u.hp << "% " << u.ct << ">";
  else
    s << "<DEAD>";
  return s.str();
};

/*
 * Updating
 */
void State::update() {
  bool anyTeam0Alive = false;
  bool anyTeam1Alive = false;

  for( Unit& u : units ) {
    u.update();

    if ( u.isAlive && u.team == Team::Team0 )
      anyTeam0Alive = true;
    else if ( u.isAlive && u.team == Team::Team1 )
      anyTeam1Alive = true;
  }

  stage = GameStage::InProgress;
  if (!anyTeam0Alive)
    stage = GameStage::Team1Won;
  if (!anyTeam1Alive)
    stage = GameStage::Team0Won;
};

void Unit::update() {
  if (hp <= 0) {
    isAlive = false;
  }
  if (!isAlive)
    return;
  ct += spd;
};

/*
 * Simulate Turns
 */
void State::doTurn() {
  Unit* next = NULL;
  while (stage == GameStage::InProgress) {
    // get unit with highest initiative
    for (Unit& u : units) {
      if (!u.isAlive)
        continue;
      if (!next || u.ct > next->ct)
        next = &u;
    }

    // if highest init is insufficient, pump mid-turn updates
    if (next->ct >= 100)
      break;
    else
      update();
  }

  if (stage == GameStage::InProgress) {
    turn += 1;
    next->doTurn( this );
  }
}

void doAttack( Unit* me, Unit* e ) {
  auto dist = me->row + e->row;
  float distF = 2.0f / dist;
  int dmg = int( me->atk * distF );
  e->hp -= dmg;
}
void doHeal( Unit* me, Unit* a ) {
  auto hp = std::min( me->heal, 100-a->hp );
  a->hp += hp;
}

template<class T>
T* choice( std::vector<T>& xs ) {
  if ( xs.size() == 0 )
    return NULL;
  int idx = rand() % xs.size();
  return &xs[ idx ];
}

// Get a random element of a vector given a filter predicate. NULL if no matches
template<class T>
T* filted_temp_choice( std::vector<T>& xs, std::function<bool (Unit&)> pred ) {
  std::vector<T*> ys;
  for ( auto& x : xs ) {
    if ( pred(x) )
      ys.push_back( &x );
  }

  if ( ys.size() == 0 )
    return NULL;
  int idx = rand() % ys.size();
  return ys[ idx ];
}

template<class T>
T* two_pass_choice( std::vector<T>& xs, std::function<bool (Unit&)> pred ) {
  int numMatch = 0;
  for ( auto& x : xs ) {
    if ( pred(x) )
      numMatch++;
  }

  if (numMatch == 0) return NULL;

  int skip = rand() % numMatch;
  for ( auto& x : xs ) {
    if ( pred(x) ) {
      if (skip == 0)
        return &x;
      skip--;
    }
  }
  assert( false ); // should be impossible
}

template<class T, class S>
T* choice( std::vector<T>& xs, S pred ) {
  T* y = NULL;
  int seen = 0;

  for ( auto& x : xs ) {
    if ( !pred(x) ) continue;

    seen++;
    if (rand() % seen == 0) y = &x; // 1/1, 1/2, 1/3, 1/4, etc
  }
  return y;
}

void rndAttack( Unit* me, State* st ) {
  auto e = choice( st->units, [&me](Unit& u){ return u.isAlive && u.team != me->team; } );

  assert( e != NULL ); // should only occur if one side has already won
  if (DEBUG) printf("%d Attacking random enemy %d\n", me->id, e->id);
  doAttack( me, e );
};

void rndHeal( Unit* me, State* st ) {
  auto a = choice( st->units, [&](Unit& u){ return u.isAlive && u.team == me->team && u.hp < 100; } );

  // if no allies to heal, attack instead
  if (!a) {
    if (DEBUG) printf( "Can't heal, attacking instead >> " );
    return rndAttack( me, st );
  }

  if (DEBUG) printf("%d Healing random ally %d\n", me->id, a->id);
  doHeal( me, a );
};

void Unit::doTurn( State* st ) {
  ct -= 100;

  int rndAction = rand() % 2 + 1;
  switch (rndAction) {
    case 1:
      rndAttack( this, st );
      break;
    case 2:
      rndHeal( this, st );
      break;
  }
};


/*
 * Driver
 */

int main( int argc, char** argv ) {
  srand( time(NULL) );

  State st = mkTest();

  auto t0 = std::chrono::steady_clock::now();
  for (int i=0; i<5000000; i++) {
    if (st.stage != GameStage::InProgress)
      break;

    st.doTurn();
    //std::cout << show( st );
  }
  auto t = std::chrono::steady_clock::now();
  auto dt = std::chrono::duration_cast< std::chrono::milliseconds >( t-t0 ).count();

  printf( "Stage %d on turn %d, %0.5f sec, %0.2f turn/sec\n", (int)st.stage, st.turn, dt/1000.0f, st.turn/(dt/1000.0f) );

  return 0;
}
