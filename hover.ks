// hover
CLEARSCREEN.
sas off.
rcs off.

SET MYTHROTTLE TO 0.75.
// set MYTHROTTLE to 0.
SET MYSTEERING TO HEADING(90, 90).

lock mass to ship:mass.
lock g to constant:g * body:mass / body:radius^2. 
LOCK STEERING TO MYSTEERING.
LOCK THROTTLE TO MYTHROTTLE.
LOCK VERT TO SHIP:VERTICALSPEED.
lock HORI to ship:groundspeed. 
lock gheight to alt:radar.
lock getretrograde to hori > 1 and gheight > 4 and vert < -0.5.
set land to false.
set isattached to true.
set rovemass to 0.
set flightmod to 0.

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
// when getretrograde then {
//     // hier nochmal gucken
//     set MYSTEERING to ship:retrograde.
//     preserve.
// }

// when not getretrograde then {
//     set mysteering to heading(90, 90).
//     preserve.
// }

//countdown(3).
PRINT "Liftoff!".
STAGE.

// erstmal bisschen Höhe gewinnen
set MYTHROTTLE to 1.
WAIT UNTIL gheight > 20.
set flightmod to 0.

// main loop vlt. mit var, die geändert werden kann.
until false {
    set MYTHROTTLE to ((mass+rovemass) * (g - VERT) / ship:availablethrust)+flightmod.

    print "mass:               " + mass at (0, 7).
    print "thrust:             " + ship:availablethrust at (0, 8).
    print "mythrottle:         " + MYTHROTTLE at (0, 9).
    print "height over ground: " + gheight at (0, 10).
    print "flightmod:          " + flightmod at (0, 11).
}

PRINT gheight.
