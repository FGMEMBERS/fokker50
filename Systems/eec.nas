############Engine Electronic Control#############
#Fulfils the role of the EEC- effectively de-rating the engine depending on ERP selection.    

    var initialise = func {

#Steal the throttle control away from the pilot.
    controls.Throttle = func() {}

#Set TQ bug to TO pwr.
       setprop("systems/fokker50/erp/maxtq", 2250);

#And calibrate the gague, 100%=10942 lb-ft.
       setprop("systems/fokker50/erp/tq100-lbft", 10942);

#       eec ();
	tqcalc ();
       settimer (gndidlecheck,5.0);
    }


##########Ground Idle Function######################
var gndidlecheck = func {
#Checks to see if we should be in ground idle mode- if throttle posn <5% and WOW:

	var wow = getprop("gear/gear/wow");
	var throttlepos = getprop("controls/engines/engine/throttle");
	var erpset = getprop("systems/fokker50/erp/settingn");

	if (wow and throttlepos < 0.05) {
		setprop ("systems/fokker50/erp/gndidle", "true");
		setprop ("systems/fokker50/erp/settinggi", erpset +0.5 );
  		}
	else  {
		setprop ("systems/fokker50/erp/gndidle", "false");
		setprop ("systems/fokker50/erp/settinggi", erpset );
		}
		settimer (gndidlecheck, 0.2);
}

#################Torque gauge calculator###################
var tqcalc = func {

#Converts current tq to a % value for the gagues:

	var acttq1 = - getprop("engines/engine/thruster/torque");
	var acttq2 = - getprop("engines/engine[1]/thruster/torque");
	var tq100pc = getprop("systems/fokker50/erp/tq100-lbft");
	var acttqpc1 = acttq1 / tq100pc ;
	var acttqpc2 = acttq2 / tq100pc ;
	setprop("systems/fokker50/erp/acttqpc[0]", acttqpc1);
	setprop("systems/fokker50/erp/acttqpc[1]", acttqpc2);

	settimer(tqcalc, 0.01);
}


#########Other EEC functions##########################
# This routine is now not called, accommodated in fdm channels
var eec = func {
    
#Converts current tq to a % value for the gagues:

	var acttq1 = - getprop("engines/engine/thruster/torque");
	var acttq2 = - getprop("engines/engine[1]/thruster/torque");
	var tq100pc = getprop("systems/fokker50/erp/tq100-lbft");
	var acttqpc1 = acttq1 / tq100pc ;
	var acttqpc2 = acttq2 / tq100pc ;
	setprop("systems/fokker50/erp/acttqpc[0]", acttqpc1);
	setprop("systems/fokker50/erp/acttqpc[1]", acttqpc2);

#This code gets the Axis [2] position from the joystick input, and converts it into a throttle position, wrt ERP setting.

	var powerleverpos = getprop("input/joysticks/js/axis[2]/binding/setting");
	powerleverpos = ( - powerleverpos + 1) / 2;
	
#If power lever (PL) position is >95%, consider it to be in 'detent'.
	if (powerleverpos > 0.95 ) {powerleverpos = 1}
	var throt = powerleverpos;

	var erpset = getprop("systems/fokker50/erp/selected");
	if ( erpset == 'GA' ) { throt = powerleverpos }
	if ( erpset == 'TO' ) { throt = powerleverpos * 0.93 }
	if ( erpset == 'MCT' ) { throt = powerleverpos * 0.95 }
	if ( erpset == 'CRZ' ) { throt = powerleverpos * 0.82 }
	if ( erpset == 'CLB' ) { throt = powerleverpos * 0.91 }

#	setprop ("systems/fokker50/eec/powerleverpos", erpset);
	setprop ("controls/engines/engine/throttle", throt);
	setprop ("controls/engines/engine[1]/throttle", throt);

	settimer(eec, 0.01);
}


setlistener("sim/signals/fdm-initialized", initialise);
