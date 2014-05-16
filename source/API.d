module api;

import vibe.http.rest;
import vibe.core.log;
import vibe.data.json;
import std.datetime;
import saillog;
import gpscoord;
import hardware.hardware;
import hardware.devices;
import decisioncenter;

interface ISailAPI
{
	// GET /devices
	Json getDevices();

	// GET /:id/devices
	Json getDevices(int id);

	// POST /:id/value
	void postValue(string data);
	
	// POSt /gps
	void postGps(float latitude, float longitude);

	// POST /:id/emulation
	void postEmulation(string data);

	// GET /logs
	Json getLogs();

	// GET /dc
	Json getDc();

	// POST /dc
	void postDc(bool status);

	// POST /targetposition
	void postTargetposition(float latitude, float longitude);

	// POST /targetheading
	void postTargetheading(float angle);

	// GET /autopilot
	Json getAutopilot();

	// POST /autopilot
	void postAutopilot(bool status);

	// GET /sh
	Json getSh();

	// POST /sh
	void postSh(bool status);

	// POST /emergency
	void postEmergency();

	// POST /backtostart
	void postBacktostart();

}


class API : ISailAPI
{

	/**
		Singleton getter
	*/
	static API Get(){
		if(m_inst is null)
			m_inst = new API();
		return m_inst;
	}


	Json getDevices()
	{
		Json devices = Json.emptyArray;
		foreach(device; DeviceID.min+1 .. DeviceID.max+1)
		{
				devices ~= getDevices(device);
		}
		return devices;
	}	


	Json getDevices(int id_)
	{
		DeviceID id = cast(DeviceID) id_ ;
		Json device = Json.emptyObject;
		switch(id){
			case DeviceID.Roll: 
				Roll roll = Hardware.Get!Roll(id);
				device.id = roll.id();
				device.name = "Roll";
				device.emulated = roll.isemulated();
				device.value = roll.value();
				break;
			case DeviceID.WindDir: 
				WindDir wd = Hardware.Get!WindDir(id);
				device.id = wd.id();
				device.name = "Wind direction";
				device.emulated = wd.isemulated();
				device.value = wd.value();
				break;
			case DeviceID.Compass: 
				Compass compass = Hardware.Get!Compass(id);
				device.id = compass.id();
				device.name = "Compass";
				device.emulated = compass.isemulated();
				device.value = compass.value();
				break;
			case DeviceID.Sail:
				Sail sail = Hardware.Get!Sail(id);
				device.id = sail.id();
				device.name = "Sail";
				device.emulated = sail.isemulated();
				device.value = to!int(sail.value());
				break;	
			case DeviceID.Helm:
				Helm helm = Hardware.Get!Helm(id);
				device.id = helm.id();
				device.name = "Helm";
				device.emulated = helm.isemulated();
				device.value = helm.value();
				break;
			case DeviceID.Gps:
				Gps gps = Hardware.Get!Gps(id);
				device.id = gps.id();
				device.name = "GPS";
				device.emulated = gps.isemulated();
				device.value = Json.emptyObject;
				device.value.longitude = GpsCoord.toDeg(gps.value().longitude());
				device.value.latitude = GpsCoord.toDeg(gps.value().latitude());
				break;
			case DeviceID.Battery:
                Battery battery = Hardware.Get!Battery(id);
                device.id = battery.id();
                device.name = "Battery";
                device.emulated = battery.isemulated();
                device.value = battery.value();
                break;
			default:
				SailLog.Warning("Called unknown Device ID. Sending empty object.");
				return parseJsonString("{}");
		}

		//common values
		device.lowCaption = "-";
		device.highCaption = "+";
		device.delta = 1; //must be integer for ubyte type !

		return device;

		
	}
	
	void postGps(float latitude, float longitude){
	    Gps gps = Hardware.Get!Gps(DeviceID.Gps);
	    
	    gps.value(GpsCoord(GpsCoord.toRad(latitude), GpsCoord.toRad(longitude)));
        SailLog.Notify("GPS set to [",gps.value().latitude(),";",gps.value().longitude(),"]");
	}

	void postEmulation(string data){
		Json device = parseJsonString(data);
		switch(to!ubyte(device.id)){
			case DeviceID.Roll: 
				Roll roll = Hardware.Get!Roll(cast(DeviceID) to!ubyte(device.id));
				roll.isemulated(to!bool(device.emulated));
				break;
			case DeviceID.WindDir: 
				WindDir wd = Hardware.Get!WindDir(cast(DeviceID) to!ubyte(device.id));
				wd.isemulated(to!bool(device.emulated));
				break;
			case DeviceID.Compass: 
				Compass compass = Hardware.Get!Compass(cast(DeviceID) to!ubyte(device.id));
				compass.isemulated(to!bool(device.emulated));
				break;
			case DeviceID.Sail:
				Sail sail = Hardware.Get!Sail(cast(DeviceID) to!ubyte(device.id));
				sail.isemulated(to!bool(device.emulated));
				break;	
			case DeviceID.Helm:
				Helm helm = Hardware.Get!Helm(cast(DeviceID) to!ubyte(device.id));
				helm.isemulated(to!bool(device.emulated));
				break;
			case DeviceID.Gps:
				Gps gps = Hardware.Get!Gps(cast(DeviceID) to!ubyte(device.id));
				gps.isemulated(to!bool(device.emulated));
				break;
			case DeviceID.Battery:
                Battery battery = Hardware.Get!Battery(cast(DeviceID) to!ubyte(device.id));
                battery.isemulated(to!bool(device.emulated));
                break;
			default:
				SailLog.Warning("Called unknown Device ID. No device set.");
		}
	}


