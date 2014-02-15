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

}

class Roll : HWSens!double {
	this(){
		super(50);
		m_id = DeviceID.Roll;
	}

	override void ParseValue(ulong[2] data){
		m_values.Append(to!float(data[0]*(360.0/ulong.max)));
		ExecFilter();
	}
}