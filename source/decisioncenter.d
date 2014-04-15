module decisioncenter;

import core.thread;
import std.json, std.file, std.conv, std.string;
import hardware.hardware, gpscoord, config, saillog;

public import autopilot, sailhandler;

/**
	Singleton class where all decisions are taken, to guide the boat
*/
class DecisionCenter {

	/**
		Singleton getter
	*/
	static DecisionCenter Get(){
		synchronized{
			if(m_inst is null)
				m_inst = new DecisionCenter();
		}
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
		GpsCoord targetposition()const{return m_route[m_nDestinationIndex];}
		void targetposition(GpsCoord target){m_route[m_nDestinationIndex] = target;}
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
		SailHandler sailhandler(){return m_sailhandler;}
	}



private:
	static __gshared DecisionCenter m_inst;
	/**
		Does the Autopilot and SailHandler instantiation
	*/
	this() {
		SailLog.Notify("Starting ",typeof(this).stringof," instantiation in ",Thread.getThis().name," thread...");

		m_nLoopTimeMS = Config.Get!uint("DecisionCenter", "Period");
		m_bEnabled = true;

		m_fDistanceToTarget = Config.Get!float("DecisionCenter", "DistanceToTarget");

		//Route parsing
		string sFile = Config.Get!string("DecisionCenter", "Route");
		try{
			JSONValue jsonFile = parseJSON(readText(sFile).removechars("\n\r\t"));

			GpsCoord.Unit unit;
			foreach(ref json ; jsonFile.array){
				try{
					switch(json["unit"].str){
						case "DecDeg": unit=GpsCoord.Unit.DecDeg; break;
						case "DegMinSec": unit=GpsCoord.Unit.DegMinSec; break;
						case "GPS": unit=GpsCoord.Unit.GPS; break;
						default: unit=GpsCoord.Unit.DecDeg;	break;
					}
					m_route~=GpsCoord(unit, json["value"].str);
				}catch(Exception e){
					SailLog.Warning("Ignoring route Waypoint: ", e);
				}
			}
		}catch(Exception e){
			SailLog.Critical("Unable to read Route (",sFile,"): ", e);
		}
		m_route = (Hardware.Get!Gps(DeviceID.Gps).value)~m_route;

		if(Config.Get!bool("DecisionCenter", "ReturnToOrigin"))
			m_route~=m_route[0];

		m_nDestinationIndex = 1;
		SailLog.Notify("Route set to: ",m_route);
		
		//	fill first cell with actual GPS position
		MakeDecision();//Will update m_targetposition and m_targetheading

		m_autopilot = new Autopilot();
		m_sailhandler = new SailHandler();
		
		m_polarWind = Polar("./res/polar_wind.json");
		m_polarHeading = Polar("./res/polar_heading.json");

		m_thread = new Thread(&DecisionThread);
		m_thread.name(typeof(this).stringof);
		m_thread.isDaemon(true);
		m_thread.start();

		SailLog.Success(typeof(this).stringof~" instantiated in ",Thread.getThis().name," thread");
	}

	Thread m_thread;
	void DecisionThread(){
		while(true){
			try{
				debug{
					SailLog.Post("Running "~typeof(this).stringof~" thread");
				}
				if(m_bEnabled)
					MakeDecision();

				m_thread.sleep(dur!("msecs")(m_nLoopTimeMS));
			}catch(Throwable t){
				SailLog.Critical("In thread ",m_thread.name,": ",t.toString);
			}
		}
	}

	/**
		THIS IS WHERE DECISIONS ARE TAKEN
	*/
	void MakeDecision(){
		/*
		THIS IS WHERE DECISIONS ARE TAKEN
		*/

		CheckIsDestinationReached();
	}

	void CheckIsDestinationReached(){
		GpsCoord currPos = Hardware.Get!Gps(DeviceID.Gps).value;
		float fDistance = currPos.GetDistanceTo(m_route[m_nDestinationIndex]);
		if(fDistance<=m_fDistanceToTarget){
			m_nDestinationIndex++;
			SailLog.Notify("Set new target to ",m_route[m_nDestinationIndex].To(GpsCoord.Unit.DecDeg)," (index=",m_nDestinationIndex,")");
		}
	}

	bool m_bEnabled;
	double m_targetheading;
	uint m_nLoopTimeMS;

	Autopilot m_autopilot;
	SailHandler m_sailhandler;

	float m_fDistanceToTarget;

	ushort m_nDestinationIndex;
	GpsCoord[] m_route;
	
	Polar m_polarWind, m_polarHeading;

}