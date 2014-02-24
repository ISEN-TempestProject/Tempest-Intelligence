module decisioncenter;

import core.thread;
import gpscoord, config, saillog;

public import autopilot;

/**
	Singleton class where all decisions are taken, to guide the boat
*/
class DecisionCenter {

	/**
		Singleton getter
	*/
	static DecisionCenter Get(){
		if(m_inst is null)
			m_inst = new DecisionCenter();
		return m_inst;
	}

	/**
		Get/Set the targetted heading
		Notes: Will modify autopilot heading
	*/
	@property{
		double targetheading()const{return m_targetheading;}
		void targetheading(double target){m_targetheading = target;}
	}

	/**
		Get/set the targeted position
	*/
	@property{
		GpsCoord targetposition()const{return m_targetposition;}
		void targetposition(GpsCoord target){m_targetposition = target;}
	}

	/**
		Enable/disable the decision center thread (=ArtificialIntelligence)
	*/
	@property{
		bool enabled()const{return m_bEnabled;}
		void enabled(bool b){m_bEnabled = b;}
	}

	/**
		Getter for Autopilot and SailHandler classes
	*/
	@property{
		Autopilot autopilot(){return m_autopilot;}
		//SailHandler sailhandler()const{return m_sailhandler;}
	}



private:
	static __gshared DecisionCenter m_inst;
	/**
		Does the Autopilot and SailHandler instantiation
	*/
	this() {
		m_nLoopTimeMS = Config.Get!uint("DecisionCenter", "Period");
		m_bEnabled = true;
		//@todo: Parse values from config to fill m_route
		//	fill first cell with actual GPS position
		MakeDecision();//Will update m_targetposition and m_targetheading

		m_autopilot = new Autopilot();
		//m_sailhandler = new SailHandler();

		m_thread = new Thread(&DecisionThread);
		m_thread.name(typeof(this).stringof);
		m_thread.isDaemon(true);
		m_thread.start();

		SailLog.Success(typeof(this).stringof~" instantiation");
	}

	Thread m_thread;
	void DecisionThread(){
		while(true){
			debug{
				SailLog.Post("Running "~typeof(this).stringof~" thread");
			}
			if(m_bEnabled)
				MakeDecision();

			m_thread.sleep(dur!("msecs")(m_nLoopTimeMS));
		}
	}

	/**
		THIS IS WHERE DECISIONS ARE TAKEN
	*/
	void MakeDecision(){
		/*
		THIS IS WHERE DECISIONS ARE TAKEN
		*/
	}

	bool m_bEnabled;
	double m_targetheading;
	GpsCoord m_targetposition;
	uint m_nLoopTimeMS;

	Autopilot m_autopilot;
	//SailHandler m_sailhandler;

	GpsCoord[] m_route;
}