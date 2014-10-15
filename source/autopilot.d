module autopilot;

import core.thread;
import saillog, config, decisioncenter;
import hardware.hardware;
import polar;

/**
	Handles the helm in order to follow a heading
*/
class Autopilot{

	this(){
		SailLog.Notify("Starting ",typeof(this).stringof," instantiation in ",Thread.getThis().name," thread...");

		//Get configuration
		m_nLoopTimeMS = Config.Get!uint("Autopilot", "Period");
		m_fDelta = Config.Get!float("Autopilot", "Delta");
		m_fTolerance = Config.Get!float("Autopilot", "Tolerance");
		m_polSpeed = Polar(Config.Get!string("Polars", "HelmSpeed"));

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
					AdjustHelm();

			}catch(Throwable t){
				SailLog.Critical("In thread ",m_thread.name,": ",t.toString);
			}

			Thread.sleep(dur!("msecs")(m_nLoopTimeMS));
		}
	}

	/**
		Do a helm adjustment, to maintain the given heading
	*/
	void AdjustHelm(){
		auto comp = Hardware.Get!Compass(DeviceID.Compass);
		auto helm = Hardware.Get!Helm(DeviceID.Helm);
		auto turns = Hardware.Get!TurnSpeed(DeviceID.TurnSpeed);

		float fDeltaHead = ((DecisionCenter.Get()).targetheading - comp.value)%360.0;
		//if(fDeltaHead<-180.0)
		//	fDeltaHead+=360.0;
		//else if(fDeltaHead>180.0)
		//	fDeltaHead-=360.0;

		//TurnSpeed the boat should have
		float fTrgSpeed = m_polSpeed.getValue(fDeltaHead);

		//TurnSpeed the boat have
		float fSpeed = turns.value;


		float fDeltaSpeed = fTrgSpeed - fSpeed;
		if(fDeltaSpeed<0.0){
			//The boat should turn faster to the right
			float fNewValue = helm.value + std.math.abs(fDeltaSpeed) * Config.Get!float("Autopilot", "CommandRatio");

			if(fNewValue>helm.max){
				m_nCounter++;
				if(m_nCounter>=Config.Get!int("Autopilot", "EdgeLocks")){
					helm.value = helm.init;
					m_nCounter = 0;
				}
				else
					helm.value = helm.max;
			}
			else
			{
				helm.value = fNewValue;
				m_nCounter = 0;
			}
		}
		else if(fDeltaSpeed>0.0){
			//The boat should turn faster to the left
			float fNewValue = helm.value - std.math.abs(fDeltaSpeed) * Config.Get!float("Autopilot", "CommandRatio");

			if(fNewValue>helm.min){
				m_nCounter++;
				if(m_nCounter>=Config.Get!int("Autopilot", "EdgeLocks")){
					helm.value = helm.init;
					m_nCounter = 0;
				}
				else
					helm.value = helm.min;
			}
			else
			{
				helm.value = fNewValue;
				m_nCounter = 0;
			}
		}
	}
  
	uint m_nLoopTimeMS;
	float m_fDelta;
	float m_fTolerance;
	Polar m_polSpeed;

	int m_nCounter = 0;

	unittest {
		auto dec = DecisionCenter.Get();
		auto ap = dec.autopilot;
		auto comp = Hardware.Get!Compass(DeviceID.Compass);
		auto helm = Hardware.Get!Helm(DeviceID.Helm);
		auto turns = Hardware.Get!TurnSpeed(DeviceID.TurnSpeed);

		dec.enabled = false;
		ap.enabled = false;
		Thread.sleep(dur!("msecs")(100));

		comp.isemulated = true;
		turns.isemulated = true;
		dec.targetheading = 90;
		
		//Dont move helm when speed is good
		comp.value = 90;
		turns.value = 0;
		helm.value = helm.init;
		ap.AdjustHelm();
		assert(helm.value==helm.init);

		//Move by delta if speed is incorrect
		comp.value = 90;
		turns.value = 10;
		helm.value = helm.init;
		ap.AdjustHelm();
		assert(helm.value==10.0);
		ap.AdjustHelm();
		assert(helm.value==20.0);

		


		//assert(std.math.abs(helm.value-(helm.init+ap.m_fDelta+0.2))<0.01);
		//ap.AdjustHelm();
		//ap.AdjustHelm();
		//assert(std.math.abs(helm.value-(helm.init+3*(ap.m_fDelta+0.2)))<0.01);

		////return to init position
		//helm.value = helm.max - ap.m_fDelta/2;
		//ap.AdjustHelm();
		//assert(helm.value == helm.max);
		//ap.AdjustHelm();
		//assert(helm.value == helm.max);
		//ap.AdjustHelm();
		//assert(helm.value == helm.max);
		//ap.AdjustHelm();
		//assert(helm.value == helm.max);
		//ap.AdjustHelm();
		//assert(helm.value == helm.init);

		////-delta compensation
		//helm.value = helm.init;
		//dec.targetheading = 15;
		//ap.AdjustHelm();
		//assert(std.math.abs(helm.value-(helm.init-(ap.m_fDelta+0.2)))<0.01);

		SailLog.Notify("Autopilot unittest done");
	}
}