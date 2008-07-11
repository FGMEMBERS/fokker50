# Converts degF to degC

var convertTemp = func{
	
#First, here's engine 1	
	var degF = getprop("engines/engine[0]/egt_degf[0]");
	var degC = (degF - 32) * 5/9;
	setprop("engines/engine/egt-degc[0]", degC);
	
#And now engine 2
	var degF1 = getprop("engines/engine[1]/egt_degf[0]");
	var degC1 = (degF1 - 32) * 5/9;
	setprop("engines/engine[1]/egt-degc[0]", degC);

settimer(convertTemp, 0.3);
#setlistener("sim/signals/fdm-initialized", convertTemp());

}

init = func {
   settimer(convertTemp, 1.0);
}

setlistener("sim/signals/fdm-initialized", convertTemp);

init();
