module autopilot;

import core.thread;
import saillog, config, decisioncenter;
import hardware.hardware;

/**
	Handles the helm in order to follow a heading
*/
class Autopilot{

	this(){
		//Get configuration
		m_nLoopTimeMS = Config.Get!uint("Autopilot", "Period");
		m_fDelta = Config.Get!float("Autopilot", "Delta");
		m_fTolerance = Config.Get!float("Autopilot", "Tolerance");

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
				AjustHelm();

			m_thread.sleep(dur!("msecs")(m_nLoopTimeMS));
		}
	}

	/**
		Do a helm adjustment, to maintain the given heading
	*/
	void AjustHelm(){
		auto comp = Hardware.Get!Compass(DeviceID.Compass);
		auto helm = Hardware.Get!Helm(DeviceID.Helm);

		float fDeltaHead = (DecisionCenter.Get()).targetheading - comp.value;
		SailLog.Post(fDeltaHead);

		if(fDeltaHead>m_fTolerance){
			float fNewValue = helm.value + m_fDelta;

			if(fNewValue>helm.max)
				helm.value = helm.init;
			else
				helm.value = fNewValue;
		}
		else if(fDeltaHead<m_fTolerance){
			float fNewValue = helm.value - m_fDelta;
			
			if(fNewValue<helm.min)
				helm.value = helm.init;
			else
				helm.value = fNewValue;
		}
	}
  
	uint m_nLoopTimeMS;
	float m_fDelta;
	float m_fTolerance;

	unittest {
		auto dec = DecisionCenter.Get();
		auto ap = dec.autopilot;
		auto comp = Hardware.Get!Compass(DeviceID.Compass);
		auto helm = Hardware.Get!Helm(DeviceID.Helm);

		dec.enabled = false;
		ap.enabled = false;
		Thread.sleep(dur!("msecs")(100));

		comp.isemulated = true;
		comp.value = 20;
		dec.targetheading = 25;

		//Delta compensation
		helm.value = helm.init;
		ap.AjustHelm();
		assert(helm.value==helm.init+ap.m_fDelta);
		ap.AjustHelm();
		ap.AjustHelm();
		assert(helm.value==helm.init+3*ap.m_fDelta);

		//return to init position
		helm.value = helm.max - ap.m_fDelta/2;
		ap.AjustHelm();
		assert(helm.value == helm.init);

		//-delta compensation
		dec.targetheading = 15;
		ap.AjustHelm();
		assert(helm.value == helm.init-ap.m_fDelta);
	}
}