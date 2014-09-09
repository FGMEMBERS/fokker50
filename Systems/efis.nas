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

var cmdDigits = func{
#Updates the VS and IAS display on the PFD.

    var vsSet = getprop ("systems/fokker50/fmp/vs");
    var iasSet = getprop ("systems/fokker50/fmp/ias");
    var last2 = 0;    
    var output = 0;

    if (vsSet > 0) {
        var currvs = getprop("autopilot/settings/vertical-speed-fpm");
        last2 = 1;
        output = int (currvs / 100) * 100; }
    if (iasSet > 0) {
        var currias = getprop("autopilot/settings/target-speed-kt");
        last2 = 1;
        output = currias  }

    var outputsq = output * output;
    if (outputsq > 1000000) {
        setprop("systems/fokker50/efis/dig1exist",1); }
    else {
                setprop("systems/fokker50/efis/dig1exist",0); }

    setprop ("systems/fokker50/efis/cmd", output);
    setprop ("systems/fokker50/efis/abscmd", abs(output));
    setprop ("systems/fokker50/efis/last2", last2);

    var tcs = getprop ("systems/fokker50/fmp/tcs");
    if (tcs > 0) {
            setprop ("systems/fokker50/efis/cmd", 0);
        setprop ("systems/fokker50/efis/abscmd", 0);
        setprop ("systems/fokker50/efis/last2", 0);
        setprop("systems/fokker50/efis/dig1exist",0);  }

    settimer (cmdDigits,0.1);
}

init = func {
#   settimer(HeadingBug, 1.0);
    cmdDigits ();
}

setlistener("sim/signals/fdm-initialized", init);
#setlistener("sim/signals/fdm-initialized", HeadingBug);

#init();
