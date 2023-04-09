// get data from a reentry
set lgco to 0. // log count

log "time,gheight,velo,c_d,gforce,accel,rho" to "entryflightlogf9_"+ lgco + ".csv".

set lastvel to V(0, 0, 0).

until false {
    set atmo to ship:body:atm.
    set vel to ship:velocity:surface.
    set a to vel-lastvel.
    set g to ship:sensors:grav.
    set a_d to a-g.
    set p to atmo:altitudepressure(alt:radar)*constant:atmtokpa*1000.
    set rho to (atmo:molarmass*p)/(8.31446*atmo:alttemp(alt:radar)).
    set c_d to (2*a_d:mag*ship:mass)/(rho*vel:mag^2).
    log time:seconds + "," + alt:radar + "," + vel:mag + "," + c_d + "," + g:mag + "," + a:mag + "," + rho to "entryflightlogf9_"+ lgco + ".csv".
    set lastvel to vel.
    wait 0.2.
}