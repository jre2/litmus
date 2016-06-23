#![allow(dead_code)]
#![feature(iter_arith)]

#[derive(Debug)]
#[derive(PartialEq)]
enum GameStage { InProgress, Team0Won, Team1Won, }

#[derive(Debug)]
#[derive(PartialEq)]
#[derive(Clone)]
enum Team { Team0, Team1 }

use std::rc::Rc;
use std::cell::RefCell;

#[derive(Debug)]
struct State<'a> {
    turn : u32,
    stage : GameStage,

    next_unit_id : u32,
    units : Vec< Rc<RefCell<  Unit<'a> >> >,
}

#[derive(Debug)]
#[derive(Clone)]
struct Unit<'a> {
    id : u32,

    team : Team,
    row : u32,

    ct : i32,
    spd : i32,

    hp : i32,
    atk : i32,
    heal : i32,
    is_alive : bool,

    phantom : std::marker::PhantomData<&'a i32>,
}

impl<'a> State<'a> {
    fn new() -> State<'a> {
        State {
            turn : 0,
            stage : GameStage::InProgress,
            next_unit_id : 0,
            units : Rc::new( RefCell::new( Vec::new() )),
        }
    }
    fn add_unit( &mut self, team : Team, row : u32 ) -> &mut State<'a> {
        let u = Unit::new( self.next_unit_id, team, row );
        self.units.push( u );
        self.next_unit_id += 1;
        self
    }
    fn mk_test() -> State<'a> {
        let mut st = State::new();
        for _ in 0..1 {
            st.add_unit( Team::Team0, 4 );
            st.add_unit( Team::Team1, 4 );
        }
        for _ in 0..2 {
            st.add_unit( Team::Team0, 3 );
            st.add_unit( Team::Team1, 3 );
        }
        for _ in 0..3 {
            st.add_unit( Team::Team0, 2 );
            st.add_unit( Team::Team1, 2 );
        }
        for _ in 0..5 {
            st.add_unit( Team::Team0, 1 );
            st.add_unit( Team::Team1, 1 );
        }
        st
    }
    fn render( &self ) {
        for row in (1..5+1).rev() {
            let x = self.units.iter()
                .filter( |u| u.row==row && u.team == Team::Team0 )
                .map( |u| u.to_string() ).collect::<Vec<_>>().join(" ");
            println!("{}", x);
        }

        println!("{}", std::iter::repeat("-").take(80).collect::<String>() );

        for row in 1..5+1 {
            let x = self.units.iter()
                .filter( |u| u.row==row && u.team == Team::Team0 )
                .map( |u| u.to_string() ).collect::<Vec<_>>().join(" ");
            println!("{}", x);
        }

        let team0_hp = self.units.iter()
            .filter( |u| u.team == Team::Team0 && u.is_alive )
            .map( |u| u.hp )
            .sum::<i32>();
        let team1_hp = self.units.iter()
            .filter( |u| u.team == Team::Team1 && u.is_alive )
            .map( |u| u.hp )
            .sum::<i32>();
        println!("Team 0: {} Team 1: {}", team0_hp, team1_hp );
    }
    fn update( &mut self ) {
        let mut any_team0_alive = false;
        let mut any_team1_alive = false;

        for u in &mut self.units {
            u.update();
            if u.is_alive && u.team == Team::Team0 { any_team0_alive = true; }
            if u.is_alive && u.team == Team::Team1 { any_team1_alive = true; }
        }

        self.stage = GameStage::InProgress;
        if !any_team0_alive { self.stage = GameStage::Team1Won; }
        if !any_team1_alive { self.stage = GameStage::Team0Won; }
    }
    /*
    fn do_turn_unit( &mut self, uidx : usize ) {
        let ref u = self.units[ uidx ];
    }
    fn do_turn( &mut self ) {
        let x = & self.units[0];

        println!(" obj {}", x );
    }
    fn __do_turn( &mut self ) {
        let mut idx = None;

        while self.stage == GameStage::InProgress {
            for i in 0..self.units.len() {
                let ref u = self.units[i];
                if !u.is_alive { continue; }

                if let None = idx { idx = Some(i); }

                let ref best = self.units[ idx.unwrap() ];
                if u.ct > best.ct { idx = Some(i); }
            }

            if self.units[ idx.unwrap() ].ct >= 100 { break; }
            self.update();
            println!("updated state");
        }

        if self.stage == GameStage::InProgress {
            println!("do_turn with unit idx {} and obj {}", idx.unwrap(), self.units[ idx.unwrap() ] );
        }
    }
    fn _do_turn( &mut self ) {
        let mut id = None;
        while self.stage == GameStage::InProgress {
            id = match self.units.iter_mut().filter( |u| u.ct >= 100 && u.is_alive ).max_by_key( |u| u.ct ) {
                None => None,
                Some(u) => Some(u.id),
            };
            match id {
                None => self.update(),
                Some(_) => { break; }
            }
        }

        if self.stage == GameStage::InProgress {
            let u = self.units.iter_mut().filter( |u| u.id == id.unwrap() ).nth(0).unwrap();
            println!("do_turn with unit {}", u );
        }
    }
    fn ___do_turn( &mut self ) {
        while self.stage == GameStage::InProgress {
            let x = self.units.iter_mut()
                .filter( |u| u.ct >= 100 && u.is_alive )
                .max_by_key( |u| u.ct );
            match x {
                None => {
                    println!("pumping mid-turn events until some unit is ready");
                    self.update();
                }
                Some(u) => {
                    println!("unit {} now takes turn", u);
                    self.turn += 1;
                    //u.do_turn( self );
                    break;
                }
            }
        }
    }*/
    fn do_turn_unit( &mut self, u : &Unit ) {
        self.units[2].hp -= u.atk;
    }
    fn do_turn( &mut self ) {
        while self.units[0].ct < 100 { self.update(); }
        let u = self.units[0].clone();

        //self.do_turn_unit( &u );
        self.units[0].do_turn( self );
    }
}

impl<'a> std::fmt::Display for Unit<'a> {
    fn fmt( &self, f: &mut std::fmt::Formatter ) -> std::fmt::Result {
        write!( f, "<{}% {} ({})>", self.hp, self.ct, self.id )
    }
}

impl<'a> Unit<'a> {
    fn new( id : u32, team : Team, row : u32 ) -> Unit<'a> {
        Unit {
            id : id, team : team,
            row : row,
            ct : id as i32,
            spd : 4,
            hp : 100,
            atk : 2, heal : 1,
            is_alive : true,
            phantom : std::marker::PhantomData,
        }
    }
    fn update( &mut self ) {
        if self.hp <= 0 { self.is_alive = false; }

        if self.is_alive {
            self.ct += self.spd
        }
    }
    fn do_turn( &mut self, st : &mut State ) {
        println!( "Unit::do_turn {}", self );
    }
}

fn main() {
    let mut st = State::mk_test();
    for _ in 0..2 {
        if st.stage != GameStage::InProgress { break; }

        st.do_turn();
        st.render();
    }
    println!("Stage {:?} on turn {}. {} sec {} turns/sec", st.stage, st.turn, -1, -1 );
}
