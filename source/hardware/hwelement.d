module hardware.hwelement;

import saillog;
import hardware.hardware;
import hardware.devices;
import fifo;
import filter;

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
		Out of service state of the device
	*/
	@property{
		bool isoutofservice() const{
			return m_isoutofservice;
		}
	}

	/**
		Value of the device, must be between min and max
	*/
	@property{
		abstract T value();
		abstract void value(T val);
	}


	/**
		min, max values of the device, and the initial value
	*/
	@property{
		T min() {return m_min;}
		T max() {return m_max;}
		T init() {return m_init;}
	}

protected:
	DeviceID m_id;
	bool m_isemulated = false;
	bool m_isoutofservice = false;
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
		override T value(){
			ExecFilter();
			return m_lastvalue;
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
		You should call CheckIsOutOfService sometimes in the function
	*/
	abstract void ParseValue(ulong[2] data);


protected:
	this(size_t fifoSize){
		m_values = Fifo!(TimestampedValue!T)(fifoSize);
	}

	/**
		Checks if the last values are coherent, and sets isoutofservice if something is wrong
	*/
	abstract void CheckIsOutOfService();

	abstract void ExecFilter();

	Fifo!(TimestampedValue!T) m_values;
}

//==============================================================================

/**
	Abstract class to represent an actuator
	Todo: find a way to check if actuators are working correctly
*/
class HWAct(T) : HWElement!T {

	@property{
		override T value(){
			return m_lastvalue;
		}

		override void value(T val){
			if(!m_isemulated){
				Hardware.GetClass().SendEvent(m_id, FormatValue(val));
			}
			m_lastvalue = val;
		}
	}

protected:
	/**
		Formats the values to send into the socket
	*/
	abstract ulong[2] FormatValue(in T value);
}