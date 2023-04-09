// same as booladr.ks but better
// the script does an boostback and then uses air to steer to the landingspot
// shortly before the ground it does an hoverslam to land
// (c) 2022-2023 Janik-ux
// licensed under MIT

// the program assumes the booster has an impact and is not on orbital velocity

// TODO roll in th right direction to support pitch

// PRINT CONVENTION: line 0 main program phase, 
//                   line 1 not used or for special debug data
//                   line 2-15 debug data

@lazyGlobal off.
clearVecDraws().
// set config:ipu to 20000. // overclocking cpu dont know if this is allowed
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
// for fheavy sides it is lower:
global heightOffset to 30.27449.
// maximum steering angle for fheavy sides has to be smaller
global maxang to 38.


// ship variables
lock g to ship:sensors:grav.
lock gheight to alt:radar - heightOffset.
lock vert to ship:verticalspeed.
lock hori to ship:groundspeed.

global ka to ship:availablethrust/ship:mass.

declare global MYTHROTTLE TO 0.
declare global MYSTEERING TO HEADING(90, 90).
LOCK STEERING TO MYSTEERING.
LOCK THROTTLE TO MYTHROTTLE.

FUNCTION getdrag {
    parameter vel.
    parameter height.
    // get drag at specific gheight and velocity, assumes retrograde

    local atmo to ship:body:atm.
    if height > atmo:height {
        return 0.
    }

    // local c_d to -0.133*vel + 14. // -0.01332*abs(vel) + 0.00004*height + 14.27807.
    local c_d to 0.1. // 12.4. // 0.015
    
    local p to atmo:altitudepressure(height)*constant:atmtokpa*1000.
    print "c_d:    " + c_d + "              " at (0, 1).
    local rho to (atmo:molarmass*p)/(8.31446*atmo:alttemp(height)).
    print "F " + 1/2*rho*c_d*vel^2 at (0, 2).
    return 1/2*rho*c_d*vel^2.
}

FUNCTION getBurndist {
    parameter vy.
    // analytical equation 1d

    // TODO g is from ship's view not that position
    return (vy)^2 / (2 * (ka - g:mag)).
}

FUNCTION simfallphase {
    // TODO rename to flying back e.g.
    parameter vel0.
    parameter pos0.
    parameter dt to 0.3.

    local vel to vel0.
    local pos to pos0+ship:body:position. // position vector of ship in terms of soi
    local t to 0.
    local maxt to 1000.
    
    // drag calc
    local a_drag to getdrag(vel:mag, ship:body:altitudeof(pos0))/ship:mass.
    local dragspeed to vel0:mag.
    local dragheight to ship:body:altitudeof(pos0).

    local thrtl to 0.
    local burnstart to false.
    local burnstartheight to 0.

    log "begin" to "simlog.log".

    // numerical integration in flight
    until t >= maxt - dt {
        local groundheight to ship:body:altitudeof(pos-ship:body:position).
        log "height: " + groundheight to "simlog.log".
        log "vel: " + vel to "simlog.log".
        log "pos: " + pos to "simlog.log".
        log "g: " + g to "simlog.log".
        if groundheight <= 0 {
            return list(pos-ship:body:position, burnstartheight).
        }

        // part of velocity orthogonal to surface---V  acc--V
        local burndist to getBurndist((vel-vxcl(pos, vel)):mag).

        if groundheight <= burndist and not burnstart {
            set burnstart to true.
            set burnstartheight to burndist.
            log "burnstart" to "simlog.log".
        }

        if burnstart {
            set thrtl to abs(burndist/groundheight).
        }

        set t to round(t + dt, 4).
        local vunit to vel:normalized.

        // calc drag only if significant change in speed or height
        if (abs(groundheight-dragheight) > 150) or (abs(vel:mag-dragspeed) > 100) {
            set a_drag to getdrag(vel:mag, groundheight)/ship:mass.
            set dragspeed to vel:mag.
            set dragheight to groundheight.
        }
        
        log "a_drag: " + a_drag to "simlog.log".
        // local dv to (- vunit*a_drag + (g) - vunit*ka*thrtl)*dt.
        local dv to g*dt - vunit*a_drag*dt.
        log "dv: " + dv to "simlog.log".
        set vel to vel + dv.

        set pos to pos + vel*dt.
    }
    // loop didnt get to an answer:
    print "ERROR t>maxt in simfallphase!!!" at (0, 2).
    return list(V(0, 0, 0), 0).
}

