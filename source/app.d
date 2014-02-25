module main;

import std.stdio;
import hardware.hardware;
import decisioncenter;
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

		DecisionCenter.Get();

		Server server = new Server();
		server.start();

		lowerPrivileges();
		runEventLoop();

	}
	return 0;
}