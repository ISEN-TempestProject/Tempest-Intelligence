module sailhandler;

import core.thread;
import std.conv, std.math;

import saillog, config;
import hardware.hardware;

class SailHandler {
	this() {
		SailLog.Post("Starting ",typeof(this).stringof," instantiation in ",Thread.getThis().name,"...");
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

		SailLog.Success(typeof(this).stringof~" instantiated in ",Thread.getThis().name);
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
		float fWind = abs(Hardware.Get!WindDir(DeviceID.WindDir).value);
		auto sail = Hardware.Get!Sail(DeviceID.Sail);

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







unittest {
	import decisioncenter;

	auto dec = DecisionCenter.Get();
	auto sh = dec.sailhandler;
	auto wind = Hardware.Get!WindDir(DeviceID.WindDir);
	auto sail = Hardware.Get!Sail(DeviceID.Sail);

	dec.enabled = false;
	sh.enabled = false;
	Thread.sleep(dur!("msecs")(100));

	wind.isemulated = true;

	wind.value = 20;
	sh.AdjustSail();
	assert(sail.value==sail.max);

	wind.value = wind.max;
	sh.AdjustSail();
	assert(sail.value==sail.min);

	wind.value = wind.min;
	sh.AdjustSail();
	assert(sail.value==sail.min);
}