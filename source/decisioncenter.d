module decisioncenter;

import core.thread;
import std.json, std.file, std.conv, std.string, std.math;
import hardware.hardware, gpscoord, config, saillog, polar;

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

	/**
		Back to the starting position, registering the position
	*/
	void backToStartPosition(){
		GpsCoord start = m_route[0];
		GpsCoord now = Hardware.Get!Gps(DeviceID.Gps).value();
		m_route = [now, start];

		//next destination is the starting one
		m_nDestinationIndex = 0;
	}

	void StartWithGPS(in GpsCoord startpoint){
		if(!m_bStartedWithGPS){
			m_bStartedWithGPS = true;
			enabled(true);

			m_route = startpoint~m_route;

			if(Config.Get!bool("DecisionCenter", "ReturnToOrigin"))
				m_route~=startpoint;

			SailLog.Success("The complete route is: ",m_route);

			//	fill first cell with actual GPS position
			MakeDecision();//Will update m_targetposition and m_targetheading

			m_autopilot = new Autopilot();
			m_sailhandler = new SailHandler();

			m_thread = new Thread(&DecisionThread);
			m_thread.name(typeof(this).stringof);
			m_thread.isDaemon(true);
			m_thread.start();

			SailLog.Success("First GPS Coordinate received (",startpoint,") ! You RRRRRR ready to sail !");
		}
		else
			SailLog.Warning("Called DecisionCenter.StartWithGPS when already started with GPS previously");
	}



