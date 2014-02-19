module main;

import std.stdio;
import autopilot;
import hardware.hardware;
import config;
import saillog;


int main(string[] args)
{
	version(unittest){
		SailLog.Success("UnitTest finished ! Congratulations !");
	}
	else{
		SailLog.Success("Starting program");

		Autopilot sc = new Autopilot();
		Hardware.Get!Roll(DeviceID.Roll);

		bool b=true;
		while(b){
			
		}
	}
	return 0;
}