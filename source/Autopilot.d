import core.thread;
import std.stdio;
import logger;

class Autopilot{

	this(){
		m_thread = new Thread(&ThreadFunction);
		m_thread.name(typeof(this).stringof);
		m_thread.isDaemon(true);
		m_thread.start();
		Logger.Success(typeof(this).stringof~" instantiation");
	}

	/*!
	@brief Time between two actions on direction
	*/
	@property{
		void loopTimeMS(int n){m_nLoopTimeMS=n;}
		int loopTimeMS(){return m_nLoopTimeMS;}
	}
  
private:
	Thread m_thread;

	void ThreadFunction(){
		while(true){
			Logger.Post("Running "~typeof(this).stringof~" thread");
			m_thread.sleep(dur!("msecs")(m_nLoopTimeMS));
		}
	} 
  
	int m_nLoopTimeMS = 1000;
	float m_fTargetedHeading = 0.;

}