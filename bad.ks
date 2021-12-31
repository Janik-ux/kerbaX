// same as booladr.ks but better
// the script does an boostback and then uses air to steer to the landingspot
// shortly before the ground it does an hoverslam to land

// the program assumes the booster has an impact and is not on orbital velocity

// TODO implement PID

@lazyGlobal off.

// to be changed by the user
global landspot to latlng(-0.0972075468722493, -74.5576849138598).
global heightOffset to 30.27449.

// ship variables
lock g to ship:sensors:grav:mag.
lock g to constant:g * body:mass / body:radius^2.
lock gheight to alt:radar - heightOffset.
lock maxaccel to (ship:availablethrust / ship:mass) - g.
lock vert to ship:verticalspeed.
lock burnDist to ABS(vert^2 / (2 * maxaccel)).		// The distance the burn will require
lock idealHoverslamThrottle to ABS(burnDist / gheight).

declare global MYTHROTTLE TO 0.
declare global MYSTEERING TO HEADING(90, 90).
LOCK STEERING TO MYSTEERING.
LOCK THROTTLE TO MYTHROTTLE.

FUNCTION dist {
    parameter a.
    parameter b.
    return sqrt((a:lng - b:lng)^2+(a:lat - b:lat)^2).
}

FUNCTION boostback {
    print "boostback" at (0, 0).
    // drawing vector of steering for debugging
    local anArrow TO VECDRAW(
        V(0,0,0),
        (landspot:position - addons:tr:impactpos:position),
        RGB(1,0,0),
        "landspot - impact",
        1.0,
        TRUE,
        0.2,
        TRUE,
        TRUE
    ).
    until false {
        print "dist: " + dist(landspot, addons:tr:impactpos) at (0, 1).
        if gheight > 1000 and gheight > burnDist + 300 and dist(landspot, addons:tr:impactpos) > 0.03 {
            local backboostvec to landspot:position - addons:tr:impactpos:position.
            set MYSTEERING to backboostvec.
            local targetDir to vAng(backboostvec, ship:facing:vector).
            print "target dir " + targetdir at (0, 2). 
            if targetDir <= 20 {
                set MYTHROTTLE to 1.
            } else {
                set MYTHROTTLE to 0.
            }

            // updating arrow
            local displayvec to backboostvec.
            set displayvec:mag to 15. 
            set anArrow:vec to displayvec.

        } else {
            print "boostback end".
            set MYTHROTTLE to 0.
            break.
        }
    }
    set anArrow:show to false.
    clearScreen.
    return.
}

FUNCTION steeringback {
    print "steering back" at (0, 0).
    brakes on.
    // PID controls
    until gheight < burnDist {
        // PID
        print "burn dist: " + burndist at  (0, 1).
        set MYSTEERING to ship:srfretrograde.
        local targetDir to vAng(ship:srfretrograde:vector, ship:facing:vector).
        print "target dir " + targetdir at (0, 2). 
        if targetDir <= 7 {
            rcs off.
        } else {
            rcs on.
        }
    }
    clearScreen.
    return.
}

FUNCTION hoverslam {
    print "hoverslam" at (0, 0).
    until gheight <= 0.5 {
        set MYTHROTTLE to idealHoverslamThrottle.
        print "throttle: " + MYTHROTTLE at (0, 1).
        if gheight < 50 {
            print "executing facing up " at (0, 10).
            set mysteering to heading(90, 90).
        } else {
            print "executing retrograde" at (0, 10).
            set MYSTEERING to ship:srfretrograde.
        }
        if gheight < 200 {gear on.}
    }
    set MYTHROTTLE to 0.
    clearScreen.
    return.
}

// main program
CLEARSCREEN.
sas off.
rcs on.

if addons:tr:available and addons:tr:hasimpact {
    print "program start".
    boostback().
    steeringback().
    hoverslam().
    brakes off.
    wait 10. // make this smarter -> look if rocket is not moving even not turning and then abort else leave steering on.
    print "booster hopefully safe landed".
    print "good bye!".

} else {
    // burn retrograde and then do landing would work without trajectories
    print "please install trajectories prediction". 
    print "program aborting..".
}

