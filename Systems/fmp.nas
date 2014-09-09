# Puts the FMP in standby, AP disengaged and passive.

var initialise = func{

#Hide the FD bars, set FD standby, disconnect autopilot.

	props.globals.initNode("systems/fokker50/fmp/fdpitchbar_visible", 0, "BOOL");
	props.globals.initNode("systems/fokker50/fmp/fdrollbar_visible", 0, "BOOL");

#Set window alt to something, so we can arm ASEL.

	setprop("systems/fokker50/fmp/window-alt",5000);

#Workaround to get a non-NULL value in tgt datums, then set GA.

	setprop("autopilot/internal/target-roll-deg",0);
	setprop("autopilot/internal/target-pitch-deg",0);
	setprop("autopilot/settings/target-speed-kt",0);
	setprop("autopilot/settings/vertical-speed-fpm",0);

	setprop("systems/fokker50/fmp/loc",0);
	setprop("systems/fokker50/fmp/nav",0);
	setprop("systems/fokker50/fmp/vapp",0);
	setprop("systems/fokker50/fmp/bc",0);

	fmpga();
	fmphdg();
	fmpasel();

	props.globals.initNode("/autopilot/locks/passive-mode", 0, "BOOL");
	setprop("autopilot/locks/passive-mode", 1);

#Initiate calculator for FD command bars.

	setprop("systems/fokker50/fmp/tcs",0);
	fdbar_calc();

#AP settings to non-null:
#	setprop ("autopilot/settings/target-pitch-deg",0);
	setprop ("autopilot/settings/vertical-speed-fpm",0);
	setprop ("autopilot/settings/target-speed-kt",0);
}


var fdbar_calc = func{
#Works out the deflection for pitch and roll command bars.

	tgtroll = getprop("autopilot/internal/target-roll-deg");
	tgtpitch = getprop("autopilot/internal/target-pitch-deg");

	actroll = getprop("orientation/roll-deg");
	actpitch = getprop("orientation/pitch-deg");

	var pitchdiff = tgtpitch - actpitch;
	var rolldiff = tgtroll - actroll;

	setprop("systems/fokker50/fmp/fdbar_roll",rolldiff);
	setprop("systems/fokker50/fmp/fdbar_pitch",pitchdiff);

#Keep calculating the bars only if TCS is not engaged.
	if (getprop("systems/fokker50/fmp/tcs") == 0) { settimer(fdbar_calc,0.01);}
	else{
		setprop("systems/fokker50/fmp/fdbar_roll", 0 );
		setprop("systems/fokker50/fmp/fdbar_pitch", 0 );}
}


#var HeadingBug = func{

#Caluculate difference in actual and target headings, and write to bugoff.
#
#	var hdg = getprop("orientation/heading-magnetic-deg");
#	var HdgTgt = getprop("autopilot/settings/heading-bug-deg");
#	var BugOff = (hdg - HdgTgt);
#	setprop("autopilot/settings/bugoff-deg", BugOff);
	#settimer(HeadingBug, 0.1);

#}

############################################################################
# FMP SBY Button
############################################################################

var fmpsby = func{
#Functions of SBY button- SBY mode, all other modes disengaged, flight director bars clear.

	setprop("systems/fokker50/fmp/sby", 2);
	setprop("systems/fokker50/fmp/hdg", 0);
	setprop("systems/fokker50/fmp/nav", 0);
	setprop("systems/fokker50/fmp/bc", 0);
	setprop("systems/fokker50/fmp/vapp", 0);
	setprop("systems/fokker50/fmp/asel", 0);
	setprop("systems/fokker50/fmp/alt", 0);
	setprop("systems/fokker50/fmp/vs", 0);
	setprop("systems/fokker50/fmp/gs", 0);
	setprop("systems/fokker50/fmp/ias", 0);
	setprop("systems/fokker50/fmp/ga", 0);
	setprop("systems/fokker50/fmp/navbtn",0);

	setprop("systems/fokker50/fmp/fdrollbar_visible", 0);
	setprop("systems/fokker50/fmp/fdpitchbar_visible", 0);

	setprop("autopilot/locks/heading", "wing-leveller");
	setprop("autopilot/locks/altitude", "pitch-hold");

}

############################################################################
# FMP ASEL Button
############################################################################

