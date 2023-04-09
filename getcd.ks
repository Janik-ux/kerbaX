@lazyGlobal off.
clearScreen.
// assumes rocket is in free flight retrograde
// lock g to constant:g * body:mass / body:radius^2.
until false {
    local atmo to ship:body:atm.
    print "p: " + atmo:altitudepressure(ship:altitude)*constant:atmtokpa*1000 at (0, 7).
    local rho to (atmo:molarmass*(atmo:altitudepressure(ship:altitude)*constant:atmtokpa*1000))/(8.31446*atmo:alttemp(ship:altitude)).
    print "rho: " + rho at (0, 8).
    local delay to 1.
    local v1 to ship:velocity:surface.
    print "v1: " + v1 at (0, 1).
    wait delay.
    local v2 to ship:velocity:surface.
    print "v2: " + v2 at (0, 2).
    local a to (v2-v1)/delay.
    local v to (v1+v2)/2.
    print "a: " + a at (0, 3).
    print "v: " + v at (0, 4).
    local g to ship:sensors:grav.
    print "g: " + g at (0, 9).
    local resta to a-g.
    print "drag a: " + resta:mag at (0, 5).
    local cdva to (ship:mass*a)/((1/2)*rho*v:sqrmagnitude).
    print "cd: " + cdva at (0, 6).
}