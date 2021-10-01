// testbooster
// ensure all is like we want it
CLEARSCREEN.
sas off.
rcs on.
SET MYTHROTTLE TO 0.
SET MYSTEERING TO HEADING(90, 90). 

lock mass to ship:mass.
// lock g to ship:sensors:grav:mag.
lock g to ship:body:mu / ship:body:position:mag ^ 2.
LOCK STEERING TO MYSTEERING.
LOCK THROTTLE TO MYTHROTTLE.
LOCK VERT TO SHIP:VERTICALSPEED.
lock HORI to ship:groundspeed.
lock gheight to alt:radar. // height over ground 
lock apoapsis to alt:apoapsis.
lock getretrograde to hori > 1 and gheight > 4 and vert < -10 and vert > -50.
lock TWR to ship:availablethrust / (mass * g).
set landed to false. // says if craf has landed
set flightmod to 0.
lock increasing to VERT > 45. //TODO ---V
lock landingthrust to ship:partstagged("landingengine")[0]:availableThrust + ship:partstagged("landingengine")[1]:availableThrust + ship:partstagged("landingengine")[2]:availableThrust.
set puttedimp to false.

// steigen
on ag8 {
    set flightmod to flightmod + 0.1.
    set landed to false.
    preserve.
}

// hovern
on ag9 {
    set flightmod to 0.
    preserve.
}

// sinken
on ag10 {
    set flightmod to flightmod - 0.1.
    preserve.
}

// wenn landen dann hor speed versuchen auszulöschen, aber nur wenn vert speed nicht dabei ist, umzuflippen
when getretrograde and puttedimp then {
    set MYSTEERING to ship:srfretrograde.
    preserve.
}

when not getretrograde and puttedimp and ship:geoposition:lng < -74 then {
    print "executing facing up" at (0, 8).
    set mysteering to heading(90, 90).
    preserve.
}

when gheight <= 0 and not landed then {
    set MYTHROTTLE to 0.
    set landed to true.
    preserve.
}

// _____main code______

if addons:tr:available {
    set MYSTEERING to heading(270, 1).
    wait (2).
    until puttedimp {
        if addons:tr:hasimpact {
            wait (1).
            set MYTHROTTLE to 1.
            wait until addons:tr:impactpos:lng < -74.5576726244574. // wait til apoapsis is near the ksc
            set MYTHROTTLE to 0.
            set MYSTEERING to ship:srfretrograde.
            print("setted impact near the ksc!").
            set puttedimp to true. // brauche nur eins von beiden
            break. // oben im until statement könnte ich auch einfach false schreiben
        } else {
            set mysteering to ship:srfRetrograde.
            set mythrottle to 1.
        }
    }

} else {
    print("we have no addon, so stage is waiting til 5km above surface. \n If this not happens because for example the stage is in orbit, the script is running endless").
}

brakes on.
print("waiting til the height is under 5km.").
wait until gheight < 6000.

until false {
    // do needed calculations
    // set timeTilImp to sqrt(2 * gheight * 1 / g * VERT).              // calculate time til impact
    // set finalspeed to VERT + timeTilImp * g.                         // impact speed
    set maxaccel   to TWR * g - g.                                   // maximal acceleration against the surface 
    set burntime   to (VERT/maxaccel) *-1.                                 // time to kill of vertical speed
    set burndist   to (- VERT * burntime + 1/2*g*(burntime*burntime)). // falling way to kill of vertical speed
    print "false burndist:" + burndist at (0, 11).
    set burndist to choose burndist *-1 if burndist < 0 else burndist.
    print "burndist: " + burndist at (0, 7).
    print "burntime: " + burntime at (0, 8).
    print "TWR: " + TWR at (0, 9).
    print "maxaccel: " + maxaccel at (0, 10).
    if(burndist - 1500 > gheight) {
        break.
    }
}

until landed {
    set MYTHROTTLE to ((mass) * (g - VERT) / ship:availablethrust) + flightmod.
    print "flightmod: " + flightmod at (0, 6).
    print "mass: " + mass at (0, 7).
    print "thrust: " + ship:availablethrust at (0, 8).
    print "mythrottle: " + MYTHROTTLE at (0, 9).
    print "height over ground: " + gheight at (0, 10).
}
