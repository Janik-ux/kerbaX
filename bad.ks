// same as booladr.ks but better
// the script does an boostback and then uses air to steer to the landingspot
// shortly before the ground it does an hoverslam to land

// the program assumes the booster has an impact and is not on orbital velocity

// TODO roll in th right direction to support pitch
@lazyGlobal off.
parameter bb.

// to be changed by the user
// KSS launchpad: latlng(-0.0972075468722493, -74.5576849138598)
// Island airfield: latlng(-1.540833, -71.909722)
// Helipad über besucherzentrum: latlng(-0.09258, -74.663112)
// Helipad West highbay: latlng(-0.096775, -74.620072)
// Helipad Ost highbay: latlng(-0.09679, -74.617419)
// Of course I still love you: latlng(0, -60)
// JRTI: latlng(0, -44)

global landspot to latlng(0, -44).
global heightOffset to 30.27449.
global landingengines to 9. // possible values are 9,3,1. If anything alse, the program assumes 1

// ship variables
lock g to ship:sensors:grav:mag.
lock g to constant:g * body:mass / body:radius^2.
lock gheight to alt:radar - heightOffset.
lock maxaccel to (ship:availablethrust / ship:mass) - g.
lock vert to ship:verticalspeed.
lock hori to ship:groundspeed.
lock burnDist to ABS((vert)^2 / (2 * maxaccel)).		// The distance the burn will require
lock idealHoverslamThrottle to ABS(burnDist / gheight).

declare global MYTHROTTLE TO 0.
declare global MYSTEERING TO HEADING(90, 90).
LOCK STEERING TO MYSTEERING.
LOCK THROTTLE TO MYTHROTTLE.

// calculate, how much hori distance we won't travel, because of the landing burn
function landingoffset {
    parameter spot is landspot.
    local a to 0.1.
    if landingengines = 9 {
        set a to 0.0000094.
    }
    else if landingengines = 3 {
        set a to 0.000035.
    }
    else {
        set a to 0.0001. // Try to get the values
    }
    local k to choose -(ship:groundspeed*a) if gheight < 30000 else -0.004.
    local distvec to V(ship:geoposition:lat-spot:lat, ship:geoposition:lng-spot:lng, 0).
    set distvec:mag to 1.
    local testspot to latlng(spot:lat + distvec:x*k, spot:lng + distvec:y*k).
    addons:tr:settarget(testspot).

    local newspot to testspot.
    // local newspot to spot.
    return newspot.
}

FUNCTION dist {
    parameter a.
    parameter b.
    local distance to sqrt((a:lng - b:lng)^2+(a:lat - b:lat)^2).
    return distance.
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
    
    // try to adjust the target
    until false {
        print "dist: " + dist(landspot, addons:tr:impactpos) at (0, 1).
        if gheight > 1000 and gheight > burnDist + 300 and dist(landspot, addons:tr:impactpos) > 0.03 { // TODO check if we are near or after apoapsis
            local backboostvec to landspot:position - addons:tr:impactpos:position.
            set MYSTEERING to backboostvec.
            local targetDir to vAng(backboostvec, ship:facing:vector).
            print "target dir " + targetdir at (0, 2). 
            if targetDir <= 15 {
                set MYTHROTTLE to 1.
            } else {
                set MYTHROTTLE to 0.
            }

            // updating debug arrow
            local displayvec to backboostvec.
            set displayvec:mag to 15. // maybe do it with vecdraw scale option
            set anArrow:vec to displayvec.

        } else {
            print "boostback end".
            set MYTHROTTLE to 0.
            break.
        }
    }
    // remove debug arrow
    set anArrow:show to false.

    // prepare for next maneuver
    clearScreen.
    return.
}

