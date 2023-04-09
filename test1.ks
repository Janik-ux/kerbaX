clearScreen.
set c_d to 5.315.

FUNCTION set_cd {
    parameter vel, height.
    // set cd to 12.4. // 0.015
    set c_d to -0.01332*vel + 0.00004*height + 14.27807.
    print "c_d: " + c_d at (0, 1).
}

FUNCTION drag {
    // if c_d = 0 {
    //     set_cd().
    // }
    parameter vel.
    parameter height.
    local atmo to ship:body:atm.
    if height > atmo:height {
        return 0.
    }
    set_cd(vel, height).
    local p to atmo:altitudepressure(height)*constant:atmtokpa*1000.
    // print "p:    " + p + "              " at (0, 1).
    local rho to (atmo:molarmass*p)/(8.31446*atmo:alttemp(height)).
    return 1/2*rho*c_d*vel^2.
}

until false {
    print "drag: " + drag(ship:velocity:surface:mag, ship:altitude) at (0, 2).
}
