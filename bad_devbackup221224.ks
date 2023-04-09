// same as booladr.ks but better
// the script does an boostback and then uses air to steer to the landingspot
// shortly before the ground it does an hoverslam to land

// the program assumes the booster has an impact and is not on orbital velocity

// TODO roll in th right direction to support pitch
// NEXT UP: replace (analyt func by iter function) in l 102

@lazyGlobal off.
clearVecDraws().
set config:ipu to 2000. // overclocking cpu dont know if this is allowed
parameter bb.

// to be changed by the user
// KSS launchpad: latlng(-0.0972075468722493, -74.5576849138598)
// Island airfield: latlng(-1.540833, -71.909722)
// Helipad über besucherzentrum: latlng(-0.09258, -74.663112)
// Helipad West highbay: latlng(-0.096775, -74.620072)
// Helipad Ost highbay: latlng(-0.09679, -74.617419)
// Of course I still love you: latlng(0, -60)
// JRTI: latlng(0, -44)

global landspot to latlng(-0.0972075468722493, -74.5576849138598).
global heightOffset to 30.27449.

// ship variables
lock g to ship:sensors:grav:mag.
lock g to constant:g * body:mass / body:radius^2.
lock gheight to alt:radar - heightOffset.
// lock maxaccel to (ship:availablethrust / ship:mass) - g.
lock vert to ship:verticalspeed.
lock hori to ship:groundspeed.
// lock burnDist to ABS((vert)^2 / (2 * maxaccel)).		// The distance the burn will require

global brakedisty to 0.
global impactpos to landspot. // before it gets calced we set it where it has to be to
global bdistruntime to 0.
global cd to 0.
lock idealHoverslamThrottle to ABS(brakedisty / gheight).

declare global MYTHROTTLE TO 0.
declare global MYSTEERING TO HEADING(90, 90).
LOCK STEERING TO MYSTEERING.
LOCK THROTTLE TO MYTHROTTLE.

function set_cd {
    set cd to 0.008.
}

function drag {
    if cd = 0 {
        set_cd().
    }
    parameter v.
    parameter height.
    local atmo to ship:body:atm.
    if height > atmo:height {
        return 0.
    }
    local p to atmo:altitudepressure(height)*constant:atmtokpa*1000.
    local rho to (atmo:molarmass*p)/(8.31446*atmo:alttemp(height)).
    print "rho: " + rho at (0, 5).
    return 1/2*rho*cd*v^2.
}

FUNCTION burnDist {
    parameter vx0.
    parameter vy0.
    parameter ka.

    // local vx0 to abs(hori). // velocity in y dir
    local vx to vx0.
    // local vy0 to abs(vert). // velocity in x dir
    local vy to vy0. // vy0 HAS TO BE <0!   
    local ry to 0. // the burndist, we will return
    local rx to 0.
    local t to 0.
    local dt to 0.7.
    local maxt to 60.
    
    
    // numerical integration in flight
    // velocity "down" is positive so g gets added but subtract
    // the program assumes we are firing perfect retrograde while hoverslam
    // -> this may not be 
    until t >= maxt - dt {
        set t to round(t + dt, 4).
        local absv to sqrt(vx^2+vy^2).
        // used this term ((-absv*dt*1.1 < absv) and (absv < absv*dt*1.1))
        // but only need greater than 0
        if vy > 0 {print "ry: " + ry at (0, 11).return list(abs(ry), rx).}
        local vunitx to vx/absv*-1.
        local vunity to vy/absv*-1.
        // print "v2:" + sqrt(vunitx^2+vunity^2).

        set vx to vx + vunitx*dt*(ka).
        set vy to vy + vunity*dt*(ka) - g*dt.
        set ry to ry + vy*dt.
        set rx to rx + vx*dt.
    }
    return list(1000, 0). // loop didnt get to an asnwer

}

