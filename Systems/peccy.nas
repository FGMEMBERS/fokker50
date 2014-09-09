    ######Script fulfilling functions of the Prop Electronic Control###########

    # For the Fokker 50.
    # This script figures out the target prop RPM, and adjusts the prop pitch to make it so!

    #Steal the propeller pitch control away from the pilot.
    controls.propellerAxis = func { }

    #Initialisation fn to set variable(s) and then call pec script.

    var initialise = func {

       setprop("systems/fokker50/pec/target_rpm", 1200);
       pec ();
    }


    var pec = func {

       var PECfreq = 0.1; #(how often this script is to be run)
       var tgtRPM = getprop("systems/fokker50/pec/target_rpm"); # 85% = 1020;
       var actPC = getprop("controls/engines/engine/propeller-pitch");
       var tgtPC = (tgtRPM  - 394) / 866;
#       var tgtPC = (tgtRPM  - 750) / 510;
       if (tgtPC > actPC) { newPC = actPC + 0.02 }
         else { newPC = actPC - 0.02 }
       if (abs (tgtPC - actPC) < 0.015) { newPC = tgtPC }   

       setprop("controls/engines/engine/propeller-pitch", newPC);
    #For now, let's use the same prop control for Eng #2.
       setprop("controls/engines/engine[1]/propeller-pitch", newPC);

      settimer(pec, PECfreq);

    }

    setlistener("sim/signals/fdm-initialized", initialise);

