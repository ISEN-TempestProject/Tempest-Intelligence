module main;

import std.stdio;
import autopilot;
import hardware.hardware;
import config;
import saillog;

import vibe.vibe;
import Server;


int main(string[] args)
{
	version(unittest){
		SailLog.Success("UnitTest finished ! Congratulations !");
	}
	else{
		if (!finalizeCommandLineOptions())
			return 1;
		
		SailLog.Success("Starting program");

		Autopilot sc = new Autopilot();
		Hardware.Get!Roll(DeviceID.Roll);

		Server server = new Server();
		server.start();

		lowerPrivileges();
		runEventLoop();

	}
	return 0;
}