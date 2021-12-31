// starship landing on kerbin
// ensure all is like we want it
CLEARSCREEN.
sas off.
rcs on.
SET MYTHROTTLE TO 0.
SET MYSTEERING TO HEADING(90, 90).

// variables to change from rocket to rocket
set heightOffset to 21.51610.

// more or less environmental variables
lock mass to ship:mass.
lock vert to ship:verticalspeed.
lock hori to ship:groundspeed.
lock aspeed to ship:airspeed.
lock aerobrake to body:atm:exists.
lock landingthrust to ship:availableThrust.// choose ship:partstagged("engAtm")[0]:availableThrust + ship:partstagged("engAtm")[1]:availableThrust + ship:partstagged("engAtm")[2]:availableThrust if aerobrake else ship:partstagged("engVac")[0]:availableThrust + ship:partstagged("engVac")[1]:availableThrust + ship:partstagged("engVac")[2]:availableThrust.
// lock g to ship:sensors:grav:mag.
lock g to constant:g * body:mass / body:radius^2. 
lock gheight to alt:radar - heightOffset. // height over ground
lock maxaccel to (landingthrust / mass) - g.
lock burnDist to aspeed^2 / (2 * maxaccel).		// The distance the burn will require
lock idealHoverslamThrottle to burnDist / gheight.			// Throttle required for perfect hoverslam
lock timeTilImpact to gheight / abs(ship:verticalspeed).		// Time until impact, used for landing gear
// lock apoapsis to alt:apoapsis.
lock TWR to landingthrust / mass * g.
lock hoverheight to choose 140 if aerobrake else 20.
// lock landingthrottle 

// ship variables
LOCK STEERING TO MYSTEERING.
LOCK THROTTLE TO MYTHROTTLE.
lock getretrograde to hori > 1 and gheight > 20. // wenn landen dann hor speed versuchen auszulöschen, aber nur wenn vert speed nicht dabei ist, umzuflippen
set landed to false.    // says if craft has landed
set bellyflip to true.
set flightmod to 0.
set puttedimp to false. // do we have an impact?
set atmOn to false.


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
    set mysteering to heading(90, 90):vector + (heading(90, 90):vector + (heading(90, 90):vector + (heading(90, 90):vector + ship:srfretrograde:vector))).
    preserve.
}

when aerobrake and ship:altitude < ship:body:atm:height then {
    if not atmOn = true {
        from {local i is 1.} until i = 4 step {set i to i+1.} do {
            if ship:partstagged("EngAtm"+i):length > 0 {
                ship:partstagged("EngAtm"+i)[0]:activate().
                print "activating engine"+i at (0, 18).
            }
            else {
                print "could not activate engine"+i+" (not found)" at (0, 18).
            }
        }
        set atmOn to true.
        for eng in ship:partstagged("EngVac") {
        eng:shutdown().
    }
    print "Vac engines shutted down" at (27, 0).
    }
    if TWR > 200 {
        ship:partstagged("EngAtm3")[0]:shutdown().
        print "using (two) Atm engines." at (0, 0).
    }
    //wait 0.3.
    if TWR > 200 {
        ship:partstagged("EngAtm2")[0]:shutdown().
        print "using (one) Atm engine." at (0, 0).
    }
    
    //wait 5.
    preserve.
}
when (not aerobrake) or (aerobrake and ship:altitude > ship:body:atm:height) then {
    for eng in ship:partstagged("EngVac") {
        eng:activate().
    }
    for eng in ship:partstagged("EngAtm") {
        eng:shutdown().
    }
    set atmOn to false.
    print "Vac engines activated, Atm engines shutted down" at (0, 0).
    // wait 5.
    preserve.
}


when gheight <= 0.5 and vert < 1 and vert > -1 and hori < 2 and not landed then {
    set MYTHROTTLE to 0.
    set landed to true.
    preserve.
}

// _________ main code _______

