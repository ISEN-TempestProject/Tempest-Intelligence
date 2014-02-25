module api;

import vibe.http.rest;
import vibe.core.log;
import vibe.data.json;
import std.datetime;
import std.stdio;
import saillog;

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
		      \"lowCaption\": \"High\",
		      \"highCaption\": \"Low\",
		      \"emulated\" : false
		    },
		    {
		      \"id\": 5, 
		      \"name\": \"Act-2\",
		      \"value\": 22.29,
		      \"delta\": 12.37,
		      \"lowCaption\": \"Hi\",
		      \"highCaption\": \"Lo\",
		      \"emulated\" : true
		    }
		]");
	}	

	Json getDevices(int id=0)
	{
		return parseJsonString("{}");
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