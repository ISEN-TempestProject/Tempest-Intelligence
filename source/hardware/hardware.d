module hardware.hardware;

import std.process;
import std.socket;
import core.thread;
import saillog;

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

package:
	/**
		Simple getter, not used outside the package
	*/
	static Hardware GetClass(){
		synchronized(this.classinfo){
			if(m_inst is null) m_inst = new Hardware();
		}
		return m_inst;
	}

	/**
		Sends and event into the socket
	*/
	void SendEvent(DeviceID id, ulong[2] data){
		//TODO Check this
		m_socket.send([id, data[0], data[1]]);
	}



private:
	static __gshared Hardware m_inst;
	this() {
		SailLog.Notify("Starting ",typeof(this).stringof," instantiation in ",Thread.getThis().name," thread...");

		//Init devices
		InitDevices();

		version(unittest){}else{
			//Open Socket
			m_addr = new UnixAddress("/tmp/socket");
			m_socket = new Socket(AddressFamily.UNIX, SocketType.SEQPACKET, ProtocolType.ICMP);
			m_socket.blocking(true);
			try{
				m_socket.connect(m_addr);
			}catch(Exception e){
				SailLog.Critical("Error when trying to connect socket: ",e.msg,"\n",e.file,":",e.line);
				return;
			}

			//Start network thread
			m_thread = new Thread(&NetworkThread);
			m_thread.name(typeof(this).stringof~"-Network");
			m_thread.isDaemon(true);
			m_thread.start();
		}
		SailLog.Success(typeof(this).stringof~" instantiated in ",Thread.getThis().name," thread");
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
	}


	/**
		Handles socket communications
	*/
	void NetworkThread(){

		while(true){
			HWEvent buffer[1];
			long nReceived = m_socket.receive(buffer);
			if(nReceived>0){
				SailLog.Post("Received: [",buffer[0].id,"|",buffer[0].data,"]");

				switch(buffer[0].id){
					case DeviceID.Gps:
						(cast(Gps)(m_hwlist[buffer[0].id])).ParseValue(buffer[0].data); 
						break;
					case DeviceID.Roll:
						(cast(Roll)(m_hwlist[buffer[0].id])).ParseValue(buffer[0].data); 
						break;
					case DeviceID.WindDir:
						(cast(WindDir)(m_hwlist[buffer[0].id])).ParseValue(buffer[0].data); 
						break;
					case DeviceID.Compass:
						(cast(Compass)(m_hwlist[buffer[0].id])).ParseValue(buffer[0].data); 
						break;

					default:
						SailLog.Warning("NetworkThread: ",buffer[0].id," is not a handled HWSensor");
				}
			}
		}
	}


	unittest {
		assert(HWEvent.id.sizeof == 1);
		assert(HWEvent.data.sizeof == 16);
	}
	/**
		Events for socket communication
	*/
	struct HWEvent{
		DeviceID id;
		ulong data[2];
	}

	/**
		Callback for parsing received events
	*/
	void OnEventReceived(T)(HWEvent ev){
		//store data in the correct device
	}


	UnixAddress m_addr;
	Socket m_socket;
	Thread m_thread;

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
	assert(r.value == 2.5);
	assertThrown(r.value = 12.3);//Throw exception

	SailLog.Notify("Hardware unittest done");
}