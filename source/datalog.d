module datalog;

import core.thread;
import std.stdio;
import std.datetime;
import hardware.hardware;
import hardware.devices;
import decisioncenter;
import saillog;


class DataLog {

    this(){
        m_thread = new Thread(&LogThread);
        m_thread.name(typeof(this).stringof);
        m_thread.isDaemon(true);
        m_thread.start();

        try{
            m_logfile.open("./zbrazaraldjan.log", "a");
        }catch(Exception e){
            m_logfile.open("/tmp/datalogs", "a");
            SailLog.Warning("Now logging to /tmp/datalogs");
        }
    }
    
    ~this(){
        m_stop = true;
        m_thread.join();
        
        m_logfile.flush();
        m_logfile.close();
    }
    
    private:
        File m_logfile;
        
        bool m_stop = false;
        uint m_nLoopTimeMS = 1000;
        Thread m_thread;
        
        
        
        void LogThread(){
            while(!m_stop){
                try{
                    debug{
                        SailLog.Post("Running "~typeof(this).stringof~" thread");
                    }
                    
                    printLog();
    
                }catch(Throwable t){
                    SailLog.Critical("In thread ",m_thread.name,": ",t.toString);
                }
    
                Thread.sleep(dur!("msecs")(m_nLoopTimeMS));
            }
        }
        
        void printLog(){
            auto time = Clock.currTime(); 
            m_logfile.writeln(
                time.hour," ",time.minute," ",time.second," "
                ,Hardware.Get!Gps(DeviceID.Gps).value().longitude()," "
                ,Hardware.Get!Gps(DeviceID.Gps).value().longitude()," "
                ,DecisionCenter.Get().targetposition().latitude() ," "
                ,DecisionCenter.Get().targetposition().longitude() ," "
                ,Hardware.Get!Helm(DeviceID.Helm).value()," "
                ,Hardware.Get!Sail(DeviceID.Sail).value()," " //Grand-voile
                ,Hardware.Get!Sail(DeviceID.Sail).value()," " //Foc
                ,Hardware.Get!WindDir(DeviceID.WindDir).value()," "
                ,"Batterie "
                ,Hardware.Get!Roll(DeviceID.Roll).value());

            m_logfile.flush();
        }
    
}