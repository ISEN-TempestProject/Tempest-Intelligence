import core.thread;
import std.stdio;


class Autopilot{

	this(){
		m_thread = new Thread(&ThreadFunction);
		m_thread.name(typeof(this).stringof);
		m_thread.isDaemon(true);
		m_thread.start();
	}

	/**
	@brief The desired orientation (heading) of the boat
	**/
	@property{
		void TargetedHeading(float f){m_fTargetedHeading=f;}
		int TargetedHeading(){return m_nLoopTimeMS;}
	}

	/**
	@brief Time between two actions on direction
	**/
	@property{
		void LoopTimeMS(int n){m_nLoopTimeMS=n;}
		int LoopTimeMS(){return m_nLoopTimeMS;}
	}
  
private:
	Thread m_thread;

	void ThreadFunction(){
		while(true){
			writeln("Running "~typeof(this).stringof~" thread");
			m_thread.sleep(dur!("msecs")(m_nLoopTimeMS));
		}
	} 
  
	int m_nLoopTimeMS = 1000;
	float m_fTargetedHeading = 0.;

}