var fmpasel = func{
#Sets ASEL white- arms altitude preselect mode.

	setprop("systems/fokker50/fmp/asel", 1);
	setprop("systems/fokker50/fmp/fdpitchbar_visible", 1);

#	setprop("autopilot/settings/target-altitude-ft", getprop ("systems/fokker50/fmp/window-alt"));
	
#Starts the monitor, checks to see if we are approaching target altitude, until we do.

	aselmonitor();	
}

var aselmonitor = func{
#Watches the altitude, turns ASEL green when within 10% of ROC/ROC of target alt.

	targetAlt = getprop ("systems/fokker50/fmp/window-alt");
	currentAlt = getprop("instrumentation/altimeter/indicated-altitude-ft");
	var currvs = getprop("instrumentation/vertical-speed-indicator/indicated-speed-fpm");
	
	captureGap = currvs / 10;
	captureGapsq = captureGap * captureGap;

	currGap = currentAlt - targetAlt;
	currGapsq = currGap * currGap;

#	captureAlt = targetAlt - captureGap;

#	setprop("systems/fokker50/fmp/captureAlt",captureAlt);

	if (captureGapsq > currGapsq ) {
		setprop("autopilot/locks/altitude", "vertical-speed-hold");
		aselGreen();  }
	else {
		settimer (aselmonitor,0.5); }
}

var aselGreen = func{
#Levels off from climb / descent, then sets ALT hold.

	setprop("systems/fokker50/fmp/maxPitchRate", 2);

	setprop ("systems/fokker50/fmp/vs",0);
	setprop ("systems/fokker50/fmp/ias",0);

	targetAlt = getprop ("systems/fokker50/fmp/window-alt");
	currentAlt = getprop("instrumentation/altimeter/indicated-altitude-ft");
	altdiffsq = (targetAlt - currentAlt) * (targetAlt - currentAlt);

	setprop("systems/fokker50/fmp/asel", 2);
	
#Calculate a continuously reducing ROC / ROD to approach target alt, then set in VS mode.

	targetROC = (targetAlt - currentAlt) / 2;
	setprop("autopilot/settings/vertical-speed-fpm", targetROC);

#Check to see whether we're within 40 ft, then set ALT hold.

	if (altdiffsq < 1600) {
		fmpalt (); }
	else {  if (getprop("systems/fokker50/fmp/asel") == 2 ) {
		settimer (aselGreen,0.1); }}
}

############################################################################
# FMP GA Button  -  can't currently be pressed in flight!
############################################################################

var fmpga = func{
#Functions of GA button- GA mode, all other modes disengaged, +8 pitch, wings level.

	setprop("systems/fokker50/fmp/maxPitchRate", 999);

	setprop("systems/fokker50/fmp/sby", 0);
	setprop("systems/fokker50/fmp/hdg", 0);
	setprop("systems/fokker50/fmp/nav", 0);
	setprop("systems/fokker50/fmp/bc", 0);
	setprop("systems/fokker50/fmp/vapp", 0);
	setprop("systems/fokker50/fmp/asel", 0);
	setprop("systems/fokker50/fmp/alt", 0);
	setprop("systems/fokker50/fmp/vs", 0);
	setprop("systems/fokker50/fmp/gs", 0);
	setprop("systems/fokker50/fmp/ias", 0);
	setprop("systems/fokker50/fmp/navbtn",0);
	setprop("systems/fokker50/fmp/ga", 2);

	setprop("systems/fokker50/fmp/fdrollbar_visible", 1);
	setprop("systems/fokker50/fmp/fdpitchbar_visible", 1);

	setprop("autopilot/locks/heading", "wing-leveller");
	setprop("autopilot/locks/altitude", "pitch-hold");

	setprop("autopilot/settings/target-pitch-deg",8);

}

############################################################################
# FMP HDG Button
############################################################################

var fmphdg = func{
#Functions of HDG button.

	setprop("systems/fokker50/fmp/sby", 0);
	setprop("systems/fokker50/fmp/hdg", 2);

	setprop("systems/fokker50/fmp/nav", 0);
	setprop("systems/fokker50/fmp/loc", 0);
	setprop("systems/fokker50/fmp/bc", 0);
	setprop("systems/fokker50/fmp/vapp", 0);
	setprop("systems/fokker50/fmp/navbtn",0);

	var nav = getprop ("systems/fokker50/fmp/nav");
	var bc = getprop ("systems/fokker50/fmp/bc");
	var vapp = getprop ("systems/fokker50/fmp/vapp");

	if ( nav == 2 ){
		setprop("systems/fokker50/fmp/nav", 0); }
	if ( bc == 2 ){
		setprop("systems/fokker50/fmp/bc", 0); }
	if ( vapp == 2 ){
		setprop("systems/fokker50/fmp/vapp", 0); }

	setprop("systems/fokker50/fmp/fdrollbar_visible", 1);

	setprop("autopilot/locks/heading", "dg-heading-hold");
}

