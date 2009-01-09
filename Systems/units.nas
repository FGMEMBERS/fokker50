# Converts degF to degC

var convertTemp = func{

#First, here's engine 1

#	var degF = getprop("engines/engine/itt_degf");
	var degF = getprop("engines/engine/egt_degf");
	var degC = (degF - 32) * 5 / 9;
	setprop("engines/engine/itt_degc", degC);


#And now engine 2

	var degF = getprop("engines/engine[1]/egt_degf");
	var degC = (degF - 32) * 5 / 9;
	setprop("engines/engine[1]/itt_degc", degC);

	settimer(convertTemp, 0);
}

setlistener("sim/signals/fdm-initialized", convertTemp);

