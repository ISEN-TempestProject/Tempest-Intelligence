module hardware.devices;

import std.conv;
import hardware.hardware;
import logger;

public import hardware.hwelement;

enum DeviceID : ubyte{
	Invalid,
	Sail,
	Helm,

	Gps,
	Roll,
	WindDir,
	Compass
}

/*!
	Handles the sail tension
	@note Values are between 0 and 255
*/
class Sail : HWAct!ubyte {
	this(){
		m_id = DeviceID.Sail;
	}

	//Check consistency
	invariant(){
		assert(0<=m_lastvalue && m_lastvalue<=255);
	}

}

class Roll : HWSens!double {
	this(){
		super(50);
		m_id = DeviceID.Roll;
		m_lastvalue=0.0;
	}

	override void ParseValue(ulong[2] data)
	out{
		assert(0<=m_values.front && m_values.front<=360);
	}body{
		m_values.Append(to!float(data[0]*(360.0/ulong.max)));
		ExecFilter();
	}

	//Check consistency
	invariant(){
		assert(0<=m_lastvalue && m_lastvalue<=360);
	}

}