############################################################################
# FMP ALT Button
############################################################################

var fmpalt = func{
#Functions of ALT button.

	setprop("systems/fokker50/fmp/maxPitchRate", 999);

	setprop("systems/fokker50/fmp/fdpitchbar_visible", 1);

	var asel = getprop("systems/fokker50/fmp/asel");

	if (asel != 2) {
		ourtarget = getprop ("instrumentation/altimeter/indicated-altitude-ft"); }
	else {
		ourtarget = getprop ("systems/fokker50/fmp/window-alt"); }

	setprop("systems/fokker50/fmp/sby", 0);
	setprop("systems/fokker50/fmp/alt", 2);
	setprop("systems/fokker50/fmp/asel", 0);
	setprop("systems/fokker50/fmp/ias", 0);
	setprop("systems/fokker50/fmp/vs", 0);
	setprop("systems/fokker50/fmp/ga", 0);

	var gs = getprop ("systems/fokker50/fmp/gs");
	if ( gs == 2 ){
		setprop("systems/fokker50/fmp/gs", 0); }

	setprop("autopilot/locks/altitude", "altitude-hold");
	setprop("autopilot/settings/target-altitude-ft", ourtarget)
}

############################################################################
# FMP VS Button
############################################################################

var fmpvs = func{
#Functions of VS button.

	setprop("systems/fokker50/fmp/maxPitchRate", 0.5);

	setprop("systems/fokker50/fmp/fdpitchbar_visible", 1);

	setprop("systems/fokker50/fmp/sby", 0);
	setprop("systems/fokker50/fmp/alt", 0);
	setprop("systems/fokker50/fmp/ias", 0);
	setprop("systems/fokker50/fmp/ga", 0);
	setprop("systems/fokker50/fmp/vs", 2);

	var currvs = getprop("instrumentation/vertical-speed-indicator/indicated-speed-fpm");
	setprop("autopilot/settings/vertical-speed-fpm", currvs);

	setprop("autopilot/locks/altitude", "vertical-speed-hold");
}

############################################################################
# FMP IAS Button
############################################################################

var fmpias = func{

	setprop("systems/fokker50/fmp/maxPitchRate", 0.7);

	setprop("systems/fokker50/fmp/sby", 0);
	setprop("systems/fokker50/fmp/alt", 0);
	setprop("systems/fokker50/fmp/ias", 2);
	setprop("systems/fokker50/fmp/ga", 0);
	setprop("systems/fokker50/fmp/vs", 0);

	setprop("systems/fokker50/fmp/fdpitchbar_visible", 1);

	var currias = getprop("instrumentation/airspeed-indicator/indicated-speed-kt");
	setprop("autopilot/settings/target-speed-kt", currias);
#	setprop("autopilot/locks/speed", "speed-with-pitch-trim");
	setprop("autopilot/locks/altitude", "speed-with-pitch-trim");
}


############################################################################
# FMP TCS Function
############################################################################

controls.applyBrakes = func (v, which = 0) { 
#Overrides normal brake command, applies brakes if on ground, otherwise calls TCS func.

	if (getprop("gear/gear/wow")){
    		if (which <= 0) { interpolate("controls/gear/brake-left", v, 0.5); }
    		if (which >= 0) { interpolate("controls/gear/brake-right", v, 0.5); } }
	else{ tcs(v)  }

}

