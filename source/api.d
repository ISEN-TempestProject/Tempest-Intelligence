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

			foreach(sens ; __traits(allMembers, DeviceID)){
				static if(mixin("DeviceID."~sens)!=DeviceID.Invalid){
					case (mixin("DeviceID."~sens)):
						auto d = Hardware.Get!(mixin(sens))(id);
						device.id = d.id();
						device.name = sens;
						device.emulated = d.isemulated();

						static if(mixin("DeviceID."~sens)==DeviceID.Gps){
							device.value = Json.emptyObject;
							device.value.longitude = GpsCoord.toDeg(d.value().longitude());
							device.value.latitude = GpsCoord.toDeg(d.value().latitude());
						}
						else static if(mixin("DeviceID."~sens)==DeviceID.Sail){
							device.value = to!int(d.value());
						}
						else{
							device.value = d.value();
						}
						break;
				}
			}
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

			foreach(sens ; __traits(allMembers, DeviceID)){
				static if(mixin("DeviceID."~sens)!=DeviceID.Invalid){
					case (mixin("DeviceID."~sens)):

						auto d = Hardware.Get!(mixin(sens))(cast(DeviceID)(to!ubyte(device.id)));
						d.isemulated(to!bool(device.emulated));
						break;
				}
			}
			break;
			default:
				SailLog.Warning("Called unknown Device ID. No device set.");
		}
	}


	void postValue(string data){
		SailLog.Post("Device set : " ~ data);
		Json device = parseJsonString(data);
		switch(to!ubyte(device.id)){
			foreach(sens ; __traits(allMembers, DeviceID)){
				static if(mixin("DeviceID."~sens)!=DeviceID.Invalid){
					case (mixin("DeviceID."~sens)):

						auto d = Hardware.Get!(mixin(sens))(cast(DeviceID) to!ubyte(device.id));
						static if(mixin("DeviceID."~sens)==DeviceID.Gps){
							d.value(GpsCoord(GpsCoord.toRad(device.value.latitude.to!double), GpsCoord.toRad(device.value.longitude.to!double)));
						}
						else{
							d.value(device.value.to!(typeof(d.value)));
						}
						break;
				}
			}
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
		auto dcobj = DecisionCenter.Get();

		dc.enabled = dcobj.enabled;

		dc.targetPosition = Json.emptyObject;
		dc.targetPosition.longitude = GpsCoord.toDeg(dcobj.targetposition().longitude());
		dc.targetPosition.latitude = GpsCoord.toDeg(dcobj.targetposition().latitude());

		dc.targetHeading = dcobj.targetheading();

		return dc;
	}

	void postDc(bool status){
		DecisionCenter.Get().enabled = status;
		SailLog.Notify("Decision center is now ", DecisionCenter.Get().enabled ? "Enabled" : "Disabled");
	}

	void postTargetposition(float latitude, float longitude){
		SailLog.Notify("[DBG] ", latitude,";" , longitude);
		DecisionCenter.Get().targetposition(GpsCoord(GpsCoord.toRad(to!double(latitude)), GpsCoord.toRad(to!double(longitude))));
	}

	void postTargetheading(float angle){
		DecisionCenter.Get().targetheading(to!double(angle));
	}


	Json getAutopilot(){
		Json ap = Json.emptyObject;
		if(DecisionCenter.Get().autopilot !is null)
			ap.enabled = DecisionCenter.Get().autopilot.enabled;
		else 
			ap.enabled = false;

		return ap;
	}

	void postAutopilot(bool status){
		auto ap = DecisionCenter.Get().autopilot;
		if(ap !is null){
			ap.enabled = status;
			SailLog.Notify("Autopilot is now ", DecisionCenter.Get().autopilot.enabled ? "Enabled" : "Disabled");
		}
	}

	Json getSh(){
		Json sh = Json.emptyObject;
		if(DecisionCenter.Get().sailhandler !is null) 
			sh.enabled = DecisionCenter.Get().sailhandler.enabled;
		else
			sh.enabled = false;

		return sh;
	}

	void postSh(bool status){
		auto sh = DecisionCenter.Get().sailhandler;
		if(sh !is null){
			sh.enabled = status;
			SailLog.Notify("Sail Handler is now ", DecisionCenter.Get().sailhandler.enabled ? "Enabled" : "Disabled");
		}
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