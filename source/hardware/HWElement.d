module hardware.hwelement;

import logger;
import hardware.hardware;
import hardware.devices;

abstract class HWElement(T) {

	DeviceID GetID(){
		return m_id;
	}

	@property{
		void isemulated(bool b){
			m_isemulated = b;
		}
		bool isemulated(){
			return m_isemulated;
		}

		abstract T value();
		abstract void value(T val);
	}

protected:
	DeviceID m_id;
	bool m_isemulated = false;
	T m_lastvalue;
}


class HWSens(T) : HWElement!T {

	@property{
		override T value(){
			if(m_isemulated)
				return m_lastvalue;
			else
				return Hardware.GetClass().QueryGet!T(m_id);
		}

		override void value(T val){
			if(m_isemulated)
				m_lastvalue = val;
			else{
				Logger.Warning("Trying to set value of ",m_id," while not emulated");
				throw new Exception("Cannot set value of a HWSens while not emulated");
			}
		}
	}
}

class HWAct(T) : HWElement!T {

	@property{
		override T value(){
			return m_lastvalue;
		}

		override void value(T val){
			if(!m_isemulated)
				Hardware.GetClass();//.QuerySet!T(m_id, val);
			m_lastvalue = val;
		}
	}
}