FUNCTION flightsim {
    parameter dofast.
    local stime to time:seconds.
    local lock ka to ship:availableThrust/ship:mass. // acceleration coefficient

    if gheight > 150 and not dofast {
        // TODO vlt 3d dann simpler -> ship:position vec usw.
        local vx0 to abs(hori). // velocity in x dir
        local vx to vx0.
        local vy0 to vert. // velocity in y dir
        local vy to vy0.
        local ry0 to gheight. // the burndist, we will return
        local ry to ry0.
        local rx to 0.
        local t to 0.
        local dt to 3.
        local maxt to 1000.
        
        // numerical integration in flight
        // velocity "down" is positive so g gets added but subtract
        // the program assumes we are firing perfect retrograde while hoverslam
        // -> this may not be 
        until t >= maxt - dt {
            // local bdist to ABS((vy)^2 / (2 * ka-g)).
            local bdist to burnDist(vx, vy, ka).
            print "dt: " + dt at (0, 8).
            if ry < bdist[0]+abs(vy*dt*1.5) {set dt to 0.08.} // we're getting near burn
            if ry < bdist[0] +abs(vy*dt*0.5) {
                set brakedisty to bdist[0].
                print "ry-bdsit: " + (ry-bdist[0]) at (0, 7).
                set rx to rx + bdist[1].
                break.
            }

            set t to round(t + dt, 4).
            local absv to sqrt(vx^2+vy^2).
            local vunitx to vx/absv.
            local vunity to vy/absv.
            set vx to vx + vunitx*-1*(drag(absv, ry)/ship:mass)*dt.
            local dvy to vunity*-1*(drag(absv, ry)/ship:mass)*dt - g*dt.
            set vy to vy + dvy.
            set ry to ry + vy*dt.
            set rx to rx + vx*dt.
        }
        if t >= maxt-dt {
            set brakedisty to 1000.
            set impactpos to landspot.
        } // loop didnt get to an asnwer
        else {
            local groundvec to ship:body:geopositionof(ship:velocity:surface):position - ship:geoposition:position.
            set impactpos to ship:body:geopositionof(groundvec:normalized*rx).
            print "rx: " + rx at (0, 4).
        }
    }
    else { // if near ground use more correct but 1d formula  
        set brakedisty to ABS((vert)^2 / (2 * (ka -g))).
        set impactpos to landspot.
    }
    addons:tr:settarget(impactpos).
    set bdistruntime to time:seconds-stime.
    print "bdistrtime: " + bdistruntime at (0, 15).

}

FUNCTION dist {
    // wird benutzt ist auch murks wegen lat lng != kartesisch
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
        flightsim(true).
        if gheight > 1000 and gheight > brakedisty + 300 and dist(landspot, addons:tr:impactpos) > 0.03 { // TODO check if we are near or after apoapsis
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
    local ltime to 0.

    // PID setup start
    // calculate the distance between dest and impact and convert th vector to delta attitude
    local lock P to dist(landspot, impactpos).
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
    until gheight < brakedisty+abs(vert)*ltime {
        local stime to time:seconds.
        print "margin " + abs(vert)*ltime at (0, 14).

        if resetcount > 10 {
            flightsim(false). //TODO long function call is really bad in PID loop
        }
        else {
            flightsim(false).
        }
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
            set steeringdir to angleAxis(dangle, vCrs(landspot:position, impactpos:position))*ship:srfRetrograde.
            set steeringdir to steeringdir*R(0, 0, 270).
            set MYSTEERING to steeringdir. // maybe roll the booster, so that 2 rcs engines are working instaed of one
            set anArrow:vec to steeringdir:vector*17.

            // set MYSTEERING to ship:srfretrograde.
            // local targetDir to vAng(ship:srfretrograde:vector, ship:facing:vector).
            local targetDir to vAng(steeringdir:forevector, ship:facing:vector).
            print "burn dist:  " + brakedisty at  (0, 1).
            // print "formula bdist: " + ABS((vert)^2 / (2 * ( ship:availableThrust/ship:mass -g))).
            print "target dir: " + targetdir at (0, 2).
            print "angle:      " + dangle at (0, 3).
            // print "P:          " + P at (0, 4).
            // print "I:          " + I at (0, 5).
            // print "D:          " + D at (0, 6).
            // print "Ki*I:       " + Ki*I at (0, 7).
            // print "Kp*P:       " + Kp*P at (0, 8).
            print "gheight:    " + gheight at (0, 9).
            print "vspeed:     " + ship:verticalspeed at (0, 10).
            // print "dangle:     " + dangle at (0, 8).
            // log time:seconds +  ", " + I to i_file.
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
        // wait 0.001.
        set ltime to time:seconds - stime.
        print "ltime: " + ltime at (0, 6).
    }
    // remove arow
    set anArrow:show to false.
    clearScreen.
    return.
}

FUNCTION hoverslam {
    print "hoverslam" at (0, 0).
    local soft to 0.05. // TODO is maybe not neccessary
    until gheight <= 0.2 {
        flightsim(true).
        set MYTHROTTLE to idealHoverslamThrottle + soft.
        print "throttle: " + MYTHROTTLE at (0, 1).
        if gheight < 30 and ship:groundspeed < 25{
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
    set Mysteering to ship:facing + R(0, 0, 90). 
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
