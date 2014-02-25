module sailhandler;

import core.thread;
import std.conv;

import saillog, config;
import hardware.hardware;

class SailHandler {
	this() {
		//Get configuration
		m_nLoopTimeMS = Config.Get!uint("SailHandler", "Period");
		m_fDelta = Config.Get!float("SailHandler", "Delta");
		m_fDanger = Config.Get!float("SailHandler", "Danger");

		m_bEnabled = true;

		//Start the thread
		m_thread = new Thread(&ThreadFunction);
		m_thread.name(typeof(this).stringof);
		m_thread.isDaemon(true);
		m_thread.start();

		SailLog.Success(typeof(this).stringof~" instantiation");
	}


	@property{
		bool enabled()const{return m_bEnabled;}
		void enabled(bool b){m_bEnabled = b;}
	}

private:
	Thread m_thread;
	bool m_bEnabled;

	void ThreadFunction(){
		while(true){
			debug{
				SailLog.Post("Running "~typeof(this).stringof~" thread");
			}
			if(m_bEnabled)
				AdjustSail();

			m_thread.sleep(dur!("msecs")(m_nLoopTimeMS));
		}
	}

	/**
		Do a sail adjustment, to match the wind direction
	*/
	void AdjustSail(){
		float fWind = Hardware.Get!WindDir(DeviceID.WindDir).value;
		auto sail = Hardware.Get!Sail(DeviceID.Sail);

		if(fWind>180)
			fWind = 360-fWind;

		if(fWind<25){
			sail.value = sail.max;
		}
		else{
			//Linear function
			sail.value = to!(typeof(sail.value))(sail.max-(sail.max-sail.min)*(fWind-25)/(180-25));
		}



	}


	uint m_nLoopTimeMS;
	float m_fDelta;
	float m_fDanger;
}