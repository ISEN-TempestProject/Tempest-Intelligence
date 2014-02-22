module decisioncenter;

import core.thread;
import gpscoord, config, saillog;

class DecisionCenter {

	static DecisionCenter Get(){
		if(m_inst is null)
			m_inst = new DecisionCenter();
		return m_inst;
	}

	@property{
		double targetheading()const{return m_targetheading;}
		GpsCoord targetposition()const{return m_targetposition;}
	}



private:
	static __gshared DecisionCenter m_inst;
	this() {
		m_nLoopTimeMS = Config.Get!uint("DecisionCenter", "Period");

		m_thread = new Thread(&DecisionThread);
		m_thread.name(typeof(this).stringof~"-Network");
		m_thread.isDaemon(true);
		m_thread.start();

		SailLog.Success(typeof(this).stringof~" instantiation");
	}

	Thread m_thread;
	void DecisionThread(){
		while(true){
			SailLog.Post("Running "~typeof(this).stringof~" thread");

			m_thread.sleep(dur!("msecs")(m_nLoopTimeMS));
		}
	}


	double m_targetheading;
	GpsCoord m_targetposition;
	uint m_nLoopTimeMS;
}