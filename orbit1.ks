//Homemade launch sequence.
 
 
clearscreen.
rcs on.
sas off.
lights off.
ag1 on.
 
set targetAp to 80000.		// ---- Use these to easily modify orbit parameters
set targetPe to 80000.		// ---- Use these to easily modify orbit parameters
set targetHe to 90.			// ---- Use these to easily modify orbit parameters
set gTurnBegin to 2500.		// ---- Use these to easily modify orbit parameters
set gTurnEnd to 70000.		// TODO:Figure out a use for this.
 
set TVAL to 1.
set runmode to 1.
 
 
 
// ---- This is the ascent program.
 
until runmode = 0 {
 
	if runmode = 1 {				//Begin countdown
		print "Launch in:" at (5,11).
		FROM {local countdown is 5.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
   			print "T - " + countdown at (16,11).
   			WAIT 1.
 
			}
		set runmode to 2.
		}
 
	else if runmode = 2 {				//Trigger ignition, liftoff and vertical ascent before gTurnBegin
		lock throttle to TVAL.
		lock steering to heading(targetHe,90).	
		stage.
		print "Initiate stage: " + stage:number at (5,17).
		wait until ship:altitude > gTurnBegin.
		set runmode to 3.
 
		}
 
	else if runmode = 3 {							//Gravity Turn
		set targetPitch to max(5, 90 * (1-alt:radar / gTurnEnd)). 	
		lock steering to heading (targetHe, targetPitch). 		//TODO: Make this better too steep
		lock throttle to TVAL.					//TODO: need to figure out a way to limit throttle.
		when ship:apoapsis >= targetAp then{				//checks for reaching target apoapsis
			lock throttle to 0.
			set runmode to 4.
			}
		}
 
	else if runmode = 4 {							//warp to apoapsis
		lock steering to prograde.
		lock throttle to 0.
		if eta:apoapsis >= 60 {
			wait 5.
			rcs off.
			set warp to 3.
			}
		else if eta:apoapsis < 60 {
			set warp to 0.
			rcs on.
			}
		when eta:apoapsis <= 10 or verticalspeed < 0 then {
			set runmode to 5.
			}
		}
 
	else if runmode = 5 {							//orbit insertion burn
 
		lock steering to heading (targetHe, 0).
		lock throttle to 1.
 
		when (ship:periapsis >= targetPe) or (ship:periapsis > targetAp * 0.95) then {
			lock throttle to 0.
			unlock steering.
			set runmode to 6.
			}
		}	
 
	else if runmode = 6 {							//shutdown launch sequence
		UNLOCK all.
		SET ship:control:pilotMainThrottle TO 0.
		ag1 off.
		print "================ END LAUNCH PROGRAM ================" at (1,35).
		set runmode to 0.
		}
 
	if stage:liquidfuel < 1 and stage:number > 0 {				//stage when fuel 0
		print "Initiate Staging Protocal: " + stage:number.
		stage.
		print "Initiate stage: " + stage:number at (5,17).
		}
 
 
 
 
	print "Stage Number:		" + stage:number + "				" at (5,3).
	print "Runmode:			" + runmode + "					" at (5,4).
	print "Altitude:		" + round(ship:altitude) + "			" at (5,5).
	print "Apoapsis:		" + round(ship:apoapsis) + "			" at (5,6).
	print "ETA to AP:		" + round(eta:apoapsis) + "			" at (5,8).
	print "Periapsis:		" + round(ship:periapsis) + "			" at (5,7).
	print "Liquid Fuel:		" + round(stage:liquidfuel) + "			" at (5,9).
	print "Dynamic Pres:		" + ship:q + "					" at (5,10).
 
 
 
 
	}