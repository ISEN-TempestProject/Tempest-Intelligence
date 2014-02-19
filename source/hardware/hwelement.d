module hardware.hwelement;

import saillog;
import hardware.hardware;
import hardware.devices;
import fifo;

abstract class HWElement(T) {

	
 
	@property{
		DeviceID id() const{
			return m_id;
		}

		void isemulated(bool b){
			m_isemulated = b;
		}
		bool isemulated() const{
			return m_isemulated;
		}

		abstract T value() const;
		abstract void value(T val);
	}


	T min() const{return m_min;}
	T max() const{return m_max;}
	T init() const{return m_init;}
	invariant(){
		assert(m_min<=m_lastvalue && m_lastvalue<=m_max);
	}

protected:
	DeviceID m_id;
	bool m_isemulated = false;
	T m_lastvalue;
	T m_min, m_max, m_init;
}

//==============================================================================
class HWSens(T) : HWElement!T {

	@property{
		override T value() const{
			if(m_isemulated)
				return m_lastvalue;
			else{
				return m_lastvalue;
			}
		}

		override void value(T val){
			if(m_isemulated)
				m_lastvalue = val;
			else{
				SailLog.Warning("Trying to set value of ",m_id," while not emulated");
				throw new Exception("Cannot set value of a HWSens while not emulated");
			}
		}
	}

	abstract void ParseValue(ulong[2] data);

protected:
	this(size_t fifoSize){
		m_values = new Fifo!T(fifoSize);
	}

	///Default filter : gets the front value
	void ExecFilter(){
		//m_lastvalue = m_values.front();
	}

	Fifo!T m_values;
}

//==============================================================================
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
	ulong[2] FormatLastValue(in T value){
		return [cast(ulong)(value), cast(ulong)(0)];
	}
}