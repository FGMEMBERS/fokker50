# Processes Heading bug information

var SetHdg = func{

#Sets heading bug to current heading

	setprop("autopilot/settings/heading-bug-deg", getprop("orientation/heading-magnetic-deg"));
}


var HeadingBug = func{

#Caluculate difference in actual and target headings, and write to bugoff.

	var hdg = getprop("orientation/heading-magnetic-deg");
	var HdgTgt = getprop("autopilot/settings/heading-bug-deg");
	var BugOff = (hdg - HdgTgt);
	setprop("autopilot/settings/bugoff-deg", BugOff);
	settimer(HeadingBug, 0.1);

}

init = func {
   settimer(HeadingBug, 1.0);
}

setlistener("sim/signals/fdm-initialized", SetHdg);
setlistener("sim/signals/fdm-initialized", HeadingBug);

init();
