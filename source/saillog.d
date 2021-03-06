module saillog;

import std.stdio;
import std.process;
import core.sync.mutex;
import core.thread;
import col;
import config;
import api;

/**
	Logs everything, on console and/or on files
	Todo: May be wise to create a thread if the mutex is locked so it doesn't slow the main process
*/
class SailLog {

public:
	/**
		Posts a Warning, and immediately writes it to disk
	*/
	static void Warning(T...)(T args){//Variadic function with undefined number of parameters
		CheckInstance();
		synchronized(m_inst.m_mtx){
			auto uptime = GetUptime();
			API.log("Warning", uptime, args);
			stderr.writeln(var.faded~uptime~"|"~var.end~bg.lightyellow~fg.red~var.bold~"Warning:  "~var.end,args);
			m_inst.m_logfile.writeln(var.faded~uptime~"|"~var.end~bg.lightyellow~fg.red~var.bold~"Warning:  "~var.end,args);
			m_inst.m_logfile.flush();//It is is important to save this
		}
	}

	/**
		Posts a Critical Error, and immediately writes it to disk
	*/
	static void Critical(T...)(T args){
		CheckInstance();
		synchronized(m_inst.m_mtx){
			auto uptime = GetUptime();
			API.log("Critical", uptime, args);
			stderr.writeln(var.faded~uptime~"|"~var.end~bg.red~fg.white~var.bold~"CRIT ERR: "~var.end,args);
			m_inst.m_logfile.writeln(var.faded~uptime~"|"~var.end~bg.red~fg.white~var.bold~"CRIT ERR: "~var.end,args);
			m_inst.m_logfile.flush();
		}
	}

	/**
		Posts a Success, and writes it to disk
	*/
	static void Success(T...)(T args){
		CheckInstance();
		synchronized(m_inst.m_mtx){
			auto uptime = GetUptime();
			API.log("Success", uptime, args);
			writeln(var.faded~uptime~"|"~var.end~fg.green~var.bold~"Success:  "~var.end,args);
			m_inst.m_logfile.writeln(var.faded~uptime~"|"~var.end~fg.green~var.bold~"Success:  "~var.end,args);
			debug {
				m_inst.m_logfile.flush();
			}
		}
	}


	/**
		Posts a Notification, and writes it to disk
	*/
	static void Notify(T...)(T args){
		CheckInstance();
		synchronized(m_inst.m_mtx){
			auto uptime = GetUptime();
			API.log("Notify", uptime, args);
			writeln(var.faded~uptime~"|"~var.end~fg.lightblack~var.bold~"Notify:   "~var.end,args);
			m_inst.m_logfile.writeln(var.faded~uptime~"|"~var.end~fg.lightblack~var.bold~"Notify:   "~var.end,args);
			debug {
				m_inst.m_logfile.flush();
			}
		}
	}


	/**
		Posts a Success, without writing it to disk
	*/
	static void Post(T...)(T args){
		CheckInstance();
		synchronized(m_inst.m_mtx){
			auto uptime = GetUptime();
			API.log("Post", uptime, args);
			stdout.writeln(var.faded~uptime~"|"~var.end~var.faded~"Post:     "~var.end,args);
		}
	}

	static string GetUptime(){
		import std.string;
		import std.datetime;
		return format("%.1f", Clock.currAppTick().to!("seconds", float)).rightJustify(7);
	}

private:
	static __gshared SailLog m_inst;//Stored in global storage, not thread local storage (TLS)

	File m_logfile;
	Mutex m_mtx;

	static void CheckInstance(){
		if(!m_inst){
			m_inst = new SailLog();
		}
	}


	static enum string MOTD = 
				 bg.white~"                                                            "~var.end~"\n"
				~bg.white~"  "~bg.lightgreen~fg.black~"                 AutoShip ©ISEN Brest                   "~bg.white~"  "~var.end~"\n"
				~bg.white~"  "~bg.lightgreen~fg.black~"            Thomas ABOT       Thibaut CHARLES           "~bg.white~"  "~var.end~"\n"
				~bg.white~"                                                            "~var.end~"\n";

	this(){
		writeln(var.bold~"Notify:   "~var.end,typeof(this).stringof~" instantiation in ",Thread.getThis().name," thread...");
		m_mtx = new Mutex();
		synchronized(m_mtx)
		{
			try{
				m_logfile.open(config.Config.Get!string("Global", "LogFile"), "a");
			}catch(Exception e){
				auto uptime = GetUptime();
				stderr.writeln(var.faded~uptime~"|"~var.end~bg.red~fg.white~var.bold~"CRIT ERR: "~var.end,e, "\nNow logging to /tmp/logs");

				m_logfile.open("/tmp/logs", "a");
				m_logfile.writeln(var.faded~uptime~"|"~var.end~bg.red~fg.white~var.bold~"CRIT ERR: "~var.end,e, "\nNow logging to /tmp/logs");
			}
			stdout.writeln(MOTD~execute("date").output);
			m_logfile.writeln(MOTD~execute("date").output);

			stdout.writeln(config.Config.toString);
			m_logfile.writeln(config.Config.toString);
		}
		auto uptime = GetUptime();
		writeln(var.faded~uptime~"|"~var.end~fg.green~var.bold~"Success:  "~var.end,typeof(this).stringof~" instantiated in ",Thread.getThis().name," thread");
		m_logfile.writeln(var.faded~uptime~"|"~var.end~fg.green~var.bold~"Success:  "~var.end,typeof(this).stringof~" instantiated in ",Thread.getThis().name," thread");

		m_logfile.flush();
	}

	~this(){
		m_logfile.flush();
		m_logfile.close();
	}
}