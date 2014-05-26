module config;

import saillog;
import inireader;
import std.stdio;


/**
	Configuration class, to handle configuration lines... >_<"
*/
class Config {
private:
	/**
		Path to configuration file
	*/
	enum CONFIG_PATH="res/config.ini";

	/**
		Default values of the configuration file
	*/
	enum string[string][string] CONFIG_DEFAULT = [
		"Global" : ([
			"LogFile":"logs",
			"GPSLogFile":"gpslogs"
		]),
		"DecisionCenter" : ([
			"Route":"res/route.json",
			"RestoreRoute":"res/restoreRoute.json",
			"DistanceToTarget":"10.0",
			"DistanceToRoute":"50.0",
			"Period":"5000",
			"ReturnToOrigin":"true", 
			"StartWithoutGPS":"false"
		]),
		"Autopilot" : ([
			"Period":"1000",
			"Delta":"1.0",
			"CommandRatio":"0.1",
			"Tolerance":"3.0",
			"EdgeLocks":"5"
		]),
		"SailHandler" : ([
			"Period":"1000",
			"Delta":"2",
			"Danger":"40.0"
		]),
		"Hardware" : ([
			"Pipe":"/tmp/pipe"
		]),
		"Battery" : ([
			"LowVoltage":"7.5",
			"CriticalVoltage":"7.0"
		]),
		"WebServer" : ([
			"Port":"1337"
		]),
		"Polars": ([
			"Wind":"res/polar_wind_basic.json",
			"Heading":"res/polar_heading_basic.json",
			"Sail":"res/polar_sail_basic.json"
		])
	];

public:
	/**
		Gets the value of the given entry
		Throws: if the entry does not exists
	*/
	static T Get(T)(string sHeader, string sName){
		if(m_inst is null)m_inst = new Config();
		return m_inst.m_ini.Get!T(sHeader, sName);
	}

	static void Set(T)(string sHeader, string sName, T value){
		if(m_inst is null)m_inst = new Config();
		m_inst.m_ini.Set!T(sHeader, sName, value);
	}

	static string toString(){
		if(m_inst is null)m_inst = new Config();
		return m_inst.m_ini.toString;
	}


private:
	static __gshared Config m_inst;

	this()
	out{
		import std.exception;
		assert(m_ini.Get!float("DecisionCenter", "DistanceToRoute")==50.0);
		assert(m_ini.Get!string("Global", "LogFile")==CONFIG_DEFAULT["Global"]["LogFile"]);
		assertThrown(m_ini.Get!string("Global", ""));
		assertThrown(m_ini.Get!string("", ""));
	}
	body{
		version(unittest){
			//using default config for unittests
			m_ini = new INIReader("", CONFIG_DEFAULT);
		}
		else{
			m_ini = new INIReader(CONFIG_PATH, CONFIG_DEFAULT);
		}
		writeln("Config loaded: "~CONFIG_PATH);
	}

	INIReader m_ini;

}