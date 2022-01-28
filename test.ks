set landspot to latlng(-0.0972075468722493, -74.5576849138598).
set lvec to landspot:position.
set lvec:mag to 350.

set Arrow1 TO VECDRAW(
    V(0,0,0),
    lvec,
    RGB(0,1,0),
    "landspot",
    1.0,
    TRUE,
    0.2,
    TRUE,
    TRUE
).

set Arrow2 TO VECDRAW(
    V(0,0,0),
    addons:tr:impactpos:position,
    RGB(1,0,0),
    "impact",
    1.0,
    TRUE,
    0.2,
    TRUE,
    TRUE
).

set Arrow3 TO VECDRAW(
    V(0,0,0),
    vcrs(addons:tr:impactpos:position, landspot:position),
    RGB(0,0,1),
    "vcrs",
    1.0,
    TRUE,
    0.2,
    TRUE,
    TRUE
).


// clearScreen.
// sas off.
// rcs on.
// SET MYTHROTTLE TO 0.
// SET MYSTEERING TO HEADING(90, 90).

// // variables to change from rocket to rocket
// set heightOffset to 20.51610.

// // more or less environmental variables
// lock mass to ship:mass.
// lock vert to ship:verticalspeed.
// lock aspeed to ship:airspeed.
// lock aerobrake to body:atm:exists.
// set landingthrust to ship:availableThrust.
// // lock g to ship:sensors:grav:mag.
// lock g to constant:g * body:mass / body:radius^2. 
// lock gheight to alt:radar - heightOffset. // height over ground
// lock maxaccel to (landingthrust / mass) - g.
// lock burnDist to aspeed^2 / (2 * maxaccel).		// The distance the burn will require
// lock idealHoverslamThrottle to burnDist / gheight.			// Throttle required for perfect hoverslam
// lock timeTilImpact to gheight / abs(ship:verticalspeed).		// Time until impact, used for landing gear
// // lock apoapsis to alt:apoapsis.
// lock TWR to landingthrust / mass * g.
// lock hoverheight to choose 140 if aerobrake else 20.
// // lock landingthrottle 

// // ship variables
// LOCK STEERING TO MYSTEERING.
// LOCK THROTTLE TO MYTHROTTLE.
// set landed to false.    // says if craft has landed
// set flightmod to 0.

// set untilstatement to false.
// until untilstatement {
//     print "burnDist:                     " + burnDist + "m      " at (0, 3).
//     print "TWR:                          " + TWR + "      " at (0, 4).
//     print "maxaccel:                     " + maxaccel + "m/s     " at (0, 5).
//     print "predicted time till impact:   " + addons:tr:timetillimpact + "s     " at (0, 6).
//     print "time til impact from gheight: " + timeTilImpact + "s     " at (0, 7).
//     print "airspeed:                     " + aspeed + "m/s      " at (0, 8).
//     set fburndist to choose burnDist if burndist > 0 else burndist*-1.
//     set ffburndist to choose 500 if fburndist < 500 else fburndist. // the numbers are guessed. maybe with formula to work on all bodies. // we need some time to bellyflip
//     set MYSTEERING to ship:srfretrograde.
//     if(gheight < ffburndist) {
//         clearScreen.
//         print "bellyflip and landingburn" at (0, 0).
//         rcs on.
//         set MYTHROTTLE to choose idealHoverslamThrottle if idealHoverslamThrottle > 0 else idealHoverslamThrottle * -1.
//         break.       
//     }
//     wait 0.001.
// }

// // do hoverslam
// until gheight < hoverheight {
//     set MYSTEERING to ship:srfRetrograde.
//     set MYTHROTTLE to choose idealHoverslamThrottle if idealHoverslamThrottle > 0 else idealHoverslamThrottle * -1.
//     print "throttle: " + MYTHROTTLE at (0, 3).
//     print "gheight:  " + gheight at (0, 4).
// }
// gear on.
// clearScreen.
// print "I am hovering." at (0, 0).

// // hover
// until landed {
//     set mysteering to heading(90, 90).
//     set MYTHROTTLE to ((mass) * (g - VERT) / ship:availablethrust) - 0.04 + flightmod.
//     print "mass:               " + mass                 + "      " at (0, 3).
//     print "thrust:             " + ship:availablethrust + "      " at (0, 4).
//     print "mythrottle:         " + MYTHROTTLE           + "      " at (0, 5).
//     print "height over ground: " + gheight              + "      " at (0, 6).
// }

// brakes off.
// clearScreen.
// print "Starship (hopefully) landed".