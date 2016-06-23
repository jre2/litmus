import random
import time

DEBUG = False

class State:
    def __init__( self ):
        self.turn = 0
        self.state = 'in progress'

        self.nextUnitId = 0
        self.units = []

    def addUnit( self, team, row ):
        self.nextUnitId += 1
        self.units.append( Unit( id=self.nextUnitId, team=team, row=row ) )

    def update( self ):
        for u in self.units:
            u.update()

        if not any( True for u in self.units if u.team == 0 and u.isAlive ):
            self.state = 'Team 0 won'

        if not any( True for u in self.units if u.team == 1 and u.isAlive ):
            self.state = 'Team 1 won'

    def doTurn( self ):
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

class Unit:
    def __init__( self, id=-1, team=0, row=0 ):
        self.id = id
        self.ct = id
        self.spd = 4
        self.hp = 100
        self.atk = 1
        self.heal = 1
        self.row = row
        self.team = team

        self.isAlive = True

    def update( self ):
        if self.hp <= 0:
            self.isAlive = False

        if not self.isAlive:
            return

        self.ct += self.spd

    def doHeal( self, a ):
        hp = min( self.heal, 100-a.hp )
        a.hp += hp
        if DEBUG: print '%d heals %d for %d hp' % ( self.id, a.id, hp )

    def doAttack( self, e ):
        dist = e.row + self.row
        distF = 2. / dist
        dmg = int( self.atk * distF )
        e.hp -= dmg
        if DEBUG: print '%d attacks %d for %0.1f dmg' % ( self.id, e.id, dmg )

    def doTurn( self, st ):
        self.ct -= 100

        def rndHeal():
            hurt = [ u for u in st.units if u.team == self.team and u.hp < 100 and u.isAlive ]
            if hurt:
                a = random.choice( hurt )
                self.doHeal( a )
            else:
                rndAtk()

        def rndAtk():
            e = random.choice([ u for u in st.units if u.team != self.team and u.isAlive ])
            self.doAttack( e )

        random.choice([ rndAtk, rndHeal ])()

    def __str__( self ): return str(vars( self ))

##### Rendering
def render( st ):
    print ( ' Turn %d ' % st.turn ).center( 80, '#' )
    for row in xrange( 5, 0, -1 ):
        renderRow([ u for u in st.units if u.row == row and u.team == 0 ])
    print '-'*80
    for row in xrange( 1, 6, +1 ):
        renderRow([ u for u in st.units if u.row == row and u.team == 1 ])

    team0hp = sum( u.hp for u in st.units if u.team == 0 and u.isAlive )
    team1hp = sum( u.hp for u in st.units if u.team == 1 and u.isAlive )
    print 'Team 0: %0.1f Team 1: %0.1f' % ( team0hp, team1hp )

def renderRow( us ):
    if len( us ) == 0:
        s = '{empty}'
    else:
        s = ' '.join( showUnit( u ) for u in us )
    print s.center( 80 )

def showUnit( u ):
    if not u.isAlive: return '<DEAD>'
    return '<%0.1f%% %d>' % ( u.hp, u.ct )

##### Test
def mkTest():
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

def main():
    st = mkTest()

    t0 = time.time()
    for i in xrange( 100000 ):
        #render( st )
        st.doTurn()
        if st.state != 'in progress': break
    dt = time.time() - t0

    print st.state, 'on turn', st.turn, st.turn/dt, 'turns/sec'
