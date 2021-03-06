module autopilot;

import core.thread;
import core.sync.condition;
import core.sync.mutex;
import saillog, config, decisioncenter;
import hardware.hardware;
import polar;

/**
	Handles the helm in order to follow a heading
*/
class Autopilot{

	this(){
		SailLog.Notify("Starting ",typeof(this).stringof," instantiation in ",Thread.getThis().name," thread...");

		m_bEnabled = true;

		//Start the thread
		m_stopCond = new Condition(new Mutex);
		m_thread = new Thread(&ThreadFunction);
		m_thread.name(typeof(this).stringof);
		m_thread.isDaemon(true);
		m_thread.start();

		SailLog.Success(typeof(this).stringof~" instantiated in ",Thread.getThis().name," thread");
	}
	~this(){
		SailLog.Critical("Destroying ",typeof(this).stringof);
		m_stop = true;
		m_stopCond.notifyAll;
		m_thread.join();
	}

	@property{
		bool enabled()const{return m_bEnabled;}
		void enabled(bool b){m_bEnabled = b;}
	}
  
private:
	Thread m_thread;
	shared bool m_stop = false;
	Condition m_stopCond;
	bool m_bEnabled;

	void ThreadFunction(){
		while(!m_stop){
			try{
				debug(thread){
					SailLog.Post("Running "~typeof(this).stringof~" thread");
				}
				if(m_bEnabled)
					AdjustHelm();

			}catch(Throwable t){
				SailLog.Critical("In thread ",m_thread.name,": ",t.toString);
			}

			synchronized(m_stopCond.mutex) m_stopCond.wait(dur!("msecs")(Config.Get!uint("Autopilot", "Period")));
		}
	}

	/**
		Do a helm adjustment, to maintain the given heading
	*/
	void AdjustHelm(){
		auto comp = Hardware.Get!Compass(DeviceID.Compass);
		auto helm = Hardware.Get!Helm(DeviceID.Helm);
		auto turns = Hardware.Get!TurnSpeed(DeviceID.TurnSpeed);

		//uint nEdgeLocks = Config.Get!uint("Autopilot", "EdgeLocks");
		//float fCommandRatio = Config.Get!float("Autopilot", "CommandRatio");
		//Polar polSpeed = Polar(Config.Get!string("Polars", "HelmSpeed"));

		float fDeltaHead = ((DecisionCenter.Get()).targetheading - comp.value)%360.0;
		if(fDeltaHead<-180.0)
			fDeltaHead+=360.0;
		else if(fDeltaHead>180.0)
			fDeltaHead-=360.0;

		float fNewValue = -fDeltaHead;
		if(fNewValue<-45)fNewValue=-45;
		else if(fNewValue>45)fNewValue=45;

		helm.value = fNewValue;
	}

	int m_nCounter = 0;