var tcs = func (v) {
#TCS func, v=1 if button pressed, 0 if it's released.
#First, disengage AP (if it's not already), or re-engage IF it was disengaged previously!

	if (v == 1){
		setprop("systems/fokker50/fmp/ap-before-tcs",getprop("autopilot/locks/passive-mode"));
		setprop("autopilot/locks/passive-mode",1);
		setprop("systems/fokker50/fmp/tcs",1);  #Announce that TCS is engaged. 

#Neutralise command bars
#		setprop("systems/fokker50/fmp/fdbar_roll", 0 );
#		setprop("systems/fokker50/fmp/fdbar_pitch", 0 ); }

#Constantly recalculate pitch datums ready for TCS release

		tcsrecalc();
}

	else{
		setprop("autopilot/locks/passive-mode",getprop("systems/fokker50/fmp/ap-before-tcs"));
		setprop("systems/fokker50/fmp/tcs",0);
#Set new pitch datums
		currpitch = getprop ("orientation/pitch-deg");
		currvs = getprop ("instrumentation/vertical-speed-indicator/indicated-speed-fpm");
		currias = getprop ("instrumentation/airspeed-indicator/indicated-speed-kt");
		curralt = getprop ("instrumentation/altimeter/indicated-altitude-ft");

		setprop ("autopilot/settings/target-pitch-deg",currpitch);
		setprop ("autopilot/settings/vertical-speed-fpm",currvs);
		setprop ("autopilot/settings/target-speed-kt",currias);
		setprop ("autopilot/settings/target-altitude-ft",curralt);

		fdbar_calc();
	}
}

var tcsrecalc = func {
#Continuous calculation of datums for TCS

	currpitch = getprop ("orientation/pitch-deg");
	currvs = getprop ("instrumentation/vertical-speed-indicator/indicated-speed-fpm");
	currias = getprop ("instrumentation/airspeed-indicator/indicated-speed-kt");
	curralt = getprop ("instrumentation/altimeter/indicated-altitude-ft");

	setprop ("autopilot/settings/target-pitch-deg",currpitch);
	setprop ("autopilot/settings/vertical-speed-fpm",currvs);
	setprop ("autopilot/settings/target-speed-kt",currias);
	setprop ("autopilot/settings/target-altitude-ft",curralt); 

#Check to see if TCS still engaged, if so call this function.

	repeat = getprop("systems/fokker50/fmp/tcs");
	if (repeat > 0) {		
		settimer (tcsrecalc,0.1);}
}

############################################################################
# FMP NAV Function
############################################################################

var fmpnav = func {
#Arms LOC or NAV and waits for the CDI to come alive.

	setprop("systems/fokker50/fmp/sby", 0);
	setprop("systems/fokker50/fmp/vapp", 0);
	setprop("systems/fokker50/fmp/bc", 0);
	setprop("systems/fokker50/fmp/navbtn",1);
	
	var isILS = getprop("instrumentation/nav/has-gs");
	if (isILS) {
		setprop("systems/fokker50/fmp/loc",1); }
	else {
		setprop("systems/fokker50/fmp/nav",1); }

	navListener();	
}

var fmpvapp = func {
#Arms VAPP- actually just a modified NAV mode.

	setprop("systems/fokker50/fmp/sby", 0);
	setprop("systems/fokker50/fmp/vapp",1);
	setprop("systems/fokker50/fmp/bc", 0);
	setprop("systems/fokker50/fmp/navbtn",0);
	navListener();	
}

var fmpbc = func {
#Arms BC- another modified NAV mode.

	setprop("systems/fokker50/fmp/sby", 0);
	setprop("systems/fokker50/fmp/vapp",0);
	setprop("systems/fokker50/fmp/bc",1);
	setprop("systems/fokker50/fmp/navbtn",0);
	navListener();	
}

var navListener = func {
#Waits for the CDI bar to start moving, then goes into NAV/LOC/VAPP mode.

	var alive = 0;
	var deflection = getprop ("instrumentation/nav/heading-needle-deflection");
	var inrange = getprop ("instrumentation/nav/in-range");

#	setprop("systems/fokker50/fmp/inrange",inrange);
#	setprop("systems/fokker50/fmp/deflection",deflection);
#	setprop("systems/fokker50/fmp/alive",alive);

	if (deflection < 9){ if (deflection > -9) { if (inrange) {
		alive = 1; } } }
	if (alive) {
		setprop ("systems/fokker50/fmp/hdg",0);
		if (getprop("systems/fokker50/fmp/nav") == 1 ) {
			setprop("systems/fokker50/fmp/nav",2);}
		if (getprop("systems/fokker50/fmp/loc") == 1 ) {
			setprop("systems/fokker50/fmp/loc",2);}
		if (getprop("systems/fokker50/fmp/vapp") == 1 ){
			setprop("systems/fokker50/fmp/vapp",2);}
		if (getprop("systems/fokker50/fmp/bc") == 1) {
			setprop("systems/fokker50/fmp/bc",2);}

		navHoldInit();
	}

#Not captured yet?  Then, if a mode is still armed, keep watching!
	else {
		var listening = getprop("systems/fokker50/fmp/loc") + getprop("systems/fokker50/fmp/nav") + getprop("systems/fokker50/fmp/vapp");
		if (listening > 0){
			settimer(navListener,0.1); }
	}
}

