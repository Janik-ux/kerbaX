// starship landing on kerbin
// ensure all is like we want it
CLEARSCREEN.
sas off.
rcs on.
SET MYTHROTTLE TO 0.
SET MYSTEERING TO HEADING(90, 90).

// variables to change from rocket to rocket
set heightOffset to 20.51610.

// more or less environmental variables
lock mass to ship:mass.
lock vert to ship:verticalspeed.
lock hori to ship:groundspeed.
lock landingthrust to ship:partstagged("landingengine")[0]:availableThrust + ship:partstagged("landingengine")[1]:availableThrust + ship:partstagged("landingengine")[2]:availableThrust.
// lock g to ship:sensors:grav:mag.
lock g to constant:g * body:mass / body:radius^2. 
lock gheight to alt:radar - heightOffset. // height over ground
lock maxaccel to (landingthrust / ship:mass) - g.
lock burnDist to ship:verticalspeed^2 / (2 * maxaccel).		// The distance the burn will require
lock idealHoverslamThrottle to burnDist / gheight.			// Throttle required for perfect hoverslam
lock timeTilImpact to gheight / abs(ship:verticalspeed).		// Time until impact, used for landing gear
// lock apoapsis to alt:apoapsis.
lock TWR to landingthrust / mass.

// ship variables
LOCK STEERING TO MYSTEERING.
LOCK THROTTLE TO MYTHROTTLE.
lock getretrograde to hori > 1 and gheight > 20. // wenn landen dann hor speed versuchen auszulöschen, aber nur wenn vert speed nicht dabei ist, umzuflippen
set landed to false.    // says if craft has landed
set bellyflip to false.
set flightmod to 0.
// set puttedimp to false. // do we have an impact?


function countdown {
    parameter count. // is 10.
    PRINT "Counting down:".
    FROM {count.} UNTIL count = 0 STEP {SET count to count - 1.} DO {
        PRINT "..." + count.
        WAIT 0.85.
    }
}

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

// if we want to land safely, we have to kill off hori speed
when getretrograde and bellyflip then {
    print "executing retrograde" at (0, 1).
    set MYSTEERING to ship:srfretrograde.
    preserve.
}
when not getretrograde and bellyflip then {
    print "executing facing up " at (0, 1).
    set mysteering to heading(90, 90).
    preserve.
}

when gheight <= 0 and vert < 1 and vert > -1 and hori < 5 and not landed then {
    set MYTHROTTLE to 0.
    set landed to true.
    preserve.
}

// _________ main code _______

// // set impact NOCH VAR PUTTEDIMP SETZEN
// if addons:tr:available {
//     until puttedimp {
//         if addons:tr:hasimpact {
//             set MYSTEERING to heading(270, 1).
//             wait (2).
//             set MYTHROTTLE to 1.
//             wait until addons:tr:impactpos:lng < -74.5576726244574. // wait til apoapsis is near the ksc
//             set MYTHROTTLE to 0.
//             print("setted impact near the ksc!") at (0, 0).
//             set puttedimp to true. // brauche nur eins von beiden puttedimp oder break //TODO
//             break. // oben im until statement könnte ich auch einfach false schreiben
//         } else {
//             set mysteering to ship:srfRetrograde.
//             set mythrottle to 1.
//         }
//     }

// } else {
//     clearScreen.
//     print("we have no addon, so stage is waiting til 15km above surface. \n If this not happens because for example the stage is in orbit, the script is running endless").
// }

// making landing engines ready
for eng in ship:partstagged("LandingEngine") {
    eng:activate().
    print "engines activated" at (0, 0).
}

print("waiting til the height is under 5km.") at (0, 0).
set MYSTEERING to heading(90, 0).
wait until gheight < 5000.
clearScreen.
print "passed 5000 meters" at (0, 0).

until bellyflip {
    print "burnDist:                     " + burnDist + "m      " at (0, 3).
    print "TWR:                          " + TWR + "      " at (0, 4).
    print "maxaccel:                     " + maxaccel + "m/s     " at (0, 5).
    print "predicted time till impact:   " + addons:tr:timetillimpact + "s     " at (0, 6).
    print "time til impact from gheight: " + timeTilImpact + "s     " at (0, 7).
    set finalburndist to choose 500 if burndist < 500 else burndist + 100. // the numbers are guessed. maybe with formula to work on all bodies. // we need some time to bellyflip
    if(gheight < finalburnDist) {
        clearScreen.
        print "bellyflip and landingburn" at (0, 0).
        rcs on.
        set MYTHROTTLE to idealHoverslamThrottle.
        set bellyflip to true.
        break.       
    }
    wait 0.001.
}

// do hoverslam
until gheight < 50 {
    set MYTHROTTLE to idealHoverslamThrottle.
    print "throttle: " + MYTHROTTLE at (0, 3).
}
gear on.
clearScreen.
print "I am hovering." at (0, 0).

// hover
until landed {
    set MYTHROTTLE to ((mass) * (g - VERT) / ship:availablethrust) - 0.05.
    print "mass:               " + mass                 + "      " at (0, 3).
    print "thrust:             " + ship:availablethrust + "      " at (0, 4).
    print "mythrottle:         " + MYTHROTTLE           + "      " at (0, 5).
    print "height over ground: " + gheight              + "      " at (0, 6).
}

brakes off.
clearScreen.
print "Starship (hopefully) landed".

