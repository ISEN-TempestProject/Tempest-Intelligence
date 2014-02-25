module hardware.hwelement;

import saillog;
import hardware.hardware;
import hardware.devices;
import fifo;
/**
	Abstract class to represent a hardware element/device
*/
abstract class HWElement(T) {

	
 
	/**
		ID of the device, which can be used to cast it to the final type
	*/
	@property{
		DeviceID id() const{
			return m_id;
		}
	}

	/**
		Emulated state of the device
	*/
	@property{
		void isemulated(bool b){
			m_isemulated = b;
		}
		bool isemulated() const{
			return m_isemulated;
		}
	}

	/**
		Value of the device, must be between min and max
	*/
	@property{
		abstract T value() const;
		abstract void value(T val);
	}


	/**
		min, max values of the device, and the initial value
	*/
	@property{
		T min() const{return m_min;}
		T max() const{return m_max;}
		T init() const{return m_init;}
	}

protected:
	DeviceID m_id;
	bool m_isemulated = false;
	T m_lastvalue;
	T m_min, m_max, m_init;
}

//==============================================================================

/**
	Abstract class to represent a sensor
	Notes: Sensors can throw exceptions when set while not emulated
*/
class HWSens(T) : HWElement!T {

	@property{
		override T value() const{
			if(m_isemulated)
				return m_lastvalue;
			else{
				return m_lastvalue;
			}
		}

		/**
			Throws: exception if the sensor is not emulated
		*/
		override void value(T val){
			if(m_isemulated)
				m_lastvalue = val;
			else{
				SailLog.Warning("Trying to set value of ",m_id," while not emulated");
				throw new Exception("Cannot set value of a HWSens while not emulated");
			}
		}
	}

	/**
		Called from the Hardware class, handles the parsing of received data
	*/
	abstract void ParseValue(ulong[2] data);

protected:
	this(size_t fifoSize){
		m_values = new Fifo!T(fifoSize);
	}

	/**
		Default filter : gets the front value. Override it to customize
	*/
	void ExecFilter(){
		//m_lastvalue = m_values.front();
	}

	Fifo!T m_values;
}

//==============================================================================

/**
	Abstract class to represent an actuator
*/
class HWAct(T) : HWElement!T {

	@property{
		override T value() const{
			return m_lastvalue;
		}

		override void value(T val){
			if(!m_isemulated){
				Hardware.GetClass().SendEvent(m_id, FormatLastValue(val));
			}
			m_lastvalue = val;
		}
	}

protected:
	/**
		Formats the values to send into the socket
	*/
	ulong[2] FormatLastValue(in T value){
		return [cast(ulong)(value), cast(ulong)(0)];
	}
}