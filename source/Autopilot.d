import core.thread;
import std.stdio;


class Autopilot{

	this(){
		m_thread = new Thread(&ThreadFunction);
		m_thread.name(typeof(this).stringof);
		m_thread.isDaemon(true);
	}
 
	void StartDaemon(in int nLoopTimeMS){
		m_nLoopTimeMS = nLoopTimeMS;
		m_thread.start();
	}
  
private:
	Thread m_thread;

	void ThreadFunction(){
		while(true){
			writeln("Running "~typeof(this).stringof~" thread");

			m_thread.sleep(dur!("msecs")(m_nLoopTimeMS));
		}
	} 
  
	int m_nLoopTimeMS;

}