var navHoldInit = func {
#Sets up the VOR/ILS hold.
	
#Cancel HDG mode first, then set the relevant NAV/LOC/VAPP mode green.
	setprop ("systems/fokker50/fmp/hdg",0);
	var navArmed = getprop ("systems/fokker50/fmp/nav");
	var locArmed = getprop ("systems/fokker50/fmp/loc");
	var vappArmed = getprop ("systems/fokker50/fmp/vapp");
	var bcArmed = getprop ("systems/fokker50/fmp/bc");

	if (navArmed > 0) {
		setprop ("systems/fokker50/fmp/nav",2); }
	if (locArmed > 0) {
		setprop ("systems/fokker50/fmp/loc",2); }
	if (vappArmed > 0) {
		setprop ("systems/fokker50/fmp/vapp",2); }
	if (bcArmed > 0) {
		setprop ("systems/fokker50/fmp/bc",2); }

#Announce that we're holding a VOR/ILS, then set heading lock.
	setprop("systems/fokker50/fmp/vorheld",1);

	setprop("autopilot/locks/heading", "nav");

#Now, call the function that will maintain the lock.
	navHold();
}

var navHold = func {
#Calculates a heading error until NAV mode is cancelled.

	var acthdg = getprop ("orientation/heading-magnetic-deg");
	var tgthdg = getprop ("instrumentation/nav/radials/target-auto-hdg-deg");

	result = tgthdg - acthdg;
	if (result > 180) { result = result - 180; }
	if (result < -180) { result = result + 360; }  

	setprop ("systems/fokker50/fmp/hdg-error-nav",result);

	var held = getprop("systems/fokker50/fmp/loc") + getprop("systems/fokker50/fmp/nav") + getprop("systems/fokker50/fmp/vapp") + getprop("systems/fokker50/fmp/bc");

	if (held > 0) {settimer (navHold,0.05)}
#	settimer (navHold,0.05)

}	


############################################################################
# Glideslope button
############################################################################

var fmpgs = func {
#Logic for the GS button on the FMP.
#If we have an ILS tuned, arm GS and LOC.  Otherwise do nothing.

	var isILS = getprop("instrumentation/nav/has-gs");
	var loc = getprop("systems/fokker50/fmp/loc");
	if (isILS) {
		setprop("systems/fokker50/fmp/gs",1); 
		fmpnav ();
		gsListener();}
}

var gsListener = func {
#While GS armed, watch for us to get on the slope, then engage GS hold mode.

	var deflection = getprop ("instrumentation/nav/gs-needle-deflection");
	var loc = getprop("systems/fokker50/fmp/loc");
	var gs = getprop("systems/fokker50/fmp/gs");
	var deflectionsq = deflection * deflection;

	if (deflectionsq < 0.25){
		if (loc == 2) {
			setprop("systems/fokker50/fmp/gs",2);
			setprop("autopilot/locks/altitude", "GS");
			setprop("systems/fokker50/fmp/sby", 0);
			setprop("systems/fokker50/fmp/alt", 0);
			setprop("systems/fokker50/fmp/ias", 0);
			setprop("systems/fokker50/fmp/ga", 0);
			setprop("systems/fokker50/fmp/vs", 0);}
	}
	else {
		if (gs == 1) { settimer (gsListener,0.1);} }
}


############################################################################
# FD pitch control adjustment.
############################################################################

controls.elevatorTrim = func (v, which = 0) {
#Hijacks the elevator trim controls to modify target pitch settings in TCS mode.

	if ( getprop("autopilot/locks/passive-mode") ) {
		controls.slewProp("controls/flight/elevator-trim", v * 0.045); }
	else {
		controls.slewProp("autopilot/settings/vertical-speed-fpm", -300 * v ); 
		controls.slewProp("autopilot/settings/target-speed-kt", 2.5 * v );
		controls.slewProp("autopilot/settings/target-pitch-deg", -1 * v ); }
}


setlistener("sim/signals/fdm-initialized", initialise);