FUNCTION distance {
    // wird benutzt ist auch murks wegen lat lng != kartesisch
    parameter a.
    parameter b.
    local dist to sqrt((a:lng - b:lng)^2+(a:lat - b:lat)^2).
    return dist.
}

FUNCTION boostback {
    print "boostback" at (0, 0).

    // drawing vector of steering for debugging
    local anArrow TO VECDRAW(
        V(0,0,0),
        ship:retrograde:vector,
        RGB(1,0,0),
        "landspot - impact",
        1.0,
        TRUE,
        0.2,
        TRUE,
        TRUE
    ).
    
    local old_dist to 0. // get written in loop so 0 doesnt mean anything

    // try to adjust the target
    until false {
        local fdistx to simfallphase(0, hori, vert, gheight, 3)[0].
        local bdist to simburnphase(hori, vert, ship:availablethrust/ship:mass, true, 0.8).
        local bdisty to bdist[1].

        // get position where we will approximately land
        local groundvec to ship:body:geopositionof(ship:velocity:surface:normalized):position - ship:geoposition:position.
        local impactpos to ship:body:geopositionof(groundvec:normalized*(fdistx)). // dont need bdistx here, because approx

        local dist to distance(landspot, impactpos).
        set old_dist to dist.

        print "dist: " + dist at (0, 2).

        if gheight > 1000 and gheight > bdisty + 300 and dist > 0.03 and dist < old_dist { // TODO check if we are near or after apoapsis
            local backboostvec to landspot:position - impactpos:position.
            set MYSTEERING to backboostvec.
            local targetDir to vAng(backboostvec, ship:facing:vector).
            print "target dir " + targetdir at (0, 3). 
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
    print "steering back..." at (0, 0).
    brakes on.
    local ltime to 0.
    local bdisty to getBurndist(vert).
    local impactpos to landspot.

    // PID setup start
    // calculate the distance between dest and impact and convert th vector to delta attitude
    local lock P to distance(landspot, impactpos).
    local I is 0.
    local D is 0.

    // PID gains
    local Kp is -250. // TODO BIG waht are the values of these numbers
    local lock Ki to -50. // choose -1000 if P < 0.04 else -200.
    local lock Kd to choose 0 if P < 0.01 else -500. // have to disable D term near 0 because we only have abs values

    // change of attitude in degrees
    local lock dangle to min(maxang, max(-maxang, (Kp * P + Ki * I + abs(Kd * D)))). // TODO maybe add gheight

    local resetcount to 0.

    local P0 is P.
    local t0 is time:seconds.
    local dt is 0.
    // PID setup end

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

    // log "time,gheight,fdistx,bdistx,bdisty,P,D,fdisterr,bdisterr,distx" to "flightlog_f9_west.csv".

    // main control loop
    until gheight < bdisty+abs(vert)*ltime {
        local stime to time:seconds.

        // calculate how the flight will enroll 0: endposition, 1: bdisty
        local simresult to simfallphase(ship:velocity:surface, ship:position, 0.2).
        set bdisty to simresult[1].

        // get position where we will approximately land
        set impactpos to ship:body:geopositionof(simresult[0]).
        addons:tr:settarget(impactpos).

        // PID start
        set dt to time:seconds - t0.
        if dt > 0 { // copied from kos docu is this really necessary? it will never be true. MAybe there is a case when the script runs faster then the game engine can render the flight.
            if P < 0.004 {
                set resetcount to resetcount+1.
                set I to 0.
                print "RESET: " + resetcount at (0, 10).
            }
            set I to I + P*dt.
            set D to (P -P0) / dt.

            // If Ki is non-zero, then limit Ki*I to [-10,10]            
            IF not Ki = 0 {
                SET I TO MIN(10/ABS(Ki), MAX(-10/ABS(Ki), I)). // if Ki is negativ, values are reversed, so taking abs of Ki, be aware of possible bugs, which i dondt know
            }
            
            set P0 to P.
            set t0 to time:seconds.
            
            // set angle to min(45, max(-45, (angle + dangle))).
            // PID end
            set steeringdir to angleAxis(dangle, vCrs(landspot:position, impactpos:position))*ship:srfRetrograde.
            set steeringdir to steeringdir*R(0, 0, 270). // maybe roll the booster, so that 2 rcs engines are working instaed of one
            set MYSTEERING to steeringdir. 
            set anArrow:vec to steeringdir:vector*17.

            // <debug begin>
            // local targetDir to vAng(ship:srfretrograde:vector, ship:facing:vector).
            local targetDir to vAng(steeringdir:forevector, ship:facing:vector).
            print "burn dist:     " + bdisty at  (0, 3).
            print "target dir:    " + targetdir at (0, 5).
            print "gheight:       " + gheight at (0, 6).
            print "angle:         " + dangle at (0, 7).
            // print "vspeed:        " + ship:verticalspeed at (0, 7).
            //print "fdist[0]:      " + fdist[0] at (0, 8).
            //print "bdist[0]:      " + bdist[0] at (0, 9).
            // print "rx:            " + (fdist[0]+bdist[0]) at (0, 10).
            // print "rt steerloop:  " + ltime at (0, 11). // run time of one loop
            // print "margin:        " + abs(vert)*ltime at (0, 12).

            print "P:          " + P at (0, 8).
            print "I:          " + I at (0, 9).
            print "D:          " + D at (0, 10).
            print "Ki*I:       " + Ki*I at (0, 11).
            print "Kp*P:       " + Kp*P at (0, 12).
            print "abs(Kd*D)   " + abs(Kd*D) at (0, 13).
            // print "dangle:     " + dangle at (0, 8).
            // log time:seconds + ", " + gheight + "," + fdist[0] + "," + bdist[0] + "," + bdisty + "," + P + "," + D + "," + fdisterr + "," + bdisterr + "," + fdist[0]+bdist[0] to "flightlog_f9_west.csv". // +Kp+Ki+Kd+".csv".
            // log time:seconds + ", " + P to p_file.
            // log time:seconds + ", " + I to i_file.
            // log time:seconds + ", " + D to d_file.
            // <debug end>

            if targetDir <= 0.5 {
                rcs off.
            } else {
                rcs on.
            }
        }
        set ltime to time:seconds - stime.
        wait 0.001.
    }
    // remove arow
    set anArrow:show to false.
    clearScreen.
    return.
}

FUNCTION hoverslam {
    print "hoverslam" at (0, 0).
    rcs on.
    local soft to 0.05. // TODO is maybe not neccessary lieber faktor
    local ltime to 0. 
    until gheight <= 0.2 {
        local stime to time:seconds.
        local bdist to getBurndist(vert).
        local idealHoverslamThrottle to abs(bdist/gheight).
        set MYTHROTTLE to idealHoverslamThrottle + soft.
        print "throttle: " + MYTHROTTLE at (0, 2).
        print "looptime: " + ltime at (0, 3).
        if gheight < 30 and ship:groundspeed < 25{
            print "executing facing up " at (0, 4).
            set mysteering to heading(90, 90).
        } else {
            print "executing retrograde" at (0, 4).
            set MYSTEERING to ship:srfretrograde.
        }
        if gheight < 200 { // TODO could make it samrter
            gear on. // (gheight / abs(ship:verticalspeed)) <= 4
        }
        if gheight < 130 { // TODO Hardcode throttle add also not smart -> faktor?
                set soft to 0.12.
        }
        set ltime to time:seconds - stime.
    }
    set MYTHROTTLE to 0.
    rcs off.
    clearScreen.
    return.
}

// ******* Main Program *******
CLEARSCREEN.
sas off.
rcs on.

print "program start" at (0, 0).
set Mysteering to ship:facing + R(0, 0, 90). 
if bb = 1 {
    boostback().
}
steeringback().
hoverslam().
rcs on.
brakes off.
wait 10. // TODO make this smarter -> look if rocket is not moving even not turning and then abort else leave steering on.
print "booster hopefully safely landed".
print "good bye!".
rcs off.
