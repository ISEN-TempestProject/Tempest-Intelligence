module config;

import logger;
import inireader;
import std.stdio;


class Config {
private:
	enum CONFIG_PATH="res/config.ini";
	enum string[string][string] CONFIG_DEFAULT = [
		"Global" : ([
			"LogFile":"logs",
			"Test":"Test!! dqioj"
		])
	];

public:
	static T Get(T)(string sHeader, string sName){
		if(m_inst is null)m_inst = new Config();
		return m_inst.m_ini.Get!T(sHeader, sName);
	}


private:
	static __gshared Config m_inst;

	this()
	out{
		assert(m_ini.Get!string("Hardware", "OverrideWindDirection")=="90");
		assert(m_ini.Get!string("Global", "LogFile")=="logs");
		assert(m_ini.Get!string("Global", "")=="");
		assert(m_ini.Get!string("", "")=="");
	}
	body{
		m_ini = new INIReader(CONFIG_PATH, CONFIG_DEFAULT);
		writeln("Config loaded: "~CONFIG_PATH);
	}

	INIReader m_ini;

}