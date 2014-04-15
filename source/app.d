module main;

import std.stdio;
import hardware.hardware;
import decisioncenter;
import saillog;

import vibe.vibe;
import Server;

import core.sys.posix.signal;
extern(C) void SigHdl(int sig) nothrow{
	bQuit = true;
	try getEventDriver.exitEventLoop();
	catch(Throwable t){}
}
bool bQuit = false;

int main(string[] args)
{
	signal(SIGINT, &SigHdl);
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
	SailLog.Critical("Exiting program !");
	DecisionCenter.Get().destroy;
	Hardware.GetClass().destroy;
	return 0;
}