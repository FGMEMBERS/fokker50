# Initialises ADF 2, called ADF[1] in the sim, as well as DME 2

var SetRadioNav2 = func{

#Makes the right-hand ADF servicable, and in ADF mode, with LCY selected.

	setprop("instrumentation/adf[1]/mode", "adf");
	setprop("instrumentation/adf[1]/serviceable", 'true');
	setprop("instrumentation/adf[1]/frequencies/selected-khz", 322);

#Makes DME serviceable, and ties it to VOR 2
	setprop("instrumentation/dme[1]/serviceable", 'true');
	setprop("instrumentation/dme[1]/switch-position", 1);
	setprop("instrumentation/dme[1]/frequencies/source", 'instrumentation/nav[1]/frequencies/selected-mhz');
}

setlistener("sim/signals/fdm-initialized", SetRadioNav2);

#init();
