import std.stdio;
import std.process;
import logger;

enum HardwareID : ubyte{
	Sail,
	Helm,

	Gps,
	Roll,
	WindDir,
	Compass
}

class Hardware {

public:
	//static HWElement Get(HardwareID id){
	//	if(m_inst is null) m_inst = new HWElement();
	//	//return m_inst;
	//}

package:
	void* QueryGet(HardwareID id){
		return cast(void*)0;
	}

	void QuerySet(HardwareID id, void* data){

	}



private:
	this() {
		//Open Pipe


		Logger.Success(typeof(this).stringof~" instantiation");
	}

	static Hardware m_inst;

	Pipe m_pipe;
	//HWElement[HardwareID] m_hwlist;
	//HWWatchdog m_wd;

}