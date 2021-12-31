// copied from https://ksp-kos.github.io/KOS/tutorials/pidloops.html
// staging, throttle, steering, go
WHEN STAGE:LIQUIDFUEL < 0.1 THEN {
    STAGE.
    PRESERVE.
}
LOCK THROTTLE TO 1.
LOCK STEERING TO R(0,0,-90) + HEADING(90,90).

STAGE.
WAIT UNTIL SHIP:ALTITUDE > 1000.

// PID-loop
SET g TO KERBIN:MU / KERBIN:RADIUS^2.
LOCK accvec TO SHIP:SENSORS:ACC - SHIP:SENSORS:GRAV.
LOCK gforce TO accvec:MAG / g.

SET gforce_setpoint TO 1.2.

LOCK P TO gforce_setpoint - gforce.
SET I TO 0.
SET D TO 0.
SET P0 TO P.

SET Kp TO 0.01.
SET Ki TO 0.006.
SET Kd TO 0.006.

LOCK dthrott TO Kp * P + Ki * I + Kd * D.

SET thrott TO 1.
LOCK THROTTLE to thrott.

SET t0 TO TIME:SECONDS.
UNTIL SHIP:ALTITUDE > 40000 {
    SET dt TO TIME:SECONDS - t0.
    IF dt > 0 {
        SET I TO I + P * dt.
        SET D TO (P - P0) / dt.
        SET thrott to thrott + dthrott.
        SET P0 TO P.
        SET t0 TO TIME:SECONDS.
    }
    WAIT 0.001.
}