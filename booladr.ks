// booster landing
// with full hoverslam without hovering
//
// ensure all is like we want it to be
// LATLNG(-0.0972077635067718, -74.5576726244574)
CLEARSCREEN.
sas off.
rcs on.
SET MYTHROTTLE TO 0.
SET MYSTEERING TO HEADING(90, 90).

// variables to change from rocket to rocket
set heightOffset to 30.27449. // 6.8.

// more or less environmental variables
set landspot to latlng(-0.0972075468722493, -74.5576849138598).
lock mass to ship:mass.
lock vert to ship:verticalspeed.
lock hori to ship:groundspeed.
lock aspeed to ship:airspeed.
lock g to ship:sensors:grav:mag.
// lock g to constant:g * body:mass / body:radius^2. 
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
set lastLat to 0.

function setang {
    parameter angle.
    set angleval to 45. // choose 80 if gheight > 25000 else
    if angle < (angleval*-1) {
        return angleval*-1.
    } else if angle > angleval {
        return angleval.
    } else {
        return angle.
    }
}

// if we want to land safely, we have to kill off hori speed
when getretrograde and puttedimp then {
    if gheight > 60 or MYTHROTTLE < 0.1 { // and MYTHROTTLE < 0.1
        print "trying to adjust the impact" at (0, 1).
        set lngangle to (-30 / -0.05*addons:tr:impactpos:lng + 44737.2). // (-30 / -0.05*addons:tr:impactpos:lng + 44737.2)
        set latangle to ((100 / -0.0878) * addons:tr:impactpos:lat - 110.47835990888383). //  ((30 / -0.0878) * addons:tr:impactpos:lat - 33.21184510250569) // 40 : 44.19134396355353 // 60 : 66.2870159453303 // 100 : 110.47835990888383

        print "lng         : " + lngangle at (0, 9).
        print "lat         : " + latangle at (0, 10).
        set lngangle to setang(lngangle).
        set latangle to setang(latangle).
        print "lng bettered: " + lngangle at (0, 11).
        print "lat bettered: " + latangle at (0, 12).
        set lngSteer to angleAxis(lngangle, srfRetrograde:starvector)*srfRetrograde. // y = -238,13x + 17753
        set latSteer to angleAxis(latangle, lngSteer:upvector)*lngSteer.
        set MYSTEERING to latSteer.
    } else {
        print "executing retrograde" at (0, 1).
        set MYSTEERING to ship:srfretrograde.
    }
    preserve.
}
when not getretrograde and puttedimp then {
    print "executing facing up " at (0, 1).
    set mysteering to heading(90, 90).
    preserve.
}

when gheight <= 0 and vert < 1 and vert > -1 and hori < 5 and not landed then {
    set MYTHROTTLE to 0.
    set landed to true.
    preserve.
}

// _____main code______

// set puttedimp to true.
// set impact
print("setting impact...") at (0, 0).
if addons:tr:available {
    until puttedimp {
        if addons:tr:hasimpact {
            // wenn der impact schon richtig ist oder wir zu tief sind lassen wir es
            if addons:tr:impactpos:lng < -74.8 or gheight < burnDist + 150 {
                print("did not modify the imapct") at (0, 0).
                break.
            }
            set MYSTEERING to heading(270, 1).
            set targetDir to vAng(heading(270, 1):vector, ship:facing:vector).

            if targetDir <= 10 {
                set MYTHROTTLE to 1.
                wait until addons:tr:impactpos:lng < -74.8. // wait til apoapsis is near the ksc
                set MYTHROTTLE to 0.
                print("setted impact near the ksc!") at (0, 0).
                set puttedimp to true. // brauche nur eins von beiden puttedimp oder break //TODO
                break. // oben im until statement könnte ich auch einfach false schreiben
            }
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