FUNCTION steeringback {
    print "steering back" at (0, 0).
    brakes on.

    // PID setup start
    // calculate the distance between dest and impact and convert th vector to delta attitude
    local lock P to dist(landingoffset(landspot), addons:tr:impactpos).
    local I is 0.
    local D is 0.

    // PID gains
    local Kp is -500. // BIG TODO waht are the values of these numbers
    local lock Ki to choose -1000 if P < 0.04 else 0.
    local Kd is 0.

    // change of attitude in degrees
    local lock dangle to min(45, max(-45, (Kp * P + Ki * I + Kd * D))). // maybe add gheight

    local resetcount to 0.

    local P0 is P.
    local t0 is time:seconds.
    local dt is 0.
    // PID setup end

    local angle to 0.
    local steeringdir to ship:srfRetrograde. // assign some more or less random value, will be changed in loop immediately
    // drawing vector of steering for debugging
    local anArrow TO VECDRAW(
        V(0,0,0),
        steeringdir:inverse:forevector,
        RGB(1,0,0),
        "steeringdir",
        1.0,
        TRUE,
        0.2,
        TRUE,
        TRUE
    ).
    until gheight < burnDist+20 {
        // PID start
        set dt to time:seconds - t0.
        if dt > 0 { // copied from kos docu is this really necessary? it will ever be true. MAybe there is a case when the script runs faster then the game engine can render the flight.
            // wir haben nur positive distanz, würden daher die ganze Zeit hochzählen, (angle + dangle > angle in jedem Fall)
            // also immer, wenn sich theoretisch vorzeichen ändern würde auf null setzen.
            if P < 0.0008 {
                set resetcount to resetcount+1.
                set angle to 0.
                set I to 0.
                print "RESET: " + resetcount at (0, 10).
            }
            set I to I + P*dt.
            set D to (P -P0) / dt.

            // If Ki is non-zero, then limit Ki*I to [-1,1]            
            IF not Ki = 0 {
                SET I TO MIN(3.5/ABS(Ki), MAX(-3.5/ABS(Ki), I)). // if Ki is negativ, values are reversed, so taking abs of Ki, be aware of possible bugs, which i dondt know
            }

            // set angle to min(45, max(-45, (angle + dangle))).
            // PID end
            set steeringdir to angleAxis(dangle, vCrs(landingoffset(landspot):position, addons:tr:impactpos:position))*ship:srfRetrograde.
            set steeringdir to steeringdir*R(0, 0, 270).
            set MYSTEERING to steeringdir. // maybe roll the booster, so that 2 rcs engines are working instaed of one
            set anArrow:vec to steeringdir:vector*17.

            // set MYSTEERING to ship:srfretrograde.
            // local targetDir to vAng(ship:srfretrograde:vector, ship:facing:vector).
            local targetDir to vAng(steeringdir:forevector, ship:facing:vector).
            print "burn dist:  " + burndist at  (0, 1).
            print "target dir: " + targetdir at (0, 2).
            print "angle:   " + dangle at (0, 3).
            print "P:          " + P at (0, 4).
            print "I:          " + I at (0, 5).
            print "D:          " + D at (0, 6).
            print "Ki*I:       " + Ki*I at (0, 7).
            print "Kp*P:       " + Kp*P at (0, 8).
            print "gheight:    " + gheight at (0, 9).
            print "vspeed:      " + ship:verticalspeed at (0, 10).
            // print "dangle:     " + dangle at (0, 8).
            log time:seconds +  ", " + I to i_file.
            // log time:seconds + ", " + P to p_file.
            // log time:seconds + ", " + I to i_file.
            // log time:seconds + ", " + D to d_file.

            if targetDir <= 0.5 {
                rcs off.
            } else {
                rcs on.
            }

            // PID start
            set P0 to P.
            set t0 to time:seconds.
            // PID end
        }
        wait 0.001.
    }
    // remove arow
    set anArrow:show to false.
    clearScreen.
    return.
}

FUNCTION hoverslam {
    print "hoverslam" at (0, 0).
    local soft to 0.
    until gheight <= 0.2 {
        set MYTHROTTLE to idealHoverslamThrottle + soft.
        print "throttle: " + MYTHROTTLE at (0, 1).
        if gheight < 60 and ship:groundspeed < 25{
            print "executing facing up " at (0, 10).
            set mysteering to heading(90, 90).
        } else {
            print "executing retrograde" at (0, 10).
            set MYSTEERING to ship:srfretrograde.
        }
        if gheight < 200 {
            gear on. // (gheight / abs(ship:verticalspeed)) <= 4
        }
        if gheight < 130{
                set soft to 0.12.
        } else {
            set soft to 0.05.
        }
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
    if bb = 1 {
        boostback().
    }
    steeringback().
    hoverslam().
    rcs on.
    brakes off.
    wait 10. // make this smarter -> look if rocket is not moving even not turning and then abort else leave steering on.
    print "booster hopefully safe landed".
    print "good bye!".
    rcs off.

} else {
    // burn retrograde and after it do landing would work without trajectories addon
    print "please install trajectories prediction addon or make an impact. You probably are in orbit or on the ground.". 
    print "program aborting..".
}