// print aerobrake at (0, 10).
// making landing engines ready
// if aerobrake {
//     for eng in ship:partstagged("EngAtm") {
//         eng:activate().
//     }
//     for eng in ship:partstagged("EngVac") {
//         eng:shutdown().
//     }
//     print "Atm engines activated, Vac engines shutted down" at (0, 0).
// } else {
//     for eng in ship:partstagged("EngVac") {
//         eng:activate().
//     }
//     for eng in ship:partstagged("EngAtm") {
//         eng:shutdown().
//     }
//     print "Vac engines activated, Atm engines shutted down" at (0, 0).
// }


// set impact on location //TODO
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

wait 0.8.
if addons:tr:available {
    until puttedimp {
        if addons:tr:hasimpact {
            set MYTHROTTLE to 0.
            print("we have an impact. going on!") at (0, 0).
            set puttedimp to true. // brauche nur eins von beiden puttedimp oder break //TODO
            break. // oben im until statement könnte ich auch einfach false schreiben
        } else {
            set mysteering to ship:srfRetrograde.
            set targetDir to vAng(ship:srfretrograde:vector, ship:facing:vector).
            if targetDir <= 10 {
                set mythrottle to 1.
            }
            wait 0.1.
        }
    }

} else {
    clearScreen.
    print("we have no addon, so stage is waiting til 15km above surface. \n If this not happens because for example the stage is in orbit, the script is running endless").
}

print("waiting til the height is under 7km.                    ") at (0, 0).
if aerobrake {
    set MYSTEERING to heading(90, 0).
    set bellyflip to false.
    print "doing aerobrake        " at (0, 1).
    lock untilstatement to bellyflip.
} else {
    lock untilstatement to false.
}

until gheight < 7000 {
    print "getretrorade: " + getretrograde at (0, 3).
    print "bellyflip:    " + bellyflip at (0, 4).
    print "aerobrake:    " + aerobrake at (0, 5).
    print "thrust:       " + ship:availablethrust at (0, 6).
    print "TWR:          " + TWR at (0, 7).
    set MYSTEERING to choose ship:srfretrograde if not aerobrake else angleAxis(90, ship:prograde:upvector)*ship:prograde:upvector. //  vxcl(ship:prograde:vector, ship:up:vector)
    wait 0.5.
}
clearScreen.
print "passed 7000 meters" at (0, 0).
print "bellyflip: " + bellyflip at (0, 10).

until untilstatement {
    print "burnDist:                     " + burnDist + "m      " at (0, 3).
    print "TWR:                          " + TWR + "      " at (0, 4).
    print "maxaccel:                     " + maxaccel + "m/s     " at (0, 5).
    print "predicted time till impact:   " + addons:tr:timetillimpact + "s     " at (0, 6).
    print "time til impact from gheight: " + timeTilImpact + "s     " at (0, 7).
    print "airspeed:                     " + aspeed + "m/s      " at (0, 8).
    set fburndist to choose burnDist if burndist > 0 else burndist*-1.
    set ffburndist to choose 500 if fburndist < 500 else fburndist. // the numbers are guessed. maybe with formula to work on all bodies. // we need some time to bellyflip
    if(gheight < ffburndist) {
        clearScreen.
        print "bellyflip and landingburn" at (0, 0).
        rcs on.
        set MYTHROTTLE to choose idealHoverslamThrottle if idealHoverslamThrottle > 0 else idealHoverslamThrottle * -1.
        set bellyflip to true.
        break.       
    }
    wait 0.001.
}

// do hoverslam
until gheight < hoverheight {
    set MYTHROTTLE to choose idealHoverslamThrottle if idealHoverslamThrottle > 0 else idealHoverslamThrottle * -1.
    print "throttle: " + MYTHROTTLE at (0, 3).
    print "gheight:  " + gheight at (0, 4).
    print "TWR:      " + TWR at (0, 5).
}
gear on.
clearScreen.
print "I am hovering." at (0, 0).

// hover
until landed {
    set MYTHROTTLE to ((mass) * (g - VERT) / ship:availablethrust) - 0.08 + flightmod.
    print "mass:               " + mass                 + "      " at (0, 3).
    print "thrust:             " + ship:availablethrust + "      " at (0, 4).
    print "mythrottle:         " + MYTHROTTLE           + "      " at (0, 5).
    print "height over ground: " + gheight              + "      " at (0, 6).
}

clearScreen.
print "Starship (hopefully) landed".
