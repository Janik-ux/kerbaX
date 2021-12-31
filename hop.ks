// hop
// with full hoverslam without hovering
//
// ensure all is like we want it to be
CLEARSCREEN.
sas off.
rcs on.
SET MYTHROTTLE TO 0.
SET MYSTEERING TO HEADING(90, 90).

// variables to change from rocket to rocket
set heightOffset to 9.845. // 6.8.

// more or less environmental variables
lock mass to ship:mass.
lock vert to ship:verticalspeed.
lock hori to ship:groundspeed.
// lock g to ship:sensors:grav:mag.
lock g to constant:g * body:mass / body:radius^2. 
lock gheight to alt:radar - heightOffset. // height over ground
lock maxaccel to (ship:availablethrust / ship:mass) - g.
lock burnDist to vert^2 / (2 * maxaccel).		// The distance the burn will require
lock idealHoverslamThrottle to burnDist / gheight.		// Throttle required for perfect hoverslam
lock timeTilImpact to gheight / abs(ship:verticalspeed).    // Time until impact, used for landing gear
// lock apoapsis to alt:apoapsis.
lock TWR to ship:availablethrust / mass.

// ship variables
LOCK STEERING TO MYSTEERING.
LOCK THROTTLE TO MYTHROTTLE.
lock getretrograde to hori > 1 and gheight > 40. // wenn landen dann hor speed versuchen auszulöschen, aber nur wenn vert speed nicht dabei ist, umzuflippen
set landed to false.    // says if craft has landed
set puttedimp to false. // do we have an impact?

// if we want to land safely, we have to kill off hori speed
when getretrograde and puttedimp then {
        print "executing retrograde" at (0, 1).
        set MYSTEERING to ship:srfretrograde.
    preserve.
}

when not getretrograde and puttedimp then {
    print "executing facing up " at (0, 1).
    set mysteering to heading(90, 90).
    preserve.
}

when gheight <= 0 and vert < 1 and vert > -1 and hori < 5 and not landed and puttedimp then {
    set MYTHROTTLE to 0.
    set landed to true.
    preserve.
}
print "hi".
set MYSTEERING to heading(0, 86).
set MYTHROTTLE to 1.
print gheight.
wait until gheight > 100.
set MYTHROTTLE to 0.
until vert <= 0 {
    print "vert:                     " + vert + "m/s      " at (0, 3).
}

set puttedimp to true.

// fly to (near) ground
// rcs off.
brakes on. // maybe set steering (or in when task)
print("waiting til the height is under 15km.") at (0, 0).
wait until gheight < 15000.

until false {
    print "burnDist:                     " + burnDist + "m      " at (0, 3).
    print "TWR:                          " + TWR + "      " at (0, 4).
    print "maxaccel:                     " + maxaccel + "m/s     " at (0, 5).
    print "predicted time till impact:   " + addons:tr:timetillimpact + "s     " at (0, 6).
    print "time til impact from gheight: " + timeTilImpact + "s     " at (0, 7).
    set fburndist to choose burnDist if burndist > 0 else burndist*-1.
    if(gheight < fburnDist) {
        clearScreen.
        print "doing hoverslam" at (0, 0).
        rcs on.
        set MYTHROTTLE to choose idealHoverslamThrottle if idealHoverslamThrottle > 0 else idealHoverslamThrottle * -1.
        break.
    }
    wait 0.001.
}

// do hoverslam
until landed {
    set MYTHROTTLE to choose idealHoverslamThrottle if idealHoverslamThrottle > 0 else idealHoverslamThrottle * -1.
    print "throttle: " + MYTHROTTLE at (0, 3).
    if gheight < 200 {
        gear on.
    }
}

brakes off.
clearScreen.
print "booster (hopefully) landed".