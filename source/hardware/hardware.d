module hardware.hardware;

import std.process;
import std.socket;
import core.thread;
import core.sync.condition;
import core.sync.mutex;
import saillog;
import config;

public import hardware.devices;

/**
	Singleton to handle communication with the hardware
*/
class Hardware {

public:
	/**
		Getter for hardware devices
	*/
	static T Get(T)(DeviceID id){
		synchronized(this.classinfo){
			if(m_inst is null) m_inst = new Hardware();
		}

		if(id in m_inst.m_hwlist){
			if(auto ret = cast(T)(m_inst.m_hwlist[id]))
				return ret;
			else{
				SailLog.Critical("Trying to cast "~(m_inst.m_hwlist[id].classinfo.name)~" to type "~id);
				throw new Exception("Trying to cast "~(m_inst.m_hwlist[id].classinfo.name)~" to type "~id);
			}
		}
		else{
			SailLog.Critical("Hardware element not found : ", id);
			throw new Exception("Hardware element not found : "~id.stringof);
		}
	}

	/**
		Simple getter, not used outside the package
	*/
	static Hardware GetClass(){
		synchronized(this.classinfo){
			if(m_inst is null) m_inst = new Hardware();
		}
		return m_inst;
	}

package:

	/**
		Sends and event into the socket
	*/
	void SendEvent(DeviceID id, ulong[2] data){
		import std.bitmanip;
		if(m_connected){
			synchronized(this.classinfo){
				m_socket.send(nativeToBigEndian(id)~nativeToBigEndian(data[0])~nativeToBigEndian(data[1]));
			}
		}
	}



private:
	static __gshared Hardware m_inst;
	//DataLog m_datalog;
	this() {
		SailLog.Notify("Starting ",typeof(this).stringof," instantiation in ",Thread.getThis().name," thread...");

		//Init devices
		InitDevices();

		if(config.Config.Get!bool("Global", "ConnectSockets")){
			version(unittest){}else{
				//Open Socket
				m_addr = new UnixAddress("/tmp/hwsocket");
				
				//Start network thread
				m_thread = new Thread(&NetworkThread);
				m_thread.name(typeof(this).stringof~"-Network");
				m_thread.isDaemon(true);
				m_thread.start();
			}
		}
		//m_datalog = new DataLog();
		m_stopCond = new Condition(new Mutex);
		
		SailLog.Success(typeof(this).stringof~" instantiated in ",Thread.getThis().name," thread");
	}
	~this(){
	    //delete m_datalog;
	
		SailLog.Critical("Destroying ",typeof(this).stringof);
		if(m_thread !is null){
			m_stopthread = true;
			m_stopCond.notifyAll;
			m_thread.join();
		}
		if(m_connected){
			m_socket.shutdown(SocketShutdown.BOTH);
			m_socket.close();
		}
	}

	/**
		Contains the instantiation list of the devices
	*/
	void InitDevices(){
		m_hwlist[DeviceID.Sail] = new Sail();
		m_hwlist[DeviceID.Helm] = new Helm();
		m_hwlist[DeviceID.Gps] = new Gps();
		m_hwlist[DeviceID.Roll] = new Roll();
		m_hwlist[DeviceID.WindDir] = new WindDir();
		m_hwlist[DeviceID.Compass] = new Compass();
		m_hwlist[DeviceID.Battery] = new Battery();
		m_hwlist[DeviceID.TurnSpeed] = new TurnSpeed();
	}


	Condition m_stopCond;
	/**
		Handles socket communications
	*/
	void NetworkThread(){
		while(!m_stopthread){

			try{
				//Connection to socket
				m_socket = new Socket(AddressFamily.UNIX, SocketType.SEQPACKET, ProtocolType.ICMP);
				m_socket.blocking(true);
				m_socket.connect(m_addr);
				m_connected = true;

				SailLog.Success("Connected to hwdaemon");

				//Handle communications
				while(!m_stopthread && m_socket.isAlive){
					ubyte buffer[17];
					long nReceived = m_socket.receive(buffer);
					if(nReceived>0){
						//SailLog.Post("Received: [",buffer[0].id,"|",buffer[0].data,"]");
						import std.bitmanip;
						//auto e = HWEvent(
						//	cast(DeviceID)bigEndianToNative!ubyte(buffer[0..1]),
						//	[
						//		bigEndianToNative!ulong(buffer[1..9]),
						//		bigEndianToNative!ulong(buffer[9..17])
						//	]
						//);
						auto e = HWEvent(
							cast(DeviceID)littleEndianToNative!ubyte(buffer[0..1]),
							[
								littleEndianToNative!ulong(buffer[1..9]),
								littleEndianToNative!ulong(buffer[9..17])
							]
						);

						switch(e.id){

							//Compile-time cast to associated class using received ID to parse value
							foreach(sens ; __traits(allMembers, DeviceSens)){

								case (mixin("DeviceID."~sens)):
									auto dev = mixin("cast("~sens~")(m_hwlist[e.id])");

									if(!dev.isemulated)
										dev.ParseValue(e.data);
									break;
							}
							break;
							default:
								SailLog.Critical("NetworkThread: ",e.id," is not a handled HWSensor");
						}
					}
					else
						break;
				}
				SailLog.Critical("Exiting ",m_thread.name," thread ! Communication with HWDaemon is dropped");
				m_socket.shutdown(SocketShutdown.BOTH);
				m_socket.close();
				m_socket.destroy();
				m_connected = false;
				
			}
			catch(Exception e){
				SailLog.Critical("Error when trying to connect socket: ",e.msg);
				synchronized(m_stopCond.mutex) m_stopCond.wait(dur!("seconds")(2));
			}
			catch(Throwable t){
				SailLog.Critical("In thread ",m_thread.name,": ",t.toString);
			}
		}

	}

	/**
		Events for socket communication
	*/
	//align(1) = struct & arguments must be packed
	align(1) struct HWEvent{
	align(1):
		DeviceID id;
		ulong data[2];
	}
	static assert(HWEvent.id.offsetof == 0);
	static assert(HWEvent.id.sizeof == 1);
	static assert(HWEvent.data.offsetof == 1);
	static assert(HWEvent.data.sizeof == 16);
	static assert(HWEvent.sizeof==17);


	UnixAddress m_addr;
	Socket m_socket;
	Thread m_thread;
	shared bool m_connected = false;
	shared bool m_stopthread = false;

	Object[DeviceID] m_hwlist;

}

//==============================================================================
unittest
{ 
	import std.stdio;
	import std.exception;

	//HWAct test
	Sail s = Hardware.Get!Sail(DeviceID.Sail);
	s.isemulated = true;
	s.value = 8;
	assert(s.value == 8);

	s.isemulated = false;
	assert(s.value == 8);
	s.value = 42;
	assert(s.value == 42);

	//HWSens test
	Roll r = Hardware.Get!Roll(DeviceID.Roll);
	r.isemulated = true;
	r.value = 2.5;
	assert(r.value == 2.5);

	r.isemulated = false;
	assertThrown(r.value = 12.3);//Throw exception

	SailLog.Notify("Hardware unittest done");
}