module hardware.devices;

import hardware.hardware;

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
		m_id = DeviceID.Roll;
	}
}