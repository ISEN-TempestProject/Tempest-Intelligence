module sailhandler;

import core.thread;
import std.conv, std.math;

import saillog, config;
import hardware.hardware;

class SailHandler {
	this() {
		SailLog.Notify("Starting ",typeof(this).stringof," instantiation in ",Thread.getThis().name," thread...");
		//Get configuration
		m_nLoopTimeMS = Config.Get!uint("SailHandler", "Period");
		m_fDelta = Config.Get!float("SailHandler", "Delta");
		m_fDanger = Config.Get!float("SailHandler", "Danger");

		m_nMaxTension = Hardware.Get!Sail(DeviceID.Sail).max;

		m_bEnabled = true;

		//Start the thread
		m_thread = new Thread(&ThreadFunction);
		m_thread.name(typeof(this).stringof);
		m_thread.isDaemon(true);
		m_thread.start();

		SailLog.Success(typeof(this).stringof~" instantiated in ",Thread.getThis().name," thread");
	}
	~this(){
		SailLog.Critical("Destroying ",typeof(this).stringof);
		m_stop = true;
		m_thread.join();
	}


	@property{
		bool enabled()const{return m_bEnabled;}
		void enabled(bool b){m_bEnabled = b;}
	}

private:
	Thread m_thread;
	bool m_stop = false;
	bool m_bEnabled;

	void ThreadFunction(){
		while(!m_stop){
			try{
				debug{
					SailLog.Post("Running "~typeof(this).stringof~" thread");
				}
				if(m_bEnabled)
					AdjustSail();

			}catch(Throwable t){
				SailLog.Critical("In thread ",m_thread.name,": ",t.toString);
			}

			Thread.sleep(dur!("msecs")(m_nLoopTimeMS));
		}
	}

	/**
		Do a sail adjustment, to match the wind direction
	*/
	void AdjustSail(){
		float fWind = abs(Hardware.Get!WindDir(DeviceID.WindDir).value);
		auto sail = Hardware.Get!Sail(DeviceID.Sail);
		auto roll = Hardware.Get!Roll(DeviceID.Roll);

		if(fWind<25){
			sail.value = m_nMaxTension;
		}
		else{
			//Linear function
			sail.value = to!(typeof(sail.value))(m_nMaxTension-(m_nMaxTension-sail.min)*(fWind-25)/(180-25));
		}

		//Handling m_nMaxTension (safety max tension)
		if(abs(roll.value)>m_fDanger && m_nMaxTension>sail.max/4){
			m_nMaxTension--;
		}
		else if(abs(roll.value)<m_fDanger/2.0 && m_nMaxTension<sail.max){
			m_nMaxTension++;
		}
	}


	uint m_nLoopTimeMS;
	float m_fDelta;
	float m_fDanger;

	ubyte m_nMaxTension;
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

	SailLog.Notify("SailHandler unittest done");
}