module main;

import std.stdio;
import autopilot;
import hardware.hardware;
import config;
import logger;


int main(string[] args)
{
	version(unittest){
		Logger.Success("UnitTest finished ! Congratulations !");
	}
	else{
		Logger.Success("Starting program");

		Autopilot sc = new Autopilot();
		Hardware.Get!Roll(DeviceID.Roll);

		bool b=true;
		while(b){
			
		}
	}
	return 0;
}