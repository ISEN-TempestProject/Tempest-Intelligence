module autopilot;

import core.thread;
import std.stdio;
import saillog;
import config;

/*!
	@brief Handles the helm in order to follow a heading
*/
class Autopilot{

	this(){
		//Get configuration
		m_nLoopTimeMS = Config.Get!uint("Autopilot", "Period");
		m_fDelta = Config.Get!float("Autopilot", "Delta");
		m_fTolerance = Config.Get!float("Autopilot", "Tolerance");

		//Start the thread
		m_thread = new Thread(&ThreadFunction);
		m_thread.name(typeof(this).stringof);
		m_thread.isDaemon(true);
		m_thread.start();

		SailLog.Success(typeof(this).stringof~" instantiation");
	}

	/*!
	@brief Targeted heading
	*/
	@property{
		void heading(float n){m_fTargetedHeading=n;}
		float heading(){return m_fTargetedHeading;}
	}
  
private:
	Thread m_thread;

	void ThreadFunction(){
		while(true){
			SailLog.Post("Running "~typeof(this).stringof~" thread");
			AjustHelm();
			m_thread.sleep(dur!("msecs")(m_nLoopTimeMS));
		}
	}

	void AjustHelm(){
		
	}
  
	uint m_nLoopTimeMS;
	float m_fDelta;
	float m_fTolerance;

	float m_fTargetedHeading = 0.;

}