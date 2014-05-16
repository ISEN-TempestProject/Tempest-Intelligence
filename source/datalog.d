module datalog;

import core.thread;
import std.stdio;
import std.datetime;
import hardware.hardware;
import hardware.devices;
import decisioncenter;
import saillog;
import gpscoord;


class DataLog {

    this(){
        m_thread = new Thread(&LogThread);
        m_thread.name(typeof(this).stringof);
        m_thread.isDaemon(true);
        m_thread.start();
    }
    
    ~this(){
        m_stop = true;
        m_thread.join();
    }
    
    private:
        File m_logfile;
        
        bool m_stop = false;
        uint m_nLoopTimeMS = 5000;
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
            try{
                m_logfile.open("./zbrazaraldjan.log", "w");
            }catch(Exception e){
                m_logfile.open("/tmp/datalogs", "a");
                SailLog.Warning("Now logging to /tmp/datalogs using append mode.");
            }
        
        
            auto time = Clock.currTime(); 
            m_logfile.writeln(
                time.hour," ",time.minute," ",time.second," "
                ,GpsCoord.toDeg(Hardware.Get!Gps(DeviceID.Gps).value().longitude())," "
                ,GpsCoord.toDeg(Hardware.Get!Gps(DeviceID.Gps).value().longitude())," "
                ,GpsCoord.toDeg(DecisionCenter.Get().targetposition().latitude())," "
                ,GpsCoord.toDeg(DecisionCenter.Get().targetposition().longitude())," "
                ,Hardware.Get!Helm(DeviceID.Helm).value()," "
                ,Hardware.Get!Sail(DeviceID.Sail).value()," " //Grand-voile
                ,Hardware.Get!Sail(DeviceID.Sail).value()," " //Foc
                ,Hardware.Get!WindDir(DeviceID.WindDir).value()," "
                ,Hardware.Get!Battery(DeviceID.Battery).value()," "
                ,Hardware.Get!Roll(DeviceID.Roll).value()," "
                ,Hardware.Get!Compass(DeviceID.Compass).value());

            m_logfile.flush();
            m_logfile.close();
        }
    
}