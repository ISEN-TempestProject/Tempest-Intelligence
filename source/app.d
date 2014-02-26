module main;

import std.stdio;
import hardware.hardware;
import decisioncenter;
import saillog;
import core.thread;


int main(string[] args)
{
	Thread.getThis().name = "Main";
	version(unittest){
		SailLog.Success("UnitTest finished ! Congratulations !");
	}
	else{
		SailLog.Success("Starting program !");

		DecisionCenter.Get();

		bool b=true;
		while(b){
			
		}
	}
	return 0;
}