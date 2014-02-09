module logger;

import std.stdio;
import std.process;
import core.sync.mutex;
import col;
import config;

/*!
	@brief Logs everything, on console and/or on files
	@todo May be wise to create a thread if the mutex is locked so it doesn't slow the main process
*/
class Logger {

public:
	/*!
		@brief Posts a Warning, and immediately writes it to disk
	*/
	static void Warning(T...)(T args){//Variadic function with undefined number of parameters
		CheckInstance();
		synchronized(m_inst.m_mtx){
			stderr.writeln(bg.lightyellow~fg.red~var.bold~"Warning:  "~end,args);
			m_inst.m_logfile.writeln(bg.lightyellow~fg.red~var.bold~"Warning:  "~end,args);
			m_inst.m_logfile.flush();//It is is important to save this
		}
	}

	/*!
		@brief Posts a Critical Error, and immediately writes it to disk
	*/
	static void Critical(T...)(T args){
		CheckInstance();
		synchronized(m_inst.m_mtx){
			stderr.writeln(bg.red~fg.white~var.bold~"CRIT ERR: "~end,args);
			m_inst.m_logfile.writeln(bg.red~fg.white~var.bold~"CRIT ERR: "~end,args);
			m_inst.m_logfile.flush();
		}
	}

	/*!
		@brief Posts a Success, and writes it to disk
	*/
	static void Success(T...)(T args){
		CheckInstance();
		synchronized(m_inst.m_mtx){
			writeln(fg.green~var.bold~"Success:  "~end,args);
			m_inst.m_logfile.writeln(fg.green~var.bold~"Success:  "~end,args);
			debug {
				m_inst.m_logfile.flush();
			}
		}
	}


	/*!
		@brief Posts a Notification, and writes it to disk
	*/
	static void Notify(T...)(T args){
		CheckInstance();
		synchronized(m_inst.m_mtx){
			writeln(fg.lightblack~var.bold~"Notify:   "~end,args);
			m_inst.m_logfile.writeln(fg.lightblack~var.bold~"Notify:   "~end,args);
			debug {
				m_inst.m_logfile.flush();
			}
		}
	}


	/*!
		@brief Posts a Success, without writing it to disk
	*/
	static void Post(T...)(T args){
		CheckInstance();
		synchronized(m_inst.m_mtx){
			stdout.writeln("Post:     ",args);
		}
	}

private:
	static __gshared Logger m_inst;//Stored in global storage, not thread local storage (TLS)

	File m_logfile;
	Mutex m_mtx;

	static void CheckInstance(){
		if(!m_inst){
			m_inst = new Logger();
		}
	}

	static enum string MOTD = 
				 bg.white~"                                                            "~end~"\n"
				~bg.white~"  "~bg.lightgreen~fg.black~"                 AutoShip ©ISEN Brest                   "~bg.white~"  "~end~"\n"
				~bg.white~"  "~bg.lightgreen~fg.black~"            Thomas ABOT       Thibaut CHARLES           "~bg.white~"  "~end~"\n"
				~bg.white~"                                                            "~end~"\n";

	this(){
		m_mtx = new Mutex();
		stdout.writeln(MOTD~execute("date").output);
		synchronized(m_mtx)
		{
			try{
				m_logfile.open(config.Config.Get!string("Global", "LogFile"), "a");
			}catch(Exception e){
				stderr.writeln(bg.red~fg.white~var.bold~"CRIT ERR: "~end,e, "\nNow logging to /tmp/logs");

				m_logfile.open("/tmp/logs", "a");
				m_logfile.writeln(bg.red~fg.white~var.bold~"CRIT ERR: "~end,e, "\nNow logging to /tmp/logs");
			}
			m_logfile.writeln(MOTD~execute("date").output);
		}
		writeln(fg.green~var.bold~"Success:  "~end,typeof(this).stringof~" instantiation");
		m_logfile.writeln(fg.green~var.bold~"Success:  "~end,typeof(this).stringof~" instantiation");

		m_logfile.flush();
	}

	~this(){
		m_logfile.flush();
		m_logfile.close();
	}
}