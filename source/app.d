module main;

import std.stdio;
import hardware.hardware;
import decisioncenter;
import saillog;
import core.thread;

import core.sys.posix.signal;
extern(C) void SigHdl(int sig) nothrow{
	bQuit = true;
}
bool bQuit = false;

int main(string[] args)
{
	Thread.getThis().name = "Main";
	signal(SIGINT, &SigHdl);
	version(unittest){
		SailLog.Success("UnitTest finished ! Congratulations !");
	}
	else{
		SailLog.Success("Starting program !");

		DecisionCenter.Get();

		while(!bQuit){
			Thread.sleep(dur!("msecs")(100));
		}
	}
	SailLog.Critical("Exiting program !");
	DecisionCenter.Get().destroy;
	Hardware.GetClass().destroy;
	return 0;
}