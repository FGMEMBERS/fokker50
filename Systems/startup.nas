# Nasal for some initial settings in the aircraft.

var StartConf = func{

#Sets up some properties for the Fokker when the sim is started

	setprop("engines/engine/damaged", "false");

#Sets the QNH for you

	var QNH = getprop("environment/pressure-sea-level-inhg");
	setprop("instrumentation/altimeter/setting-inhg", QNH);
}

init = func {

#Needs a short delay between sim starting and setting QNH
	
	settimer(StartConf, 3);
}

setlistener("sim/signals/fdm-initialized", init);