	void postValue(string data){
		SailLog.Post("Device set : " ~ data);
		Json device = parseJsonString(data);
		switch(to!ubyte(device.id)){
			case DeviceID.Roll: 
				Roll roll = Hardware.Get!Roll(cast(DeviceID) to!ubyte(device.id));
				roll.value(device.value.to!float);
				break;
			case DeviceID.WindDir: 
				WindDir wd = Hardware.Get!WindDir(cast(DeviceID) to!ubyte(device.id));
				wd.value(device.value.to!float);
				break;
			case DeviceID.Compass: 
				Compass compass = Hardware.Get!Compass(cast(DeviceID) to!ubyte(device.id));
				compass.value(device.value.to!float);
				break;
			case DeviceID.Sail:
				Sail sail = Hardware.Get!Sail(cast(DeviceID) to!ubyte(device.id));
				sail.value(device.value.to!ubyte);
				break;	
			case DeviceID.Helm:
				Helm helm = Hardware.Get!Helm(cast(DeviceID) to!ubyte(device.id));
				helm.value(device.value.to!float);
				break;
			case DeviceID.Gps:
				Gps gps = Hardware.Get!Gps(cast(DeviceID) to!ubyte(device.id));
				gps.value(GpsCoord(GpsCoord.toRad(device.value.latitude.to!double), GpsCoord.toRad(device.value.longitude.to!double)));
				break;
			case DeviceID.Battery:
                Battery battery = Hardware.Get!Battery(cast(DeviceID) to!ubyte(device.id));
                battery.value(device.value.to!float);
                break;
			default:
				SailLog.Warning("Called unknown Device ID. No device set.");
		}
	}

	Json getLogs(){
		return logCache;
	}

	/**
		Add a new log line into cache
	*/
	static void log(T...)(string level, T args){
		CheckInstance();
		Json log = Json.emptyObject;
		log.level = level;
		log.date = Clock.currTime().toSimpleString();

		//Format content in a single string
		string content = "";
		foreach(arg; args){
			content ~= to!string(arg);
		}
		log.content = content;


		if(logCache.length >= 256){
			logCache = logCache.opSlice(1, 256);
		}
		logCache ~= log;
	}

	Json getDc(){
		Json dc = Json.emptyObject;
		dc.enabled = DecisionCenter.Get().enabled();

		dc.targetPosition = Json.emptyObject;
		dc.targetPosition.longitude = DecisionCenter.Get().targetposition().longitude();
		dc.targetPosition.latitude = DecisionCenter.Get().targetposition().latitude();

		dc.targetHeading = DecisionCenter.Get().targetheading();

		return dc;
	}

	void postDc(bool status){
		DecisionCenter.Get().enabled(status);
		SailLog.Notify("Decision center is now ", DecisionCenter.Get().enabled() ? "Enabled" : "Disbaled");
	}

	void postTargetposition(float latitude, float longitude){
	    SailLog.Notify("[DBG] ", latitude,";" , longitude);
		DecisionCenter.Get().targetposition(GpsCoord(to!double(latitude), to!double(longitude)));
	}

	void postTargetheading(float angle){
		DecisionCenter.Get().targetheading(to!double(angle));
	}


	Json getAutopilot(){
		Json ap = Json.emptyObject;
		ap.enabled = DecisionCenter.Get().autopilot().enabled();

		return ap;
	}

	void postAutopilot(bool status){
		DecisionCenter.Get().autopilot().enabled(status);
		SailLog.Notify("Autopilot is now ", DecisionCenter.Get().autopilot().enabled() ? "Enabled" : "Disbaled");
	}

	Json getSh(){
		Json sh = Json.emptyObject;
		sh.enabled = DecisionCenter.Get().sailhandler().enabled();

		return sh;
	}

	void postSh(bool status){
		DecisionCenter.Get().sailhandler().enabled(status);
		SailLog.Notify("Sail Handler is now ", DecisionCenter.Get().sailhandler().enabled() ? "Enabled" : "Disbaled");
	}

	void postEmergency(){
		//Disable systems
		postDc(false);
		postSh(false);
		postAutopilot(false);

		//Emulate sensors and actuators
		for(int i = 1 ; i<=DeviceID.max ; i++){
			postEmulation("{\"id\":"~to!string(i)~",\"emulated\":true}");

		}
	}

	void postBacktostart(){
		DecisionCenter.Get().backToStartPosition();
	}



private:
	static __gshared API m_inst;

	static void CheckInstance(){
		if(!m_inst){
			m_inst = new API();
		}
	}




	static __gshared Json logCache;

	this(){
		logCache = Json.emptyArray;
	}	
}