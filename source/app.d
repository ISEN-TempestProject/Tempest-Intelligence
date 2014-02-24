module main;

import std.stdio;
import hardware.hardware;
import decisioncenter;
import saillog;


int main(string[] args)
{
	version(unittest){
		SailLog.Success("UnitTest finished ! Congratulations !");
	}
	else{
		SailLog.Success("Starting program");

		DecisionCenter.Get();

		bool b=true;
		while(b){
			
		}
	}
	return 0;
}