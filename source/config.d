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
			"LogFile":"logs"
		]),
		"DecisionCenter" : ([
			"Targets":"",
			"DistanceToTarget":"10.0",
			"DistanceToRoute":"50.0",
			"Period":"5000"
		]),
		"Autopilot" : ([
			"Period":"1000",
			"Delta":"1.0",
			"Tolerance":"3.0"
		]),
		"SailHandler" : ([
			"Period":"1000",
			"Delta":"2",
			"Danger":"40.0"
		]),
		"Hardware" : ([
			"Pipe":"/tmp/pipe",
			"ConstantWindValue":""
		]),
		"HardwareWatchdog" : ([
			"Enable":"true"
		]),
		"WebServer" : ([
			"Port":"8080"
		])
	];

public:
	/**
		@brief Gets the value of the given entry
		@throw if the entry does not exists
	*/
	static T Get(T)(string sHeader, string sName){
		if(m_inst is null)m_inst = new Config();
		return m_inst.m_ini.Get!T(sHeader, sName);
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
		m_ini = new INIReader(CONFIG_PATH, CONFIG_DEFAULT);
		writeln("Config loaded: "~CONFIG_PATH);
	}

	INIReader m_ini;

}