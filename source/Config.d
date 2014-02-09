module config;

import logger;
import inireader;
import std.stdio;


class Config {
private:
	/*!
		@brief Path to configuration file
	*/
	enum CONFIG_PATH="res/config.ini";

	/*!
		@brief Default values of the configuration file
	*/
	enum string[string][string] CONFIG_DEFAULT = [
		"Global" : ([
			"LogFile":"logs",
			"Test":"Test!! dqioj"
		])
	];

public:
	/*!
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
		assert(m_ini.Get!int("Hardware", "OverrideWindDirection")==90);
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