	unittest {
		auto dec = DecisionCenter.Get();
		auto ap = dec.autopilot;
		auto comp = Hardware.Get!Compass(DeviceID.Compass);
		auto helm = Hardware.Get!Helm(DeviceID.Helm);
		auto turns = Hardware.Get!TurnSpeed(DeviceID.TurnSpeed);

		pragma(msg, "WARNING: No unittests for the autopilot");

		//dec.enabled = false;
		//ap.enabled = false;
		//Thread.sleep(dur!("msecs")(100));

		//comp.isemulated = true;
		//turns.isemulated = true;
		//dec.targetheading = 90;
		
		////Dont move helm when speed is good
		//comp.value = 90;
		//turns.value = 0;
		//helm.value = helm.init;
		//ap.AdjustHelm();
		//assert(helm.value==helm.init);

		////Move by delta if speed is incorrect
		//comp.value = 90;
		//turns.value = 10;
		//helm.value = helm.init;
		//ap.AdjustHelm();
		//assert(helm.value==10.0);
		//ap.AdjustHelm();
		//assert(helm.value==20.0);
		//turns.value = -10;
		//ap.AdjustHelm();
		//assert(helm.value==10.0);
		//turns.value = 0;
		//ap.AdjustHelm();
		//assert(helm.value==10.0);

		////Delta is a function of DeltaSpeed
		//turns.value = 20;
		//helm.value = helm.init;
		//ap.AdjustHelm();
		//assert(helm.value==20.0);
		//turns.value = -50;
		//ap.AdjustHelm();
		//assert(helm.value==-30.0);
		//turns.value = -15;
		//ap.AdjustHelm();
		//assert(helm.value==-45.0);
		//turns.value = 90;
		//ap.AdjustHelm();
		//assert(helm.value==45.0);

		////Edge-lock: helm should return to init if max is over-reach 5 times
		//turns.value = 0.01;
		//helm.value = helm.max;
		//ap.AdjustHelm();
		//assert(helm.value==helm.max);
		//ap.AdjustHelm();
		//assert(helm.value==helm.max);
		//ap.AdjustHelm();
		//assert(helm.value==helm.max);
		//ap.AdjustHelm();
		//assert(helm.value==helm.max);
		//ap.AdjustHelm();
		//assert(helm.value==helm.init);
		////The counter is reset if the helm turns the other side
		//turns.value = 0.01;
		//helm.value = helm.max;
		//ap.AdjustHelm();
		//assert(helm.value==helm.max);
		//ap.AdjustHelm();
		//assert(helm.value==helm.max);
		//ap.AdjustHelm();
		//assert(helm.value==helm.max);
		//ap.AdjustHelm();
		//assert(helm.value==helm.max);
		//turns.value = -0.01;
		//ap.AdjustHelm();
		//assert(std.math.abs(helm.value-helm.max-0.01)<0.02);
		//turns.value = 0.015;
		//ap.AdjustHelm();
		//assert(helm.value==helm.max);
		//ap.AdjustHelm();
		//assert(helm.value==helm.max);
		//ap.AdjustHelm();
		//assert(helm.value==helm.max);
		//ap.AdjustHelm();
		//assert(helm.value==helm.max);
		//ap.AdjustHelm();
		//assert(helm.value==helm.init);
		////Same the other side
		//turns.value = -0.01;
		//helm.value = helm.min;
		//ap.AdjustHelm();
		//assert(helm.value==helm.min);
		//ap.AdjustHelm();
		//assert(helm.value==helm.min);
		//ap.AdjustHelm();
		//assert(helm.value==helm.min);
		//ap.AdjustHelm();
		//assert(helm.value==helm.min);
		//turns.value = 0.01;
		//ap.AdjustHelm();
		//assert(std.math.abs(helm.value-(helm.min+0.01))<0.01);
		//turns.value = -0.015;
		//ap.AdjustHelm();
		//assert(helm.value==helm.min);
		//ap.AdjustHelm();
		//assert(helm.value==helm.min);
		//ap.AdjustHelm();
		//assert(helm.value==helm.min);
		//ap.AdjustHelm();
		//assert(helm.value==helm.min);
		//ap.AdjustHelm();
		//assert(helm.value==helm.init);

		////Heading diff change targeted speed
		//comp.value = 60;
		//turns.value = 0;
		//helm.value = helm.init;
		//ap.AdjustHelm();
		//assert(std.math.abs(helm.value+20.0)<=0.1);
		//comp.value = 75;
		//ap.AdjustHelm();
		//assert(std.math.abs(helm.value+30.0)<=0.1);
		//comp.value = 90;
		//ap.AdjustHelm();
		//assert(std.math.abs(helm.value+30.0)<=0.1);
		//comp.value = 180;
		//ap.AdjustHelm();
		//assert(std.math.abs(helm.value+10.0)<=0.1);
		//ap.AdjustHelm();
		//assert(std.math.abs(helm.value-10.0)<=0.1);
		//comp.value = 90;
		//ap.AdjustHelm();
		//assert(std.math.abs(helm.value-10.0)<=0.1);
		//comp.value = 75;
		//ap.AdjustHelm();
		//assert(std.math.abs(helm.value)<=0.1);


		//SailLog.Notify("Autopilot unittest done");
	}
}