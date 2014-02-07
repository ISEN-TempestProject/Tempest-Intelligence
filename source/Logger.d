module logger;

import std.stdio;
import core.sync.mutex;
import col;

/*!
	@brief Logs everything, on console and/or on files
	@todo May be wise to create a thread if the mutex is locked so it doesn't slow the main process
*/
class Logger {

public:
	static void Warning(T...)(T args){//Variadic function with undefined number of parameters
		CheckInstance();
		synchronized(m_inst.m_mtx){
			stderr.writeln(bg.lightyellow~fg.red~var.bold~"Warning:  "~end,args);
			m_inst.m_logfile.writeln(bg.lightyellow~fg.red~var.bold~"Warning:  "~end,args);
			m_inst.m_logfile.flush();//It is is important to save this
		}
	}

	static void Critical(T...)(T args){
		CheckInstance();
		synchronized(m_inst.m_mtx){
			stderr.writeln(bg.red~fg.white~var.bold~"CRIT ERR: "~end,args);
			m_inst.m_logfile.writeln(bg.red~fg.white~var.bold~"CRIT ERR: "~end,args);
			m_inst.m_logfile.flush();//It is is important to save this
		}
	}

	static void Success(T...)(T args){
		CheckInstance();
		synchronized(m_inst.m_mtx){
			writeln(fg.green~var.bold~"Success:  "~end,args);
			m_inst.m_logfile.writeln(fg.green~var.bold~"Success:  "~end,args);
		}
	}

	static void Notify(T...)(T args){
		CheckInstance();
		synchronized(m_inst.m_mtx){
			writeln(fg.lightblack~var.bold~"Notify:   "~end,args);
			m_inst.m_logfile.writeln(fg.lightblack~var.bold~"Notify:   "~end,args);
		}
	}

	static void Post(T...)(T args){
		CheckInstance();
		synchronized(m_inst.m_mtx){
			stdout.writeln("Post:     ",args);
		}
	}

private:
	static Logger m_inst;

	File m_logfile;
	Mutex m_mtx;

	static void CheckInstance(){
		if(m_inst is null){
			m_inst = new Logger();
			Success(typeof(this).stringof~" instanciation");
		}
	}

	this(){
		m_logfile.open("logs", "a");
		m_mtx = new Mutex();
	}
}