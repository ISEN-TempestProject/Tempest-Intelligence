module main;

import std.stdio;
import std.getopt;
import hardware.hardware;
import decisioncenter;
import saillog;
import config;

import vibe.vibe;
import server;

import core.sys.posix.signal;
extern(C) @system
void SigHdl(int sig) nothrow{
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
		if (!finalizeCommandLineOptions(&args))
			return 1;

		bool bRestart = false;
		bool bStartWithoutGPS = false;
		bool bNoSocket = false;
		getopt(
		    args,
		    "Restart|r",  &bRestart,
		    "StartWithoutGPS|g", &bStartWithoutGPS,
		    "NoSocket|s", &bNoSocket
		    );

		if(bRestart){
			string sRoute = Config.Get!string("DecisionCenter", "RestoreRoute");
			if(std.file.exists(sRoute))
				std.file.remove(sRoute);
		}
		if(bStartWithoutGPS)
			Config.Set!bool("DecisionCenter", "StartWithoutGPS", true);
		if(bNoSocket)
			Config.Set!bool("Global", "ConnectSockets", false);

		
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
