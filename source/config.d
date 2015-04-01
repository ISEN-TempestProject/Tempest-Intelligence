module config;

import saillog;
import inireader;
import std.stdio;

debug{
	import std.datetime : SysTime;
	import std.file : timeLastModified;
}


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
			"GPSLogFile":"gpslogs",
			"ConnectSockets":"true"
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
			"CommandRatio":"1.0",
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
			"Sail":"res/polar_sail_basic.json",
			"HelmSpeed":"res/polar_helmspeed_basic.json"
		])
	];

public:
	/**
		Gets the value of the given entry
		Throws: if the entry does not exists
	*/
	static T Get(T)(string sHeader, string sName){
		if(m_inst is null)m_inst = new Config();
		debug m_inst.ReloadConfigIfNeeded();
		return m_inst.m_ini.Get!T(sHeader, sName);
	}

	static void Set(T)(string sHeader, string sName, T value){
		if(m_inst is null)m_inst = new Config();
		debug m_inst.ReloadConfigIfNeeded();
		m_inst.m_ini.Set!T(sHeader, sName, value);
	}

	static string toString(){
		if(m_inst is null)m_inst = new Config();
		debug m_inst.ReloadConfigIfNeeded();
		return m_inst.m_ini.toString;
	}


private:
	static __gshared Config m_inst;

	this(){
		version(unittest){
			//using default config for unittests
			m_ini = new INIReader("", CONFIG_DEFAULT);
		}
		else{
			m_ini = new INIReader(CONFIG_PATH, CONFIG_DEFAULT);
		}
		debug m_lastReload = timeLastModified(CONFIG_PATH);
		writeln("Config loaded: "~CONFIG_PATH);
	}


	INIReader m_ini;

	debug{
		void ReloadConfigIfNeeded(){
			synchronized{
				auto mod = timeLastModified(CONFIG_PATH);
				if(mod>m_lastReload){
					import col;
					import saillog;
					auto uptime = SailLog.GetUptime();
					writeln(var.faded~uptime~"|"~var.end~fg.lightblack~var.bold~"Notify:   "~var.end, "Config file reloaded");

					m_ini = new INIReader(CONFIG_PATH, CONFIG_DEFAULT);
					m_lastReload = mod;
				}
			}
		}
		SysTime m_lastReload;
	}
}