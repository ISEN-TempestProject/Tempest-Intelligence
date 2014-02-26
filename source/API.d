module api;

import vibe.http.rest;
import vibe.core.log;
import vibe.data.json;
import std.datetime;
import std.stdio;
import saillog;
import hardware.hardware;
import hardware.devices;

interface ISailAPI
{
	// GET /devices
	Json getDevices();

	// GET /:id/devices
	Json getDevices(int id);

	// POST /:id/devices
	void addDevices(int id);

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
		return parseJsonString("
		[
		    {
		      \"id\": 1,
		      \"name\": \"Capt-1\",
		      \"value\": 42.1337,
		      \"delta\": 0.1,
		      \"lowCaption\": \"up\",
		      \"highCaption\": \"down\",
		      \"emulated\" : true
		    },
		    {
		      \"id\": 2,
		      \"name\": \"Capt-2\",
		      \"value\": 13.37,
		      \"delta\": 0.15,
		      \"lowCaption\": \"-\",
		      \"highCaption\": \"+\",
		      \"emulated\" : false
		    },
		    {
		      \"id\": 3,
		      \"name\": \"Capt-3\",
		      \"value\": 22.29,
		      \"delta\": 12.37,
		      \"lowCaption\": \"lower\",
		      \"highCaption\": \"higher\",
		      \"emulated\" : true
		    },
		    {
		      \"id\": 4,
		      \"name\": \"Act-1\",
		      \"value\": 13.37,
		      \"delta\": 0.15,
		      \"lowCaption\": \"Low\",
		      \"highCaption\": \"High\",
		      \"emulated\" : false
		    },
		    {
		      \"id\": 5, 
		      \"name\": \"Act-2\",
		      \"value\": 22.29,
		      \"delta\": 12.37,
		      \"lowCaption\": \"Lo\",
		      \"highCaption\": \"Hi\",
		      \"emulated\" : true
		    }
		]");
	}	

	Json getDevices(int id_)
	{
		DeviceID id = cast(DeviceID) id_ ;
		Json device = Json.emptyObject;
		switch(id){
			case DeviceID.Roll: 
				Roll roll = Hardware.Get!Roll(id);
				device.id = roll.id();
				device.isEmulated = roll.isemulated();
				device.value = roll.value();
				break;
			case DeviceID.WindDir: 
				WindDir wd = Hardware.Get!WindDir(id);
				device.id = wd.id();
				device.isEmulated = wd.isemulated();
				device.value = wd.value();
				break;
			case DeviceID.Compass: 
				Compass compass = Hardware.Get!Compass(id);
				device.id = compass.id();
				device.isEmulated = compass.isemulated();
				device.value = compass.value();
				break;
			case DeviceID.Sail:
				Sail sail = Hardware.Get!Sail(id);
				device.id = sail.id();
				device.isEmulated = sail.isemulated();
				device.value = sail.value();
				break;	
			case DeviceID.Helm:
				Helm helm = Hardware.Get!Helm(id);
				device.id = helm.id();
				device.isEmulated = helm.isemulated();
				device.value = helm.value();
				break;
			case DeviceID.Gps:
				Gps gps = Hardware.Get!Gps(id);
				device.id = gps.id();
				device.isEmulated = gps.isemulated();
				device.value = Json.emptyObject;
				device.value.longitude = gps.value().longitude();
				device.value.latitude = gps.value().latitude();
				break;
			default:
				SailLog.Warning("Called unknown Device ID. Sending empty object.");
				return parseJsonString("{}");
		}

		return device;

		
	}

	void addDevices(int id){
		SailLog.Post("Device set : " ~ to!string(id));
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