from cpython cimport bool

import random
import time

cdef bool DEBUG = False

cdef class State:
    cdef public int turn, nextUnitId
    cdef public str state
    cdef public list units
    def __init__( self ):
        self.turn = 0
        self.state = 'in progress'

        self.nextUnitId = 0
        self.units = []

    cdef addUnit( self, int team, int row ):
        self.nextUnitId += 1
        self.units.append( Unit( id=self.nextUnitId, team=team, row=row ) )

    cdef update( self ):
        cdef Unit u
        for u in self.units:
            u.update()

        if not any( True for u in self.units if u.team == 0 and u.isAlive ):
            self.state = 'Team 0 won'

        if not any( True for u in self.units if u.team == 1 and u.isAlive ):
            self.state = 'Team 1 won'

    cdef doTurn( self ):
        cdef Unit u, u_
        while self.state == 'in progress':
            u = self.units[0]
            for u_ in self.units:
                if u_.ct > u.ct:
                    u = u_

            if u.ct >= 100 and u.isAlive:
                break
            else:
                self.update()

        if self.state == 'in progress':
            self.turn += 1
            u.doTurn( self )

cdef class Unit:
    cdef public int id, ct, spd, hp, atk, heal, row, team
    cdef public bool isAlive
    def __init__( self, id=-1, team=0, row=0 ):
        self.id = id
        self.ct = id
        self.spd = 4
        self.hp = 100
        self.atk = 2
        self.heal = 1
        self.row = row
        self.team = team

        self.isAlive = True

    cpdef update( self ):
        if self.hp <= 0:
            self.isAlive = False

        if not self.isAlive:
            return

        self.ct += self.spd

    cdef doHeal( self, Unit a ):
        cdef int hp

        hp = min( self.heal, 100-a.hp )
        a.hp += hp
        if DEBUG: print '%d heals %d for %d hp' % ( self.id, a.id, hp )

    cdef doAttack( self, Unit e ):
        cdef int dist, dmg
        cdef float distF

        dist = e.row + self.row
        distF = 2. / dist
        dmg = int( self.atk * distF )
        e.hp -= dmg
        if DEBUG: print '%d attacks %d for %0.1f dmg' % ( self.id, e.id, dmg )

    cdef rndHeal( self, State st ):
        cdef Unit a
        cdef list hurt

        hurt = [ u for u in st.units if u.team == self.team and u.hp < 100 and u.isAlive ]
        if hurt:
            a = random.choice( hurt )
            self.doHeal( a )
        else:
            self.rndAttack( st )

    cdef rndAttack( self, State st ):
        cdef Unit e
        e = random.choice([ u for u in st.units if u.team != self.team and u.isAlive ])
        self.doAttack( e )

    cdef doTurn( self, State st ):
        self.ct -= 100

        if random.randint(1,2) == 1:
            self.rndAttack( st )
        else:
            self.rndHeal( st )

    def __str__( self ): return str(vars( self ))

##### Rendering
cdef render( State st ):
    cdef Unit u
    cdef int team0hp, team1hp, row

    print ( ' Turn %d ' % st.turn ).center( 80, '#' )
    for row in xrange( 5, 0, -1 ):
        renderRow([ u for u in st.units if u.row == row and u.team == 0 ])
    print '-'*80
    for row in xrange( 1, 6, +1 ):
        renderRow([ u for u in st.units if u.row == row and u.team == 1 ])

    team0hp = sum( u.hp for u in st.units if u.team == 0 and u.isAlive )
    team1hp = sum( u.hp for u in st.units if u.team == 1 and u.isAlive )
    print 'Team 0: %0.1f Team 1: %0.1f' % ( team0hp, team1hp )

cdef renderRow( list us ):
    if len( us ) == 0:
        s = '{empty}'
    else:
        s = ' '.join( showUnit( u ) for u in us )
    print s.center( 80 )

cdef showUnit( Unit u ):
    if not u.isAlive: return '<DEAD>'
    return '<%0.1f%% %d>' % ( u.hp, u.ct )

##### Test
cdef mkTest():
    st = State()

    for _ in xrange( 1 ):
        st.addUnit( team=0, row=4 )
        st.addUnit( team=1, row=4 )
    for _ in xrange( 2 ):
        st.addUnit( team=0, row=3 )
        st.addUnit( team=1, row=3 )
    for _ in xrange( 3 ):
        st.addUnit( team=0, row=2 )
        st.addUnit( team=1, row=2 )
    for _ in xrange( 5 ):
        st.addUnit( team=0, row=1 )
        st.addUnit( team=1, row=1 )

    return st

cdef cmain():
    cdef State st
    _ = render

    st = mkTest()

    t0 = time.time()
    for i in xrange( 1000000 ):
        #render( st )
        st.doTurn()
        if st.state != 'in progress': break
    dt = time.time() - t0
    tps = (st.turn / dt) /1000.

    print 'Stage %s on turn %d. Took %0.2f sec at %0.2f k turns/sec' % ( st.state, st.turn, dt, tps )

def main(): cmain()
