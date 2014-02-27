module api;

import vibe.http.rest;
import vibe.core.log;
import vibe.data.json;
import std.datetime;
import saillog;
import hardware.hardware;
import hardware.devices;

interface ISailAPI
{
	// GET /devices
	Json getDevices();

	// GET /:id/devices
	Json getDevices(int id);

	// POST /:id/value
	void postValue(string data);

	// POST /:id/emulation
	void postEmulation(string data);

	// GET /logs
	Json getLogs();
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
		foreach(device; DeviceID.min+1 .. DeviceID.max)
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
				device.emulated = roll.isemulated();
				device.value = roll.value();
				break;
			case DeviceID.WindDir: 
				WindDir wd = Hardware.Get!WindDir(id);
				device.id = wd.id();
				device.emulated = wd.isemulated();
				device.value = wd.value();
				break;
			case DeviceID.Compass: 
				Compass compass = Hardware.Get!Compass(id);
				device.id = compass.id();
				device.emulated = compass.isemulated();
				device.value = compass.value();
				break;
			case DeviceID.Sail:
				Sail sail = Hardware.Get!Sail(id);
				device.id = sail.id();
				device.emulated = sail.isemulated();
				device.value = to!int(sail.value());
				break;	
			case DeviceID.Helm:
				Helm helm = Hardware.Get!Helm(id);
				device.id = helm.id();
				device.emulated = helm.isemulated();
				device.value = helm.value();
				break;
			case DeviceID.Gps:
				Gps gps = Hardware.Get!Gps(id);
				device.id = gps.id();
				device.emulated = gps.isemulated();
				device.value = Json.emptyObject;
				device.value.longitude = gps.value().longitude();
				device.value.latitude = gps.value().latitude();
				break;
			default:
				SailLog.Warning("Called unknown Device ID. Sending empty object.");
				return parseJsonString("{}");
		}

		//common values
		device.lowCaption = "-";
		device.highCaption = "+";
		device.delta = 0.1;

		return device;

		
	}

	void postEmulation(string data){
		SailLog.Post("Device set : " ~ data);
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
				roll.value(to!float(device.value));
				break;
			case DeviceID.WindDir: 
				WindDir wd = Hardware.Get!WindDir(cast(DeviceID) to!ubyte(device.id));
				wd.value(to!float(device.value));
				break;
			case DeviceID.Compass: 
				Compass compass = Hardware.Get!Compass(cast(DeviceID) to!ubyte(device.id));
				compass.value(to!float(device.value));
				break;
			case DeviceID.Sail:
				Sail sail = Hardware.Get!Sail(cast(DeviceID) to!ubyte(device.id));
				sail.value(to!ubyte(device.value));
				break;	
			case DeviceID.Helm:
				Helm helm = Hardware.Get!Helm(cast(DeviceID) to!ubyte(device.id));
				helm.value(to!double(device.value));
				break;
			case DeviceID.Gps:
				Gps gps = Hardware.Get!Gps(cast(DeviceID) to!ubyte(device.id));
				gps.value().longitude(to!double(device.value.longitude));
				gps.value().latitude(to!double(device.value.latitude));
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