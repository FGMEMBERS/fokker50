# Nasal for some initial settings in the aircraft.

var StartConf = func{

#Sets up some properties for the Fokker when the sim is started.

#Select ERP to TO


	setprop("engines/engine/damaged", "false");
	setprop("systems/fokker50/erp/selected", "TO");
	setprop("systems/fokker50/erp/to", 1);
	setprop("systems/fokker50/erp/ga", 0);
	setprop("systems/fokker50/erp/crz", 0);
	setprop("systems/fokker50/erp/clb", 0);
	setprop("systems/fokker50/erp/mct", 0);
#	setprop("systems/fokker50/erp/settingn", 2);

#Steal the propeller pitch control away from the pilot.
    controls.propellerAxis = func { }


#Sets the QNH for you

	var QNH = getprop("environment/pressure-sea-level-inhg");
	setprop("instrumentation/altimeter/setting-inhg", QNH);
}

init = func {



#Needs a short delay between sim starting and setting QNH
	
	settimer(StartConf, 3);
}

#Set some ERP selections for the benefit of the models before we do anything else.

setprop("/systems/fokker50/erp/settingn", 2);
setprop("systems/fokker50/erp/settinggi", 2.5);

#Now start up properly:
setlistener("sim/signals/fdm-initialized", init);