private:
	static __gshared DecisionCenter m_inst;
	/**
		Does the Autopilot and SailHandler instantiation
	*/
	this() {
		SailLog.Notify("Starting ",typeof(this).stringof," instantiation in ",Thread.getThis().name," thread...");

		m_nLoopTimeMS = Config.Get!uint("DecisionCenter", "Period");
		m_bEnabled = false;//Will be enabled by GPS device on first coordinate

		m_fDistanceToTarget = Config.Get!float("DecisionCenter", "DistanceToTarget");
		m_fDistanceToRoute = Config.Get!float("DecisionCenter", "DistanceToRoute");

		//Route parsing
		string sFile = Config.Get!string("DecisionCenter", "RestoreRoute");
		if(exists(sFile)){
            readRoute(sFile);
		}
		else {
    		sFile = Config.Get!string("DecisionCenter", "Route");
    		readRoute(sFile);
    	}

		m_nDestinationIndex = 1;
		SailLog.Notify("Route set to: ",m_route, ". Waiting for first GPS coordinate...");
		
		string sPolWind = Config.Get!string("Polars", "Wind");
		string sPolHeading = Config.Get!string("Polars", "Heading");
		m_polarWind = Polar(sPolWind);
        m_polarHeading = Polar(sPolHeading);
		SailLog.Notify("Using polars: ",sPolWind,", ",sPolHeading);

		//Instanciate hardware class
		Hardware.GetClass();

		SailLog.Success(typeof(this).stringof~" instantiated in ",Thread.getThis().name," thread");

		version(unittest){
			StartWithGPS(GpsCoord(0,0));
		}
		else{
		    if(Config.Get!bool("DecisionCenter", "StartWithoutGPS")) StartWithGPS(GpsCoord(0,0));
		}
	}
	~this(){
		SailLog.Critical("Destroying ",typeof(this).stringof);
		m_stop = true;

		m_autopilot.destroy;
		m_sailhandler.destroy;
		
		m_thread.join();
	}

	Thread m_thread;
	bool m_stop = false;
	void DecisionThread(){
		while(!m_stop){
			try{
				debug{
					SailLog.Post("Running "~typeof(this).stringof~" thread");
				}
				if(m_bEnabled)
					MakeDecision();

			}catch(Throwable t){
				SailLog.Critical("In thread ",m_thread.name,": ",t.toString);
			}

			Thread.sleep(dur!("msecs")(m_nLoopTimeMS));
		}
	}

	/**
		THIS IS WHERE DECISIONS ARE TAKEN
	*/
	void MakeDecision(){

	    //Check if target is reached
		CheckIsDestinationReached(); //Updates m_targetposition

		//Heading
	    checkDistanceToRoute();
	    m_targetheading = getHeadingAngle();
	}
	
	
	/**
	    Factors applied on each polar vector (among its importance)
	*/
	enum PolarFactor : float {
	    Wind = 1.0,
	    Heading = 1.0
	}
	
	/**
	    Get an optimized heading angle using polars.
	    Using AIUR.
	*/
	float getHeadingAngle(){
        //Reading fixed values (references)
            //Target heading
        float _targetDirection = (to!float(Hardware.Get!Gps(DeviceID.Gps).value.GetBearingTo(targetposition())) + 360.0 ) % 360.0;
        float compassAngle = (to!float(Hardware.Get!Compass(DeviceID.Compass).value));
        float heading_angle = _targetDirection - compassAngle;
        if(isNaN(heading_angle)) heading_angle = 0;
        
            //Wind direction
        float wind_angle = Hardware.Get!WindDir(DeviceID.WindDir).value();
            
        //Result vector = 0
        float result = 0.0, res_sum = 0.0;
        float h_vect, w_vect, s_vector;
        
        //Solve "equation" on polars
            //Move wind ruler (cap ruler is fixed at time t) from min (0) to max (360). For each position :
        for(float i=0.0 ; i<=360.0 ; i=i+1.0){        
                //get boat heading vector (== pos 0 of wind ruler)
            h_vect = m_polarHeading.getValue(i - heading_angle);
                //get wind vector (position fixed)
            w_vect = m_polarWind.getValue(wind_angle - i);
                //apply coefs on those 2 vectors and sum them
            s_vector  = ( h_vect * PolarFactor.Heading ) * ( w_vect * PolarFactor.Wind );
            //DBG : SailLog.Post("s_vector (",i,") : ", s_vector , "[w", w_vect, ";h", h_vect,"]");
                //is the vector greater than result vector ?
            if(s_vector > res_sum){
                    //YES : result vector = this new vector position
                res_sum = s_vector;
                result = i;
            }
                    //NO : do nothing

        }
            
        //Return result vector (== heading angle) 
        return (result + compassAngle + 360.0) % 360.0;
	}
	
	/**
	    Checks if the distance to the route is not too important.
	    Forces the boat to turn by disablig a side of the polars.
	*/
	void checkDistanceToRoute(){
	    float distanceToRoute = to!float(Hardware.Get!Gps(DeviceID.Gps).value.GetDistanceToRoute(m_route[m_nDestinationIndex - 1], m_route[m_nDestinationIndex] ));
	    
	    if(distanceToRoute > m_fDistanceToRoute){
	        //Right : disable right side
	        m_polarHeading.setSide(true, false);
	    }
	    else if( -distanceToRoute > m_fDistanceToRoute){
	        //Left : disable left side
	        m_polarHeading.setSide(false, true);
	    }
	    else{
	        //Enable both sides
	        m_polarHeading.setSide();
	    }
	}

	void CheckIsDestinationReached(){
		GpsCoord currPos = Hardware.Get!Gps(DeviceID.Gps).value;
		float fDistance = currPos.GetDistanceTo(m_route[m_nDestinationIndex]);
		SailLog.Warning("Distance : ", fDistance);
		if(fDistance<=m_fDistanceToTarget){
			m_nDestinationIndex++;
			SailLog.Notify("Set new target to ",m_route[m_nDestinationIndex].To(GpsCoord.Unit.DecDeg)," (index=",m_nDestinationIndex,")");
		    
		    //Set RestoreRoute file
		    string sFile = Config.Get!string("DecisionCenter", "RestoreRoute");
		    File restoreFile;
		    restoreFile.open(sFile, "w+");
		    restoreFile.writeln("[");
            for(int i = m_nDestinationIndex ; i < m_route.length-1 ; i++){
                restoreFile.write("{\"unit\":\"DecDeg\", \"value\":\"", m_route[i].To(GpsCoord.Unit.DecDeg) ,"\"}");
                if(i < m_route.length-2)restoreFile.writeln(",");
            }
            restoreFile.writeln("\n]");
            restoreFile.flush();
            restoreFile.close();
		}
	}
	
	void readRoute(string sFile){
        try{
            JSONValue jsonFile = parseJSON(readText(sFile).removechars("\n\r\t"));
    
            GpsCoord.Unit unit;
            foreach(ref json ; jsonFile.array){
                try{
                    switch(json["unit"].str){
                        case "DecDeg": unit=GpsCoord.Unit.DecDeg; break;
                        case "DegMinSec": unit=GpsCoord.Unit.DegMinSec; break;
                        case "GPS": unit=GpsCoord.Unit.GPS; break;
                        default: unit=GpsCoord.Unit.DecDeg;    break;
                    }
                    m_route~=GpsCoord(unit, json["value"].str);
                }catch(Exception e){
                    SailLog.Warning("Ignoring route Waypoint: ", e);
                }
            }
        }catch(Exception e){
            SailLog.Critical("Unable to read Route (",sFile,"): ", e);
        }
	}

	bool m_bEnabled;
	bool m_bStartedWithGPS = false;
	double m_targetheading = 0;
	uint m_nLoopTimeMS;

	Autopilot m_autopilot;
	SailHandler m_sailhandler;

	float m_fDistanceToTarget;
	float m_fDistanceToRoute;

	ushort m_nDestinationIndex;
	GpsCoord[] m_route;
	
	Polar m_polarWind, m_polarHeading;

}